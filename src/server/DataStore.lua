-- Thin wrapper around DataStoreService with a memory fallback. In Studio
-- without API access the real DataStore calls fail; we still want the game to
-- be playable in a session, so we fall back to an in-memory table after the
-- first failure.

local DataStoreService = game:GetService("DataStoreService")

local STORE_NAME = "GoonerCases_PlayerData_v1"

local DataStore = {}
DataStore.__index = DataStore

local memory = {}
local useMemory = false
local store

local function getStore()
	if useMemory then
		return nil
	end
	if not store then
		local ok, result = pcall(function()
			return DataStoreService:GetDataStore(STORE_NAME)
		end)
		if ok then
			store = result
		else
			useMemory = true
			warn("[DataStore] Falling back to in-memory store:", result)
		end
	end
	return store
end

function DataStore.load(userId)
	local key = tostring(userId)
	local s = getStore()
	if s then
		local ok, data = pcall(function() return s:GetAsync(key) end)
		if ok then
			return data
		end
		warn("[DataStore] GetAsync failed:", data)
		useMemory = true
	end
	return memory[key]
end

function DataStore.save(userId, data)
	local key = tostring(userId)
	memory[key] = data
	local s = getStore()
	if s then
		local ok, err = pcall(function() s:SetAsync(key, data) end)
		if not ok then
			warn("[DataStore] SetAsync failed:", err)
		end
	end
end

return DataStore
