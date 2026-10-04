-- Admin panel, only shown to admins. The server re-checks every command, so this is just buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local AdminPanel = {}

function AdminPanel.mount(playerGui: Instance)
	local player = Players.LocalPlayer
	local gui = Ui.screen("Admin", playerGui, 9)

	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -12, 0.5, 0),
		Size = UDim2.fromOffset(250, 470),
		BackgroundColor3 = Color3.fromRGB(50, 40, 70),
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 14)), Ui.stroke(Color3.fromRGB(255, 200, 60), 3) })
	Ui.new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = panel })
	Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = panel,
	})

	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	Ui.label({
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 30),
		Text = Strings.get("Admin.Title"),
		Parent = panel,
	})
	local targetBox = Ui.new("TextBox", {
		LayoutOrder = nextOrder(),
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundColor3 = Ui.WHITE,
		Font = Ui.FONT,
		TextScaled = true,
		PlaceholderText = Strings.get("Admin.Target"),
		Text = "",
		Parent = panel,
	}, { Ui.corner() })

	local function command(label: string, name: string, args: () -> { any })
		Ui.button({
			LayoutOrder = nextOrder(),
			Size = UDim2.new(1, 0, 0, 38),
			Text = label,
			BackgroundColor3 = Color3.fromRGB(110, 90, 160),
			Parent = panel,
		}, function()
			local ok, reason = Net.func("AdminCommand"):InvokeServer(name, args())
			Toasts.show(
				if ok then Strings.get("Admin.Done") else Strings.get("Admin.Failed", { reason = reason or "?" })
			)
		end)
	end
	local function who(): string
		return targetBox.Text
	end
	command(Strings.get("Admin.GiveCash", { cash = "$1K" }), "giveCash", function()
		return { who(), 1000 }
	end)
	command(Strings.get("Admin.GiveCash", { cash = "$1M" }), "giveCash", function()
		return { who(), 1000000 }
	end)
	command(Strings.get("Admin.SkipPhase"), "skipPhase", function()
		return {}
	end)
	command(Strings.get("Admin.Spawn"), "spawnCreatures", function()
		return { 5 }
	end)
	command(Strings.get("Admin.BloodMoon"), "forceEvent", function()
		return { "BloodMoon" }
	end)
	command(Strings.get("Admin.Streak"), "setStreak", function()
		return { who(), (player:GetAttribute("Streak") or 0) + 5 }
	end)
	command(Strings.get("Admin.RepairAll"), "repairAll", function()
		return {}
	end)
	command(Strings.get("Admin.Reset"), "resetData", function()
		return { who() }
	end)

	local opener = Ui.button({
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 60),
		Size = UDim2.fromOffset(110, 40),
		Text = Strings.get("Admin.Button"),
		BackgroundColor3 = Color3.fromRGB(255, 200, 60),
		Visible = false,
		Parent = gui,
	}, function()
		panel.Visible = not panel.Visible
	end)

	local function refresh()
		local isAdmin = player:GetAttribute("IsAdmin") == true
		opener.Visible = isAdmin
		if not isAdmin then
			panel.Visible = false
		end
	end
	player:GetAttributeChangedSignal("IsAdmin"):Connect(refresh)
	refresh()
end

return AdminPanel
