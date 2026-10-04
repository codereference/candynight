-- Pure cash rules for one player's wallet.
-- Rules modules never touch Roblox APIs or require other modules, so Lune can test them headless.

local Economy = {}
Economy.__index = Economy

function Economy.new(startingCash: number?)
	return setmetatable({ cash = startingCash or 0 }, Economy)
end

function Economy:getCash(): number
	return self.cash
end

function Economy:canAfford(cost: number): boolean
	return cost >= 0 and self.cash >= cost
end

-- Cash is always whole and never goes down through earning. Returns the amount actually added.
function Economy:earn(amount: number): number
	local applied = math.max(0, math.floor(amount))
	self.cash += applied
	return applied
end

-- Returns false (and changes nothing) when the wallet can't cover the cost.
function Economy:spend(cost: number): boolean
	if not self:canAfford(cost) then
		return false
	end
	self.cash -= cost
	return true
end

return Economy
