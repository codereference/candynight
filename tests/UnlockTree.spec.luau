local t = require("./lib/t")
local UnlockTree = require("../src/shared/Rules/UnlockTree")
local Economy = require("../src/shared/Rules/Economy")

local CATALOG = {
	{ id = "Tray", cost = 10, goods = 3 },
	{ id = "Walls", cost = 20, requires = "Tray" },
	{ id = "Sign", cost = 30, decor = 1, requires = "Walls" },
	{ id = "Baker", cost = 50, staff = 4, requires = "Tray" },
	{ id = "Jar", cost = 15, goods = 5, requires = "Tray" },
}

t.test("only buttons without prerequisites are available at the start", function()
	t.expect(UnlockTree.new(CATALOG):available({})).toEqual({ "Tray" })
end)

t.test("buying reveals the buttons that depend on it, in catalog order", function()
	local tree = UnlockTree.new(CATALOG)
	local owned = {}
	tree:buy(owned, Economy.new(100), "Tray")
	t.expect(tree:available(owned)).toEqual({ "Walls", "Baker", "Jar" })
end)

t.test("buying spends the cost and marks it owned", function()
	local tree, owned, wallet = UnlockTree.new(CATALOG), {}, Economy.new(25)
	t.expect(tree:buy(owned, wallet, "Tray")).toBe(true)
	t.expect(wallet:getCash()).toBe(15)
	t.expect(owned.Tray).toBe(true)
end)

t.test("can't buy without enough cash, and nothing changes", function()
	local tree, owned, wallet = UnlockTree.new(CATALOG), {}, Economy.new(5)
	local ok, reason = tree:buy(owned, wallet, "Tray")
	t.expect(ok).toBe(false)
	t.expect(reason).toBe("cash")
	t.expect(wallet:getCash()).toBe(5)
	t.expect(owned.Tray).toBe(nil)
end)

t.test("can't buy something locked behind a prerequisite", function()
	local _, reason = UnlockTree.new(CATALOG):buy({}, Economy.new(100), "Walls")
	t.expect(reason).toBe("locked")
end)

t.test("can't buy the same thing twice", function()
	local tree, owned, wallet = UnlockTree.new(CATALOG), {}, Economy.new(100)
	tree:buy(owned, wallet, "Tray")
	local _, reason = tree:buy(owned, wallet, "Tray")
	t.expect(reason).toBe("owned")
	t.expect(wallet:getCash()).toBe(90)
end)

t.test("unknown buttons are rejected", function()
	local _, reason = UnlockTree.new(CATALOG):buy({}, Economy.new(100), "Nope")
	t.expect(reason).toBe("unknown")
end)

t.test("effects add up goods, decor and staff from everything owned", function()
	local owned = { Tray = true, Walls = true, Sign = true, Baker = true, Jar = true }
	t.expect(UnlockTree.new(CATALOG):effects(owned)).toEqual({ goods = 8, decor = 1, staff = { 4 }, weapons = {} })
end)

t.test("owned items come back in catalog order for rebuilding", function()
	local owned = { Jar = true, Tray = true }
	t.expect(UnlockTree.new(CATALOG):ownedInOrder(owned)).toEqual({ "Tray", "Jar" })
end)
