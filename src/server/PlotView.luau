-- Builds a shop plot in the world from placeholder parts and exposes the spots customers use.
-- Plot-local space follows Layout: the counter faces -Z, toward the road.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Layout = require(ReplicatedStorage.Shared.Layout)
local Strings = require(ReplicatedStorage.Shared.Strings)

local PlotView = {}

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = parent
	return p
end
PlotView.part = part

local function folder(parent: Instance, name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

-- origin: CFrame on the ground at the plot's centre. Customer spots are ground-level CFrames.
function PlotView.build(index: number, origin: CFrame, queueSpacing: number)
	local model = Instance.new("Model")
	model.Name = "Plot" .. index

	local function at(x: number, y: number, z: number): CFrame
		return origin * CFrame.new(x, y, z)
	end

	part(model, {
		Name = "Floor",
		Size = Vector3.new(Layout.PLOT_SIZE, 1, Layout.PLOT_SIZE),
		CFrame = at(0, -0.4, 0), -- mostly sunk so the road and floor are level
		Color = Color3.fromRGB(255, 214, 224),
	})
	local counter = part(model, {
		Name = "Counter",
		Size = Vector3.new(12, 3.5, 3),
		CFrame = at(0, 1.85, Layout.COUNTER_Z),
		Color = Color3.fromRGB(176, 112, 76),
		Material = Enum.Material.Wood,
	})
	part(model, {
		Name = "CounterTop",
		Size = Vector3.new(12.6, 0.4, 3.6),
		CFrame = at(0, 3.8, Layout.COUNTER_Z),
		Color = Color3.fromRGB(255, 250, 240),
	})
	local register = part(model, {
		Name = "Register",
		Size = Vector3.new(2, 1.4, 1.6),
		CFrame = at(3.5, 4.7, Layout.COUNTER_Z),
		Color = Color3.fromRGB(120, 210, 200),
	})

	local sign = part(model, {
		Name = "OwnerSign",
		Size = Vector3.new(10, 3, 0.4),
		CFrame = at(-22, 4, -30), -- front face looks at the road
		Color = Color3.fromRGB(255, 250, 240),
	})
	part(model, { Name = "SignPost", Size = Vector3.new(0.6, 3, 0.6), CFrame = at(-22, 1.5, -30) })
	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local signText = Instance.new("TextLabel")
	signText.Size = UDim2.fromScale(1, 1)
	signText.BackgroundTransparency = 1
	signText.Font = Enum.Font.FredokaOne
	signText.TextScaled = true
	signText.TextColor3 = Color3.fromRGB(255, 120, 160)
	signText.Parent = signGui

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "OwnerSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Enabled = false -- only used as each owner's RespawnLocation
	spawn.Duration = 0
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.CFrame = at(Layout.OWNER_SPAWN.x, 0.6, Layout.OWNER_SPAWN.z)
	spawn.Color = Color3.fromRGB(255, 235, 150)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Parent = model

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = Strings.get("Prompt.Serve")
	prompt.ObjectText = Strings.get("Prompt.Counter")
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.Parent = counter

	local view = {
		model = model,
		origin = origin,
		counter = counter,
		register = register,
		spawn = spawn,
		servePrompt = prompt,
		items = folder(model, "Items"),
		buttons = folder(model, "Buttons"),
		customers = folder(model, "Customers"),
		defenses = folder(model, "Defenses"),
		at = at,
		entrance = at(Layout.ENTRANCE.x, 0, Layout.ENTRANCE.z),
		exit = at(Layout.EXIT.x, 0, Layout.EXIT.z),
	}

	-- Standing spot for the n-th customer in line (1 = front), facing the counter.
	function view.queueSlot(n: number): CFrame
		local position = at(0, 0, Layout.COUNTER_Z - 4 - (n - 1) * queueSpacing).Position
		return CFrame.lookAt(position, position - origin.LookVector)
	end

	function view.setOwnerName(name: string?)
		signText.Text = if name then Strings.get("Plot.Owned", { name = name }) else Strings.get("Plot.Free")
	end

	-- Removes everything an owner built, leaving the empty plot.
	function view.clear()
		for _, f in { view.items, view.buttons, view.customers, view.defenses } do
			f:ClearAllChildren()
		end
		prompt.Enabled = false
	end

	view.setOwnerName(nil)
	model.Parent = workspace
	return view
end

-- The road that runs between the two rows of plots.
function PlotView.buildRoad(length: number)
	part(workspace, {
		Name = "Road",
		Size = Vector3.new(length, 1, 16),
		CFrame = CFrame.new(0, -0.45, 0),
		Color = Color3.fromRGB(110, 105, 120),
	})
end

return PlotView
