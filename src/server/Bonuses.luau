-- Social income boosts: being in the game's Roblox group, and playing with friends in the same
-- server. Sets session.factors.inGroup / .friends (see Income) and refreshes the multiplier.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Sessions = require(script.Parent.Sessions)

local Bonuses = {}

local friendships: { [string]: boolean } = {} -- "lowId:highId" -> are they friends

local function pairKey(a: number, b: number): string
	return if a < b then a .. ":" .. b else b .. ":" .. a
end

local function areFriends(a: Player, b: Player): boolean
	local key = pairKey(a.UserId, b.UserId)
	if friendships[key] == nil then
		local ok, result = pcall(a.IsFriendsWithAsync, a, b.UserId)
		friendships[key] = ok and result == true
	end
	return friendships[key]
end

local function recountFriends()
	local sessions = table.clone(Sessions.all()) -- friend checks yield; don't walk the live table
	for _, session in sessions do
		local count = 0
		for _, other in sessions do
			if other ~= session and areFriends(session.player, other.player) then
				count += 1
			end
		end
		if Sessions.get(session.player) ~= session then
			continue -- left while we were checking
		end
		local before = session.factors.friends or 0
		session.factors.friends = count
		session:refreshMultiplier()
		if count > before then
			session:notify("Bonus.Friend", { pct = math.round(Config.Income.friendBonus * 100 * count) })
		end
	end
end

local function checkGroup(session)
	local groupId = Config.Group.id
	if groupId == 0 then
		return
	end
	local ok, inGroup = pcall(session.player.IsInGroup, session.player, groupId)
	session.factors.inGroup = ok and inGroup == true
	session:refreshMultiplier()
	session:notify(if session.factors.inGroup then "Bonus.Group" else "Bonus.JoinGroup")
end

function Bonuses.start()
	Sessions.started.Event:Connect(function(session)
		task.spawn(checkGroup, session)
		task.spawn(recountFriends)
	end)
	Players.PlayerRemoving:Connect(function()
		task.defer(recountFriends) -- after the leaving session is gone
	end)
end

return Bonuses
