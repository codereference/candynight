-- Shadow creatures in the world: soft purple blobs with big glowing eyes. Spooky-cute, never gory.
-- Defeated creatures burst into candy sprinkles.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CreatureView = {}

local BODY = Color3.fromRGB(70, 40, 105)
local EYES = Color3.fromRGB(255, 240, 120)
CreatureView.HOVER = 2.4 -- body centre height above the ground

function CreatureView.make(id: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Shadow" .. id

	local function part(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.Shape = Enum.PartType.Ball
		p.Material = Enum.Material.SmoothPlastic
		for key, value in props do
			(p :: any)[key] = value
		end
		p.Parent = model
		return p
	end

	local body = part({ Name = "Body", Size = Vector3.one * 3.4, Color = BODY, Transparency = 0.12, CanQuery = true })
	part({ Name = "Wisp", Size = Vector3.one * 1.8, Color = BODY, Transparency = 0.35, CFrame = CFrame.new(0, -1.4, 1) })
	for _, x in { -0.6, 0.6 } do
		part({
			Name = "Eye",
			Size = Vector3.one * 0.75,
			Color = EYES,
			Material = Enum.Material.Neon,
			CFrame = CFrame.new(x, 0.35, -1.45),
		})
	end
	model.PrimaryPart = body
	model:SetAttribute("CreatureId", id)

	local bar = Instance.new("BillboardGui")
	bar.Name = "HealthBar"
	bar.Size = UDim2.fromOffset(60, 8)
	bar.StudsOffsetWorldSpace = Vector3.new(0, 2.6, 0)
	bar.Enabled = false
	bar.Parent = body
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
	back.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(190, 120, 255)
	fill.BorderSizePixel = 0
	fill.Parent = back

	model.Parent = parent
	return model
end

function CreatureView.setHealth(model: Model, share: number)
	local bar = model.PrimaryPart and model.PrimaryPart:FindFirstChild("HealthBar") :: BillboardGui?
	if bar then
		bar.Enabled = share < 1
		local fill = bar:FindFirstChild("Fill", true) :: Frame
		fill.Size = UDim2.fromScale(math.clamp(share, 0, 1), 1)
	end
end

-- Pastel sprinkles burst out and the creature shrinks away.
function CreatureView.poof(model: Model)
	local body = model.PrimaryPart
	if body then
		local sprinkles = Instance.new("ParticleEmitter")
		sprinkles.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 150, 200)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 230, 255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 240, 140)),
		})
		sprinkles.Size = NumberSequence.new(0.35)
		sprinkles.Speed = NumberRange.new(10, 18)
		sprinkles.SpreadAngle = Vector2.new(180, 180)
		sprinkles.Lifetime = NumberRange.new(0.6, 1)
		sprinkles.Rate = 0
		sprinkles.Parent = body
		sprinkles:Emit(30)
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			TweenService:Create(part, TweenInfo.new(0.35), { Size = part.Size * 0.1, Transparency = 1 }):Play()
		end
	end
	Debris:AddItem(model, 1.2)
end

return CreatureView
