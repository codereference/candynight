local t = require("./lib/t")
local Entitlements = require("../src/shared/Rules/Entitlements")

local OWNER = 5224066822
local CONFIG = {
	ownerIds = { OWNER },
	passes = {
		DoubleCash = { id = 1, perk = "doubleCash" },
		VIP = { id = 2, perk = "vip" },
		ExtraHelper = { id = 3, perk = "extraHelper" },
	},
}

t.test("players only get the passes they own", function()
	t.expect(Entitlements.perks(CONFIG, { DoubleCash = true }, 42)).toEqual({ doubleCash = true })
	t.expect(Entitlements.hasPass(CONFIG, {}, 42, "VIP")).toBe(false)
end)

t.test("the owner gets every pass free", function()
	t.expect(Entitlements.perks(CONFIG, {}, OWNER)).toEqual({ doubleCash = true, vip = true, extraHelper = true })
	t.expect(Entitlements.isOwner(CONFIG, 42)).toBe(false)
end)

t.test("overhead tags: Owner beats VIP, nothing for regular players", function()
	t.expect(Entitlements.tag(CONFIG, { VIP = true }, OWNER)).toBe("Owner")
	t.expect(Entitlements.tag(CONFIG, { VIP = true }, 42)).toBe("VIP")
	t.expect(Entitlements.tag(CONFIG, {}, 42)).toBe(nil)
end)

local Receipts = require("../src/shared/Rules/Receipts")
local SaveSession = require("../src/shared/Persistence/SaveSession")
local MemoryStorage = require("../src/shared/Persistence/MemoryStorage")

t.test("a receipt is granted once, and a retry grants nothing", function()
	local receipts, grants = {}, 0
	local function grant()
		grants += 1
		return true
	end
	t.expect(Receipts.process(receipts, "p1", 100, grant)).toBe("granted")
	t.expect(Receipts.process(receipts, "p1", 101, grant)).toBe("already")
	t.expect(grants).toBe(1)
end)

t.test("a failed grant isn't recorded, so Roblox can retry it", function()
	local receipts = {}
	t.expect(Receipts.process(receipts, "p1", 100, function()
		return false
	end)).toBe("failed")
	t.expect(receipts).toEqual({})
end)

t.test("a saved receipt survives a server restart, so the retry is recognised", function()
	local storage = MemoryStorage.new()
	local session = SaveSession.load(storage, "Player_1")
	Receipts.process(session.profile.receipts, "p1", 100, function()
		session.profile.cash += 500
		return true
	end)
	t.expect(session:save()).toBe(true) -- saved before acknowledging the purchase

	local afterRestart = SaveSession.load(storage, "Player_1")
	t.expect(Receipts.process(afterRestart.profile.receipts, "p1", 200, function()
		afterRestart.profile.cash += 500
		return true
	end)).toBe("already")
	t.expect(afterRestart.profile.cash).toBe(500)
end)

t.test("old receipts are pruned, newest kept", function()
	local receipts = { a = 1, b = 3, c = 2 }
	Receipts.prune(receipts, 2)
	t.expect(receipts).toEqual({ b = 3, c = 2 })
end)
