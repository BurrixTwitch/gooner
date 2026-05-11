local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cases = require(Shared.Cases)
local Items = require(Shared.Items)
local Rarity = require(Shared.Rarity)
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local PlayerData = require(script.Parent.PlayerData)

local CaseService = {}

local rng = Random.new()

-- Group a case's item ids by rarity once so case opens are O(1) tier lookup.
local groupedCache = {}
local function groupItemsByRarity(case)
	if groupedCache[case.id] then return groupedCache[case.id] end
	local grouped = {}
	for _, itemId in ipairs(case.items) do
		local item = Items.get(itemId)
		if item then
			grouped[item.rarity] = grouped[item.rarity] or {}
			table.insert(grouped[item.rarity], itemId)
		end
	end
	groupedCache[case.id] = grouped
	return grouped
end

-- Pick a rarity tier that this case actually contains, weighted by Rarity.lua.
-- We restrict to tiers present in the case so a 5-tier weight table doesn't
-- silently give the player nothing when a tier is missing.
local function rollRarity(case)
	local grouped = groupItemsByRarity(case)
	local candidates = {}
	for _, tier in ipairs(Rarity.Order) do
		if grouped[tier] and #grouped[tier] > 0 then
			table.insert(candidates, tier)
		end
	end
	if #candidates == 0 then return nil end
	return Util.weightedPick(candidates, function(tier)
		return Rarity.Data[tier].weight
	end, function() return rng:NextNumber() end)
end

local function rollItem(case)
	local tier = rollRarity(case)
	if not tier then return nil end
	local pool = groupItemsByRarity(case)[tier]
	return pool[rng:NextInteger(1, #pool)]
end

function CaseService.openCase(player, caseId)
	local case = Cases.get(caseId)
	if not case then
		return { ok = false, reason = "Unknown case" }
	end
	if not PlayerData.spendCredits(player, case.price) then
		return { ok = false, reason = "Not enough credits" }
	end

	local itemId = rollItem(case)
	if not itemId then
		-- Refund if the case is misconfigured rather than swallow the credits.
		PlayerData.addCredits(player, case.price)
		return { ok = false, reason = "Case has no rollable items" }
	end

	local item = Items.get(itemId)
	local instance = {
		uuid = Util.uuid(),
		itemId = itemId,
		acquiredAt = os.time(),
		sourceCase = caseId,
	}

	if not PlayerData.addItem(player, instance) then
		-- Inventory full: refund half so opens aren't a total loss.
		PlayerData.addCredits(player, math.floor(case.price * 0.5))
		return { ok = false, reason = "Inventory full" }
	end

	-- Public announcement for rare drops (could light up a feed in the UI).
	if item.rarity == "Covert" or item.rarity == "Exceedingly" then
		Remotes.get("CaseOpened"):FireAllClients(player.Name, caseId, itemId)
	end

	return {
		ok = true,
		caseId = caseId,
		itemId = itemId,
		instance = instance,
	}
end

function CaseService.sellItem(player, uuid)
	local profile = PlayerData.get(player)
	if not profile then return { ok = false, reason = "No profile" } end

	local found
	for _, inst in ipairs(profile.inventory) do
		if inst.uuid == uuid then
			found = inst
			break
		end
	end
	if not found then
		return { ok = false, reason = "Item not found" }
	end

	local item = Items.get(found.itemId)
	if not item then
		return { ok = false, reason = "Unknown item" }
	end

	local removed = PlayerData.removeItem(player, uuid)
	if not removed then
		return { ok = false, reason = "Item not found" }
	end
	local payout = math.floor(item.value * Config.SELL_RATIO)
	PlayerData.addCredits(player, payout)
	return { ok = true, credits = payout }
end

function CaseService.claimDaily(player)
	local profile = PlayerData.get(player)
	if not profile then return { ok = false, reason = "No profile" } end
	local now = os.time()
	if now - profile.lastDaily < 86400 then
		local wait = 86400 - (now - profile.lastDaily)
		return { ok = false, reason = "Already claimed", wait = wait }
	end
	profile.lastDaily = now
	PlayerData.addCredits(player, Config.DAILY_BONUS)
	return { ok = true, credits = Config.DAILY_BONUS }
end

return CaseService
