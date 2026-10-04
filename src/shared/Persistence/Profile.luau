-- The saved record for one player. Pure: no Roblox APIs.
-- New fields go in defaults(); migrate() fills them into older saves automatically.

local Profile = {}

Profile.VERSION = 1

function Profile.defaults()
	return {
		version = Profile.VERSION,
		cash = 0,
		owned = {}, -- [buttonId] = true
		placed = {}, -- grid defenses: { id, kind, col, row, rot, hp }
		nextPlacedId = 1,
		weapons = { RollingPin = true },
		streak = 0,
		bestStreak = 0,
		nightsSurvived = 0,
		rebirths = 0,
		lastOnline = 0, -- unix seconds
		daily = { lastDay = 0, streak = 0 },
		codes = {}, -- [code] = true
		cosmetics = { owned = {}, equipped = {} },
		tutorial = { step = 1, done = false, firstNightDone = false },
		receipts = {}, -- [purchaseId] = unix time granted, for exactly-once dev products
		boosts = { overdrive = 0, shield = 0 }, -- bought boosts waiting for the next night
		badges = {}, -- [badgeKey] = true
		stats = { served = 0 },
	}
end

-- Version upgrades, keyed by the version they upgrade from. Each returns the next version's data.
local MIGRATIONS: { [number]: (any) -> any } = {}

local function fillMissing(target, defaults)
	for key, value in defaults do
		if target[key] == nil then
			target[key] = value
		elseif type(value) == "table" and type(target[key]) == "table" and next(value) ~= nil then
			-- Only recurse into tables with fixed fields; empty defaults are open-ended maps/lists.
			fillMissing(target[key], value)
		end
	end
end

-- Turns whatever came out of storage (nil for a new player) into a current-version profile.
function Profile.migrate(data: any)
	if type(data) ~= "table" then
		return Profile.defaults()
	end
	local version = data.version or 1
	while MIGRATIONS[version] do
		data = MIGRATIONS[version](data)
		version += 1
	end
	data.version = Profile.VERSION
	fillMissing(data, Profile.defaults())
	return data
end

return Profile
