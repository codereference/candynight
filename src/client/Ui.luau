-- Shared look for all client UI: candy colours, rounded panels, chunky buttons.

local Ui = {}

Ui.PINK = Color3.fromRGB(255, 120, 160)
Ui.DEEP = Color3.fromRGB(150, 50, 90)
Ui.CREAM = Color3.fromRGB(255, 248, 235)
Ui.MINT = Color3.fromRGB(110, 210, 160)
Ui.GOLD = Color3.fromRGB(255, 240, 120)
Ui.WHITE = Color3.fromRGB(255, 255, 255)
Ui.NIGHT = Color3.fromRGB(70, 50, 110)
Ui.FONT = Enum.Font.FredokaOne

function Ui.new(className: string, props: { [string]: any }, children: { Instance }?): any
	local instance = Instance.new(className)
	for key, value in props do
		if key ~= "Parent" then
			(instance :: any)[key] = value
		end
	end
	if children then
		for _, child in children do
			child.Parent = instance
		end
	end
	instance.Parent = props.Parent
	return instance
end

function Ui.corner(radius: UDim?): UICorner
	return Ui.new("UICorner", { CornerRadius = radius or UDim.new(0, 12) })
end

function Ui.stroke(color: Color3?, thickness: number?): UIStroke
	return Ui.new("UIStroke", {
		Color = color or Ui.WHITE,
		Thickness = thickness or 3,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

-- White text with a soft outline.
function Ui.label(props: { [string]: any }): TextLabel
	local defaults = {
		BackgroundTransparency = 1,
		Font = Ui.FONT,
		TextColor3 = Ui.WHITE,
		TextScaled = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	local label = Ui.new("TextLabel", defaults)
	Ui.new("UIStroke", { Color = Ui.DEEP, Thickness = 2, Parent = label })
	return label
end

-- Chunky rounded button. Works with touch, mouse and gamepad via Activated.
function Ui.button(props: { [string]: any }, onActivated: () -> ()): TextButton
	local defaults = {
		BackgroundColor3 = Ui.PINK,
		Font = Ui.FONT,
		TextColor3 = Ui.WHITE,
		TextScaled = true,
		AutoButtonColor = true,
	}
	for key, value in props do
		defaults[key] = value
	end
	local button = Ui.new("TextButton", defaults, { Ui.corner(), Ui.stroke() })
	Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, 6),
		PaddingBottom = UDim.new(0, 6),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = button,
	})
	button.Activated:Connect(onActivated)
	return button
end

-- A ScreenGui that survives respawns.
function Ui.screen(name: string, parent: Instance, displayOrder: number?): ScreenGui
	return Ui.new("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = displayOrder or 0,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	})
end

return Ui
