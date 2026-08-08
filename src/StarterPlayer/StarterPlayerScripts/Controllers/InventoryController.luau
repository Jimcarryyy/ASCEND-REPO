--!strict
--[[
    InventoryController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
    Client UI controller for ASCEND Spirit Pouch.
    Features Xianxia Jade/Cream/Mahogany Palette, Rarity Tinted Slot Backgrounds,
    and non-overlapping inspection text.
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

-- XIANXIA JADE, CREAM, PEACH & MAHOGANY PALETTE
local COLOR_MAIN_CREAM     = UIAssets.Colors.MainPanel       -- #F7EAE0
local COLOR_CARD_PEACH     = UIAssets.Colors.CardBackground  -- #F9D2BA
local COLOR_BORDER_JADE    = UIAssets.Colors.BorderStroke    -- #1D4533
local COLOR_TEXT_JADE      = UIAssets.Colors.TextPrimary     -- #1D4533
local COLOR_MAHOGANY       = UIAssets.Colors.ButtonPrimary   -- #5E3122

local RARITY_COLORS = {
	Immortal  = Color3.fromRGB(225, 29, 72),   -- Crimson Red
	Mythic    = Color3.fromRGB(225, 29, 72),   -- Crimson Red
	Legendary = Color3.fromRGB(217, 119, 6),   -- Gold Amber
	Epic      = Color3.fromRGB(147, 51, 234),  -- Purple
	Rare      = Color3.fromRGB(59, 130, 246),  -- Sapphire Blue
	Uncommon  = Color3.fromRGB(16, 185, 129),  -- Jade Green
	Common    = Color3.fromRGB(100, 116, 139), -- Slate Gray
}

-- SOFT TINTED BACKGROUNDS BY RARITY TIER
local RARITY_SLOT_BG = {
	Immortal  = Color3.fromRGB(254, 226, 226), -- Soft Red Tint
	Mythic    = Color3.fromRGB(254, 226, 226), -- Soft Red Tint
	Legendary = Color3.fromRGB(254, 243, 199), -- Soft Amber Tint
	Epic      = Color3.fromRGB(243, 232, 255), -- Soft Purple Tint
	Rare      = Color3.fromRGB(224, 242, 254), -- Soft Sapphire Tint
	Uncommon  = Color3.fromRGB(220, 252, 231), -- Soft Emerald Tint
	Common    = Color3.fromRGB(241, 245, 249), -- Soft Slate Tint
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
		currentInventory = inventoryData
		InventoryController.RefreshGrid()
		InventoryController.UpdateVitalStats()
		InventoryController.Update3DDoll()
		InventoryController.InspectSlot(selectedSlotIndex or 1)
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
				InventoryController.InspectSlot(selectedSlotIndex or 1)
			end
		end
	end)

	task.defer(function()
		task.wait(0.8)
		inventoryActionRemote:FireServer({ Action = "RequestSync" })
	end)

	print("[ASCEND] Xianxia Palette InventoryController Initialized.")
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
	mainModal.Size = UDim2.new(0, 1300, 0, 700)
	mainModal.Position = UDim2.new(0.5, -650, 0.5, -350)
	mainModal.BackgroundColor3 = COLOR_MAIN_CREAM
	mainModal.BorderSizePixel = 0
	mainModal.Parent = overlayBackdrop

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = COLOR_BORDER_JADE
	mStroke.Thickness = 2
	mStroke.Parent = mainModal

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, 0, 0, 56)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SPIRIT POUCH"
	headerTitle.TextColor3 = COLOR_TEXT_JADE
	headerTitle.Font = UI_FONT
	headerTitle.TextSize = 40
	headerTitle.Parent = mainModal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 38, 0, 38)
	closeBtn.Position = UDim2.new(1, -48, 0, 9)
	closeBtn.BackgroundColor3 = RARITY_COLORS.Immortal
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 22
	closeBtn.Parent = mainModal

	closeBtn.MouseButton1Click:Connect(function()
		overlayBackdrop.Visible = false
	end)

	local verticalTabBar = Instance.new("Frame")
	verticalTabBar.Name = "VerticalTabBar"
	verticalTabBar.Size = UDim2.new(0, 120, 1, -70)
	verticalTabBar.Position = UDim2.new(0, 10, 0, 58)
	verticalTabBar.BackgroundColor3 = COLOR_CARD_PEACH
	verticalTabBar.BorderSizePixel = 0
	verticalTabBar.Parent = mainModal

	local vtStroke = Instance.new("UIStroke")
	vtStroke.Color = COLOR_BORDER_JADE
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
		btn.BackgroundColor3 = if idx == 1 then COLOR_MAIN_CREAM else COLOR_CARD_PEACH
		btn.Text = tabData.Label
		btn.TextColor3 = COLOR_TEXT_JADE
		btn.Font = UI_FONT
		btn.TextSize = 15
		btn.Parent = verticalTabBar

		local activeBar = Instance.new("Frame")
		activeBar.Name = "ActiveBar"
		activeBar.Size = UDim2.new(0, 4, 1, 0)
		activeBar.Position = UDim2.new(0, 0, 0, 0)
		activeBar.BackgroundColor3 = COLOR_BORDER_JADE
		activeBar.BorderSizePixel = 0
		activeBar.Visible = (idx == 1)
		activeBar.Parent = btn

		btn.MouseButton1Click:Connect(function()
			activeCategoryFilter = tabData.Id
			for _, child in ipairs(verticalTabBar:GetChildren()) do
				if child:IsA("TextButton") then
					child.BackgroundColor3 = COLOR_CARD_PEACH
					child.TextColor3 = COLOR_MAHOGANY
					local bar = child:FindFirstChild("ActiveBar") :: Frame?
					if bar then bar.Visible = false end
				end
			end
			btn.BackgroundColor3 = COLOR_MAIN_CREAM
			btn.TextColor3 = COLOR_TEXT_JADE
			activeBar.Visible = true
			InventoryController.RefreshGrid()
		end)
	end

	local leftPanel = Instance.new("Frame")
	leftPanel.Name = "LeftPanel_CharacterHub"
	leftPanel.Size = UDim2.new(0, 380, 1, -70)
	leftPanel.Position = UDim2.new(0, 140, 0, 58)
	leftPanel.BackgroundColor3 = COLOR_CARD_PEACH
	leftPanel.BorderSizePixel = 0
	leftPanel.Parent = mainModal

	local lpStroke = Instance.new("UIStroke")
	lpStroke.Color = COLOR_BORDER_JADE
	lpStroke.Thickness = 1.5
	lpStroke.Parent = leftPanel

	local pouchTitle = Instance.new("TextLabel")
	pouchTitle.Size = UDim2.new(1, 0, 0, 36)
	pouchTitle.Position = UDim2.new(0, 0, 0, 8)
	pouchTitle.BackgroundTransparency = 1
	pouchTitle.Text = "CULTIVATOR"
	pouchTitle.TextColor3 = COLOR_TEXT_JADE
	pouchTitle.Font = UI_FONT
	pouchTitle.TextSize = 26
	pouchTitle.Parent = leftPanel

	characterViewport = Instance.new("ViewportFrame")
	characterViewport.Name = "CharacterViewport"
	characterViewport.Size = UDim2.new(0, 230, 0, 310)
	characterViewport.Position = UDim2.new(0, 15, 0, 48)
	characterViewport.BackgroundTransparency = 1
	characterViewport.Parent = leftPanel

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
		slot.BackgroundColor3 = COLOR_MAIN_CREAM
		slot.BorderSizePixel = 0
		slot.Parent = eqContainer

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = COLOR_BORDER_JADE
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.Text = slotName
		label.TextColor3 = COLOR_TEXT_JADE
		label.Font = UI_FONT
		label.TextSize = 16
		label.Parent = slot

		gearSlots[slotName] = slot
	end

	statsCardContainer = Instance.new("Frame")
	statsCardContainer.Name = "StatsContainerCard"
	statsCardContainer.Size = UDim2.new(1, -24, 0, 210)
	statsCardContainer.Position = UDim2.new(0, 12, 1, -222)
	statsCardContainer.BackgroundColor3 = COLOR_MAIN_CREAM
	statsCardContainer.BorderSizePixel = 0
	statsCardContainer.Parent = leftPanel

	local scStroke = Instance.new("UIStroke")
	scStroke.Color = COLOR_BORDER_JADE
	scStroke.Thickness = 1.5
	scStroke.Parent = statsCardContainer

	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -65, 0, 28)
	hpBg.Position = UDim2.new(0, 50, 0, 18)
	hpBg.BackgroundColor3 = COLOR_CARD_PEACH
	hpBg.BorderSizePixel = 0
	hpBg.Parent = statsCardContainer

	hpBarFill = Instance.new("Frame")
	hpBarFill.Size = UDim2.new(1, 0, 1, 0)
	hpBarFill.BackgroundColor3 = COLOR_BORDER_JADE
	hpBarFill.BorderSizePixel = 0
	hpBarFill.Parent = hpBg

	hpBarText = Instance.new("TextLabel")
	hpBarText.Size = UDim2.new(1, 0, 1, 0)
	hpBarText.BackgroundTransparency = 1
	hpBarText.Text = "800 / 800"
	hpBarText.TextColor3 = COLOR_MAIN_CREAM
	hpBarText.Font = UI_FONT
	hpBarText.TextSize = 16
	hpBarText.ZIndex = 5
	hpBarText.Parent = hpBg

	local hpLabel = Instance.new("TextLabel")
	hpLabel.Size = UDim2.new(0, 40, 0, 28)
	hpLabel.Position = UDim2.new(0, -45, 0, 0)
	hpLabel.BackgroundTransparency = 1
	hpLabel.Text = "HP"
	hpLabel.TextColor3 = COLOR_MAHOGANY
	hpLabel.Font = UI_FONT
	hpLabel.TextSize = 16
	hpLabel.TextXAlignment = Enum.TextXAlignment.Right
	hpLabel.Parent = hpBg

	local qiBg = Instance.new("Frame")
	qiBg.Size = UDim2.new(1, -65, 0, 28)
	qiBg.Position = UDim2.new(0, 50, 0, 58)
	qiBg.BackgroundColor3 = COLOR_CARD_PEACH
	qiBg.BorderSizePixel = 0
	qiBg.Parent = statsCardContainer

	qiBarFill = Instance.new("Frame")
	qiBarFill.Size = UDim2.new(1, 0, 1, 0)
	qiBarFill.BackgroundColor3 = COLOR_MAHOGANY
	qiBarFill.BorderSizePixel = 0
	qiBarFill.Parent = qiBg

	qiBarText = Instance.new("TextLabel")
	qiBarText.Size = UDim2.new(1, 0, 1, 0)
	qiBarText.BackgroundTransparency = 1
	qiBarText.Text = "800 / 800"
	qiBarText.TextColor3 = COLOR_MAIN_CREAM
	qiBarText.Font = UI_FONT
	qiBarText.TextSize = 16
	qiBarText.ZIndex = 5
	qiBarText.Parent = qiBg

	local qiLabel = Instance.new("TextLabel")
	qiLabel.Size = UDim2.new(0, 40, 0, 28)
	qiLabel.Position = UDim2.new(0, -45, 0, 0)
	qiLabel.BackgroundTransparency = 1
	qiLabel.Text = "QI"
	qiLabel.TextColor3 = COLOR_MAHOGANY
	qiLabel.Font = UI_FONT
	qiLabel.TextSize = 16
	qiLabel.TextXAlignment = Enum.TextXAlignment.Right
	qiLabel.Parent = qiBg

	realmTitleLabel = Instance.new("TextLabel")
	realmTitleLabel.Size = UDim2.new(1, -24, 0, 28)
	realmTitleLabel.Position = UDim2.new(0, 12, 0, 108)
	realmTitleLabel.BackgroundTransparency = 1
	realmTitleLabel.Text = "Foundation Establishment — Tier 2"
	realmTitleLabel.TextColor3 = COLOR_BORDER_JADE
	realmTitleLabel.Font = UI_FONT
	realmTitleLabel.TextSize = 18
	realmTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	realmTitleLabel.Parent = statsCardContainer

	capacityLabel = Instance.new("TextLabel")
	capacityLabel.Size = UDim2.new(1, -24, 0, 24)
	capacityLabel.Position = UDim2.new(0, 12, 0, 148)
	capacityLabel.BackgroundTransparency = 1
	capacityLabel.Text = "STORAGE  0 / 60 SLOTS"
	capacityLabel.TextColor3 = COLOR_MAHOGANY
	capacityLabel.Font = UI_FONT
	capacityLabel.TextSize = 16
	capacityLabel.TextXAlignment = Enum.TextXAlignment.Left
	capacityLabel.Parent = statsCardContainer

	local midPanel = Instance.new("Frame")
	midPanel.Name = "MidPanel_InventoryGrid"
	midPanel.Size = UDim2.new(0, 460, 1, -70)
	midPanel.Position = UDim2.new(0, 530, 0, 58)
	midPanel.BackgroundColor3 = COLOR_CARD_PEACH
	midPanel.BorderSizePixel = 0
	midPanel.Parent = mainModal

	local mpStroke = Instance.new("UIStroke")
	mpStroke.Color = COLOR_BORDER_JADE
	mpStroke.Thickness = 1.5
	mpStroke.Parent = midPanel

	local searchBg = Instance.new("Frame")
	searchBg.Size = UDim2.new(0, 260, 0, 40)
	searchBg.Position = UDim2.new(0, 12, 0, 12)
	searchBg.BackgroundColor3 = COLOR_MAIN_CREAM
	searchBg.BorderSizePixel = 0
	searchBg.Parent = midPanel

	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = COLOR_BORDER_JADE
	sbStroke.Thickness = 1.5
	sbStroke.Parent = searchBg

	searchBox = Instance.new("TextBox")
	searchBox.Size = UDim2.new(1, -12, 1, 0)
	searchBox.Position = UDim2.new(0, 6, 0, 0)
	searchBox.BackgroundTransparency = 1
	searchBox.PlaceholderText = "Search items..."
	searchBox.Text = ""
	searchBox.TextColor3 = COLOR_TEXT_JADE
	searchBox.PlaceholderColor3 = COLOR_MAHOGANY
	searchBox.Font = UI_FONT
	searchBox.TextSize = 16
	searchBox.TextXAlignment = Enum.TextXAlignment.Left
	searchBox.ClearTextOnFocus = false
	searchBox.Parent = searchBg

	sortDropdownBtn = Instance.new("TextButton")
	sortDropdownBtn.Size = UDim2.new(0, 160, 0, 40)
	sortDropdownBtn.Position = UDim2.new(1, -172, 0, 12)
	sortDropdownBtn.BackgroundColor3 = COLOR_MAIN_CREAM
	sortDropdownBtn.Text = "Sort by Rarity"
	sortDropdownBtn.TextColor3 = COLOR_TEXT_JADE
	sortDropdownBtn.Font = UI_FONT
	sortDropdownBtn.TextSize = 16
	sortDropdownBtn.Parent = midPanel

	local sdStroke = Instance.new("UIStroke")
	sdStroke.Color = COLOR_BORDER_JADE
	sdStroke.Thickness = 1.5
	sdStroke.Parent = sortDropdownBtn

	itemGrid = Instance.new("ScrollingFrame")
	itemGrid.Name = "ItemGrid"
	itemGrid.Size = UDim2.new(1, -20, 1, -68)
	itemGrid.Position = UDim2.new(0, 10, 0, 58)
	itemGrid.BackgroundTransparency = 1
	itemGrid.BorderSizePixel = 0
	itemGrid.ScrollBarThickness = 6
	itemGrid.ScrollBarImageColor3 = COLOR_BORDER_JADE
	itemGrid.CanvasSize = UDim2.new(0, 0, 0, 1100)
	itemGrid.Parent = midPanel

	local gridLayout = Instance.new("UIGridLayout")
	gridLayout.CellSize = UDim2.new(0, 76, 0, 76)
	gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
	gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	gridLayout.Parent = itemGrid

	itemCardContainer = Instance.new("Frame")
	itemCardContainer.Name = "RightItemCardContainer"
	itemCardContainer.Size = UDim2.new(0, 300, 1, -70)
	itemCardContainer.Position = UDim2.new(0, 990, 0, 58)
	itemCardContainer.BackgroundColor3 = COLOR_CARD_PEACH
	itemCardContainer.BorderSizePixel = 0
	itemCardContainer.Parent = mainModal

	local icStroke = Instance.new("UIStroke")
	icStroke.Color = COLOR_BORDER_JADE
	icStroke.Thickness = 1.5
	icStroke.Parent = itemCardContainer

	-- FIXED OVERLAPPING TITLE (Padded height + TextWrapped)
	tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Size = UDim2.new(1, -20, 0, 48)
	tooltipTitle.Position = UDim2.new(0, 10, 0, 8)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = UI_FONT
	tooltipTitle.TextSize = 15
	tooltipTitle.TextWrapped = true
	tooltipTitle.TextColor3 = COLOR_TEXT_JADE
	tooltipTitle.TextXAlignment = Enum.TextXAlignment.Center
	tooltipTitle.Parent = itemCardContainer

	tooltipRarityBadge = Instance.new("TextLabel")
	tooltipRarityBadge.Size = UDim2.new(1, -20, 0, 22)
	tooltipRarityBadge.Position = UDim2.new(0, 10, 0, 58)
	tooltipRarityBadge.BackgroundTransparency = 1
	tooltipRarityBadge.Font = UI_FONT
	tooltipRarityBadge.TextSize = 15
	tooltipRarityBadge.TextColor3 = RARITY_COLORS.Immortal
	tooltipRarityBadge.Text = "IMMORTAL CONSUMABLE"
	tooltipRarityBadge.TextXAlignment = Enum.TextXAlignment.Center
	tooltipRarityBadge.Parent = itemCardContainer

	tooltipIconBox = Instance.new("Frame")
	tooltipIconBox.Size = UDim2.new(0, 110, 0, 110)
	tooltipIconBox.Position = UDim2.new(0.5, -55, 0, 84)
	tooltipIconBox.BackgroundColor3 = COLOR_MAIN_CREAM
	tooltipIconBox.BorderSizePixel = 0
	tooltipIconBox.Parent = itemCardContainer

	local ibStroke = Instance.new("UIStroke")
	ibStroke.Color = COLOR_BORDER_JADE
	ibStroke.Thickness = 1.5
	ibStroke.Parent = tooltipIconBox

	tooltipIcon = Instance.new("ImageLabel")
	tooltipIcon.Size = UDim2.new(1, -12, 1, -12)
	tooltipIcon.Position = UDim2.new(0, 6, 0, 6)
	tooltipIcon.BackgroundTransparency = 1
	tooltipIcon.ScaleType = Enum.ScaleType.Fit
	tooltipIcon.Parent = tooltipIconBox

	tooltipStatsBox = Instance.new("Frame")
	tooltipStatsBox.Size = UDim2.new(1, -24, 0, 70)
	tooltipStatsBox.Position = UDim2.new(0, 12, 0, 202)
	tooltipStatsBox.BackgroundColor3 = COLOR_MAIN_CREAM
	tooltipStatsBox.BorderSizePixel = 0
	tooltipStatsBox.Parent = itemCardContainer

	local sbBoxStroke = Instance.new("UIStroke")
	sbBoxStroke.Color = COLOR_BORDER_JADE
	sbBoxStroke.Thickness = 1
	sbBoxStroke.Parent = tooltipStatsBox

	tooltipStats = Instance.new("TextLabel")
	tooltipStats.Size = UDim2.new(1, -16, 1, -8)
	tooltipStats.Position = UDim2.new(0, 8, 0, 4)
	tooltipStats.BackgroundTransparency = 1
	tooltipStats.Font = UI_FONT
	tooltipStats.TextSize = 15
	tooltipStats.TextColor3 = COLOR_BORDER_JADE
	tooltipStats.TextWrapped = true
	tooltipStats.TextXAlignment = Enum.TextXAlignment.Left
	tooltipStats.Parent = tooltipStatsBox

	tooltipDescBox = Instance.new("Frame")
	tooltipDescBox.Size = UDim2.new(1, -24, 0, 120)
	tooltipDescBox.Position = UDim2.new(0, 12, 0, 282)
	tooltipDescBox.BackgroundColor3 = COLOR_MAIN_CREAM
	tooltipDescBox.BorderSizePixel = 0
	tooltipDescBox.Parent = itemCardContainer

	local lbStroke = Instance.new("UIStroke")
	lbStroke.Color = COLOR_BORDER_JADE
	lbStroke.Thickness = 1
	lbStroke.Parent = tooltipDescBox

	tooltipDesc = Instance.new("TextLabel")
	tooltipDesc.Size = UDim2.new(1, -12, 1, -12)
	tooltipDesc.Position = UDim2.new(0, 6, 0, 6)
	tooltipDesc.BackgroundTransparency = 1
	tooltipDesc.Font = UI_FONT
	tooltipDesc.TextSize = 14
	tooltipDesc.TextColor3 = COLOR_MAHOGANY
	tooltipDesc.TextWrapped = true
	tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
	tooltipDesc.TextYAlignment = Enum.TextYAlignment.Top
	tooltipDesc.Parent = tooltipDescBox

	actionPrimaryBtn = Instance.new("TextButton")
	actionPrimaryBtn.Size = UDim2.new(1, -24, 0, 44)
	actionPrimaryBtn.Position = UDim2.new(0, 12, 1, -104)
	actionPrimaryBtn.BackgroundColor3 = COLOR_BORDER_JADE
	actionPrimaryBtn.Text = "EQUIP"
	actionPrimaryBtn.TextColor3 = COLOR_MAIN_CREAM
	actionPrimaryBtn.Font = UI_FONT
	actionPrimaryBtn.TextSize = 22
	actionPrimaryBtn.Parent = itemCardContainer

	actionPrimaryBtn.MouseButton1Click:Connect(function()
		if selectedSlotIndex then
			InventoryController.UseSlot(selectedSlotIndex)
		end
	end)

	actionDropBtn = Instance.new("TextButton")
	actionDropBtn.Size = UDim2.new(1, -24, 0, 44)
	actionDropBtn.Position = UDim2.new(0, 12, 1, -52)
	actionDropBtn.BackgroundColor3 = COLOR_MAHOGANY
	actionDropBtn.Text = "DROP"
	actionDropBtn.TextColor3 = COLOR_MAIN_CREAM
	actionDropBtn.Font = UI_FONT
	actionDropBtn.TextSize = 22
	actionDropBtn.Parent = itemCardContainer

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
		slot.BackgroundColor3 = COLOR_MAIN_CREAM
		slot.BorderSizePixel = 0
		slot.Parent = itemGrid

		local stroke = Instance.new("UIStroke")
		stroke.Name = "RarityBorder"
		stroke.Thickness = 1.5
		stroke.Color = COLOR_BORDER_JADE
		stroke.Parent = slot

		local rarityHeader = Instance.new("TextLabel")
		rarityHeader.Name = "RarityHeader"
		rarityHeader.Size = UDim2.new(1, 0, 0, 18)
		rarityHeader.Position = UDim2.new(0, 0, 0, 0)
		rarityHeader.BackgroundColor3 = COLOR_BORDER_JADE
		rarityHeader.Text = ""
		rarityHeader.TextColor3 = COLOR_MAIN_CREAM
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
		quantity.TextColor3 = COLOR_TEXT_JADE
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

		btn.MouseButton1Click:Connect(function()
			InventoryController.InspectSlot(i)
		end)

		slotButtons[i] = slot
	end
