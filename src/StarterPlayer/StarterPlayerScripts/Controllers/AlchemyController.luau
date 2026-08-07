--!strict
--[[
    AlchemyController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AlchemyController.luau
    Client UI controller for ASCEND Alchemy & Spirit Pill Crafting Cauldron System.
    Light-Mode Flat 2D UI with crisp high-contrast charcoal text.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local AlchemyController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- BOLD, COMPACT FONT STYLE
local UI_FONT = Enum.Font.FredokaOne

-- LIGHT-MODE FLAT 2D PALETTE
local COLOR_LIGHT_MAIN     = Color3.fromRGB(248, 250, 249) -- #F8FAF9 Main Window
local COLOR_LIGHT_PANEL    = Color3.fromRGB(241, 245, 249) -- #F1F5F9 Sub-Panels
local COLOR_LIGHT_CARD     = Color3.fromRGB(255, 255, 255) -- #FFFFFF Cards & Slots
local COLOR_LIGHT_BORDER   = Color3.fromRGB(203, 213, 225) -- #CBD5E1 Edge Borders

local COLOR_TEXT_MAIN      = Color3.fromRGB(15, 23, 42)    -- #0F172A Deep Charcoal
local COLOR_TEXT_SUB       = Color3.fromRGB(100, 116, 139)  -- #64748B Muted Subtext
local COLOR_AZURE          = Color3.fromRGB(59, 130, 246)   -- #3B82F6 Sapphire Blue
local COLOR_HP_GREEN       = Color3.fromRGB(16, 185, 129)  -- #10B981 Emerald Green
local COLOR_ACTION_GOLD    = Color3.fromRGB(217, 119, 6)   -- #D97706 Warm Amber Gold
local COLOR_DANGER_RED     = Color3.fromRGB(225, 29, 72)   -- #E11D48 Carmine Red

local RARITY_COLORS = {
	Immortal  = Color3.fromRGB(225, 29, 72),
	Legendary = Color3.fromRGB(217, 119, 6),
	Epic      = Color3.fromRGB(147, 51, 234),
	Rare      = Color3.fromRGB(59, 130, 246),
	Uncommon  = Color3.fromRGB(16, 185, 129),
	Common    = Color3.fromRGB(100, 116, 139),
}

local alchemyGui: ScreenGui
local overlayBackdrop: Frame
local mainModal: Frame

-- 1. Recipe Book Elements
local recipeListFrame: ScrollingFrame
local recipeButtons: { [string]: Frame } = {}

-- 2. Cauldron Workspace Elements
local cauldronViewport: ViewportFrame
local successChanceText: TextLabel
local qiCostText: TextLabel
local durationText: TextLabel
local ingredientSlotContainer: Frame
local progressBarFill: Frame
local refineBtn: TextButton

-- 3. Outcome Inspection Elements
local outcomeCard: Frame
local outcomeTitle: TextLabel
local outcomeRarityBadge: TextLabel
local outcomeIcon: ImageLabel
local outcomeStatsText: TextLabel
local outcomeDescText: TextLabel

local selectedRecipeId: string = "SpiritHealingDan"
local isCrafting: boolean = false
local currentInventory: { [number]: any } = {}

local updateInventoryRemote: RemoteEvent
local alchemyActionRemote: RemoteEvent

function AlchemyController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	alchemyActionRemote = RemoteEvents.GetRemote("AlchemyAction")

	AlchemyController.BuildUI()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventory = inventoryData
		AlchemyController.RefreshWorkspace()
	end)

	alchemyActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" and payload.CraftResult then
			isCrafting = false
			progressBarFill.Size = UDim2.new(0, 0, 1, 0)
			refineBtn.Text = "REFINE SPIRIT DAN"
			refineBtn.BackgroundColor3 = COLOR_ACTION_GOLD

			if payload.CraftResult.Success then
				print("[AlchemyController] 🔥 Refinement Success! Crafted:", payload.CraftResult.PillName)
			else
				warn("[AlchemyController] 💥 Refinement Failed! Herbs ruined into ash.")
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.L then
			overlayBackdrop.Visible = not overlayBackdrop.Visible
			if overlayBackdrop.Visible then
				AlchemyController.RefreshWorkspace()
			end
		end
	end)

	print("[ASCEND] Light-Mode AlchemyController Initialized.")
