-- One shop plot at runtime: its world view, its shop rules, its customers and its owner's session.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Defenses = require(ReplicatedStorage.Shared.Rules.Defenses)
local Grid = require(ReplicatedStorage.Shared.Rules.Grid)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local NightOutcome = require(ReplicatedStorage.Shared.Rules.NightOutcome)
local Offline = require(ReplicatedStorage.Shared.Rules.Offline)
local Rebirth = require(ReplicatedStorage.Shared.Rules.Rebirth)
local Shop = require(ReplicatedStorage.Shared.Rules.Shop)
local Strings = require(ReplicatedStorage.Shared.Strings)
local UnlockTree = require(ReplicatedStorage.Shared.Rules.UnlockTree)
local WeaponRules = require(ReplicatedStorage.Shared.Rules.WeaponRules)
local ButtonsView = require(script.Parent.ButtonsView)
local CustomerView = require(script.Parent.CustomerView)
local DefenseView = require(script.Parent.DefenseView)
local ItemsView = require(script.Parent.ItemsView)
local PlotView = require(script.Parent.PlotView)
local TurretDirector = require(script.Parent.TurretDirector)
local Weapons = require(script.Parent.Weapons)

local PlotRuntime = {}
PlotRuntime.__index = PlotRuntime

PlotRuntime.tree = UnlockTree.new(Config.Buttons)
PlotRuntime.grid = Grid.new(Layout)
local DEFENSES = Config.Defenses.catalog
PlotRuntime.nightEnded = Instance.new("BindableEvent") -- fires (runtime, result) after each shop's dawn
PlotRuntime.reborn = Instance.new("BindableEvent") -- fires (runtime) after a rebirth

local nightResultRemote = Net.event("NightResult")
local offlineRemote = Net.event("OfflineEarnings")

function PlotRuntime.new(index: number, origin: CFrame)
	local view = PlotView.build(index, origin, Config.Customer.queueSpacing)
	local self = setmetatable({
		index = index,
		view = view,
		customers = CustomerView.new(Config.Customer.walkSpeed, view.customers),
		owner = nil :: Player?,
		session = nil,
		shop = nil,
		outcome = nil, -- NightOutcome while it's night
		defenseModels = {}, -- [placed id] = Model
		connections = {},
	}, PlotRuntime)
	self.buttons = ButtonsView.new(view, function(player, id)
		if player == self.owner then
			self:buy(id)
		end
	end)

	view.servePrompt.Triggered:Connect(function(player)
		if player == self.owner then
			self:_applySale(self.shop:serve())
		end
	end)
	return self
end

function PlotRuntime:assign(player: Player, session)
	self.owner = player
	self.session = session
	self.shop = Shop.new(Config.Shop)
	self.view.setOwnerName(player.DisplayName)
	player:SetAttribute("PlotIndex", self.index)

	self:_buildShop()
	self:_publishNight()
	self:giveWeapons()
	self:_offerOfflineEarnings()
	table.insert(
		self.connections,
		session.cashChanged.Event:Connect(function(cash)
			self.buttons:refreshColours(cash)
		end)
	)
	self:sendOwnerHome()
end

-- Builds everything the owner owns: items, buttons, defenses. Used on join and after rebirth.
function PlotRuntime:_buildShop()
	local profile = self.session.profile
	for _, id in self.tree:ownedInOrder(profile.owned) do
		ItemsView.build(self.view, id, false)
	end
	self:_applyEffects()
	self:_showButtons()
	for _, entry in profile.placed do
		self:_buildDefense(entry)
	end
end

-- Works out what staff earned while the owner was away and offers it in a welcome-back popup.
function PlotRuntime:_offerOfflineEarnings()
	local session = self.session
	local lastOnline = session.profile.lastOnline
	if lastOnline <= 0 then
		return -- brand-new player
	end
	local away = os.time() - lastOnline
	local staff = self.tree:effects(session.profile.owned).staff
	local amount = Offline.earnings(Config.Offline, away, staff, self.shop:saleValue(), session:multiplier())
	if amount > 0 then
		session.pendingOffline = amount
		offlineRemote:FireClient(self.owner, amount, math.min(away, Config.Offline.capSeconds))
	end
