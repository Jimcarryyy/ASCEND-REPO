--!strict
--[[
    InventoryController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
    Client UI controller for ASCEND Spirit Pouch.
    Unified Light-Mode Aesthetic with Item Name Labels & Auto-Inspection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local InventoryController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI_FONT = Enum.Font.FredokaOne

-- LIGHT-MODE FLAT 2D PALETTE
local COLOR_LIGHT_MAIN   = Color3.fromRGB(248, 250, 249) -- #F8FAF9
local COLOR_LIGHT_PANEL  = Color3.fromRGB(241, 245, 249) -- #F1F5F9
local COLOR_LIGHT_CARD   = Color3.fromRGB(255, 255, 255) -- #FFFFFF
local COLOR_LIGHT_BORDER = Color3.fromRGB(203, 213, 225) -- #CBD5E1

local COLOR_TEXT_MAIN    = Color3.fromRGB(15, 23, 42)    -- #0F172A
local COLOR_TEXT_SUB     = Color3.fromRGB(100, 116, 139)  -- #64748B
local COLOR_AZURE_BLUE   = Color3.fromRGB(59, 130, 246)   -- #3B82F6
local COLOR_HP_GREEN     = Color3.fromRGB(16, 185, 129)  -- #10B981
local COLOR_ACTION_GOLD  = Color3.fromRGB(217, 119, 6)   -- #D97706
local COLOR_DANGER_RED   = Color3.fromRGB(225, 29, 72)   -- #E11D48

local RARITY_COLORS: { [string]: Color3 } = {
	Mythic    = Color3.fromRGB(225, 29, 72),   -- Crimson Red
	Legendary = Color3.fromRGB(217, 119, 6),   -- Flame Gold
	Epic      = Color3.fromRGB(147, 51, 234),  -- Spiritual Purple
	Rare      = Color3.fromRGB(59, 130, 246),  -- Sapphire Blue
	Uncommon  = Color3.fromRGB(16, 185, 129),  -- Emerald Green
	Common    = Color3.fromRGB(100, 116, 139), -- Slate Gray
}

local spiritPouchGui: ScreenGui
local overlayBackdrop: Frame
local mainModal: Frame
local searchBox: TextBox
local capacityLabel: TextLabel
local itemGrid: ScrollingFrame
local sortDropdownBtn: TextButton

local characterViewport: ViewportFrame
local statsCardContainer: Frame
local realmTitleLabel: TextLabel
local hpBarFill: Frame
local hpBarText: TextLabel
local qiBarFill: Frame
local qiBarText: TextLabel

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

local updateInventoryRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent

function InventoryController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	InventoryController.BuildUI()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventory = inventoryData or {}
		InventoryController.RefreshGrid()
		InventoryController.UpdateVitalStats()
		InventoryController.Update3DDoll()
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.K then
			overlayBackdrop.Visible = not overlayBackdrop.Visible
			if overlayBackdrop.Visible then
				inventoryActionRemote:FireServer({ Action = "RequestSync" })
				InventoryController.RefreshGrid()
				InventoryController.UpdateVitalStats()
				InventoryController.Update3DDoll()
			end
		end
	end)

	task.defer(function()
		task.wait(0.8)
		inventoryActionRemote:FireServer({ Action = "RequestSync" })
	end)

	print("[ASCEND] Light-Mode InventoryController Initialized with Name Labels & Auto-Inspect.")
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

	overlayBackdrop = Instance.new("Frame")
	overlayBackdrop.Name = "OverlayBackdrop"
	overlayBackdrop.Size = UDim2.new(1, 0, 1, 0)
	overlayBackdrop.BackgroundTransparency = 1
	overlayBackdrop.BorderSizePixel = 0
	overlayBackdrop.Visible = false
	overlayBackdrop.Parent = spiritPouchGui

	mainModal = Instance.new("Frame")
	mainModal.Name = "MainModal"
	mainModal.Size = UDim2.new(0, 1260, 0, 680)
	mainModal.Position = UDim2.new(0.5, -630, 0.5, -340)
	mainModal.BackgroundColor3 = COLOR_LIGHT_MAIN
	mainModal.BorderSizePixel = 0
	mainModal.Parent = overlayBackdrop

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = COLOR_LIGHT_BORDER
	mStroke.Thickness = 1.5
	mStroke.Parent = mainModal

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, 0, 0, 52)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SPIRIT POUCH"
	headerTitle.TextColor3 = COLOR_TEXT_MAIN
	headerTitle.Font = UI_FONT
	headerTitle.TextSize = 36
	headerTitle.Parent = mainModal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = COLOR_DANGER_RED
	closeBtn.Text = "X"
	closeBtn.TextColor3 = COLOR_LIGHT_CARD
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 20
	closeBtn.Parent = mainModal

	closeBtn.MouseButton1Click:Connect(function()
		overlayBackdrop.Visible = false
	end)

	-- LEFT TAB BAR
	local verticalTabBar = Instance.new("Frame")
	verticalTabBar.Name = "VerticalTabBar"
	verticalTabBar.Size = UDim2.new(0, 120, 1, -64)
	verticalTabBar.Position = UDim2.new(0, 12, 0, 52)
	verticalTabBar.BackgroundColor3 = COLOR_LIGHT_PANEL
	verticalTabBar.BorderSizePixel = 0
	verticalTabBar.Parent = mainModal

	local vtStroke = Instance.new("UIStroke")
	vtStroke.Color = COLOR_LIGHT_BORDER
	vtStroke.Thickness = 1.5
	vtStroke.Parent = verticalTabBar

	local vtLayout = Instance.new("UIListLayout")
	vtLayout.FillDirection = Enum.FillDirection.Vertical
	vtLayout.Padding = UDim.new(0, 8)
	vtLayout.Parent = verticalTabBar

	local vtPadding = Instance.new("UIPadding")
	vtPadding.PaddingTop = UDim.new(0, 8)
	vtPadding.PaddingLeft = UDim.new(0, 6)
	vtPadding.PaddingRight = UDim.new(0, 6)
	vtPadding.Parent = verticalTabBar

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
		btn.Size = UDim2.new(1, 0, 0, 52)
		btn.BackgroundColor3 = if idx == 1 then COLOR_LIGHT_CARD else COLOR_LIGHT_PANEL
		btn.Text = tabData.Label
		btn.TextColor3 = if idx == 1 then COLOR_AZURE_BLUE else COLOR_TEXT_SUB
		btn.Font = UI_FONT
		btn.TextSize = 13
		btn.Parent = verticalTabBar

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = COLOR_LIGHT_BORDER
		btnStroke.Thickness = 1
		btnStroke.Parent = btn

		btn.MouseButton1Click:Connect(function()
			activeCategoryFilter = tabData.Id
			for _, child in ipairs(verticalTabBar:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = COLOR_LIGHT_PANEL
					child.TextColor3 = COLOR_TEXT_SUB
				end
			end
			btn.BackgroundColor3 = COLOR_LIGHT_CARD
			btn.TextColor3 = COLOR_AZURE_BLUE
			InventoryController.RefreshGrid()
		end)
	end

	-- COLUMN 1: CULTIVATOR HUB
	local col1 = Instance.new("Frame")
	col1.Name = "Column1_CultivatorHub"
	col1.Size = UDim2.new(0, 360, 1, -64)
	col1.Position = UDim2.new(0, 140, 0, 52)
	col1.BackgroundColor3 = COLOR_LIGHT_PANEL
	col1.BorderSizePixel = 0
	col1.Parent = mainModal

	local col1Stroke = Instance.new("UIStroke")
	col1Stroke.Color = COLOR_LIGHT_BORDER
	col1Stroke.Thickness = 1.5
	col1Stroke.Parent = col1

	local c1Header = Instance.new("TextLabel")
	c1Header.Size = UDim2.new(1, 0, 0, 40)
	c1Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c1Header.Text = "CULTIVATOR"
	c1Header.TextColor3 = COLOR_TEXT_MAIN
	c1Header.Font = UI_FONT
	c1Header.TextSize = 20
	c1Header.Parent = col1

	local c1HeaderStroke = Instance.new("UIStroke")
	c1HeaderStroke.Color = COLOR_LIGHT_BORDER
	c1HeaderStroke.Thickness = 1
	c1HeaderStroke.Parent = c1Header

	characterViewport = Instance.new("ViewportFrame")
	characterViewport.Name = "CharacterViewport"
	characterViewport.Size = UDim2.new(0, 220, 0, 300)
	characterViewport.Position = UDim2.new(0, 12, 0, 48)
	characterViewport.BackgroundColor3 = COLOR_LIGHT_CARD
	characterViewport.BorderSizePixel = 0
	characterViewport.Parent = col1

	local cvStroke = Instance.new("UIStroke")
	cvStroke.Color = COLOR_LIGHT_BORDER
	cvStroke.Thickness = 1.5
	cvStroke.Parent = characterViewport

	local eqContainer = Instance.new("Frame")
	eqContainer.Size = UDim2.new(0, 108, 0, 300)
	eqContainer.Position = UDim2.new(1, -120, 0, 48)
	eqContainer.BackgroundTransparency = 1
	eqContainer.Parent = col1

	local eqLayout = Instance.new("UIListLayout")
	eqLayout.FillDirection = Enum.FillDirection.Vertical
	eqLayout.Padding = UDim.new(0, 10)
	eqLayout.Parent = eqContainer

	local slotNames = { "HEAD", "ROBE", "WEAPON", "ARTIFACT" }
	for _, slotName in ipairs(slotNames) do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. slotName
		slot.Size = UDim2.new(1, 0, 0, 67)
		slot.BackgroundColor3 = COLOR_LIGHT_CARD
		slot.BorderSizePixel = 0
		slot.Parent = eqContainer

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = COLOR_LIGHT_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = slotName
		label.TextColor3 = COLOR_TEXT_SUB
		label.Font = UI_FONT
		label.TextSize = 13
		label.Parent = slot

		gearSlots[slotName] = slot
	end

	statsCardContainer = Instance.new("Frame")
	statsCardContainer.Name = "StatsContainerCard"
	statsCardContainer.Size = UDim2.new(1, -24, 0, 230)
	statsCardContainer.Position = UDim2.new(0, 12, 1, -242)
	statsCardContainer.BackgroundColor3 = COLOR_LIGHT_CARD
	statsCardContainer.BorderSizePixel = 0
	statsCardContainer.Parent = col1

	local scStroke = Instance.new("UIStroke")
	scStroke.Color = COLOR_LIGHT_BORDER
	scStroke.Thickness = 1.5
	scStroke.Parent = statsCardContainer

	-- HP BAR
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -65, 0, 28)
	hpBg.Position = UDim2.new(0, 50, 0, 18)
	hpBg.BackgroundColor3 = COLOR_LIGHT_PANEL
	hpBg.BorderSizePixel = 0
	hpBg.Parent = statsCardContainer

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = COLOR_LIGHT_BORDER
	hpStroke.Thickness = 1
	hpStroke.Parent = hpBg

	hpBarFill = Instance.new("Frame")
	hpBarFill.Size = UDim2.new(1, 0, 1, 0)
	hpBarFill.BackgroundColor3 = COLOR_HP_GREEN
	hpBarFill.BorderSizePixel = 0
	hpBarFill.Parent = hpBg

	hpBarText = Instance.new("TextLabel")
	hpBarText.Size = UDim2.new(1, 0, 1, 0)
	hpBarText.BackgroundTransparency = 1
	hpBarText.Text = "800 / 800"
	hpBarText.TextColor3 = COLOR_TEXT_MAIN
	hpBarText.Font = UI_FONT
	hpBarText.TextSize = 13
	hpBarText.ZIndex = 5
	hpBarText.Parent = hpBg

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 40, 0, 28)
	hpLabel.Position = UDim2.new(0, -45, 0, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP"
	hpLabel.TextColor3 = COLOR_TEXT_SUB
	hpLabel.Font = UI_FONT
	hpLabel.TextSize = 13
	hpLabel.TextXAlignment = Enum.TextXAlignment.Right
	hpLabel.Parent = hpBg

	-- QI BAR
	local qiBg = Instance.new("Frame")
	qiBg.Size = UDim2.new(1, -65, 0, 28)
	qiBg.Position = UDim2.new(0, 50, 0, 58)
	qiBg.BackgroundColor3 = COLOR_LIGHT_PANEL
	qiBg.BorderSizePixel = 0
	qiBg.Parent = statsCardContainer

	local qiStroke = Instance.new("UIStroke")
	qiStroke.Color = COLOR_LIGHT_BORDER
	qiStroke.Thickness = 1
	qiStroke.Parent = qiBg

	qiBarFill = Instance.new("Frame")
	qiBarFill.Size = UDim2.new(1, 0, 1, 0)
	qiBarFill.BackgroundColor3 = COLOR_AZURE_BLUE
	qiBarFill.BorderSizePixel = 0
	qiBarFill.Parent = qiBg

	qiBarText = Instance.new("TextLabel")
	qiBarText.Size = UDim2.new(1, 0, 1, 0)
	qiBarText.BackgroundTransparency = 1
	qiBarText.Text = "800 / 800"
	qiBarText.TextColor3 = COLOR_TEXT_MAIN
	qiBarText.Font = UI_FONT
	qiBarText.TextSize = 13
	qiBarText.ZIndex = 5
	qiBarText.Parent = qiBg

	local qiLabel = Instance.new("TextLabel")
	qiLabel.Size = UDim2.new(0, 40, 0, 28)
	qiLabel.Position = UDim2.new(0, -45, 0, 0)
	qiLabel.BackgroundTransparency = 1
	qiLabel.Text = "QI"
	qiLabel.TextColor3 = COLOR_TEXT_SUB
	qiLabel.Font = UI_FONT
	qiLabel.TextSize = 13
	qiLabel.TextXAlignment = Enum.TextXAlignment.Right
	qiLabel.Parent = qiBg

	realmTitleLabel = Instance.new("TextLabel")
	realmTitleLabel.Size = UDim2.new(1, -24, 0, 28)
	realmTitleLabel.Position = UDim2.new(0, 12, 0, 108)
	realmTitleLabel.BackgroundTransparency = 1
	realmTitleLabel.Text = "Qi Condensation — Tier 1"
	realmTitleLabel.TextColor3 = COLOR_ACTION_GOLD
	realmTitleLabel.Font = UI_FONT
	realmTitleLabel.TextSize = 16
	realmTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	realmTitleLabel.Parent = statsCardContainer

	capacityLabel = Instance.new("TextLabel")
	capacityLabel.Size = UDim2.new(1, -24, 0, 24)
	capacityLabel.Position = UDim2.new(0, 12, 0, 148)
	capacityLabel.BackgroundTransparency = 1
	capacityLabel.Text = "STORAGE  0 / 60 SLOTS"
	capacityLabel.TextColor3 = COLOR_TEXT_SUB
	capacityLabel.Font = UI_FONT
	capacityLabel.TextSize = 14
	capacityLabel.TextXAlignment = Enum.TextXAlignment.Left
	capacityLabel.Parent = statsCardContainer

	-- COLUMN 2: INVENTORY GRID WORKSPACE
	local col2 = Instance.new("Frame")
	col2.Name = "Column2_InventoryGrid"
	col2.Size = UDim2.new(0, 460, 1, -64)
	col2.Position = UDim2.new(0, 510, 0, 52)
	col2.BackgroundColor3 = COLOR_LIGHT_PANEL
	col2.BorderSizePixel = 0
	col2.Parent = mainModal

	local col2Stroke = Instance.new("UIStroke")
	col2Stroke.Color = COLOR_LIGHT_BORDER
	col2Stroke.Thickness = 1.5
	col2Stroke.Parent = col2

	local searchBg = Instance.new("Frame")
	searchBg.Size = UDim2.new(0, 260, 0, 38)
	searchBg.Position = UDim2.new(0, 12, 0, 10)
	searchBg.BackgroundColor3 = COLOR_LIGHT_CARD
	searchBg.BorderSizePixel = 0
	searchBg.Parent = col2

	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = COLOR_LIGHT_BORDER
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
	searchBox.TextSize = 14
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	searchBox:GetPropertyChangedSignal("Text"):Connect(function()
		currentSearchQuery = searchBox.Text:lower()
		InventoryController.RefreshGrid()
	end)

	sortDropdownBtn = Instance.new("TextButton")
	sortDropdownBtn.Size = UDim2.new(0, 160, 0, 38)
	sortDropdownBtn.Position = UDim2.new(1, -172, 0, 10)
	sortDropdownBtn.BackgroundColor3 = COLOR_LIGHT_CARD
	sortDropdownBtn.Text = "Sort by Rarity"
	sortDropdownBtn.TextColor3 = COLOR_TEXT_MAIN
	sortDropdownBtn.Font = UI_FONT
	sortDropdownBtn.TextSize = 14
	sortDropdownBtn.Parent = col2

	local sdStroke = Instance.new("UIStroke")
	sdStroke.Color = COLOR_LIGHT_BORDER
	sdStroke.Thickness = 1.5
	sdStroke.Parent = sortDropdownBtn

	itemGrid = Instance.new("ScrollingFrame")
	itemGrid.Name = "ItemGrid"
	itemGrid.Size = UDim2.new(1, -20, 1, -64)
	itemGrid.Position = UDim2.new(0, 10, 0, 56)
	itemGrid.BackgroundTransparency = 1
	itemGrid.BorderSizePixel = 0
	itemGrid.ScrollBarThickness = 4
	itemGrid.ScrollBarImageColor3 = COLOR_AZURE_BLUE
	itemGrid.CanvasSize = UDim2.new(0, 0, 0, 1200)
	itemGrid.Parent = col2

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 76, 0, 76)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemGrid

	-- COLUMN 3: ITEM INSPECTION
	itemCardContainer = Instance.new("Frame")
	itemCardContainer.Name = "Column3_ItemInspection"
	itemCardContainer.Size = UDim2.new(0, 270, 1, -64)
	itemCardContainer.Position = UDim2.new(0, 978, 0, 52)
	itemCardContainer.BackgroundColor3 = COLOR_LIGHT_PANEL
	itemCardContainer.BorderSizePixel = 0
	itemCardContainer.Parent = mainModal

	local icStroke = Instance.new("UIStroke")
	icStroke.Color = COLOR_LIGHT_BORDER
	icStroke.Thickness = 1.5
	icStroke.Parent = itemCardContainer

	local c3Header = Instance.new("TextLabel")
	c3Header.Size = UDim2.new(1, 0, 0, 40)
	c3Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c3Header.Text = "ITEM INSPECTION"
	c3Header.TextColor3 = COLOR_TEXT_MAIN
	c3Header.Font = UI_FONT
	c3Header.TextSize = 18
	c3Header.Parent = itemCardContainer

	local c3HeaderStroke = Instance.new("UIStroke")
	c3HeaderStroke.Color = COLOR_LIGHT_BORDER
	c3HeaderStroke.Thickness = 1
	c3HeaderStroke.Parent = c3Header

	tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Size = UDim2.new(1, -20, 0, 36)
	tooltipTitle.Position = UDim2.new(0, 10, 0, 48)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = UI_FONT
	tooltipTitle.TextSize = 18
	tooltipTitle.TextWrapped = true
	tooltipTitle.TextColor3 = COLOR_TEXT_MAIN
	tooltipTitle.TextXAlignment = Enum.TextXAlignment.Center
	tooltipTitle.Parent = itemCardContainer

	tooltipRarityBadge = Instance.new("TextLabel")
	tooltipRarityBadge.Size = UDim2.new(1, -20, 0, 22)
	tooltipRarityBadge.Position = UDim2.new(0, 10, 0, 86)
	tooltipRarityBadge.BackgroundTransparency = 1
	tooltipRarityBadge.Font = UI_FONT
	tooltipRarityBadge.TextSize = 14
	tooltipRarityBadge.TextColor3 = RARITY_COLORS.Common
	tooltipRarityBadge.Text = "COMMON ITEM"
	tooltipRarityBadge.TextXAlignment = Enum.TextXAlignment.Center
	tooltipRarityBadge.Parent = itemCardContainer

	tooltipIconBox = Instance.new("Frame")
	tooltipIconBox.Size = UDim2.new(0, 110, 0, 110)
	tooltipIconBox.Position = UDim2.new(0.5, -55, 0, 112)
	tooltipIconBox.BackgroundColor3 = COLOR_LIGHT_CARD
	tooltipIconBox.BorderSizePixel = 0
	tooltipIconBox.Parent = itemCardContainer

	local ibStroke = Instance.new("UIStroke")
	ibStroke.Color = COLOR_LIGHT_BORDER
	ibStroke.Thickness = 1.5
	ibStroke.Parent = tooltipIconBox

	tooltipIcon = Instance.new("ImageLabel")
	tooltipIcon.Size = UDim2.new(1, -12, 1, -12)
	tooltipIcon.Position = UDim2.new(0, 6, 0, 6)
	tooltipIcon.BackgroundTransparency = 1
	tooltipIcon.ScaleType = Enum.ScaleType.Fit
	tooltipIcon.Parent = tooltipIconBox

	tooltipStatsBox = Instance.new("Frame")
	tooltipStatsBox.Size = UDim2.new(1, -24, 0, 75)
	tooltipStatsBox.Position = UDim2.new(0, 12, 0, 232)
	tooltipStatsBox.BackgroundColor3 = COLOR_LIGHT_CARD
	tooltipStatsBox.BorderSizePixel = 0
	tooltipStatsBox.Parent = itemCardContainer

	local sbBoxStroke = Instance.new("UIStroke")
	sbBoxStroke.Color = COLOR_LIGHT_BORDER
	sbBoxStroke.Thickness = 1
	sbBoxStroke.Parent = tooltipStatsBox

	tooltipStats = Instance.new("TextLabel")
	tooltipStats.Size = UDim2.new(1, -16, 1, -8)
	tooltipStats.Position = UDim2.new(0, 8, 0, 4)
	tooltipStats.BackgroundTransparency = 1
	tooltipStats.Font = UI_FONT
	tooltipStats.TextSize = 14
	tooltipStats.TextColor3 = COLOR_HP_GREEN
	tooltipStats.TextWrapped = true
	tooltipStats.TextXAlignment = Enum.TextXAlignment.Left
	tooltipStats.Parent = tooltipStatsBox

	tooltipDescBox = Instance.new("Frame")
	tooltipDescBox.Size = UDim2.new(1, -24, 0, 175)
	tooltipDescBox.Position = UDim2.new(0, 12, 0, 317)
	tooltipDescBox.BackgroundColor3 = COLOR_LIGHT_CARD
	tooltipDescBox.BorderSizePixel = 0
	tooltipDescBox.Parent = itemCardContainer

	local dbStroke = Instance.new("UIStroke")
	dbStroke.Color = COLOR_LIGHT_BORDER
	dbStroke.Thickness = 1
	dbStroke.Parent = tooltipDescBox

	tooltipDesc = Instance.new("TextLabel")
	tooltipDesc.Size = UDim2.new(1, -12, 1, -12)
	tooltipDesc.Position = UDim2.new(0, 6, 0, 6)
	tooltipDesc.BackgroundTransparency = 1
	tooltipDesc.Font = UI_FONT
	tooltipDesc.TextSize = 14
	tooltipDesc.TextColor3 = COLOR_TEXT_SUB
	tooltipDesc.TextWrapped = true
	tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
	tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
	tooltipDesc.Parent = tooltipDescBox

	actionPrimaryBtn = Instance.new("TextButton")
	actionPrimaryBtn.Size = UDim2.new(1, -24, 0, 44)
	actionPrimaryBtn.Position = UDim2.new(0, 12, 1, -104)
	actionPrimaryBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	actionPrimaryBtn.Text = "EQUIP"
	actionPrimaryBtn.TextColor3 = COLOR_LIGHT_MAIN
	actionPrimaryBtn.Font = UI_FONT
	actionPrimaryBtn.TextSize = 18
	actionPrimaryBtn.Parent = itemCardContainer

	actionPrimaryBtn.MouseButton1Click:Connect(function()
		if selectedSlotIndex then
			InventoryController.UseSlot(selectedSlotIndex)
		end
	end)

	actionDropBtn = Instance.new("TextButton")
	actionDropBtn.Size = UDim2.new(1, -24, 0, 44)
	actionDropBtn.Position = UDim2.new(0, 12, 1, -52)
	actionDropBtn.BackgroundColor3 = COLOR_DANGER_RED
	actionDropBtn.Text = "DROP"
	actionDropBtn.TextColor3 = COLOR_LIGHT_CARD
	actionDropBtn.Font = UI_FONT
	actionDropBtn.TextSize = 18
	actionDropBtn.Parent = itemCardContainer

	actionDropBtn.MouseButton1Click:Connect(function()
		if selectedSlotIndex then
			inventoryActionRemote:FireServer({
				Action = "DropItem",
				SlotIndex = selectedSlotIndex,
			})
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

	for _, child in ipairs(charClone:GetDescendants()) do
		if child:IsA("LuaSourceContainer") or child:IsA("Sound") then
			child:Destroy()
		end
	end

	charClone.Parent = worldModel

	local hrp = charClone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = CFrame.new(0, 0, 0)
		camera.CFrame = CFrame.new(Vector3.new(0, 0.2, -6.2), Vector3.new(0, 0.1, 0))
	end
end

function InventoryController.SetupGridSlots()
	for i = 1, 60 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. i
		slot.LayoutOrder = i
		slot.BackgroundColor3 = COLOR_LIGHT_CARD
		slot.BorderSizePixel = 0
		slot.Parent = itemGrid

		local stroke = Instance.new("UIStroke")
		stroke.Name = "RarityBorder"
		stroke.Thickness = 1.5
		stroke.Color = COLOR_LIGHT_BORDER
		stroke.Parent = slot

		local rarityHeader = Instance.new("TextLabel")
		rarityHeader.Name = "RarityHeader"
		rarityHeader.Size = UDim2.new(1, 0, 0, 18)
		rarityHeader.Position = UDim2.new(0, 0, 0, 0)
		rarityHeader.BackgroundColor3 = COLOR_LIGHT_BORDER
		rarityHeader.Text = ""
		rarityHeader.TextColor3 = COLOR_LIGHT_CARD
		rarityHeader.Font = UI_FONT
		rarityHeader.TextSize = 10
		rarityHeader.Visible = false
		rarityHeader.Parent = slot

		local itemNameLabel = Instance.new("TextLabel")
		itemNameLabel.Name = "ItemNameLabel"
		itemNameLabel.Size = UDim2.new(1, -8, 1, -34)
		itemNameLabel.Position = UDim2.new(0, 4, 0, 20)
		itemNameLabel.BackgroundTransparency = 1
		itemNameLabel.Text = ""
		itemNameLabel.TextColor3 = COLOR_TEXT_MAIN
		itemNameLabel.Font = UI_FONT
		itemNameLabel.TextSize = 11
		itemNameLabel.TextWrapped = true
		itemNameLabel.TextYAlignment = Enum.TextYAlignment.Center
		itemNameLabel.Visible = false
		itemNameLabel.Parent = slot

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -12, 1, -34)
		icon.Position = UDim2.new(0, 6, 0, 20)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Visible = false
		icon.Parent = slot

		local quantity = Instance.new("TextLabel")
		quantity.Name = "Quantity"
		quantity.Size = UDim2.new(1, -4, 0, 14)
		quantity.Position = UDim2.new(0, 0, 1, -14)
		quantity.BackgroundTransparency = 1
		quantity.TextColor3 = COLOR_TEXT_MAIN
		quantity.Font = UI_FONT
		quantity.TextSize = 11
		quantity.TextXAlignment = Enum.TextXAlignment.Right
		quantity.Text = ""
		quantity.Parent = slot

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = slot

		btn.MouseButton1Click:Connect(function()
			InventoryController.InspectSlot(i)
		end)

		slotButtons[i] = slot
	end
