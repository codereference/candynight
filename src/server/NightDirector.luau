-- Runs the night across all plots: spawns each shop's wave, moves shadow creatures toward customers,
-- scares customers off on contact, and settles every shop at dawn. Weapons and defenses damage
-- creatures through NightDirector.damage.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Horde = require(ReplicatedStorage.Shared.Rules.Horde)
local Wave = require(ReplicatedStorage.Shared.Rules.Wave)
local CreatureView = require(script.Parent.CreatureView)

local NightDirector = {}

local horde = Horde.new()
local creatures = {} -- [id] = { id, runtime, model, position, speed, targetId }
local waves = {} -- [runtime] = Wave
local plan = nil
local elapsed = 0
NightDirector.modifiers = {} -- set by events (Blood Moon); multipliers for Wave.plan
NightDirector.creatureDefeated = Instance.new("BindableEvent") -- fires (runtime, byPlayer?)

local SPAWNS = { { -28, 28 }, { 28, 28 }, { -28, 0 }, { 28, 0 }, { 0, 30 } }

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end

local function spawnCreature(runtime)
	local id = horde:spawn(plan.health)
	local spot = SPAWNS[math.random(#SPAWNS)]
	local position = runtime.view.at(spot[1], 0, spot[2]).Position
	creatures[id] = {
		id = id,
		runtime = runtime,
		model = CreatureView.make(id, runtime.view.model),
		position = position,
		speed = plan.speed * (0.9 + math.random() * 0.2),
	}
end

local function removeCreature(id: number, poof: boolean)
	local creature = creatures[id]
	if creature == nil then
		return
	end
	creatures[id] = nil
	horde:remove(id)
	if poof then
		CreatureView.poof(creature.model)
	else
		creature.model:Destroy()
	end
end

-- Nearest customer still in this creature's shop line.
local function nearestCustomer(creature): (number?, Vector3?)
	local runtime = creature.runtime
	local bestId, bestPosition, bestDistance = nil, nil, math.huge
	for _, customerId in runtime.shop:getQueue() do
		local position = runtime.customers:positionOf(customerId)
		if position then
			local distance = (flat(position) - flat(creature.position)).Magnitude
			if distance < bestDistance then
				bestId, bestPosition, bestDistance = customerId, position, distance
			end
		end
	end
	return bestId, bestPosition
end

local function moveCreature(creature, dt: number)
	if creature.restUntil and elapsed < creature.restUntil then
		return -- still celebrating its last "boo!"
	end
	local runtime = creature.runtime
	local customerId, target = nearestCustomer(creature)
	if target == nil then
		target = runtime.view.at(0, 0, -14).Position -- loiter near the counter
	end
	local offset = flat(target) - flat(creature.position)
	local distance = offset.Magnitude
	if customerId and distance <= Config.Creatures.catchRadius then
		runtime:loseCustomer(customerId)
		creature.restUntil = elapsed + Config.Creatures.restAfterScare
	elseif distance > 0.5 then
		creature.position += offset.Unit * math.min(distance, creature.speed * dt)
	end
	local bob = math.sin(elapsed * 3 + creature.id) * 0.35
	local here = Vector3.new(creature.position.X, CreatureView.HOVER + bob, creature.position.Z)
	local facing = if distance > 0.5 then here + offset else here - runtime.view.origin.LookVector
	creature.model:PivotTo(CFrame.lookAt(here, Vector3.new(facing.X, here.Y, facing.Z)))
end

function NightDirector.startNight(runtimes, night: number)
	plan = Wave.plan(Config.Creatures, night, NightDirector.modifiers)
	for _, runtime in runtimes do
		if runtime.owner then
			runtime:beginNight()
			waves[runtime] = Wave.new(plan, Config.Clock.nightLength, Config.Creatures.spawnWindow)
		end
	end
end

function NightDirector.endNight(runtimes)
	for id in creatures do
		removeCreature(id, true)
	end
	table.clear(waves)
	for _, runtime in runtimes do
		if runtime.outcome then
			runtime:endNight()
		end
	end
end

-- Deals damage to a creature. Returns true if it was defeated. byPlayer earns the bounty.
function NightDirector.damage(id: number, amount: number, byPlayer: Player?): boolean
	local creature = creatures[id]
	if creature == nil then
		return false
	end
	local defeated = horde:damage(id, amount)
	if defeated then
		removeCreature(id, true)
		NightDirector.creatureDefeated:Fire(creature.runtime, byPlayer)
	else
		CreatureView.setHealth(creature.model, horde:healthShare(id))
	end
	return defeated
end

-- Creatures within radius of a point (ignoring height): { { id, position } }.
function NightDirector.near(position: Vector3, radius: number)
	local found = {}
	for id, creature in creatures do
		if (flat(creature.position) - flat(position)).Magnitude <= radius then
			table.insert(found, { id = id, position = creature.position, runtime = creature.runtime })
		end
	end
	return found
end

-- Admin/testing: spawn extra creatures at a plot right now (needs night stats to exist).
function NightDirector.spawnAt(runtime, count: number)
	plan = plan or Wave.plan(Config.Creatures, 1, NightDirector.modifiers)
	for _ = 1, count do
		spawnCreature(runtime)
	end
end

function NightDirector.tick(dt: number)
	elapsed += dt
	for runtime, wave in waves do
		if runtime.owner == nil then
			waves[runtime] = nil
		else
			for _ = 1, wave:tick(dt) do
				spawnCreature(runtime)
			end
		end
	end
	for id, creature in creatures do
		if creature.runtime.owner == nil or creature.runtime.shop == nil then
			removeCreature(id, false) -- the shop's owner left
		else
			moveCreature(creature, dt)
		end
	end
end

return NightDirector
