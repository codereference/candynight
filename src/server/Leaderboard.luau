-- Global "best survival streak" board at the end of the road, backed by an OrderedDataStore.
-- Pushes each player's best streak when it changes and redraws the top 10 every couple of minutes.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Sessions = require(script.Parent.Sessions)

local Leaderboard = {}

local REFRESH_SECONDS = 120
local TOP = 10

local store: OrderedDataStore? = nil
local pushed: { [number]: number } = {} -- userId -> best streak last written
local names: { [number]: string } = {}

local function nameOf(userId: number): string
	if names[userId] == nil then
		local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
		names[userId] = if ok then name else "?"
	end
	return names[userId]
end

local function buildBoard(): { TextLabel }
	local board = Instance.new("Part")
	board.Name = "StreakLeaderboard"
	board.Anchored = true
	board.Size = Vector3.new(18, 22, 1)
	board.CFrame = CFrame.lookAt(Vector3.new(Config.Plots.spacing * 2 - 10, 11, 0), Vector3.new(0, 11, 0))
	board.Color = Color3.fromRGB(70, 50, 110)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = workspace

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(360, 440)
	gui.Parent = board
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.Parent = gui

	local function line(text: string, height: number, color: Color3): TextLabel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, height)
		label.BackgroundTransparency = 1
		label.Font = Enum.Font.FredokaOne
		label.TextScaled = true
		label.TextColor3 = color
		label.Text = text
		label.Parent = gui
		return label
	end
	line(Strings.get("Leaderboard.Title"), 56, Color3.fromRGB(255, 200, 90))
	local rows = {}
	for _ = 1, TOP do
		table.insert(rows, line("", 34, Color3.new(1, 1, 1)))
	end
	return rows
end

local function push()
	if store == nil then
		return
	end
	for _, session in Sessions.all() do
		local userId, best = session.player.UserId, session.profile.bestStreak
		if best > 0 and pushed[userId] ~= best then
			local ok = pcall(store.SetAsync, store, tostring(userId), best)
			if ok then
				pushed[userId] = best
			end
		end
	end
end

local function redraw(rows: { TextLabel })
	if store == nil then
		rows[1].Text = Strings.get("Leaderboard.Unavailable")
		return
	end
	local ok, pages = pcall(store.GetSortedAsync, store, false, TOP)
	if not ok then
		rows[1].Text = Strings.get("Leaderboard.Unavailable")
		return
	end
	local entries = (pages :: DataStorePages):GetCurrentPage()
	for rank, row in rows do
		local entry = entries[rank]
		row.Text = if entry
			then Strings.get(
				"Leaderboard.Row",
				{ rank = rank, name = nameOf(tonumber(entry.key) :: number), streak = entry.value }
			)
			else ""
	end
end

function Leaderboard.start()
	local ok, result = pcall(DataStoreService.GetOrderedDataStore, DataStoreService, Config.Save.leaderboardName)
	store = if ok then result else nil
	local rows = buildBoard()
	task.spawn(function()
		while true do
			push()
			redraw(rows)
			task.wait(REFRESH_SECONDS)
		end
	end)
end

return Leaderboard
