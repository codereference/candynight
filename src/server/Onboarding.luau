-- Guided first day: advances each player's tutorial from their real progress and publishes the
-- current step as the TutorialStep player attribute for the client's tips and arrow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Tutorial = require(ReplicatedStorage.Shared.Rules.Tutorial)
local Sessions = require(script.Parent.Sessions)

local Onboarding = {}

local function update(session)
	local state = session.profile.tutorial
	Tutorial.advance(state, session.profile)
	local step = Tutorial.current(state)
	if session.player:GetAttribute("TutorialStep") ~= step then
		session.player:SetAttribute("TutorialStep", step)
	end
end

function Onboarding.start()
	Sessions.started.Event:Connect(update)
	Net.func("SkipTutorial").OnServerInvoke = function(player)
		local session = Sessions.get(player)
		if session then
			Tutorial.skip(session.profile.tutorial)
			update(session)
		end
		return true
	end
	task.spawn(function()
		while true do
			task.wait(1)
			for _, session in Sessions.all() do
				update(session)
			end
		end
	end)
end

return Onboarding
