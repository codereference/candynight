-- Display formatting shared by server and client. Pure, so Lune can test it.

local Format = {}

local SUFFIXES = { "K", "M", "B", "T", "Qa", "Qi" }

-- 950 -> "$950", 1250 -> "$1.2K", 3400000 -> "$3.4M".
-- Rounds down, so the HUD never shows more cash than the player has.
function Format.cash(amount: number): string
	local whole = math.floor(amount)
	if whole < 1000 then
		return "$" .. whole
	end
	local value, tier = whole, 0
	while value >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	local text = string.format("%.1f", math.floor(value * 10) / 10)
	text = (text:gsub("%.0$", ""))
	return "$" .. text .. SUFFIXES[tier]
end

return Format
