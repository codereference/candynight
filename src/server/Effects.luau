-- Small shared visual effects.

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Effects = {}

-- A candy ball flying from one point to another (visual only; damage is applied separately).
function Effects.shoot(from: Vector3, to: Vector3, color: Color3?, size: number?)
	local ball = Instance.new("Part")
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.one * (size or 0.9)
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CanTouch = false
	ball.Material = Enum.Material.Neon
	ball.Color = color or Color3.fromHSV(math.random(), 0.5, 1)
	ball.Position = from
	ball.Parent = workspace
	local flight = (to - from).Magnitude / 120
	TweenService:Create(ball, TweenInfo.new(flight, Enum.EasingStyle.Linear), { Position = to }):Play()
	Debris:AddItem(ball, flight + 0.05)
end

return Effects
