-- Night raiding: a "Sneak & Steal" prompt on every register, defender warnings, defender-only
-- weapon hits on invaders, and lockouts for invaders who get caught. Rules live in Raid.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Format = require(ReplicatedStorage.Shared.Format)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Raid = require(ReplicatedStorage.Shared.Rules.Raid)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Sessions = require(script.Parent.Sessions)
local Weapons = require(script.Parent.Weapons)
local World = require(script.Parent.World)

local Raids = {}

local raid = Raid.new(Config.Raid)
local lastHitBy: { [Player]: { by: Player, at: number } } = {}
local runtimes = {}

local function plotContaining(position: Vector3)
	local half = Layout.PLOT_SIZE / 2
	for _, runtime in runtimes do
		local here = runtime.view.origin:PointToObjectSpace(position)
		if math.abs(here.X) <= half and math.abs(here.Z) <= half then
			return runtime
		end
	end
	return nil
end

local function rootOf(player: Player): BasePart?
	return player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

-- Invaders inside the defender's shop, as weapon targets that hurt instead of hitting creatures.
local function invaderTargets(defender: Player)
	local targets = {}
	if not World.isNight() then
		return targets
	end
	for _, other in Players:GetPlayers() do
		local root = rootOf(other)
		local runtime = root and plotContaining(root.Position)
		local ownerId = runtime and runtime.owner and runtime.owner.UserId
		if root and raid:canHurt(defender.UserId, other.UserId, ownerId, true) then
			table.insert(targets, {
				id = "player:" .. other.UserId,
				x = root.Position.X,
				z = root.Position.Z,
				hit = function(damage: number)
					local humanoid = other.Character and other.Character:FindFirstChildOfClass("Humanoid")
					if humanoid and humanoid.Health > 0 then
						lastHitBy[other] = { by = defender, at = os.clock() }
						humanoid:TakeDamage(damage * Config.Raid.pvpDamageScale)
					end
				end,
			})
		end
	end
	return targets
end

local function onCaught(invader: Player)
	local hit = lastHitBy[invader]
	lastHitBy[invader] = nil
	if hit == nil or os.clock() - hit.at > 5 or not World.isNight() then
		return
	end
	raid:lockOut(invader.UserId)
	local invaderSession, defenderSession = Sessions.get(invader), Sessions.get(hit.by)
	if invaderSession then
		invaderSession:notify("Raid.Caught")
	end
	if defenderSession then
		defenderSession:notify("Raid.YouCaught", { name = invader.DisplayName })
	end
end

local function addStealPrompt(runtime)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StealPrompt"
	prompt.ActionText = Strings.get("Raid.Steal")
	prompt.ObjectText = Strings.get("Raid.Register")
	prompt.HoldDuration = Config.Raid.stealHoldSeconds
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Enabled = false
	prompt.UIOffset = Vector2.new(0, 60) -- don't sit on top of the Serve prompt
	prompt.Parent = runtime.view.register

	prompt.PromptButtonHoldBegan:Connect(function(thief)
		local owner = runtime.owner
		local session = owner and Sessions.get(owner)
		if session and thief ~= owner and raid:canSteal(thief.UserId, owner.UserId, World.isNight(), os.clock()) then
			session:notify("Raid.Warning", { name = thief.DisplayName })
		end
	end)

	prompt.Triggered:Connect(function(thief)
		local owner = runtime.owner
		local victim, robber = owner and Sessions.get(owner), Sessions.get(thief)
		if victim == nil or robber == nil then
			return
		end
		local amount, reason =
			raid:steal(thief.UserId, owner.UserId, victim.wallet, robber.wallet, World.isNight(), os.clock())
		victim:syncCash()
		robber:syncCash()
		if amount > 0 then
			robber:notify("Raid.Stole", { cash = Format.cash(amount) })
			victim:notify("Raid.Robbed", { name = thief.DisplayName, cash = Format.cash(amount) })
		elseif reason and reason ~= "own" then
			robber:notify("Raid.Reason." .. reason)
		end
	end)
	return prompt
end

function Raids.init(allRuntimes)
	runtimes = allRuntimes
	local prompts = {}
	for _, runtime in runtimes do
		table.insert(prompts, addStealPrompt(runtime))
	end

	World.phaseChanged.Event:Connect(function(phase)
		if phase == "Night" then
			raid:beginNight()
		end
		for _, prompt in prompts do
			prompt.Enabled = phase == "Night"
		end
	end)

	Weapons.extraTargets = invaderTargets

	local function watch(player: Player)
		player.CharacterAdded:Connect(function(character)
			local humanoid = character:WaitForChild("Humanoid") :: Humanoid
			humanoid.Died:Connect(function()
				onCaught(player)
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastHitBy[player] = nil
	end)
end

return Raids
