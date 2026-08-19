--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Client UI controller for the Azure Cloud Sect Market and Quest Pavilion.
    Theme: Dark Obsidian (#111827), Antique Gold (#8B6B32), and Jade Cultivation (#10B981).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local MarketController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

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

local CLICK_SOUND_ID = "rbxassetid://6895079853"

local marketRemote: RemoteEvent
local sectRemote: RemoteEvent

-- UI Instances
local screenGui: ScreenGui
local toastGui: ScreenGui
local overlayBackdrop: Frame
local mainModal: Frame
local headerTitle: TextLabel
local balanceLabel: TextLabel
local rankLabel: TextLabel
local contributionLabel: TextLabel
local navBar: Frame
local contentContainer: Frame
local toastContainer: Frame

-- State
local isOpen = false
local viewMode: "Market" | "SectDuties" = "Market"
local currentTab: "Buy" | "Sell" | "Duties" = "Buy"
local currentStones = 250
local currentRank: SectConfig.DiscipleRank = "OuterDisciple"
local currentContribution = 0
local playerInventoryList: { [number]: { ItemId: string, Count: number, Quality: string? } } = {}
local activeQuests: { [string]: any } = {}

local function PlayClickAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)
end

function MarketController.ShowToast(message: string, isError: boolean?)
	if not toastContainer then return end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 380, 0, 44)
	toast.Position = UDim2.new(0.5, 0, 0, -60)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = if isError then COLOR_DANGER_RED else COLOR_HP_GREEN
	toast.BorderSizePixel = 0
	toast.ZIndex = 100
	toast.Parent = toastContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = COLOR_TEXT_MAIN
	stroke.Thickness = 1.5
	stroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = COLOR_TEXT_MAIN
	label.Font = UI_FONT
	label.TextSize = 14
	label.TextScaled = true
	label.ZIndex = 101
	label.Parent = toast

	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 25) }):Play()

	task.delay(2.8, function()
		if toast and toast.Parent then
			local fade = TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = UDim2.new(0.5, 0, 0, -60),
				BackgroundTransparency = 1,
			})
			fade:Play()
			fade.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end

function MarketController.IsOpen(): boolean
	return isOpen
end

function MarketController.Init()
	marketRemote = RemoteEvents.GetRemote("MarketAction")
	sectRemote = RemoteEvents.GetRemote("SectAction")

	MarketController.BuildUI()

	-- Network Listeners
	marketRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "OpenShop" then
			viewMode = "Market"
			currentTab = "Buy"
			currentStones = payload.SpiritStones or currentStones
			currentRank = payload.SectRank or currentRank
			MarketController.UpdateHeader()
			MarketController.Open()
		elseif action == "TransactionSuccess" then
			currentStones = payload.NewBalance or currentStones
			MarketController.UpdateHeader()
			if payload.Type == "Buy" then
				MarketController.ShowToast(string.format("Purchased %dx %s (-%d Stones)!", payload.Amount, payload.ItemId, payload.TotalCost))
			else
				MarketController.ShowToast(string.format("Sold %dx %s (+%d Stones)!", payload.Amount, payload.ItemId, payload.TotalPayout))
			end
			if isOpen then
				MarketController.RenderCurrentTab()
			end
		elseif action == "TransactionFailed" then
			MarketController.ShowToast(payload.Message or "Transaction Failed!", true)
		elseif action == "SyncBalance" then
			currentStones = payload.SpiritStones or currentStones
			MarketController.UpdateHeader()
			if isOpen then
				MarketController.RenderCurrentTab()
			end
		end
	end)

	sectRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "OpenSectMenu" then
			viewMode = "SectDuties"
			currentTab = "Duties"
			MarketController.Open()
		elseif action == "SyncSectData" then
			currentRank = payload.Rank or currentRank
			currentContribution = payload.ContributionPoints or currentContribution
			currentStones = payload.SpiritStones or currentStones
			activeQuests = payload.Quests or activeQuests
			MarketController.UpdateHeader()
			if isOpen and currentTab == "Duties" then
				MarketController.RenderDutiesTab()
			end
		elseif action == "QuestCompleted" then
			MarketController.ShowToast(string.format("Duty Completed! (+%d CP, +%d Stones, +%d Qi)", payload.RewardContribution, payload.RewardSpiritStones, payload.RewardQi))
			MarketController.UpdateHeader()
			if isOpen and currentTab == "Duties" then
				MarketController.RenderDutiesTab()
			end
		elseif action == "PromotionSuccess" then
			MarketController.ShowToast(string.format("Promoted to %s!", payload.DisplayName))
			MarketController.UpdateHeader()
		elseif action == "PromotionFailed" or action == "QuestError" or action == "StipendFailed" then
			MarketController.ShowToast(payload.Message or "Action Failed!", true)
		elseif action == "StipendClaimed" then
			MarketController.ShowToast(string.format("Claimed Daily Stipend (+%d Stones)!", payload.Amount))
			MarketController.UpdateHeader()
		end
	end)

	local updateInvRemote = RemoteEvents.GetRemote("UpdateInventory")
	updateInvRemote.OnClientEvent:Connect(function(invTable)
		if type(invTable) == "table" then
			playerInventoryList = invTable
			if isOpen and currentTab == "Sell" then
				MarketController.RenderSellTab()
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Escape and isOpen then
			MarketController.Close()
		end
	end)

	print("[ASCEND] MarketController Initialized with Dark Obsidian Palette & UIAssets Cards.")
