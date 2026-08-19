--!strict
--[[
    AlchemyController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AlchemyController.luau
    Client UI controller for Manual Herb Combination Alchemy with 2D PNG Icon Cards.
    Theme: Dark Obsidian (#111827), Antique Gold (#8B6B32), and Jade Cultivation (#10B981).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local HUDController = require(script.Parent.HUDController)

local AlchemyController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI_FONT = Enum.Font.FredokaOne
local T = UIAssets.Theme

-- UNIFIED DARK OBSIDIAN & ANTIQUE GOLD PALETTE
local COLOR_LIGHT_MAIN   = T.DeepBackground   -- Color3.fromHex("#111827")
local COLOR_LIGHT_PANEL  = T.SecondarySurface -- Color3.fromHex("#1C2638")
local COLOR_LIGHT_CARD   = T.RaisedSurface    -- Color3.fromHex("#273246")
local COLOR_LIGHT_BORDER = T.MainBorder       -- Color3.fromHex("#8B6B32")

local COLOR_TEXT_MAIN    = T.PrimaryText      -- Color3.fromHex("#F1E8D2")
local COLOR_TEXT_SUB     = T.SecondaryText    -- Color3.fromHex("#A9A99F")
local COLOR_AZURE_BLUE   = T.SpiritBlue       -- Color3.fromHex("#3B82F6")
local COLOR_HP_GREEN     = T.JadeAccent       -- Color3.fromHex("#10B981")
local COLOR_ACTION_GOLD  = T.HighlightBorder  -- Color3.fromHex("#C49A4A")
local COLOR_DANGER_RED   = T.Vermilion        -- Color3.fromHex("#E63946")

local alchemyGui: ScreenGui
local overlayBackdrop: Frame
local mainModal: Frame
local herbPickerGrid: ScrollingFrame

local masteryRankLabel: TextLabel
local masteryExpFill: Frame
local masteryExpText: TextLabel

local cauldronSlots: { [number]: { SlotIdx: number?, ItemId: string? } } = {
	[1] = { SlotIdx = nil, ItemId = nil },
	[2] = { SlotIdx = nil, ItemId = nil },
	[3] = { SlotIdx = nil, ItemId = nil },
}

local cauldronSlotButtons: { [number]: Frame } = {}
local currentInventoryData: { [number]: any } = {}

local matchedFormulaLabel: TextLabel
local successRateLabel: TextLabel
local qualityTextLabel: TextLabel
local qiCostLabel: TextLabel
local statusMessageLabel: TextLabel
local refineButton: TextButton

local flameGaugeFrame: Frame
local flameNeedle: Frame
local flameStatusText: TextLabel

local isRefining: boolean = false
local minigameActive: boolean = false
local needlePosition: number = 0
local needleDirection: number = 1
local flamePrecisionScore: number = 0.5

local alchemyActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent

function AlchemyController.Init()
	alchemyActionRemote = RemoteEvents.GetRemote("AlchemyAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	AlchemyController.BuildUI()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventoryData = inventoryData or {}
		AlchemyController.RefreshHerbPicker()
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
		if playerWhoTriggered ~= player then return end

		if prompt.Name == "CauldronPrompt" or (prompt.Parent and (prompt.Parent.Name == "SpiritCauldron" or prompt.Parent:GetAttribute("Cauldron"))) then
			overlayBackdrop.Visible = true
			local inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")
			inventoryActionRemote:FireServer({ Action = "RequestSync" })
			alchemyActionRemote:FireServer({ Action = "RequestMasterySync" })
			AlchemyController.RefreshHerbPicker()
			AlchemyController.UpdateMetrics()
		end
	end)

	alchemyActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "SyncMastery" then
			AlchemyController.UpdateMasteryBar(payload.Exp or 0, payload.Level or 1)
		elseif payload.Action == "RefineResult" then
			isRefining = false
			minigameActive = false
			flameGaugeFrame.Visible = false
			refineButton.Text = "REFINE SPIRIT DAN"
			refineButton.BackgroundColor3 = COLOR_ACTION_GOLD

			for i = 1, 3 do
				cauldronSlots[i] = { SlotIdx = nil, ItemId = nil }
			end
			AlchemyController.UpdateCauldronSlotDisplay()
			AlchemyController.UpdateMetrics()
			AlchemyController.RefreshHerbPicker()

			if payload.TotalExp and payload.Level then
				AlchemyController.UpdateMasteryBar(payload.TotalExp, payload.Level)
			end

			if statusMessageLabel then
				statusMessageLabel.Text = payload.Message or ""
				statusMessageLabel.TextColor3 = if payload.Success then COLOR_HP_GREEN else COLOR_DANGER_RED
			end

			if payload.Success and payload.ResultItemId then
				HUDController.ShowItemToast(payload.ResultItemId, 1, payload.QualityText)
			end
		end
	end)

	RunService.RenderStepped:Connect(function(deltaTime: number)
		if minigameActive then
			needlePosition += deltaTime * 2.2 * needleDirection
			if needlePosition >= 1 then
				needlePosition = 1
				needleDirection = -1
			elseif needlePosition <= 0 then
				needlePosition = 0
				needleDirection = 1
			end

			flameNeedle.Position = UDim2.new(needlePosition, -2, 0, 0)

			if needlePosition >= 0.40 and needlePosition <= 0.60 then
				flameStatusText.Text = "OPTIMAL QI FLAME! (PRESS LOCK)"
				flameStatusText.TextColor3 = COLOR_HP_GREEN
			elseif needlePosition < 0.20 or needlePosition > 0.80 then
				flameStatusText.Text = "FLAME WEAK / OVERHEATING"
				flameStatusText.TextColor3 = COLOR_DANGER_RED
			else
				flameStatusText.Text = "WARM QI HEAT"
				flameStatusText.TextColor3 = COLOR_ACTION_GOLD
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not minigameActive then return end

		if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
			AlchemyController.LockFlamePrecision()
		end
	end)

	print("[ASCEND] AlchemyController Initialized with Unified Dark Obsidian Theme.")
end

function AlchemyController.BuildUI()
	local oldGui = playerGui:FindFirstChild("SpiritCauldronAlchemyGui")
	if oldGui then oldGui:Destroy() end

	alchemyGui = Instance.new("ScreenGui")
	alchemyGui.Name = "SpiritCauldronAlchemyGui"
	alchemyGui.ResetOnSpawn = false
	alchemyGui.DisplayOrder = 20
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
	mainModal.Size = UDim2.new(0, 1150, 0, 660)
	mainModal.Position = UDim2.new(0.5, -575, 0.5, -330)
	mainModal.BackgroundColor3 = COLOR_LIGHT_MAIN
	mainModal.BorderSizePixel = 0
	mainModal.Parent = overlayBackdrop

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = COLOR_LIGHT_BORDER
	mStroke.Thickness = 1.5
	mStroke.Parent = mainModal

	local headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, 0, 0, 42)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SPIRIT CAULDRON ALCHEMY"
	headerTitle.TextColor3 = COLOR_TEXT_MAIN
	headerTitle.Font = UI_FONT
	headerTitle.TextSize = 28
	headerTitle.Parent = mainModal

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0, 8)
	closeBtn.BackgroundColor3 = COLOR_DANGER_RED
	closeBtn.Text = "X"
	closeBtn.TextColor3 = COLOR_TEXT_MAIN
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 20
	closeBtn.Parent = mainModal

	closeBtn.MouseButton1Click:Connect(function()
		overlayBackdrop.Visible = false
		minigameActive = false
		flameGaugeFrame.Visible = false
	end)

	-- MASTERY BAR
	local masteryBarFrame = Instance.new("Frame")
	masteryBarFrame.Size = UDim2.new(1, -88, 0, 28)
	masteryBarFrame.Position = UDim2.new(0, 12, 0, 44)
	masteryBarFrame.BackgroundColor3 = COLOR_LIGHT_PANEL
	masteryBarFrame.BorderSizePixel = 0
	masteryBarFrame.Parent = mainModal

	local mbStroke = Instance.new("UIStroke")
	mbStroke.Color = COLOR_LIGHT_BORDER
	mbStroke.Thickness = 1
	mbStroke.Parent = masteryBarFrame

	masteryRankLabel = Instance.new("TextLabel")
	masteryRankLabel.Size = UDim2.new(0, 240, 1, 0)
	masteryRankLabel.Position = UDim2.new(0, 10, 0, 0)
	masteryRankLabel.BackgroundTransparency = 1
	masteryRankLabel.Text = "RANK 1 — APPRENTICE ALCHEMIST"
	masteryRankLabel.TextColor3 = COLOR_TEXT_MAIN
	masteryRankLabel.Font = UI_FONT
	masteryRankLabel.TextSize = 12
	masteryRankLabel.TextXAlignment = Enum.TextXAlignment.Left
	masteryRankLabel.Parent = masteryBarFrame

	local expBg = Instance.new("Frame")
	expBg.Size = UDim2.new(1, -260, 0, 18)
	expBg.Position = UDim2.new(0, 250, 0, 5)
	expBg.BackgroundColor3 = COLOR_LIGHT_CARD
	expBg.BorderSizePixel = 0
	expBg.Parent = masteryBarFrame

	local expStroke = Instance.new("UIStroke")
	expStroke.Color = COLOR_LIGHT_BORDER
	expStroke.Thickness = 1
	expStroke.Parent = expBg

	masteryExpFill = Instance.new("Frame")
	masteryExpFill.Size = UDim2.new(0, 0, 1, 0)
	masteryExpFill.BackgroundColor3 = COLOR_ACTION_GOLD
	masteryExpFill.BorderSizePixel = 0
	masteryExpFill.Parent = expBg

	masteryExpText = Instance.new("TextLabel")
	masteryExpText.Size = UDim2.new(1, 0, 1, 0)
	masteryExpText.BackgroundTransparency = 1
	masteryExpText.Text = "0 / 100 EXP"
	masteryExpText.TextColor3 = COLOR_TEXT_MAIN
	masteryExpText.Font = UI_FONT
	masteryExpText.TextSize = 11
	masteryExpText.ZIndex = 5
	masteryExpText.Parent = expBg

	-- COLUMN 1: HERB PICKER
	local col1 = Instance.new("Frame")
	col1.Size = UDim2.new(0, 320, 1, -84)
	col1.Position = UDim2.new(0, 12, 0, 76)
	col1.BackgroundColor3 = COLOR_LIGHT_PANEL
	col1.BorderSizePixel = 0
	col1.Parent = mainModal

	local col1Stroke = Instance.new("UIStroke")
	col1Stroke.Color = COLOR_LIGHT_BORDER
	col1Stroke.Thickness = 1.5
	col1Stroke.Parent = col1

	local c1Header = Instance.new("TextLabel")
	c1Header.Size = UDim2.new(1, 0, 0, 38)
	c1Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c1Header.Text = "SELECT HERBS FROM POUCH"
	c1Header.TextColor3 = COLOR_TEXT_MAIN
	c1Header.Font = UI_FONT
	c1Header.TextSize = 15
	c1Header.Parent = col1

	herbPickerGrid = Instance.new("ScrollingFrame")
	herbPickerGrid.Size = UDim2.new(1, -16, 1, -52)
	herbPickerGrid.Position = UDim2.new(0, 8, 0, 44)
	herbPickerGrid.BackgroundTransparency = 1
	herbPickerGrid.BorderSizePixel = 0
	herbPickerGrid.ScrollBarThickness = 4
	herbPickerGrid.ScrollBarImageColor3 = COLOR_AZURE_BLUE
	herbPickerGrid.Parent = col1

	-- COLUMN 2: WORKSPACE
	local col2 = Instance.new("Frame")
	col2.Name = "Column2_CauldronWorkspace"
	col2.Size = UDim2.new(0, 480, 1, -84)
	col2.Position = UDim2.new(0, 344, 0, 76)
	col2.BackgroundColor3 = COLOR_LIGHT_PANEL
	col2.BorderSizePixel = 0
	col2.Parent = mainModal

	local col2Stroke = Instance.new("UIStroke")
	col2Stroke.Color = COLOR_LIGHT_BORDER
	col2Stroke.Thickness = 1.5
	col2Stroke.Parent = col2

	local c2Header = Instance.new("TextLabel")
	c2Header.Size = UDim2.new(1, 0, 0, 38)
	c2Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c2Header.Text = "CAULDRON COMBINATION SLOTS"
	c2Header.TextColor3 = COLOR_TEXT_MAIN
	c2Header.Font = UI_FONT
	c2Header.TextSize = 16
	c2Header.Parent = col2

	local slotContainer = Instance.new("Frame")
	slotContainer.Size = UDim2.new(1, -24, 0, 110)
	slotContainer.Position = UDim2.new(0, 12, 0, 48)
	slotContainer.BackgroundColor3 = COLOR_LIGHT_CARD
	slotContainer.BorderSizePixel = 0
	slotContainer.Parent = col2

	local scStroke = Instance.new("UIStroke")
	scStroke.Color = COLOR_LIGHT_BORDER
	scStroke.Thickness = 1
	scStroke.Parent = slotContainer

	local slotLayout = Instance.new("UIListLayout")
	slotLayout.FillDirection = Enum.FillDirection.Horizontal
	slotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	slotLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	slotLayout.Padding = UDim.new(0, 18)
	slotLayout.Parent = slotContainer

	for i = 1, 3 do
		local slotFrame = Instance.new("Frame")
		slotFrame.Name = "CauldronSlot_" .. i
		slotFrame.Size = UDim2.new(0, 120, 0, 90)
		slotFrame.BackgroundColor3 = COLOR_LIGHT_PANEL
		slotFrame.BorderSizePixel = 0
		slotFrame.Parent = slotContainer

		local sStroke = Instance.new("UIStroke")
		sStroke.Name = "SlotStroke"
		sStroke.Color = COLOR_LIGHT_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slotFrame

		local slotTitle = Instance.new("TextLabel")
		slotTitle.Name = "SlotTitle"
		slotTitle.Size = UDim2.new(1, 0, 0, 18)
		slotTitle.BackgroundTransparency = 1
		slotTitle.Text = "HERB SLOT " .. i
		slotTitle.TextColor3 = COLOR_TEXT_SUB
		slotTitle.Font = UI_FONT
		slotTitle.TextSize = 10
		slotTitle.Parent = slotFrame

		local slotIcon = Instance.new("ImageLabel")
		slotIcon.Name = "SlotIcon"
		slotIcon.Size = UDim2.new(0, 48, 0, 48)
		slotIcon.Position = UDim2.new(0.5, -24, 0, 20)
		slotIcon.BackgroundTransparency = 1
		slotIcon.ScaleType = Enum.ScaleType.Fit
		slotIcon.Visible = false
		slotIcon.Parent = slotFrame

		local herbNameLbl = Instance.new("TextLabel")
		herbNameLbl.Name = "HerbNameLabel"
		herbNameLbl.Size = UDim2.new(1, -8, 0, 18)
		herbNameLbl.Position = UDim2.new(0, 4, 1, -20)
		herbNameLbl.BackgroundTransparency = 1
		herbNameLbl.Text = "+ Add Herb"
		herbNameLbl.TextColor3 = COLOR_TEXT_SUB
		herbNameLbl.Font = UI_FONT
		herbNameLbl.TextSize = 10
		herbNameLbl.TextWrapped = true
		herbNameLbl.Parent = slotFrame

		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(1, 0, 1, 0)
		btn.BackgroundTransparency = 1
		btn.Text = ""
		btn.Parent = slotFrame

		btn.MouseButton1Click:Connect(function()
			cauldronSlots[i] = { SlotIdx = nil, ItemId = nil }
			AlchemyController.UpdateCauldronSlotDisplay()
			AlchemyController.UpdateMetrics()
		end)

		cauldronSlotButtons[i] = slotFrame
	end

	-- METRICS BOX
	local metricsBox = Instance.new("Frame")
	metricsBox.Size = UDim2.new(1, -24, 0, 160)
	metricsBox.Position = UDim2.new(0, 12, 0, 168)
	metricsBox.BackgroundColor3 = COLOR_LIGHT_CARD
	metricsBox.BorderSizePixel = 0
	metricsBox.Parent = col2

	local mbBoxStroke = Instance.new("UIStroke")
	mbBoxStroke.Color = COLOR_LIGHT_BORDER
	mbBoxStroke.Thickness = 1
	mbBoxStroke.Parent = metricsBox

	matchedFormulaLabel = Instance.new("TextLabel")
	matchedFormulaLabel.Size = UDim2.new(1, -20, 0, 28)
	matchedFormulaLabel.Position = UDim2.new(0, 10, 0, 8)
	matchedFormulaLabel.BackgroundTransparency = 1
	matchedFormulaLabel.Text = "MATCHED FORMULA: NONE"
	matchedFormulaLabel.TextColor3 = COLOR_TEXT_MAIN
	matchedFormulaLabel.Font = UI_FONT
	matchedFormulaLabel.TextSize = 14
	matchedFormulaLabel.TextXAlignment = Enum.TextXAlignment.Left
	matchedFormulaLabel.Parent = metricsBox

	successRateLabel = Instance.new("TextLabel")
	successRateLabel.Size = UDim2.new(1, -20, 0, 26)
	successRateLabel.Position = UDim2.new(0, 10, 0, 40)
	successRateLabel.BackgroundTransparency = 1
	successRateLabel.Text = "ESTIMATED SUCCESS: 0%"
	successRateLabel.TextColor3 = COLOR_HP_GREEN
	successRateLabel.Font = UI_FONT
	successRateLabel.TextSize = 13
	successRateLabel.TextXAlignment = Enum.TextXAlignment.Left
	successRateLabel.Parent = metricsBox

	qualityTextLabel = Instance.new("TextLabel")
	qualityTextLabel.Size = UDim2.new(1, -20, 0, 26)
	qualityTextLabel.Position = UDim2.new(0, 10, 0, 70)
	qualityTextLabel.BackgroundTransparency = 1
	qualityTextLabel.Text = "EXPECTED QUALITY: STANDARD"
	qualityTextLabel.TextColor3 = COLOR_ACTION_GOLD
	qualityTextLabel.Font = UI_FONT
	qualityTextLabel.TextSize = 13
	qualityTextLabel.TextXAlignment = Enum.TextXAlignment.Left
	qualityTextLabel.Parent = metricsBox

	qiCostLabel = Instance.new("TextLabel")
	qiCostLabel.Size = UDim2.new(1, -20, 0, 26)
	qiCostLabel.Position = UDim2.new(0, 10, 0, 100)
	qiCostLabel.BackgroundTransparency = 1
	qiCostLabel.Text = "REQUIRED QI: 0 SPIRIT QI"
	qiCostLabel.TextColor3 = COLOR_AZURE_BLUE
	qiCostLabel.Font = UI_FONT
	qiCostLabel.TextSize = 13
	qiCostLabel.TextXAlignment = Enum.TextXAlignment.Left
	qiCostLabel.Parent = metricsBox

	-- FLAME GAUGE MINIGAME
	flameGaugeFrame = Instance.new("Frame")
	flameGaugeFrame.Name = "FlameGaugeFrame"
	flameGaugeFrame.Size = UDim2.new(1, -24, 0, 70)
	flameGaugeFrame.Position = UDim2.new(0, 12, 0, 336)
	flameGaugeFrame.BackgroundColor3 = COLOR_LIGHT_CARD
	flameGaugeFrame.BorderSizePixel = 0
	flameGaugeFrame.Visible = false
	flameGaugeFrame.Parent = col2

	local fgStroke = Instance.new("UIStroke")
	fgStroke.Color = COLOR_LIGHT_BORDER
	fgStroke.Thickness = 1
	fgStroke.Parent = flameGaugeFrame

	local flameImg = Instance.new("ImageLabel")
	flameImg.Size = UDim2.new(0, 20, 0, 20)
	flameImg.Position = UDim2.new(0, 8, 0, 4)
	flameImg.BackgroundTransparency = 1
	flameImg.Image = UIAssets.Icons.FlameIcon or ""
	flameImg.Parent = flameGaugeFrame

	flameStatusText = Instance.new("TextLabel")
	flameStatusText.Size = UDim2.new(1, -36, 0, 22)
	flameStatusText.Position = UDim2.new(0, 32, 0, 2)
	flameStatusText.BackgroundTransparency = 1
	flameStatusText.Text = "CONTROL QI FLAME TEMP"
	flameStatusText.TextColor3 = COLOR_ACTION_GOLD
	flameStatusText.Font = UI_FONT
	flameStatusText.TextSize = 12
	flameStatusText.TextXAlignment = Enum.TextXAlignment.Left
	flameStatusText.Parent = flameGaugeFrame

	local barBackground = Instance.new("Frame")
	barBackground.Size = UDim2.new(1, -20, 0, 22)
	barBackground.Position = UDim2.new(0, 10, 0, 30)
	barBackground.BackgroundColor3 = COLOR_LIGHT_PANEL
	barBackground.BorderSizePixel = 0
	barBackground.Parent = flameGaugeFrame

	local optimalZone = Instance.new("Frame")
	optimalZone.Size = UDim2.new(0.2, 0, 1, 0)
	optimalZone.Position = UDim2.new(0.4, 0, 0, 0)
	optimalZone.BackgroundColor3 = COLOR_HP_GREEN
	optimalZone.BorderSizePixel = 0
	optimalZone.Parent = barBackground

	flameNeedle = Instance.new("Frame")
	flameNeedle.Size = UDim2.new(0, 4, 1, 4)
	flameNeedle.Position = UDim2.new(0, 0, 0, -2)
	flameNeedle.BackgroundColor3 = COLOR_TEXT_MAIN
	flameNeedle.BorderSizePixel = 0
	flameNeedle.ZIndex = 10
	flameNeedle.Parent = barBackground

	statusMessageLabel = Instance.new("TextLabel")
	statusMessageLabel.Size = UDim2.new(1, -24, 0, 24)
	statusMessageLabel.Position = UDim2.new(0, 12, 1, -110)
	statusMessageLabel.BackgroundTransparency = 1
	statusMessageLabel.Text = ""
	statusMessageLabel.TextColor3 = COLOR_HP_GREEN
	statusMessageLabel.Font = UI_FONT
	statusMessageLabel.TextSize = 14
	statusMessageLabel.Parent = col2

	refineButton = Instance.new("TextButton")
	refineButton.Size = UDim2.new(1, -24, 0, 52)
	refineButton.Position = UDim2.new(0, 12, 1, -64)
	refineButton.BackgroundColor3 = COLOR_ACTION_GOLD
	refineButton.Text = "REFINE SPIRIT DAN"
	refineButton.TextColor3 = COLOR_TEXT_MAIN
	refineButton.Font = UI_FONT
	refineButton.TextSize = 20
	refineButton.Parent = col2

	refineButton.MouseButton1Click:Connect(function()
		if isRefining then return end

		local selectedIndices: { number } = {}
		for i = 1, 3 do
			if cauldronSlots[i].SlotIdx then
				table.insert(selectedIndices, cauldronSlots[i].SlotIdx :: number)
			end
		end

		if #selectedIndices == 0 then
			statusMessageLabel.Text = "Cauldron is empty! Click herbs on the left."
			statusMessageLabel.TextColor3 = COLOR_DANGER_RED
			return
		end

		isRefining = true
		minigameActive = true
		needlePosition = 0
		needleDirection = 1
		flameGaugeFrame.Visible = true
		refineButton.Text = "LOCK QI FLAME [SPACE]"
		refineButton.BackgroundColor3 = COLOR_AZURE_BLUE
		statusMessageLabel.Text = "Catch the needle inside the GREEN zone!"
	end)

	-- COLUMN 3: FORMULA GUIDE
	local col3 = Instance.new("Frame")
	col3.Size = UDim2.new(0, 310, 1, -84)
	col3.Position = UDim2.new(0, 828, 0, 76)
	col3.BackgroundColor3 = COLOR_LIGHT_PANEL
	col3.BorderSizePixel = 0
	col3.Parent = mainModal

	local col3Stroke = Instance.new("UIStroke")
	col3Stroke.Color = COLOR_LIGHT_BORDER
	col3Stroke.Thickness = 1.5
	col3Stroke.Parent = col3

	local c3Header = Instance.new("TextLabel")
	c3Header.Size = UDim2.new(1, 0, 0, 38)
	c3Header.BackgroundColor3 = COLOR_LIGHT_CARD
	c3Header.Text = "FORMULA COMBINATION GUIDE"
	c3Header.TextColor3 = COLOR_TEXT_MAIN
	c3Header.Font = UI_FONT
	c3Header.TextSize = 15
	c3Header.Parent = col3

	local guideList = Instance.new("ScrollingFrame")
	guideList.Size = UDim2.new(1, -16, 1, -52)
	guideList.Position = UDim2.new(0, 8, 0, 44)
	guideList.BackgroundTransparency = 1
	guideList.BorderSizePixel = 0
	guideList.ScrollBarThickness = 4
	guideList.ScrollBarImageColor3 = COLOR_AZURE_BLUE
	guideList.Parent = col3

	local glLayout = Instance.new("UIListLayout")
	glLayout.FillDirection = Enum.FillDirection.Vertical
	glLayout.Padding = UDim.new(0, 8)
	glLayout.Parent = guideList

	for formulaId, formula in pairs(AlchemyConfig.GetAllFormulas()) do
		local card = Instance.new("Frame")
		card.Size = UDim2.new(1, 0, 0, 95)
		card.BackgroundColor3 = COLOR_LIGHT_CARD
		card.BorderSizePixel = 0
		card.Parent = guideList

		local cardStroke = Instance.new("UIStroke")
		cardStroke.Color = COLOR_LIGHT_BORDER
		cardStroke.Thickness = 1
		cardStroke.Parent = card

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -12, 0, 24)
		title.Position = UDim2.new(0, 6, 0, 4)
		title.BackgroundTransparency = 1
		title.Text = formula.Name
		title.TextColor3 = COLOR_TEXT_MAIN
		title.Font = UI_FONT
		title.TextSize = 14
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Parent = card

		local reqs = "Reqs: " .. table.concat(formula.RequiredArchetypes, " + ")
		local reqLabel = Instance.new("TextLabel")
		reqLabel.Size = UDim2.new(1, -12, 0, 36)
		reqLabel.Position = UDim2.new(0, 6, 0, 28)
		reqLabel.BackgroundTransparency = 1
		reqLabel.Text = reqs
		reqLabel.TextColor3 = COLOR_AZURE_BLUE
		reqLabel.Font = UI_FONT
		reqLabel.TextSize = 12
		reqLabel.TextWrapped = true
		reqLabel.TextXAlignment = Enum.TextXAlignment.Left
		reqLabel.Parent = card

		local info = string.format("Base Rate: %d%% | Qi: %d", math.floor(formula.BaseSuccessRate * 100), formula.BaseQiCost)
		local infoLabel = Instance.new("TextLabel")
		infoLabel.Size = UDim2.new(1, -12, 0, 20)
		infoLabel.Position = UDim2.new(0, 6, 0, 68)
		infoLabel.BackgroundTransparency = 1
		infoLabel.Text = info
		infoLabel.TextColor3 = COLOR_TEXT_SUB
		infoLabel.Font = UI_FONT
		infoLabel.TextSize = 11
		infoLabel.TextXAlignment = Enum.TextXAlignment.Left
		infoLabel.Parent = card
	end
