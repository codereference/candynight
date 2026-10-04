-- Short messages from the server ("Unlocked Oven!", "You need $20 more!") stacked above the bottom of the screen.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Ui = require(script.Parent.Ui)

local Toasts = {}

local SHOW_SECONDS = 2.5
local holder: Frame

function Toasts.show(text: string, color: Color3?)
	local toast = Ui.new("Frame", {
		Size = UDim2.fromOffset(320, 44),
		BackgroundColor3 = color or Ui.PINK,
		Parent = holder,
	}, { Ui.corner(UDim.new(1, 0)), Ui.stroke() })
	Ui.label({ Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5), Text = text, Parent = toast })
	task.delay(SHOW_SECONDS, function()
		local fade = TweenService:Create(toast, TweenInfo.new(0.3), { BackgroundTransparency = 1 })
		for _, descendant in toast:GetDescendants() do
			if descendant:IsA("TextLabel") then
				TweenService:Create(descendant, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
			elseif descendant:IsA("UIStroke") then
				TweenService:Create(descendant, TweenInfo.new(0.3), { Transparency = 1 }):Play()
			end
		end
		fade.Completed:Connect(function()
			toast:Destroy()
		end)
		fade:Play()
	end)
end

function Toasts.mount(playerGui: Instance)
	local gui = Ui.screen("Toasts", playerGui, 10)
	holder = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -170), -- above the tutorial card and placement buttons
		Size = UDim2.fromOffset(320, 200),
		BackgroundTransparency = 1,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 6),
		Parent = holder,
	})
	Net.event("Notify").OnClientEvent:Connect(function(key: string, vars)
		Toasts.show(Strings.get(key, vars))
	end)
end

return Toasts
