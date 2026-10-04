-- Pure rules for what a player is entitled to from gamepasses. Owners get everything free.
-- config: { ownerIds = { userId }, passes = { [passKey] = { id, perk } } }
-- owned: { [passKey] = true } from purchase checks.

local Entitlements = {}

function Entitlements.isOwner(config, userId: number): boolean
	return table.find(config.ownerIds, userId) ~= nil
end

function Entitlements.hasPass(config, owned, userId: number, passKey: string): boolean
	return Entitlements.isOwner(config, userId) or owned[passKey] == true
end

-- Every perk the player has: { [perk] = true } (e.g. doubleCash, vip, extraHelper, sweetStyle).
function Entitlements.perks(config, owned, userId: number)
	local perks = {}
	for passKey, pass in config.passes do
		if Entitlements.hasPass(config, owned, userId, passKey) then
			perks[pass.perk] = true
		end
	end
	return perks
end

-- The overhead tag to show, if any: "Owner" beats "VIP".
function Entitlements.tag(config, owned, userId: number): string?
	if Entitlements.isOwner(config, userId) then
		return "Owner"
	end
	return if Entitlements.perks(config, owned, userId).vip then "VIP" else nil
end

return Entitlements
