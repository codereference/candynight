-- Pure server-wide day/night cycle. The game starts on day 1; each night is numbered from 1.
-- tick(dt) and skip() return { kind = "PhaseChanged", phase = "Day" | "Night", night } events.

local Clock = {}
Clock.__index = Clock

-- config: { dayLength: number, nightLength: number } in seconds
function Clock.new(config)
	return setmetatable({ config = config, phase = "Day", timeLeft = config.dayLength, night = 0 }, Clock)
end

function Clock:phaseLength(): number
	return if self.phase == "Day" then self.config.dayLength else self.config.nightLength
end

-- 0 at the start of the current phase, 1 at its end.
function Clock:progress(): number
	return 1 - self.timeLeft / self:phaseLength()
end

function Clock:_advance()
	if self.phase == "Day" then
		self.phase = "Night"
		self.night += 1
	else
		self.phase = "Day"
	end
	self.timeLeft += self:phaseLength()
	return { kind = "PhaseChanged", phase = self.phase, night = self.night }
end

function Clock:tick(dt: number)
	local events = {}
	self.timeLeft -= dt
	while self.timeLeft <= 0 do
		table.insert(events, self:_advance())
	end
	return events
end

-- Jumps straight to the next phase (admin tool).
function Clock:skip()
	self.timeLeft = 0
	return { self:_advance() }
end

return Clock
