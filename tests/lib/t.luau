-- Tiny test library for Lune. Specs register tests with t.test; tests/run.luau runs them.

local t = { tests = {}, currentFile = "" }

function t.test(name: string, fn: () -> ())
	table.insert(t.tests, { name = t.currentFile .. " > " .. name, fn = fn })
end

local function deepEqual(a: any, b: any): boolean
	if type(a) ~= "table" or type(b) ~= "table" then
		return a == b
	end
	for key, value in a do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in b do
		if a[key] == nil then
			return false
		end
	end
	return true
end

local function show(value: any): string
	if type(value) ~= "table" then
		return tostring(value)
	end
	local parts = {}
	for key, item in value do
		table.insert(parts, tostring(key) .. "=" .. show(item))
	end
	table.sort(parts)
	return "{" .. table.concat(parts, ", ") .. "}"
end

function t.expect(actual: any)
	return {
		toBe = function(expected: any)
			if actual ~= expected then
				error(`expected {show(expected)}, got {show(actual)}`, 2)
			end
		end,
		toEqual = function(expected: any)
			if not deepEqual(actual, expected) then
				error(`expected {show(expected)}, got {show(actual)}`, 2)
			end
		end,
	}
end

return t
