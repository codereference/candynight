-- Style panel: shop themes, weapon skins and trails. Shows what's worn, what's buyable with cash,
-- and what comes with a pass. The server owns every purchase and equip.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local StylePanel = {}

local CATALOG = Config.Cosmetics
local SLOTS = { "theme", "skin", "trail" }
local LOCK_TEXT = { vip = "Style.NeedsVIP", sweetStyle = "Style.NeedsSweetStyle" }

function StylePanel.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Style", playerGui, 7)
	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.8, 0),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 18)), Ui.stroke(Ui.PINK, 4) })
	Ui.new("UISizeConstraint", { MaxSize = Vector2.new(480, 560), Parent = panel })
	Ui.label({
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -70, 0, 40),
		Text = Strings.get("Style.Title"),
		TextColor3 = Ui.PINK,
		Parent = panel,
	})
	Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 10),
		Size = UDim2.fromOffset(44, 44),
		Text = "✕",
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = panel,
	}, function()
		panel.Visible = false
	end)
	local list = Ui.new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 60),
		Size = UDim2.new(1, -24, 1, -72),
		BackgroundTransparency = 1,
		ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = panel,
	})
	Ui.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })

	local ids = {}
	for id in CATALOG do
		table.insert(ids, id)
	end
	table.sort(ids, function(a, b)
		return CATALOG[a].order < CATALOG[b].order
	end)

	local refreshers = {}
	for slotIndex, slot in SLOTS do
		Ui.label({
			LayoutOrder = slotIndex * 100,
			Size = UDim2.new(1, -8, 0, 32),
			TextColor3 = Ui.DEEP,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Strings.get("Style." .. slot),
			Parent = list,
		})
		for _, id in ids do
			local entry = CATALOG[id]
			if entry.slot ~= slot then
				continue
			end
			local row = Ui.new("Frame", {
				LayoutOrder = slotIndex * 100 + entry.order,
				Size = UDim2.new(1, -8, 0, 52),
				BackgroundColor3 = Ui.WHITE,
				Parent = list,
			}, { Ui.corner() })
			Ui.label({
				Position = UDim2.fromOffset(10, 8),
				Size = UDim2.new(1, -150, 1, -16),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Ui.PINK,
				Text = Strings.get("Cosmetic." .. id),
				Parent = row,
			})
			local button = Ui.button({
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(130, 42),
				Parent = row,
			}, function()
				local owned = player:GetAttribute("Cos_" .. id) == true
				local remote = if owned then "EquipCosmetic" else "BuyCosmetic"
				local ok, reason = Net.func(remote):InvokeServer(id)
				if not ok and reason then
					Toasts.show(Strings.get("Style.Reason." .. reason))
				end
			end)
			table.insert(refreshers, function()
				local owned = player:GetAttribute("Cos_" .. id) == true
				local wearing = player:GetAttribute("Wear_" .. slot) == id
				button.Text = if wearing
					then Strings.get("Style.Equipped")
					elseif owned then Strings.get("Style.Equip")
					elseif entry.cost then Format.cash(entry.cost)
					else Strings.get(LOCK_TEXT[entry.perk])
				button.BackgroundColor3 = if wearing
					then Color3.fromRGB(180, 170, 190)
					elseif owned or entry.cost then Ui.MINT
					else Color3.fromRGB(190, 160, 230)
			end)
		end
	end

	local function refreshAll()
		for _, refresh in refreshers do
			refresh()
		end
	end
	player.AttributeChanged:Connect(function(name)
		if name:sub(1, 4) == "Cos_" or name:sub(1, 5) == "Wear_" then
			refreshAll()
		end
	end)
	refreshAll()

	Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 90),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Style.Button"),
		BackgroundColor3 = Color3.fromRGB(255, 140, 200),
		Parent = gui,
	}, function()
		panel.Visible = not panel.Visible
	end)
end

return StylePanel
