-- Item database. Each entry is a weapon skin with a rarity tier and a base
-- credit value used for selling. Icons are Roblox asset ids; placeholder ids
-- can be swapped out for real uploads later.

local Items = {
	-- Mil-Spec (Blue)
	p2000_imperial = { name = "P2000 | Imperial Dragon", weapon = "P2000", rarity = "MilSpec", value = 120, icon = "rbxassetid://0" },
	mp9_sand_dashed = { name = "MP9 | Sand Dashed", weapon = "MP9", rarity = "MilSpec", value = 110, icon = "rbxassetid://0" },
	famas_pulse = { name = "FAMAS | Pulse", weapon = "FAMAS", rarity = "MilSpec", value = 145, icon = "rbxassetid://0" },
	negev_loudmouth = { name = "Negev | Loudmouth", weapon = "Negev", rarity = "MilSpec", value = 100, icon = "rbxassetid://0" },

	-- Restricted (Purple)
	five_seven_monkey = { name = "Five-SeveN | Monkey Business", weapon = "Five-SeveN", rarity = "Restricted", value = 360, icon = "rbxassetid://0" },
	xm1014_oxide = { name = "XM1014 | Oxide Blaze", weapon = "XM1014", rarity = "Restricted", value = 320, icon = "rbxassetid://0" },
	ump45_arctic = { name = "UMP-45 | Arctic Wolf", weapon = "UMP-45", rarity = "Restricted", value = 410, icon = "rbxassetid://0" },

	-- Classified (Pink)
	usp_kill_confirmed = { name = "USP-S | Kill Confirmed", weapon = "USP-S", rarity = "Classified", value = 1850, icon = "rbxassetid://0" },
	mp7_bloodsport = { name = "MP7 | Bloodsport", weapon = "MP7", rarity = "Classified", value = 1620, icon = "rbxassetid://0" },

	-- Covert (Red)
	ak47_neon_rider = { name = "AK-47 | Neon Rider", weapon = "AK-47", rarity = "Covert", value = 6800, icon = "rbxassetid://0" },
	m4a4_hellfire = { name = "M4A4 | Hellfire", weapon = "M4A4", rarity = "Covert", value = 6400, icon = "rbxassetid://0" },

	-- Exceedingly Rare (Gold knives / gloves)
	karambit_doppler = { name = "★ Karambit | Doppler", weapon = "Karambit", rarity = "Exceedingly", value = 75000, icon = "rbxassetid://0" },
	butterfly_fade = { name = "★ Butterfly Knife | Fade", weapon = "Butterfly Knife", rarity = "Exceedingly", value = 82000, icon = "rbxassetid://0" },
	gloves_pandoras_box = { name = "★ Specialist Gloves | Pandora's Box", weapon = "Gloves", rarity = "Exceedingly", value = 24000, icon = "rbxassetid://0" },
}

function Items.get(id)
	return Items[id]
end

function Items.exists(id)
	return Items[id] ~= nil
end

return Items
