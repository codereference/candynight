-- Awards badges as players reach milestones (checked every few seconds). Badge asset ids live in
-- Config.Badges; a 0 id still records and announces the badge but skips the Roblox award.

local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Badges = require(ReplicatedStorage.Shared.Rules.Badges)
local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Sessions = require(script.Parent.Sessions)

local Achievements = {}

local CHECK_SECONDS = 4

function Achievements.check(session)
	for _, key in Badges.award(session.profile) do
		session:notify("Badge.Earned", { name = Strings.get("Badge." .. key) })
		local badgeId = Config.Badges[key] or 0
		if badgeId ~= 0 then
			task.spawn(function()
				local ok, err = pcall(BadgeService.AwardBadge, BadgeService, session.player.UserId, badgeId)
				if not ok then
					warn("[Badges] couldn't award", key, err)
				end
			end)
		end
	end
end

function Achievements.start()
	task.spawn(function()
		while true do
			task.wait(CHECK_SECONDS)
			for _, session in Sessions.all() do
				Achievements.check(session)
			end
		end
	end)
end

return Achievements
