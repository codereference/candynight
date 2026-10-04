-- Pure raiding rules. Players are identified by user id; times are seconds.
-- Raiding only happens at night. A steal takes a share of the victim's cash, capped, with a
-- cooldown per victim. An invader caught (defeated) by the defender is locked out until next night.
-- Only the defender can hurt invaders, and only inside their own shop.

local Raid = {}
Raid.__index = Raid

-- config: { stealShare, stealCap, stealCooldown }
function Raid.new(config)
	return setmetatable({ config = config, lockedOut = {}, lastSteal = {} }, Raid)
end

-- A new night: everyone may raid again.
function Raid:beginNight()
	table.clear(self.lockedOut)
	table.clear(self.lastSteal)
end

function Raid:isLockedOut(userId: number): boolean
	return self.lockedOut[userId] == true
end

function Raid:lockOut(userId: number)
	self.lockedOut[userId] = true
end

-- Returns true, or false plus "day" | "own" | "locked" | "cooldown".
function Raid:canSteal(thiefId: number, victimId: number, isNight: boolean, now: number): (boolean, string?)
	if not isNight then
		return false, "day"
	elseif thiefId == victimId then
		return false, "own"
	elseif self.lockedOut[thiefId] then
		return false, "locked"
	end
	local last = self.lastSteal[thiefId .. ":" .. victimId]
	if last and now - last < self.config.stealCooldown then
		return false, "cooldown"
	end
	return true, nil
end

-- Moves cash from victim to thief if allowed. Returns the amount stolen (0 if not allowed) and a reason.
function Raid:steal(thiefId: number, victimId: number, victimWallet, thiefWallet, isNight: boolean, now: number)
	local ok, reason = self:canSteal(thiefId, victimId, isNight, now)
	if not ok then
		return 0, reason
	end
	local amount = math.min(self.config.stealCap, math.floor(victimWallet:getCash() * self.config.stealShare))
	if amount > 0 then
		victimWallet:spend(amount)
		thiefWallet:earn(amount)
	end
	self.lastSteal[thiefId .. ":" .. victimId] = now
	return amount, nil
end

-- Whether attacker may hurt target: only at night, only a defender on their own plot, never themselves.
function Raid:canHurt(attackerId: number, targetId: number, plotOwnerId: number?, isNight: boolean): boolean
	return isNight and attackerId ~= targetId and plotOwnerId == attackerId
end

return Raid
