-- Pure placement rules for defenses on a plot's grid. Used by the server to validate and by the
-- client to colour the preview, so both always agree.
-- placed entries: { id, kind, col, row, rot, hp }. Cells are 1-based (col along x, row along z).

local Grid = {}
Grid.__index = Grid

-- layout: { PLOT_SIZE, CELL, GRID, ZONES = { name = { minX, maxX, minZ, maxZ } } } (see Layout)
function Grid.new(layout)
	return setmetatable({ layout = layout }, Grid)
end

function Grid:inBounds(col: number, row: number): boolean
	local size = self.layout.GRID
	return col >= 1 and row >= 1 and col <= size and row <= size and col % 1 == 0 and row % 1 == 0
end

-- Plot-local rectangle a cell covers.
function Grid:cellRect(col: number, row: number): (number, number, number, number)
	local half, cell = self.layout.PLOT_SIZE / 2, self.layout.CELL
	local minX, minZ = -half + (col - 1) * cell, -half + (row - 1) * cell
	return minX, minX + cell, minZ, minZ + cell
end

-- Cell under a plot-local point.
function Grid:cellAt(x: number, z: number): (number, number)
	local half, cell = self.layout.PLOT_SIZE / 2, self.layout.CELL
	return math.floor((x + half) / cell) + 1, math.floor((z + half) / cell) + 1
end

-- True when any part of the cell overlaps a no-build zone (shop, customer path, buttons...).
function Grid:isBlocked(col: number, row: number): boolean
	local minX, maxX, minZ, maxZ = self:cellRect(col, row)
	for _, zone in self.layout.ZONES do
		if minX < zone[2] and maxX > zone[1] and minZ < zone[4] and maxZ > zone[3] then
			return true
		end
	end
	return false
end

-- Whether a defense may go at (col, row). ignoreId lets a defense being moved ignore itself.
-- Returns true, or false plus "bounds" | "blocked" | "occupied".
function Grid:validate(placed, col: number, row: number, ignoreId: number?): (boolean, string?)
	if not self:inBounds(col, row) then
		return false, "bounds"
	end
	if self:isBlocked(col, row) then
		return false, "blocked"
	end
	for _, entry in placed do
		if entry.id ~= ignoreId and entry.col == col and entry.row == row then
			return false, "occupied"
		end
	end
	return true, nil
end

return Grid
