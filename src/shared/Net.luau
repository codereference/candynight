-- Named remotes. The server creates them; clients wait for them. Clients only ever send requests;
-- the server validates everything.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local function remote(className: string, name: string): Instance
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if RunService:IsServer() then
		if folder == nil then
			folder = Instance.new("Folder")
			folder.Name = "Remotes"
			folder.Parent = ReplicatedStorage
		end
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing
		end
		local created = Instance.new(className)
		created.Name = name
		created.Parent = folder
		return created
	end
	return ReplicatedStorage:WaitForChild("Remotes"):WaitForChild(name)
end

function Net.event(name: string): RemoteEvent
	return remote("RemoteEvent", name) :: RemoteEvent
end

function Net.func(name: string): RemoteFunction
	return remote("RemoteFunction", name) :: RemoteFunction
end

return Net
