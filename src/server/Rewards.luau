-- Retention rewards: daily login streak (and, later, codes and group/friend bonuses).
-- Publishes DailyAvailable / DailyNext player attributes so the client can show the calendar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Daily = require(ReplicatedStorage.Shared.Rules.Daily)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Rebirth = require(ReplicatedStorage.Shared.Rules.Rebirth)
local Sessions = require(script.Parent.Sessions)

local Rewards = {}

local function today(): number
	return Daily.today(os.time())
end

-- Rewards grow with rebirths so they stay worth claiming.
local function scaled(session, amount: number): number
	return math.floor(amount * Rebirth.multiplier(Config.Rebirth, session.profile.rebirths))
end

function Rewards.publishDaily(session)
	local state = session.profile.daily
	session.player:SetAttribute("DailyAvailable", Daily.canClaim(state, today()))
	session.player:SetAttribute("DailyNext", Daily.nextStreak(state, today()))
	session.player:SetAttribute("DailyScale", Rebirth.multiplier(Config.Rebirth, session.profile.rebirths))
end

function Rewards.claimDaily(session): number?
	local reward = Daily.claim(Config.Daily, session.profile.daily, today())
	if reward == nil then
		return nil
	end
	local amount = session:earn(scaled(session, reward))
	session:notify("Daily.Claimed", { cash = Format.cash(amount), day = session.profile.daily.streak })
	Rewards.publishDaily(session)
	return amount
end

function Rewards.start()
	Sessions.started.Event:Connect(Rewards.publishDaily)
	Net.func("ClaimDaily").OnServerInvoke = function(player)
		local session = Sessions.get(player)
		return session and Rewards.claimDaily(session)
	end
	-- A new day can start while people are playing.
	task.spawn(function()
		while true do
			task.wait(60)
			for _, session in Sessions.all() do
				Rewards.publishDaily(session)
			end
		end
	end)
end

return Rewards
