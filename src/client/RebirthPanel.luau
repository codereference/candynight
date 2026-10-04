-- Rebirth button and confirmation: shows the cost, the income boost, and what resets vs. what's kept.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Rebirth = require(ReplicatedStorage.Shared.Rules.Rebirth)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local RebirthPanel = {}

function RebirthPanel.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Rebirth", playerGui, 6)

	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 260),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 18)), Ui.stroke(Ui.PINK, 4) })
	local function text(y: number, height: number, color: Color3?): TextLabel
		return Ui.label({
			Position = UDim2.fromOffset(14, y),
			Size = UDim2.new(1, -28, 0, height),
			TextColor3 = color or Ui.PINK,
			TextWrapped = true,
			Parent = panel,
		})
	end
	local title = text(12, 40)
	local boost = text(56, 30, Ui.MINT)
	local cost = text(88, 28, Color3.fromRGB(240, 170, 60))
	local resets = text(120, 64, Ui.DEEP)
	resets.Text = Strings.get("Rebirth.Resets")

	local function refresh()
		local rebirths = player:GetAttribute("Rebirths") or 0
		title.Text = Strings.get("Rebirth.Title", { n = rebirths + 1 })
		boost.Text = Strings.get("Rebirth.Boost", {
			from = string.format("%.1f", Rebirth.multiplier(Config.Rebirth, rebirths)),
			to = string.format("%.1f", Rebirth.multiplier(Config.Rebirth, rebirths + 1)),
		})
		cost.Text = Strings.get("Rebirth.Cost", { cash = Format.cash(Rebirth.cost(Config.Rebirth, rebirths)) })
	end

	Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 14, 1, -14),
		Size = UDim2.fromOffset(150, 46),
		Text = Strings.get("Rebirth.Confirm"),
		BackgroundColor3 = Ui.MINT,
		Parent = panel,
	}, function()
		panel.Visible = false
		local ok, reason = Net.func("Rebirth"):InvokeServer()
		if not ok then
			Toasts.show(Strings.get("Reason." .. (reason or "unknown")))
		end
	end)
	Ui.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -14, 1, -14),
		Size = UDim2.fromOffset(150, 46),
		Text = Strings.get("Ui.Cancel"),
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = panel,
	}, function()
		panel.Visible = false
	end)

	Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, -118),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Rebirth.Button"),
		BackgroundColor3 = Color3.fromRGB(170, 130, 240),
		Parent = gui,
	}, function()
		refresh()
		panel.Visible = not panel.Visible
	end)
end

return RebirthPanel
