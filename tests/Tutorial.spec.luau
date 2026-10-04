local t = require("./lib/t")
local Tutorial = require("../src/shared/Rules/Tutorial")
local Profile = require("../src/shared/Persistence/Profile")

t.test("new players start by serving a customer", function()
	local profile = Profile.defaults()
	t.expect(Tutorial.current(profile.tutorial)).toBe("Serve")
	t.expect(Tutorial.advance(profile.tutorial, profile)).toBe(false)
end)

t.test("steps advance as the player makes progress", function()
	local profile = Profile.defaults()
	profile.stats.served = 1
	t.expect(Tutorial.advance(profile.tutorial, profile)).toBe(true)
	t.expect(Tutorial.current(profile.tutorial)).toBe("BuyTray")
	profile.owned.CupcakeTray = true
	Tutorial.advance(profile.tutorial, profile)
	t.expect(Tutorial.current(profile.tutorial)).toBe("BuyMore")
end)

t.test("progress made out of order skips steps already finished", function()
	local profile = Profile.defaults()
	profile.stats.served = 5
	profile.owned = { CupcakeTray = true, Walls = true, CookieJar = true, Oven = true, Staff1 = true }
	Tutorial.advance(profile.tutorial, profile)
	t.expect(Tutorial.current(profile.tutorial)).toBe("Defend")
end)

t.test("placing a defense finishes the tutorial", function()
	local profile = Profile.defaults()
	profile.stats.served = 5
	profile.owned = { CupcakeTray = true, Walls = true, CookieJar = true, Staff1 = true }
	profile.placed = { { id = 1 } }
	Tutorial.advance(profile.tutorial, profile)
	t.expect(Tutorial.current(profile.tutorial)).toBe(nil)
	t.expect(profile.tutorial.done).toBe(true)
end)

t.test("returning players can skip it", function()
	local profile = Profile.defaults()
	Tutorial.skip(profile.tutorial)
	t.expect(Tutorial.current(profile.tutorial)).toBe(nil)
end)
