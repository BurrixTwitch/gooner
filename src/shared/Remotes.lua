-- Lazy accessor for the RemoteEvent/RemoteFunction objects under
-- ReplicatedStorage.Remotes. The server creates them on boot; the client just
-- waits for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = {}

local FOLDER_NAME = "Remotes"

local DEFINITIONS = {
	OpenCase = "RemoteFunction",
	SellItem = "RemoteFunction",
	ClaimDaily = "RemoteFunction",

	CaseOpened = "RemoteEvent",
	InventoryChanged = "RemoteEvent",
	CreditsChanged = "RemoteEvent",
}

local function getFolder()
	if RunService:IsServer() then
		local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = FOLDER_NAME
			folder.Parent = ReplicatedStorage
		end
		return folder
	else
		return ReplicatedStorage:WaitForChild(FOLDER_NAME)
	end
end

function Remotes.init()
	assert(RunService:IsServer(), "Remotes.init must be called on the server")
	local folder = getFolder()
	for name, class in pairs(DEFINITIONS) do
		if not folder:FindFirstChild(name) then
			local obj = Instance.new(class)
			obj.Name = name
			obj.Parent = folder
		end
	end
end

function Remotes.get(name)
	local folder = getFolder()
	if RunService:IsServer() then
		return folder:FindFirstChild(name) or error(("Remote %s not initialised"):format(name))
	end
	return folder:WaitForChild(name)
end

return Remotes