end

function AlchemyController.UpdateMasteryBar(exp: number, level: number)
	local rankTitles = {
		[1] = "APPRENTICE ALCHEMIST",
		[2] = "SPIRIT HERB MASTER",
		[3] = "GRAND CAULDRON SCHOLAR",
		[4] = "PILL EMPEROR",
	}

	local title = rankTitles[level] or ("ALCHEMY RANK " .. level)
	if masteryRankLabel then
		masteryRankLabel.Text = string.format("RANK %d — %s", level, title)
	end

	local reqExp = level * 100
	local ratio = math.clamp(exp / reqExp, 0, 1)

	if masteryExpFill then
		masteryExpFill.Size = UDim2.new(ratio, 0, 1, 0)
	end

	if masteryExpText then
		masteryExpText.Text = string.format("%d / %d EXP", exp, reqExp)
	end
end

function AlchemyController.LockFlamePrecision()
	if not minigameActive then return end

	minigameActive = false
	flamePrecisionScore = 1 - math.abs(needlePosition - 0.5) * 2

	refineButton.Text = "REFINING IN PROGRESS..."
	refineButton.BackgroundColor3 = COLOR_TEXT_SUB

	local selectedIndices: { number } = {}
	for i = 1, 3 do
		if cauldronSlots[i].SlotIdx then
			table.insert(selectedIndices, cauldronSlots[i].SlotIdx :: number)
		end
	end

	alchemyActionRemote:FireServer({
		Action = "RefineManualCombination",
		SelectedSlotIndices = selectedIndices,
		FlamePrecision = flamePrecisionScore,
	})
