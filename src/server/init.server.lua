local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

Remotes.init()

local PlayerData = require(script.PlayerData)
local CaseService = require(script.CaseService)

local function onPlayerAdded(player)
	local profile = PlayerData.load(player)
	-- Wait for the client to be ready before pushing initial state.
	task.spawn(function()
		task.wait(0.25)
		Remotes.get("CreditsChanged"):FireClient(player, profile.credits)
		Remotes.get("InventoryChanged"):FireClient(player, profile.inventory)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Remotes.get("OpenCase").OnServerInvoke = function(player, caseId)
	if typeof(caseId) ~= "string" then return { ok = false, reason = "Bad request" } end
	return CaseService.openCase(player, caseId)
end

Remotes.get("SellItem").OnServerInvoke = function(player, uuid)
	if typeof(uuid) ~= "string" then return { ok = false, reason = "Bad request" } end
	return CaseService.sellItem(player, uuid)
end

Remotes.get("ClaimDaily").OnServerInvoke = function(player)
	return CaseService.claimDaily(player)
end
