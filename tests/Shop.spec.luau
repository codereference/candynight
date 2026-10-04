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
