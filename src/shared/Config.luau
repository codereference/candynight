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
	},

	Customer = {
		walkSpeed = 10, -- studs per second
		queueSpacing = 4, -- studs between customers in line
	},
}
