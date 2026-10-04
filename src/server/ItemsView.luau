-- Builds bought items into a plot from placeholder parts. One builder per button id.
-- Builders work in plot-local studs via view.at(x, y, z); see Layout for the zones.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Layout = require(ReplicatedStorage.Shared.Layout)
local Strings = require(ReplicatedStorage.Shared.Strings)
local NpcModel = require(script.Parent.NpcModel)

local ItemsView = {}

local PINK = Color3.fromRGB(255, 150, 180)
local CREAM = Color3.fromRGB(255, 244, 220)
local MINT = Color3.fromRGB(170, 235, 210)
local CHOC = Color3.fromRGB(120, 72, 50)

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

local function ball(model: Model, at: CFrame, size: number, color: Color3, material: Enum.Material?)
	return part(model, {
		Shape = Enum.PartType.Ball,
		Size = Vector3.one * size,
		CFrame = at,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
	})
end

local function staff(view, model: Model, x: number, color: Color3)
	local npc = NpcModel.make("Worker", { color = color, chefHat = true })
	local ground = view.at(x, 0, Layout.COUNTER_Z + 3)
	-- Face the counter and the customers (plot -Z).
	npc:PivotTo(NpcModel.pivotFor(CFrame.lookAt(ground.Position, ground.Position + view.origin.LookVector)))
	npc.Parent = model
end

local COUNTER_TOP = 4.0 -- top of the counter in plot-local studs
local Z = Layout.COUNTER_Z

local BUILDERS: { [string]: (any, Model) -> () } = {
	CupcakeTray = function(view, m)
		part(m, { Size = Vector3.new(3, 0.2, 1.6), CFrame = view.at(-4, COUNTER_TOP + 0.1, Z), Color = CREAM })
		for i, x in { -5, -4, -3 } do
			local colors = { PINK, MINT, Color3.fromRGB(255, 220, 120) }
			part(m, { Size = Vector3.new(0.7, 0.5, 0.7), CFrame = view.at(x, COUNTER_TOP + 0.45, Z), Color = CHOC })
			ball(m, view.at(x, COUNTER_TOP + 0.85, Z), 0.8, colors[i])
		end
	end,
	Walls = function(view, m)
		local color = Color3.fromRGB(255, 236, 170)
		part(m, { Size = Vector3.new(24, 10, 1), CFrame = view.at(0, 5, 8), Color = color })
		part(m, { Size = Vector3.new(1, 10, 18), CFrame = view.at(-12, 5, -1), Color = color })
		part(m, { Size = Vector3.new(1, 10, 18), CFrame = view.at(12, 5, -1), Color = color })
	end,
	CookieJar = function(view, m)
		part(m, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.6, 1.4, 1.4),
			CFrame = view.at(0, COUNTER_TOP + 0.8, Z) * CFrame.Angles(0, 0, math.rad(90)),
			Color = Color3.fromRGB(200, 235, 255),
			Transparency = 0.3,
			Material = Enum.Material.Glass,
		})
		ball(m, view.at(0, COUNTER_TOP + 0.6, Z), 0.6, Color3.fromRGB(210, 160, 100))
	end,
	Sign = function(view, m)
		local board = part(m, { Size = Vector3.new(14, 3, 0.5), CFrame = view.at(0, 12, -10.5), Color = PINK })
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Text = Strings.get("Plot.ShopSign")
		label.Parent = gui
	end,
	Oven = function(view, m)
		part(m, { Size = Vector3.new(5, 5, 3), CFrame = view.at(-7, 2.5, 5), Color = Color3.fromRGB(230, 230, 240) })
		part(m, {
			Size = Vector3.new(3, 2, 0.2),
			CFrame = view.at(-7, 2.5, 3.45),
			Color = Color3.fromRGB(255, 160, 60),
			Material = Enum.Material.Neon,
		})
	end,
	Staff1 = function(view, m)
		staff(view, m, -3, Color3.fromRGB(255, 255, 255))
	end,
	Roof = function(view, m)
		part(m, { Size = Vector3.new(27, 1, 21), CFrame = view.at(0, 10.5, -1), Color = PINK })
		for x = -12, 12, 4 do
			part(m, { Size = Vector3.new(2, 0.6, 21.2), CFrame = view.at(x, 10.6, -1), Color = Color3.new(1, 1, 1) })
		end
	end,
	CandyMachine = function(view, m)
		part(m, { Size = Vector3.new(2, 3, 2), CFrame = view.at(8, 1.5, 4), Color = Color3.fromRGB(230, 60, 80) })
		ball(m, view.at(8, 4.2, 4), 3, Color3.fromRGB(220, 240, 255), Enum.Material.Glass).Transparency = 0.4
		for i = 1, 6 do
			local angle = i * math.pi / 3
			ball(
				m,
				view.at(8 + math.cos(angle) * 0.7, 4, 4 + math.sin(angle) * 0.7),
				0.6,
				NpcModel.PASTELS[(i - 1) % 5 + 1]
			)
		end
	end,
	Flowers = function(view, m)
		for _, x in { -9, 9 } do
			part(m, { Size = Vector3.new(5, 1, 1.5), CFrame = view.at(x, 0.5, -11), Color = CHOC })
			for i = -2, 2 do
				ball(m, view.at(x + i, 1.3, -11), 0.8, NpcModel.PASTELS[i + 3])
			end
		end
	end,
	Staff2 = function(view, m)
		staff(view, m, 0, Color3.fromRGB(190, 230, 255))
	end,
	CakeStand = function(view, m)
		part(m, { Size = Vector3.new(4, 3, 4), CFrame = view.at(-9, 1.5, -4), Color = CREAM })
		part(m, {
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.5, 2.5, 2.5),
			CFrame = view.at(-9, 3.75, -4) * CFrame.Angles(0, 0, math.rad(90)),
			Color = PINK,
		})
		ball(m, view.at(-9, 4.8, -4), 0.6, Color3.fromRGB(230, 40, 60))
	end,
	NeonSign = function(view, m)
		part(m, {
			Size = Vector3.new(10, 1.2, 0.3),
			CFrame = view.at(0, 14.2, -10.5),
			Color = Color3.fromRGB(255, 90, 200),
			Material = Enum.Material.Neon,
		})
	end,
	Staff3 = function(view, m)
		staff(view, m, 3, Color3.fromRGB(255, 215, 120))
	end,
}
ItemsView.BUILDERS = BUILDERS