end

function InventoryController.RefreshGrid()
	local usedCount = 0

	for i = 1, 60 do
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
					local rarityColor = RARITY_COLORS[itemDef.Rarity] or COLOR_BORDER_JADE
					-- MATCH SLOT BACKGROUND COLOR WITH RARITY TIER
					slotFrame.BackgroundColor3 = RARITY_SLOT_BG[itemDef.Rarity] or COLOR_MAIN_CREAM

					if icon then
						icon.Image = itemDef.Icon or ""
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
			slotFrame.BackgroundColor3 = COLOR_MAIN_CREAM
			isVisible = (activeCategoryFilter == "ALL" and currentSearchQuery == "")
		end

		slotFrame.Visible = isVisible
		if not slotData or not isVisible then
			if icon then icon.Visible = false end
			if quantity then quantity.Text = "" end
			if rarityHeader then rarityHeader.Visible = false end
			if stroke then stroke.Color = COLOR_BORDER_JADE end
		end
	end

	if capacityLabel then
		capacityLabel.Text = string.format("STORAGE  %d / 60 SLOTS", usedCount)
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
	tooltipRarityBadge.TextColor3 = RARITY_COLORS[itemDef.Rarity] or COLOR_TEXT_JADE
	tooltipDesc.Text = itemDef.Description
	tooltipIcon.Image = itemDef.Icon or ""
	tooltipIcon.Visible = true

	if itemDef.Category == "Consumable" then
		actionPrimaryBtn.Text = "USE"
		actionPrimaryBtn.BackgroundColor3 = COLOR_BORDER_JADE
	else
		actionPrimaryBtn.Text = "EQUIP"
		actionPrimaryBtn.BackgroundColor3 = COLOR_MAHOGANY
	end

	local statText = ""
	if itemDef.HealAmount and itemDef.HealAmount > 0 then
		statText ..= string.format("HEALTH RESTORED: +%d\n", itemDef.HealAmount)
	end
	if itemDef.QiAmount and itemDef.QiAmount > 0 then
		statText ..= string.format("SPIRIT QI RESTORED: +%d\n", itemDef.QiAmount)
	end
	if itemDef.StatBonus then
		if itemDef.StatBonus.AttackPower then
			statText ..= string.format("ATTACK POWER: +%d\n", itemDef.StatBonus.AttackPower)
		end
		if itemDef.StatBonus.MaxHP then
			statText ..= string.format("MAX HP BONUS: +%d\n", itemDef.StatBonus.MaxHP)
		end
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
	local maxQi = char:GetAttribute("MaxQi") or 800
	local clampedQi = math.min(currentQi, maxQi)
	local qiRatio = math.clamp(clampedQi / math.max(1, maxQi), 0, 1)
	qiBarFill.Size = UDim2.new(qiRatio, 0, 1, 0)
	qiBarText.Text = string.format("%d / %d", math.floor(clampedQi), math.floor(maxQi))

	realmTitleLabel.Text = "Foundation Establishment — Tier 2"
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