end

function AlchemyController.RefreshHerbPicker()
	herbPickerGrid:ClearAllChildren()

	local layout = Instance.new("UIGridLayout")
	layout.CellSize = UDim2.new(0, 92, 0, 92)
	layout.CellPadding = UDim2.new(0, 8, 0, 8)
	layout.Parent = herbPickerGrid

	for slotIdx, slotData in pairs(currentInventoryData) do
		if slotData then
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef and itemDef.Type == "Material" then
				local colorData = UIAssets.RarityCardColors[itemDef.Rarity]
				if slotData.Quality and UIAssets.GradeCardColors[slotData.Quality] then
					colorData = UIAssets.GradeCardColors[slotData.Quality]
				end

				local cardBg = if colorData then colorData.Background else COLOR_LIGHT_CARD
				local borderCol = if colorData then colorData.Border else COLOR_LIGHT_BORDER

				local slotFrame = Instance.new("Frame")
				slotFrame.Name = "HerbSlot_" .. slotIdx
				slotFrame.BackgroundColor3 = cardBg
				slotFrame.BorderSizePixel = 0
				slotFrame.Parent = herbPickerGrid

				local stroke = Instance.new("UIStroke")
				stroke.Color = borderCol
				stroke.Thickness = 1.5
				stroke.Parent = slotFrame

				local iconAsset = UIAssets.Icons[slotData.ItemId] or itemDef.Icon
				if iconAsset and iconAsset ~= "" then
					local icon = Instance.new("ImageLabel")
					icon.Size = UDim2.new(1, -12, 1, -20)
					icon.Position = UDim2.new(0, 6, 0, 4)
					icon.BackgroundTransparency = 1
					icon.ScaleType = Enum.ScaleType.Fit
					icon.Image = iconAsset
					icon.Parent = slotFrame
				else
					local nameLbl = Instance.new("TextLabel")
					nameLbl.Size = UDim2.new(1, -6, 1, -22)
					nameLbl.Position = UDim2.new(0, 3, 0, 4)
					nameLbl.BackgroundTransparency = 1
					nameLbl.Text = itemDef.Name
					nameLbl.TextColor3 = COLOR_TEXT_MAIN
					nameLbl.Font = UI_FONT
					nameLbl.TextSize = 11
					nameLbl.TextWrapped = true
					nameLbl.Parent = slotFrame
				end

				local countLbl = Instance.new("TextLabel")
				countLbl.Size = UDim2.new(1, -4, 0, 16)
				countLbl.Position = UDim2.new(0, 0, 1, -16)
				countLbl.BackgroundTransparency = 1
				countLbl.Text = "x" .. slotData.Count
				countLbl.TextColor3 = COLOR_TEXT_MAIN
				countLbl.Font = UI_FONT
				countLbl.TextSize = 11
				countLbl.TextXAlignment = Enum.TextXAlignment.Right
				countLbl.Parent = slotFrame

				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 1, 0)
				btn.BackgroundTransparency = 1
				btn.Text = ""
				btn.Parent = slotFrame

				btn.MouseButton1Click:Connect(function()
					for i = 1, 3 do
						if not cauldronSlots[i].SlotIdx then
							cauldronSlots[i] = { SlotIdx = slotIdx, ItemId = slotData.ItemId }
							break
						end
					end
					AlchemyController.UpdateCauldronSlotDisplay()
					AlchemyController.UpdateMetrics()
				end)
			end
		end
	end
