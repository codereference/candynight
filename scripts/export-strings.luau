-- Writes every English string to localization/Strings.csv, the LocalizationTable Rojo syncs into
-- LocalizationService. Translators (or Roblox auto-translate) fill in the other language columns.
-- Usage (from the repo root): lune run scripts/export-strings [output path]

local fs = require("@lune/fs")
local process = require("@lune/process")
local Strings = require("../src/shared/Strings")

local LANGUAGES = { "es", "pt", "fr", "de", "id", "ko", "ja", "zh-hans", "tr", "ru" }

local function cell(text: string): string
	return '"' .. text:gsub('"', '""') .. '"'
end

local keys = {}
for key in Strings.EN do
	table.insert(keys, key)
end
table.sort(keys)

local header = { "Key", "Source", "Context", "Example" }
for _, language in LANGUAGES do
	table.insert(header, language)
end
local lines = { table.concat(header, ",") }
for _, key in keys do
	local row = { cell(key), cell(Strings.EN[key]), '""', '""' }
	for _ in LANGUAGES do
		table.insert(row, '""')
	end
	table.insert(lines, table.concat(row, ","))
end

local output = process.args[1] or "localization/Strings.csv"
fs.writeFile(output, table.concat(lines, "\n") .. "\n")
print(`wrote {#keys} strings to {output}`)
