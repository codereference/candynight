-- Tutorial tips: a card with what to do next and a bouncing arrow over where to do it.
-- Driven entirely by the TutorialStep attribute the server sets.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Ui = require(script.Parent.Ui)

local Onboarding = {}

-- Where the arrow points for each step (a part in the player's plot), or nil for UI-only steps.
local function targetFor(step: string, plot: Instance?): BasePart?
	if plot == nil then
		return nil
	end
	local buttons = plot:FindFirstChild("Buttons")
	if step == "Serve" then
		return plot:FindFirstChild("Counter") :: BasePart?
	elseif step == "BuyTray" then
		return buttons and buttons:FindFirstChild("CupcakeTray") :: BasePart?
	elseif step == "Hire" then
		return buttons and (buttons:FindFirstChild("Staff1") or buttons:FindFirstChildWhichIsA("BasePart")) :: BasePart?
	elseif step == "BuyMore" then
		return buttons and buttons:FindFirstChildWhichIsA("BasePart") :: BasePart?
	end
	return nil
end

function Onboarding.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Tutorial", playerGui, 3)

	local card = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -90),
		Size = UDim2.fromOffset(420, 70),
		BackgroundColor3 = Ui.WHITE,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 14)), Ui.stroke(Ui.PINK, 3) })
	Ui.new("UISizeConstraint", { MaxSize = Vector2.new(420, 70), Parent = card })
	local tip = Ui.label({
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -110, 1, -12),
		TextColor3 = Ui.DEEP,
		TextWrapped = true,
		Parent = card,
	})
	Ui.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(90, 40),
		Text = Strings.get("Tutorial.Skip"),
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = card,
	}, function()
		Net.func("SkipTutorial"):InvokeServer()
	end)

	local arrow = Ui.new("BillboardGui", {
		Size = UDim2.fromOffset(60, 60),
		AlwaysOnTop = true,
		Enabled = false,
		Parent = gui,
	})
	Ui.new("TextLabel", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		TextScaled = true,
		Text = "👇",
		Parent = arrow,
	})

	local function refresh()
		local step = player:GetAttribute("TutorialStep")
		card.Visible = step ~= nil
		if step then
			tip.Text = Strings.get("Tutorial." .. step)
		end
	end
	player:GetAttributeChangedSignal("TutorialStep"):Connect(refresh)
	refresh()

	RunService.Heartbeat:Connect(function()
		local step = player:GetAttribute("TutorialStep")
		local index = player:GetAttribute("PlotIndex")
		local target = step and targetFor(step, index and workspace:FindFirstChild("Plot" .. index))
		arrow.Enabled = target ~= nil
		if target then
			arrow.Adornee = target
			arrow.StudsOffsetWorldSpace = Vector3.new(0, 4 + math.abs(math.sin(os.clock() * 4)) * 1.5, 0)
		end
	end)
end

return Onboarding
