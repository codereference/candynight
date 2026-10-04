-- Every tunable number lives here so balancing never means hunting through code.

return {
	startingCash = 0,

	Save = {
		dataStoreName = "SweetNights_v1",
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
		restAfterScare = 1.5,
		bounty = 6, -- cash for defeating one, plus 1 per night number
	},

	-- Handheld weapons (see WeaponRules). Melee hits everything in range; ranged auto-aims.
	Weapons = {
		RollingPin = { damage = 20, cooldown = 0.5, range = 8 },
		CandyCaneSword = { damage = 40, cooldown = 0.45, range = 10 },
		GumballBlaster = { damage = 30, cooldown = 0.3, range = 40, ranged = true },
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
