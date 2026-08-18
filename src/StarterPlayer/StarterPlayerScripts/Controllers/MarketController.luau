--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Client UI Controller for the Azure Cloud Sect Market and Quest Pavilion.
    Features: Dedicated Top-Level ToastGui (DisplayOrder 99), valid UI sound effects, and responsive button tweens.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local MarketController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local marketRemote: RemoteEvent
local sectRemote: RemoteEvent

-- Valid Roblox Audio IDs
local CLICK_SOUND_ID = "rbxassetid://138567614125924"
local SUCCESS_SOUND_ID = "rbxassetid://135165335432475"

-- UI Instances
local screenGui: ScreenGui
local toastGui: ScreenGui
local mainModal: Frame
local titleLabel: TextLabel
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

local function PlaySuccessAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = SUCCESS_SOUND_ID
	sound.Volume = 0.6
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.5)
end

local function AnimateButtonPress(button: GuiButton)
	local originalSize = button.Size
	local shrinkSize = UDim2.new(originalSize.X.Scale * 0.95, originalSize.X.Offset * 0.95, originalSize.Y.Scale * 0.95, originalSize.Y.Offset * 0.95)
	
	TweenService:Create(button, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = shrinkSize }):Play()
	task.delay(0.06, function()
		TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = originalSize }):Play()
	end)
end

function MarketController.ShowToast(message: string, isError: boolean?)
	if not toastContainer then return end

	local toast = Instance.new("Frame")
	toast.Size = UDim2.new(0, 360, 0, 44)
	toast.Position = UDim2.new(0.5, 0, 0, -60)
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.BackgroundColor3 = if isError then Color3.fromRGB(190, 40, 40) else Color3.fromRGB(39, 174, 96)
	toast.BorderSizePixel = 0
	toast.ZIndex = 100
	toast.Parent = toastContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = if isError then Color3.fromRGB(255, 120, 120) else Color3.fromRGB(120, 255, 180)
	stroke.Thickness = 2
	stroke.Parent = toast

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = message
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextScaled = true
	label.ZIndex = 101
	label.Parent = toast

	-- Slide Down Animation
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 25) }):Play()

	-- Auto Dismiss after 2.8s
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
			PlaySuccessAudio()
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
			PlaySuccessAudio()
			MarketController.ShowToast(string.format("Duty Completed! (+%d CP, +%d Stones, +%d Qi)", payload.RewardContribution, payload.RewardSpiritStones, payload.RewardQi))
			MarketController.UpdateHeader()
			if isOpen and currentTab == "Duties" then
				MarketController.RenderDutiesTab()
			end
		elseif action == "PromotionSuccess" then
			PlaySuccessAudio()
			MarketController.ShowToast(string.format("Promoted to %s!", payload.DisplayName))
			MarketController.UpdateHeader()
		elseif action == "PromotionFailed" or action == "QuestError" or action == "StipendFailed" then
			MarketController.ShowToast(payload.Message or "Action Failed!", true)
		elseif action == "StipendClaimed" then
			PlaySuccessAudio()
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

	-- Close on ESC key
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.Escape and isOpen then
			MarketController.Close()
		end
	end)

	print("[ASCEND] MarketController Initialized (Dedicated Top-Level ToastGui Active).")
end

