-- Plot-local measurements in studs, shared by world building and the placement grid.
-- -Z is the front of the plot, facing the road where customers come from.

local Layout = {}

Layout.PLOT_SIZE = 64
Layout.COUNTER_Z = -6
Layout.OWNER_SPAWN = { x = 0, z = 4 }
Layout.ENTRANCE = { x = 0, z = -40 } -- out on the road
Layout.EXIT = { x = 40, z = -40 }

-- Areas defenses can't be placed on: { minX, maxX, minZ, maxZ }.
Layout.ZONES = {
	shop = { -12, 12, -12, 8 },
	queue = { -4, 4, -32, -10 },
	backHouse = { -12, 12, 12, 28 },
	buttons = { 18, 32, -32, 32 },
	weaponsStall = { -30, -16, -26, -14 },
	ownerSign = { -27, -17, -32, -28 },
}

-- Defense grid: square cells covering the whole plot.
Layout.CELL = 4
Layout.GRID = Layout.PLOT_SIZE // Layout.CELL

-- Centre of a grid cell (1-based column/row) in plot-local studs.
function Layout.cellCentre(col: number, row: number): (number, number)
	local half = Layout.PLOT_SIZE / 2
	return -half + (col - 0.5) * Layout.CELL, -half + (row - 0.5) * Layout.CELL
end

return Layout
