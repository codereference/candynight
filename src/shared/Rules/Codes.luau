-- Pure code-redemption rules. Codes are case-insensitive and usable once per player.
-- catalog: { [CODE] = { cash: number, expires: number? (unix seconds) } }
-- redeemed: the profile's { [CODE] = true }

local Codes = {}

function Codes.normalize(text: string): string
	return (text:gsub("%s", "")):upper()
end

-- Returns the reward entry, or nil plus "invalid" | "expired" | "used". Marks it used on success.
function Codes.redeem(catalog, redeemed, text: string, now: number)
	local code = Codes.normalize(text)
	local entry = catalog[code]
	if entry == nil then
		return nil, "invalid"
	elseif entry.expires and now >= entry.expires then
		return nil, "expired"
	elseif redeemed[code] then
		return nil, "used"
	end
	redeemed[code] = true
	return entry, nil
end

return Codes
