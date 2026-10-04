-- Pure rules for what staff earn while the owner is away.
-- config: { capSeconds, minSeconds, efficiency } (efficiency: share of the online rate, e.g. 0.5)

local Offline = {}

-- staff: { { interval } } (see UnlockTree:effects). saleValue: cash per sale before boosts.
function Offline.earnings(config, secondsAway: number, staff, saleValue: number, multiplier: number): number
	if secondsAway < config.minSeconds or #staff == 0 then
		return 0
	end
	local salesPerSecond = 0
	for _, worker in staff do
		salesPerSecond += 1 / worker.interval
	end
	local seconds = math.min(secondsAway, config.capSeconds)
	return math.floor(salesPerSecond * saleValue * multiplier * config.efficiency * seconds)
end

return Offline
