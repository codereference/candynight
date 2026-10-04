-- Every tunable number lives here so balancing never means hunting through code.

return {
	startingCash = 0,

	Save = {
		dataStoreName = "SweetNights_v1",
		leaderboardName = "BestStreak_v1",
		autosaveSeconds = 60,
	},

	Plots = {
		count = 6,
		spacing = 80, -- studs between plot centres along a row
		rowOffset = 44, -- studs from the road's centre line to each row's plot centres
	},

	Shop = {
		baseSale = 5, -- cash per serve before any goods bonuses
		customerInterval = 5, -- seconds between customer arrivals before décor
		minCustomerInterval = 1.5,
		maxQueue = 5,
	},

	-- Buy buttons, in the order they appear. See UnlockTree for what each field does.
	-- Display names live in Strings under "Button.<id>".
	Buttons = {
		{ id = "CupcakeTray", cost = 15, goods = 3 },
		{ id = "Walls", cost = 30, requires = "CupcakeTray" },
		{ id = "CookieJar", cost = 50, goods = 5, requires = "CupcakeTray" },
		{ id = "Sign", cost = 90, decor = 0.75, requires = "Walls" },
		{ id = "Oven", cost = 150, goods = 10, requires = "CookieJar" },
		{ id = "Staff1", cost = 300, staff = 4, requires = "Oven" },
		{ id = "Roof", cost = 350, requires = "Sign" },
		{ id = "CandyMachine", cost = 600, goods = 20, requires = "Staff1" },
		{ id = "Flowers", cost = 800, decor = 0.75, requires = "Roof" },
		{ id = "Staff2", cost = 1200, staff = 3, requires = "CandyMachine" },
		{ id = "CakeStand", cost = 2000, goods = 40, requires = "Staff2" },
		{ id = "NeonSign", cost = 3000, decor = 1, requires = "Flowers" },
		{ id = "Staff3", cost = 5000, staff = 2, requires = "CakeStand" },

		-- Expansion packs: buying one builds its area and reveals the buttons that require it.
		{ id = "WeaponsPack", cost = 1500, pack = true, requires = "Staff2" },
		{ id = "CandyCaneSword", cost = 2500, weapon = "CandyCaneSword", requires = "WeaponsPack" },
		{ id = "GumballBlaster", cost = 9000, weapon = "GumballBlaster", requires = "CandyCaneSword" },
		{ id = "BackHousePack", cost = 7500, pack = true, requires = "Staff3" },
		{ id = "ChocolateFountain", cost = 10000, goods = 80, requires = "BackHousePack" },
		{ id = "IceCreamBar", cost = 18000, goods = 150, requires = "ChocolateFountain" },
		{ id = "Staff4", cost = 30000, staff = 1.5, requires = "IceCreamBar" },
	},

	Clock = {
		dayLength = 150, -- seconds
		nightLength = 90,
	},

	-- Asset ids like "rbxassetid://123". Empty = silent (pick tracks before launch, see #28).
	Audio = {
		dayMusic = "",
		nightMusic = "",
		musicVolume = 0.4,
	},

	-- Shadow creatures. Later nights scale count, health and speed (see Wave.plan).
	Creatures = {
		baseCount = 3,
		countPerNight = 1,
		maxCount = 20,
		baseHealth = 40,
		healthGrowth = 0.2,
		speed = 7,
		speedGrowth = 0.03,
		spawnWindow = 0.6, -- creatures arrive across the first 60% of the night
		catchRadius = 3,
		biteDamage = 10, -- damage per bite to a defense a creature is next to
		biteInterval = 1, -- seconds between bites
		biteRange = 4.5,
		restAfterScare = 1.5,
		bounty = 6, -- cash for defeating one, plus 1 per night number
	},

	-- Handheld weapons (see WeaponRules). Melee hits everything in range; ranged auto-aims.
	Weapons = {
		RollingPin = { damage = 20, cooldown = 0.5, range = 8 },
		CandyCaneSword = { damage = 40, cooldown = 0.45, range = 10 },
		GumballBlaster = { damage = 30, cooldown = 0.3, range = 40, ranged = true },
	},

	-- Grid defenses (see Defenses). requires = button id that unlocks it in the defense shop.
	Defenses = {
		maxPlaced = 24,
		sellShare = 0.5,
		repairShare = 0.4, -- share of the price to fully repair a destroyed defense
		catalog = {
			GumdropTurret = { order = 1, cost = 150, hp = 100, damage = 8, range = 18, fireRate = 1 },
			PeppermintCannon = {
				order = 2,
				cost = 900,
				hp = 260,
				damage = 24,
				range = 22,
				fireRate = 1.4,
				requires = "WeaponsPack",
			},
			CottonCandyZapper = {
				order = 3,
				cost = 3500,
				hp = 650,
				damage = 12,
				range = 16,
				fireRate = 0.35,
				requires = "GumballBlaster",
			},
		},
	},

	-- Night raiding (see Raid).
	Raid = {
		stealShare = 0.1, -- share of the victim's cash per steal
		stealCap = 1000, -- most one steal can take
		stealCooldown = 45, -- seconds before robbing the same shop again
		stealHoldSeconds = 1.5,
		pvpDamageScale = 1, -- defender weapon damage multiplier against invaders
	},

	-- What staff earn while you're away (see Offline).
	Offline = {
		capSeconds = 8 * 3600,
		minSeconds = 60,
		efficiency = 0.5,
	},

	Daily = {
		rewards = { 100, 250, 500, 1000, 2000, 3500, 6000 }, -- day 1..7; day 7 repeats after
	},

	-- Limited-time events (see Events). First match wins. Dates are unix seconds (UTC).
	Events = {
		{
			id = "BloodMoon",
			everyNthNight = 5,
			modifiers = { count = 1.5, health = 1.3, reward = 2 },
		},
		{
			id = "SpookySeason",
			startsAt = 1792022400, -- 2026-10-15
			endsAt = 1793577600, -- 2026-11-02
			modifiers = { count = 1.2, reward = 1.5 },
		},
	},

	-- Redeemable codes for YouTubers and socials. UPPERCASE keys; expires = unix seconds (optional).
	Codes = {
		SWEETNIGHTS = { cash = 500 },
		RELEASE = { cash = 1000 },
	},

	-- Roblox badge asset ids per badge key (see Badges). 0 = not created yet (see #28).
	Badges = {
		FirstSale = 0,
		FirstStaff = 0,
		FirstDefense = 0,
		FirstNight = 0,
		Streak5 = 0,
		Streak10 = 0,
		Streak25 = 0,
		Served1000 = 0,
		FirstRebirth = 0,
		Rebirth5 = 0,
	},

	Rebirth = {
		baseCost = 50000,
		costGrowth = 2.5,
		multiplierPerRebirth = 0.5, -- +50% income per rebirth
	},

	-- The game's Roblox group (members get Income.groupBonus). 0 = not created yet (see #28).
	Group = {
		id = 0,
	},

	-- Boosts on shop sales (see Income).
	Income = {
		vipBonus = 0.1,
		groupBonus = 0.1,
		friendBonus = 0.1, -- per friend in the server
		maxFriends = 3,
	},

	-- Surviving a night (see NightOutcome).
	Night = {
		lossShare = 0.5, -- share of the night's customers you may lose on a 0 streak
		lossShareStep = 0.04, -- less allowed per night of streak
		minLossShare = 0.1,
		failCashShare = 0.25,
		failBrokenDefenses = 2,
	},

	Customer = {
		walkSpeed = 10, -- studs per second
		queueSpacing = 4, -- studs between customers in line
	},
}
