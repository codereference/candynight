-- In-memory storage with the same interface as the DataStore one. Used by tests and when
-- Studio has no DataStore access. Copies data in and out, like real serialization would.

local MemoryStorage = {}
MemoryStorage.__index = MemoryStorage

local function copy(value: any): any
	if type(value) ~= "table" then
		return value
	end
	local out = {}
	for key, item in value do
		out[key] = copy(item)
	end
	return out
end

function MemoryStorage.new()
	return setmetatable({
		data = {},
		failLoads = false, -- tests flip these to simulate an outage
		failSaves = false,
		writes = 0,
	}, MemoryStorage)
end

function MemoryStorage:load(key: string): (boolean, any)
	if self.failLoads then
		return false, nil
	end
	return true, copy(self.data[key])
end

function MemoryStorage:save(key: string, data: any): boolean
	if self.failSaves then
		return false
	end
	self.writes += 1
	self.data[key] = copy(data)
	return true
end

function MemoryStorage:release(key: string, data: any): boolean
	return self:save(key, data)
end

return MemoryStorage