end

-- Resets the shop for a permanent income multiplier. Returns true, or false plus a reason key.
function PlotRuntime:rebirth(): (boolean, string?)
	local session = self.session
	local ok, reason = Rebirth.apply(Config.Rebirth, session.profile, session.wallet)
	session:syncCash()
	if not ok then
		return false, reason
	end
	self.buttons:clear()
	self.view.items:ClearAllChildren()
	self.view.defenses:ClearAllChildren()
	table.clear(self.defenseModels)
	self:_buildShop()
	Weapons.reset(self.owner)
	self:giveWeapons()
	session:refreshMultiplier()
	session:notify(
		"Rebirth.Done",
		{ mult = string.format("%.1f", Rebirth.multiplier(Config.Rebirth, session.profile.rebirths)) }
	)
	PlotRuntime.reborn:Fire(self)
	return true, nil
end

function PlotRuntime:release()
	if self.owner then
		self.owner:SetAttribute("PlotIndex", nil)
	end
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.owner = nil
	self.session = nil
	self.shop = nil
	self.outcome = nil
	table.clear(self.defenseModels)
	self.customers:clear()
	self.buttons:clear()
	self.view.clear()
	self.view.setOwnerName(nil)
end

function PlotRuntime:sendOwnerHome()
	local character = self.owner and self.owner.Character
	if character then
		character:PivotTo(self.view.spawn.CFrame + Vector3.new(0, 3, 0))
	end
end

-- Buys a button for the owner. All checks happen in the rules; this only shows the result.
function PlotRuntime:buy(id: string)
	local session = self.session
	local ok, reason = self.tree:buy(session.profile.owned, session.wallet, id)
	session:syncCash()
	if ok then
		ItemsView.build(self.view, id, true)
		self:_applyEffects()
		self:_showButtons()
		self:giveWeapons()
		session:notify("Notify.Bought", { item = Strings.get("Button." .. id) })
	elseif reason == "cash" then
		local missing = self.tree:get(id).cost - session.wallet:getCash()
		session:notify("Notify.NeedCash", { amount = Format.cash(missing) })
	end
end

-- Puts every weapon the owner has earned into their backpack (call again after each respawn).
function PlotRuntime:giveWeapons()
	local profile = self.session.profile
	local unlocked = self.tree:effects(profile.owned).weapons
	Weapons.equip(self.owner, WeaponRules.owned(profile.weapons, unlocked))
end

function PlotRuntime:_applyEffects()
	local effects = self.tree:effects(self.session.profile.owned)
	local perks = self.session.perks or {}
	if perks.extraHelper then
		table.insert(effects.staff, { id = "PassHelper", interval = Config.Monetization.extraHelperInterval })
		if self.view.items:FindFirstChild("PassHelper") == nil then
			ItemsView.build(self.view, "PassHelper", true)
		end
	end
	self.shop:setEffects(effects)
end

-- Gamepass perks changed (bought in-game, or ownership finished loading).
function PlotRuntime:refreshPerks()
	if self.shop then
		self:_applyEffects()
	end
end

function PlotRuntime:_showButtons()
	local buttons = {}
	for _, id in self.tree:available(self.session.profile.owned) do
		table.insert(buttons, { id = id, cost = self.tree:get(id).cost })
	end
	self.buttons:show(buttons, self.session.wallet:getCash())
end

function PlotRuntime:_refreshQueue()
	local queue = self.shop:getQueue()
	self.customers:layout(queue, self.view.queueSlot)
	self.view.servePrompt.Enabled = #queue > 0
end

