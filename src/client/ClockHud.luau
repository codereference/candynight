-- Phase pill next to the cash: "☀️ Day 2  1:23" / "🌙 Night 2  0:45".

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Strings = require(ReplicatedStorage.Shared.Strings)
local Atmosphere = require(script.Parent.Atmosphere)
local Ui = require(script.Parent.Ui)

local ClockHud = {}

function ClockHud.mount(playerGui: Instance)
	local gui = Ui.screen("ClockHud", playerGui)
	local pill = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 68),
		Size = UDim2.fromOffset(190, 36),
		BackgroundColor3 = Ui.MINT,
		Parent = gui,
	}, { Ui.corner(UDim.new(1, 0)), Ui.stroke() })
	local text = Ui.label({ Size = UDim2.new(1, -20, 1, -8), Position = UDim2.fromOffset(10, 4), Parent = pill })

	local lastShown = ""
	RunService.Heartbeat:Connect(function()
		local phase = ReplicatedStorage:GetAttribute("Phase") or "Day"
		local night = ReplicatedStorage:GetAttribute("Night") or 0
		local left = math.ceil((Atmosphere.phaseTime()))
		local clock = string.format("%d:%02d", left // 60, left % 60)
		local shown = if phase == "Day"
			then Strings.get("Clock.Day", { n = night + 1, time = clock })
			else Strings.get("Clock.Night", { n = night, time = clock })
		if shown ~= lastShown then
			lastShown = shown
			text.Text = shown
			pill.BackgroundColor3 = if phase == "Day" then Ui.MINT else Ui.NIGHT
		end
	end)
end

return ClockHud