end

function AlchemyController.UpdateCauldronSlotDisplay()
	for i = 1, 3 do
		local slotFrame = cauldronSlotButtons[i]
		if slotFrame then
			local nameLbl = slotFrame:FindFirstChild("HerbNameLabel") :: TextLabel?
			local slotIcon = slotFrame:FindFirstChild("SlotIcon") :: ImageLabel?
			local stroke = slotFrame:FindFirstChild("SlotStroke") :: UIStroke?

			local data = cauldronSlots[i]
			if data and data.ItemId then
				local itemDef = ItemConfig.GetItem(data.ItemId)
				local iconAsset = UIAssets.Icons[data.ItemId] or (itemDef and itemDef.Icon)
				if iconAsset and iconAsset ~= "" then
					if slotIcon then
						slotIcon.Image = iconAsset
						slotIcon.Visible = true
					end
					if nameLbl then nameLbl.Visible = false end
				else
					if slotIcon then slotIcon.Visible = false end
					if nameLbl then
						nameLbl.Text = if itemDef then itemDef.Name else data.ItemId
						nameLbl.TextColor3 = COLOR_AZURE_BLUE
						nameLbl.Visible = true
					end
				end
				if stroke then stroke.Color = COLOR_AZURE_BLUE end
			else
				if slotIcon then slotIcon.Visible = false end
				if nameLbl then
					nameLbl.Text = "+ Add Herb"
					nameLbl.TextColor3 = COLOR_TEXT_SUB
					nameLbl.Visible = true
				end
				if stroke then stroke.Color = COLOR_LIGHT_BORDER end
			end
		end
	end
