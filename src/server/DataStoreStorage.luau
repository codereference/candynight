-- Production storage: Roblox DataStore with retries and session locking.
-- Same interface as MemoryStorage (see SaveSession). Each record is { data = profile, lock = { jobId, time } }.
-- The lock stops two servers writing the same player at once (e.g. while they hop servers).

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local DataStoreStorage = {}
DataStoreStorage.__index = DataStoreStorage

local LOAD_ATTEMPTS = 18
local LOAD_RETRY_SECONDS = 5 -- 18 x 5s outlasts LOCK_TIMEOUT, so a crashed server's lock always expires in time
local SAVE_ATTEMPTS = 3
local LOCK_TIMEOUT = 75 -- seconds; autosave (every 60s) refreshes the lock within this

function DataStoreStorage.new(name: string)
	local ok, store = pcall(DataStoreService.GetDataStore, DataStoreService, name)
	if not ok then
		warn("[Save] DataStores unavailable, progress will not save:", store)
		store = nil
	end
	return setmetatable({ store = store }, DataStoreStorage)
end

local function lockedByOther(record): boolean
	local lock = record and record.lock
	return lock ~= nil and lock.jobId ~= game.JobId and os.time() - lock.time < LOCK_TIMEOUT
end

function DataStoreStorage:load(key: string): (boolean, any)
	if not self.store then
		return false, nil
	end
	for attempt = 1, LOAD_ATTEMPTS do
		local data, blocked = nil, false
		local ok, err = pcall(function()
			self.store:UpdateAsync(key, function(record)
				if lockedByOther(record) then
					blocked = true
					return nil -- cancel the write, keep the other server's lock
				end
				record = record or {}
				record.lock = { jobId = game.JobId, time = os.time() }
				data = record.data
				return record
			end)
		end)
		if ok and not blocked then
			return true, data
		end
		warn(`[Save] load {key} attempt {attempt} failed:`, if blocked then "locked by another server" else err)
		if not blocked and RunService:IsStudio() then
			break -- usually "Studio access to API services" is off; don't make playtests wait
		end
		task.wait(LOAD_RETRY_SECONDS)
	end
	return false, nil
end

function DataStoreStorage:_write(key: string, data: any, keepLock: boolean): boolean
	if not self.store then
		return false
	end
	for attempt = 1, SAVE_ATTEMPTS do
		local stolen = false
		local ok, err = pcall(function()
			self.store:UpdateAsync(key, function(record)
				-- Only the server holding the lock may write. A save that lands after we released
				-- (or after another server took over) must not lock the record again.
				local lock = record and record.lock
				if lock == nil or lock.jobId ~= game.JobId then
					stolen = true
					return nil
				end
				return {
					data = data,
					lock = if keepLock then { jobId = game.JobId, time = os.time() } else nil,
				}
			end)
		end)
		if stolen then
			warn(`[Save] {key} is now owned by another server; not overwriting`)
			return false
		end
		if ok then
			return true
		end
		warn(`[Save] save {key} attempt {attempt} failed:`, err)
		task.wait(attempt)
	end
	return false
end

function DataStoreStorage:save(key: string, data: any): boolean
	return self:_write(key, data, true)
end

function DataStoreStorage:release(key: string, data: any): boolean
	return self:_write(key, data, false)
end

return DataStoreStorage
