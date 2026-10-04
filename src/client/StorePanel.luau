-- The Sweet Store: gamepasses (and boosts). Purchases go through Roblox's own prompt; the server
-- grants perks when Roblox confirms the purchase.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local StorePanel = {}

local function sortedKeys(entries): { string }
	local keys = {}
	for key in entries do
		table.insert(keys, key)
	end
	table.sort(keys, function(a, b)
		return entries[a].order < entries[b].order
	end)
	return keys
end

-- A store row: title, description, and a buy button. Returns the button.
function StorePanel.row(list: Instance, order: number, title: string, info: string, onBuy: () -> ()): TextButton
	local row = Ui.new("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, -8, 0, 74),
		BackgroundColor3 = Ui.WHITE,
		Parent = list,
	}, { Ui.corner() })
	Ui.label({
		Position = UDim2.fromOffset(10, 6),
		Size = UDim2.new(1, -130, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.PINK,
		Text = title,
		Parent = row,
	})
	Ui.label({
		Position = UDim2.fromOffset(10, 38),
		Size = UDim2.new(1, -130, 0, 30),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Ui.DEEP,
		TextWrapped = true,
		Text = info,
		Parent = row,
	})
	return Ui.button({
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(108, 46),
		Text = Strings.get("Store.Buy"),
		BackgroundColor3 = Ui.MINT,
		Parent = row,
	}, onBuy)
end

function StorePanel.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Store", playerGui, 7)
	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0.9, 0, 0.8, 0),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 18)), Ui.stroke(Ui.PINK, 4) })
	Ui.new("UISizeConstraint", { MaxSize = Vector2.new(480, 520), Parent = panel })
	Ui.label({
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -70, 0, 40),
		Text = Strings.get("Store.Title"),
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
	Ui.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	StorePanel.list = list

	local passes = Config.Monetization.passes
	for _, passKey in sortedKeys(passes) do
		local pass = passes[passKey]
		local button = StorePanel.row(
			list,
			pass.order,
			Strings.get("Pass." .. passKey),
			Strings.get("PassInfo." .. passKey),
			function()
				if player:GetAttribute("Pass_" .. passKey) then
					return
				elseif pass.id == 0 then
					Toasts.show(Strings.get("Store.Soon"))
				else
					MarketplaceService:PromptGamePassPurchase(player, pass.id)
				end
			end
		)
		local function refresh()
			local owned = player:GetAttribute("Pass_" .. passKey) == true
			button.Text = Strings.get(if owned then "Store.Owned" else "Store.Buy")
			button.BackgroundColor3 = if owned then Color3.fromRGB(180, 170, 190) else Ui.MINT
		end
		player:GetAttributeChangedSignal("Pass_" .. passKey):Connect(refresh)
		refresh()
	end

	Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 38),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Store.Button"),
		BackgroundColor3 = Color3.fromRGB(255, 200, 60),
		Parent = gui,
	}, function()
		panel.Visible = not panel.Visible
	end)
end

return StorePanel
