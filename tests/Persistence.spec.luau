local t = require("./lib/t")
local Profile = require("../src/shared/Persistence/Profile")
local SaveSession = require("../src/shared/Persistence/SaveSession")
local MemoryStorage = require("../src/shared/Persistence/MemoryStorage")

t.test("a brand-new player gets a default profile and can save", function()
	local session = SaveSession.load(MemoryStorage.new(), "Player_1")
	t.expect(session.profile.cash).toBe(0)
	t.expect(session.profile.version).toBe(Profile.VERSION)
	t.expect(session.canSave).toBe(true)
end)

t.test("progress survives a save and a fresh load", function()
	local storage = MemoryStorage.new()
	local first = SaveSession.load(storage, "Player_1")
	first.profile.cash = 250
	first.profile.owned.CupcakeTray = true
	t.expect(first:close()).toBe(true)

	local second = SaveSession.load(storage, "Player_1")
	t.expect(second.profile.cash).toBe(250)
	t.expect(second.profile.owned).toEqual({ CupcakeTray = true })
end)

t.test("a failed load never writes, so real data can't be wiped", function()
	local storage = MemoryStorage.new()
	storage.data.Player_1 = { version = 1, cash = 9000 }
	storage.failLoads = true

	local session = SaveSession.load(storage, "Player_1")
	t.expect(session.canSave).toBe(false)
	t.expect(session.profile.cash).toBe(0)
	t.expect(session:save()).toBe(false)
	t.expect(session:close()).toBe(false)
	t.expect(storage.writes).toBe(0)
	t.expect(storage.data.Player_1.cash).toBe(9000)
end)

t.test("a failed save reports failure", function()
	local storage = MemoryStorage.new()
	local session = SaveSession.load(storage, "Player_1")
	storage.failSaves = true
	t.expect(session:save()).toBe(false)
end)

t.test("closing stops any later saves", function()
	local storage = MemoryStorage.new()
	local session = SaveSession.load(storage, "Player_1")
	session:close()
	t.expect(session:save()).toBe(false)
	t.expect(storage.writes).toBe(1)
end)

t.test("old saves gain new fields without losing their values", function()
	local storage = MemoryStorage.new()
	storage.data.Player_1 = { version = 1, cash = 40, daily = { streak = 3 } }
	local profile = SaveSession.load(storage, "Player_1").profile
	t.expect(profile.cash).toBe(40)
	t.expect(profile.daily).toEqual({ streak = 3, lastDay = 0 })
	t.expect(profile.weapons).toEqual({ RollingPin = true })
end)

t.test("garbage in storage becomes a default profile", function()
	t.expect(Profile.migrate("nonsense").cash).toBe(0)
end)