end

function MarketController.BuildUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SectMarketGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 25
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = true
	screenGui.Parent = playerGui

	toastGui = Instance.new("ScreenGui")
	toastGui.Name = "AscendToastGui"
	toastGui.ResetOnSpawn = false
	toastGui.DisplayOrder = 99
	toastGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	toastGui.Parent = playerGui

	toastContainer = Instance.new("Frame")
	toastContainer.Name = "ToastContainer"
	toastContainer.Size = UDim2.new(0, 400, 0, 100)
	toastContainer.Position = UDim2.new(0.5, 0, 0, 10)
	toastContainer.AnchorPoint = Vector2.new(0.5, 0)
	toastContainer.BackgroundTransparency = 1
	toastContainer.Parent = toastGui

	overlayBackdrop = Instance.new("Frame")
	overlayBackdrop.Name = "OverlayBackdrop"
	overlayBackdrop.Size = UDim2.new(1, 0, 1, 0)
	overlayBackdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlayBackdrop.BackgroundTransparency = 0.6
	overlayBackdrop.BorderSizePixel = 0
	overlayBackdrop.Visible = false
	overlayBackdrop.Parent = screenGui

	mainModal = Instance.new("Frame")
	mainModal.Name = "MainModal"
	mainModal.Size = UDim2.new(0, 1150, 0, 660)
	mainModal.Position = UDim2.new(0.5, -575, 0.5, -330)
	mainModal.BackgroundColor3 = COLOR_LIGHT_MAIN
	mainModal.BorderSizePixel = 0
	mainModal.Parent = overlayBackdrop

	local mStroke = Instance.new("UIStroke")
	mStroke.Color = COLOR_LIGHT_BORDER
	mStroke.Thickness = 2
	mStroke.Parent = mainModal

	-- Header Title
	headerTitle = Instance.new("TextLabel")
	headerTitle.Size = UDim2.new(1, 0, 0, 48)
	headerTitle.BackgroundTransparency = 1
	headerTitle.Text = "SECT MERCHANT MARKET"
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
		PlayClickAudio()
		MarketController.Close()
	end)

	-- Status Bar (Stones, Rank, Contribution)
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, -24, 0, 32)
	statusBar.Position = UDim2.new(0, 12, 0, 50)
	statusBar.BackgroundColor3 = COLOR_LIGHT_PANEL
	statusBar.BorderSizePixel = 0
	statusBar.Parent = mainModal

	local sbStroke = Instance.new("UIStroke")
	sbStroke.Color = COLOR_LIGHT_BORDER
	sbStroke.Thickness = 1
	sbStroke.Parent = statusBar

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusLayout.Padding = UDim.new(0, 30)
	statusLayout.Parent = statusBar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.Parent = statusBar

	balanceLabel = Instance.new("TextLabel")
	balanceLabel.Size = UDim2.new(0, 180, 1, 0)
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.Text = "SPIRIT STONES: 250"
	balanceLabel.TextColor3 = COLOR_AZURE_BLUE
	balanceLabel.Font = UI_FONT
	balanceLabel.TextSize = 13
	balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	balanceLabel.Parent = statusBar

	rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 220, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "RANK: OUTER DISCIPLE"
	rankLabel.TextColor3 = COLOR_HP_GREEN
	rankLabel.Font = UI_FONT
	rankLabel.TextSize = 13
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = statusBar

	contributionLabel = Instance.new("TextLabel")
	contributionLabel.Size = UDim2.new(0, 200, 1, 0)
	contributionLabel.BackgroundTransparency = 1
	contributionLabel.Text = "CONTRIBUTION: 0 CP"
	contributionLabel.TextColor3 = COLOR_ACTION_GOLD
	contributionLabel.Font = UI_FONT
	contributionLabel.TextSize = 13
	contributionLabel.TextXAlignment = Enum.TextXAlignment.Left
	contributionLabel.Parent = statusBar

	-- Tab Navigation Bar
	navBar = Instance.new("Frame")
	navBar.Name = "NavBar"
	navBar.Size = UDim2.new(1, -24, 0, 38)
	navBar.Position = UDim2.new(0, 12, 0, 88)
	navBar.BackgroundTransparency = 1
	navBar.Parent = mainModal

	-- Content Container
	contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -24, 1, -136)
	contentContainer.Position = UDim2.new(0, 12, 0, 128)
	contentContainer.BackgroundColor3 = COLOR_LIGHT_PANEL
	contentContainer.BorderSizePixel = 0
	contentContainer.Parent = mainModal

	local ccStroke = Instance.new("UIStroke")
	ccStroke.Color = COLOR_LIGHT_BORDER
	ccStroke.Thickness = 1.5
	ccStroke.Parent = contentContainer
