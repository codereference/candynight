local t = require("./lib/t")
local Turrets = require("../src/shared/Rules/Turrets")

local TARGETS = { { id = 1, x = 10, z = 0 }, { id = 2, x = 4, z = 3 }, { id = 3, x = 50, z = 0 } }

t.test("turrets aim at the nearest target in range", function()
	t.expect(Turrets.pickTarget({ x = 0, z = 0 }, 20, TARGETS)).toBe(2)
end)

t.test("turrets ignore targets out of range", function()
	t.expect(Turrets.pickTarget({ x = 0, z = 0 }, 4, TARGETS)).toBe(nil)
end)

t.test("a loaded turret fires right away, then reloads", function()
	local turrets = Turrets.new()
	t.expect(turrets:ready(1, 0.1, 1, true)).toBe(true)
	t.expect(turrets:ready(1, 0.5, 1, true)).toBe(false)
	t.expect(turrets:ready(1, 0.5, 1, true)).toBe(true)
end)

t.test("with nothing to shoot, a turret waits loaded", function()
	local turrets = Turrets.new()
	t.expect(turrets:ready(1, 5, 1, false)).toBe(false)
	t.expect(turrets:ready(1, 0.01, 1, true)).toBe(true)
end)

t.test("overdrive reloads faster", function()
	local turrets = Turrets.new()
	turrets:ready(1, 0, 1, true)
	t.expect(turrets:ready(1, 0.5, 1, true, 2)).toBe(true)
end)
