local t = require("./lib/t")
local Rebirth = require("../src/shared/Rules/Rebirth")
local Income = require("../src/shared/Rules/Income")
local Economy = require("../src/shared/Rules/Economy")
local Profile = require("../src/shared/Persistence/Profile")

local REBIRTH = { baseCost = 10000, costGrowth = 2, multiplierPerRebirth = 0.5 }

t.test("each rebirth costs more and multiplies income more", function()
	t.expect(Rebirth.cost(REBIRTH, 0)).toBe(10000)
	t.expect(Rebirth.cost(REBIRTH, 2)).toBe(40000)
	t.expect(Rebirth.multiplier(REBIRTH, 0)).toBe(1)
	t.expect(Rebirth.multiplier(REBIRTH, 3)).toBe(2.5)
end)

t.test("rebirth needs enough cash and changes nothing otherwise", function()
	local profile, wallet = Profile.defaults(), Economy.new(9999)
	profile.owned.Oven = true
	t.expect(select(2, Rebirth.apply(REBIRTH, profile, wallet))).toBe("cash")
	t.expect(profile.rebirths).toBe(0)
	t.expect(profile.owned.Oven).toBe(true)
end)

t.test("rebirth resets the shop but keeps long-term progress", function()
	local profile, wallet = Profile.defaults(), Economy.new(12000)
	profile.owned = { Oven = true }
	profile.placed = { { id = 1, kind = "GumdropTurret", col = 1, row = 1, rot = 0, hp = 100 } }
	profile.weapons = { RollingPin = true, CandyCaneSword = true }
	profile.bestStreak = 7
	profile.cosmetics.owned.Mint = true

	t.expect(Rebirth.apply(REBIRTH, profile, wallet)).toBe(true)
	t.expect(wallet:getCash()).toBe(0)
	t.expect(profile.rebirths).toBe(1)
	t.expect(profile.owned).toEqual({})
	t.expect(profile.placed).toEqual({})
	t.expect(profile.weapons).toEqual({ RollingPin = true })
	t.expect(profile.bestStreak).toBe(7)
	t.expect(profile.cosmetics.owned.Mint).toBe(true)
end)

local INCOME = { vipBonus = 0.1, groupBonus = 0.1, friendBonus = 0.1, maxFriends = 3 }

t.test("with no boosts, income is unchanged", function()
	t.expect(Income.multiplier(INCOME, {})).toBe(1)
end)

t.test("boosts stack: rebirth, 2x cash, VIP, group, friends, events", function()
	local total = Income.multiplier(INCOME, {
		rebirthMultiplier = 2,
		doubleCash = true,
		vip = true,
		inGroup = true,
		friends = 1,
		event = 2,
	})
	t.expect(math.abs(total - 2 * 2 * 1.1 * 1.1 * 1.1 * 2) < 1e-9).toBe(true)
end)

t.test("the friend bonus is capped", function()
	t.expect(Income.multiplier(INCOME, { friends = 10 })).toBe(1.3)
end)

local Offline = require("../src/shared/Rules/Offline")
local OFFLINE = { capSeconds = 8 * 3600, minSeconds = 60, efficiency = 0.5 }

t.test("staff earn at half speed while you're away", function()
	-- one worker serving every 4s at $10 for 400s = 100 sales, half rate = $500
	t.expect(Offline.earnings(OFFLINE, 400, { { interval = 4 } }, 10, 1)).toBe(500)
end)

t.test("offline earnings are capped", function()
	local capped = Offline.earnings(OFFLINE, 100 * 3600, { { interval = 4 } }, 10, 1)
	t.expect(capped).toBe(Offline.earnings(OFFLINE, 8 * 3600, { { interval = 4 } }, 10, 1))
end)

t.test("no staff or a quick rejoin earns nothing", function()
	t.expect(Offline.earnings(OFFLINE, 5000, {}, 10, 1)).toBe(0)
	t.expect(Offline.earnings(OFFLINE, 30, { { interval = 4 } }, 10, 1)).toBe(0)
end)

t.test("boosts apply to offline earnings too", function()
	t.expect(Offline.earnings(OFFLINE, 400, { { interval = 4 } }, 10, 2)).toBe(1000)
end)

local Badges = require("../src/shared/Rules/Badges")

t.test("a fresh profile has no badges to award", function()
	t.expect(Badges.award(Profile.defaults())).toEqual({})
end)

t.test("reaching milestones awards their badges once", function()
	local profile = Profile.defaults()
	profile.stats.served = 1
	profile.nightsSurvived = 1
	profile.bestStreak = 6
	t.expect(Badges.award(profile)).toEqual({ "FirstSale", "FirstNight", "Streak5" })
	t.expect(Badges.award(profile)).toEqual({})
	t.expect(profile.badges.Streak5).toBe(true)
end)

t.test("badges survive a rebirth because they're based on long-term stats", function()
	local profile = Profile.defaults()
	profile.rebirths = 1
	t.expect(Badges.award(profile)).toEqual({ "FirstRebirth" })
end)
