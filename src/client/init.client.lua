local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local State = require(script.State)
local LobbyUI = require(script.UI.LobbyUI)
local InventoryUI = require(script.UI.InventoryUI)
local CaseOpenUI = require(script.UI.CaseOpenUI)

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Subscribe to server-side state changes before mounting UI so first paint has
-- real data.
Remotes.get("CreditsChanged").OnClientEvent:Connect(function(value)
	State.setCredits(value)
end)
Remotes.get("InventoryChanged").OnClientEvent:Connect(function(list)
	State.setInventory(list)
end)

local inventoryView = InventoryUI.create(gui)
local caseOpenView = CaseOpenUI.create(gui)

LobbyUI.create(gui, {
	onInventory = function()
		inventoryView.open()
	end,
	onOpen = function(case, done)
		local result = Remotes.get("OpenCase"):InvokeServer(case.id)
		if not result or not result.ok then
			-- Reset the button and surface the reason briefly through the lobby.
			warn("[Case] open failed:", result and result.reason)
			done()
			return
		end
		caseOpenView.open(case.id, result.itemId, function()
			done()
		end)
	end,
})

-- Public drop announcements: low-volume feed so players see when someone hits
-- a Covert or knife.
Remotes.get("CaseOpened").OnClientEvent:Connect(function(name, caseId, itemId)
	print(("[Drop] %s unboxed %s from %s"):format(name, itemId, caseId))
end)
