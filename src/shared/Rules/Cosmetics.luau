-- Pure cosmetic rules. Purely visual: nothing here changes gameplay.
-- catalog: { [id] = { slot = "theme" | "skin" | "trail", cost?, perk? ("vip" | "sweetStyle"), default? } }
--   default = free for everyone; cost = buyable with cash; perk = included with that pass.
-- state: the profile's { owned = { [id] = true }, equipped = { [slot] = id } }. perks: { [perk] = true }.

local Cosmetics = {}

function Cosmetics.isOwned(catalog, state, perks, id: string): boolean
	local entry = catalog[id]
	if entry == nil then
		return false
	end
	return entry.default == true or state.owned[id] == true or (entry.perk ~= nil and perks[entry.perk] == true)
end

-- Buys a cash cosmetic. Returns true, or false plus "unknown" | "owned" | "perk" | "cash".
-- "perk" means it can't be bought with cash; it comes with a pass.
function Cosmetics.buy(catalog, state, perks, wallet, id: string): (boolean, string?)
	local entry = catalog[id]
	if entry == nil then
		return false, "unknown"
	elseif Cosmetics.isOwned(catalog, state, perks, id) then
		return false, "owned"
	elseif entry.cost == nil then
		return false, "perk"
	elseif not wallet:spend(entry.cost) then
		return false, "cash"
	end
	state.owned[id] = true
	return true, nil
end

-- Equips an owned cosmetic in its slot. Returns true, or false plus "unknown" | "notOwned".
function Cosmetics.equip(catalog, state, perks, id: string): (boolean, string?)
	local entry = catalog[id]
	if entry == nil then
		return false, "unknown"
	elseif not Cosmetics.isOwned(catalog, state, perks, id) then
		return false, "notOwned"
	end
	state.equipped[entry.slot] = id
	return true, nil
end

-- What's actually worn in a slot: the equipped item if still usable (a pass could lapse), else the default.
function Cosmetics.worn(catalog, state, perks, slot: string): string?
	local id = state.equipped[slot]
	if id and Cosmetics.isOwned(catalog, state, perks, id) then
		return id
	end
	for candidate, entry in catalog do
		if entry.slot == slot and entry.default then
			return candidate
		end
	end
	return nil
end

return Cosmetics