end

function MarketController.UpdateHeader()
	if balanceLabel then
		balanceLabel.Text = string.format("SPIRIT STONES: %d", currentStones)
	end
	if rankLabel then
		local rankDef = SectConfig.GetRank(currentRank)
		rankLabel.Text = string.format("RANK: %s", rankDef.DisplayName:upper())
	end
	if contributionLabel then
		contributionLabel.Text = string.format("CONTRIBUTION: %d CP", currentContribution)
	end
	if headerTitle then
		if viewMode == "Market" then
			headerTitle.Text = "SECT MERCHANT MARKET"
		else
			headerTitle.Text = "SECT ELDER PAVILION"
		end
	end
end

function MarketController.RenderNavBar()
	navBar:ClearAllChildren()
	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.Padding = UDim.new(0, 8)
	navLayout.Parent = navBar

	local function AddTab(text: string, tabKey: "Buy" | "Sell" | "Duties")
		local isSelected = (currentTab == tabKey)
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 140, 1, 0)
		btn.BackgroundColor3 = if isSelected then COLOR_LIGHT_CARD else COLOR_LIGHT_PANEL
		btn.Text = text
		btn.TextColor3 = if isSelected then COLOR_ACTION_GOLD else COLOR_TEXT_SUB
		btn.Font = UI_FONT
		btn.TextSize = 13
		btn.Parent = navBar

		local btnStroke = Instance.new("UIStroke")
		btnStroke.Color = COLOR_LIGHT_BORDER
		btnStroke.Thickness = 1
		btnStroke.Parent = btn

		btn.MouseButton1Click:Connect(function()
			PlayClickAudio()
			currentTab = tabKey
			MarketController.RenderNavBar()
			MarketController.RenderCurrentTab()
		end)
	end

	if viewMode == "Market" then
		AddTab("BUY GOODS", "Buy")
		AddTab("SELL ITEMS", "Sell")
	else
		AddTab("SECT DUTIES", "Duties")
	end
end

function MarketController.RenderCurrentTab()
	contentContainer:ClearAllChildren()

	if currentTab == "Buy" then
		MarketController.RenderBuyTab()
	elseif currentTab == "Sell" then
		MarketController.RenderSellTab()
	elseif currentTab == "Duties" then
		MarketController.RenderDutiesTab()
	end
end

