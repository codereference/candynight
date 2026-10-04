-- Pure rules for one shop: customer arrivals, the queue, and serving.
-- Time only moves through tick(dt), so tests can simulate hours instantly.
-- Results come back as events ({ kind = "CustomerArrived" | "CustomerServed", ... }) for adapters to show.

local Shop = {}
Shop.__index = Shop

-- config: { baseSale, customerInterval, minCustomerInterval, maxQueue }
function Shop.new(config)
	return setmetatable({
		config = config,
		effects = { goods = 0, decor = 0 },
		queue = {},
		nextCustomerId = 1,
		untilArrival = 0, -- the first customer shows up on the first tick
	}, Shop)
end

-- effects: { goods = extra cash per sale, decor = seconds off the arrival interval } (see UnlockTree:effects)
function Shop:setEffects(effects)
	self.effects = effects
end

function Shop:saleValue(): number
	return self.config.baseSale + self.effects.goods
end

-- Seconds between customer arrivals. Décor speeds it up, down to a floor.
function Shop:arrivalInterval(): number
	return math.max(self.config.minCustomerInterval, self.config.customerInterval - self.effects.decor)
end

-- Customer ids in line order, front first. A copy, so callers can't change the queue.
function Shop:getQueue(): { number }
	return table.clone(self.queue)
end

function Shop:tick(dt: number)
	local events = {}
	self.untilArrival -= dt
	while self.untilArrival <= 0 do
		if #self.queue >= self.config.maxQueue then
			-- Line is full: the next customer walks up as soon as there's room.
			self.untilArrival = 0
			break
		end
		local id = self.nextCustomerId
		self.nextCustomerId += 1
		table.insert(self.queue, id)
		table.insert(events, { kind = "CustomerArrived", customerId = id })
		self.untilArrival += self:arrivalInterval()
	end
	return events
end

-- Serves the front customer. Returns the sale event, or nil when nobody is waiting.
function Shop:serve()
	local id = table.remove(self.queue, 1)
	if id == nil then
		return nil
	end
	return { kind = "CustomerServed", customerId = id, cash = self:saleValue() }
end

return Shop
