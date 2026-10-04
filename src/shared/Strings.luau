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

	["Clock.Day"] = "☀️ Day {n}  {time}",
	["Clock.Night"] = "🌙 Night {n}  {time}",

	["Night.Streak"] = "🔥 Streak {n}",
	["Night.Meter"] = "😱 Scared away: {lost} / {allowed}",
	["Night.Survived"] = "You survived the night! 🌅",
	["Night.SurvivedDetail"] = "Your streak is now {streak}. Keep those customers safe!",
	["Night.Failed"] = "Oh no! 😱",
	["Night.FailedDetail"] = "Too many customers got scared away. You lost {cash} and {broken} defenses broke.",
	["Ui.Ok"] = "OK",

	["Weapon.RollingPin"] = "Rolling Pin",
	["Weapon.CandyCaneSword"] = "Candy Cane Sword",
	["Weapon.GumballBlaster"] = "Gumball Blaster",

	["Defense.GumdropTurret"] = "Gumdrop Turret",
	["Defense.PeppermintCannon"] = "Peppermint Cannon",
	["Defense.CottonCandyZapper"] = "Cotton Candy Zapper",
	["Defense.Shop"] = "🛡️ Defenses",
	["Defense.Locked"] = "🔒 Needs {item}",
	["Defense.Move"] = "Move",
	["Defense.Sell"] = "Sell {cash}",
	["Defense.Repair"] = "Repair {cash}",
	["Defense.Rotate"] = "↻ Rotate",
	["Defense.Place"] = "✓ Place",
	["Defense.Cancel"] = "✕ Cancel",
	["Defense.Placed"] = "Placed {item}!",
	["Defense.Sold"] = "Sold for {cash}",
	["Defense.Repaired"] = "Good as new!",
	["Reason.bounds"] = "That's off your plot.",
	["Reason.blocked"] = "Can't build there.",
	["Reason.occupied"] = "Something's already there.",
	["Reason.full"] = "Your plot is full of defenses!",
	["Reason.locked"] = "That's still locked.",
	["Reason.cash"] = "Not enough cash!",
	["Reason.unknown"] = "That didn't work.",
	["Reason.missing"] = "That defense is gone.",
	["Reason.rotation"] = "That didn't work.",
	["Reason.full_hp"] = "It's already at full health.",

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
	["Button.WeaponsPack"] = "📦 Weapons Pack",
	["Button.CandyCaneSword"] = "Candy Cane Sword",
	["Button.GumballBlaster"] = "Gumball Blaster",
	["Button.BackHousePack"] = "📦 Back Shop House",
	["Button.ChocolateFountain"] = "Chocolate Fountain",
	["Button.IceCreamBar"] = "Ice Cream Bar",
	["Button.Staff4"] = "Hire Pastry Chef",
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
