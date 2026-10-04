-- Buy pads in a plot's button column. Shows whatever buttons are available, coloured by affordability.
-- Stepping on a pad calls onStep(player, id); the caller decides whether the purchase goes through.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Format = require(ReplicatedStorage.Shared.Format)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Strings = require(ReplicatedStorage.Shared.Strings)

local ButtonsView = {}
ButtonsView.__index = ButtonsView

local AFFORDABLE = Color3.fromRGB(110, 220, 120)
local TOO_PRICEY = Color3.fromRGB(235, 120, 120)
local STEP_COOLDOWN = 0.75

local zone = Layout.ZONES.buttons
local COLUMNS = { zone[1] + 3.5, zone[2] - 3.5 }
local ROW_STEP = 7

-- Pad position for the n-th visible button: fills two columns, front to back.
local function slot(n: number): (number, number)
	local column = COLUMNS[(n - 1) % #COLUMNS + 1]
	local row = (n - 1) // #COLUMNS
	return column, zone[3] + 4 + row * ROW_STEP
end

function ButtonsView.new(view, onStep: (Player, string) -> ())
	return setmetatable({ view = view, onStep = onStep, pads = {} }, ButtonsView)
end

function ButtonsView:_makePad(id: string, cost: number, n: number)
	local x, z = slot(n)
	local pad = Instance.new("Part")
	pad.Name = id
	pad.Anchored = true
	pad.Size = Vector3.new(5, 0.5, 5)
	pad.CFrame = self.view.at(x, 0.35, z)
	pad.Material = Enum.Material.SmoothPlastic
	pad.Parent = self.view.buttons

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 60)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 70
	gui.Parent = pad
	local function label(text: string, y: number, color: Color3)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, 0, 0.5, 0)
		l.Position = UDim2.fromScale(0, y)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextColor3 = color
		l.TextStrokeTransparency = 0.3
		l.Text = text
		l.Parent = gui
	end
	label(Strings.get("Button." .. id), 0, Color3.new(1, 1, 1))
	label(Format.cash(cost), 0.5, Color3.fromRGB(255, 240, 120))

	local lastStep: { [Player]: number } = {}
	pad.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player == nil then
			return
		end
		local now = os.clock()
		if now - (lastStep[player] or 0) < STEP_COOLDOWN then
			return
		end
		lastStep[player] = now
		self.onStep(player, id)
	end)

	self.pads[id] = { part = pad, cost = cost }
end

-- Shows exactly these buttons. buttons: { { id, cost } } in display order.
function ButtonsView:show(buttons, cash: number)
	self:clear()
	for n, button in buttons do
		self:_makePad(button.id, button.cost, n)
	end
	self:refreshColours(cash)
end

function ButtonsView:refreshColours(cash: number)
	for _, pad in self.pads do
		pad.part.Color = if cash >= pad.cost then AFFORDABLE else TOO_PRICEY
	end
end

function ButtonsView:clear()
	for _, pad in self.pads do
		pad.part:Destroy()
	end
	table.clear(self.pads)
end

return ButtonsView
