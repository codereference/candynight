-- One shop plot at runtime: its world view, its shop rules, its customers and its owner's session.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Shop = require(ReplicatedStorage.Shared.Rules.Shop)
local Strings = require(ReplicatedStorage.Shared.Strings)
local UnlockTree = require(ReplicatedStorage.Shared.Rules.UnlockTree)
local ButtonsView = require(script.Parent.ButtonsView)
local CustomerView = require(script.Parent.CustomerView)
local ItemsView = require(script.Parent.ItemsView)
local PlotView = require(script.Parent.PlotView)

local PlotRuntime = {}
PlotRuntime.__index = PlotRuntime

PlotRuntime.tree = UnlockTree.new(Config.Buttons)

function PlotRuntime.new(index: number, origin: CFrame)
	local view = PlotView.build(index, origin, Config.Customer.queueSpacing)
	local self = setmetatable({
		index = index,
		view = view,
		customers = CustomerView.new(Config.Customer.walkSpeed, view.customers),
		owner = nil :: Player?,
		session = nil,
		shop = nil,
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
		session:notify("Notify.Bought", { item = Strings.get("Button." .. id) })
	elseif reason == "cash" then
		local missing = self.tree:get(id).cost - session.wallet:getCash()
		session:notify("Notify.NeedCash", { amount = Format.cash(missing) })
	end
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
		elseif event.kind == "CustomerServed" then
			self:_applySale(event)
		end
	end
	if #events > 0 then
		self:_refreshQueue()
	end
end

return PlotRuntime