end

function AlchemyController.UpdateMetrics()
	local insertedItemIds: { string } = {}
	for i = 1, 3 do
		if cauldronSlots[i].ItemId then
			table.insert(insertedItemIds, cauldronSlots[i].ItemId :: string)
		end
	end

	if #insertedItemIds == 0 then
		matchedFormulaLabel.Text = "MATCHED FORMULA: NONE"
		successRateLabel.Text = "ESTIMATED SUCCESS: 0%"
		qualityTextLabel.Text = "EXPECTED QUALITY: STANDARD"
		qiCostLabel.Text = "REQUIRED QI: 0 SPIRIT QI"
		return
	end

	local formula, successRate, potencyMult, qualityText = AlchemyConfig.CalculateCombinationMetrics(insertedItemIds)

	if formula then
		matchedFormulaLabel.Text = "FORMULA: " .. formula.Name:upper()
		qiCostLabel.Text = string.format("REQUIRED QI: %d SPIRIT QI", formula.BaseQiCost)
	else
		matchedFormulaLabel.Text = "FORMULA: UNKNOWN MIXTURE"
		qiCostLabel.Text = "REQUIRED QI: 20 SPIRIT QI"
	end

	successRateLabel.Text = string.format("ESTIMATED SUCCESS: %d%% CHANCE", math.floor(successRate * 100))
	qualityTextLabel.Text = string.format("QUALITY: %s (%.1fx)", qualityText:upper(), potencyMult)
end

return AlchemyController