-- Pure admin rules: who may use admin commands, and validating each command's arguments.
-- Every request is checked on the server with these before anything runs.

local Admin = {}

-- config: { adminIds = { userId } } (owners are added by the caller)
function Admin.isAdmin(adminIds: { number }, userId: number): boolean
	return table.find(adminIds, userId) ~= nil
end

local function wholeNumber(value: any, min: number, max: number): number?
	if type(value) ~= "number" or value ~= value or value % 1 ~= 0 or value < min or value > max then
		return nil
	end
	return value
end

local function target(value: any): string?
	if value == nil or value == "" then
		return "me"
	end
	if type(value) ~= "string" or #value > 20 then
		return nil
	end
	return value
end

-- Each validator turns raw client args into clean args, or nil when they're bad.
local COMMANDS: { [string]: (args: { any }) -> { any }? } = {
	giveCash = function(args)
		local who, amount = target(args[1]), wholeNumber(args[2], 1, 1e12)
		return if who and amount then { who, amount } else nil
	end,
	skipPhase = function()
		return {}
	end,
	spawnCreatures = function(args)
		local count = wholeNumber(args[1], 1, 25)
		return if count then { count } else nil
	end,
	setStreak = function(args)
		local who, streak = target(args[1]), wholeNumber(args[2], 0, 10000)
		return if who and streak then { who, streak } else nil
	end,
	forceEvent = function(args)
		return if type(args[1]) == "string" and #args[1] <= 30 then { args[1] } else nil
	end,
	repairAll = function()
		return {}
	end,
	resetData = function(args)
		local who = target(args[1])
		return if who then { who } else nil
	end,
}
Admin.COMMANDS = COMMANDS

-- Returns clean args, or nil plus "unknown" | "args".
function Admin.validate(name: any, args: any): ({ any }?, string?)
	local validator = type(name) == "string" and COMMANDS[name]
	if not validator then
		return nil, "unknown"
	end
	local clean = validator(if type(args) == "table" then args else {})
	if clean == nil then
		return nil, "args"
	end
	return clean, nil
end

return Admin
