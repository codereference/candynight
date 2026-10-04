-- Defense shop and grid placement on the client. The preview uses the same Grid rules as the
-- server, so green really means "this will work". The server still validates every request.
-- PC: mouse to aim, click to place, R to rotate, Q/Esc to cancel. Touch: tap to aim, then buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage.Shared.Config)
local Defenses = require(ReplicatedStorage.Shared.Rules.Defenses)
local Format = require(ReplicatedStorage.Shared.Format)
local Grid = require(ReplicatedStorage.Shared.Rules.Grid)
local Layout = require(ReplicatedStorage.Shared.Layout)
local Net = require(ReplicatedStorage.Shared.Net)
local Strings = require(ReplicatedStorage.Shared.Strings)
local Toasts = require(script.Parent.Toasts)
local Ui = require(script.Parent.Ui)

local DefensePlacement = {}

local CATALOG = Config.Defenses.catalog
local grid = Grid.new(Layout)
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local mode = nil -- { kind, moveId?, col?, row?, rot, ghost, valid }
local pointer: Vector3? = nil -- last pointer position in GUI space

local function myPlot(): Model?
	local index = player:GetAttribute("PlotIndex")
	return index and workspace:FindFirstChild("Plot" .. index) :: Model?
end

local function origin(): CFrame?
	local plot = myPlot()
	return plot and plot:GetAttribute("Origin")
end

local function cash(): number
	local stats = player:FindFirstChild("leaderstats")
	local value = stats and stats:FindFirstChild("Cash") :: IntValue?
	return if value then value.Value else 0
end

local function owns(buttonId: string): boolean
	local plot = myPlot()
	local items = plot and plot:FindFirstChild("Items")
	return items ~= nil and items:FindFirstChild(buttonId) ~= nil
end

-- Placed defenses as the rules expect them, read from the models the server replicates.
local function placedNow()
	local placed = {}
	local folder = myPlot() and (myPlot() :: Model):FindFirstChild("Defenses")
	if folder then
		for _, model in folder:GetChildren() do
			table.insert(placed, {
				id = model:GetAttribute("DefenseId"),
				col = model:GetAttribute("Col"),
				row = model:GetAttribute("Row"),
			})
		end
	end
	return placed
end

local function makeGhost(kind: string): Model
	local ghost = Instance.new("Model")
	ghost.Name = "PlacementGhost"
	local box = Instance.new("Part")
	box.Name = "Box"
	box.Anchored = true
	box.CanCollide = false
	box.CanQuery = false
	box.Size = Vector3.new(Layout.CELL - 0.4, 0.4, Layout.CELL - 0.4)
	box.Transparency = 0.35
	box.Material = Enum.Material.Neon
	box.Parent = ghost
	local marker = Instance.new("Part")
	marker.Name = "Marker"
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.Shape = Enum.PartType.Ball
	marker.Size = Vector3.one * 2.4
	marker.Transparency = 0.45
	marker.Material = Enum.Material.Neon
	marker.Parent = ghost
	ghost:SetAttribute("Kind", kind)
	ghost.Parent = workspace
	return ghost
end

local actionBar: Frame
local shopPanel: Frame
local contextPanel: Frame

local function endMode()
	if mode and mode.ghost then
		mode.ghost:Destroy()
	end
	mode = nil
	actionBar.Visible = false
end

local function startMode(kind: string, moveId: number?, rot: number?)
	endMode()
	mode = { kind = kind, moveId = moveId, rot = rot or 0, ghost = makeGhost(kind), valid = false }
	actionBar.Visible = true
	shopPanel.Visible = false
	contextPanel.Visible = false
end

