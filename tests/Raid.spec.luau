local t = require("./lib/t")
local Raid = require("../src/shared/Rules/Raid")
local Economy = require("../src/shared/Rules/Economy")

local CONFIG = { stealShare = 0.1, stealCap = 500, stealCooldown = 30 }
local THIEF, VICTIM = 1, 2

t.test("raiding is impossible during the day", function()
	local raid = Raid.new(CONFIG)
	local victim, thief = Economy.new(1000), Economy.new(0)
	local amount, reason = raid:steal(THIEF, VICTIM, victim, thief, false, 0)
	t.expect(amount).toBe(0)
	t.expect(reason).toBe("day")
	t.expect(victim:getCash()).toBe(1000)
end)

t.test("a night steal takes a share of the victim's cash", function()
	local raid = Raid.new(CONFIG)
	local victim, thief = Economy.new(1000), Economy.new(0)
	t.expect((raid:steal(THIEF, VICTIM, victim, thief, true, 0))).toBe(100)
	t.expect(victim:getCash()).toBe(900)
	t.expect(thief:getCash()).toBe(100)
end)

t.test("one steal can never take more than the cap", function()
	local raid = Raid.new(CONFIG)
	t.expect((raid:steal(THIEF, VICTIM, Economy.new(1000000), Economy.new(0), true, 0))).toBe(500)
end)

t.test("you can't rob your own shop", function()
	t.expect(select(2, Raid.new(CONFIG):canSteal(THIEF, THIEF, true, 0))).toBe("own")
end)

t.test("there's a cooldown before robbing the same shop again", function()
	local raid = Raid.new(CONFIG)
	raid:steal(THIEF, VICTIM, Economy.new(1000), Economy.new(0), true, 0)
	t.expect(select(2, raid:canSteal(THIEF, VICTIM, true, 10))).toBe("cooldown")
	t.expect(raid:canSteal(THIEF, 3, true, 10)).toBe(true) -- a different shop is fine
	t.expect(raid:canSteal(THIEF, VICTIM, true, 30)).toBe(true)
end)

t.test("a caught invader is locked out until the next night", function()
	local raid = Raid.new(CONFIG)
	raid:lockOut(THIEF)
	t.expect(select(2, raid:canSteal(THIEF, VICTIM, true, 0))).toBe("locked")
	raid:beginNight()
	t.expect(raid:canSteal(THIEF, VICTIM, true, 0)).toBe(true)
end)

t.test("only a defender on their own plot can hurt, and only at night", function()
	local raid = Raid.new(CONFIG)
	t.expect(raid:canHurt(VICTIM, THIEF, VICTIM, true)).toBe(true) -- defender hits invader at home
	t.expect(raid:canHurt(THIEF, VICTIM, VICTIM, true)).toBe(false) -- invader can't hit back
	t.expect(raid:canHurt(VICTIM, THIEF, VICTIM, false)).toBe(false) -- no PvP by day
	t.expect(raid:canHurt(VICTIM, THIEF, 3, true)).toBe(false) -- not on someone else's plot
end)
