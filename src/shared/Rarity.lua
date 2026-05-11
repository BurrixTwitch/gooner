local Rarity = {}

Rarity.Order = {
	"MilSpec",
	"Restricted",
	"Classified",
	"Covert",
	"Exceedingly",
}

Rarity.Data = {
	MilSpec = {
		name = "Mil-Spec",
		color = Color3.fromRGB(75, 105, 255),
		weight = 7992,
	},
	Restricted = {
		name = "Restricted",
		color = Color3.fromRGB(136, 71, 255),
		weight = 1598,
	},
	Classified = {
		name = "Classified",
		color = Color3.fromRGB(211, 44, 230),
		weight = 320,
	},
	Covert = {
		name = "Covert",
		color = Color3.fromRGB(235, 75, 75),
		weight = 64,
	},
	Exceedingly = {
		name = "Exceedingly Rare",
		color = Color3.fromRGB(255, 215, 0),
		weight = 26,
	},
}

function Rarity.get(id)
	return Rarity.Data[id]
end

function Rarity.color(id)
	local r = Rarity.Data[id]
	return r and r.color or Color3.fromRGB(180, 180, 180)
end

return Rarity