end

function AlchemyController.GetRecipeTable(): { [string]: any }
	local raw = AlchemyConfig :: any
	local recipeMap: { [string]: any } = {}

	local targetTable = if (raw.Recipes and type(raw.Recipes) == "table") then raw.Recipes else raw
	if type(targetTable) == "table" then
		for key, val in pairs(targetTable) do
			if type(val) == "table" and val.OutputItemId then
				recipeMap[key] = val
			end
		end
	end

	return recipeMap
end

function AlchemyController.BuildUI()
	local oldGui = playerGui:FindFirstChild("AlchemyGui")
	if oldGui then oldGui:Destroy() end

	alchemyGui = Instance.new("ScreenGui")
	alchemyGui.Name = "AlchemyGui"
	alchemyGui.ResetOnSpawn = false
	alchemyGui.DisplayOrder = 25
	alchemyGui.Enabled = true
	alchemyGui.Parent = playerGui

	overlayBackdrop = Instance.new("Frame")
	overlayBackdrop.Name = "OverlayBackdrop"
	overlayBackdrop.Size = UDim2.new(1, 0, 1, 0)
	overlayBackdrop.BackgroundTransparency = 1
	overlayBackdrop.BorderSizePixel = 0
	overlayBackdrop.Visible = false
	overlayBackdrop.Parent = alchemyGui

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
	headerTitle.Text = "SPIRIT CAULDRON ALCHEMY"
	headerTitle.TextColor3 = COLOR_TEXT_MAIN
	headerTitle.Font = UI_FONT
	headerTitle.TextSize = 36
	headerTitle.Parent = mainModal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = RARITY_COLORS.Immortal
	closeBtn.Text = "X"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 20
	closeBtn.Parent = mainModal

	closeBtn.MouseButton1Click:Connect(function()
		overlayBackdrop.Visible = false
	end)

	local col1 = Instance.new("Frame")
	col1.Name = "Column1_RecipeBook"
	col1.Size = UDim2.new(0, 350, 1, -64)
	col1.Position = UDim2.new(0, 12, 0, 52)
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
	c1Header.Text = "RECIPE BOOK"
	c1Header.TextColor3 = COLOR_TEXT_MAIN
	c1Header.Font = UI_FONT
	c1Header.TextSize = 20
	c1Header.Parent = col1

	local c1HeaderStroke = Instance.new("UIStroke")
	c1HeaderStroke.Color = COLOR_LIGHT_BORDER
	c1HeaderStroke.Thickness = 1
	c1HeaderStroke.Parent = c1Header

	recipeListFrame = Instance.new("ScrollingFrame")
	recipeListFrame.Name = "RecipeListFrame"
	recipeListFrame.Size = UDim2.new(1, -16, 1, -52)
	recipeListFrame.Position = UDim2.new(0, 8, 0, 46)
	recipeListFrame.BackgroundTransparency = 1
	recipeListFrame.BorderSizePixel = 0
	recipeListFrame.ScrollBarThickness = 4
	recipeListFrame.ScrollBarImageColor3 = COLOR_AZURE
	recipeListFrame.Parent = col1

	local rListLayout = Instance.new("UIListLayout")
	rListLayout.FillDirection = Enum.FillDirection.Vertical
	rListLayout.Padding = UDim.new(0, 8)
	rListLayout.Parent = recipeListFrame

	local col2 = Instance.new("Frame")
	col2.Name = "Column2_CraftingWorkspace"
	col2.Size = UDim2.new(0, 580, 1, -64)
	col2.Position = UDim2.new(0, 372, 0, 52)
	col2.BackgroundColor3 = COLOR_LIGHT_PANEL
	col2.BorderSizePixel = 0
	col2.Parent = mainModal

	local col2Stroke = Instance.new("UIStroke")
	col2Stroke.Color = COLOR_LIGHT_BORDER
	col2Stroke.Thickness = 1.5
	col2Stroke.Parent = col2

	local c2Header = Instance.new("TextLabel")
	c2Header.Size = UDim2.new(1, 0, 0, 40)
	c2Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c2Header.Text = "CAULDRON CRAFTING WORKSPACE"
	c2Header.TextColor3 = COLOR_TEXT_MAIN
	c2Header.Font = UI_FONT
	c2Header.TextSize = 20
	c2Header.Parent = col2

	local c2HeaderStroke = Instance.new("UIStroke")
	c2HeaderStroke.Color = COLOR_LIGHT_BORDER
	c2HeaderStroke.Thickness = 1
	c2HeaderStroke.Parent = c2Header

	cauldronViewport = Instance.new("ViewportFrame")
	cauldronViewport.Name = "CauldronViewport"
	cauldronViewport.Size = UDim2.new(0, 260, 0, 280)
	cauldronViewport.Position = UDim2.new(0, 15, 0, 50)
	cauldronViewport.BackgroundColor3 = COLOR_LIGHT_CARD
	cauldronViewport.BorderSizePixel = 0
	cauldronViewport.Parent = col2

	local cvStroke = Instance.new("UIStroke")
	cvStroke.Color = COLOR_LIGHT_BORDER
	cvStroke.Thickness = 1.5
	cvStroke.Parent = cauldronViewport

	local paramsBox = Instance.new("Frame")
	paramsBox.Name = "BrewingParametersBox"
	paramsBox.Size = UDim2.new(0, 275, 0, 280)
	paramsBox.Position = UDim2.new(0, 288, 0, 50)
	paramsBox.BackgroundColor3 = COLOR_LIGHT_CARD
	paramsBox.BorderSizePixel = 0
	paramsBox.Parent = col2

	local pbStroke = Instance.new("UIStroke")
	pbStroke.Color = COLOR_LIGHT_BORDER
	pbStroke.Thickness = 1.5
	pbStroke.Parent = paramsBox

	local pbTitle = Instance.new("TextLabel")
	pbTitle.Size = UDim2.new(1, -20, 0, 32)
	pbTitle.Position = UDim2.new(0, 10, 0, 8)
	pbTitle.BackgroundTransparency = 1
	pbTitle.Text = "BREWING PARAMETERS"
	pbTitle.TextColor3 = COLOR_ACTION_GOLD
	pbTitle.Font = UI_FONT
	pbTitle.TextSize = 16
	pbTitle.TextXAlignment = Enum.TextXAlignment.Left
	pbTitle.Parent = paramsBox

	successChanceText = Instance.new("TextLabel")
	successChanceText.Size = UDim2.new(1, -20, 0, 28)
	successChanceText.Position = UDim2.new(0, 10, 0, 48)
	successChanceText.BackgroundTransparency = 1
	successChanceText.Text = "SUCCESS RATE: 85% CHANCE"
	successChanceText.TextColor3 = COLOR_HP_GREEN
	successChanceText.Font = UI_FONT
	successChanceText.TextSize = 15
	successChanceText.TextXAlignment = Enum.TextXAlignment.Left
	successChanceText.Parent = paramsBox

	qiCostText = Instance.new("TextLabel")
	qiCostText.Size = UDim2.new(1, -20, 0, 28)
	qiCostText.Position = UDim2.new(0, 10, 0, 84)
	qiCostText.BackgroundTransparency = 1
	qiCostText.Text = "QI COST: 30 SPIRIT QI"
	qiCostText.TextColor3 = COLOR_AZURE
	qiCostText.Font = UI_FONT
	qiCostText.TextSize = 15
	qiCostText.TextXAlignment = Enum.TextXAlignment.Left
	qiCostText.Parent = paramsBox

	durationText = Instance.new("TextLabel")
	durationText.Size = UDim2.new(1, -20, 0, 28)
	durationText.Position = UDim2.new(0, 10, 0, 120)
	durationText.BackgroundTransparency = 1
	durationText.Text = "CRAFTING DURATION: 3.0s"
	durationText.TextColor3 = COLOR_TEXT_MAIN
	durationText.Font = UI_FONT
	durationText.TextSize = 15
	durationText.TextXAlignment = Enum.TextXAlignment.Left
	durationText.Parent = paramsBox

	local ingLabel = Instance.new("TextLabel")
	ingLabel.Size = UDim2.new(1, -30, 0, 24)
	ingLabel.Position = UDim2.new(0, 15, 0, 342)
	ingLabel.BackgroundTransparency = 1
	ingLabel.Text = "INGREDIENT REQUIREMENT SLOTS"
	ingLabel.TextColor3 = COLOR_TEXT_SUB
	ingLabel.Font = UI_FONT
	ingLabel.TextSize = 14
	ingLabel.TextXAlignment = Enum.TextXAlignment.Left
	ingLabel.Parent = col2

	ingredientSlotContainer = Instance.new("Frame")
	ingredientSlotContainer.Name = "IngredientSlotContainer"
	ingredientSlotContainer.Size = UDim2.new(1, -30, 0, 120)
	ingredientSlotContainer.Position = UDim2.new(0, 15, 0, 370)
	ingredientSlotContainer.BackgroundTransparency = 1
	ingredientSlotContainer.Parent = col2

	local ingLayout = Instance.new("UIListLayout")
	ingLayout.FillDirection = Enum.FillDirection.Horizontal
	ingLayout.Padding = UDim.new(0, 12)
	ingLayout.Parent = ingredientSlotContainer

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBarBg"
	progressBg.Size = UDim2.new(1, -30, 0, 24)
	progressBg.Position = UDim2.new(0, 15, 0, 505)
	progressBg.BackgroundColor3 = COLOR_LIGHT_CARD
	progressBg.BorderSizePixel = 0
	progressBg.Parent = col2

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = COLOR_LIGHT_BORDER
	pStroke.Thickness = 1.5
	pStroke.Parent = progressBg

	progressBarFill = Instance.new("Frame")
	progressBarFill.Name = "ProgressBarFill"
	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	progressBarFill.BackgroundColor3 = COLOR_HP_GREEN
	progressBarFill.BorderSizePixel = 0
	progressBarFill.Parent = progressBg

	refineBtn = Instance.new("TextButton")
	refineBtn.Name = "RefineButton"
	refineBtn.Size = UDim2.new(1, -30, 0, 52)
	refineBtn.Position = UDim2.new(0, 15, 0, 542)
	refineBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	refineBtn.Text = "REFINE SPIRIT DAN"
	refineBtn.TextColor3 = COLOR_LIGHT_MAIN
	refineBtn.Font = UI_FONT
	refineBtn.TextSize = 22
	refineBtn.Parent = col2

	refineBtn.MouseButton1Click:Connect(function()
		AlchemyController.StartCrafting()
	end)

	outcomeCard = Instance.new("Frame")
	outcomeCard.Name = "Column3_OutcomeInspection"
	outcomeCard.Size = UDim2.new(0, 290, 1, -64)
	outcomeCard.Position = UDim2.new(0, 958, 0, 52)
	outcomeCard.BackgroundColor3 = COLOR_LIGHT_PANEL
	outcomeCard.BorderSizePixel = 0
	outcomeCard.Parent = mainModal

	local col3Stroke = Instance.new("UIStroke")
	col3Stroke.Color = COLOR_LIGHT_BORDER
	col3Stroke.Thickness = 1.5
	col3Stroke.Parent = outcomeCard

	local c3Header = Instance.new("TextLabel")
	c3Header.Size = UDim2.new(1, 0, 0, 40)
	c3Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c3Header.Text = "OUTCOME PILL INSPECTION"
	c3Header.TextColor3 = COLOR_TEXT_MAIN
	c3Header.Font = UI_FONT
	c3Header.TextSize = 18
	c3Header.Parent = outcomeCard

	local c3HeaderStroke = Instance.new("UIStroke")
	c3HeaderStroke.Color = COLOR_LIGHT_BORDER
	c3HeaderStroke.Thickness = 1
	c3HeaderStroke.Parent = c3Header

	outcomeTitle = Instance.new("TextLabel")
	outcomeTitle.Size = UDim2.new(1, -20, 0, 32)
	outcomeTitle.Position = UDim2.new(0, 10, 0, 48)
	outcomeTitle.BackgroundTransparency = 1
	outcomeTitle.Font = UI_FONT
	outcomeTitle.TextSize = 22
	outcomeTitle.TextColor3 = COLOR_TEXT_MAIN
	outcomeTitle.TextXAlignment = Enum.TextXAlignment.Center
	outcomeTitle.Parent = outcomeCard

	outcomeRarityBadge = Instance.new("TextLabel")
	outcomeRarityBadge.Size = UDim2.new(1, -20, 0, 22)
	outcomeRarityBadge.Position = UDim2.new(0, 10, 0, 80)
	outcomeRarityBadge.BackgroundTransparency = 1
	outcomeRarityBadge.Font = UI_FONT
	outcomeRarityBadge.TextSize = 15
	outcomeRarityBadge.TextColor3 = RARITY_COLORS.Uncommon
	outcomeRarityBadge.Text = "UNCOMMON SPIRIT DAN"
	outcomeRarityBadge.TextXAlignment = Enum.TextXAlignment.Center
	outcomeRarityBadge.Parent = outcomeCard

	local iconBox = Instance.new("Frame")
	iconBox.Size = UDim2.new(0, 110, 0, 110)
	iconBox.Position = UDim2.new(0.5, -55, 0, 110)
	iconBox.BackgroundColor3 = COLOR_LIGHT_CARD
	iconBox.BorderSizePixel = 0
	iconBox.Parent = outcomeCard

	local ibStroke = Instance.new("UIStroke")
	ibStroke.Color = COLOR_LIGHT_BORDER
	ibStroke.Thickness = 1.5
	ibStroke.Parent = iconBox

	outcomeIcon = Instance.new("ImageLabel")
	outcomeIcon.Size = UDim2.new(1, -12, 1, -12)
	outcomeIcon.Position = UDim2.new(0, 6, 0, 6)
	outcomeIcon.BackgroundTransparency = 1
	outcomeIcon.ScaleType = Enum.ScaleType.Fit
	outcomeIcon.Parent = iconBox

	local statBox = Instance.new("Frame")
	statBox.Size = UDim2.new(1, -24, 0, 75)
	statBox.Position = UDim2.new(0, 12, 0, 230)
	statBox.BackgroundColor3 = COLOR_LIGHT_CARD
	statBox.BorderSizePixel = 0
	statBox.Parent = outcomeCard

	local sbBoxStroke = Instance.new("UIStroke")
	sbBoxStroke.Color = COLOR_LIGHT_BORDER
	sbBoxStroke.Thickness = 1
	sbBoxStroke.Parent = statBox

	outcomeStatsText = Instance.new("TextLabel")
	outcomeStatsText.Size = UDim2.new(1, -16, 1, -8)
	outcomeStatsText.Position = UDim2.new(0, 8, 0, 4)
	outcomeStatsText.BackgroundTransparency = 1
	outcomeStatsText.Font = UI_FONT
	outcomeStatsText.TextSize = 16
	outcomeStatsText.TextColor3 = COLOR_HP_GREEN
	outcomeStatsText.TextWrapped = true
	outcomeStatsText.TextXAlignment = Enum.TextXAlignment.Left
	outcomeStatsText.Parent = statBox

	local descBox = Instance.new("Frame")
	descBox.Size = UDim2.new(1, -24, 0, 280)
	descBox.Position = UDim2.new(0, 12, 0, 315)
	descBox.BackgroundColor3 = COLOR_LIGHT_CARD
	descBox.BorderSizePixel = 0
	descBox.Parent = outcomeCard

	local dbStroke = Instance.new("UIStroke")
	dbStroke.Color = COLOR_LIGHT_BORDER
	dbStroke.Thickness = 1
	dbStroke.Parent = descBox

	local dbPadding = Instance.new("UIPadding")
	dbPadding.PaddingTop = UDim.new(0, 8)
	dbPadding.PaddingBottom = UDim.new(0, 8)
	dbPadding.PaddingLeft = UDim.new(0, 8)
	dbPadding.PaddingRight = UDim.new(0, 8)
	dbPadding.Parent = descBox

	outcomeDescText = Instance.new("TextLabel")
	outcomeDescText.Size = UDim2.new(1, 0, 1, 0)
	outcomeDescText.BackgroundTransparency = 1
	outcomeDescText.Font = UI_FONT
	outcomeDescText.TextSize = 15
	outcomeDescText.TextColor3 = COLOR_TEXT_SUB
	outcomeDescText.TextWrapped = true
	outcomeDescText.TextXAlignment = Enum.TextXAlignment.Left
	outcomeDescText.TextYAlignment = Enum.TextYAlignment.Top
	outcomeDescText.Parent = descBox

	AlchemyController.SetupRecipeList()
	AlchemyController.RefreshWorkspace()
