--!strict
--[[
    InventoryController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
    Client UI controller for ASCEND Spirit Pouch & Character Hub.
    Engineered with centered 3D standing character viewport doll and real-time dynamic weapon equipment sync.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local InventoryController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- BOLD, COMPACT FONT STYLE
local UI_FONT = Enum.Font.FredokaOne

-- DARK OBSIDIAN COLOR PALETTE
local COLOR_OBSIDIAN_MAIN   = Color3.fromRGB(12, 14, 20)  -- #0C0E14 Main Window
local COLOR_OBSIDIAN_PANEL  = Color3.fromRGB(18, 21, 32)  -- #121520 Sub-Panels
local COLOR_OBSIDIAN_CARD   = Color3.fromRGB(12, 14, 20)  -- #0C0E14 Cards & Slots
local COLOR_OBSIDIAN_BORDER = Color3.fromRGB(30, 35, 48)  -- #1E2330 Edge Borders
local COLOR_BORDER          = Color3.fromRGB(30, 35, 48)  -- Fallback Border

local COLOR_TEXT_MAIN       = Color3.fromRGB(241, 245, 249) -- #F1F5F9 Off-White
local COLOR_TEXT_SUB        = Color3.fromRGB(148, 163, 184) -- #94A3B8 Muted Grey
local COLOR_AZURE           = Color3.fromRGB(56, 189, 248)  -- #38BDF8 Cyan
local COLOR_HP_GREEN        = Color3.fromRGB(34, 197, 94)   -- #22C55E Green
local COLOR_ACTION_GOLD     = Color3.fromRGB(234, 179, 8)   -- #EAB308 Gold
local COLOR_BUTTON_DARK     = Color3.fromRGB(58, 69, 92)    -- #3A455C

local RARITY_COLORS = {
	Immortal  = Color3.fromRGB(239, 68, 68),   -- #EF4444 Red
	Legendary = Color3.fromRGB(245, 158, 11),  -- #F59E0B Gold
	Epic      = Color3.fromRGB(168, 85, 247),  -- #A855F7 Purple
	Rare      = Color3.fromRGB(59, 130, 246),  -- #3B82F6 Blue
	Uncommon  = Color3.fromRGB(16, 185, 129),  -- #10B981 Green
	Common    = Color3.fromRGB(100, 116, 139), -- #64748B Gray
}

local spiritPouchGui: ScreenGui
local overlayBackdrop: Frame
local mainModal: Frame
local searchBox: TextBox
local capacityLabel: TextLabel
local itemGrid: ScrollingFrame
local sortDropdownBtn: TextButton

-- Left Panel Vitals Container & Viewport
local characterViewport: ViewportFrame
local statsCardContainer: Frame
local realmTitleLabel: TextLabel
local hpBarFill: Frame
local hpBarText: TextLabel
local qiBarFill: Frame
local qiBarText: TextLabel

-- Right Panel Inspection Elements
local itemCardContainer: Frame
local tooltipTitle: TextLabel
local tooltipRarityBadge: TextLabel
local tooltipIconBox: Frame
local tooltipIcon: ImageLabel
local tooltipStatsBox: Frame
local tooltipStats: TextLabel
local tooltipDescBox: Frame
local tooltipDesc: TextLabel
local actionPrimaryBtn: TextButton
local actionDropBtn: TextButton

local gearSlots: { [string]: Frame } = {}
local slotButtons: { [number]: Frame } = {}
local currentInventory: { [number]: any } = {}
local selectedSlotIndex: number? = 1

local activeCategoryFilter: string = "ALL"
local currentSearchQuery: string = ""
local currentSortMode: string = "Rarity"

local updateInventoryRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent

function InventoryController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	InventoryController.BuildUI()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventory = inventoryData
		InventoryController.RefreshGrid()
		InventoryController.UpdateVitalStats()
		InventoryController.Update3DDoll() -- Dynamically refresh character doll on inventory change
		InventoryController.InspectSlot(selectedSlotIndex or 1)
	end)

	-- Hotkey 'K' Toggle
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.K then
			overlayBackdrop.Visible = not overlayBackdrop.Visible
			if overlayBackdrop.Visible then
				InventoryController.RefreshGrid()
				InventoryController.UpdateVitalStats()
				InventoryController.Update3DDoll()
				InventoryController.InspectSlot(selectedSlotIndex or 1)
			end
		end
	end)

	print("[ASCEND] InventoryController Centered 3D Doll & Dynamic Gear Sync Engine Initialized.")
end

