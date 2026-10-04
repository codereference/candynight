-- The world around the shops: a flat pastel lawn and faceted low-poly trees and hills.
-- Also puts the baseplate where everything expects it (top surface at y = 0), whatever the
-- place file says, so a mis-saved place can never bury the game.

local Scenery = {}

local GRASS = Color3.fromRGB(150, 215, 120)
local LEAVES = { Color3.fromRGB(120, 200, 110), Color3.fromRGB(160, 220, 120), Color3.fromRGB(255, 180, 210) }
local TRUNK = Color3.fromRGB(150, 105, 80)
local HILL = Color3.fromRGB(135, 200, 110)

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

-- A tree: a block trunk with two cubes twisted against each other for a faceted canopy.
local function tree(parent: Instance, position: Vector3, size: number, random: Random)
	local model = Instance.new("Model")
	model.Name = "Tree"
	part({
		Size = Vector3.new(1.2, 4, 1.2) * size,
		CFrame = CFrame.new(position + Vector3.new(0, 2 * size, 0)),
		Color = TRUNK,
	}).Parent =
		model
	local leaves = LEAVES[random:NextInteger(1, #LEAVES)]
	for i, scale in { 4.5, 3.2 } do
		part({
			Size = Vector3.one * scale * size,
			CFrame = CFrame.new(position + Vector3.new(0, (3.5 + i * 1.6) * size, 0))
				* CFrame.Angles(math.rad(35), math.rad(45 * i), math.rad(20)),
			Color = leaves,
		}).Parent =
			model
	end
	model.Parent = parent
end

-- A hill: a big tilted block sunk into the ground so only a faceted top shows.
local function hill(parent: Instance, position: Vector3, size: number, random: Random)
	part({
		Size = Vector3.new(30, 30, 30) * size,
		CFrame = CFrame.new(position - Vector3.new(0, 18 * size, 0))
			* CFrame.Angles(math.rad(random:NextNumber(30, 50)), math.rad(random:NextNumber(0, 90)), math.rad(45)),
		Color = HILL,
		CanCollide = false,
	}).Parent =
		parent
end

function Scenery.build(plotSpacing: number, rowOffset: number)
	local base = workspace:FindFirstChild("Baseplate") :: BasePart?
	if base then
		base.Size = Vector3.new(512, 20, 512)
		base.CFrame = CFrame.new(0, -10, 0)
		base.Material = Enum.Material.SmoothPlastic
		base.Color = GRASS
	end

	local folder = Instance.new("Folder")
	folder.Name = "Scenery"
	local random = Random.new(7) -- same layout every server
	local clearX, clearZ = plotSpacing * 2, rowOffset + 40 -- keep trees off the plots and road

	for _ = 1, 70 do
		local x, z = random:NextNumber(-240, 240), random:NextNumber(-240, 240)
		if math.abs(x) > clearX or math.abs(z) > clearZ then
			tree(folder, Vector3.new(x, 0, z), random:NextNumber(0.8, 1.6), random)
		end
	end
	for _ = 1, 14 do
		local angle = random:NextNumber(0, math.pi * 2)
		local distance = random:NextNumber(200, 240)
		hill(
			folder,
			Vector3.new(math.cos(angle) * distance, 0, math.sin(angle) * distance),
			random:NextNumber(1, 1.8),
			random
		)
	end
	folder.Parent = workspace
end

return Scenery
