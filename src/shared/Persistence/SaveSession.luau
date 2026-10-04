-- Loads and saves one player's profile through a storage implementation.
-- Storage interface (the persistence seam):
--   storage:load(key) -> (ok: boolean, data: any)   -- data is nil for a brand-new player
--   storage:save(key, data) -> ok: boolean
--   storage:release(key, data) -> ok: boolean        -- final save that also gives up the session lock
-- Safety rule: if the load failed, this session never writes, so an outage can't wipe real progress.

-- Classic require inside Roblox; Lune (tests) has no `script`, so it uses the file path.
local Profile = if script then require(script.Parent.Profile) else require("./Profile")

local SaveSession = {}
SaveSession.__index = SaveSession

function SaveSession.load(storage, key: string)
	local ok, data = storage:load(key)
	return setmetatable({
		storage = storage,
		key = key,
		canSave = ok,
		profile = if ok then Profile.migrate(data) else Profile.defaults(),
	}, SaveSession)
end

function SaveSession:save(): boolean
	if not self.canSave then
		return false
	end
	return self.storage:save(self.key, self.profile)
end

-- Final save when the player leaves. The session can't save again afterwards.
function SaveSession:close(): boolean
	if not self.canSave then
		return false
	end
	self.canSave = false
	return self.storage:release(self.key, self.profile)
end

return SaveSession
