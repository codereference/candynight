-- Retention rewards: daily login streak (and, later, codes and group/friend bonuses).
-- Publishes DailyAvailable / DailyNext player attributes so the client can show the calendar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Codes = require(ReplicatedStorage.Shared.Rules.Codes)
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

local lastCodeTry: { [Player]: number } = {}
local CODE_COOLDOWN = 2 -- seconds between attempts, so codes can't be brute-forced

function Rewards.redeemCode(session, text: string): (boolean, string?)
	local now = os.clock()
	if now - (lastCodeTry[session.player] or 0) < CODE_COOLDOWN then
		return false, "slow"
	end
	lastCodeTry[session.player] = now
	local entry, reason = Codes.redeem(Config.Codes, session.profile.codes, text, os.time())
	if entry == nil then
		return false, reason
	end
	local amount = session:earn(entry.cash)
	session:notify("Codes.Redeemed", { cash = Format.cash(amount) })
	return true, nil
end

function Rewards.start()
	Net.func("RedeemCode").OnServerInvoke = function(player, text)
		local session = Sessions.get(player)
		if session == nil or type(text) ~= "string" or #text > 40 then
			return false, "invalid"
		end
		return Rewards.redeemCode(session, text)
	end
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastCodeTry[player] = nil
	end)
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
