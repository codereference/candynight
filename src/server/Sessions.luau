-- One session per player in the server: their saved profile, wallet, and the leaderstats the HUD reads.
-- The profile is the saved truth; the wallet is written back into it before every save.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Economy = require(ReplicatedStorage.Shared.Rules.Economy)
local Income = require(ReplicatedStorage.Shared.Rules.Income)
local Rebirth = require(ReplicatedStorage.Shared.Rules.Rebirth)
local SaveSession = require(ReplicatedStorage.Shared.Persistence.SaveSession)
local DataStoreStorage = require(script.Parent.DataStoreStorage)
local Net = require(ReplicatedStorage.Shared.Net)

local Sessions = {}

local Session = {}
Session.__index = Session

local storage = DataStoreStorage.new(Config.Save.dataStoreName)
local notifyRemote = Net.event("Notify")
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
		cashChanged = Instance.new("BindableEvent"), -- fires (cash) whenever cash changes
		factors = {}, -- income boosts from passes, group, friends, events (see Income)
	}, Session)
	session:syncCash()
	session:refreshMultiplier()
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
		session:collectOffline()
		session:_writeBack()
		session.cashChanged:Destroy()
		session.save:close()
		closing -= 1
	end
end

-- Pays out offline earnings the player was offered (on Collect, or automatically when leaving).
function Session:collectOffline(): number
	local amount = self.pendingOffline or 0
	self.pendingOffline = nil
	if amount > 0 then
		self:earn(amount)
	end
	return amount
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
	local cash = self.wallet:getCash()
	if self.cashValue.Value ~= cash then
		self.cashValue.Value = cash
		self.cashChanged:Fire(cash)
	end
end

-- Sends the player a localized toast message (see Strings for keys).
function Session:notify(key: string, vars: { [string]: any }?)
	notifyRemote:FireClient(self.player, key, vars)
end

function Session:earn(amount: number): number
	local added = self.wallet:earn(amount)
	self:syncCash()
	return added
end

-- Total multiplier on shop sales right now. Systems set self.factors.* then call refreshMultiplier.
function Session:multiplier(): number
	self.factors.rebirthMultiplier = Rebirth.multiplier(Config.Rebirth, self.profile.rebirths)
	return Income.multiplier(Config.Income, self.factors)
end

function Session:refreshMultiplier()
	self.player:SetAttribute("Multiplier", self:multiplier())
	self.player:SetAttribute("Rebirths", self.profile.rebirths)
end

-- Earnings from serving customers, with every boost applied.
function Session:earnSale(amount: number): number
	return self:earn(amount * self:multiplier())
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