function PlotRuntime:_applySale(sale)
	if sale == nil then
		return
	end
	self.session:earnSale(sale.cash)
	self.session.profile.stats.served += 1
	self.customers:leave(sale.customerId, self.view.exit)
	if sale.staffId then
		ItemsView.cheer(self.view, sale.staffId)
	end
	self:_refreshQueue()
end

function PlotRuntime:tick(dt: number)
	if self.shop == nil then
		return -- no shopkeeper, no customers
	end
	local events = self.shop:tick(dt)
	for _, event in events do
		if event.kind == "CustomerArrived" then
			self.customers:spawn(event.customerId, self.view.entrance)
			if self.outcome then
				self.outcome:customerArrived()
				self:_publishNight()
			end
		elseif event.kind == "CustomerServed" then
			self:_applySale(event)
		end
	end
	if #events > 0 then
		self:_refreshQueue()
	end
end

-- Night ----------------------------------------------------------------------------------------

-- Shares night progress with the owner's HUD as player attributes.
function PlotRuntime:_publishNight()
	local owner = self.owner
	if owner == nil then
		return
	end
	owner:SetAttribute("Streak", self.session.profile.streak)
	owner:SetAttribute("NightLost", self.outcome and self.outcome.lost)
	owner:SetAttribute("NightAllowed", self.outcome and self.outcome:allowed())
end

function PlotRuntime:beginNight()
	local profile = self.session.profile
	self.outcome = NightOutcome.new(Config.Night, profile.streak, { forgiving = not profile.tutorial.firstNightDone })
	for _ in self.shop:getQueue() do
		self.outcome:customerArrived() -- whoever's already in line is out in the dark too
	end
	self:applyBoosts()
	self:_publishNight()
end

-- A shadow creature scared a customer away.
function PlotRuntime:loseCustomer(customerId: number)
	if not self.shop:loseCustomer(customerId) then
		return
	end
	self.customers:leave(customerId, self.view.exit, "😱", 2.2)
	if self.outcome then
		self.outcome:customerLost()
		self:_publishNight()
	end
	self:_refreshQueue()
end

-- Ids of placed defenses still standing, oldest first (the ones a failed night breaks).
function PlotRuntime:standingDefenseIds(): { number }
	local ids = {}
	for _, placed in self.session.profile.placed do
		if placed.hp > 0 then
			table.insert(ids, placed.id)
		end
	end
	return ids
end

-- Settles the night at dawn and applies the result to the owner's profile.
function PlotRuntime:endNight()
	local outcome = self.outcome
	self.outcome = nil
	local session, profile = self.session, self.session.profile
	local result = outcome:settle(session.wallet:getCash(), self:standingDefenseIds())

	profile.streak = result.streak
	profile.bestStreak = math.max(profile.bestStreak, result.streak)
	if result.survived then
		profile.nightsSurvived += 1
	end
	if result.cashLost > 0 then
		session:spend(result.cashLost)
	end
	for _, id in result.brokenDefenses do
		self:breakDefense(id)
	end
	profile.tutorial.firstNightDone = true

	self:_publishNight()
	nightResultRemote:FireClient(self.owner, {
		survived = result.survived,
		lost = result.lost,
		allowed = result.allowed,
		cashLost = result.cashLost,
		broken = #result.brokenDefenses,
		streak = result.streak,
	})
	PlotRuntime.nightEnded:Fire(self, result)
end

-- Defenses -------------------------------------------------------------------------------------

function PlotRuntime:_buildDefense(entry)
	local model = DefenseView.build(self.view, entry)
	DefenseView.setHealth(model, entry.hp / DEFENSES[entry.kind].hp)
	self.defenseModels[entry.id] = model
end

