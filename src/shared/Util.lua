local Util = {}

function Util.formatCredits(n)
	n = math.floor(n + 0.5)
	local s = tostring(math.abs(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	if n < 0 then
		return "-" .. formatted
	end
	return formatted
end

function Util.weightedPick(items, weightOf, rng)
	local total = 0
	for _, item in ipairs(items) do
		total = total + weightOf(item)
	end
	if total <= 0 then
		return items[1]
	end
	local roll = (rng or math.random)() * total
	local acc = 0
	for _, item in ipairs(items) do
		acc = acc + weightOf(item)
		if roll <= acc then
			return item
		end
	end
	return items[#items]
end

function Util.uuid()
	local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
	return (template:gsub("[xy]", function(c)
		local v = c == "x" and math.random(0, 15) or math.random(8, 11)
		return string.format("%x", v)
	end))
end

return Util
