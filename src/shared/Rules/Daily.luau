-- Pure daily login reward rules. Days are whole UTC days (unix seconds // 86400).
-- state: { lastDay, streak } (saved on the profile). config: { rewards = { day1, day2, ... } }
-- Claiming on consecutive days grows the streak; missing a day starts again at day 1.
-- After the last reward day, the final reward repeats.

local Daily = {}

function Daily.today(unixSeconds: number): number
	return unixSeconds // 86400
end

function Daily.canClaim(state, today: number): boolean
	return state.lastDay ~= today
end

-- Which streak day the next claim would be.
function Daily.nextStreak(state, today: number): number
	return if state.lastDay == today - 1 then state.streak + 1 else 1
end

function Daily.rewardFor(config, streak: number): number
	return config.rewards[math.min(streak, #config.rewards)]
end

-- Claims today's reward. Returns the cash reward, or nil if already claimed today.
function Daily.claim(config, state, today: number): number?
	if not Daily.canClaim(state, today) then
		return nil
	end
	state.streak = Daily.nextStreak(state, today)
	state.lastDay = today
	return Daily.rewardFor(config, state.streak)
end

return Daily
