-- Owns the server-wide clock. Publishes it to clients as attributes on ReplicatedStorage:
--   Phase ("Day" | "Night"), Night (number), PhaseEndsAt and PhaseLength (server time, seconds).
-- Clients derive the countdown, lighting and music from those, so nothing replicates every frame.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Clock = require(ReplicatedStorage.Shared.Rules.Clock)

local World = {}

local clock = Clock.new(Config.Clock)
World.phaseChanged = Instance.new("BindableEvent") -- fires (phase, night)

local function publish()
	ReplicatedStorage:SetAttribute("Phase", clock.phase)
	ReplicatedStorage:SetAttribute("Night", clock.night)
	ReplicatedStorage:SetAttribute("PhaseLength", clock:phaseLength())
	ReplicatedStorage:SetAttribute("PhaseEndsAt", workspace:GetServerTimeNow() + clock.timeLeft)
end

local function announce(events)
	if #events == 0 then
		return
	end
	publish()
	for _, event in events do
		World.phaseChanged:Fire(event.phase, event.night)
	end
end

function World.phase(): string
	return clock.phase
end

function World.night(): number
	return clock.night
end

function World.isNight(): boolean
	return clock.phase == "Night"
end

function World.tick(dt: number)
	announce(clock:tick(dt))
end

-- Admin tool: jump to the next phase now.
function World.skip()
	announce(clock:skip())
end

publish()

return World
