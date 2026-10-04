-- Pure rules for buying, moving, selling, damaging and repairing grid defenses.
-- state: the profile fields { placed = { { id, kind, col, row, rot, hp } }, nextPlacedId }.
-- catalog: { [kind] = { cost, hp, damage, range, fireRate, requires? } }.
-- config: { maxPlaced, sellShare, repairShare }.

local Defenses = {}

local ROTATIONS = { [0] = true, [90] = true, [180] = true, [270] = true }

local function find(state, id: number)
	for index, entry in state.placed do
		if entry.id == id then
			return entry, index
		end
	end
	return nil, nil
end
Defenses.find = find

-- Buys and places a new defense. Returns the entry, or nil plus a reason:
-- "unknown" | "locked" | "full" | "rotation" | "bounds" | "blocked" | "occupied" | "cash".
function Defenses.place(state, wallet, grid, catalog, config, ownedButtons, kind: string, col, row, rot)
	local def = catalog[kind]
	if def == nil then
		return nil, "unknown"
	elseif def.requires and not ownedButtons[def.requires] then
		return nil, "locked"
	elseif #state.placed >= config.maxPlaced then
		return nil, "full"
	elseif not ROTATIONS[rot] then
		return nil, "rotation"
	end
	local ok, reason = grid:validate(state.placed, col, row)
	if not ok then
		return nil, reason
	end
	if not wallet:spend(def.cost) then
		return nil, "cash"
	end
	local entry = { id = state.nextPlacedId, kind = kind, col = col, row = row, rot = rot, hp = def.hp }
	state.nextPlacedId += 1
	table.insert(state.placed, entry)
	return entry, nil
end

-- Moves an existing defense. Returns true, or false plus a reason ("missing", "rotation", or a grid reason).
function Defenses.move(state, grid, id: number, col, row, rot): (boolean, string?)
	local entry = find(state, id)
	if entry == nil then
		return false, "missing"
	elseif not ROTATIONS[rot] then
		return false, "rotation"
	end
	local ok, reason = grid:validate(state.placed, col, row, id)
	if not ok then
		return false, reason
	end
	entry.col, entry.row, entry.rot = col, row, rot
	return true, nil
end

-- What selling would refund: a share of the price, scaled by remaining health.
function Defenses.sellValue(catalog, config, entry): number
	local def = catalog[entry.kind]
	return math.floor(def.cost * config.sellShare * (entry.hp / def.hp))
end

-- Sells a defense. Returns the refund, or nil if it doesn't exist.
function Defenses.sell(state, wallet, catalog, config, id: number): number?
	local entry, index = find(state, id)
	if entry == nil then
		return nil
	end
	local refund = Defenses.sellValue(catalog, config, entry)
	table.remove(state.placed, index)
	wallet:earn(refund)
	return refund
end

-- Damages a defense. Returns true when this hit destroyed it.
function Defenses.damage(state, id: number, amount: number): boolean
	local entry = find(state, id)
	if entry == nil or entry.hp <= 0 then
		return false
	end
	entry.hp = math.max(0, entry.hp - amount)
	return entry.hp == 0
end

-- Cost to bring a defense back to full health (destroyed ones cost the most).
function Defenses.repairCost(catalog, config, entry): number
	local def = catalog[entry.kind]
	local missing = 1 - entry.hp / def.hp
	return math.ceil(def.cost * config.repairShare * missing)
end

-- Repairs to full. Returns true, or false plus "missing" | "full" | "cash".
function Defenses.repair(state, wallet, catalog, config, id: number): (boolean, string?)
	local entry = find(state, id)
	if entry == nil then
		return false, "missing"
	end
	local cost = Defenses.repairCost(catalog, config, entry)
	if cost == 0 then
		return false, "full"
	end
	if not wallet:spend(cost) then
		return false, "cash"
	end
	entry.hp = catalog[entry.kind].hp
	return true, nil
end

return Defenses
