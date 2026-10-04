-- Night UI: the "scared away" meter while it's night, the streak badge, and the result card at dawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Ui = require(script.Parent.Ui)

local NightHud = {}

local function resultCard(gui: ScreenGui, result)
	local card = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.42),
		Size = UDim2.fromOffset(340, 190),
		BackgroundColor3 = if result.survived then Ui.MINT else Ui.NIGHT,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 20)), Ui.stroke(Ui.WHITE, 4) })
	local scale = Ui.new("UIScale", { Scale = 0.2, Parent = card })
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()

	Ui.label({
		Size = UDim2.new(1, -24, 0, 48),
		Position = UDim2.fromOffset(12, 12),
		Text = Strings.get(if result.survived then "Night.Survived" else "Night.Failed"),
		Parent = card,
	})
	local detail = if result.survived
		then Strings.get("Night.SurvivedDetail", { streak = result.streak })
		else Strings.get("Night.FailedDetail", { cash = Format.cash(result.cashLost), broken = result.broken })
	Ui.label({
		Size = UDim2.new(1, -24, 0, 70),
		Position = UDim2.fromOffset(12, 64),
		Text = detail,
		TextWrapped = true,
		Parent = card,
	})
	Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.fromOffset(150, 40),
		Text = Strings.get("Ui.Ok"),
		Parent = card,
	}, function()
		card:Destroy()
	end)
	task.delay(8, function()
		if card.Parent then
			card:Destroy()
		end
	end)
end

function NightHud.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("NightHud", playerGui, 5)

	local streak = Ui.new("Frame", {
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.fromOffset(130, 34),
		BackgroundColor3 = Color3.fromRGB(255, 160, 80),
		Parent = gui,
	}, { Ui.corner(UDim.new(1, 0)), Ui.stroke() })
	local streakText = Ui.label({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Parent = streak })

	local meter = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 110),
		Size = UDim2.fromOffset(230, 36),
		BackgroundColor3 = Ui.NIGHT,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(1, 0)), Ui.stroke() })
	local meterText = Ui.label({ Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Parent = meter })

	local function refresh()
		streakText.Text = Strings.get("Night.Streak", { n = player:GetAttribute("Streak") or 0 })
		local lost, allowed = player:GetAttribute("NightLost"), player:GetAttribute("NightAllowed")
		meter.Visible = lost ~= nil
		if lost ~= nil then
			meterText.Text = Strings.get("Night.Meter", { lost = lost, allowed = allowed })
			meter.BackgroundColor3 = if lost > allowed then Color3.fromRGB(220, 70, 90) else Ui.NIGHT
		end
	end
	for _, name in { "Streak", "NightLost", "NightAllowed" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	Net.event("NightResult").OnClientEvent:Connect(function(result)
		resultCard(gui, result)
	end)
end

return NightHud