function InventoryController.BuildUI()
	local oldGui = playerGui:FindFirstChild("SpiritPouchInventoryGui")
	if oldGui then oldGui:Destroy() end

	spiritPouchGui = Instance.new("ScreenGui")
	spiritPouchGui.Name = "SpiritPouchInventoryGui"
	spiritPouchGui.ResetOnSpawn = false
	spiritPouchGui.DisplayOrder = 25
	spiritPouchGui.Enabled = true
	spiritPouchGui.Parent = playerGui

	-- Transparent Backdrop
	overlayBackdrop = Instance.new("Frame")
	overlayBackdrop.Name = "OverlayBackdrop"
	overlayBackdrop.Size = UDim2.new(1, 0, 1, 0)
	overlayBackdrop.BackgroundTransparency = 1
	overlayBackdrop.BorderSizePixel = 0
	overlayBackdrop.Visible = false
	overlayBackdrop.Parent = spiritPouchGui

	-- Main Modal Frame
	mainModal = Instance.new("Frame")
	mainModal.Name = "MainModal"
	mainModal.Size = UDim2.new(0, 1300, 0, 700)
	mainModal.Position = UDim2.new(0.5, -650, 0.5, -350)
	mainModal.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
	mainModal.BackgroundTransparency = 0
	mainModal.BorderSizePixel = 0
	mainModal.Parent = overlayBackdrop

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = COLOR_OBSIDIAN_BORDER
	mStroke.Thickness = 1.5
	mStroke.Parent = mainModal

	-- Header Title
	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, 0, 0, 56)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SPIRIT POUCH"
	headerTitle.TextColor3 = COLOR_TEXT_MAIN
	headerTitle.Font = UI_FONT
	headerTitle.TextSize = 42
	headerTitle.Parent = mainModal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 38, 0, 38)
	closeBtn.Position = UDim2.new(1, -48, 0, 9)
	closeBtn.BackgroundColor3 = RARITY_COLORS.Immortal
	closeBtn.Text = "X"
	closeBtn.TextColor3 = COLOR_TEXT_MAIN
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 22
	closeBtn.Parent = mainModal

	closeBtn.MouseButton1Click:Connect(function()
		overlayBackdrop.Visible = false
	end)

	-- 1. LEFT SIDEBAR (120px Width)
	local verticalTabBar = Instance.new("Frame")
	verticalTabBar.Name = "VerticalTabBar"
	verticalTabBar.Size = UDim2.new(0, 120, 1, -70)
	verticalTabBar.Position = UDim2.new(0, 10, 0, 58)
	verticalTabBar.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	verticalTabBar.BorderSizePixel = 0
	verticalTabBar.Parent = mainModal

	local vtStroke = Instance.new("UIStroke")
	vtStroke.Color = COLOR_OBSIDIAN_BORDER
	vtStroke.Thickness = 1.5
	vtStroke.Parent = verticalTabBar

	local vtLayout = Instance.new("UIListLayout")
	vtLayout.FillDirection = Enum.FillDirection.Vertical
	vtLayout.Padding = UDim.new(0, 8)
	vtLayout.Parent = verticalTabBar

	local iconTabs = {
		{ Id = "ALL", Label = "ALL" },
		{ Id = "CONSUMABLE", Label = "CONSUMABLES" },
		{ Id = "HERB", Label = "INGREDIENTS" },
		{ Id = "WEAPON", Label = "EQUIPMENT" },
		{ Id = "CURRENCY", Label = "CURRENCIES" },
	}

	for idx, tabData in ipairs(iconTabs) do
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. tabData.Id
		btn.Size = UDim2.new(1, -12, 0, 52)
		btn.Position = UDim2.new(0, 6, 0, 0)
		btn.BackgroundColor3 = if idx == 1 then COLOR_OBSIDIAN_BORDER else COLOR_OBSIDIAN_MAIN
		btn.Text = tabData.Label
		btn.TextColor3 = if idx == 1 then COLOR_TEXT_MAIN else COLOR_TEXT_SUB
		btn.Font = UI_FONT
		btn.TextSize = 16
		btn.Parent = verticalTabBar

		local activeBar = Instance.new("Frame")
		activeBar.Name = "ActiveBar"
		activeBar.Size = UDim2.new(0, 4, 1, 0)
		activeBar.Position = UDim2.new(0, 0, 0, 0)
		activeBar.BackgroundColor3 = COLOR_AZURE
		activeBar.BorderSizePixel = 0
		activeBar.Visible = (idx == 1)
		activeBar.Parent = btn

		btn.MouseEnter:Connect(function()
			if activeCategoryFilter ~= tabData.Id then
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_OBSIDIAN_BORDER }):Play()
			end
		end)
		btn.MouseLeave:Connect(function()
			if activeCategoryFilter ~= tabData.Id then
				TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_OBSIDIAN_MAIN }):Play()
			end
		end)

		btn.MouseButton1Click:Connect(function()
			activeCategoryFilter = tabData.Id
			for _, child in ipairs(verticalTabBar:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
					child.TextColor3 = COLOR_TEXT_SUB
					local bar = child:FindFirstChild("ActiveBar") :: Frame?
					if bar then bar.Visible = false end
				end
			end
			btn.BackgroundColor3 = COLOR_OBSIDIAN_BORDER
			btn.TextColor3 = COLOR_TEXT_MAIN
			activeBar.Visible = true
			InventoryController.RefreshGrid()
		end)
	end

	-- 2. LEFT PANEL: Character Hub & Equipment (380px Width)
	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel_CharacterHub"
	leftPanel.Size = UDim2.new(0, 380, 1, -70)
	leftPanel.Position = UDim2.new(0, 140, 0, 58)
	leftPanel.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = mainModal

	local lpStroke = Instance.new("UIStroke")
	lpStroke.Color = COLOR_OBSIDIAN_BORDER
	lpStroke.Thickness = 1.5
	lpStroke.Parent = leftPanel

	local pouchTitle = Instance.new("TextLabel")
	pouchTitle.Size = UDim2.new(1, 0, 0, 36)
	pouchTitle.Position = UDim2.new(0, 0, 0, 8)
	pouchTitle.BackgroundTransparency = 1
	pouchTitle.Text = "CULTIVATOR"
	pouchTitle.TextColor3 = COLOR_TEXT_MAIN
	pouchTitle.Font = UI_FONT
	pouchTitle.TextSize = 28
	pouchTitle.Parent = leftPanel

	-- Perfectly Positioned ViewportFrame for 3D Player Character
	characterViewport = Instance.new("ViewportFrame")
	characterViewport.Name = "CharacterViewport"
	characterViewport.Size = UDim2.new(0, 230, 0, 310)
	characterViewport.Position = UDim2.new(0, 15, 0, 48)
	characterViewport.BackgroundTransparency = 1
	characterViewport.Parent = leftPanel

	-- 4 Equipment Slots Stacked Vertically
	local eqContainer = Instance.new("Frame")
	eqContainer.Size = UDim2.new(0, 90, 0, 330)
	eqContainer.Position = UDim2.new(1, -105, 0, 48)
	eqContainer.BackgroundTransparency = 1
	eqContainer.Parent = leftPanel

	local eqLayout = Instance.new("UIListLayout")
	eqLayout.FillDirection = Enum.FillDirection.Vertical
	eqLayout.Padding = UDim.new(0, 14)
	eqLayout.Parent = eqContainer

	local slotNames = { "HEAD", "ROBE", "WEAPON", "ARTIFACT" }
	for _, slotName in ipairs(slotNames) do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. slotName
		slot.Size = UDim2.new(0, 90, 0, 72)
		slot.BackgroundColor3 = COLOR_OBSIDIAN_CARD
		slot.BorderSizePixel = 0
		slot.Parent = eqContainer

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = COLOR_OBSIDIAN_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = slotName
		label.TextColor3 = COLOR_TEXT_MAIN
		label.Font = UI_FONT
		label.TextSize = 16
		label.Parent = slot

		gearSlots[slotName] = slot
	end

	-- Dedicated Inset Stats Container Card
	statsCardContainer = Instance.new("Frame")
	statsCardContainer.Name = "StatsContainerCard"
	statsCardContainer.Size = UDim2.new(1, -24, 0, 210)
	statsCardContainer.Position = UDim2.new(0, 12, 1, -222)
	statsCardContainer.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	statsCardContainer.BorderSizePixel = 0
	statsCardContainer.Parent = leftPanel

	local scStroke = Instance.new("UIStroke")
	scStroke.Color = COLOR_OBSIDIAN_BORDER
	scStroke.Thickness = 1.5
	scStroke.Parent = statsCardContainer

	-- HP Gauge Bar
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -65, 0, 28)
	hpBg.Position = UDim2.new(0, 50, 0, 18)
	hpBg.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
	hpBg.BorderSizePixel = 0
	hpBg.Parent = statsCardContainer

	hpBarFill = Instance.new("Frame")
	hpBarFill.Size = UDim2.new(1, 0, 1, 0)
	hpBarFill.BackgroundColor3 = COLOR_HP_GREEN
	hpBarFill.BorderSizePixel = 0
	hpBarFill.Parent = hpBg

	hpBarText = Instance.new("TextLabel")
	hpBarText.Size = UDim2.new(1, 0, 1, 0)
	hpBarText.BackgroundTransparency = 1
	hpBarText.Text = "7200 / 7200"
	hpBarText.TextColor3 = COLOR_TEXT_MAIN
	hpBarText.Font = UI_FONT
	hpBarText.TextSize = 17
	hpBarText.ZIndex = 5
	hpBarText.Parent = hpBg

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 40, 0, 28)
	hpLabel.Position = UDim2.new(0, -45, 0, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP"
	hpLabel.TextColor3 = COLOR_TEXT_SUB
	hpLabel.Font = UI_FONT
	hpLabel.TextSize = 17
	hpLabel.TextXAlignment = Enum.TextXAlignment.Right
	hpLabel.Parent = hpBg

	-- Qi Gauge Bar
	local qiBg = Instance.new("Frame")
	qiBg.Size = UDim2.new(1, -65, 0, 28)
	qiBg.Position = UDim2.new(0, 50, 0, 58)
	qiBg.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
	qiBg.BorderSizePixel = 0
	qiBg.Parent = statsCardContainer

	qiBarFill = Instance.new("Frame")
	qiBarFill.Size = UDim2.new(1, 0, 1, 0)
	qiBarFill.BackgroundColor3 = COLOR_AZURE
	qiBarFill.BorderSizePixel = 0
	qiBarFill.Parent = qiBg

	qiBarText = Instance.new("TextLabel")
	qiBarText.Size = UDim2.new(1, 0, 1, 0)
	qiBarText.BackgroundTransparency = 1
	qiBarText.Text = "4500 / 4500"
	qiBarText.TextColor3 = COLOR_TEXT_MAIN
	qiBarText.Font = UI_FONT
	qiBarText.TextSize = 17
	qiBarText.ZIndex = 5
	qiBarText.Parent = qiBg

	local qiLabel = Instance.new("TextLabel")
	qiLabel.Size = UDim2.new(0, 40, 0, 28)
	qiLabel.Position = UDim2.new(0, -45, 0, 0)
	qiLabel.BackgroundTransparency = 1
	qiLabel.Text = "QI"
	qiLabel.TextColor3 = COLOR_TEXT_SUB
	qiLabel.Font = UI_FONT
	qiLabel.TextSize = 17
	qiLabel.TextXAlignment = Enum.TextXAlignment.Right
	qiLabel.Parent = qiBg

	-- Realm Title Label
	realmTitleLabel = Instance.new("TextLabel")
	realmTitleLabel.Size = UDim2.new(1, -24, 0, 28)
	realmTitleLabel.Position = UDim2.new(0, 12, 0, 108)
	realmTitleLabel.BackgroundTransparency = 1
	realmTitleLabel.Text = "Foundation Establishment — Tier 2"
	realmTitleLabel.TextColor3 = COLOR_ACTION_GOLD
	realmTitleLabel.Font = UI_FONT
	realmTitleLabel.TextSize = 20
	realmTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	realmTitleLabel.Parent = statsCardContainer

	-- Capacity Indicator
	capacityLabel = Instance.new("TextLabel")
	capacityLabel.Size = UDim2.new(1, -24, 0, 24)
	capacityLabel.Position = UDim2.new(0, 12, 0, 148)
	capacityLabel.BackgroundTransparency = 1
	capacityLabel.Text = "STORAGE  14 / 30 SLOTS"
	capacityLabel.TextColor3 = COLOR_TEXT_SUB
	capacityLabel.Font = UI_FONT
	capacityLabel.TextSize = 17
	capacityLabel.TextXAlignment = Enum.TextXAlignment.Left
	capacityLabel.Parent = statsCardContainer

	-- 3. MIDDLE PANEL: Item Grid Panel (460px Width)
	local midPanel = Instance.new("Frame")
	midPanel.Name = "MidPanel_InventoryGrid"
	midPanel.Size = UDim2.new(0, 460, 1, -70)
	midPanel.Position = UDim2.new(0, 530, 0, 58)
	midPanel.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	midPanel.BorderSizePixel = 0
	midPanel.Parent = mainModal

	local mpStroke = Instance.new("UIStroke")
	mpStroke.Color = COLOR_OBSIDIAN_BORDER
	mpStroke.Thickness = 1.5
	mpStroke.Parent = midPanel

	-- Search Bar
	local searchBg = Instance.new("Frame")
	searchBg.Size = UDim2.new(0, 260, 0, 40)
	searchBg.Position = UDim2.new(0, 12, 0, 12)
	searchBg.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	searchBg.BorderSizePixel = 0
	searchBg.Parent = midPanel

	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = COLOR_OBSIDIAN_BORDER
	sbStroke.Thickness = 1.5
	sbStroke.Parent = searchBg

	searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -12, 1, 0)
	searchBox.Position = UDim2.new(0, 6, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "Search items..."
	searchBox.Text = ""
	searchBox.TextColor3 = COLOR_TEXT_MAIN
	searchBox.PlaceholderColor3 = COLOR_TEXT_SUB
	searchBox.Font = UI_FONT
	searchBox.TextSize = 17
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	searchBox.Focused:Connect(function()
		TweenService:Create(sbStroke, TweenInfo.new(0.15), { Color = COLOR_AZURE }):Play()
	end)
	searchBox.FocusLost:Connect(function()
		TweenService:Create(sbStroke, TweenInfo.new(0.15), { Color = COLOR_OBSIDIAN_BORDER }):Play()
	end)

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		currentSearchQuery = searchBox.Text:lower()
		InventoryController.RefreshGrid()
	end)

	-- Sort Dropdown
	sortDropdownBtn = Instance.new("TextButton")
	sortDropdownBtn.Size = UDim2.new(0, 160, 0, 40)
	sortDropdownBtn.Position = UDim2.new(1, -172, 0, 12)
	sortDropdownBtn.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	sortDropdownBtn.Text = "Sort by Rarity"
	sortDropdownBtn.TextColor3 = COLOR_TEXT_MAIN
	sortDropdownBtn.Font = UI_FONT
	sortDropdownBtn.TextSize = 17
	sortDropdownBtn.Parent = midPanel

	local sdStroke = Instance.new("UIStroke")
	sdStroke.Color = COLOR_OBSIDIAN_BORDER
	sdStroke.Thickness = 1.5
	sdStroke.Parent = sortDropdownBtn

	sortDropdownBtn.MouseButton1Click:Connect(function()
		if currentSortMode == "Rarity" then
			currentSortMode = "Quantity"
			sortDropdownBtn.Text = "Sort by Quantity"
		else
			currentSortMode = "Rarity"
			sortDropdownBtn.Text = "Sort by Rarity"
		end
		InventoryController.RefreshGrid()
	end)

	-- 5-Column Grid Layout with Non-Stretching Fitted Slots (76px x 76px)
	itemGrid = Instance.new("ScrollingFrame")
	itemGrid.Name = "ItemGrid"
	itemGrid.Size = UDim2.new(1, -20, 1, -68)
	itemGrid.Position = UDim2.new(0, 10, 0, 58)
	itemGrid.BackgroundTransparency = 1
	itemGrid.BorderSizePixel = 0
	itemGrid.ScrollBarThickness = 4
	itemGrid.ScrollBarImageColor3 = COLOR_AZURE
	itemGrid.Parent = midPanel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 76, 0, 76)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemGrid

	-- 4. RIGHT PANEL: Independent Item Card Inspection Container (300px Width)
	itemCardContainer = Instance.new("Frame")
	itemCardContainer.Name = "RightItemCardContainer"
	itemCardContainer.Size = UDim2.new(0, 300, 1, -70)
	itemCardContainer.Position = UDim2.new(0, 990, 0, 58)
	itemCardContainer.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	itemCardContainer.BorderSizePixel = 0
	itemCardContainer.Parent = mainModal

	local icStroke = Instance.new("UIStroke")
	icStroke.Color = COLOR_OBSIDIAN_BORDER
	icStroke.Thickness = 1.5
	icStroke.Parent = itemCardContainer

	tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Size = UDim2.new(1, -20, 0, 34)
	tooltipTitle.Position = UDim2.new(0, 10, 0, 12)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = UI_FONT
	tooltipTitle.TextSize = 28
	tooltipTitle.TextColor3 = COLOR_TEXT_MAIN
	tooltipTitle.TextXAlignment = Enum.TextXAlignment.Center
	tooltipTitle.Parent = itemCardContainer

	tooltipRarityBadge = Instance.new("TextLabel")
	tooltipRarityBadge.Size = UDim2.new(1, -20, 0, 22)
	tooltipRarityBadge.Position = UDim2.new(0, 10, 0, 48)
	tooltipRarityBadge.BackgroundTransparency = 1
	tooltipRarityBadge.Font = UI_FONT
	tooltipRarityBadge.TextSize = 17
	tooltipRarityBadge.TextColor3 = RARITY_COLORS.Immortal
	tooltipRarityBadge.Text = "IMMORTAL CONSUMABLE"
	tooltipRarityBadge.TextXAlignment = Enum.TextXAlignment.Center
	tooltipRarityBadge.Parent = itemCardContainer

	-- Icon Preview Box
	tooltipIconBox = Instance.new("Frame")
	tooltipIconBox.Size = UDim2.new(0, 110, 0, 110)
	tooltipIconBox.Position = UDim2.new(0.5, -55, 0, 78)
	tooltipIconBox.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	tooltipIconBox.BorderSizePixel = 0
	tooltipIconBox.Parent = itemCardContainer

	local ibStroke = Instance.new("UIStroke")
	ibStroke.Color = COLOR_OBSIDIAN_BORDER
	ibStroke.Thickness = 1.5
	ibStroke.Parent = tooltipIconBox

	tooltipIcon = Instance.new("ImageLabel")
	tooltipIcon.Size = UDim2.new(1, -12, 1, -12)
	tooltipIcon.Position = UDim2.new(0, 6, 0, 6)
	tooltipIcon.BackgroundTransparency = 1
	tooltipIcon.ScaleType = Enum.ScaleType.Fit
	tooltipIcon.Parent = tooltipIconBox

	-- Stat Box
	tooltipStatsBox = Instance.new("Frame")
	tooltipStatsBox.Size = UDim2.new(1, -24, 0, 70)
	tooltipStatsBox.Position = UDim2.new(0, 12, 0, 200)
	tooltipStatsBox.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	tooltipStatsBox.BorderSizePixel = 0
	tooltipStatsBox.Parent = itemCardContainer

	local sbBoxStroke = Instance.new("UIStroke")
	sbBoxStroke.Color = COLOR_OBSIDIAN_BORDER
	sbBoxStroke.Thickness = 1
	sbBoxStroke.Parent = tooltipStatsBox

	tooltipStats = Instance.new("TextLabel")
	tooltipStats.Size = UDim2.new(1, -16, 1, -8)
	tooltipStats.Position = UDim2.new(0, 8, 0, 4)
	tooltipStats.BackgroundTransparency = 1
	tooltipStats.Font = UI_FONT
	tooltipStats.TextSize = 18
	tooltipStats.TextColor3 = COLOR_HP_GREEN
	tooltipStats.TextWrapped = true
	tooltipStats.TextXAlignment = Enum.TextXAlignment.Left
	tooltipStats.Parent = tooltipStatsBox

	-- Lore Box
	tooltipDescBox = Instance.new("Frame")
	tooltipDescBox.Size = UDim2.new(1, -24, 0, 120)
	tooltipDescBox.Position = UDim2.new(0, 12, 0, 282)
	tooltipDescBox.BackgroundColor3 = COLOR_OBSIDIAN_CARD
	tooltipDescBox.BorderSizePixel = 0
	tooltipDescBox.Parent = itemCardContainer

	local lbStroke = Instance.new("UIStroke")
	lbStroke.Color = COLOR_OBSIDIAN_BORDER
	lbStroke.Thickness = 1
	lbStroke.Parent = tooltipDescBox

	local lbPadding = Instance.new("UIPadding")
	lbPadding.PaddingTop = UDim.new(0, 6)
	lbPadding.PaddingBottom = UDim.new(0, 6)
	lbPadding.PaddingLeft = UDim.new(0, 8)
	lbPadding.PaddingRight = UDim.new(0, 8)
	lbPadding.Parent = tooltipDescBox

	tooltipDesc = Instance.new("TextLabel")
	tooltipDesc.Size = UDim2.new(1, 0, 1, 0)
	tooltipDesc.BackgroundTransparency = 1
	tooltipDesc.Font = UI_FONT
	tooltipDesc.TextSize = 16
	tooltipDesc.TextColor3 = COLOR_TEXT_SUB
	tooltipDesc.TextWrapped = true
	tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
	tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
	tooltipDesc.Parent = tooltipDescBox

	-- Action Buttons
	actionPrimaryBtn = Instance.new("TextButton")
	actionPrimaryBtn.Size = UDim2.new(1, -24, 0, 44)
	actionPrimaryBtn.Position = UDim2.new(0, 12, 1, -104)
	actionPrimaryBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	actionPrimaryBtn.Text = "EQUIP"
	actionPrimaryBtn.TextColor3 = COLOR_OBSIDIAN_CARD
	actionPrimaryBtn.Font = UI_FONT
	actionPrimaryBtn.TextSize = 22
	actionPrimaryBtn.Parent = itemCardContainer

	actionPrimaryBtn.MouseEnter:Connect(function()
		TweenService:Create(actionPrimaryBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(250, 204, 21) }):Play()
	end)
	actionPrimaryBtn.MouseLeave:Connect(function()
		TweenService:Create(actionPrimaryBtn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_ACTION_GOLD }):Play()
	end)

	actionDropBtn = Instance.new("TextButton")
	actionDropBtn.Size = UDim2.new(1, -24, 0, 44)
	actionDropBtn.Position = UDim2.new(0, 12, 1, -52)
	actionDropBtn.BackgroundColor3 = COLOR_BUTTON_DARK
	actionDropBtn.Text = "DROP"
	actionDropBtn.TextColor3 = COLOR_TEXT_MAIN
	actionDropBtn.Font = UI_FONT
	actionDropBtn.TextSize = 22
	actionDropBtn.Parent = itemCardContainer

	local drStroke = Instance.new("UIStroke")
	drStroke.Color = COLOR_OBSIDIAN_BORDER
	drStroke.Thickness = 1
	drStroke.Parent = actionDropBtn

	actionDropBtn.MouseEnter:Connect(function()
		TweenService:Create(actionDropBtn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(71, 85, 105) }):Play()
	end)
	actionDropBtn.MouseLeave:Connect(function()
		TweenService:Create(actionDropBtn, TweenInfo.new(0.15), { BackgroundColor3 = COLOR_BUTTON_DARK }):Play()
	end)

	actionPrimaryBtn.MouseButton1Click:Connect(function()
		if selectedSlotIndex then
			InventoryController.UseSlot(selectedSlotIndex)
		end
	end)

	InventoryController.SetupGridSlots()
