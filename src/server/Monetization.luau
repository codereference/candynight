-- Gamepasses: checks ownership on join, applies perks (income boosts, extra helper), shows
-- overhead Owner/VIP tags, and grants a pass the moment it's bought in-game.
-- Owners (Config.Monetization.ownerIds) get every pass free.

local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Entitlements = require(ReplicatedStorage.Shared.Rules.Entitlements)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Sessions = require(script.Parent.Sessions)

local Monetization = {}
Monetization.perksChanged = Instance.new("BindableEvent") -- fires (session) when perks change

local CONFIG = Config.Monetization

local TAG_COLOURS = {
	Owner = Color3.fromRGB(255, 200, 60),
	VIP = Color3.fromRGB(190, 140, 255),
}

local function showTag(player: Player)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if head == nil then
		return
	end
	local existing = head:FindFirstChild("RankTag")
	if existing then
		existing:Destroy()
	end
	local tag = player:GetAttribute("Tag")
	if tag == nil then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "RankTag"
	gui.Size = UDim2.fromOffset(120, 30)
	gui.StudsOffset = Vector3.new(0, 2.6, 0)
	gui.MaxDistance = 80
	gui.Parent = head
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.TextColor3 = TAG_COLOURS[tag]
	label.TextStrokeTransparency = 0.2
	label.Text = Strings.get("Tag." .. tag)
	label.Parent = gui
end

function Monetization.refresh(session)
	local player = session.player
	local perks = Entitlements.perks(CONFIG, session.passes, player.UserId)
	session.perks = perks
	session.factors.doubleCash = perks.doubleCash
	session.factors.vip = perks.vip
	session:refreshMultiplier()
	for passKey in CONFIG.passes do
		player:SetAttribute("Pass_" .. passKey, Entitlements.hasPass(CONFIG, session.passes, player.UserId, passKey))
	end
	player:SetAttribute("Tag", Entitlements.tag(CONFIG, session.passes, player.UserId))
	showTag(player)
	Monetization.perksChanged:Fire(session)
end

local function checkOwnership(session)
	session.passes = session.passes or {}
	for passKey, pass in CONFIG.passes do
		if pass.id ~= 0 then
			local ok, owns =
				pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, session.player.UserId, pass.id)
			if ok and owns then
				session.passes[passKey] = true
			end
		end
	end
	Monetization.refresh(session)
end

function Monetization.start()
	Sessions.started.Event:Connect(function(session)
		session.passes = {}
		session.perks = {}
		task.spawn(checkOwnership, session)
		session.player.CharacterAdded:Connect(function()
			task.defer(showTag, session.player)
		end)
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local session = Sessions.get(player)
		if not purchased or session == nil then
			return
		end
		for passKey, pass in CONFIG.passes do
			if pass.id == passId then
				session.passes[passKey] = true
				Monetization.refresh(session)
				session:notify("Store.Thanks", { item = Strings.get("Pass." .. passKey) })
			end
		end
	end)
end

return Monetization