function MarketController.BuildUI()
	-- 1. Main Modal GUI
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "SectMarketGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 15
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- 2. Dedicated Top-Level Toast GUI (DisplayOrder = 99 to always sit on top of all modals)
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

	local overlay = Instance.new("Frame")
	overlay.Name = "DarkOverlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui

	mainModal = Instance.new("Frame")
	mainModal.Name = "MainModal"
	mainModal.Size = UDim2.new(0.65, 0, 0.75, 0)
	mainModal.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainModal.AnchorPoint = Vector2.new(0.5, 0.5)
	mainModal.BackgroundColor3 = Color3.fromRGB(20, 24, 30)
	mainModal.BorderSizePixel = 0
	mainModal.Parent = screenGui

	local modalCorner = Instance.new("UICorner")
	modalCorner.CornerRadius = UDim.new(0, 10)
	modalCorner.Parent = mainModal

	local modalStroke = Instance.new("UIStroke")
	modalStroke.Color = Color3.fromRGB(212, 175, 55)
	modalStroke.Thickness = 2
	modalStroke.Parent = mainModal

	-- Header Bar
	local headerBar = Instance.new("Frame")
	headerBar.Name = "HeaderBar"
	headerBar.Size = UDim2.new(1, 0, 0, 50)
	headerBar.BackgroundColor3 = Color3.fromRGB(15, 18, 22)
	headerBar.BorderSizePixel = 0
	headerBar.Parent = mainModal

	local headerCorner = Instance.new("UICorner")
	headerCorner.CornerRadius = UDim.new(0, 10)
	headerCorner.Parent = headerBar

	titleLabel = Instance.new("TextLabel")
	titleLabel.Size = UDim2.new(0.6, 0, 1, 0)
	titleLabel.Position = UDim2.new(0, 16, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "AZURE CLOUD SECT — PAVILION"
	titleLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextSize = 18
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Parent = headerBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 36, 0, 36)
	closeBtn.Position = UDim2.new(1, -44, 0.5, 0)
	closeBtn.AnchorPoint = Vector2.new(0, 0.5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
	closeBtn.Text = "✕"
	closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.TextSize = 18
	closeBtn.Parent = headerBar

	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 8)
	closeCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		MarketController.Close()
	end)

	-- Status Bar
	local statusBar = Instance.new("Frame")
	statusBar.Name = "StatusBar"
	statusBar.Size = UDim2.new(1, -32, 0, 35)
	statusBar.Position = UDim2.new(0, 16, 0, 58)
	statusBar.BackgroundColor3 = Color3.fromRGB(26, 32, 40)
	statusBar.BorderSizePixel = 0
	statusBar.Parent = mainModal

	local statusCorner = Instance.new("UICorner")
	statusCorner.CornerRadius = UDim.new(0, 6)
	statusCorner.Parent = statusBar

	local statusLayout = Instance.new("UIListLayout")
	statusLayout.FillDirection = Enum.FillDirection.Horizontal
	statusLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statusLayout.Padding = UDim.new(0, 24)
	statusLayout.Parent = statusBar

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent = statusBar

	balanceLabel = Instance.new("TextLabel")
	balanceLabel.Size = UDim2.new(0, 160, 1, 0)
	balanceLabel.BackgroundTransparency = 1
	balanceLabel.Text = "💎 Spirit Stones: 250"
	balanceLabel.TextColor3 = Color3.fromRGB(80, 220, 255)
	balanceLabel.Font = Enum.Font.GothamMedium
	balanceLabel.TextSize = 14
	balanceLabel.TextXAlignment = Enum.TextXAlignment.Left
	balanceLabel.Parent = statusBar

	rankLabel = Instance.new("TextLabel")
	rankLabel.Size = UDim2.new(0, 200, 1, 0)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Text = "🥋 Rank: Outer Disciple"
	rankLabel.TextColor3 = Color3.fromRGB(120, 255, 150)
	rankLabel.Font = Enum.Font.GothamMedium
	rankLabel.TextSize = 14
	rankLabel.TextXAlignment = Enum.TextXAlignment.Left
	rankLabel.Parent = statusBar

	contributionLabel = Instance.new("TextLabel")
	contributionLabel.Size = UDim2.new(0, 160, 1, 0)
	contributionLabel.BackgroundTransparency = 1
	contributionLabel.Text = "📜 Contribution: 0 CP"
	contributionLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	contributionLabel.Font = Enum.Font.GothamMedium
	contributionLabel.TextSize = 14
	contributionLabel.TextXAlignment = Enum.TextXAlignment.Left
	contributionLabel.Parent = statusBar

	-- Navigation Bar
	navBar = Instance.new("Frame")
	navBar.Name = "NavBar"
	navBar.Size = UDim2.new(1, -32, 0, 40)
	navBar.Position = UDim2.new(0, 16, 0, 100)
	navBar.BackgroundTransparency = 1
	navBar.Parent = mainModal

	-- Content Container
	contentContainer = Instance.new("Frame")
	contentContainer.Name = "ContentContainer"
	contentContainer.Size = UDim2.new(1, -32, 1, -156)
	contentContainer.Position = UDim2.new(0, 16, 0, 146)
	contentContainer.BackgroundTransparency = 1
	contentContainer.Parent = mainModal
end

function MarketController.UpdateHeader()
	if balanceLabel then
		balanceLabel.Text = string.format("💎 Spirit Stones: %d", currentStones)
	end
	if rankLabel then
		local rankDef = SectConfig.GetRank(currentRank)
		rankLabel.Text = string.format("🥋 Rank: %s", rankDef.DisplayName)
		rankLabel.TextColor3 = rankDef.TitleColor
	end
	if contributionLabel then
		contributionLabel.Text = string.format("📜 Contribution: %d CP", currentContribution)
	end
	if titleLabel then
		if viewMode == "Market" then
			titleLabel.Text = "AZURE CLOUD SECT — MERCHANT MARKET"
		else
			titleLabel.Text = "AZURE CLOUD SECT — ELDER PAVILION"
		end
	end
