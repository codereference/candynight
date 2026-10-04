-- Developer products (repeat purchases): Instant Repair, Turret Overdrive, Night Shield.
-- Exactly-once: the receipt is recorded on the profile and SAVED before Roblox is told the
-- purchase was granted. Anything that can't be recorded is left for Roblox to retry.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Receipts = require(ReplicatedStorage.Shared.Rules.Receipts)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Sessions = require(script.Parent.Sessions)

local Products = {}

local MAX_RECEIPTS = 300

local GRANTS: { [string]: (runtime: any) -> boolean } = {
	InstantRepair = function(runtime)
		runtime:repairAll()
		return true
	end,
	TurretOverdrive = function(runtime)
		runtime.session.profile.boosts.overdrive += 1
		runtime:applyBoosts()
		return true
	end,
	NightShield = function(runtime)
		runtime.session.profile.boosts.shield += 1
		runtime:applyBoosts()
		return true
	end,
}

function Products.start(runtimeOf: (Player) -> any)
	local keyById = {}
	for key, product in Config.Monetization.products do
		if product.id ~= 0 then
			keyById[product.id] = key
		end
	end

	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local session = player and Sessions.get(player)
		local runtime = player and runtimeOf(player)
		local key = keyById[info.ProductId]
		if session == nil or runtime == nil or key == nil or not session.save.canSave then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox will retry later
		end
		local result = Receipts.process(session.profile.receipts, info.PurchaseId, os.time(), function()
			return GRANTS[key](runtime)
		end)
		if result == "failed" then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		Receipts.prune(session.profile.receipts, MAX_RECEIPTS)
		if not session:saveNow() then
			return Enum.ProductPurchaseDecision.NotProcessedYet -- recorded in memory; retry will see "already"
		end
		if result == "granted" then
			session:notify("Store.Thanks", { item = Strings.get("Product." .. key) })
		end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return Products