-- Builds item `id` into the plot. pop = true plays a little grow-in animation.
function ItemsView.build(view, id: string, pop: boolean?): Model?
	local builder = BUILDERS[id]
	if builder == nil then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = id
	builder(view, model)
	model.Parent = view.items
	if pop then
		local scale = Instance.new("NumberValue")
		scale.Value = 0.05
		model:ScaleTo(scale.Value)
		scale.Changed:Connect(function(value)
			model:ScaleTo(math.max(value, 0.05))
		end)
		local tween = TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Value = 1 })
		tween.Completed:Connect(function()
			scale:Destroy()
		end)
		tween:Play()
	end
	return model
end

-- A worker does a happy little hop after serving someone.
function ItemsView.cheer(view, id: string)
	local item = view.items:FindFirstChild(id)
	local worker = item and item:FindFirstChild("Worker")
	if worker == nil or worker:GetAttribute("Hopping") then
		return
	end
	worker:SetAttribute("Hopping", true)
	local base = worker:GetPivot()
	local driver = Instance.new("CFrameValue")
	driver.Value = base
	driver.Changed:Connect(function(value)
		worker:PivotTo(value)
	end)
	local hop = TweenService:Create(
		driver,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true),
		{ Value = base + Vector3.new(0, 1, 0) }
	)
	hop.Completed:Connect(function()
		worker:PivotTo(base)
		worker:SetAttribute("Hopping", nil)
		driver:Destroy()
	end)
	hop:Play()
end

return ItemsView
