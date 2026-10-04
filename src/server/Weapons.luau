-- Handheld weapons as Roblox Tools. Swings are validated on the server (cooldowns, range) through
-- WeaponRules; the client only presses the button. Handheld weapons are never destroyed.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)
local WeaponRules = require(ReplicatedStorage.Shared.Rules.WeaponRules)
local Effects = require(script.Parent.Effects)
local NightDirector = require(script.Parent.NightDirector)

local Weapons = {}

local lastSwing: { [Player]: { [string]: number } } = {}

-- Extra targets beyond creatures (raiding plugs invaders in here). Returns { { id, x, z, hit } }.
Weapons.extraTargets = nil :: ((Player) -> { any })?

local function handlePart(tool: Tool, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.CanCollide = false
	p.Massless = true
	p.Material = Enum.Material.SmoothPlastic
	for key, value in props do
		(p :: any)[key] = value
	end
	p.Parent = tool
	return p
end

local LOOKS: { [string]: (Tool) -> () } = {
	RollingPin = function(tool)
		handlePart(tool, { Name = "Handle", Size = Vector3.new(0.6, 0.6, 3.4), Color = Color3.fromRGB(222, 184, 135) })
	end,
	CandyCaneSword = function(tool)
		handlePart(tool, {
			Name = "Handle",
			Size = Vector3.new(0.4, 0.4, 4.2),
			Color = Color3.fromRGB(240, 60, 80),
			Material = Enum.Material.Neon,
		})
	end,
	GumballBlaster = function(tool)
		handlePart(tool, { Name = "Handle", Size = Vector3.new(0.8, 0.9, 2.4), Color = Color3.fromRGB(110, 210, 160) })
	end,
}

local function slash(tool: Tool)
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash" -- the default Animate script plays a swing for this
	anim.Parent = tool
	Debris:AddItem(anim, 1)
end

local function swing(player: Player, id: string, tool: Tool)
	local weapon = Config.Weapons[id]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if weapon == nil or root == nil then
		return
	end
	lastSwing[player] = lastSwing[player] or {}
	local ok, at = WeaponRules.trySwing(weapon, lastSwing[player][id], os.clock())
	if not ok then
		return
	end
	lastSwing[player][id] = at :: number

	local position = root.Position
	local targets = {}
	for _, creature in NightDirector.near(position, weapon.range) do
		table.insert(targets, { id = creature.id, x = creature.position.X, z = creature.position.Z })
	end
	if Weapons.extraTargets then
		for _, target in Weapons.extraTargets(player) do
			table.insert(targets, target)
		end
	end
	local byId = {}
	for _, target in targets do
		byId[target.id] = target
	end

	if not weapon.ranged then
		slash(tool)
	end
	for _, hitId in WeaponRules.hits(weapon, { x = position.X, z = position.Z }, targets) do
		local target = byId[hitId]
		if weapon.ranged then
			Effects.shoot(position + Vector3.new(0, 1.5, 0), Vector3.new(target.x, position.Y, target.z))
		end
		if target.hit then
			target.hit(weapon.damage) -- e.g. an invading player
		else
			NightDirector.damage(hitId, weapon.damage, player)
		end
	end
end

function Weapons.makeTool(player: Player, id: string): Tool
	local tool = Instance.new("Tool")
	tool.Name = Strings.get("Weapon." .. id)
	tool:SetAttribute("WeaponId", id)
	tool.CanBeDropped = false
	LOOKS[id](tool)
	tool.Activated:Connect(function()
		swing(player, id, tool)
	end)
	return tool
end

-- Makes sure the player's backpack holds exactly these weapons (call on spawn and after buying).
function Weapons.equip(player: Player, ids: { string })
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack == nil then
		return
	end
	local have = {}
	for _, container in { backpack, player.Character } do
		for _, tool in (container :: Instance):GetChildren() do
			local weaponId = tool:IsA("Tool") and tool:GetAttribute("WeaponId")
			if weaponId then
				have[weaponId] = true
			end
		end
	end
	for _, id in ids do
		if not have[id] and LOOKS[id] then
			Weapons.makeTool(player, id).Parent = backpack
		end
	end
end

function Weapons.forget(player: Player)
	lastSwing[player] = nil
end

return Weapons
