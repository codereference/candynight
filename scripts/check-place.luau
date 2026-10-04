-- Sanity checks on the built place file (run by check.sh after rojo build).
-- Usage: lune run scripts/check-place <place.rbxl>

local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

local game = roblox.deserializePlace(fs.readFile(process.args[1]))
local base = game:GetService("Workspace"):FindFirstChild("Baseplate")
local top = base.CFrame.Position.Y + base.Size.Y / 2
-- Plots, the road and everything else are built at ground level y = 0.
if math.abs(top) > 0.01 then
	print(`Baseplate top is at y = {top}, expected 0 (the game would be buried)`)
	process.exit(1)
end
