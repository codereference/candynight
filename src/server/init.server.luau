-- Server entry point. Thin adapter: Roblox input and time go into the rules layer,
-- and the events that come back are shown in the world. Cash only ever changes on the server.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage.Shared.Config)
local Plots = require(ReplicatedStorage.Shared.Rules.Plots)
local PlotRuntime = require(script.PlotRuntime)
local PlotView = require(script.PlotView)
local Sessions = require(script.Sessions)
local Strings = require(ReplicatedStorage.Shared.Strings)
local World = require(script.World)
local NightDirector = require(script.NightDirector)
local Weapons = require(script.Weapons)
local TurretDirector = require(script.TurretDirector)
local Raids = require(script.Raids)
local Achievements = require(script.Achievements)
local Leaderboard = require(script.Leaderboard)
local Rewards = require(script.Rewards)
local Bonuses = require(script.Bonuses)
local Events = require(ReplicatedStorage.Shared.Rules.Events)
local Monetization = require(script.Monetization)
local Products = require(script.Products)
local Style = require(script.Style)
local AdminService = require(script.AdminService)
local Onboarding = require(script.Onboarding)
local Net = require(ReplicatedStorage.Shared.Net)

local plots = Plots.new(Config.Plots.count)
local runtimes = {}

-- Two rows of plots facing each other across the road.
PlotView.buildRoad(Config.Plots.spacing * 4)
local perRow = math.ceil(Config.Plots.count / 2)
for index = 1, Config.Plots.count do
	local north = index <= perRow
	local column = (if north then index else index - perRow) - (perRow + 1) / 2
	local position =
		Vector3.new(column * Config.Plots.spacing, 0, if north then -Config.Plots.rowOffset else Config.Plots.rowOffset)
	-- Each plot's front (-Z) faces the road.
	local origin = if north then CFrame.new(position) * CFrame.Angles(0, math.pi, 0) else CFrame.new(position)
	runtimes[index] = PlotRuntime.new(index, origin)
end

local function runtimeOf(player: Player)
	local index = plots:plotOf(player.UserId)
	return index and runtimes[index]
end

-- Systems start before any player is handled, so none of them miss a join.
Raids.init(runtimes)
Monetization.perksChanged.Event:Connect(function(session)
	local index = plots:plotOf(session.player.UserId)
	if index then
		runtimes[index]:refreshPerks()
	end
end)
Achievements.start()
Leaderboard.start()
Rewards.start()
Bonuses.start()
Monetization.start()
Products.start(runtimeOf)
Style.start(runtimeOf, PlotRuntime.weaponsGiven, Monetization.perksChanged)
AdminService.start(runtimeOf)
Onboarding.start()

local function onPlayerAdded(player: Player)
	local session = Sessions.start(player) -- yields while the save loads
	if session == nil then
		return -- left while loading
	end
	local index = plots:claim(player.UserId)
	if index == nil then
		player:Kick(Strings.get("Kick.Full"))
		return
	end
	local runtime = runtimes[index]
	runtime:assign(player, session)
	local function onSpawn()
		task.defer(function()
			if runtime.owner == player then
				runtime:sendOwnerHome()
				runtime:giveWeapons()
			end
		end)
	end
	player.CharacterAdded:Connect(onSpawn)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do -- anyone who joined before this script ran
	onPlayerAdded(player)
end

Players.PlayerRemoving:Connect(function(player)
	local index = plots:release(player.UserId)
	if index then
		runtimes[index]:release()
	end
	Weapons.forget(player)
	Sessions.stop(player)
end)

local function isCell(n: any): boolean
	return type(n) == "number" and n == n and n % 1 == 0 and math.abs(n) < 1000
end

-- Defense requests from clients. Every argument is type-checked; the rules check everything else.
Net.func("PlaceDefense").OnServerInvoke = function(player, kind, col, row, rot)
	local runtime = runtimeOf(player)
	if not (runtime and type(kind) == "string" and isCell(col) and isCell(row) and isCell(rot)) then
		return false, "unknown"
	end
	return runtime:placeDefense(kind, col, row, rot)
end

Net.func("MoveDefense").OnServerInvoke = function(player, id, col, row, rot)
	local runtime = runtimeOf(player)
	if not (runtime and isCell(id) and isCell(col) and isCell(row) and isCell(rot)) then
		return false, "unknown"
	end
	return runtime:moveDefense(id, col, row, rot)
end

Net.func("Rebirth").OnServerInvoke = function(player)
	local runtime = runtimeOf(player)
	if runtime == nil then
		return false, "unknown"
	end
	return runtime:rebirth()
end

Net.func("CollectOffline").OnServerInvoke = function(player)
	local session = Sessions.get(player)
	return session and session:collectOffline() or 0
end

Net.func("SellDefense").OnServerInvoke = function(player, id)
	local runtime = runtimeOf(player)
	if not (runtime and isCell(id)) then
		return false, "unknown"
	end
	return runtime:sellDefense(id)
end

Net.func("RepairDefense").OnServerInvoke = function(player, id)
	local runtime = runtimeOf(player)
	if not (runtime and isCell(id)) then
		return false, "unknown"
	end
	return runtime:repairDefense(id)
end

-- Tonight's event (Blood Moon, seasonal...): creature modifiers plus an income boost for everyone.
local currentEvent = nil

local function applyEventBoost(session)
	session.factors.event = currentEvent and currentEvent.modifiers.reward
	session:refreshMultiplier()
	if currentEvent then
		session:notify("Event." .. currentEvent.id)
	end
end
Sessions.started.Event:Connect(applyEventBoost)

World.phaseChanged.Event:Connect(function(phase, night)
	if phase == "Night" then
		currentEvent = Events.forNight(Config.Events, night, os.time())
		if AdminService.forcedEvent then
			for _, event in Config.Events do
				if event.id == AdminService.forcedEvent then
					currentEvent = event
				end
			end
			AdminService.forcedEvent = nil
		end
		NightDirector.modifiers = if currentEvent then currentEvent.modifiers else {}
		NightDirector.startNight(runtimes, night)
	else
		NightDirector.endNight(runtimes)
		TurretDirector.endNight()
		currentEvent = nil
		NightDirector.modifiers = {}
	end
	ReplicatedStorage:SetAttribute("Event", currentEvent and currentEvent.id)
	for _, session in Sessions.all() do
		applyEventBoost(session)
	end
end)

-- Whoever lands the final hit earns a little bounty.
NightDirector.creatureDefeated.Event:Connect(function(_runtime, byPlayer: Player?)
	local session = byPlayer and Sessions.get(byPlayer)
	if session then
		local eventBoost = if currentEvent then currentEvent.modifiers.reward or 1 else 1
		session:earn((Config.Creatures.bounty + World.night()) * eventBoost)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	World.tick(dt)
	NightDirector.tick(dt)
	TurretDirector.tick(dt, runtimes)
	for _, runtime in runtimes do
		runtime:tick(dt)
	end
end)
