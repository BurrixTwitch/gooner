-- The marquee feature: a horizontal spinning reel that lands on the item the
-- server rolled. The server is authoritative; the client just animates a
-- pre-seeded reel where the winning slot is at a known index.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cases = require(Shared.Cases)
local Items = require(Shared.Items)
local Rarity = require(Shared.Rarity)
local Config = require(Shared.Config)

local Theme = require(script.Parent.Theme)
local ItemTile = require(script.Parent.ItemTile)
local UI = require(script.Parent.Parent.UIBuilder)

local CaseOpenUI = {}

local TILE_WIDTH = 140
local TILE_GAP = 8

local function buildReelItems(case, winningItemId)
	-- Fill the reel with random items from the case, then slot the winning
	-- item at the winning index so the deceleration lands on it.
	local pool = case.items
	local items = {}
	local rng = Random.new()
	for i = 1, Config.REEL_ITEM_COUNT do
		items[i] = pool[rng:NextInteger(1, #pool)]
	end
	items[Config.WINNING_INDEX] = winningItemId
	return items
end

function CaseOpenUI.create(parent)
	local screen = UI.new("ScreenGui", {
		Name = "CaseOpenOverlay",
		IgnoreGuiInset = true,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 50,
		Enabled = false,
		Parent = parent,
	})

	local dimmer = UI.new("Frame", {
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
		Parent = screen,
	})

	local title = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Unlock Container",
		Font = Theme.Font,
		TextSize = 28,
		TextColor3 = Theme.Text,
		Position = UDim2.new(0.5, 0, 0, 60),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 600, 0, 40),
		ZIndex = 2,
		Parent = dimmer,
	})

	local subtitle = UI.new("TextLabel", {
		BackgroundTransparency = 1,
		Text = "Unlock",
		Font = Theme.FontRegular,
		TextSize = 18,
		TextColor3 = Theme.Accent,
		Position = UDim2.new(0.5, 0, 0, 100),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 600, 0, 22),
		ZIndex = 2,
		Parent = dimmer,
	})

	-- The reel itself. Width matches the viewport so the centre marker lines up
	-- visually wherever the player's screen is.
	local reelHeight = 180
	local reelFrame = UI.new("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.new(1, -80, 0, reelHeight),
		ClipsDescendants = true,
		ZIndex = 2,
		Parent = dimmer,
	}, {
		UI.corner(10),
		UI.stroke(Color3.fromRGB(0, 0, 0), 1, 0.4),
	})

	-- Strip that actually scrolls. We move it via tween to slide the tiles past
	-- the centre marker.
	local strip = UI.new("Frame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(0, 0, 1, -40),
		ZIndex = 3,
		Parent = reelFrame,
	})

	-- Centre marker (the yellow pillar in the CS reference image).
	local marker = UI.new("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0, 3, 1, 0),
		ZIndex = 4,
		Parent = reelFrame,
	})

	local arrowTop = UI.new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = "rbxasset://textures/ui/Controls/DropdownArrow.png",
		ImageColor3 = Theme.Accent,
		Position = UDim2.new(0.5, 0, 0, -2),
		AnchorPoint = Vector2.new(0.5, 0),
		Rotation = 180,
		Size = UDim2.fromOffset(24, 18),
		ZIndex = 5,
		Parent = reelFrame,
	})

	local closeButton = UI.new("TextButton", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Text = "Close",
		Font = Theme.Font,
		TextSize = 16,
		TextColor3 = Theme.Text,
		Position = UDim2.new(1, -32, 0, 32),
		AnchorPoint = Vector2.new(1, 0),
		Size = UDim2.fromOffset(96, 36),
		AutoButtonColor = true,
		ZIndex = 6,
		Parent = dimmer,
	}, { UI.corner(6) })
	closeButton.Visible = false

	local function clearStrip()
		for _, child in ipairs(strip:GetChildren()) do
			if child:IsA("GuiObject") then
				child:Destroy()
			end
		end
	end

	local function showResult(itemId)
		local item = Items.get(itemId)
		local rarity = item and Rarity.get(item.rarity)

		subtitle.TextColor3 = (rarity and rarity.color) or Theme.Accent
		subtitle.Text = item and (item.name .. "  ·  " .. (rarity and rarity.name or "")) or "Unknown"

		closeButton.Visible = true
	end

	local activeTween

	function CaseOpenUI.open(caseId, winningItemId, onComplete)
		local case = Cases.get(caseId)
		if not case then return end

		screen.Enabled = true
		subtitle.Text = ("Unlock %s"):format(case.name)
		subtitle.TextColor3 = Theme.Accent
		closeButton.Visible = false
		if activeTween then activeTween:Cancel() end

		clearStrip()

		local items = buildReelItems(case, winningItemId)
		strip.Size = UDim2.new(0, #items * (TILE_WIDTH + TILE_GAP), 1, -40)

		for i, itemId in ipairs(items) do
			local tile = ItemTile.create(itemId, { size = UDim2.fromOffset(TILE_WIDTH, 140) })
			tile.Position = UDim2.fromOffset((i - 1) * (TILE_WIDTH + TILE_GAP), 0)
			tile.Parent = strip
		end

		-- Compute the target x offset so the winning tile's centre lines up with
		-- the reel's centre marker. A tiny random jitter inside the tile width
		-- gives each spin a slightly different stopping pixel.
		local reelWidth = reelFrame.AbsoluteSize.X
		if reelWidth <= 0 then
			reelWidth = workspace.CurrentCamera.ViewportSize.X - 80
		end
		local jitter = (math.random() - 0.5) * (TILE_WIDTH * 0.6)
		local winningCentre = (Config.WINNING_INDEX - 1) * (TILE_WIDTH + TILE_GAP) + (TILE_WIDTH / 2)
		local targetX = (reelWidth / 2) - winningCentre + jitter

		strip.Position = UDim2.fromOffset(reelWidth, 20)

		local tweenInfo = TweenInfo.new(
			Config.SPIN_DURATION,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.Out
		)
		activeTween = TweenService:Create(strip, tweenInfo, {
			Position = UDim2.fromOffset(targetX, 20),
		})

		local clickSound = Instance.new("Sound")
		clickSound.SoundId = "rbxasset://sounds/electronicpingshort.caf"
		clickSound.Volume = 0.3
		clickSound.Parent = screen

		activeTween:Play()
		task.spawn(function()
			-- Lightweight tick sounds as tiles pass under the marker, slowing
			-- down as the strip decelerates.
			local elapsed = 0
			while elapsed < Config.SPIN_DURATION and activeTween.PlaybackState == Enum.PlaybackState.Playing do
				local progress = elapsed / Config.SPIN_DURATION
				local interval = 0.05 + progress * 0.35
				clickSound:Play()
				task.wait(interval)
				elapsed = elapsed + interval
			end
		end)

		activeTween.Completed:Connect(function()
			showResult(winningItemId)
			if onComplete then task.spawn(onComplete, winningItemId) end
		end)
	end

	closeButton.MouseButton1Click:Connect(function()
		screen.Enabled = false
	end)

	return CaseOpenUI
end

return CaseOpenUI