end

function InventoryController.RefreshGrid()
	local usedCount = 0
	local firstValidSlot: number? = nil

	for i = 1, 60 do
		local slotFrame = slotButtons[i]
		if not slotFrame then continue end

		local icon = slotFrame:FindFirstChild("Icon") :: ImageLabel?
		local itemNameLabel = slotFrame:FindFirstChild("ItemNameLabel") :: TextLabel?
		local quantity = slotFrame:FindFirstChild("Quantity") :: TextLabel?
		local rarityHeader = slotFrame:FindFirstChild("RarityHeader") :: TextLabel?
		local stroke = slotFrame:FindFirstChildOfClass("UIStroke")

		local slotData = currentInventory[i]
		local isVisible = true

		if slotData then
			usedCount += 1
			if not firstValidSlot then
				firstValidSlot = i
			end

			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef then
				local itemType = itemDef.Type or "Material"
				if activeCategoryFilter ~= "ALL" then
					if activeCategoryFilter == "CONSUMABLE" and itemType ~= "Consumable" then
						isVisible = false
					elseif activeCategoryFilter == "HERB" and itemType ~= "Material" then
						isVisible = false
					elseif activeCategoryFilter == "WEAPON" and itemType ~= "Weapon" and itemType ~= "Crest" then
						isVisible = false
					end
				end

				if currentSearchQuery ~= "" and not itemDef.Name:lower():find(currentSearchQuery, 1, true) then
					isVisible = false
				end

				if isVisible then
					local rarityColor = RARITY_COLORS[itemDef.Rarity] or COLOR_TEXT_SUB
					slotFrame.BackgroundColor3 = COLOR_LIGHT_CARD

					if itemNameLabel then
						itemNameLabel.Text = itemDef.Name
						itemNameLabel.Visible = true
					end

					if quantity then
						quantity.Text = "x" .. tostring(slotData.Count)
					end

					if rarityHeader then
						rarityHeader.Text = itemDef.Rarity:upper()
						rarityHeader.BackgroundColor3 = rarityColor
						rarityHeader.Visible = true
					end

					if stroke then
						stroke.Color = if i == selectedSlotIndex then COLOR_AZURE_BLUE else rarityColor
						stroke.Thickness = if i == selectedSlotIndex then 2.5 else 1.5
					end
				end
			end
		else
			slotFrame.BackgroundColor3 = COLOR_LIGHT_CARD
			isVisible = (activeCategoryFilter == "ALL" and currentSearchQuery == "")
		end

		slotFrame.Visible = isVisible
		if not slotData or not isVisible then
			if icon then icon.Visible = false end
			if itemNameLabel then itemNameLabel.Visible = false end
			if quantity then quantity.Text = "" end
			if rarityHeader then rarityHeader.Visible = false end
			if stroke then stroke.Color = COLOR_LIGHT_BORDER end
		end
	end

	if capacityLabel then
		capacityLabel.Text = string.format("STORAGE  %d / 60 SLOTS", usedCount)
	end

	-- Auto-Inspect first filled slot if no valid item is currently selected
	if firstValidSlot then
		if not selectedSlotIndex or not currentInventory[selectedSlotIndex] then
			selectedSlotIndex = firstValidSlot
		end
		InventoryController.InspectSlot(selectedSlotIndex)
	end