end

function MarketController.RenderNavBar()
	navBar:ClearAllChildren()
	local navLayout = Instance.new("UIListLayout")
	navLayout.FillDirection = Enum.FillDirection.Horizontal
	navLayout.Padding = UDim.new(0, 10)
	navLayout.Parent = navBar

	local function AddTab(text: string, tabKey: "Buy" | "Sell" | "Duties")
		local btn = Instance.new("TextButton")
		btn.Size = UDim2.new(0, 140, 1, 0)
		btn.BackgroundColor3 = currentTab == tabKey and Color3.fromRGB(212, 175, 55) or Color3.fromRGB(35, 42, 54)
		btn.Text = text
		btn.TextColor3 = currentTab == tabKey and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(220, 220, 220)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.Parent = navBar

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 6)
		corner.Parent = btn

		btn.MouseButton1Click:Connect(function()
			PlayClickAudio()
			AnimateButtonPress(btn)
			currentTab = tabKey
			MarketController.RenderNavBar()
			MarketController.RenderCurrentTab()
		end)
	end

	if viewMode == "Market" then
		AddTab("🛒 Buy Goods", "Buy")
		AddTab("💰 Sell Items", "Sell")
	else
		AddTab("📜 Sect Duties", "Duties")
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
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 80)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 10)
	grid.Parent = scroll

	for itemId, itemDef in pairs(SectConfig.GetAllMarketItems()) do
		if itemDef.BuyPrice then
			local card = Instance.new("Frame")
			card.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
			card.BorderSizePixel = 0
			card.Parent = scroll

			local cardCorner = Instance.new("UICorner")
			cardCorner.CornerRadius = UDim.new(0, 6)
			cardCorner.Parent = card

			local name = Instance.new("TextLabel")
			name.Size = UDim2.new(0.6, 0, 0.4, 0)
			name.Position = UDim2.new(0, 10, 0, 8)
			name.BackgroundTransparency = 1
			name.Text = itemDef.ItemId
			name.TextColor3 = Color3.fromRGB(255, 255, 255)
			name.Font = Enum.Font.GothamBold
			name.TextSize = 14
			name.TextXAlignment = Enum.TextXAlignment.Left
			name.Parent = card

			local price = Instance.new("TextLabel")
			price.Size = UDim2.new(0.6, 0, 0.4, 0)
			price.Position = UDim2.new(0, 10, 0.45, 0)
			price.BackgroundTransparency = 1
			price.Text = string.format("💎 %d Stones", itemDef.BuyPrice)
			price.TextColor3 = Color3.fromRGB(80, 220, 255)
			price.Font = Enum.Font.GothamMedium
			price.TextSize = 12
			price.TextXAlignment = Enum.TextXAlignment.Left
			price.Parent = card

			local buyBtn = Instance.new("TextButton")
			buyBtn.Size = UDim2.new(0, 75, 0, 32)
			buyBtn.Position = UDim2.new(1, -85, 0.5, 0)
			buyBtn.AnchorPoint = Vector2.new(0, 0.5)
			buyBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
			buyBtn.Text = "Buy"
			buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
			buyBtn.Font = Enum.Font.GothamBold
			buyBtn.TextSize = 13
			buyBtn.Parent = card

			local btnCorner = Instance.new("UICorner")
			btnCorner.CornerRadius = UDim.new(0, 4)
			btnCorner.Parent = buyBtn

			buyBtn.MouseButton1Click:Connect(function()
				PlayClickAudio()
				AnimateButtonPress(buyBtn)
				marketRemote:FireServer({ Action = "BuyItem", ItemId = itemDef.ItemId, Amount = 1 })
			end)
		end
	end
end

