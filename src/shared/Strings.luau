-- Every player-facing string, by key. The server sends keys (plus variables) and the client
-- looks them up, so all display text can be localized in one place.

local Strings = {}

local EN: { [string]: string } = {
	["Prompt.Serve"] = "Serve",
	["Prompt.Counter"] = "Counter",
	["Plot.Owned"] = "{name}'s Sweet Shop",
	["Plot.Free"] = "Free Shop",
	["Plot.ShopSign"] = "Sweet Shop",
	["Kick.Full"] = "This server is full. Please try another one!",

	["Notify.NeedCash"] = "You need {amount} more!",
	["Notify.Bought"] = "Unlocked {item}!",

	["Button.CupcakeTray"] = "Cupcake Tray",
	["Button.Walls"] = "Shop Walls",
	["Button.CookieJar"] = "Cookie Jar",
	["Button.Sign"] = "Shop Sign",
	["Button.Oven"] = "Oven",
	["Button.Staff1"] = "Hire Baker",
	["Button.Roof"] = "Roof",
	["Button.CandyMachine"] = "Candy Machine",
	["Button.Flowers"] = "Flower Boxes",
	["Button.Staff2"] = "Hire Cashier",
	["Button.CakeStand"] = "Cake Stand",
	["Button.NeonSign"] = "Neon Sign",
	["Button.Staff3"] = "Hire Head Chef",
}

Strings.EN = EN

-- Fills {placeholders} from vars. Unknown keys come back as the key so missing text is obvious.
function Strings.get(key: string, vars: { [string]: any }?): string
	local text = EN[key] or key
	if vars then
		text = text:gsub("{(%w+)}", function(name)
			local value = vars[name]
			return if value ~= nil then tostring(value) else "{" .. name .. "}"
		end)
	end
	return text
end

-- Adds or replaces strings (catalog modules register their item names this way).
function Strings.add(entries: { [string]: string })
	for key, value in entries do
		EN[key] = value
	end
end

return Strings
