-- Daily reward calendar: seven days of rewards, today's highlighted, opens on join when ready.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Daily = require(ReplicatedStorage.Shared.Rules.Daily)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Ui = require(script.Parent.Ui)

local DailyPanel = {}

function DailyPanel.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Daily", playerGui, 7)
	local days = #Config.Daily.rewards

	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromOffset(460, 250),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 18)), Ui.stroke(Ui.PINK, 4) })
	Ui.new("UISizeConstraint", { MaxSize = Vector2.new(460, 250), Parent = panel })
	Ui.label({
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, 40),
		Text = Strings.get("Daily.Title"),
		TextColor3 = Ui.PINK,
		Parent = panel,
	})
	local row = Ui.new("Frame", {
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.new(1, -24, 0, 110),
		BackgroundTransparency = 1,
		Parent = panel,
	})
	Ui.new("UIGridLayout", {
		CellSize = UDim2.new(1 / days, -6, 1, 0),
		CellPadding = UDim2.fromOffset(6, 0),
		Parent = row,
	})
	local tiles = {}
	for day = 1, days do
		local tile = Ui.new("Frame", { BackgroundColor3 = Ui.MINT, LayoutOrder = day, Parent = row }, { Ui.corner() })
		Ui.label({ Size = UDim2.fromScale(1, 0.4), Text = Strings.get("Daily.Day", { n = day }), Parent = tile })
		local reward = Ui.label({ Position = UDim2.fromScale(0, 0.45), Size = UDim2.fromScale(1, 0.5), Parent = tile })
		tiles[day] = { tile = tile, reward = reward }
	end

	local claim = Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, -80, 1, -12),
		Size = UDim2.fromOffset(150, 46),
		Text = Strings.get("Daily.Claim"),
		BackgroundColor3 = Ui.MINT,
		Parent = panel,
	}, function()
		Net.func("ClaimDaily"):InvokeServer()
		panel.Visible = false
	end)
	Ui.button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 80, 1, -12),
		Size = UDim2.fromOffset(150, 46),
		Text = Strings.get("Ui.Close"),
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = panel,
	}, function()
		panel.Visible = false
	end)

	local opener = Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, -66),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Daily.Button"),
		BackgroundColor3 = Color3.fromRGB(255, 170, 90),
		Parent = gui,
	}, function()
		panel.Visible = not panel.Visible
	end)

	local function refresh()
		local available = player:GetAttribute("DailyAvailable") == true
		local nextDay = player:GetAttribute("DailyNext") or 1
		local scale = player:GetAttribute("DailyScale") or 1
		for day, tile in tiles do
			tile.reward.Text = Format.cash(Daily.rewardFor(Config.Daily, day) * scale)
			local isNext = day == math.min(nextDay, days)
			tile.tile.BackgroundColor3 = if isNext and available
				then Ui.PINK
				elseif day < nextDay then Color3.fromRGB(180, 170, 190)
				else Ui.MINT
		end
		claim.Visible = available
		opener.Text = Strings.get(if available then "Daily.ButtonReady" else "Daily.Button")
	end
	for _, name in { "DailyAvailable", "DailyNext", "DailyScale" } do
		player:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()

	-- Pop open on join when there's something to claim.
	task.delay(3, function()
		if player:GetAttribute("DailyAvailable") then
			refresh()
			panel.Visible = true
		end
	end)
end

return DailyPanel
