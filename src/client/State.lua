-- Client-side mirror of the player's profile. The server is the source of
-- truth; this module just holds the most recent snapshot and lets UI scripts
-- subscribe to changes.

local State = {}

local credits = 0
local inventory = {}
local listeners = { credits = {}, inventory = {} }

local function emit(channel, ...)
	for _, fn in ipairs(listeners[channel]) do
		task.spawn(fn, ...)
	end
end

function State.getCredits()
	return credits
end

function State.setCredits(value)
	credits = value
	emit("credits", credits)
end

function State.getInventory()
	return inventory
end

function State.setInventory(list)
	inventory = list or {}
	emit("inventory", inventory)
end

function State.onCredits(fn)
	table.insert(listeners.credits, fn)
	fn(credits)
end

function State.onInventory(fn)
	table.insert(listeners.inventory, fn)
	fn(inventory)
end

return State
