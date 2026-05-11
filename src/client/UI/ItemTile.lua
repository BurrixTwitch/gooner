-- Renders a single weapon-skin tile. Used in the spinning reel, inventory grid,
-- and result modal — anywhere we need to show an item.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local Rarity = require(Shared.Rarity)

local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.Parent.UIBuilder)

local ItemTile = {}

local function darken(color, amount)
	return Color3.new(
		math.max(0, color.R - amount),
		math.max(0, color.G - amount),
		math.max(0, color.B - amount)
	)
end

function ItemTile.create(itemId, opts)
	opts = opts or {}
	local item = Items.get(itemId)
	local rarity = item and Rarity.get(item.rarity)
	local rarityColor = rarity and rarity.color or Theme.PanelLight

	local frame = UI.new("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = opts.size or UDim2.fromOffset(120, 140),
	}, {
		UI.corner(8),
	})

	-- Rarity gradient backdrop, brighter at the bottom like CS:GO tiles.
	local bg = UI.new("Frame", {
		BackgroundColor3 = rarityColor,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = frame,
	}, {
		UI.corner(8),
		UI.gradient(darken(rarityColor, 0.35), rarityColor, 90),
	})
	bg.BackgroundTransparency = 0.05

	-- Inner panel so the rarity color reads as a frame/glow rather than a flat fill.
	local inner = UI.new("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 4, 0, 4),
		Size = UDim2.new(1, -8, 1, -8),
		ZIndex = 2,
		Parent = frame,
	}, {
		UI.corner(6),
	})

	if item and item.icon and item.icon ~= "rbxassetid://0" then
		UI.new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = item.icon,
			ScaleType = Enum.ScaleType.Fit,
			Position = UDim2.new(0.5, 0, 0, 8),
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.new(1, -16, 0, 70),
			ZIndex = 3,
			Parent = inner,
		})
	else
		-- Fallback art: the weapon name in big letters over the rarity gradient.
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Text = (item and item.weapon) or "?",
			Font = Theme.Font,
			TextScaled = true,
			TextColor3 = Theme.Text,
			TextStrokeTransparency = 0.6,
			Position = UDim2.new(0.5, 0, 0, 10),
			AnchorPoint = Vector2.new(0.5, 0),
			Size = UDim2.new(1, -16, 0, 60),
			ZIndex = 3,
			Parent = inner,
		})
	end

	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = item and item.name or "Unknown",
		Font = Theme.Font,
		TextSize = 12,
		TextWrapped = true,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.new(0, 4, 1, -52),
		Size = UDim2.new(1, -8, 0, 36),
		ZIndex = 3,
		Parent = inner,
	})

	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = rarity and rarity.name or "",
		Font = Theme.FontRegular,
		TextSize = 10,
		TextColor3 = rarityColor,
		Position = UDim2.new(0, 4, 1, -16),
		Size = UDim2.new(1, -8, 0, 12),
		ZIndex = 3,
		Parent = inner,
	})

	return frame
end

return ItemTile
