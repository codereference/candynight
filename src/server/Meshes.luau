-- Swaps placeholder parts for the low-poly Blender meshes once they're uploaded to Roblox.
-- Ids live in Config.Meshes (0 = not uploaded yet, keep the placeholder). Meshes are tinted by the
-- part's colour and scaled uniformly to fit inside the part, so proportions never stretch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local MeshSizes = require(ReplicatedStorage.Shared.MeshSizes)

local Meshes = {}

-- Dresses `part` with mesh `key`. size (optional) resizes the part first, for meshes whose shape
-- differs from the placeholder's. Returns true when a mesh was applied.
function Meshes.dress(part: BasePart, key: string, size: Vector3?): boolean
	local id = Config.Meshes[key] or 0
	local native = MeshSizes[key]
	if id == 0 or native == nil then
		return false
	end
	if size then
		part.Size = size
	end
	local fit = math.min(part.Size.X / native.X, part.Size.Y / native.Y, part.Size.Z / native.Z)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.FileMesh
	mesh.MeshId = "rbxassetid://" .. id
	mesh.Scale = Vector3.one * fit
	mesh.Parent = part
	return true
end

-- Hides placeholder pieces a mesh already includes (e.g. a creature's wisp tail).
function Meshes.hide(parts: { Instance? })
	for _, part in parts do
		if part and part:IsA("BasePart") then
			part.Transparency = 1
		end
	end
end

return Meshes