function MarketController.RenderBuyTab()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -16)
	scroll.Position = UDim2.new(0, 8, 0, 8)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLOR_ACTION_GOLD
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.485, 0, 0, 88)
	grid.CellPadding = UDim2.new(0.03, 0, 0, 10)
	grid.Parent = scroll

	for itemId, itemDef in pairs(SectConfig.GetAllMarketItems()) do
		if itemDef.BuyPrice then
			local itemInfo = ItemConfig.GetItem(itemDef.ItemId)
			local colorData = UIAssets.RarityCardColors[if itemInfo then itemInfo.Rarity else "Common"]
			local borderCol = if colorData then colorData.Border else COLOR_LIGHT_BORDER

			local card = Instance.new("Frame")
			card.BackgroundColor3 = COLOR_LIGHT_CARD
			card.BorderSizePixel = 0
			card.Parent = scroll

			local cStroke = Instance.new("UIStroke")
			cStroke.Color = borderCol
			cStroke.Thickness = 1.5
			cStroke.Parent = card

			-- 2D PNG Icon
			local iconAsset = UIAssets.Icons[itemDef.ItemId] or (itemInfo and itemInfo.Icon)
			if iconAsset and iconAsset ~= "" then
				local icon = Instance.new("ImageLabel")
				icon.Size = UDim2.new(0, 54, 0, 54)
				icon.Position = UDim2.new(0, 10, 0.5, -27)
				icon.BackgroundTransparency = 1
				icon.ScaleType = Enum.ScaleType.Fit
				icon.Image = iconAsset
				icon.Parent = card
			end

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(0.5, 0, 0, 22)
			name.Position = UDim2.new(0, 72, 0, 14)
			name.BackgroundTransparency = 1
			name.Text = if itemInfo then itemInfo.Name else itemDef.ItemId
			name.TextColor3 = COLOR_TEXT_MAIN
			name.Font = UI_FONT
			name.TextSize = 14
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = card

			local price = Instance.new("TextLabel")
			price.Size = UDim2.new(0.5, 0, 0, 20)
			price.Position = UDim2.new(0, 72, 0, 38)
			price.BackgroundTransparency = 1
			price.Text = string.format("PRICE: %d STONES", itemDef.BuyPrice)
			price.TextColor3 = COLOR_AZURE_BLUE
			price.Font = UI_FONT
			price.TextSize = 12
			price.TextXAlignment = Enum.TextXAlignment.Left
			price.Parent = card

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0, 80, 0, 38)
			buyBtn.Position = UDim2.new(1, -92, 0.5, -19)
			buyBtn.BackgroundColor3 = COLOR_HP_GREEN
			buyBtn.Text = "BUY"
			buyBtn.TextColor3 = COLOR_TEXT_MAIN
			buyBtn.Font = UI_FONT
			buyBtn.TextSize = 14
			buyBtn.Parent = card

			buyBtn.MouseButton1Click:Connect(function()
				PlayClickAudio()
				marketRemote:FireServer({ Action = "BuyItem", ItemId = itemDef.ItemId, Amount = 1 })
			end)
		end
	end
end

