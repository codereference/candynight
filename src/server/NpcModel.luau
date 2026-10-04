-- Cute placeholder NPCs (customers, staff) built from parts. Origin is at ground level, facing -Z.
-- Parts are anchored and non-colliding; callers move the whole model with PivotTo.

local NpcModel = {}

NpcModel.BODY_HEIGHT = 2.6

NpcModel.PASTELS = {
	Color3.fromRGB(255, 179, 186),
	Color3.fromRGB(255, 223, 186),
	Color3.fromRGB(186, 255, 201),
	Color3.fromRGB(186, 225, 255),
	Color3.fromRGB(221, 190, 255),
}

-- options: { color: Color3, chefHat: boolean?, bubble: string? }
function NpcModel.make(name: string, options): Model
	local height = NpcModel.BODY_HEIGHT
	local model = Instance.new("Model")
	model.Name = name

	local function part(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Material = Enum.Material.SmoothPlastic
		for key, value in props do
			(p :: any)[key] = value
		end
		p.Parent = model
		return p
	end

	local body = part({
		Name = "Body",
		Size = Vector3.new(2, height, 1.4),
		CFrame = CFrame.new(0, height / 2, 0),
		Color = options.color,
	})
	part({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(0, height + 0.9, 0),
		Color = Color3.fromRGB(255, 220, 190),
	})
	for _, x in { -0.4, 0.4 } do
		part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.35, 0.35, 0.35),
			CFrame = CFrame.new(x, height + 1.05, -0.9),
			Color = Color3.fromRGB(40, 30, 40),
		})
	end
	if options.chefHat then
		part({
			Name = "Hat",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.4, 1.6, 1.6),
			CFrame = CFrame.new(0, height + 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(255, 255, 255),
		})
	end
	model.PrimaryPart = body

	if options.bubble then
		local bubble = Instance.new("BillboardGui")
		bubble.Name = "Bubble"
		bubble.Size = UDim2.fromOffset(40, 40)
		bubble.StudsOffsetWorldSpace = Vector3.new(0, height + 3, 0)
		bubble.Adornee = body
		bubble.Parent = body
		local label = Instance.new("TextLabel")
		label.Name = "Text"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = options.bubble
		label.TextScaled = true
		label.Parent = bubble
	end

	return model
end

-- The model pivot (body centre) for a ground-level CFrame.
function NpcModel.pivotFor(ground: CFrame): CFrame
	return ground * CFrame.new(0, NpcModel.BODY_HEIGHT / 2, 0)
end

-- Changes the emoji in the speech bubble, if there is one.
function NpcModel.setBubble(model: Model, text: string)
	local bubble = model:FindFirstChild("Bubble", true)
	if bubble then
		(bubble :: any).Text.Text = text
	end
end

return NpcModel