local function updateGhost()
	local plotOrigin = origin()
	if mode == nil or plotOrigin == nil or pointer == nil then
		return
	end
	local ray = camera:ScreenPointToRay(pointer.X, pointer.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { mode.ghost, player.Character :: Instance }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if hit == nil then
		return
	end
	local here = plotOrigin:PointToObjectSpace(hit.Position)
	local col, row = grid:cellAt(here.X, here.Z)
	local valid = grid:validate(placedNow(), col, row, mode.moveId)
	if mode.moveId == nil and cash() < CATALOG[mode.kind].cost then
		valid = false
	end
	mode.col, mode.row, mode.valid = col, row, valid

	local x, z = Layout.cellCentre(col, row)
	local at = plotOrigin * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(mode.rot), 0)
	local colour = if valid then Color3.fromRGB(110, 230, 130) else Color3.fromRGB(240, 90, 90)
	local box, marker = mode.ghost:FindFirstChild("Box") :: Part, mode.ghost:FindFirstChild("Marker") :: Part
	box.CFrame = at * CFrame.new(0, 0.3, 0)
	marker.CFrame = at * CFrame.new(0, 2.2, 0)
	box.Color, marker.Color = colour, colour
end

local function confirm()
	if mode == nil or mode.col == nil then
		return
	end
	if not mode.valid then
		local _, reason = grid:validate(placedNow(), mode.col, mode.row, mode.moveId)
		Toasts.show(Strings.get("Reason." .. (reason or "cash")))
		return
	end
	local ok, reason
	if mode.moveId then
		ok, reason = Net.func("MoveDefense"):InvokeServer(mode.moveId, mode.col, mode.row, mode.rot)
	else
		ok, reason = Net.func("PlaceDefense"):InvokeServer(mode.kind, mode.col, mode.row, mode.rot)
	end
	if not ok then
		Toasts.show(Strings.get("Reason." .. (reason or "unknown")))
		return
	end
	-- Keep placing the same kind while it's affordable; moves finish after one go.
	if mode.moveId or cash() < CATALOG[mode.kind].cost then
		endMode()
	end
end

local function rotate()
	if mode then
		mode.rot = (mode.rot + 90) % 360
		updateGhost()
	end
end

local function sortedKinds(): { string }
	local kinds = {}
	for kind in CATALOG do
		table.insert(kinds, kind)
	end
	table.sort(kinds, function(a, b)
		return CATALOG[a].order < CATALOG[b].order
	end)
	return kinds
end

local function buildShop(gui: ScreenGui)
	shopPanel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(280, 260),
		BackgroundColor3 = Ui.CREAM,
		Visible = false,
		Parent = gui,
	}, { Ui.corner(UDim.new(0, 16)), Ui.stroke(Ui.PINK, 4) })
	Ui.new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = shopPanel })
	Ui.new("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = shopPanel,
	})

	local rows = {}
	for order, kind in sortedKinds() do
		local def = CATALOG[kind]
		local row = Ui.button({
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, 64),
			Text = "",
			BackgroundColor3 = Ui.MINT,
			Parent = shopPanel,
		}, function()
			if def.requires and not owns(def.requires) then
				Toasts.show(Strings.get("Reason.locked"))
			else
				startMode(kind)
			end
		end)
		Ui.label({ Size = UDim2.new(1, 0, 0.55, 0), Text = Strings.get("Defense." .. kind), Parent = row })
		local detail = Ui.label({
			Position = UDim2.fromScale(0, 0.55),
			Size = UDim2.new(1, 0, 0.45, 0),
			TextColor3 = Ui.GOLD,
			Parent = row,
		})
		rows[kind] = { button = row, detail = detail }
	end

	local function refresh()
		for kind, row in rows do
			local def = CATALOG[kind]
			local locked = def.requires and not owns(def.requires)
			row.detail.Text = if locked
				then Strings.get("Defense.Locked", { item = Strings.get("Button." .. def.requires) })
				else Format.cash(def.cost)
			row.button.BackgroundColor3 = if locked then Color3.fromRGB(180, 170, 190) else Ui.MINT
		end
	end

	Ui.button({
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, -170),
		Size = UDim2.fromOffset(150, 44),
		Text = Strings.get("Defense.Shop"),
		Parent = gui,
	}, function()
		if player:GetAttribute("PlotIndex") == nil then
			return
		end
		refresh()
		shopPanel.Visible = not shopPanel.Visible
		contextPanel.Visible = false
		endMode()
	end)
end

