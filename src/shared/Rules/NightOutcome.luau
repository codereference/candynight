-- Pure rules for one shop's night: counting customers and losses, and settling the result at dawn.
-- The allowed losses are a share of that night's customers, and the share shrinks as the streak grows.

local NightOutcome = {}
NightOutcome.__index = NightOutcome

-- config: { lossShare, lossShareStep, minLossShare, failCashShare, failBrokenDefenses }
function NightOutcome.lossShare(config, streak: number): number
	return math.max(config.minLossShare, config.lossShare - streak * config.lossShareStep)
end

-- options: { forgiving: boolean? (first night: can't fail), bonusAllowance: number? (night shield) }
function NightOutcome.new(config, streak: number, options)
	options = options or {}
	return setmetatable({
		config = config,
		streak = streak,
		arrived = 0,
		lost = 0,
		forgiving = options.forgiving == true,
		bonusAllowance = options.bonusAllowance or 0,
	}, NightOutcome)
end

function NightOutcome:customerArrived()
	self.arrived += 1
end

function NightOutcome:customerLost()
	self.lost += 1
end

function NightOutcome:addAllowance(amount: number)
	self.bonusAllowance += amount
end

function NightOutcome:allowed(): number
	return math.floor(self.arrived * NightOutcome.lossShare(self.config, self.streak)) + self.bonusAllowance
end

function NightOutcome:isFailing(): boolean
	return not self.forgiving and self.lost > self:allowed()
end

-- Settles the night at dawn. Pure: returns what should change; the caller applies it.
-- cash: the owner's cash now. defenseIds: ids of standing defenses, in the order to break them.
function NightOutcome:settle(cash: number, defenseIds: { number })
	local survived = not self:isFailing()
	local result = {
		survived = survived,
		lost = self.lost,
		allowed = self:allowed(),
		streak = if survived then self.streak + 1 else 0,
		cashLost = 0,
		brokenDefenses = {},
	}
	if not survived then
		result.cashLost = math.floor(cash * self.config.failCashShare)
		for i = 1, math.min(self.config.failBrokenDefenses, #defenseIds) do
			table.insert(result.brokenDefenses, defenseIds[i])
		end
	end
	return result
end

return NightOutcome
