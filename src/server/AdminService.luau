-- Admin commands for owners/admins. Every request is authorized and validated on the server
-- (see Admin rules) before it runs; the client panel is only a convenience.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Admin = require(ReplicatedStorage.Shared.Rules.Admin)
local Config = require(ReplicatedStorage.Shared.Config)
local Net = require(ReplicatedStorage.Shared.Net)
local Profile = require(ReplicatedStorage.Shared.Persistence.Profile)
local Strings = require(ReplicatedStorage.Shared.Strings)
local NightDirector = require(script.Parent.NightDirector)
local Sessions = require(script.Parent.Sessions)
local World = require(script.Parent.World)

local AdminService = {}

-- Set by forceEvent; the night handler uses it once.
AdminService.forcedEvent = nil :: string?

local function adminIds(): { number }
	local ids = table.clone(Config.Monetization.ownerIds)
	for _, id in Config.Admin.extraIds do
		table.insert(ids, id)
	end
	return ids
end

local function findTarget(admin: Player, who: string): Player?
	if who == "me" then
		return admin
	end
	local lower = who:lower()
	for _, player in Players:GetPlayers() do
		if player.Name:lower() == lower or player.DisplayName:lower() == lower then
			return player
		end
	end
	return nil
end

local function run(admin: Player, name: string, args, runtimeOf): (boolean, string?)
	if name == "skipPhase" then
		World.skip()
	elseif name == "forceEvent" then
		AdminService.forcedEvent = args[1]
	elseif name == "spawnCreatures" then
		if not World.isNight() then
			return false, "night"
		end
		local runtime = runtimeOf(admin)
		if runtime == nil then
			return false, "target"
		end
		NightDirector.spawnAt(runtime, args[1])
	elseif name == "repairAll" then
		local runtime = runtimeOf(admin)
		if runtime then
			runtime:repairAll()
		end
	else
		local target = findTarget(admin, args[1])
		local session = target and Sessions.get(target)
		if session == nil then
			return false, "target"
		end
		if name == "giveCash" then
			session:earn(args[2])
		elseif name == "setStreak" then
			session.profile.streak = args[2]
			session.profile.bestStreak = math.max(session.profile.bestStreak, args[2])
			target:SetAttribute("Streak", args[2])
		elseif name == "resetData" then
			-- Replace the profile's contents with a fresh one, then send them off to rejoin.
			local fresh = Profile.defaults()
			for key in session.profile do
				session.profile[key] = nil
			end
			for key, value in fresh do
				session.profile[key] = value
			end
			session.wallet:spend(session.wallet:getCash())
			target:Kick(Strings.get("Admin.ResetKick"))
		end
	end
	return true, nil
end

function AdminService.start(runtimeOf: (Player) -> any)
	Sessions.started.Event:Connect(function(session)
		session.player:SetAttribute("IsAdmin", Admin.isAdmin(adminIds(), session.player.UserId))
	end)

	Net.func("AdminCommand").OnServerInvoke = function(player, name, args)
		if not Admin.isAdmin(adminIds(), player.UserId) then
			warn(`[Admin] refused {player.Name} ({player.UserId}): not an admin`)
			return false, "denied"
		end
		local clean, reason = Admin.validate(name, args)
		if clean == nil then
			return false, reason
		end
		return run(player, name, clean, runtimeOf)
	end
end

return AdminService
