-- Runs every tests/*.spec.luau headless. Usage (from the repo root): lune run tests/run

local fs = require("@lune/fs")
local process = require("@lune/process")
local t = require("./lib/t")

local files = {}
for _, name in fs.readDir("tests") do
	if name:match("%.spec%.luau$") then
		table.insert(files, name)
	end
end
table.sort(files)

for _, name in files do
	t.currentFile = (name:gsub("%.spec%.luau$", ""))
	require("./" .. name:gsub("%.luau$", ""))
end

local failed = 0
for _, case in t.tests do
	local ok, err = pcall(case.fn)
	if ok then
		print("  ok   " .. case.name)
	else
		failed += 1
		print("  FAIL " .. case.name .. "\n       " .. tostring(err))
	end
end

print(`\n{#t.tests - failed} passed, {failed} failed`)
process.exit(if failed > 0 then 1 else 0)