end

function InventoryController.Update3DDoll()
	local char = player.Character
	if not char or not characterViewport then return end

	characterViewport:ClearAllChildren()

	local camera = Instance.new("Camera")
	camera.CameraType = Enum.CameraType.Scriptable
	characterViewport.CurrentCamera = camera
	camera.Parent = characterViewport

	local worldModel = Instance.new("WorldModel")
	worldModel.Parent = characterViewport

	char.Archivable = true
	local charClone = char:Clone()
	char.Archivable = false

	-- Strip heavy scripts/sounds from clone
	for _, child in ipairs(charClone:GetDescendants()) do
		if child:IsA("LuaSourceContainer") or child:IsA("Sound") then
			child:Destroy()
		end
	end

	charClone.Parent = worldModel

	local hrp = charClone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(0, 0, 0)
		-- Camera positioned directly in front facing character standing centered
		camera.CFrame = CFrame.new(Vector3.new(0, 0.2, -6.2), Vector3.new(0, 0.1, 0))
	end
end

function InventoryController.SetupGridSlots()
	for i = 1, 30 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.LayoutOrder = i
		slot.BackgroundColor3 = COLOR_OBSIDIAN_CARD
		slot.BorderSizePixel = 0
		slot.Parent = itemGrid

		local aspect = Instance.new("UIAspectRatioConstraint")
		aspect.AspectRatio = 1.0
		aspect.AspectType = Enum.AspectType.FitWithinMaxSize
		aspect.Parent = slot

		local stroke = Instance.new("UIStroke")
		stroke.Name = "RarityBorder"
		stroke.Thickness = 1.5
		stroke.Color = COLOR_OBSIDIAN_BORDER
		stroke.Parent = slot

		local rarityHeader = Instance.new("TextLabel")
		rarityHeader.Name = "RarityHeader"
		rarityHeader.Size = UDim2.new(1, 0, 0, 18)
		rarityHeader.Position = UDim2.new(0, 0, 0, 0)
		rarityHeader.BackgroundColor3 = COLOR_OBSIDIAN_BORDER
		rarityHeader.Text = ""
		rarityHeader.TextColor3 = COLOR_TEXT_MAIN
		rarityHeader.Font = UI_FONT
		rarityHeader.TextSize = 12
		rarityHeader.Visible = false
		rarityHeader.Parent = slot

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -12, 1, -22)
		icon.Position = UDim2.new(0, 6, 0, 18)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Visible = false
		icon.Parent = slot

		local quantity = Instance.new("TextLabel")
		quantity.Name = "Quantity"
		quantity.Size = UDim2.new(1, -4, 0, 16)
		quantity.Position = UDim2.new(0, 0, 1, -16)
		quantity.BackgroundTransparency = 1
		quantity.TextColor3 = COLOR_TEXT_MAIN
		quantity.TextStrokeTransparency = 0
		quantity.Font = UI_FONT
		quantity.TextSize = 14
		quantity.TextXAlignment = Enum.TextXAlignment.Right
		quantity.Text = ""
		quantity.Parent = slot

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = slot

		btn.MouseEnter:Connect(function()
			if selectedSlotIndex ~= i then
				stroke.Thickness = 2
				stroke.Color = COLOR_AZURE
			end
		end)
		btn.MouseLeave:Connect(function()
			if selectedSlotIndex ~= i then
				local slotData = currentInventory[i]
				local itemDef = if slotData then ItemConfig[slotData.ItemId] else nil
				stroke.Thickness = 1.5
				stroke.Color = if itemDef then (RARITY_COLORS[itemDef.Rarity] or COLOR_OBSIDIAN_BORDER) else COLOR_OBSIDIAN_BORDER
			end
		end)

		btn.MouseButton1Click:Connect(function()
			InventoryController.InspectSlot(i)
		end)

		slotButtons[i] = slot
	end
