-- Pure rules for handheld weapons: which weapons a player has, swing cooldowns, and who a swing hits.
-- Positions are plain { x, z } tables so this runs headless.
-- weapon: { damage, cooldown, range, ranged? }. Melee hits everything in range (easy on phones);
-- ranged weapons auto-aim at the nearest target in range.

local WeaponRules = {}

-- profileWeapons: { [id] = true } saved on the profile; unlocked: { id } from bought buttons.
function WeaponRules.owned(profileWeapons, unlocked: { string }): { string }
	local set, list = {}, {}
	for id in profileWeapons do
		set[id] = true
	end
	for _, id in unlocked do
		set[id] = true
	end
	for id in set do
		table.insert(list, id)
	end
	table.sort(list)
	return list
end

-- Server-side cooldown check. Returns true (and the new last-swing time) when the swing is allowed.
function WeaponRules.trySwing(weapon, lastSwing: number?, now: number): (boolean, number?)
	if lastSwing and now - lastSwing < weapon.cooldown then
		return false, lastSwing
	end
	return true, now
end

-- attacker: { x, z }. targets: { { id, x, z } }. Returns the ids this swing hits.
function WeaponRules.hits(weapon, attacker, targets): { any }
	local inRange = {}
	for _, target in targets do
		local distance = math.sqrt((target.x - attacker.x) ^ 2 + (target.z - attacker.z) ^ 2)
		if distance <= weapon.range then
			table.insert(inRange, { id = target.id, distance = distance })
		end
	end
	if weapon.ranged then
		table.sort(inRange, function(a, b)
			return a.distance < b.distance
		end)
		return if inRange[1] then { inRange[1].id } else {}
	end
	local ids = {}
	for _, hit in inRange do
		table.insert(ids, hit.id)
	end
	return ids
end

return WeaponRules