function MarketController.RenderSellTab()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.48, 0, 0, 80)
	grid.CellPadding = UDim2.new(0.04, 0, 0, 10)
	grid.Parent = scroll

	local hasSellable = false

	for _, slot in pairs(playerInventoryList) do
		if slot and slot.Count > 0 then
			local itemDef = SectConfig.GetMarketItem(slot.ItemId)
			if itemDef and itemDef.SellPrice > 0 then
				hasSellable = true

				local card = Instance.new("Frame")
				card.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
				card.BorderSizePixel = 0
				card.Parent = scroll

				local cardCorner = Instance.new("UICorner")
				cardCorner.CornerRadius = UDim.new(0, 6)
				cardCorner.Parent = card

				local name = Instance.new("TextLabel")
				name.Size = UDim2.new(0.6, 0, 0.4, 0)
				name.Position = UDim2.new(0, 10, 0, 8)
				name.BackgroundTransparency = 1
				name.Text = string.format("%s (x%d)", slot.ItemId, slot.Count)
				name.TextColor3 = Color3.fromRGB(255, 255, 255)
				name.Font = Enum.Font.GothamBold
				name.TextSize = 13
				name.TextXAlignment = Enum.TextXAlignment.Left
				name.Parent = card

				local payout = Instance.new("TextLabel")
				payout.Size = UDim2.new(0.6, 0, 0.4, 0)
				payout.Position = UDim2.new(0, 10, 0.45, 0)
				payout.BackgroundTransparency = 1
				payout.Text = string.format("Sell: +%d Stones ea", itemDef.SellPrice)
				payout.TextColor3 = Color3.fromRGB(255, 215, 0)
				payout.Font = Enum.Font.GothamMedium
				payout.TextSize = 12
				payout.TextXAlignment = Enum.TextXAlignment.Left
				payout.Parent = card

				local sellBtn = Instance.new("TextButton")
				sellBtn.Size = UDim2.new(0, 75, 0, 32)
				sellBtn.Position = UDim2.new(1, -85, 0.5, 0)
				sellBtn.AnchorPoint = Vector2.new(0, 0.5)
				sellBtn.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
				sellBtn.Text = "Sell 1"
				sellBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
				sellBtn.Font = Enum.Font.GothamBold
				sellBtn.TextSize = 13
				sellBtn.Parent = card

				local btnCorner = Instance.new("UICorner")
				btnCorner.CornerRadius = UDim.new(0, 4)
				btnCorner.Parent = sellBtn

				sellBtn.MouseButton1Click:Connect(function()
					PlayClickAudio()
					AnimateButtonPress(sellBtn)
					marketRemote:FireServer({ Action = "SellItem", ItemId = slot.ItemId, Amount = 1 })
				end)
			end
		end
	end

	if not hasSellable then
		local emptyLabel = Instance.new("TextLabel")
		emptyLabel.Size = UDim2.new(1, 0, 0, 50)
		emptyLabel.BackgroundTransparency = 1
		emptyLabel.Text = "No sellable herbs or materials in your Spirit Pouch."
		emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		emptyLabel.Font = Enum.Font.GothamMedium
		emptyLabel.TextSize = 14
		emptyLabel.Parent = scroll
	end
end

