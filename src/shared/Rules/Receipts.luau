-- Pure exactly-once rules for developer product receipts.
-- receipts: the profile's { [purchaseId] = unix time granted }.
-- Flow: process() grants and records the receipt; the caller must then SAVE before telling Roblox
-- the purchase was granted. If Roblox retries a purchase we already recorded, nothing is granted twice.

local Receipts = {}

-- Returns "granted" | "already" | "failed". grant() returns true when the product was delivered.
function Receipts.process(receipts, purchaseId: string, now: number, grant: () -> boolean): string
	if receipts[purchaseId] then
		return "already"
	end
	if not grant() then
		return "failed"
	end
	receipts[purchaseId] = now
	return "granted"
end

-- Keeps only the newest `max` receipts so saves don't grow forever.
function Receipts.prune(receipts, max: number)
	local list = {}
	for id, at in receipts do
		table.insert(list, { id = id, at = at })
	end
	if #list <= max then
		return
	end
	table.sort(list, function(a, b)
		return a.at > b.at
	end)
	for i = max + 1, #list do
		receipts[list[i].id] = nil
	end
end

return Receipts
