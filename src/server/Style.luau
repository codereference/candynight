-- Cosmetics in the world: shop themes recolour the plot, weapon skins recolour tools, trails follow
-- the player. Purely visual. Owned/equipped state is published as player attributes for the UI:
-- Cos_<id> (usable) and Wear_<slot> (worn id).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Cosmetics = require(ReplicatedStorage.Shared.Rules.Cosmetics)
local Net = require(ReplicatedStorage.Shared.Net)
local Sessions = require(script.Parent.Sessions)

local Style = {}

local CATALOG = Config.Cosmetics
local SLOTS = { "theme", "skin", "trail" }

local function worn(session, slot: string)
	local id = Cosmetics.worn(CATALOG, session.profile.cosmetics, session.perks or {}, slot)
	return id, id and CATALOG[id]
end

local function applySkin(session)
	local _, skin = worn(session, "skin")
	local player = session.player
	for _, container in { player:FindFirstChildOfClass("Backpack"), player.Character } do
		for _, tool in (container :: Instance):GetChildren() do
			local handle = tool:IsA("Tool") and tool:FindFirstChild("Handle") :: BasePart?
			if handle then
				if handle:GetAttribute("BaseColour") == nil then
					handle:SetAttribute("BaseColour", handle.Color)
					handle:SetAttribute("BaseMaterial", handle.Material.Name)
				end
				local colour = skin and skin.color
				handle.Color = colour or handle:GetAttribute("BaseColour")
				handle.Material = if skin and skin.neon
					then Enum.Material.Neon
					else (Enum.Material :: any)[handle:GetAttribute("BaseMaterial")]
			end
		end
	end
end

local function applyTrail(session)
	local root = session.player.Character and session.player.Character:FindFirstChild("HumanoidRootPart")
	if root == nil then
		return
	end
	local old = root:FindFirstChild("StyleTrail")
	if old then
		old:Destroy()
	end
	for _, name in { "StyleTrailA", "StyleTrailB" } do
		local attachment = root:FindFirstChild(name)
		if attachment then
			attachment:Destroy()
		end
	end
	local _, trail = worn(session, "trail")
	if trail == nil or trail.colors == nil then
		return
	end
	local a = Instance.new("Attachment")
	a.Name = "StyleTrailA"
	a.Position = Vector3.new(0, 0.8, 0)
	a.Parent = root
	local b = Instance.new("Attachment")
	b.Name = "StyleTrailB"
	b.Position = Vector3.new(0, -0.8, 0)
	b.Parent = root
	local effect = Instance.new("Trail")
	effect.Name = "StyleTrail"
	effect.Attachment0, effect.Attachment1 = a, b
	effect.Lifetime = 0.5
	effect.LightEmission = 0.4
	local keypoints = {}
	for i, colour in trail.colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((i - 1) / math.max(1, #trail.colors - 1), colour))
	end
	if #keypoints == 1 then
		table.insert(keypoints, ColorSequenceKeypoint.new(1, trail.colors[1]))
	end
	effect.Color = ColorSequence.new(keypoints)
	effect.Transparency = NumberSequence.new(0.2, 1)
	effect.Parent = root
end

-- Re-applies everything and republishes attributes. runtimeOf finds the player's plot.
function Style.apply(session, runtime)
	local player = session.player
	for id in CATALOG do
		player:SetAttribute(
			"Cos_" .. id,
			Cosmetics.isOwned(CATALOG, session.profile.cosmetics, session.perks or {}, id)
		)
	end
	for _, slot in SLOTS do
		player:SetAttribute("Wear_" .. slot, (worn(session, slot)))
	end
	if runtime then
		local _, theme = worn(session, "theme")
		runtime.view.setTheme(theme)
	end
	applySkin(session)
	applyTrail(session)
end

function Style.start(runtimeOf: (Player) -> any, weaponsGiven: BindableEvent, perksChanged: BindableEvent)
	local function refresh(player: Player)
		local session = Sessions.get(player)
		if session then
			Style.apply(session, runtimeOf(player))
		end
	end

	Sessions.started.Event:Connect(function(session)
		session.player.CharacterAdded:Connect(function()
			task.defer(refresh, session.player)
		end)
		task.defer(refresh, session.player)
	end)
	weaponsGiven.Event:Connect(refresh)
	perksChanged.Event:Connect(function(session)
		refresh(session.player)
	end)

	Net.func("BuyCosmetic").OnServerInvoke = function(player, id)
		local session = Sessions.get(player)
		if session == nil or type(id) ~= "string" then
			return false, "unknown"
		end
		local ok, reason = Cosmetics.buy(CATALOG, session.profile.cosmetics, session.perks or {}, session.wallet, id)
		session:syncCash()
		if ok then
			Cosmetics.equip(CATALOG, session.profile.cosmetics, session.perks or {}, id)
			refresh(player)
		end
		return ok, reason
	end

	Net.func("EquipCosmetic").OnServerInvoke = function(player, id)
		local session = Sessions.get(player)
		if session == nil or type(id) ~= "string" then
			return false, "unknown"
		end
		local ok, reason = Cosmetics.equip(CATALOG, session.profile.cosmetics, session.perks or {}, id)
		if ok then
			refresh(player)
		end
		return ok, reason
	end
end

return Style