end

function AlchemyController.SetupRecipeList()
	local recipes = AlchemyController.GetRecipeTable()

	for recipeId, recipeDef in pairs(recipes) do
		if type(recipeDef) ~= "table" or not recipeDef.OutputItemId then continue end

		local pillDef = ItemConfig[recipeDef.OutputItemId]
		if not pillDef then continue end

		local card = Instance.new("Frame")
		card.Name = "RecipeCard_" .. recipeId
		card.Size = UDim2.new(1, 0, 0, 72)
		card.BackgroundColor3 = COLOR_LIGHT_CARD
		card.BorderSizePixel = 0
		card.Parent = recipeListFrame

		local stroke = Instance.new("UIStroke")
		stroke.Name = "Stroke"
		stroke.Color = COLOR_LIGHT_BORDER
		stroke.Thickness = 1.5
		stroke.Parent = card

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 48, 0, 48)
		icon.Position = UDim2.new(0, 8, 0.5, -24)
		icon.BackgroundTransparency = 1
        icon.Image = pillDef.Icon or ""
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = card

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(1, -64, 0, 24)
		nameLabel.Position = UDim2.new(0, 64, 0, 8)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = pillDef.Name
		nameLabel.TextColor3 = COLOR_TEXT_MAIN
		nameLabel.Font = UI_FONT
		nameLabel.TextSize = 16
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = card

		local realmBadge = Instance.new("TextLabel")
		realmBadge.Size = UDim2.new(1, -64, 0, 20)
		realmBadge.Position = UDim2.new(0, 64, 0, 34)
		realmBadge.BackgroundTransparency = 1
		realmBadge.Text = tostring(recipeDef.RequiredRealm or "QiCondensation"):upper()
		realmBadge.TextColor3 = COLOR_ACTION_GOLD
		realmBadge.Font = UI_FONT
		realmBadge.TextSize = 12
		realmBadge.TextXAlignment = Enum.TextXAlignment.Left
		realmBadge.Parent = card

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = card

		btn.MouseButton1Click:Connect(function()
			selectedRecipeId = recipeId
			AlchemyController.RefreshWorkspace()
		end)

		recipeButtons[recipeId] = card
	end
