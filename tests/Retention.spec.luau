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

local Codes = require("../src/shared/Rules/Codes")
local CODES = { SWEET = { cash = 500 }, OLD = { cash = 100, expires = 1000 } }

t.test("codes ignore case and spaces", function()
	t.expect(Codes.normalize(" sw eet ")).toBe("SWEET")
	t.expect(Codes.redeem(CODES, {}, "sweet", 0)).toEqual({ cash = 500 })
end)

t.test("each code works once per player", function()
	local redeemed = {}
	Codes.redeem(CODES, redeemed, "SWEET", 0)
	t.expect(select(2, Codes.redeem(CODES, redeemed, "SWEET", 0))).toBe("used")
	t.expect(Codes.redeem(CODES, {}, "SWEET", 0)).toEqual({ cash = 500 }) -- another player
end)

t.test("unknown and expired codes are refused", function()
	t.expect(select(2, Codes.redeem(CODES, {}, "NOPE", 0))).toBe("invalid")
	t.expect(select(2, Codes.redeem(CODES, {}, "OLD", 1000))).toBe("expired")
	t.expect(Codes.redeem(CODES, {}, "OLD", 999)).toEqual({ cash = 100, expires = 1000 })
end)

t.test("a refused code isn't marked as used", function()
	local redeemed = {}
	Codes.redeem(CODES, redeemed, "OLD", 2000)
	t.expect(redeemed).toEqual({})
end)

local Events = require("../src/shared/Rules/Events")
local EVENTS = {
	{ id = "BloodMoon", everyNthNight = 5, modifiers = { health = 1.5, reward = 2 } },
	{ id = "Spooky", startsAt = 1000, endsAt = 2000, modifiers = { reward = 1.5 } },
}

t.test("Blood Moon rises every fifth night", function()
	t.expect(Events.forNight(EVENTS, 4, 0)).toBe(nil)
	t.expect(Events.forNight(EVENTS, 5, 0).id).toBe("BloodMoon")
	t.expect(Events.forNight(EVENTS, 10, 0).id).toBe("BloodMoon")
end)

t.test("dated events only run inside their window", function()
	t.expect(Events.forNight(EVENTS, 1, 999)).toBe(nil)
	t.expect(Events.forNight(EVENTS, 1, 1000).id).toBe("Spooky")
	t.expect(Events.forNight(EVENTS, 1, 2000)).toBe(nil)
end)

t.test("when two events match, the first in the list wins", function()
	t.expect(Events.forNight(EVENTS, 5, 1500).id).toBe("BloodMoon")
end)
