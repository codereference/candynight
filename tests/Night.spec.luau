local t = require("./lib/t")
local NightOutcome = require("../src/shared/Rules/NightOutcome")
local Wave = require("../src/shared/Rules/Wave")
local Horde = require("../src/shared/Rules/Horde")

local NIGHT = { lossShare = 0.5, lossShareStep = 0.1, minLossShare = 0.2, failCashShare = 0.25, failBrokenDefenses = 2 }

local function night(streak, arrived, lost, options)
	local outcome = NightOutcome.new(NIGHT, streak, options)
	for _ = 1, arrived do
		outcome:customerArrived()
	end
	for _ = 1, lost do
		outcome:customerLost()
	end
	return outcome
end

t.test("allowed losses are a share of that night's customers", function()
	t.expect(night(0, 10, 0):allowed()).toBe(5)
	t.expect(night(0, 3, 0):allowed()).toBe(1)
end)

t.test("a longer streak means fewer allowed losses, down to a floor", function()
	t.expect(night(2, 10, 0):allowed()).toBe(3)
	t.expect(night(10, 10, 0):allowed()).toBe(2)
end)

t.test("surviving keeps cash and grows the streak", function()
	local result = night(3, 10, 2):settle(1000, { 1, 2 })
	t.expect(result.survived).toBe(true)
	t.expect(result.streak).toBe(4)
	t.expect(result.cashLost).toBe(0)
	t.expect(result.brokenDefenses).toEqual({})
end)

t.test("losing more than allowed fails: streak resets, some cash and defenses are lost", function()
	local result = night(0, 10, 6):settle(1000, { 7, 8, 9 })
	t.expect(result.survived).toBe(false)
	t.expect(result.streak).toBe(0)
	t.expect(result.cashLost).toBe(250)
	t.expect(result.brokenDefenses).toEqual({ 7, 8 })
end)

t.test("losing exactly the allowed amount still survives", function()
	t.expect(night(0, 10, 5):settle(0, {}).survived).toBe(true)
end)

t.test("the forgiving first night can't be failed", function()
	t.expect(night(0, 4, 4, { forgiving = true }):settle(100, {}).survived).toBe(true)
end)

t.test("a night shield adds to the allowance", function()
	local outcome = night(0, 10, 7)
	outcome:addAllowance(3)
	t.expect(outcome:allowed()).toBe(8)
	t.expect(outcome:isFailing()).toBe(false)
end)

local CREATURES = {
	baseCount = 3,
	countPerNight = 2,
	maxCount = 10,
	baseHealth = 40,
	healthGrowth = 0.5,
	speed = 6,
	speedGrowth = 0.1,
	spawnWindow = 0.5,
	biteDamage = 10,
}

t.test("later nights bring more, tougher, faster creatures, capped in number", function()
	t.expect(Wave.plan(CREATURES, 1)).toEqual({ count = 3, health = 40, speed = 6, bite = 10 })
	local third = Wave.plan(CREATURES, 3)
	t.expect(third.count).toBe(7)
	t.expect(third.health).toBe(80)
	t.expect(third.bite).toBe(20)
	t.expect(Wave.plan(CREATURES, 50).count).toBe(10)
end)

t.test("event modifiers scale the wave", function()
	local plan = Wave.plan(CREATURES, 1, { count = 2, health = 1.5 })
	t.expect(plan.count).toBe(6)
	t.expect(plan.health).toBe(60)
end)

t.test("creatures arrive spread across the spawn window, the first right away", function()
	local wave = Wave.new({ count = 3 }, 100, 0.5) -- one every 25 seconds
	t.expect(wave:tick(0.1)).toBe(1)
	t.expect(wave:tick(24)).toBe(0)
	t.expect(wave:tick(1)).toBe(1)
	t.expect(wave:tick(1000)).toBe(1)
	t.expect(wave:tick(1000)).toBe(0)
end)

t.test("creatures take damage and are defeated at zero health", function()
	local horde = Horde.new()
	local id = horde:spawn(50)
	t.expect(horde:damage(id, 20)).toBe(false)
	t.expect(horde:healthShare(id)).toBe(0.6)
	t.expect(horde:damage(id, 30)).toBe(true)
	t.expect(horde:isAlive(id)).toBe(false)
	t.expect(horde:damage(id, 10)).toBe(false)
end)
