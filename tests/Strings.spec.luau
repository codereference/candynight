local t = require("./lib/t")
local Strings = require("../src/shared/Strings")

t.test("fills placeholders from variables", function()
	t.expect(Strings.get("Plot.Owned", { name = "Sep" })).toBe("Sep's Sweet Shop")
end)

t.test("leaves unknown placeholders visible", function()
	t.expect(Strings.get("Plot.Owned", {})).toBe("{name}'s Sweet Shop")
end)

t.test("unknown keys come back as the key", function()
	t.expect(Strings.get("Nope.Missing")).toBe("Nope.Missing")
end)

t.test("added strings can be looked up", function()
	Strings.add({ ["Test.Hello"] = "Hi {who}" })
	t.expect(Strings.get("Test.Hello", { who = "you" })).toBe("Hi you")
end)

local fs = require("@lune/fs")

local function sourceFiles(dir: string, found: { string })
	for _, name in fs.readDir(dir) do
		local path = dir .. "/" .. name
		if fs.isDir(path) then
			sourceFiles(path, found)
		elseif name:match("%.luau$") then
			table.insert(found, path)
		end
	end
	return found
end

t.test("every string key used in the code has English text", function()
	local missing = {}
	for _, path in sourceFiles("src", {}) do
		for key in fs.readFile(path):gmatch('Strings%.get%(%s*"([^"]+)"%s*[,%)]') do
			if Strings.EN[key] == nil then
				table.insert(missing, key .. " (" .. path .. ")")
			end
		end
	end
	t.expect(missing).toEqual({})
end)

t.test("every buy button has a display name", function()
	local missing = {}
	for id in fs.readFile("src/shared/Config.luau"):gmatch('{ id = "(%w+)"') do
		if Strings.EN["Button." .. id] == nil then
			table.insert(missing, id)
		end
	end
	t.expect(missing).toEqual({})
end)
