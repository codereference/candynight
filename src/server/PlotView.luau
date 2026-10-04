-- Builds a shop plot in the world from placeholder parts and exposes the spots customers use.
-- Plot-local space: the counter faces -Z, toward the road where customers come from.

local PlotView = {}

local FLOOR_SIZE = 40
local COUNTER_Z = -6

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end

-- origin: CFrame on the ground at the plot's centre. Customer spots are ground-level CFrames.
function PlotView.build(origin: CFrame, queueSpacing: number)
	local model = Instance.new("Model")
	model.Name = "Plot"

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	part(model, {
		Name = "Floor",
		Size = Vector3.new(FLOOR_SIZE, 1, FLOOR_SIZE),
		CFrame = at(0, -0.4, 0), -- mostly sunk so the road and floor are level
		Color = Color3.fromRGB(255, 214, 224),
		Material = Enum.Material.SmoothPlastic,
	})
	local counter = part(model, {
		Name = "Counter",
		Size = Vector3.new(12, 3.5, 3),
		CFrame = at(0, 1.85, COUNTER_Z),
		Color = Color3.fromRGB(176, 112, 76),
		Material = Enum.Material.Wood,
	})
	part(model, {
		Name = "CounterTop",
		Size = Vector3.new(12.6, 0.4, 3.6),
		CFrame = at(0, 3.8, COUNTER_Z),
		Color = Color3.fromRGB(255, 250, 240),
		Material = Enum.Material.SmoothPlastic,
	})
	part(model, {
		Name = "Register",
		Size = Vector3.new(2, 1.4, 1.6),
		CFrame = at(3.5, 4.7, COUNTER_Z),
		Color = Color3.fromRGB(120, 210, 200),
		Material = Enum.Material.SmoothPlastic,
	})
	part(model, {
		Name = "Awning",
		Size = Vector3.new(14, 0.6, 5),
		CFrame = at(0, 9, COUNTER_Z) * CFrame.Angles(math.rad(-15), 0, 0),
		Color = Color3.fromRGB(255, 120, 160),
		Material = Enum.Material.SmoothPlastic,
	})

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "OwnerSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = at(0, 0.6, 6)
	spawn.Color = Color3.fromRGB(255, 235, 150)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Serve"
	prompt.ObjectText = "Counter"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = counter

	model.Parent = workspace

	return {
		model = model,
		servePrompt = prompt,
		-- Where customers appear and disappear, out on the road.
		entrance = at(0, 0, -34),
		exit = at(30, 0, -34),
		-- Standing spot for the n-th customer in line (1 = front), facing the counter.
		queueSlot = function(n: number): CFrame
			local position = at(0, 0, COUNTER_Z - 4 - (n - 1) * queueSpacing).Position
			return CFrame.lookAt(position, position + origin.LookVector * -1)
		end,
	}
end

return PlotView
