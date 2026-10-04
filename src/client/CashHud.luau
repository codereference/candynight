-- Cash pill at the top of the screen, with a "+$5" popup and a little bounce whenever cash goes up.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Strings = require(ReplicatedStorage.Shared.Strings)

local CashHud = {}

local PINK = Color3.fromRGB(255, 120, 160)
local WHITE = Color3.fromRGB(255, 255, 255)

local function label(parent: Instance, text: string): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = WHITE
	l.TextScaled = true
	l.Text = text
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 50, 90)
	stroke.Thickness = 2
	stroke.Parent = l
	l.Parent = parent
	return l
end

function CashHud.mount(playerGui: Instance, cash: IntValue, format: (number) -> string)
	local gui = Instance.new("ScreenGui")
	gui.Name = "CashHud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local pill = Instance.new("Frame")
	pill.AnchorPoint = Vector2.new(0.5, 0)
	pill.Position = UDim2.new(0.5, 0, 0, 10)
	pill.Size = UDim2.fromOffset(190, 52)
	pill.BackgroundColor3 = PINK
	pill.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = pill
	local border = Instance.new("UIStroke")
	border.Color = WHITE
	border.Thickness = 3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = pill
	local bounce = Instance.new("UIScale")
	bounce.Parent = pill

	local amount = label(pill, format(cash.Value))
	amount.Size = UDim2.new(1, -24, 1, -12)
	amount.Position = UDim2.fromOffset(12, 6)

	-- Income boost badge hanging off the cash pill (rebirths, passes, group, friends, events).
	local boost = label(pill, "")
	boost.AnchorPoint = Vector2.new(0, 0.5)
	boost.Position = UDim2.new(1, 8, 0.5, 0)
	boost.Size = UDim2.fromOffset(80, 30)
	boost.TextXAlignment = Enum.TextXAlignment.Left
	local player = game:GetService("Players").LocalPlayer
	local function refreshBoost()
		local multiplier = player:GetAttribute("Multiplier") or 1
		boost.Visible = multiplier > 1.001
		boost.Text =
			Strings.get("Bonus.Boost", { mult = string.format("%.2f", multiplier):gsub("0+$", ""):gsub("%.$", "") })
	end
	player:GetAttributeChangedSignal("Multiplier"):Connect(refreshBoost)
	refreshBoost()

	local shown = cash.Value
	cash.Changed:Connect(function(value)
		local gained = value - shown
		shown = value
		amount.Text = format(value)
		if gained <= 0 then
			return
		end

		bounce.Scale = 1.12
		TweenService:Create(bounce, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()

		local popup = label(gui, "+" .. format(gained))
		popup.AnchorPoint = Vector2.new(0.5, 0)
		popup.Size = UDim2.fromOffset(120, 34)
		popup.Position = UDim2.new(0.5, 0, 0, 150)
		popup.TextColor3 = Color3.fromRGB(255, 240, 120)
		local drift = TweenService:Create(popup, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, 0, 0, 190),
			TextTransparency = 1,
		})
		TweenService:Create(popup:FindFirstChildWhichIsA("UIStroke"), TweenInfo.new(0.9), { Transparency = 1 }):Play()
		drift.Completed:Connect(function()
			popup:Destroy()
		end)
		drift:Play()
	end)
end

return CashHud
