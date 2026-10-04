-- Codes entry: a text box and a Redeem button. The server does all the checking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local CodesPanel = {}

function CodesPanel.mount(playerGui: Instance)
	local gui = Ui.screen("Codes", playerGui, 7)
	local panel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.45),
		Size = UDim2.fromOffset(320, 190),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 18)), Ui.stroke(Ui.PINK, 4) })
	Ui.label({
		Position = UDim2.fromOffset(12, 10),
		Size = UDim2.new(1, -24, 0, 36),
		Text = Strings.get("Codes.Title"),
		TextColor3 = Ui.PINK,
		Parent = panel,
	})
	local box = Ui.new("TextBox", {
		Position = UDim2.fromOffset(16, 56),
		Size = UDim2.new(1, -32, 0, 50),
		BackgroundColor3 = Ui.WHITE,
		Font = Ui.FONT,
		TextScaled = true,
		TextColor3 = Ui.DEEP,
		PlaceholderText = Strings.get("Codes.Placeholder"),
		Text = "",
		ClearTextOnFocus = false,
		Parent = panel,
	}, { Ui.corner(), Ui.stroke(Ui.PINK, 2) })

	local function redeem()
		local text = box.Text
		if text == "" then
			return
		end
		local ok, reason = Net.func("RedeemCode"):InvokeServer(text)
		if ok then
			box.Text = ""
			panel.Visible = false
		else
			Toasts.show(Strings.get("Codes.Reason." .. (reason or "invalid")))
		end
	end
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			redeem()
		end
	end)
	Ui.button({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 16, 1, -12),
		Size = UDim2.fromOffset(136, 46),
		Text = Strings.get("Codes.Redeem"),
		BackgroundColor3 = Ui.MINT,
		Parent = panel,
	}, redeem)
	Ui.button({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -12),
		Size = UDim2.fromOffset(136, 46),
		Text = Strings.get("Ui.Close"),
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = panel,
	}, function()
		panel.Visible = false
	end)

	Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, -14),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Codes.Button"),
		BackgroundColor3 = Color3.fromRGB(120, 180, 255),
		Parent = gui,
	}, function()
		panel.Visible = not panel.Visible
	end)
end

return CodesPanel
