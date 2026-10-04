-- Pure rules for the shadow creatures that come to one shop in one night: how many, how tough,
-- and when each one shows up. Spawns are spread across the first part of the night.

local Wave = {}
Wave.__index = Wave

-- config: { baseCount, countPerNight, maxCount, baseHealth, healthGrowth, speed, speedGrowth, biteDamage, spawnWindow }
-- modifiers (events like Blood Moon): { count?, health?, speed? } multipliers.
function Wave.plan(config, night: number, modifiers)
	modifiers = modifiers or {}
	local step = math.max(0, night - 1)
	local count = math.min(config.maxCount, config.baseCount + step * config.countPerNight)
	return {
		count = math.floor(count * (modifiers.count or 1)),
		health = math.floor(config.baseHealth * (1 + step * config.healthGrowth) * (modifiers.health or 1)),
		speed = config.speed * (1 + step * config.speedGrowth) * (modifiers.speed or 1),
		bite = math.floor(config.biteDamage * (1 + step * config.healthGrowth) * (modifiers.health or 1)),
	}
end

-- nightLength: seconds. Spawns are evenly spaced across nightLength * spawnWindow, the first right away.
function Wave.new(plan, nightLength: number, spawnWindow: number)
	local interval = if plan.count > 1 then nightLength * spawnWindow / (plan.count - 1) else 0
	return setmetatable({ plan = plan, interval = interval, spawned = 0, untilNext = 0 }, Wave)
end

-- How many creatures should appear this tick.
function Wave:tick(dt: number): number
	local due = 0
	self.untilNext -= dt
	while self.spawned < self.plan.count and self.untilNext <= 0 do
		self.spawned += 1
		due += 1
		self.untilNext += self.interval
	end
	return due
end

return Wave
