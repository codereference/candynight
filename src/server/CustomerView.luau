-- Shows customers in the world: an NPC per customer id that walks between spots.
-- Movement is tweened on anchored parts. That's cheap on phones, and creatures can reuse it later.

local TweenService = game:GetService("TweenService")

local NpcModel = require(script.Parent.NpcModel)

local CustomerView = {}
CustomerView.__index = CustomerView

function CustomerView.new(walkSpeed: number, parent: Instance)
	return setmetatable({ walkSpeed = walkSpeed, parent = parent, customers = {} }, CustomerView)
end

function CustomerView:_walk(id: number, ground: CFrame, onArrived: (() -> ())?, speedScale: number?)
	local customer = self.customers[id]
	if not customer then
		return
	end
	if customer.tween then
		customer.tween:Cancel()
	end
	local from = customer.driver.Value
	local to = NpcModel.pivotFor(ground)
	local distance = (to.Position - from.Position).Magnitude
	-- Face the way we're walking, then turn to the target facing on arrival.
	if distance > 0.05 then
		customer.driver.Value = CFrame.lookAt(from.Position, Vector3.new(to.X, from.Y, to.Z))
	end
	local tween = TweenService:Create(
		customer.driver,
		TweenInfo.new(distance / (self.walkSpeed * (speedScale or 1)), Enum.EasingStyle.Linear),
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
	local pastels = NpcModel.PASTELS
	local model = NpcModel.make("Customer" .. id, { color = pastels[(id - 1) % #pastels + 1], bubble = "🧁" })
	local driver = Instance.new("CFrameValue")
	driver.Value = NpcModel.pivotFor(at)
	driver.Changed:Connect(function(value)
		model:PivotTo(value)
	end)
	model:PivotTo(driver.Value)
	model.Parent = self.parent
	self.customers[id] = { model = model, driver = driver }
end

-- Current world position of a customer, or nil if they're gone.
function CustomerView:positionOf(id: number): Vector3?
	local customer = self.customers[id]
	return customer and customer.driver.Value.Position
end

-- Walks every customer still in line to their spot. queue: ids front-first.
function CustomerView:layout(queue: { number }, slotFor: (number) -> CFrame)
	for position, id in queue do
		self:_walk(id, slotFor(position))
	end
end

-- Walks a customer off to `exit` showing `bubble`, then removes them. speedScale > 1 to run.
function CustomerView:leave(id: number, exit: CFrame, bubble: string?, speedScale: number?)
	local customer = self.customers[id]
	if not customer then
		return
	end
	NpcModel.setBubble(customer.model, bubble or "😋")
	self:_walk(id, exit, function()
		self:_remove(id)
	end, speedScale)
end

function CustomerView:_remove(id: number)
	local customer = self.customers[id]
	if customer then
		if customer.tween then
			customer.tween:Cancel()
		end
		customer.model:Destroy()
		customer.driver:Destroy()
		self.customers[id] = nil
	end
end

-- Removes every customer at once (the plot was freed).
function CustomerView:clear()
	for id in self.customers do
		self:_remove(id)
	end
end

return CustomerView
