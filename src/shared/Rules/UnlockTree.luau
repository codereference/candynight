-- Pure rules for the buy-button catalog: what's buyable, buying, and what owning things adds up to.
-- Catalog entries: { id, cost, requires?, goods?, decor?, staff?, weapon? }
--   goods  = extra cash per sale, decor = seconds off the customer interval,
--   staff  = a worker who serves every `staff` seconds, weapon = handheld weapon id it grants.
-- owned is a set: { [id] = true }.

local UnlockTree = {}
UnlockTree.__index = UnlockTree

function UnlockTree.new(catalog)
	local byId = {}
	for _, entry in catalog do
		byId[entry.id] = entry
	end
	return setmetatable({ catalog = catalog, byId = byId }, UnlockTree)
end

function UnlockTree:get(id: string)
	return self.byId[id]
end

-- Why a button can't be bought right now, or nil if it can (ignoring cash).
function UnlockTree:blocker(owned, id: string): string?
	local entry = self.byId[id]
	if entry == nil then
		return "unknown"
	elseif owned[id] then
		return "owned"
	elseif entry.requires and not owned[entry.requires] then
		return "locked"
	end
	return nil
end

-- Buttons to show right now, in catalog order.
function UnlockTree:available(owned): { string }
	local ids = {}
	for _, entry in self.catalog do
		if self:blocker(owned, entry.id) == nil then
			table.insert(ids, entry.id)
		end
	end
	return ids
end

-- Owned ids in catalog order, so rebuilding a shop always happens in the same order.
function UnlockTree:ownedInOrder(owned): { string }
	local ids = {}
	for _, entry in self.catalog do
		if owned[entry.id] then
			table.insert(ids, entry.id)
		end
	end
	return ids
end

-- Buys `id` with `wallet` (an Economy wallet). Returns true, or false plus a reason:
-- "unknown" | "owned" | "locked" | "cash".
function UnlockTree:buy(owned, wallet, id: string): (boolean, string?)
	local reason = self:blocker(owned, id)
	if reason then
		return false, reason
	end
	if not wallet:spend(self.byId[id].cost) then
		return false, "cash"
	end
	owned[id] = true
	return true, nil
end

-- What everything owned adds up to, ready for Shop:setEffects.
function UnlockTree:effects(owned)
	local effects = { goods = 0, decor = 0, staff = {}, weapons = {} }
	for _, id in self:ownedInOrder(owned) do
		local entry = self.byId[id]
		effects.goods += entry.goods or 0
		effects.decor += entry.decor or 0
		if entry.staff then
			table.insert(effects.staff, entry.staff)
		end
		if entry.weapon then
			table.insert(effects.weapons, entry.weapon)
		end
	end
	return effects
end

return UnlockTree
