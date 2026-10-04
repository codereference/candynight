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