function MarketController.RenderSellTab()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -16)
	scroll.Position = UDim2.new(0, 8, 0, 8)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLOR_ACTION_GOLD
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.485, 0, 0, 88)
	grid.CellPadding = UDim2.new(0.03, 0, 0, 10)
	grid.Parent = scroll

	local hasSellable = false

	for _, slot in pairs(playerInventoryList) do
		if slot and slot.Count > 0 then
			local itemDef = SectConfig.GetMarketItem(slot.ItemId)
			if itemDef and itemDef.SellPrice > 0 then
				hasSellable = true

				local itemInfo = ItemConfig.GetItem(slot.ItemId)
				local colorData = UIAssets.RarityCardColors[if itemInfo then itemInfo.Rarity else "Common"]
				if slot.Quality and UIAssets.GradeCardColors[slot.Quality] then
					colorData = UIAssets.GradeCardColors[slot.Quality]
				end

				local borderCol = if colorData then colorData.Border else COLOR_LIGHT_BORDER

				local card = Instance.new("Frame")
				card.BackgroundColor3 = COLOR_LIGHT_CARD
				card.BorderSizePixel = 0
				card.Parent = scroll

				local cStroke = Instance.new("UIStroke")
				cStroke.Color = borderCol
				cStroke.Thickness = 1.5
				cStroke.Parent = card

				local iconAsset = UIAssets.Icons[slot.ItemId] or (itemInfo and itemInfo.Icon)
				if iconAsset and iconAsset ~= "" then
					local icon = Instance.new("ImageLabel")
					icon.Size = UDim2.new(0, 54, 0, 54)
					icon.Position = UDim2.new(0, 10, 0.5, -27)
					icon.BackgroundTransparency = 1
					icon.ScaleType = Enum.ScaleType.Fit
					icon.Image = iconAsset
					icon.Parent = card
				end

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(0.5, 0, 0, 22)
				name.Position = UDim2.new(0, 72, 0, 14)
				name.BackgroundTransparency = 1
				name.Text = string.format("%s (x%d)", if itemInfo then itemInfo.Name else slot.ItemId, slot.Count)
				name.TextColor3 = COLOR_TEXT_MAIN
				name.Font = UI_FONT
				name.TextSize = 13
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Parent = card

				local payout = Instance.new("TextLabel")
				payout.Size = UDim2.new(0.5, 0, 0, 20)
				payout.Position = UDim2.new(0, 72, 0, 38)
				payout.BackgroundTransparency = 1
				payout.Text = string.format("SELL: +%d STONES EA", itemDef.SellPrice)
				payout.TextColor3 = COLOR_ACTION_GOLD
				payout.Font = UI_FONT
				payout.TextSize = 12
				payout.TextXAlignment = Enum.TextXAlignment.Left
				payout.Parent = card

				local sellBtn = Instance.new("TextButton")
				sellBtn.Size = UDim2.new(0, 80, 0, 38)
				sellBtn.Position = UDim2.new(1, -92, 0.5, -19)
				sellBtn.BackgroundColor3 = COLOR_ACTION_GOLD
				sellBtn.Text = "SELL 1"
				sellBtn.TextColor3 = COLOR_TEXT_MAIN
				sellBtn.Font = UI_FONT
				sellBtn.TextSize = 13
				sellBtn.Parent = card

				sellBtn.MouseButton1Click:Connect(function()
					PlayClickAudio()
					marketRemote:FireServer({ Action = "SellItem", ItemId = slot.ItemId, Amount = 1 })
				end)
			end
		end
	end

	if not hasSellable then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 60)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No sellable herbs or materials in your Spirit Pouch."
		emptyLabel.TextColor3 = COLOR_TEXT_SUB
		emptyLabel.Font = UI_FONT
		emptyLabel.TextSize = 14
		emptyLabel.Parent = scroll
	end
end

