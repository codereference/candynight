-- One session per player in the server: their saved profile, wallet, and the leaderstats the HUD reads.
-- The profile is the saved truth; the wallet is written back into it before every save.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Rules.Economy)
local SaveSession = require(ReplicatedStorage.Shared.Persistence.SaveSession)
local DataStoreStorage = require(script.Parent.DataStoreStorage)

local Sessions = {}

local Session = {}
Session.__index = Session

local storage = DataStoreStorage.new(Config.Save.dataStoreName)
local active: { [Player]: any } = {}
local closing = 0 -- final saves still in flight; shutdown waits for these

-- Loads the player's save (yields). Returns nil if they left while loading.
function Sessions.start(player: Player)
	local save = SaveSession.load(storage, "Player_" .. player.UserId)
	if not save.canSave then
		warn(`[Save] {player.Name} is playing without saving this session`)
	end
	if player.Parent ~= Players then
		save:close()
		return nil
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	leaderstats.Parent = player

	local session = setmetatable({
		player = player,
		save = save,
		profile = save.profile,
		wallet = Economy.new(save.profile.cash),
		cashValue = cash,
	}, Session)
	session:syncCash()
	active[player] = session
	return session
end

function Sessions.get(player: Player)
	return active[player]
end

function Sessions.all()
	return active
end

-- Final save and cleanup when the player leaves.
function Sessions.stop(player: Player)
	local session = active[player]
	if session then
		active[player] = nil
		closing += 1
		session:_writeBack()
		session.save:close()
		closing -= 1
	end
end

function Session:_writeBack()
	self.profile.cash = self.wallet:getCash()
	self.profile.lastOnline = os.time()
end

function Session:saveNow(): boolean
	self:_writeBack()
	return self.save:save()
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

-- Periodic autosave, and a last save for everyone when the server shuts down.
task.spawn(function()
	while true do
		task.wait(Config.Save.autosaveSeconds)
		for _, session in active do
			task.spawn(session.saveNow, session)
		end
	end
end)

game:BindToClose(function()
	for player in active do
		task.spawn(Sessions.stop, player)
	end
	while closing > 0 or next(active) do
		task.wait()
	end
end)

return Sessions
