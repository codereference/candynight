-- Pure rebirth rules: reset your shop for a permanent income multiplier.
-- config: { baseCost, costGrowth, multiplierPerRebirth }

local Rebirth = {}

function Rebirth.cost(config, rebirths: number): number
	return math.floor(config.baseCost * config.costGrowth ^ rebirths)
end

function Rebirth.multiplier(config, rebirths: number): number
	return 1 + config.multiplierPerRebirth * rebirths
end

-- Rebirths if the wallet can cover the cost. Returns true, or false plus "cash".
-- Resets cash, shop unlocks, placed defenses and bought weapons. Keeps streaks, cosmetics,
-- daily rewards, codes, badges, receipts and tutorial progress.
function Rebirth.apply(config, profile, wallet): (boolean, string?)
	if not wallet:canAfford(Rebirth.cost(config, profile.rebirths)) then
		return false, "cash"
	end
	wallet:spend(wallet:getCash())
	profile.rebirths += 1
	profile.owned = {}
	profile.placed = {}
	profile.weapons = { RollingPin = true }
	return true, nil
end

return Rebirth
