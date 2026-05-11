-- A modal inventory grid. Clicking a tile opens a small panel that lets the
-- player sell it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared.Items)
local Rarity = require(Shared.Rarity)
local Config = require(Shared.Config)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local Theme = require(script.Parent.Theme)
local ItemTile = require(script.Parent.ItemTile)
local UI = require(script.Parent.Parent.UIBuilder)
local State = require(script.Parent.Parent.State)

local InventoryUI = {}

function InventoryUI.create(parent)
	local screen = UI.new("ScreenGui", {
		Name = "Inventory",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		DisplayOrder = 30,
		Enabled = false,
		Parent = parent,
	})

	local dimmer = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		Parent = screen,
	})

	local panel = UI.new("Frame", {
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(900, 600),
		Parent = dimmer,
	}, { UI.corner(12), UI.stroke(Theme.PanelLight, 1, 0.4) })

	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Inventory",
		Font = Theme.Font,
		TextSize = 22,
		TextColor3 = Theme.Text,
		Position = UDim2.new(0, 24, 0, 16),
		Size = UDim2.new(0, 240, 0, 28),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local close = UI.new("TextButton", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Text = "Close",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Position = UDim2.new(1, -88, 0, 16),
		Size = UDim2.fromOffset(72, 28),
		Parent = panel,
	}, { UI.corner(6) })

	local sellInfo = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = ("Sell payout: %d%% of nominal value"):format(math.floor(Config.SELL_RATIO * 100)),
		Font = Theme.FontRegular,
		TextSize = 12,
		TextColor3 = Theme.TextDim,
		Position = UDim2.new(0, 24, 0, 48),
		Size = UDim2.new(1, -48, 0, 16),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = panel,
	})

	local grid = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 24, 0, 80),
		Size = UDim2.new(1, -48, 1, -104),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Accent,
		Parent = panel,
	})

	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(140, 160),
		CellPadding = UDim2.fromOffset(12, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = grid,
	})

	local function rarityRank(item)
		for i, tier in ipairs(Rarity.Order) do
			if tier == item.rarity then return i end
		end
		return 0
	end

	local function refresh()
		for _, child in ipairs(grid:GetChildren()) do
			if child:IsA("GuiObject") then child:Destroy() end
		end

		local inv = State.getInventory()
		local sorted = {}
		for _, instance in ipairs(inv) do table.insert(sorted, instance) end
		table.sort(sorted, function(a, b)
			local ia, ib = Items.get(a.itemId), Items.get(b.itemId)
			local ra = ia and rarityRank(ia) or 0
			local rb = ib and rarityRank(ib) or 0
			if ra ~= rb then return ra > rb end
			return a.acquiredAt > b.acquiredAt
		end)

		for i, instance in ipairs(sorted) do
			local tile = ItemTile.create(instance.itemId, { size = UDim2.fromOffset(140, 160) })
			tile.LayoutOrder = i

			local button = UI.new("TextButton", {
				BackgroundTransparency = 1,
				Text = "",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 10,
				Parent = tile,
			})

			local item = Items.get(instance.itemId)
			local payout = item and math.floor(item.value * Config.SELL_RATIO) or 0

			button.MouseButton1Click:Connect(function()
				button.Active = false
				local result = Remotes.get("SellItem"):InvokeServer(instance.uuid)
				if result.ok then
					sellInfo.Text = ("Sold for $%s"):format(Util.formatCredits(payout))
					sellInfo.TextColor3 = Theme.Success
					task.delay(2, function()
						sellInfo.TextColor3 = Theme.TextDim
						sellInfo.Text = ("Sell payout: %d%% of nominal value"):format(math.floor(Config.SELL_RATIO * 100))
					end)
				else
					button.Active = true
					sellInfo.Text = result.reason or "Sell failed"
					sellInfo.TextColor3 = Theme.Danger
				end
			end)

			tile.Parent = grid
		end

		if #sorted == 0 then
			UI.new("TextLabel", {
				BackgroundTransparency = 1,
				Text = "Empty — open a case to get started.",
				Font = Theme.FontRegular,
				TextSize = 14,
				TextColor3 = Theme.TextDim,
				Size = UDim2.fromOffset(400, 40),
				Parent = grid,
			})
		end
	end

	State.onInventory(refresh)
	close.MouseButton1Click:Connect(function() screen.Enabled = false end)

	function InventoryUI.open() screen.Enabled = true; refresh() end
	function InventoryUI.close() screen.Enabled = false end

	return InventoryUI
end

return InventoryUI
