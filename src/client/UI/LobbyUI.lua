-- The "shop" view: lists available cases plus the player's credit balance and
-- a button to open the inventory. Buying a case fires OpenCase and hands the
-- result off to CaseOpenUI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cases = require(Shared.Cases)
local Remotes = require(Shared.Remotes)
local Util = require(Shared.Util)

local Theme = require(script.Parent.Theme)
local UI = require(script.Parent.Parent.UIBuilder)
local State = require(script.Parent.Parent.State)

local LobbyUI = {}

local function makeCaseCard(case, onBuy)
	local card = UI.new("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(220, 280),
	}, {
		UI.corner(12),
		UI.stroke(Theme.PanelLight, 1, 0.3),
	})

	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = case.name,
		Font = Theme.Font,
		TextSize = 18,
		TextColor3 = Theme.Text,
		Position = UDim2.new(0, 12, 0, 12),
		Size = UDim2.new(1, -24, 0, 24),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local artFrame = UI.new("Frame", {
		BackgroundColor3 = Theme.AccentDark,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 12, 0, 44),
		Size = UDim2.new(1, -24, 0, 160),
		Parent = card,
	}, {
		UI.corner(8),
		UI.gradient(Color3.fromRGB(80, 50, 0), Theme.Accent, 90),
	})

	if case.icon and case.icon ~= "rbxassetid://0" then
		UI.new("ImageLabel", {
			BackgroundTransparency = 1,
			Image = case.icon,
			ScaleType = Enum.ScaleType.Fit,
			Size = UDim2.fromScale(1, 1),
			Parent = artFrame,
		})
	else
		UI.new("TextLabel", {
			BackgroundTransparency = 1,
			Text = "CASE",
			Font = Theme.Font,
			TextSize = 32,
			TextColor3 = Theme.Background,
			Size = UDim2.fromScale(1, 1),
			Parent = artFrame,
		})
	end

	local priceLabel = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "$ " .. Util.formatCredits(case.price),
		Font = Theme.Font,
		TextSize = 16,
		TextColor3 = Theme.Accent,
		Position = UDim2.new(0, 12, 1, -64),
		Size = UDim2.new(1, -24, 0, 20),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local button = UI.new("TextButton", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Text = "Open",
		Font = Theme.Font,
		TextSize = 16,
		TextColor3 = Theme.Background,
		Position = UDim2.new(0, 12, 1, -40),
		Size = UDim2.new(1, -24, 0, 32),
		AutoButtonColor = true,
		Parent = card,
	}, { UI.corner(6) })

	button.MouseButton1Click:Connect(function()
		if State.getCredits() < case.price then
			priceLabel.Text = "Not enough credits"
			priceLabel.TextColor3 = Theme.Danger
			task.delay(1.2, function()
				priceLabel.Text = "$ " .. Util.formatCredits(case.price)
				priceLabel.TextColor3 = Theme.Accent
			end)
			return
		end
		button.Active = false
		button.AutoButtonColor = false
		onBuy(case, function()
			button.Active = true
			button.AutoButtonColor = true
		end)
	end)

	return card
end

function LobbyUI.create(parent, callbacks)
	local screen = UI.new("ScreenGui", {
		Name = "Lobby",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		Parent = parent,
	})

	local topBar = UI.new("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 56),
		Parent = screen,
	})

	UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "GOONER CASES",
		Font = Theme.Font,
		TextSize = 22,
		TextColor3 = Theme.Accent,
		Position = UDim2.new(0, 24, 0, 0),
		Size = UDim2.new(0, 240, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = topBar,
	})

	local creditsLabel = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "$ 0",
		Font = Theme.Font,
		TextSize = 18,
		TextColor3 = Theme.Text,
		Position = UDim2.new(1, -300, 0, 0),
		Size = UDim2.new(0, 160, 1, 0),
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = topBar,
	})

	State.onCredits(function(value)
		creditsLabel.Text = "$ " .. Util.formatCredits(value)
	end)

	local inventoryBtn = UI.new("TextButton", {
		BackgroundColor3 = Theme.PanelLight,
		BorderSizePixel = 0,
		Text = "Inventory",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Text,
		Position = UDim2.new(1, -128, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(112, 32),
		Parent = topBar,
	}, { UI.corner(6) })

	inventoryBtn.MouseButton1Click:Connect(function()
		if callbacks.onInventory then callbacks.onInventory() end
	end)

	local dailyBtn = UI.new("TextButton", {
		BackgroundColor3 = Theme.Success,
		BorderSizePixel = 0,
		Text = "Daily",
		Font = Theme.Font,
		TextSize = 14,
		TextColor3 = Theme.Background,
		Position = UDim2.new(1, -248, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.fromOffset(96, 32),
		Parent = topBar,
	}, { UI.corner(6) })

	dailyBtn.MouseButton1Click:Connect(function()
		local result = Remotes.get("ClaimDaily"):InvokeServer()
		if not result.ok and result.wait then
			local hours = math.ceil(result.wait / 3600)
			dailyBtn.Text = hours .. "h"
			task.delay(2, function() dailyBtn.Text = "Daily" end)
		elseif result.ok then
			dailyBtn.Text = "+ " .. result.credits
			task.delay(2, function() dailyBtn.Text = "Daily" end)
		end
	end)

	-- Scrollable list of cases.
	local list = UI.new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 56),
		Size = UDim2.new(1, 0, 1, -56),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = Theme.Accent,
		Parent = screen,
	})

	UI.new("UIPadding", {
		PaddingTop = UDim.new(0, 32),
		PaddingLeft = UDim.new(0, 32),
		PaddingRight = UDim.new(0, 32),
		PaddingBottom = UDim.new(0, 32),
		Parent = list,
	})

	UI.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(220, 280),
		CellPadding = UDim2.fromOffset(20, 20),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = list,
	})

	for i, case in ipairs(Cases.all()) do
		local card = makeCaseCard(case, function(c, done)
			if callbacks.onOpen then
				callbacks.onOpen(c, done)
			else
				done()
			end
		end)
		card.LayoutOrder = i
		card.Parent = list
	end

	return screen
end

return LobbyUI