function MarketController.RenderDutiesTab()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -16)
	scroll.Position = UDim2.new(0, 8, 0, 8)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 4
	scroll.ScrollBarImageColor3 = COLOR_ACTION_GOLD
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scroll

	-- Promotion & Stipend Top Banner
	local promoCard = Instance.new("Frame")
	promoCard.Size = UDim2.new(1, -8, 0, 64)
	promoCard.BackgroundColor3 = COLOR_LIGHT_CARD
	promoCard.BorderSizePixel = 0
	promoCard.Parent = scroll

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = COLOR_LIGHT_BORDER
	pStroke.Thickness = 1.5
	pStroke.Parent = promoCard

	local stipendBtn = Instance.new("TextButton")
	stipendBtn.Size = UDim2.new(0, 180, 0, 38)
	stipendBtn.Position = UDim2.new(0, 14, 0.5, -19)
	stipendBtn.BackgroundColor3 = COLOR_HP_GREEN
	stipendBtn.Text = "CLAIM DAILY STIPEND"
	stipendBtn.TextColor3 = COLOR_TEXT_MAIN
	stipendBtn.Font = UI_FONT
	stipendBtn.TextSize = 12
	stipendBtn.Parent = promoCard

	stipendBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		sectRemote:FireServer({ Action = "ClaimDailyStipend" })
	end)

	local promoteBtn = Instance.new("TextButton")
	promoteBtn.Size = UDim2.new(0, 180, 0, 38)
	promoteBtn.Position = UDim2.new(1, -194, 0.5, -19)
	promoteBtn.BackgroundColor3 = COLOR_ACTION_GOLD
	promoteBtn.Text = "REQUEST PROMOTION"
	promoteBtn.TextColor3 = COLOR_TEXT_MAIN
	promoteBtn.Font = UI_FONT
	promoteBtn.TextSize = 12
	promoteBtn.Parent = promoCard

	promoteBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		sectRemote:FireServer({ Action = "RequestPromotion" })
	end)

	-- Quests Rows
	for questId, questDef in pairs(SectConfig.GetAllQuests()) do
		local progress = activeQuests[questId] or { CurrentAmount = 0, TargetAmount = questDef.TargetAmount, Completed = false }

		local qCard = Instance.new("Frame")
		qCard.Size = UDim2.new(1, -8, 0, 78)
		qCard.BackgroundColor3 = COLOR_LIGHT_CARD
		qCard.BorderSizePixel = 0
		qCard.Parent = scroll

		local qStroke = Instance.new("UIStroke")
		qStroke.Color = if progress.Completed then COLOR_HP_GREEN else COLOR_LIGHT_BORDER
		qStroke.Thickness = 1.5
		qStroke.Parent = qCard

		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(0.65, 0, 0, 24)
		qTitle.Position = UDim2.new(0, 14, 0, 6)
		qTitle.BackgroundTransparency = 1
		qTitle.Text = string.format("%s (%d/%d)", questDef.Title:upper(), progress.CurrentAmount, questDef.TargetAmount)
		qTitle.TextColor3 = COLOR_TEXT_MAIN
		qTitle.Font = UI_FONT
		qTitle.TextSize = 14
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Parent = qCard

		local qDesc = Instance.new("TextLabel")
		qDesc.Size = UDim2.new(0.65, 0, 0, 20)
		qDesc.Position = UDim2.new(0, 14, 0, 28)
		qDesc.BackgroundTransparency = 1
		qDesc.Text = questDef.Description
		qDesc.TextColor3 = COLOR_TEXT_SUB
		qDesc.Font = UI_FONT
		qDesc.TextSize = 12
		qDesc.TextXAlignment = Enum.TextXAlignment.Left
		qDesc.Parent = qCard

		local qReward = Instance.new("TextLabel")
		qReward.Size = UDim2.new(0.65, 0, 0, 20)
		qReward.Position = UDim2.new(0, 14, 0, 50)
		qReward.BackgroundTransparency = 1
		qReward.Text = string.format("REWARDS: +%d CP  |  +%d STONES  |  +%d QI", questDef.RewardContribution, questDef.RewardSpiritStones, questDef.RewardQi)
		qReward.TextColor3 = COLOR_AZURE_BLUE
		qReward.Font = UI_FONT
		qReward.TextSize = 11
		qReward.TextXAlignment = Enum.TextXAlignment.Left
		qReward.Parent = qCard

		local submitBtn = Instance.new("TextButton")
		submitBtn.Size = UDim2.new(0, 100, 0, 36)
		submitBtn.Position = UDim2.new(1, -114, 0.5, -18)
		submitBtn.BackgroundColor3 = if progress.Completed then COLOR_HP_GREEN else COLOR_LIGHT_PANEL
		submitBtn.Text = if progress.Completed then "SUBMIT" else "IN PROGRESS"
		submitBtn.TextColor3 = if progress.Completed then COLOR_TEXT_MAIN else COLOR_TEXT_SUB
		submitBtn.Font = UI_FONT
		submitBtn.TextSize = 12
		submitBtn.Parent = qCard

		if progress.Completed then
			submitBtn.MouseButton1Click:Connect(function()
				PlayClickAudio()
				sectRemote:FireServer({ Action = "SubmitQuest", QuestId = questId })
			end)
		end
	end
end

function MarketController.Open()
	isOpen = true
	overlayBackdrop.Visible = true
	MarketController.UpdateHeader()
	MarketController.RenderNavBar()
	MarketController.RenderCurrentTab()
end

function MarketController.Close()
	isOpen = false
	overlayBackdrop.Visible = false
end

return MarketController