-- Each returns true, or false plus a reason key the client shows (see Strings "Reason.*").
function PlotRuntime:placeDefense(kind: string, col: number, row: number, rot: number): (boolean, string?)
	local session = self.session
	local entry, reason = Defenses.place(
		session.profile,
		session.wallet,
		self.grid,
		DEFENSES,
		Config.Defenses,
		session.profile.owned,
		kind,
		col,
		row,
		rot
	)
	session:syncCash()
	if entry == nil then
		return false, reason
	end
	self:_buildDefense(entry)
	session:notify("Defense.Placed", { item = Strings.get("Defense." .. kind) })
	return true, nil
end

function PlotRuntime:moveDefense(id: number, col: number, row: number, rot: number): (boolean, string?)
	local ok, reason = Defenses.move(self.session.profile, self.grid, id, col, row, rot)
	if ok then
		DefenseView.place(self.view, self.defenseModels[id], (Defenses.find(self.session.profile, id)))
	end
	return ok, reason
end

function PlotRuntime:sellDefense(id: number): (boolean, string?)
	local session = self.session
	local refund = Defenses.sell(session.profile, session.wallet, DEFENSES, Config.Defenses, id)
	session:syncCash()
	if refund == nil then
		return false, "missing"
	end
	self.defenseModels[id]:Destroy()
	self.defenseModels[id] = nil
	session:notify("Defense.Sold", { cash = Format.cash(refund) })
	return true, nil
end

function PlotRuntime:repairDefense(id: number): (boolean, string?)
	local session = self.session
	local ok, reason = Defenses.repair(session.profile, session.wallet, DEFENSES, Config.Defenses, id)
	session:syncCash()
	if not ok then
		return false, if reason == "full" then "full_hp" else reason
	end
	DefenseView.setHealth(self.defenseModels[id], 1)
	session:notify("Defense.Repaired")
	return true, nil
end

-- Damages a placed defense (creatures, failed nights). Returns true when it was destroyed.
function PlotRuntime:damageDefense(id: number, amount: number): boolean
	local profile = self.session.profile
	local destroyed = Defenses.damage(profile, id, amount)
	local entry = Defenses.find(profile, id)
	if entry then
		DefenseView.setHealth(self.defenseModels[id], entry.hp / DEFENSES[entry.kind].hp)
	end
	return destroyed
end

-- The closest standing defense within radius of a world position: id and position, or nil.
function PlotRuntime:nearestStandingDefense(position: Vector3, radius: number): (number?, Vector3?)
	local bestId, bestPosition, bestDistance = nil, nil, radius
	for id, model in self.defenseModels do
		local entry = Defenses.find(self.session.profile, id)
		if entry and entry.hp > 0 then
			local at = model:GetPivot().Position
			local distance = Vector3.new(at.X - position.X, 0, at.Z - position.Z).Magnitude
			if distance <= bestDistance then
				bestId, bestPosition, bestDistance = id, at, distance
			end
		end
	end
	return bestId, bestPosition
end

-- Uses bought boosts if it's night (otherwise they wait for the next night).
function PlotRuntime:applyBoosts()
	local boosts = self.session.profile.boosts
	if self.outcome == nil then
		return
	end
	local used = false
	if boosts.shield > 0 then
		self.outcome:addAllowance(Config.Monetization.shieldAllowance * boosts.shield)
		boosts.shield = 0
		used = true
	end
	if boosts.overdrive > 0 and TurretDirector.overdrive[self] == nil then
		TurretDirector.overdrive[self] = Config.Monetization.overdriveMultiplier
		boosts.overdrive -= 1
		used = true
	end
	if used then
		self:_publishNight()
		self.session:notify("Boost.Active")
	end
end

-- Instant Repair: every defense back to full health.
function PlotRuntime:repairAll()
	for _, entry in self.session.profile.placed do
		entry.hp = DEFENSES[entry.kind].hp
		local model = self.defenseModels[entry.id]
		if model then
			DefenseView.setHealth(model, 1)
		end
	end
end

function PlotRuntime:breakDefense(id: number)
	self:damageDefense(id, math.huge)
end

return PlotRuntime
