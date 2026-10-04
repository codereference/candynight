local t = require("./lib/t")
local WeaponRules = require("../src/shared/Rules/WeaponRules")

local PIN = { damage = 20, cooldown = 0.5, range = 8 }
local BLASTER = { damage = 25, cooldown = 0.3, range = 40, ranged = true }

t.test("players own their saved weapons plus any unlocked by buttons", function()
	t.expect(WeaponRules.owned({ RollingPin = true }, { "CandyCaneSword" })).toEqual({ "CandyCaneSword", "RollingPin" })
	t.expect(WeaponRules.owned({ RollingPin = true }, { "RollingPin" })).toEqual({ "RollingPin" })
end)

t.test("a weapon can't swing again until its cooldown passes", function()
	local ok, last = WeaponRules.trySwing(PIN, nil, 10)
	t.expect(ok).toBe(true)
	t.expect((WeaponRules.trySwing(PIN, last, 10.3))).toBe(false)
	t.expect((WeaponRules.trySwing(PIN, last, 10.5))).toBe(true)
end)

local TARGETS = {
	{ id = 1, x = 3, z = 4 }, -- 5 away
	{ id = 2, x = 0, z = -7 }, -- 7 away
	{ id = 3, x = 30, z = 0 }, -- 30 away
}

t.test("melee hits everything within range, in any direction", function()
	t.expect(WeaponRules.hits(PIN, { x = 0, z = 0 }, TARGETS)).toEqual({ 1, 2 })
end)

t.test("ranged weapons hit only the nearest target in range", function()
	t.expect(WeaponRules.hits(BLASTER, { x = 25, z = 0 }, TARGETS)).toEqual({ 3 })
end)

t.test("nothing in range means no hits", function()
	t.expect(WeaponRules.hits(PIN, { x = 100, z = 100 }, TARGETS)).toEqual({})
	t.expect(WeaponRules.hits(BLASTER, { x = 100, z = 100 }, TARGETS)).toEqual({})
end)