local function buildActionBar(gui: ScreenGui)
	actionBar = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(420, 56),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 10),
		Parent = actionBar,
	})
	Ui.button({ Size = UDim2.fromOffset(130, 52), Text = Strings.get("Defense.Rotate"), Parent = actionBar }, rotate)
	Ui.button({
		Size = UDim2.fromOffset(130, 52),
		Text = Strings.get("Defense.Place"),
		BackgroundColor3 = Ui.MINT,
		Parent = actionBar,
	}, confirm)
	Ui.button({
		Size = UDim2.fromOffset(130, 52),
		Text = Strings.get("Defense.Cancel"),
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = actionBar,
	}, endMode)
end

local function buildContext(gui: ScreenGui)
	contextPanel = Ui.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(440, 56),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = contextPanel,
	})
end

-- Shows Move / Sell / Repair for one of the player's defenses.
local function openContext(model: Model)
	contextPanel:ClearAllChildren()
	Ui.new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 8),
		Parent = contextPanel,
	})
	local id, kind = model:GetAttribute("DefenseId"), model:GetAttribute("Kind")
	local entry = { kind = kind, hp = (model:GetAttribute("HealthShare") or 1) * CATALOG[kind].hp }
	local function close()
		contextPanel.Visible = false
	end
	Ui.button(
		{ Size = UDim2.fromOffset(100, 52), Text = Strings.get("Defense.Move"), Parent = contextPanel },
		function()
			close()
			startMode(kind, id, model:GetAttribute("Rot") :: number?)
		end
	)
	local refund = Defenses.sellValue(CATALOG, Config.Defenses, entry)
	Ui.button({
		Size = UDim2.fromOffset(120, 52),
		Text = Strings.get("Defense.Sell", { cash = Format.cash(refund) }),
		BackgroundColor3 = Color3.fromRGB(240, 170, 90),
		Parent = contextPanel,
	}, function()
		close()
		local ok, reason = Net.func("SellDefense"):InvokeServer(id)
		if not ok then
			Toasts.show(Strings.get("Reason." .. (reason or "unknown")))
		end
	end)
	local repairCost = Defenses.repairCost(CATALOG, Config.Defenses, entry)
	if repairCost > 0 then
		Ui.button({
			Size = UDim2.fromOffset(130, 52),
			Text = Strings.get("Defense.Repair", { cash = Format.cash(repairCost) }),
			BackgroundColor3 = Ui.MINT,
			Parent = contextPanel,
		}, function()
			close()
			local ok, reason = Net.func("RepairDefense"):InvokeServer(id)
			if not ok then
				Toasts.show(Strings.get("Reason." .. (reason or "unknown")))
			end
		end)
	end
	Ui.button({
		Size = UDim2.fromOffset(52, 52),
		Text = "✕",
		BackgroundColor3 = Color3.fromRGB(200, 120, 140),
		Parent = contextPanel,
	}, close)
	contextPanel.Visible = true
	shopPanel.Visible = false
end

-- A tap or click outside placement mode: did it land on one of my defenses?
local function trySelect(position: Vector3)
	local folder = myPlot() and (myPlot() :: Model):FindFirstChild("Defenses")
	if folder == nil then
		return
	end
	local ray = camera:ScreenPointToRay(position.X, position.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	if model and model:GetAttribute("DefenseId") then
		openContext(model)
	end
end

function DefensePlacement.mount(playerGui: Instance)
	local gui = Ui.screen("Defenses", playerGui, 4)
	buildShop(gui)
	buildActionBar(gui)
	buildContext(gui)

	UserInputService.InputChanged:Connect(function(input, processed)
		if input.UserInputType == Enum.UserInputType.MouseMovement and not processed then
			pointer = input.Position
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local kind = input.UserInputType
		if kind == Enum.UserInputType.Touch then
			pointer = input.Position
			if mode == nil then
				trySelect(input.Position)
			end
		elseif kind == Enum.UserInputType.MouseButton1 then
			pointer = input.Position
			if mode then
				updateGhost()
				confirm()
			else
				trySelect(input.Position)
			end
		elseif mode and input.KeyCode == Enum.KeyCode.R then
			rotate()
		elseif mode and (input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.Escape) then
			endMode()
		end
	end)
	RunService.RenderStepped:Connect(updateGhost)
	player:GetAttributeChangedSignal("PlotIndex"):Connect(endMode)
end

return DefensePlacement
