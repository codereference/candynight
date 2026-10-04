-- Pure onboarding rules. Each step is finished by the player's actual progress (not by events),
-- so doing things out of order never leaves the tutorial stuck.
-- state: the profile's { step, done } ; profile: the whole profile.

local Tutorial = {}

local function ownedCount(profile): number
	local count = 0
	for _ in profile.owned do
		count += 1
	end
	return count
end

Tutorial.STEPS = {
	{
		key = "Serve",
		finished = function(p)
			return p.stats.served >= 1
		end,
	},
	{
		key = "BuyTray",
		finished = function(p)
			return p.owned.CupcakeTray == true
		end,
	},
	{
		key = "BuyMore",
		finished = function(p)
			return ownedCount(p) >= 3
		end,
	},
	{
		key = "Hire",
		finished = function(p)
			return p.owned.Staff1 == true
		end,
	},
	{
		key = "Defend",
		finished = function(p)
			return #p.placed >= 1
		end,
	},
}

-- The step the player is on, or nil once the tutorial is done.
function Tutorial.current(state): string?
	if state.done then
		return nil
	end
	local step = Tutorial.STEPS[state.step]
	return step and step.key
end

-- Moves past every step the profile has already finished. Returns true if anything changed.
function Tutorial.advance(state, profile): boolean
	local changed = false
	while not state.done do
		local step = Tutorial.STEPS[state.step]
		if step == nil then
			state.done = true
			changed = true
		elseif step.finished(profile) then
			state.step += 1
			changed = true
		else
			break
		end
	end
	return changed
end

function Tutorial.skip(state)
	state.done = true
end

return Tutorial