end

function InventoryController.RefreshGrid()
	local usedCount = 0

	for i = 1, 30 do
		local slotFrame = slotButtons[i]
		if not slotFrame then continue end

		local icon = slotFrame:FindFirstChild("Icon") :: ImageLabel?
		local quantity = slotFrame:FindFirstChild("Quantity") :: TextLabel?
		local rarityHeader = slotFrame:FindFirstChild("RarityHeader") :: TextLabel?
		local stroke = slotFrame:FindFirstChildOfClass("UIStroke")

		local slotData = currentInventory[i]
		local isVisible = true

		if slotData then
			usedCount += 1
			local itemDef = ItemConfig[slotData.ItemId]
			if itemDef then
				if activeCategoryFilter ~= "ALL" and itemDef.Category:upper() ~= activeCategoryFilter then
					isVisible = false
				end

				if currentSearchQuery ~= "" and not itemDef.Name:lower():find(currentSearchQuery, 1, true) then
					isVisible = false
				end

				if isVisible then
					local rarityColor = RARITY_COLORS[itemDef.Rarity] or COLOR_OBSIDIAN_CARD
					slotFrame.BackgroundColor3 = rarityColor

					if icon then
						icon.Image = itemDef.Icon
						icon.Visible = true
					end
					if quantity then
						quantity.Text = if slotData.Count > 1 then "x" .. slotData.Count else ""
					end
					if rarityHeader then
						rarityHeader.Text = itemDef.Rarity:upper()
						rarityHeader.BackgroundColor3 = rarityColor
						rarityHeader.Visible = true
					end
					if stroke then
						stroke.Color = rarityColor
						stroke.Thickness = if i == selectedSlotIndex then 2.5 else 1.5
					end
				end
			end
		else
			slotFrame.BackgroundColor3 = COLOR_OBSIDIAN_CARD
			isVisible = (activeCategoryFilter == "ALL" and currentSearchQuery == "")
		end

		slotFrame.Visible = isVisible
		if not slotData or not isVisible then
			if icon then icon.Visible = false end
			if quantity then quantity.Text = "" end
			if rarityHeader then rarityHeader.Visible = false end
			if stroke then stroke.Color = COLOR_OBSIDIAN_BORDER end
		end
	end

	if capacityLabel then
		capacityLabel.Text = string.format("STORAGE  %d / 30 SLOTS", usedCount)
	end
