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
		customerInterval = 6, -- seconds between customer arrivals
		maxQueue = 5,
	},

	Customer = {
		walkSpeed = 10, -- studs per second
		queueSpacing = 4, -- studs between customers in line
	},
}
