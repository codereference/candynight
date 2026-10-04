-- Pure rules for which player owns which plot. Players are identified by user id.

local Plots = {}
Plots.__index = Plots

function Plots.new(count: number)
	return setmetatable({ count = count, owners = {} }, Plots)
end

function Plots:plotOf(userId: number): number?
	for index = 1, self.count do
		if self.owners[index] == userId then
			return index
		end
	end
	return nil
end

function Plots:ownerOf(index: number): number?
	return self.owners[index]
end

-- Gives the player the lowest free plot. Claiming twice returns the same plot. nil when the server is full.
function Plots:claim(userId: number): number?
	local existing = self:plotOf(userId)
	if existing then
		return existing
	end
	for index = 1, self.count do
		if self.owners[index] == nil then
			self.owners[index] = userId
			return index
		end
	end
	return nil
end

-- Frees the player's plot. Returns the freed index, or nil if they had none.
function Plots:release(userId: number): number?
	local index = self:plotOf(userId)
	if index then
		self.owners[index] = nil
	end
	return index
end

return Plots
