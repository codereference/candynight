-- One shop plot at runtime: its world view, its shop rules, its customers and its owner's session.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local NightOutcome = require(ReplicatedStorage.Shared.Rules.NightOutcome)
local Shop = require(ReplicatedStorage.Shared.Rules.Shop)
local Strings = require(ReplicatedStorage.Shared.Strings)
local UnlockTree = require(ReplicatedStorage.Shared.Rules.UnlockTree)
local WeaponRules = require(ReplicatedStorage.Shared.Rules.WeaponRules)
local ButtonsView = require(script.Parent.ButtonsView)
local CustomerView = require(script.Parent.CustomerView)
local ItemsView = require(script.Parent.ItemsView)
local PlotView = require(script.Parent.PlotView)
local Weapons = require(script.Parent.Weapons)

local PlotRuntime = {}
PlotRuntime.__index = PlotRuntime

PlotRuntime.tree = UnlockTree.new(Config.Buttons)
PlotRuntime.nightEnded = Instance.new("BindableEvent") -- fires (runtime, result) after each shop's dawn

local nightResultRemote = Net.event("NightResult")

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

	for _, id in self.tree:ownedInOrder(session.profile.owned) do
		ItemsView.build(self.view, id, false)
	end
	self:_applyEffects()
	self:_showButtons()
	self:_publishNight()
	self:giveWeapons()
	table.insert(
		self.connections,
		session.cashChanged.Event:Connect(function(cash)
			self.buttons:refreshColours(cash)
		end)
	)
	self:sendOwnerHome()
end

function PlotRuntime:release()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.owner = nil
	self.session = nil
	self.shop = nil
	self.outcome = nil
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
	self.shop:setEffects(self.tree:effects(self.session.profile.owned))
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
	self.session:earn(sale.cash)
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

-- Placeholder until defenses exist (#11/#12): marks a placed defense as destroyed.
function PlotRuntime:breakDefense(id: number)
	for _, placed in self.session.profile.placed do
		if placed.id == id then
			placed.hp = 0
		end
	end
end

return PlotRuntime