function MarketController.RenderDutiesTab()
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, 0, 1, 0)
	scroll.BackgroundTransparency = 1
	scroll.ScrollBarThickness = 6
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = contentContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 10)
	listLayout.Parent = scroll

	-- Promotion & Stipend Banner Card
	local promoCard = Instance.new("Frame")
	promoCard.Size = UDim2.new(1, -10, 0, 70)
	promoCard.BackgroundColor3 = Color3.fromRGB(35, 45, 60)
	promoCard.BorderSizePixel = 0
	promoCard.Parent = scroll

	local pCorner = Instance.new("UICorner")
	pCorner.CornerRadius = UDim.new(0, 6)
	pCorner.Parent = promoCard

	local stipendBtn = Instance.new("TextButton")
	stipendBtn.Size = UDim2.new(0, 150, 0, 36)
	stipendBtn.Position = UDim2.new(0, 10, 0.5, 0)
	stipendBtn.AnchorPoint = Vector2.new(0, 0.5)
	stipendBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	stipendBtn.Text = "Claim Daily Stipend"
	stipendBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	stipendBtn.Font = Enum.Font.GothamBold
	stipendBtn.TextSize = 12
	stipendBtn.Parent = promoCard

	local sCorner = Instance.new("UICorner")
	sCorner.CornerRadius = UDim.new(0, 4)
	sCorner.Parent = stipendBtn

	stipendBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		AnimateButtonPress(stipendBtn)
		sectRemote:FireServer({ Action = "ClaimDailyStipend" })
	end)

	local promoteBtn = Instance.new("TextButton")
	promoteBtn.Size = UDim2.new(0, 150, 0, 36)
	promoteBtn.Position = UDim2.new(1, -160, 0.5, 0)
	promoteBtn.AnchorPoint = Vector2.new(0, 0.5)
	promoteBtn.BackgroundColor3 = Color3.fromRGB(212, 175, 55)
	promoteBtn.Text = "Request Promotion"
	promoteBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	promoteBtn.Font = Enum.Font.GothamBold
	promoteBtn.TextSize = 12
	promoteBtn.Parent = promoCard

	local prCorner = Instance.new("UICorner")
	prCorner.CornerRadius = UDim.new(0, 4)
	prCorner.Parent = promoteBtn

	promoteBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		AnimateButtonPress(promoteBtn)
		sectRemote:FireServer({ Action = "RequestPromotion" })
	end)

	-- Quests List
	for questId, questDef in pairs(SectConfig.GetAllQuests()) do
		local progress = activeQuests[questId] or { CurrentAmount = 0, TargetAmount = questDef.TargetAmount, Completed = false }

		local qCard = Instance.new("Frame")
		qCard.Size = UDim2.new(1, -10, 0, 80)
		qCard.BackgroundColor3 = Color3.fromRGB(28, 34, 44)
		qCard.BorderSizePixel = 0
		qCard.Parent = scroll

		local qCorner = Instance.new("UICorner")
		qCorner.CornerRadius = UDim.new(0, 6)
		qCorner.Parent = qCard

		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(0.6, 0, 0, 24)
		qTitle.Position = UDim2.new(0, 12, 0, 8)
		qTitle.BackgroundTransparency = 1
		qTitle.Text = string.format("%s (%d/%d)", questDef.Title, progress.CurrentAmount, questDef.TargetAmount)
		qTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
		qTitle.Font = Enum.Font.GothamBold
		qTitle.TextSize = 14
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Parent = qCard

		local qDesc = Instance.new("TextLabel")
		qDesc.Size = UDim2.new(0.6, 0, 0, 20)
		qDesc.Position = UDim2.new(0, 12, 0, 32)
		qDesc.BackgroundTransparency = 1
		qDesc.Text = questDef.Description
		qDesc.TextColor3 = Color3.fromRGB(180, 180, 180)
		qDesc.Font = Enum.Font.Gotham
		qDesc.TextSize = 12
		qDesc.TextXAlignment = Enum.TextXAlignment.Left
		qDesc.Parent = qCard

		local qReward = Instance.new("TextLabel")
		qReward.Size = UDim2.new(0.6, 0, 0, 20)
		qReward.Position = UDim2.new(0, 12, 0, 52)
		qReward.BackgroundTransparency = 1
		qReward.Text = string.format("Rewards: +%d CP | +%d Stones | +%d Qi", questDef.RewardContribution, questDef.RewardSpiritStones, questDef.RewardQi)
		qReward.TextColor3 = Color3.fromRGB(80, 220, 255)
		qReward.Font = Enum.Font.GothamMedium
		qReward.TextSize = 11
		qReward.TextXAlignment = Enum.TextXAlignment.Left
		qReward.Parent = qCard

		local submitBtn = Instance.new("TextButton")
		submitBtn.Size = UDim2.new(0, 95, 0, 34)
		submitBtn.Position = UDim2.new(1, -105, 0.5, 0)
		submitBtn.AnchorPoint = Vector2.new(0, 0.5)
		submitBtn.BackgroundColor3 = progress.Completed and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(60, 65, 75)
		submitBtn.Text = progress.Completed and "Submit" or "In Progress"
		submitBtn.TextColor3 = progress.Completed and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(150, 150, 150)
		submitBtn.Font = Enum.Font.GothamBold
		submitBtn.TextSize = 12
		submitBtn.Parent = qCard

		local subCorner = Instance.new("UICorner")
		subCorner.CornerRadius = UDim.new(0, 4)
		subCorner.Parent = submitBtn

		if progress.Completed then
			submitBtn.MouseButton1Click:Connect(function()
				PlayClickAudio()
				AnimateButtonPress(submitBtn)
				sectRemote:FireServer({ Action = "SubmitQuest", QuestId = questId })
			end)
		end
	end -- Closed the quest loop cleanly
end

function MarketController.Open()
	isOpen = true
	screenGui.Enabled = true
	MarketController.UpdateHeader()
	MarketController.RenderNavBar()
	MarketController.RenderCurrentTab()
end

function MarketController.Close()
	isOpen = false
	screenGui.Enabled = false
end

return MarketController