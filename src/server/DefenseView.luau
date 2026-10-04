-- Grid defenses in the world: candy turrets with a health bar. Destroyed ones slump grey with a 🔧.
-- Each model carries attributes (DefenseId, Kind, Col, Row, Rot) the client reads for placement.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)

local DefenseView = {}

local function part(model: Model, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = model
	return p
end

-- Builders work around a local origin at the cell centre on the ground, facing -Z.
local LOOKS: { [string]: (Model) -> () } = {
	GumdropTurret = function(m)
		part(m, {
			Name = "Base",
			Size = Vector3.new(3, 1, 3),
			CFrame = CFrame.new(0, 0.5, 0),
			Color = Color3.fromRGB(255, 244, 220),
		})
		part(m, {
			Name = "Head",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 2.6,
			CFrame = CFrame.new(0, 2.2, 0),
			Color = Color3.fromRGB(255, 120, 170),
		})
		part(m, {
			Name = "Nozzle",
			Size = Vector3.new(0.6, 0.6, 1.6),
			CFrame = CFrame.new(0, 2.2, -1.5),
			Color = Color3.fromRGB(255, 240, 120),
		})
	end,
	PeppermintCannon = function(m)
		part(m, {
			Name = "Base",
			Size = Vector3.new(3.4, 1.2, 3.4),
			CFrame = CFrame.new(0, 0.6, 0),
			Color = Color3.fromRGB(120, 72, 50),
		})
		part(m, {
			Name = "Head",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, 3, 3),
			CFrame = CFrame.new(0, 2.6, 0),
			Color = Color3.fromRGB(240, 60, 80),
		})
		part(m, {
			Name = "Nozzle",
			Size = Vector3.new(0.9, 0.9, 2.4),
			CFrame = CFrame.new(0, 2.6, -1.8),
			Color = Color3.new(1, 1, 1),
		})
	end,
	CottonCandyZapper = function(m)
		part(m, {
			Name = "Base",
			Size = Vector3.new(0.5, 4, 0.5),
			CFrame = CFrame.new(0, 2, 0),
			Color = Color3.fromRGB(255, 244, 220),
		})
		for i, offset in { Vector3.new(0, 4.6, 0), Vector3.new(0.8, 4.2, 0.3), Vector3.new(-0.7, 4.3, -0.3) } do
			part(m, {
				Name = if i == 1 then "Head" else "Fluff",
				Shape = Enum.PartType.Ball,
				Size = Vector3.one * 2.2,
				CFrame = CFrame.new(offset),
				Color = Color3.fromRGB(255, 180, 230),
			})
		end
		part(m, {
			Name = "Nozzle",
			Shape = Enum.PartType.Ball,
			Size = Vector3.one * 0.8,
			CFrame = CFrame.new(0, 5.8, 0),
			Color = Color3.fromRGB(150, 220, 255),
			Material = Enum.Material.Neon,
		})
	end,
}
DefenseView.LOOKS = LOOKS

-- World CFrame of a cell centre on the ground, with rotation in degrees.
function DefenseView.cellCFrame(view, col: number, row: number, rot: number): CFrame
	local x, z = Layout.cellCentre(col, row)
	return view.at(x, 0, z) * CFrame.Angles(0, math.rad(rot), 0)
end

function DefenseView.build(view, entry): Model
	local model = Instance.new("Model")
	model.Name = entry.kind
	LOOKS[entry.kind](model)
	for _, p in model:GetChildren() do
		p:SetAttribute("Colour", (p :: BasePart).Color) -- remembered for when it's repaired
	end
	model.WorldPivot = CFrame.new() -- pivot on the ground at the cell centre
	local base = model:FindFirstChild("Base") :: BasePart

	local bar = Instance.new("BillboardGui")
	bar.Name = "HealthBar"
	bar.Size = UDim2.fromOffset(56, 8)
	bar.StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0)
	bar.MaxDistance = 80
	bar.Parent = base
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = Color3.fromRGB(60, 40, 60)
	back.Parent = bar
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(110, 220, 120)
	fill.BorderSizePixel = 0
	fill.Parent = back

	local wrench = Instance.new("BillboardGui")
	wrench.Name = "Broken"
	wrench.Size = UDim2.fromOffset(36, 36)
	wrench.StudsOffsetWorldSpace = Vector3.new(0, 4, 0)
	wrench.Enabled = false
	wrench.Parent = base
	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.TextScaled = true
	icon.Text = "🔧"
	icon.Parent = wrench

	DefenseView.place(view, model, entry)
	model.Parent = view.defenses
	return model
end

-- Moves the model to the entry's cell and refreshes its attributes.
function DefenseView.place(view, model: Model, entry)
	model:PivotTo(DefenseView.cellCFrame(view, entry.col, entry.row, entry.rot))
	model:SetAttribute("DefenseId", entry.id)
	model:SetAttribute("Kind", entry.kind)
	model:SetAttribute("Col", entry.col)
	model:SetAttribute("Row", entry.row)
	model:SetAttribute("Rot", entry.rot)
end

function DefenseView.setHealth(model: Model, share: number)
	local destroyed = share <= 0
	local base = model:FindFirstChild("Base") :: BasePart
	local bar = base:FindFirstChild("HealthBar") :: BillboardGui
	local fill = bar:FindFirstChild("Fill", true) :: Frame
	fill.Size = UDim2.fromScale(math.clamp(share, 0, 1), 1)
	fill.BackgroundColor3 = if share > 0.5
		then Color3.fromRGB(110, 220, 120)
		elseif share > 0.25 then Color3.fromRGB(255, 200, 80)
		else Color3.fromRGB(235, 90, 90)
	bar.Enabled = not destroyed;
	(base:FindFirstChild("Broken") :: BillboardGui).Enabled = destroyed
	model:SetAttribute("Destroyed", destroyed)
	model:SetAttribute("HealthShare", share)
	for _, p in model:GetChildren() do
		if p:IsA("BasePart") then
			p.Color = if destroyed then Color3.fromRGB(130, 125, 135) else p:GetAttribute("Colour")
		end
	end
end

-- Points the head and nozzle at a world position (turrets track their target).
function DefenseView.aim(model: Model, target: Vector3)
	local pivot = model:GetPivot()
	local flatTarget = Vector3.new(target.X, pivot.Y, target.Z)
	if (flatTarget - pivot.Position).Magnitude < 0.1 then
		return
	end
	model:PivotTo(CFrame.lookAt(pivot.Position, flatTarget))
end

return DefenseView
