local t = require("./lib/t")
local Shop = require("../src/shared/Rules/Shop")

local CONFIG = { baseSale = 5, customerInterval = 6, minCustomerInterval = 2, maxQueue = 3 }

local function arrivals(events)
	local ids = {}
	for _, event in events do
		if event.kind == "CustomerArrived" then
			table.insert(ids, event.customerId)
		end
	end
	return ids
end

local function staffServes(events)
	local served = {}
	for _, event in events do
		if event.kind == "CustomerServed" then
			table.insert(served, event.staffId)
		end
	end
	return served
end

local function withStaff(shop, staff)
	shop:setEffects({ goods = 0, decor = 0, staff = staff })
	return shop
end

t.test("first customer arrives on the first tick", function()
	local shop = Shop.new(CONFIG)
	t.expect(arrivals(shop:tick(0.1))).toEqual({ 1 })
	t.expect(shop:getQueue()).toEqual({ 1 })
end)

t.test("next customer arrives once the interval has passed", function()
	local shop = Shop.new(CONFIG)
	shop:tick(0.1)
	t.expect(arrivals(shop:tick(5.8))).toEqual({})
	t.expect(arrivals(shop:tick(0.2))).toEqual({ 2 })
end)

t.test("a long tick brings every customer that was due", function()
	local shop = Shop.new(CONFIG)
	t.expect(arrivals(shop:tick(12))).toEqual({ 1, 2, 3 })
end)

t.test("the queue never grows past its cap", function()
	local shop = Shop.new(CONFIG)
	shop:tick(1000)
	t.expect(#shop:getQueue()).toBe(3)
	t.expect(arrivals(shop:tick(1000))).toEqual({})
end)

t.test("when a full line frees up, the next customer comes right away", function()
	local shop = Shop.new(CONFIG)
	shop:tick(1000)
	shop:serve()
	t.expect(arrivals(shop:tick(0.1))).toEqual({ 4 })
end)

t.test("serving takes the front customer and pays the base sale", function()
	local shop = Shop.new(CONFIG)
	shop:tick(12)
	t.expect(shop:serve()).toEqual({ kind = "CustomerServed", customerId = 1, cash = 5 })
	t.expect(shop:getQueue()).toEqual({ 2, 3 })
end)

t.test("serving with nobody waiting does nothing", function()
	local shop = Shop.new(CONFIG)
	t.expect(shop:serve()).toBe(nil)
end)

t.test("changing the returned queue doesn't change the shop", function()
	local shop = Shop.new(CONFIG)
	shop:tick(0.1)
	table.clear(shop:getQueue())
	t.expect(shop:getQueue()).toEqual({ 1 })
end)

t.test("goods raise the cash paid per sale", function()
	local shop = Shop.new(CONFIG)
	shop:setEffects({ goods = 8, decor = 0 })
	shop:tick(0.1)
	t.expect(shop:serve().cash).toBe(13)
end)

t.test("decor brings customers more often", function()
	local shop = Shop.new(CONFIG)
	shop:setEffects({ goods = 0, decor = 2 })
	shop:tick(0.1)
	t.expect(arrivals(shop:tick(4))).toEqual({ 2 })
end)

t.test("decor can't push arrivals faster than the minimum interval", function()
	local shop = Shop.new(CONFIG)
	shop:setEffects({ goods = 0, decor = 100 })
	t.expect(shop:arrivalInterval()).toBe(2)
end)

t.test("a worker serves on their own once their interval passes", function()
	local shop = withStaff(Shop.new(CONFIG), { { id = "Baker", interval = 4 } })
	shop:tick(0.1)
	t.expect(staffServes(shop:tick(3.8))).toEqual({})
	local served = shop:tick(0.2)
	t.expect(staffServes(served)).toEqual({ "Baker" })
	t.expect(served[1].cash).toBe(5)
end)

t.test("an idle worker serves the moment a customer arrives", function()
	local shop = withStaff(Shop.new({ baseSale = 5, customerInterval = 10, minCustomerInterval = 1, maxQueue = 3 }), {
		{ id = "Baker", interval = 2 },
	})
	shop:tick(0.1) -- customer 1 arrives
	shop:tick(2) -- baker serves them and goes idle
	t.expect(staffServes(shop:tick(5))).toEqual({})
	t.expect(staffServes(shop:tick(5))).toEqual({ "Baker" }) -- customer 2 arrives at t=10
end)

t.test("several workers each serve on their own timers", function()
	local shop = Shop.new({ baseSale = 5, customerInterval = 0.1, minCustomerInterval = 0.1, maxQueue = 10 })
	shop:tick(5) -- a full line before anyone is hired
	withStaff(shop, { { id = "A", interval = 2 }, { id = "B", interval = 3 } })
	local served = {}
	for _ = 1, 60 do
		for _, id in staffServes(shop:tick(0.1)) do
			served[id] = (served[id] or 0) + 1
		end
	end
	t.expect(served).toEqual({ A = 3, B = 2 }) -- A at 2, 4, 6 and B at 3, 6
end)

t.test("hiring another worker doesn't reset the others", function()
	local shop = withStaff(Shop.new(CONFIG), { { id = "A", interval = 4 } })
	shop:tick(1)
	withStaff(shop, { { id = "A", interval = 4 }, { id = "B", interval = 4 } })
	shop:tick(1)
	t.expect(staffServes(shop:tick(2.1))).toEqual({ "A" })
end)

t.test("a scared-off customer leaves the line without paying", function()
	local shop = Shop.new(CONFIG)
	shop:tick(12)
	t.expect(shop:loseCustomer(2)).toBe(true)
	t.expect(shop:getQueue()).toEqual({ 1, 3 })
	t.expect(shop:loseCustomer(2)).toBe(false)
end)
