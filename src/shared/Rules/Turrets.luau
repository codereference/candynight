-- Pure rules for automatic defenses: picking a target and firing on a cadence.
-- Positions are plain { x, z } tables. Destroyed defenses never fire.

local Turrets = {}
Turrets.__index = Turrets

-- Nearest target within range, or nil. targets: { { id, x, z } }.
function Turrets.pickTarget(from, range: number, targets): any
	local bestId, bestDistance = nil, math.huge
	for _, target in targets do
		local distance = math.sqrt((target.x - from.x) ^ 2 + (target.z - from.z) ^ 2)
		if distance <= range and distance < bestDistance then
			bestId, bestDistance = target.id, distance
		end
	end
	return bestId
end

function Turrets.new()
	-- Weak keys: a sold or removed defense's entry disappears with it.
	return setmetatable({ cooldowns = setmetatable({}, { __mode = "k" }) }, Turrets)
end

-- Advances one defense's reload (id: any key that identifies the defense). Returns true when it may fire now (then it starts reloading).
-- fireRate: seconds per shot. speedUp: overdrive multiplier (2 = twice as fast).
-- A turret with nothing to shoot stays loaded, so it fires the moment something comes in range.
function Turrets:ready(id: any, dt: number, fireRate: number, hasTarget: boolean, speedUp: number?): boolean
	local left = (self.cooldowns[id] or 0) - dt * (speedUp or 1)
	if left > 0 then
		self.cooldowns[id] = left
		return false
	end
	if not hasTarget then
		self.cooldowns[id] = 0
		return false
	end
	self.cooldowns[id] = left + fireRate
	return true
end

function Turrets:forget(id: any)
	self.cooldowns[id] = nil
end

return Turrets
