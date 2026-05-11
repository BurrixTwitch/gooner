-- Case definitions. Each case references item ids from Items.lua. When the case
-- is opened the server first rolls a rarity tier (weighted by Rarity.lua) and
-- then picks uniformly among the items of that tier present in the case. If a
-- case lacks any items of the rolled tier, it falls back to the closest lower
-- tier so opens always pay out something.

local Cases = {
	clutch = {
		id = "clutch",
		name = "Clutch Case",
		price = 250,
		icon = "rbxassetid://0",
		items = {
			"p2000_imperial",
			"mp9_sand_dashed",
			"famas_pulse",
			"negev_loudmouth",
			"five_seven_monkey",
			"xm1014_oxide",
			"usp_kill_confirmed",
			"ak47_neon_rider",
			"karambit_doppler",
			"butterfly_fade",
			"gloves_pandoras_box",
		},
	},
	chroma = {
		id = "chroma",
		name = "Chroma Case",
		price = 400,
		icon = "rbxassetid://0",
		items = {
			"mp9_sand_dashed",
			"famas_pulse",
			"ump45_arctic",
			"five_seven_monkey",
			"mp7_bloodsport",
			"usp_kill_confirmed",
			"m4a4_hellfire",
			"karambit_doppler",
			"butterfly_fade",
		},
	},
	prisma = {
		id = "prisma",
		name = "Prisma Case",
		price = 800,
		icon = "rbxassetid://0",
		items = {
			"famas_pulse",
			"negev_loudmouth",
			"xm1014_oxide",
			"ump45_arctic",
			"mp7_bloodsport",
			"ak47_neon_rider",
			"m4a4_hellfire",
			"karambit_doppler",
			"butterfly_fade",
			"gloves_pandoras_box",
		},
	},
}

function Cases.get(id)
	return Cases[id]
end

function Cases.all()
	local list = {}
	for _, c in pairs(Cases) do
		table.insert(list, c)
	end
	table.sort(list, function(a, b) return a.price < b.price end)
	return list
end

return Cases
