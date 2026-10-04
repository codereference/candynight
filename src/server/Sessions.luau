-- One session per player in the server: their wallet and the leaderstats the HUD reads.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Rules.Economy)

local Sessions = {}

local Session = {}
Session.__index = Session

local active: { [Player]: any } = {}

function Sessions.start(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	leaderstats.Parent = player

	local session = setmetatable({
		player = player,
		wallet = Economy.new(Config.startingCash),
		cashValue = cash,
	}, Session)
	session:syncCash()
	active[player] = session
	return session
end

function Sessions.get(player: Player)
	return active[player]
end

function Sessions.stop(player: Player)
	active[player] = nil
end

function Session:syncCash()
	self.cashValue.Value = self.wallet:getCash()
end

function Session:earn(amount: number): number
	local added = self.wallet:earn(amount)
	self:syncCash()
	return added
end

function Session:spend(cost: number): boolean
	local ok = self.wallet:spend(cost)
	self:syncCash()
	return ok
end

return Sessions