end

function InventoryController.InspectSlot(slotIdx: number)
	selectedSlotIndex = slotIdx

	local slotData = currentInventory[slotIdx]
	if not slotData then
		itemCardContainer.Visible = false
		return
	end

	local itemDef = ItemConfig.GetItem(slotData.ItemId)
	if not itemDef then return end

	itemCardContainer.Visible = true

	tooltipTitle.Text = itemDef.Name
	tooltipRarityBadge.Text = string.format("%s %s", itemDef.Rarity:upper(), itemDef.Type:upper())
	tooltipRarityBadge.TextColor3 = RARITY_COLORS[itemDef.Rarity] or COLOR_TEXT_MAIN
	tooltipDesc.Text = itemDef.Description
	tooltipIcon.Visible = true

	if itemDef.Type == "Consumable" then
		actionPrimaryBtn.Text = "USE"
		actionPrimaryBtn.BackgroundColor3 = COLOR_HP_GREEN
	else
		actionPrimaryBtn.Text = "EQUIP"
		actionPrimaryBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	end

	local statText = ""
	if itemDef.Stats then
		if itemDef.Stats.HealAmount then
			statText ..= string.format("HEALTH RESTORED: +%d\n", itemDef.Stats.HealAmount)
		end
		if itemDef.Stats.QiGrant then
			statText ..= string.format("SPIRIT QI RESTORED: +%d\n", itemDef.Stats.QiGrant)
		end
		if itemDef.Stats.Damage then
			statText ..= string.format("ATTACK DAMAGE: +%d\n", itemDef.Stats.Damage)
		end
		if itemDef.Stats.Speed then
			statText ..= string.format("ATTACK SPEED: %.1fx\n", itemDef.Stats.Speed)
		end
	end
	tooltipStats.Text = if statText ~= "" then statText else "NO EXTRA ATTRIBUTES"
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
	local maxQi = char:GetAttribute("MaxQi") or 800
	local clampedQi = math.min(currentQi, maxQi)
	local qiRatio = math.clamp(clampedQi / math.max(1, maxQi), 0, 1)
	qiBarFill.Size = UDim2.new(qiRatio, 0, 1, 0)
	qiBarText.Text = string.format("%d / %d", math.floor(clampedQi), math.floor(maxQi))

	realmTitleLabel.Text = "Qi Condensation — Tier 1"
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