end

function AlchemyController.RefreshWorkspace()
	for rId, card in pairs(recipeButtons) do
		local stroke = card:FindFirstChildOfClass("UIStroke")
		if stroke then
			if rId == selectedRecipeId then
				stroke.Color = COLOR_AZURE
				stroke.Thickness = 2.5
				card.BackgroundColor3 = COLOR_LIGHT_PANEL
			else
				stroke.Color = COLOR_LIGHT_BORDER
				stroke.Thickness = 1.5
				card.BackgroundColor3 = COLOR_LIGHT_CARD
			end
		end
	end

	local recipes = AlchemyController.GetRecipeTable()
	local recipeDef = recipes[selectedRecipeId]
	if not recipeDef or type(recipeDef) ~= "table" then return end

	local pillDef = ItemConfig[recipeDef.OutputItemId]
	if not pillDef then return end

	successChanceText.Text = string.format("SUCCESS RATE: %d%% CHANCE", math.round((recipeDef.SuccessRate or 0.85) * 100))
	qiCostText.Text = string.format("QI COST: %d SPIRIT QI", recipeDef.QiCost or 30)
	durationText.Text = string.format("CRAFTING DURATION: %.1fs", recipeDef.CraftingTime or 3.0)

	outcomeTitle.Text = pillDef.Name
	outcomeRarityBadge.Text = string.format("%s %s", pillDef.Rarity:upper(), pillDef.Category:upper())
	outcomeRarityBadge.TextColor3 = RARITY_COLORS[pillDef.Rarity] or COLOR_TEXT_MAIN
	outcomeIcon.Image = pillDef.Icon or ""
	outcomeDescText.Text = pillDef.Description

	local statText = ""
	if pillDef.HealAmount and pillDef.HealAmount > 0 then
		statText ..= string.format("HEALTH RESTORED: +%d\n", pillDef.HealAmount)
	end
	if pillDef.QiAmount and pillDef.QiAmount > 0 then
		statText ..= string.format("SPIRIT QI RESTORED: +%d\n", pillDef.QiAmount)
	end
	outcomeStatsText.Text = statText

	for _, child in ipairs(ingredientSlotContainer:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	local ingredients = recipeDef.Ingredients or {}
	for _, ing in ipairs(ingredients) do
		local herbDef = ItemConfig[ing.ItemId]
		if not herbDef then continue end

		local ownedCount = AlchemyController.GetInventoryItemCount(ing.ItemId)

		local slot = Instance.new("Frame")
		slot.Size = UDim2.new(0, 110, 0, 110)
		slot.BackgroundColor3 = COLOR_LIGHT_CARD
		slot.BorderSizePixel = 0
		slot.Parent = ingredientSlotContainer

		local stroke = Instance.new("UIStroke")
		stroke.Color = if ownedCount >= ing.Count then COLOR_HP_GREEN else COLOR_DANGER_RED
		stroke.Thickness = 1.5
		stroke.Parent = slot

		local icon = Instance.new("ImageLabel")
		icon.Size = UDim2.new(0, 56, 0, 56)
		icon.Position = UDim2.new(0.5, -28, 0, 10)
		icon.BackgroundTransparency = 1
		icon.Image = herbDef.Icon or ""
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Parent = slot

		local countLabel = Instance.new("TextLabel")
		countLabel.Size = UDim2.new(1, -4, 0, 32)
		countLabel.Position = UDim2.new(0, 2, 0, 72)
		countLabel.BackgroundTransparency = 1
		countLabel.Text = string.format("%d / %d Owned", ownedCount, ing.Count)
		countLabel.TextColor3 = if ownedCount >= ing.Count then COLOR_TEXT_MAIN else COLOR_DANGER_RED
		countLabel.Font = UI_FONT
		countLabel.TextSize = 12
		countLabel.TextWrapped = true
		countLabel.Parent = slot
	end
end

function AlchemyController.GetInventoryItemCount(itemId: string): number
	local total = 0
	for _, slotData in pairs(currentInventory) do
		if slotData and slotData.ItemId == itemId then
			total += slotData.Count
		end
	end
	return total
end

function AlchemyController.StartCrafting()
	if isCrafting then return end

	local recipes = AlchemyController.GetRecipeTable()
	local recipeDef = recipes[selectedRecipeId]
	if not recipeDef or type(recipeDef) ~= "table" then return end

	local ingredients = recipeDef.Ingredients or {}
	for _, ing in ipairs(ingredients) do
		local owned = AlchemyController.GetInventoryItemCount(ing.ItemId)
		if owned < ing.Count then
			warn("[AlchemyController] Cannot craft! Insufficient ingredient:", ing.ItemId)
			return
		end
	end

	isCrafting = true
	refineBtn.Text = "BREWING SPIRIT DAN..."
	refineBtn.BackgroundColor3 = COLOR_AZURE

	progressBarFill.Size = UDim2.new(0, 0, 1, 0)
	local tween = TweenService:Create(progressBarFill, TweenInfo.new(recipeDef.CraftingTime or 3.0, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 1, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		alchemyActionRemote:FireServer({
			Action = "CraftPill",
			RecipeId = selectedRecipeId,
		})
	end)
end

return AlchemyController