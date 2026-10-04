-- Makes placed defenses fight: each standing defense fires at the nearest creature in range.
-- Runs at a fixed 10 Hz rather than every frame to stay cheap with many turrets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Defenses = require(ReplicatedStorage.Shared.Rules.Defenses)
local Turrets = require(ReplicatedStorage.Shared.Rules.Turrets)
local DefenseView = require(script.Parent.DefenseView)
local Effects = require(script.Parent.Effects)
local NightDirector = require(script.Parent.NightDirector)

local TurretDirector = {}

local CATALOG = Config.Defenses.catalog
local STEP = 0.1
local turrets = Turrets.new()
local pending = 0

-- [runtime] = fire-rate multiplier for tonight (Turret Overdrive dev product). Cleared at dawn.
TurretDirector.overdrive = {}

local SHOT_COLOURS = {
	GumdropTurret = Color3.fromRGB(255, 120, 170),
	PeppermintCannon = Color3.fromRGB(240, 60, 80),
	CottonCandyZapper = Color3.fromRGB(150, 220, 255),
}

local function fire(runtime, step: number)
	local profile = runtime.session.profile
	for id, model in runtime.defenseModels do
		local entry = Defenses.find(profile, id)
		if entry == nil or entry.hp <= 0 then
			turrets:forget(model)
			continue
		end
		local def = CATALOG[entry.kind]
		local position = model:GetPivot().Position
		local candidates = {}
		local positions = {}
		for _, creature in NightDirector.near(position, def.range) do
			table.insert(candidates, { id = creature.id, x = creature.position.X, z = creature.position.Z })
			positions[creature.id] = creature.position
		end
		local target = Turrets.pickTarget({ x = position.X, z = position.Z }, def.range, candidates)
		if turrets:ready(model, step, def.fireRate, target ~= nil, TurretDirector.overdrive[runtime]) then
			local at = positions[target]
			DefenseView.aim(model, at)
			Effects.shoot(position + Vector3.new(0, 2.5, 0), at + Vector3.new(0, 2, 0), SHOT_COLOURS[entry.kind], 0.7)
			NightDirector.damage(target, def.damage, runtime.owner)
		end
	end
end

function TurretDirector.tick(dt: number, runtimes)
	pending += dt
	if pending < STEP then
		return
	end
	local step = pending
	pending = 0
	for _, runtime in runtimes do
		if runtime.owner and runtime.session then
			fire(runtime, step)
		end
	end
end

function TurretDirector.endNight()
	table.clear(TurretDirector.overdrive)
end

return TurretDirector
