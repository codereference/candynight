-- "Welcome back!" popup with what staff earned while the player was away.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Ui = require(script.Parent.Ui)

local WelcomeBack = {}

local function duration(seconds: number): string
	local hours, minutes = seconds // 3600, (seconds % 3600) // 60
	return if hours > 0 then string.format("%dh %dm", hours, minutes) else string.format("%dm", minutes)
end

function WelcomeBack.mount(playerGui: Instance)
	local gui = Ui.screen("WelcomeBack", playerGui, 8)
	Net.event("OfflineEarnings").OnClientEvent:Connect(function(amount: number, seconds: number)
		local card = Ui.new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromOffset(340, 200),
			BackgroundColor3 = Ui.MINT,
			Parent = gui,
		}, { Ui.corner(UDim.new(0, 20)), Ui.stroke(Ui.WHITE, 4) })
		local scale = Ui.new("UIScale", { Scale = 0.2, Parent = card })
		TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		Ui.label({
			Position = UDim2.fromOffset(12, 12),
			Size = UDim2.new(1, -24, 0, 44),
			Text = Strings.get("Offline.Title"),
			Parent = card,
		})
		Ui.label({
			Position = UDim2.fromOffset(12, 60),
			Size = UDim2.new(1, -24, 0, 70),
			TextWrapped = true,
			Text = Strings.get("Offline.Body", { time = duration(seconds), cash = Format.cash(amount) }),
			Parent = card,
		})
		Ui.button({
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.fromOffset(170, 46),
			Text = Strings.get("Offline.Collect"),
			BackgroundColor3 = Ui.PINK,
			Parent = card,
		}, function()
			card:Destroy()
			Net.func("CollectOffline"):InvokeServer()
		end)
	end)
end

return WelcomeBack
