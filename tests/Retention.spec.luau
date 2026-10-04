local t = require("./lib/t")
local Daily = require("../src/shared/Rules/Daily")

local DAILY = { rewards = { 100, 200, 300 } }

t.test("days roll over at UTC midnight", function()
	t.expect(Daily.today(86399)).toBe(0)
	t.expect(Daily.today(86400)).toBe(1)
end)

t.test("the first claim is day 1", function()
	local state = { lastDay = 0, streak = 0 }
	t.expect(Daily.claim(DAILY, state, 500)).toBe(100)
	t.expect(state).toEqual({ lastDay = 500, streak = 1 })
end)

t.test("you can only claim once a day", function()
	local state = { lastDay = 0, streak = 0 }
	Daily.claim(DAILY, state, 500)
	t.expect(Daily.canClaim(state, 500)).toBe(false)
	t.expect(Daily.claim(DAILY, state, 500)).toBe(nil)
end)

t.test("claiming on consecutive days grows the reward", function()
	local state = { lastDay = 0, streak = 0 }
	Daily.claim(DAILY, state, 500)
	t.expect(Daily.claim(DAILY, state, 501)).toBe(200)
	t.expect(Daily.claim(DAILY, state, 502)).toBe(300)
end)

t.test("after the last day, the top reward repeats", function()
	local state = { lastDay = 502, streak = 3 }
	t.expect(Daily.claim(DAILY, state, 503)).toBe(300)
	t.expect(state.streak).toBe(4)
end)

t.test("missing a day starts the streak over", function()
	local state = { lastDay = 500, streak = 2 }
	t.expect(Daily.nextStreak(state, 502)).toBe(1)
	t.expect(Daily.claim(DAILY, state, 502)).toBe(100)
end)
