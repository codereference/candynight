-- Shows customers in the world: a cute placeholder NPC per customer id that walks between spots.
-- Movement is tweened on anchored parts. That's cheap on phones, and creatures can reuse it later.

local TweenService = game:GetService("TweenService")

local CustomerView = {}
CustomerView.__index = CustomerView

local BODY_HEIGHT = 2.6
local PASTELS = {
	Color3.fromRGB(255, 179, 186),
	Color3.fromRGB(255, 223, 186),
	Color3.fromRGB(186, 255, 201),
	Color3.fromRGB(186, 225, 255),
	Color3.fromRGB(221, 190, 255),
}

local function makeModel(id: number): Model
	local model = Instance.new("Model")
	model.Name = "Customer" .. id

	local function part(props: { [string]: any }): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CastShadow = true
		p.Material = Enum.Material.SmoothPlastic
		for key, value in props do
			(p :: any)[key] = value
		end
		p.Parent = model
		return p
	end

	-- Built around a body origin at ground level, facing -Z.
	local body = part({
		Name = "Body",
		Size = Vector3.new(2, BODY_HEIGHT, 1.4),
		CFrame = CFrame.new(0, BODY_HEIGHT / 2, 0),
		Color = PASTELS[(id - 1) % #PASTELS + 1],
	})
	part({
		Name = "Head",
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2, 2, 2),
		CFrame = CFrame.new(0, BODY_HEIGHT + 0.9, 0),
		Color = Color3.fromRGB(255, 220, 190),
	})
	for _, x in { -0.4, 0.4 } do
		part({
			Name = "Eye",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(0.35, 0.35, 0.35),
			CFrame = CFrame.new(x, BODY_HEIGHT + 1.05, -0.9),
			Color = Color3.fromRGB(40, 30, 40),
		})
	end
	model.PrimaryPart = body

	local bubble = Instance.new("BillboardGui")
	bubble.Size = UDim2.fromOffset(40, 40)
	bubble.StudsOffsetWorldSpace = Vector3.new(0, BODY_HEIGHT + 3, 0)
	bubble.Adornee = body
	bubble.Parent = body
	local wish = Instance.new("TextLabel")
	wish.BackgroundTransparency = 1
	wish.Size = UDim2.fromScale(1, 1)
	wish.Text = "🧁"
	wish.TextScaled = true
	wish.Parent = bubble

	return model
end

function CustomerView.new(walkSpeed: number)
	return setmetatable({ walkSpeed = walkSpeed, customers = {} }, CustomerView)
end

-- Ground-level pivot: the body part's pivot sits half a body above the ground.
local function pivotFor(ground: CFrame): CFrame
	return ground * CFrame.new(0, BODY_HEIGHT / 2, 0)
end

function CustomerView:_walk(id: number, ground: CFrame, onArrived: (() -> ())?)
	local customer = self.customers[id]
	if not customer then
		return
	end
	if customer.tween then
		customer.tween:Cancel()
	end
	local from = customer.driver.Value
	local to = pivotFor(ground)
	local distance = (to.Position - from.Position).Magnitude
	-- Face the way we're walking, then turn to the target facing on arrival.
	if distance > 0.05 then
		customer.driver.Value = CFrame.lookAt(from.Position, Vector3.new(to.X, from.Y, to.Z))
	end
	local tween = TweenService:Create(
		customer.driver,
		TweenInfo.new(distance / self.walkSpeed, Enum.EasingStyle.Linear),
		{ Value = to }
	)
	customer.tween = tween
	tween.Completed:Connect(function(state)
		if state == Enum.PlaybackState.Completed and onArrived then
			onArrived()
		end
	end)
	tween:Play()
end

function CustomerView:spawn(id: number, at: CFrame)
	local model = makeModel(id)
	local driver = Instance.new("CFrameValue")
	driver.Value = pivotFor(at)
	driver.Changed:Connect(function(value)
		model:PivotTo(value)
	end)
	model:PivotTo(driver.Value)
	model.Parent = workspace
	self.customers[id] = { model = model, driver = driver }
end

-- Walks every customer still in line to their spot. queue: ids front-first.
function CustomerView:layout(queue: { number }, slotFor: (number) -> CFrame)
	for position, id in queue do
		self:_walk(id, slotFor(position))
	end
end

-- Walks a served customer off to `exit`, then removes them.
function CustomerView:leave(id: number, exit: CFrame)
	local customer = self.customers[id]
	if not customer then
		return
	end
	local wish = customer.model:FindFirstChildWhichIsA("BillboardGui", true)
	if wish then
		wish:FindFirstChildWhichIsA("TextLabel").Text = "😋"
	end
	self:_walk(id, exit, function()
		customer.model:Destroy()
		customer.driver:Destroy()
		self.customers[id] = nil
	end)
end

return CustomerView
