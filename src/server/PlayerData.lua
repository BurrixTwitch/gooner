local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)

local DataStore = require(script.Parent.DataStore)

local PlayerData = {}

local cache = {}
local autosave = {}

local function defaultProfile()
	return {
		credits = Config.STARTING_CREDITS,
		inventory = {},
		lastDaily = 0,
	}
end

local function sanitize(profile)
	profile = profile or {}
	profile.credits = tonumber(profile.credits) or Config.STARTING_CREDITS
	if type(profile.inventory) ~= "table" then
		profile.inventory = {}
	end
	profile.lastDaily = tonumber(profile.lastDaily) or 0
	return profile
end

function PlayerData.load(player)
	if cache[player] then return cache[player] end

	local saved = DataStore.load(player.UserId)
	local profile
	if saved then
		profile = sanitize(saved)
	else
		profile = defaultProfile()
	end
	cache[player] = profile
	autosave[player] = os.time()
	return profile
end

function PlayerData.get(player)
	return cache[player]
end

function PlayerData.save(player)
	local profile = cache[player]
	if not profile then return end
	DataStore.save(player.UserId, profile)
end

function PlayerData.release(player)
	PlayerData.save(player)
	cache[player] = nil
	autosave[player] = nil
end

function PlayerData.addCredits(player, amount)
	local profile = cache[player]
	if not profile then return end
	profile.credits = math.max(0, profile.credits + amount)
	Remotes.get("CreditsChanged"):FireClient(player, profile.credits)
end

function PlayerData.spendCredits(player, amount)
	local profile = cache[player]
	if not profile or profile.credits < amount then
		return false
	end
	profile.credits = profile.credits - amount
	Remotes.get("CreditsChanged"):FireClient(player, profile.credits)
	return true
end

function PlayerData.addItem(player, instance)
	local profile = cache[player]
	if not profile then return false end
	if #profile.inventory >= Config.MAX_INVENTORY then
		return false
	end
	table.insert(profile.inventory, instance)
	Remotes.get("InventoryChanged"):FireClient(player, profile.inventory)
	return true
end

function PlayerData.removeItem(player, uuid)
	local profile = cache[player]
	if not profile then return nil end
	for i, item in ipairs(profile.inventory) do
		if item.uuid == uuid then
			local removed = table.remove(profile.inventory, i)
			Remotes.get("InventoryChanged"):FireClient(player, profile.inventory)
			return removed
		end
	end
	return nil
end

-- Periodic autosave loop. Each player is saved at most once per 60s while in
-- the server, then again on disconnect.
task.spawn(function()
	while true do
		task.wait(15)
		for player, last in pairs(autosave) do
			if os.time() - last >= 60 then
				PlayerData.save(player)
				autosave[player] = os.time()
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData.release(player)
end)

game:BindToClose(function()
	for player in pairs(cache) do
		PlayerData.save(player)
	end
end)

return PlayerData
