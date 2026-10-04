-- Pure rules for the total earnings multiplier on shop sales. Every boost stacks multiplicatively.
-- factors (all optional): { rebirthMultiplier, doubleCash, vip, inGroup, friends, event }
-- config: { vipBonus, groupBonus, friendBonus, maxFriends }

local Income = {}

function Income.multiplier(config, factors): number
	local total = factors.rebirthMultiplier or 1
	if factors.doubleCash then
		total *= 2
	end
	if factors.vip then
		total *= 1 + config.vipBonus
	end
	if factors.inGroup then
		total *= 1 + config.groupBonus
	end
	local friends = math.min(factors.friends or 0, config.maxFriends)
	total *= 1 + config.friendBonus * friends
	return total * (factors.event or 1)
end

return Income
