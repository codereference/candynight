-- Server entry point. Thin adapter: Roblox input and time go into the rules layer,
-- and the events that come back are shown in the world. Cash only ever changes here, on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local Config = require(Shared.Config)
local Economy = require(Shared.Rules.Economy)
local Shop = require(Shared.Rules.Shop)
local PlotView = require(script.PlotView)
local CustomerView = require(script.CustomerView)

local wallets = {} -- [Player] = Economy wallet
local cashValues: { [Player]: IntValue } = {} -- the leaderstats Cash the HUD reads

local plot = PlotView.build(CFrame.new(0, 0, 0), Config.Customer.queueSpacing)
local shop = Shop.new(Config.Shop)
local customers = CustomerView.new(Config.Customer.walkSpeed)
local owner: Player? = nil -- one plot for now; ticket #3 brings six

local function refreshQueue()
	customers:layout(shop:getQueue(), plot.queueSlot)
	plot.servePrompt.Enabled = #shop:getQueue() > 0
end

local function syncCash(player: Player)
	cashValues[player].Value = wallets[player]:getCash()
end

local function onPlayerAdded(player: Player)
	wallets[player] = Economy.new(Config.startingCash)

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	leaderstats.Parent = player
	cashValues[player] = cash
	syncCash(player)

	if owner == nil then
		owner = player
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- anyone who joined before this script ran
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	wallets[player] = nil
	cashValues[player] = nil
	if owner == player then
		owner = nil
		for _, other in Players:GetPlayers() do
			if other ~= player then
				owner = other
				break
			end
		end
	end
end)

plot.servePrompt.Triggered:Connect(function(player)
	if player ~= owner or not wallets[player] then
		return
	end
	local sale = shop:serve()
	if sale == nil then
		return
	end
	wallets[player]:earn(sale.cash)
	syncCash(player)
	customers:leave(sale.customerId, plot.exit)
	refreshQueue()
end)

RunService.Heartbeat:Connect(function(dt)
	if owner == nil then
		return -- no shopkeeper, no customers
	end
	local events = shop:tick(dt)
	if #events == 0 then
		return
	end
	for _, event in events do
		if event.kind == "CustomerArrived" then
			customers:spawn(event.customerId, plot.entrance)
		end
	end
	refreshQueue()
end)
