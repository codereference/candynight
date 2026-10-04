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

World.phaseChanged.Event:Connect(function(phase, night)
	if phase == "Night" then
		NightDirector.startNight(runtimes, night)
	else
		NightDirector.endNight(runtimes)
	end
end)

-- Whoever lands the final hit earns a little bounty.
NightDirector.creatureDefeated.Event:Connect(function(_runtime, byPlayer: Player?)
	local session = byPlayer and Sessions.get(byPlayer)
	if session then
		session:earn(Config.Creatures.bounty + World.night())
	end
end)

RunService.Heartbeat:Connect(function(dt)
	World.tick(dt)
	NightDirector.tick(dt)
	for _, runtime in runtimes do
		runtime:tick(dt)
	end
end)