end

function InventoryController.InspectSlot(slotIdx: number)
	selectedSlotIndex = slotIdx
	InventoryController.RefreshGrid()

	local slotData = currentInventory[slotIdx]
	if not slotData then
		itemCardContainer.Visible = false
		return
	end

	local itemDef = ItemConfig[slotData.ItemId]
	if not itemDef then return end

	itemCardContainer.Visible = true

	tooltipTitle.Text = itemDef.Name
	tooltipRarityBadge.Text = string.format("%s %s", itemDef.Rarity:upper(), itemDef.Category:upper())
	tooltipRarityBadge.TextColor3 = RARITY_COLORS[itemDef.Rarity] or COLOR_TEXT_MAIN
	tooltipDesc.Text = itemDef.Description
	tooltipIcon.Image = itemDef.Icon
	tooltipIcon.Visible = true

	if itemDef.Category == "Consumable" then
		actionPrimaryBtn.Text = "USE"
		actionPrimaryBtn.BackgroundColor3 = COLOR_AZURE
	else
		actionPrimaryBtn.Text = "EQUIP"
		actionPrimaryBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	end

	local statText = ""
	if itemDef.HealAmount and itemDef.HealAmount > 0 then
		statText ..= string.format("HEALTH RESTORED: +%d\n", itemDef.HealAmount)
	end
	if itemDef.QiAmount and itemDef.QiAmount > 0 then
		statText ..= string.format("SPIRIT QI RESTORED: +%d\n", itemDef.QiAmount)
	end
	if itemDef.WeaponType then
		statText ..= string.format("ATTACK POWER: +350\nCRIT RATE: +15%%")
	end
	tooltipStats.Text = statText
end

function InventoryController.UpdateVitalStats()
	local char = player.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local hpRatio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)
		hpBarFill.Size = UDim2.new(hpRatio, 0, 1, 0)
		hpBarText.Text = string.format("%d / %d", math.floor(humanoid.Health), math.floor(humanoid.MaxHealth))
	end

	local currentQi = char:GetAttribute("Qi") or 0
	local maxQi = char:GetAttribute("MaxQi") or 100
	local qiRatio = math.clamp(currentQi / math.max(1, maxQi), 0, 1)
	qiBarFill.Size = UDim2.new(qiRatio, 0, 1, 0)
	qiBarText.Text = string.format("%d / %d", math.floor(currentQi), math.floor(maxQi))

	local realm = char:GetAttribute("Realm") or "Golden Core"
	realmTitleLabel.Text = string.format("Foundation Establishment — Tier 2")
end

function InventoryController.UseSlot(slotIdx: number)
	if currentInventory[slotIdx] then
		inventoryActionRemote:FireServer({
			Action = "UseItem",
			SlotIndex = slotIdx,
		})
	end
end

return InventoryController