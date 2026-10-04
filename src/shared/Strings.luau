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

	["Raid.Steal"] = "Sneak & Steal",
	["Raid.Register"] = "Register",
	["Raid.Warning"] = "⚠️ {name} is sneaking into your shop!",
	["Raid.Stole"] = "🤫 You swiped {cash}!",
	["Raid.Robbed"] = "😠 {name} swiped {cash} from your register!",
	["Raid.Caught"] = "You got caught! No more sneaking tonight.",
	["Raid.YouCaught"] = "🛡️ You caught {name}!",
	["Raid.Reason.day"] = "Registers are locked during the day.",
	["Raid.Reason.locked"] = "You got caught tonight. Try again tomorrow night!",
	["Raid.Reason.cooldown"] = "They're watching closely now. Try another shop!",

	["Rebirth.Button"] = "🔁 Rebirth",
	["Rebirth.Title"] = "Rebirth #{n}",
	["Rebirth.Boost"] = "Income x{from} → x{to}",
	["Rebirth.Cost"] = "Costs {cash}",
	["Rebirth.Resets"] = "Resets your cash, shop, defenses and bought weapons. Keeps streaks, cosmetics and rewards.",
	["Rebirth.Confirm"] = "Rebirth!",
	["Rebirth.Done"] = "✨ Reborn! Income is now x{mult}",
	["Ui.Cancel"] = "Cancel",

	["Offline.Title"] = "Welcome back! 👋",
	["Offline.Body"] = "Your staff kept the shop open for {time} and earned {cash}!",
	["Offline.Collect"] = "Collect",

	["Badge.Earned"] = "🏅 Badge unlocked: {name}!",
	["Badge.FirstSale"] = "First Sale",
	["Badge.FirstStaff"] = "Help Wanted",
	["Badge.FirstDefense"] = "Sweet Defense",
	["Badge.FirstNight"] = "Survived the Night",
	["Badge.Streak5"] = "5 Night Streak",
	["Badge.Streak10"] = "10 Night Streak",
	["Badge.Streak25"] = "25 Night Streak",
	["Badge.Served1000"] = "1,000 Happy Customers",
	["Badge.FirstRebirth"] = "Reborn Baker",
	["Badge.Rebirth5"] = "Legendary Baker",
	["Leaderboard.Title"] = "🔥 Best Streaks 🔥",
	["Leaderboard.Row"] = "{rank}. {name}: {streak}",
	["Leaderboard.Unavailable"] = "Leaderboard loading…",

	["Daily.Title"] = "🎁 Daily Treats",
	["Daily.Day"] = "Day {n}",
	["Daily.Claim"] = "Claim!",
	["Daily.Button"] = "🎁 Daily",
	["Daily.ButtonReady"] = "🎁 Daily ❗",
	["Daily.Claimed"] = "🎁 Day {day} reward: {cash}!",
	["Ui.Close"] = "Close",

	["Codes.Button"] = "🎟️ Codes",
	["Codes.Title"] = "Enter a code",
	["Codes.Placeholder"] = "Type a code…",
	["Codes.Redeem"] = "Redeem",
	["Codes.Redeemed"] = "🎟️ Code redeemed: {cash}!",
	["Codes.Reason.invalid"] = "That code doesn't exist.",
	["Codes.Reason.expired"] = "That code has expired.",
	["Codes.Reason.used"] = "You already used that code.",
	["Codes.Reason.slow"] = "Slow down a little!",

	["Bonus.Friend"] = "👯 Playing with friends: +{pct}% income!",
	["Bonus.Group"] = "💗 Thanks for joining the group: +10% income!",
	["Bonus.JoinGroup"] = "💗 Join our group for +10% income!",
	["Bonus.Boost"] = "🍭 x{mult}",

	["Event.BloodMoon"] = "🌕 Blood Moon! More shadows tonight, but double rewards!",
	["Event.SpookySeason"] = "🎃 Spooky Season! Extra shadows and +50% rewards tonight!",

	["Tag.Owner"] = "👑 Owner",
	["Tag.VIP"] = "⭐ VIP",
	["Store.Button"] = "🛒 Store",
	["Store.Title"] = "🛒 Sweet Store",
	["Store.Owned"] = "Owned ✓",
	["Store.Buy"] = "Buy",
	["Store.Soon"] = "Coming soon!",
	["Store.Thanks"] = "💖 Thanks for buying {item}!",
	["Pass.DoubleCash"] = "2x Cash",
	["Pass.VIP"] = "VIP",
	["Pass.ExtraHelper"] = "Extra Helper",
	["Pass.SweetStyle"] = "Sweet Style",
	["PassInfo.DoubleCash"] = "Double cash from every sale, forever!",
	["PassInfo.VIP"] = "VIP tag, +10% income and VIP-only styles.",
	["PassInfo.ExtraHelper"] = "A bonus worker who serves customers for you.",
	["PassInfo.SweetStyle"] = "Unlocks every premium shop theme, weapon skin and trail.",

	["Product.InstantRepair"] = "🔧 Instant Repair",
	["Product.TurretOverdrive"] = "⚡ Turret Overdrive",
	["Product.NightShield"] = "🛡️ Night Shield",
	["ProductInfo.InstantRepair"] = "Fixes every defense to full health right now.",
	["ProductInfo.TurretOverdrive"] = "Defenses fire twice as fast for a whole night.",
	["ProductInfo.NightShield"] = "3 more customers can get scared away without failing the night.",
	["Boost.Active"] = "⚡ Boost active tonight!",

	["Style.Button"] = "🎨 Style",
	["Style.Title"] = "🎨 Sweet Style",
	["Style.theme"] = "Shop Themes",
	["Style.skin"] = "Weapon Skins",
	["Style.trail"] = "Trails",
	["Style.Equip"] = "Wear",
	["Style.Equipped"] = "Wearing ✓",
	["Style.NeedsVIP"] = "🔒 VIP",
	["Style.NeedsSweetStyle"] = "🔒 Sweet Style",
	["Style.Reason.perk"] = "That one comes with a pass in the Store!",
	["Style.Reason.cash"] = "Not enough cash!",
	["Style.Reason.owned"] = "You already have that!",
	["Style.Reason.notOwned"] = "You don't have that yet.",
	["Style.Reason.unknown"] = "That didn't work.",
	["Cosmetic.Classic"] = "Classic Pink",
	["Cosmetic.Mint"] = "Mint Dream",
	["Cosmetic.Lavender"] = "Lavender Fields",
	["Cosmetic.Midnight"] = "Midnight Treats",
	["Cosmetic.Rainbow"] = "Rainbow Sprinkles",
	["Cosmetic.PlainSkin"] = "Plain",
	["Cosmetic.Bubblegum"] = "Bubblegum",
	["Cosmetic.GoldSkin"] = "Golden",
	["Cosmetic.NoTrail"] = "No Trail",
	["Cosmetic.Sparkle"] = "Sparkle",
	["Cosmetic.Hearts"] = "Hearts",
	["Cosmetic.RainbowTrail"] = "Rainbow",

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
