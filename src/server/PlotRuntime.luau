-- One shop plot at runtime: its world view, its shop rules, its customers and its owner's session.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Shop = require(ReplicatedStorage.Shared.Rules.Shop)
local PlotView = require(script.Parent.PlotView)
local CustomerView = require(script.Parent.CustomerView)

local PlotRuntime = {}
PlotRuntime.__index = PlotRuntime

function PlotRuntime.new(index: number, origin: CFrame)
	local view = PlotView.build(index, origin, Config.Customer.queueSpacing)
	local self = setmetatable({
		index = index,
		view = view,
		customers = CustomerView.new(Config.Customer.walkSpeed, view.customers),
		owner = nil :: Player?,
		session = nil,
		shop = nil,
	}, PlotRuntime)

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
	self:sendOwnerHome()
end

function PlotRuntime:release()
	self.owner = nil
	self.session = nil
	self.shop = nil
	self.customers:clear()
	self.view.clear()
	self.view.setOwnerName(nil)
end

function PlotRuntime:sendOwnerHome()
	local character = self.owner and self.owner.Character
	if character then
		character:PivotTo(self.view.spawn.CFrame + Vector3.new(0, 3, 0))
	end
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
	self.customers:leave(sale.customerId, self.view.exit)
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
		end
	end
	if #events > 0 then
		self:_refreshQueue()
	end
end

return PlotRuntime
