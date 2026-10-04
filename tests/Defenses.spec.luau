local t = require("./lib/t")
local Grid = require("../src/shared/Rules/Grid")
local Defenses = require("../src/shared/Rules/Defenses")
local Economy = require("../src/shared/Rules/Economy")

-- A small 4x4 plot (cells of 4 studs) with one no-build zone over the top-left cell.
local LAYOUT = { PLOT_SIZE = 16, CELL = 4, GRID = 4, ZONES = { shop = { -8, -4, -8, -4 } } }
local CATALOG = {
	Gumdrop = { cost = 100, hp = 100 },
	Cannon = { cost = 500, hp = 300, requires = "WeaponsPack" },
}
local CONFIG = { maxPlaced = 3, sellShare = 0.5, repairShare = 0.4 }

local function fresh(cash)
	return { placed = {}, nextPlacedId = 1 }, Economy.new(cash or 1000), Grid.new(LAYOUT)
end

local function place(state, wallet, grid, kind, col, row, rot, owned)
	return Defenses.place(state, wallet, grid, CATALOG, CONFIG, owned or {}, kind, col, row, rot or 0)
end

t.test("grid cells map to and from plot-local positions", function()
	local grid = Grid.new(LAYOUT)
	t.expect({ grid:cellAt(-7, -7) }).toEqual({ 1, 1 })
	t.expect({ grid:cellAt(7.9, 0.1) }).toEqual({ 4, 3 })
	t.expect({ grid:cellRect(2, 1) }).toEqual({ -4, 0, -8, -4 })
end)

t.test("placing buys the defense at full health with a new id", function()
	local state, wallet, grid = fresh()
	local entry = place(state, wallet, grid, "Gumdrop", 2, 2, 90)
	t.expect(entry).toEqual({ id = 1, kind = "Gumdrop", col = 2, row = 2, rot = 90, hp = 100 })
	t.expect(wallet:getCash()).toBe(900)
	t.expect(state.nextPlacedId).toBe(2)
end)

t.test("can't place off the plot, on a no-build zone, or on another defense", function()
	local state, wallet, grid = fresh()
	t.expect(select(2, place(state, wallet, grid, "Gumdrop", 5, 1))).toBe("bounds")
	t.expect(select(2, place(state, wallet, grid, "Gumdrop", 1, 1))).toBe("blocked")
	place(state, wallet, grid, "Gumdrop", 2, 2)
	t.expect(select(2, place(state, wallet, grid, "Gumdrop", 2, 2))).toBe("occupied")
	t.expect(wallet:getCash()).toBe(900)
end)

t.test("locked, unaffordable, odd rotations and full plots are refused", function()
	local state, wallet, grid = fresh(150)
	t.expect(select(2, place(state, wallet, grid, "Cannon", 2, 2))).toBe("locked")
	t.expect(select(2, place(state, wallet, grid, "Cannon", 2, 2, 0, { WeaponsPack = true }))).toBe("cash")
	t.expect(select(2, place(state, wallet, grid, "Gumdrop", 2, 2, 45))).toBe("rotation")
	t.expect(select(2, place(state, wallet, grid, "Nope", 2, 2))).toBe("unknown")

	local busy, rich = fresh(10000)
	for col = 2, 4 do
		place(busy, rich, grid, "Gumdrop", col, 2)
	end
	t.expect(select(2, place(busy, rich, grid, "Gumdrop", 2, 3))).toBe("full")
end)

t.test("moving keeps the defense but checks the new cell", function()
	local state, wallet, grid = fresh()
	local a = place(state, wallet, grid, "Gumdrop", 2, 2)
	place(state, wallet, grid, "Gumdrop", 3, 3)
	t.expect(select(2, Defenses.move(state, grid, a.id, 3, 3, 0))).toBe("occupied")
	t.expect(Defenses.move(state, grid, a.id, 2, 2, 180)).toBe(true) -- staying put is fine
	t.expect(Defenses.move(state, grid, a.id, 4, 4, 90)).toBe(true)
	t.expect({ a.col, a.row, a.rot }).toEqual({ 4, 4, 90 })
end)

t.test("selling refunds half the price, less if damaged", function()
	local state, wallet, grid = fresh()
	local a = place(state, wallet, grid, "Gumdrop", 2, 2)
	a.hp = 50
	t.expect(Defenses.sell(state, wallet, CATALOG, CONFIG, a.id)).toBe(25)
	t.expect(#state.placed).toBe(0)
	t.expect(wallet:getCash()).toBe(925)
	t.expect(Defenses.sell(state, wallet, CATALOG, CONFIG, a.id)).toBe(nil)
end)

t.test("damage wears a defense down until it's destroyed", function()
	local state, wallet, grid = fresh()
	local a = place(state, wallet, grid, "Gumdrop", 2, 2)
	t.expect(Defenses.damage(state, a.id, 60)).toBe(false)
	t.expect(Defenses.damage(state, a.id, 60)).toBe(true)
	t.expect(a.hp).toBe(0)
	t.expect(Defenses.damage(state, a.id, 10)).toBe(false)
end)

t.test("repairing costs a share of the price for the missing health", function()
	local state, wallet, grid = fresh()
	local a = place(state, wallet, grid, "Gumdrop", 2, 2)
	t.expect(select(2, Defenses.repair(state, wallet, CATALOG, CONFIG, a.id))).toBe("full")
	a.hp = 0
	t.expect(Defenses.repairCost(CATALOG, CONFIG, a)).toBe(40)
	t.expect(Defenses.repair(state, wallet, CATALOG, CONFIG, a.id)).toBe(true)
	t.expect(a.hp).toBe(100)
	t.expect(wallet:getCash()).toBe(860)
end)

t.test("on the real plot, the shop, customer path and buttons are no-build, open lawn is fine", function()
	local Layout = require("../src/shared/Layout")
	local grid = Grid.new(Layout)
	t.expect(grid:isBlocked(grid:cellAt(0, -20))).toBe(true) -- customer queue
	t.expect(grid:isBlocked(grid:cellAt(0, 0))).toBe(true) -- shop
	t.expect(grid:isBlocked(grid:cellAt(25, 0))).toBe(true) -- buttons
	t.expect(grid:isBlocked(grid:cellAt(-25, 10))).toBe(false) -- side lawn
	t.expect(grid:isBlocked(grid:cellAt(10, -25))).toBe(false) -- front lawn
end)
