-- Pure health bookkeeping for shadow creatures. Weapons and defenses deal damage through here.

local Horde = {}
Horde.__index = Horde

function Horde.new()
	return setmetatable({ health = {}, maxHealth = {}, nextId = 1 }, Horde)
end

function Horde:spawn(health: number): number
	local id = self.nextId
	self.nextId += 1
	self.health[id] = health
	self.maxHealth[id] = health
	return id
end

function Horde:isAlive(id: number): boolean
	return self.health[id] ~= nil
end

-- Share of health left, 0..1 (0 when gone).
function Horde:healthShare(id: number): number
	local health = self.health[id]
	return if health then health / self.maxHealth[id] else 0
end

-- Returns true when this hit defeated the creature. Hits on defeated creatures do nothing.
function Horde:damage(id: number, amount: number): boolean
	local health = self.health[id]
	if health == nil or amount <= 0 then
		return false
	end
	health -= amount
	if health <= 0 then
		self:remove(id)
		return true
	end
	self.health[id] = health
	return false
end

function Horde:remove(id: number)
	self.health[id] = nil
	self.maxHealth[id] = nil
end

return Horde
