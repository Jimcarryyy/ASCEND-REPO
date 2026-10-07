--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Directly bound to StarterGui.SectMerchantMarketGui:
    - Master Sect Exchange Pavilion controller
    - Seamlessly wired to the bamboo/cloud Chinese Pavilion hierarchy
    - Fixed: Responsive grid sizing (2-3 items per row on mobile, 4 on desktop)
    - Fixed: Removed static "Stock: 99" from Buy Goods; MAX calculates affordable quantity
    - Fixed: Live inventory synchronization on purchases so bought items appear immediately
    - Fixed: First item selectedGlow activates immediately on tab/mode switch
    - Fixed: Fallback UI display for empty catalog/inventory
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local MarketController = {}
MarketController.__index = MarketController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local marketActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent
local modalManager: any = nil

local function GetModalManager(): any
	if not modalManager then
		local controllers = player:WaitForChild("PlayerScripts"):WaitForChild("Controllers")
		local mod = controllers:FindFirstChild("ModalWindowManager")
		if mod and mod:IsA("ModuleScript") then
			modalManager = require(mod)
		end
	end
	return modalManager
end

local function EmitToast(message: string)
	local controllers = player.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local hudCtrl = controllers:FindFirstChild("HUDController")
		if hudCtrl then
			local req = require(hudCtrl) :: any
			if req and req.ShowToast then
				req.ShowToast(message)
			end
		end
	end
end

local PANEL_CLICK_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.PanelClick) or "rbxassetid://101735926591481"
local function PlayPanelClickSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = PANEL_CLICK_SOUND_ID
	sound.Volume = 0.55
	sound.PlaybackSpeed = math.random(98, 102) / 100
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

-- UI Hierarchy References (SectMerchantMarketGui)
local marketGui: ScreenGui? = nil
local mainFrame: GuiObject? = nil
local windowScale: UIScale? = nil

-- Header & Currencies
local closeBtn: GuiButton? = nil
local stonesLabel: TextLabel? = nil
local rankLabel: TextLabel? = nil
local cpLabel: TextLabel? = nil

-- Tabs (Mode & Category)
local tabBuyGoods: GuiButton? = nil
local tabSellLoot: GuiButton? = nil
local filterAll: GuiButton? = nil
local filterHerbs: GuiButton? = nil
local filterElixirs: GuiButton? = nil
local filterCores: GuiButton? = nil

-- Item Catalog Grid & Fallback Notice
local innerFrame1: GuiObject? = nil
local itemGridScroll: ScrollingFrame? = nil
local gridLayout: UIGridLayout? = nil
local slotTemplate: GuiObject? = nil
local activeSlotClones: { GuiObject } = {}
local emptyCatalogNotice: Frame? = nil
local emptyCatalogLabel: TextLabel? = nil

-- Detail Inspector Pane & Fallback Notice
local innerFrame2: GuiObject? = nil
local itemSpecsFrame: Frame? = nil
local inspectTitle: TextLabel? = nil
local inspectItemImage: ImageLabel? = nil
local inspectGrade: TextLabel? = nil
local inspectSpiritAge: TextLabel? = nil
local inspectEffectsDesc: TextLabel? = nil

-- Quantity Stepper & Total
local minusBtn: GuiButton? = nil
local plusBtn: GuiButton? = nil
local maxBtn: GuiButton? = nil
local countLabel: TextLabel? = nil
local totalFrame: Frame? = nil
local totalValueLabel: TextLabel? = nil
local confirmExchangeBtn: GuiButton? = nil
local confirmBtnText: TextLabel? = nil
local emptyDetailsNotice: Frame? = nil

-- Controller State
local currentMode: "Buy" | "Sell" = "Buy"
local currentCategory: string = "ALL"
local selectedItemId: string? = nil
local currentQuantity: number = 1
local isOpen: boolean = false
local lastOpenTime: number = 0

local serverCatalog: { [string]: any } = {}
local playerInventoryCache: { [string]: number } = {}
local isInitialized: boolean = false

local function FormatNumber(num: number): string
	local formatted = tostring(math.floor(math.abs(num)))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

local function FormatCompact(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function GetItemIcon(itemId: string): string
	if UIAssets.Icons and UIAssets.Icons[itemId] and UIAssets.Icons[itemId] ~= "" then
		return UIAssets.Icons[itemId]
	end
	local def = ItemConfig.GetItem(itemId)
	if def and def.Icon and def.Icon ~= "" then
		return def.Icon
	end
	return (UIAssets.Icons and UIAssets.Icons.SwordPlaceholder) or "rbxassetid://109157084266033"
end

local function GetPlayerItemCount(itemId: string): number
	return playerInventoryCache[itemId] or 0
end

local function IsHerbItem(itemId: string, itemDef: ItemConfig.ItemDefinition): boolean
	local idLower = itemId:lower()
	return idLower:find("grass") ~= nil 
		or idLower:find("vine") ~= nil 
		or idLower:find("lotus") ~= nil 
		or idLower:find("dew") ~= nil 
		or idLower:find("ginseng") ~= nil
		or (itemDef.Type == "Material" and not idLower:find("core") and not idLower:find("ash"))
end

-- Responsive Grid Cell Scaler (2-3 items per row on mobile, 4 on desktop)
function MarketController.UpdateGridCellSize()
	if not itemGridScroll or not gridLayout then return end

	local scrollBarWidth = if itemGridScroll.ScrollBarThickness > 0 then itemGridScroll.ScrollBarThickness else 6
	local containerWidth = itemGridScroll.AbsoluteSize.X - scrollBarWidth - 10

	if containerWidth <= 0 then
		task.defer(MarketController.UpdateGridCellSize)
		return
	end

	local columns = 3
	if containerWidth < 280 then
		columns = 2
	elseif containerWidth > 420 then
		columns = 4
	end

	local padding = 5
	local totalPadding = (columns - 1) * padding
	local exactCellSize = math.floor((containerWidth - totalPadding) / columns)

	gridLayout.CellPadding = UDim2.new(0, padding, 0, padding)
	gridLayout.CellSize = UDim2.new(0, exactCellSize, 0, exactCellSize)
end

local function EnsureUI(): boolean
	if isInitialized and marketGui and marketGui.Parent and mainFrame and mainFrame.Parent then
		return true
	end

	marketActionRemote = RemoteEvents.GetRemote("MarketAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	local legacyGui = playerGui:FindFirstChild("SectMarketGui") or playerGui:FindFirstChild("SectExchangePavilion")
	if legacyGui and legacyGui:IsA("ScreenGui") then
		legacyGui.Enabled = false
	end

	marketGui = (playerGui:FindFirstChild("SectMerchantMarketGui") or playerGui:WaitForChild("SectMerchantMarketGui", 8)) :: ScreenGui?
	if not marketGui then
		warn("[MarketController] SectMerchantMarketGui not found in PlayerGui!")
		return false
	end

	mainFrame = marketGui:FindFirstChild("MainFrame") :: GuiObject?
	if not mainFrame then
		warn("[MarketController] MainFrame not found inside SectMerchantMarketGui!")
		return false
	end

	windowScale = mainFrame:FindFirstChildOfClass("UIScale")
	if not windowScale then
		windowScale = Instance.new("UIScale")
		windowScale.Scale = 1.0
		windowScale.Parent = mainFrame
	end

	-- Header Frame
	local headerFrame = mainFrame:FindFirstChild("HeaderFrame") :: Frame?
	if headerFrame then
		closeBtn = headerFrame:FindFirstChild("CloseImageButton") :: GuiButton?
	end

	-- Upper Frame (Currencies)
	local upperFrame = mainFrame:FindFirstChild("UpperFrame") :: Frame?
	if upperFrame then
		local left = upperFrame:FindFirstChild("Left") :: ImageLabel?
		stonesLabel = if left then left:FindFirstChild("TextLabel") :: TextLabel? else nil

		local center = upperFrame:FindFirstChild("Center") :: ImageLabel?
		rankLabel = if center then center:FindFirstChild("TextLabel") :: TextLabel? else nil

		local right = upperFrame:FindFirstChild("Right") :: ImageLabel?
		cpLabel = if right then right:FindFirstChild("TextLabel") :: TextLabel? else nil
	end

	-- Secondary Frame (Tabs)
	local secFrame = mainFrame:FindFirstChild("SecondaryFrame") :: Frame?
	if secFrame then
		local tabF1 = secFrame:FindFirstChild("TabFrame") :: Frame?
		if tabF1 then
			tabBuyGoods = tabF1:FindFirstChild("Tab_BUYGOODS") :: GuiButton?
			tabSellLoot = tabF1:FindFirstChild("Tab_SELLLOOT") :: GuiButton?
		end

		local tabF2 = secFrame:FindFirstChild("TabFrame2") :: Frame?
		if tabF2 then
			filterAll = tabF2:FindFirstChild("Tab_ALL") :: GuiButton?
			filterHerbs = tabF2:FindFirstChild("Tab_HERBS") :: GuiButton?
			filterElixirs = tabF2:FindFirstChild("Tab_ELIXIRS") :: GuiButton?
			filterCores = tabF2:FindFirstChild("Tab_CORES") :: GuiButton?
		end
	end

	-- Tertiary Frame (Catalog & Inspector)
	local terFrame = mainFrame:FindFirstChild("TertiaryFrame") :: Frame?
	if terFrame then
		innerFrame1 = terFrame:FindFirstChild("InnerFrame1") :: ImageLabel?
		if innerFrame1 then
			emptyCatalogNotice = innerFrame1:FindFirstChild("EmptyCatalogNotice") :: Frame?
			emptyCatalogLabel = if emptyCatalogNotice then emptyCatalogNotice:FindFirstChild("NoticeLabel") :: TextLabel? else nil

			itemGridScroll = innerFrame1:FindFirstChild("ItemGridScroll") :: ScrollingFrame?
			if itemGridScroll then
				itemGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
				itemGridScroll.ScrollBarThickness = 6
				gridLayout = itemGridScroll:FindFirstChildOfClass("UIGridLayout")

				itemGridScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(MarketController.UpdateGridCellSize)
				MarketController.UpdateGridCellSize()

				local existingTemplate = itemGridScroll:FindFirstChild("SlotFrame") :: GuiObject?
				if existingTemplate then
					slotTemplate = existingTemplate:Clone()
					existingTemplate.Visible = false
				end
			end
		end

		innerFrame2 = terFrame:FindFirstChild("InnerFrame2") :: ImageLabel?
		if innerFrame2 then
			emptyDetailsNotice = innerFrame2:FindFirstChild("EmptyDetailsNotice") :: Frame?

			itemSpecsFrame = innerFrame2:FindFirstChild("ItemSpecsFrame") :: Frame?
			if itemSpecsFrame then
				inspectTitle = itemSpecsFrame:FindFirstChild("PillDescription") :: TextLabel?

				local firstInner = itemSpecsFrame:FindFirstChild("FirstInnerFrame") :: Frame?
				if firstInner then
					inspectItemImage = firstInner:FindFirstChild("ItemImage") :: ImageLabel?
					local descFrame = firstInner:FindFirstChild("DescriptionFrame") :: ImageLabel?
					if descFrame then
						inspectGrade = descFrame:FindFirstChild("Grade") :: TextLabel?
						inspectSpiritAge = descFrame:FindFirstChild("SpiritAge") :: TextLabel?
						inspectEffectsDesc = descFrame:FindFirstChild("EffectsDescription") :: TextLabel?
					end
				end

				local secondInner = itemSpecsFrame:FindFirstChild("SecondInnerFrame") :: Frame?
				if secondInner then
					minusBtn = secondInner:FindFirstChild("MinusBtn") :: GuiButton?
					plusBtn = secondInner:FindFirstChild("PlusBtn") :: GuiButton?
					maxBtn = secondInner:FindFirstChild("MAXBtn") :: GuiButton?

					if minusBtn then
						local mLbl = minusBtn:FindFirstChild("TextLabel") or minusBtn:FindFirstChildOfClass("TextLabel")
						if mLbl then mLbl.Text = "-" end
					end
					if plusBtn then
						local pLbl = plusBtn:FindFirstChild("TextLabel") or plusBtn:FindFirstChildOfClass("TextLabel")
						if pLbl then pLbl.Text = "+" end
					end

					local countBox = secondInner:FindFirstChild("Count") :: ImageLabel?
					countLabel = if countBox then countBox:FindFirstChild("TextLabel") :: TextLabel? else nil
				end
			end

			totalFrame = innerFrame2:FindFirstChild("TotalFrame") :: Frame?
			totalValueLabel = if totalFrame then totalFrame:FindFirstChild("TotalValue") :: TextLabel? else nil

			confirmExchangeBtn = innerFrame2:FindFirstChild("ConfirmExchangeBtn") :: GuiButton?
			confirmBtnText = if confirmExchangeBtn then confirmExchangeBtn:FindFirstChild("TextLabel") :: TextLabel? else nil
		end
	end

	-- Wire Button Handlers
	if closeBtn then
		closeBtn.Activated:Connect(function()
			MarketController.Close()
		end)
	end

	if tabBuyGoods then
		tabBuyGoods.Activated:Connect(function()
			PlayPanelClickSFX()
			currentMode = "Buy"
			currentQuantity = 1
			selectedItemId = nil
			MarketController.UpdateTabHighlights()
			MarketController.RenderCatalog()
			if itemGridScroll then itemGridScroll.CanvasPosition = Vector2.zero end
		end)
	end

	if tabSellLoot then
		tabSellLoot.Activated:Connect(function()
			PlayPanelClickSFX()
			currentMode = "Sell"
			currentQuantity = 1
			selectedItemId = nil
			MarketController.UpdateTabHighlights()
			MarketController.RenderCatalog()
			if itemGridScroll then itemGridScroll.CanvasPosition = Vector2.zero end
		end)
	end

	local function hookFilter(btn: GuiButton?, cat: string)
		if btn then
			btn.Activated:Connect(function()
				PlayPanelClickSFX()
				currentCategory = cat
				currentQuantity = 1
				selectedItemId = nil
				MarketController.UpdateTabHighlights()
				MarketController.RenderCatalog()
				if itemGridScroll then itemGridScroll.CanvasPosition = Vector2.zero end
			end)
		end
	end

	hookFilter(filterAll, "ALL")
	hookFilter(filterHerbs, "HERBS")
	hookFilter(filterElixirs, "ELIXIRS")
	hookFilter(filterCores, "CORES")

	if minusBtn then
		minusBtn.Activated:Connect(function()
			PlayPanelClickSFX()
			MarketController.DecrementQuantity()
		end)
	end

	if plusBtn then
		plusBtn.Activated:Connect(function()
			PlayPanelClickSFX()
			MarketController.IncrementQuantity()
		end)
	end

	if maxBtn then
		maxBtn.Activated:Connect(function()
			PlayPanelClickSFX()
			local maxAvail = MarketController.GetMaxPurchasableOrSellable()
			currentQuantity = math.max(1, maxAvail)
			MarketController.UpdateDetailsPane()
		end)
	end

	if confirmExchangeBtn then
		confirmExchangeBtn.Activated:Connect(function()
			PlayPanelClickSFX()
			MarketController.ConfirmTransaction()
		end)
	end

	isInitialized = true
	return true
end

function MarketController.DecrementQuantity()
	currentQuantity = math.max(1, currentQuantity - 1)
	MarketController.UpdateDetailsPane()
end

function MarketController.IncrementQuantity()
	local maxAvail = MarketController.GetMaxPurchasableOrSellable()
	currentQuantity = math.clamp(currentQuantity + 1, 1, math.max(1, maxAvail))
	MarketController.UpdateDetailsPane()
end

function MarketController.UpdateCurrencies()
	local stones = player:GetAttribute("SpiritStones") or 0
	local cp = player:GetAttribute("ContributionPoints") or 0
	local rank = player:GetAttribute("SectRank") or "OuterDisciple"
	local rankDef = SectConfig.GetRank(rank)
	local rankName = if rankDef then rankDef.DisplayName else tostring(rank)

	if stonesLabel then stonesLabel.Text = FormatCompact(tonumber(stones) or 0) end
	if cpLabel then cpLabel.Text = string.format("%d CP", tonumber(cp) or 0) end
	if rankLabel then rankLabel.Text = rankName end
end

function MarketController.UpdateTabHighlights()
	local activeColor = Color3.fromRGB(255, 235, 140)
	local inactiveColor = Color3.fromRGB(180, 195, 215)

	if tabBuyGoods then
		local lbl = tabBuyGoods:FindFirstChildOfClass("TextLabel")
		if lbl then lbl.TextColor3 = (currentMode == "Buy") and activeColor or inactiveColor end
	end
	if tabSellLoot then
		local lbl = tabSellLoot:FindFirstChildOfClass("TextLabel")
		if lbl then lbl.TextColor3 = (currentMode == "Sell") and activeColor or inactiveColor end
	end

	local filters = {
		{ Btn = filterAll, Key = "ALL" },
		{ Btn = filterHerbs, Key = "HERBS" },
		{ Btn = filterElixirs, Key = "ELIXIRS" },
		{ Btn = filterCores, Key = "CORES" },
	}

	for _, f in ipairs(filters) do
		if f.Btn then
			local lbl = f.Btn:FindFirstChildOfClass("TextLabel")
			if lbl then
				lbl.TextColor3 = (currentCategory == f.Key) and activeColor or inactiveColor
			end
		end
	end
end

function MarketController.GetMaxPurchasableOrSellable(): number
	if not selectedItemId then return 1 end

	if currentMode == "Sell" then
		return math.max(1, GetPlayerItemCount(selectedItemId))
	else
		-- Unlimited stock in shop: Max is whatever player can afford
		local entry = serverCatalog[selectedItemId]
		local price = (entry and (entry.BuyPrice or entry.Price)) or 100
		local playerStones = tonumber(player:GetAttribute("SpiritStones")) or 0
		local maxAfford = math.floor(playerStones / math.max(1, price))
		return math.max(1, maxAfford)
	end
end

function MarketController.RenderCatalog()
	for _, clone in ipairs(activeSlotClones) do
		clone:Destroy()
	end
	table.clear(activeSlotClones)

	if not itemGridScroll or not slotTemplate then return end

	MarketController.UpdateGridCellSize()

	local allItems = ItemConfig.GetAllItems()
	local displayList = {}

	if currentMode == "Buy" then
		for itemId, itemDef in pairs(allItems) do
			if itemDef.Type == "Weapon" then continue end

			local passesFilter = false
			if currentCategory == "ALL" then
				passesFilter = true
			elseif currentCategory == "HERBS" and IsHerbItem(itemId, itemDef) then
				passesFilter = true
			elseif currentCategory == "ELIXIRS" and itemDef.Type == "Consumable" then
				passesFilter = true
			elseif currentCategory == "CORES" and string.find(itemId:lower(), "core") ~= nil then
				passesFilter = true
			end

			if passesFilter then
				local entry = serverCatalog[itemId]
				local price = (entry and (entry.BuyPrice or entry.Price)) or (itemDef.AgeYears and itemDef.AgeYears * 15) or 100
				table.insert(displayList, {
					Id = itemId,
					Name = itemDef.Name,
					Price = price,
					Stock = 0,
					Def = itemDef,
				})
			end
		end
	else
		for itemId, count in pairs(playerInventoryCache) do
			if count > 0 then
				local itemDef = ItemConfig.GetItem(itemId)
				if itemDef and itemDef.Type ~= "Weapon" then
					local passesFilter = false
					if currentCategory == "ALL" then
						passesFilter = true
					elseif currentCategory == "HERBS" and IsHerbItem(itemId, itemDef) then
						passesFilter = true
					elseif currentCategory == "ELIXIRS" and itemDef.Type == "Consumable" then
						passesFilter = true
					elseif currentCategory == "CORES" and string.find(itemId:lower(), "core") ~= nil then
						passesFilter = true
					end

					if passesFilter then
						local entry = serverCatalog[itemId]
						local sellPrice = (entry and entry.SellPrice) or math.floor(((itemDef.AgeYears and itemDef.AgeYears * 10) or 12) * 0.7)
						table.insert(displayList, {
							Id = itemId,
							Name = itemDef.Name,
							Price = sellPrice,
							Stock = count,
							Def = itemDef,
						})
					end
				end
			end
		end
	end

	table.sort(displayList, function(a, b)
		return a.Name < b.Name
	end)

	if #displayList > 0 then
		local hasSelected = false
		for _, it in ipairs(displayList) do
			if it.Id == selectedItemId then
				hasSelected = true
				break
			end
		end
		if not hasSelected then
			selectedItemId = displayList[1].Id
			currentQuantity = 1
		end
	else
		selectedItemId = nil
		currentQuantity = 1
	end

	if #displayList == 0 then
		if emptyCatalogNotice then
			if emptyCatalogLabel then
				emptyCatalogLabel.Text = (currentMode == "Sell")
					and ("NO " .. currentCategory .. " IN SPIRIT POUCH")
					or "NO COMMODITIES IN THIS CATEGORY"
			end
			emptyCatalogNotice.Visible = true
		end
		itemGridScroll.Visible = false
	else
		if emptyCatalogNotice then emptyCatalogNotice.Visible = false end
		itemGridScroll.Visible = true
	end

	for _, itemData in ipairs(displayList) do
		local slotClone = slotTemplate:Clone()
		slotClone.Name = "Slot_" .. itemData.Id
		slotClone.Visible = true

		local descLbl = slotClone:FindFirstChild("PillDescription") :: TextLabel?
		if descLbl then descLbl.Text = itemData.Name end

		-- Hide StockValue completely in Buy Goods (infinite shop commodity)
		local stockLbl = slotClone:FindFirstChild("StockValue") :: TextLabel?
		if stockLbl then
			if currentMode == "Buy" then
				stockLbl.Visible = false
				stockLbl.Text = ""
			else
				stockLbl.Visible = true
				stockLbl.Text = string.format("Owned: %d", itemData.Stock)
			end
		end

		local amtBox = slotClone:FindFirstChild("Amount") :: ImageLabel?
		local priceLbl = if amtBox then amtBox:FindFirstChild("TextLabel") :: TextLabel? else nil
		if priceLbl then
			priceLbl.Text = tostring(itemData.Price)
		end

		local itemImg = slotClone:FindFirstChild("ItemImage") :: ImageLabel?
		if itemImg then
			itemImg.Image = GetItemIcon(itemData.Id)
		end

		local selGlow = slotClone:FindFirstChild("SelectedGlow") :: ImageLabel?
		if selGlow then
			selGlow.Visible = (selectedItemId == itemData.Id)
		end

		slotClone.Activated:Connect(function()
			PlayPanelClickSFX()
			selectedItemId = itemData.Id
			currentQuantity = 1
			MarketController.UpdateDetailsPane()
			MarketController.RenderCatalog()
		end)

		slotClone.Parent = itemGridScroll
		table.insert(activeSlotClones, slotClone)
	end

	MarketController.UpdateDetailsPane()
end

function MarketController.UpdateDetailsPane()
	if not selectedItemId then
		if itemSpecsFrame then itemSpecsFrame.Visible = false end
		if totalFrame then totalFrame.Visible = false end
		if confirmExchangeBtn then confirmExchangeBtn.Visible = false end

		if emptyDetailsNotice then
			local titleLbl = emptyDetailsNotice:FindFirstChild("NoticeTitle") :: TextLabel?
			if titleLbl then
				titleLbl.Text = (currentMode == "Sell") and "SPIRIT POUCH EMPTY" or "NO ITEM SELECTED"
			end
			emptyDetailsNotice.Visible = true
		end
		return
	end

	if emptyDetailsNotice then emptyDetailsNotice.Visible = false end
	if itemSpecsFrame then itemSpecsFrame.Visible = true end
	if totalFrame then totalFrame.Visible = true end
	if confirmExchangeBtn then confirmExchangeBtn.Visible = true end

	local def = ItemConfig.GetItem(selectedItemId)
	if not def then return end

	if inspectTitle then inspectTitle.Text = def.Name end
	if inspectItemImage then inspectItemImage.Image = GetItemIcon(selectedItemId) end
	if inspectGrade then inspectGrade.Text = string.format("Grade: %s-Rank", def.Rarity or "Mortal") end
	if inspectSpiritAge then
		inspectSpiritAge.Text = string.format("Spirit Age: %s", def.AgeYears and (def.AgeYears .. "-Yr") or "Standard")
	end
	if inspectEffectsDesc then
		inspectEffectsDesc.Text = def.Description or "Purified spiritual catalyst."
	end

	if countLabel then countLabel.Text = tostring(currentQuantity) end

	local entry = serverCatalog[selectedItemId]
	local unitPrice = (entry and (entry.BuyPrice or entry.Price)) or (def.AgeYears and def.AgeYears * 15) or 100
	if currentMode == "Sell" then
		unitPrice = (entry and entry.SellPrice) or math.floor(((def.AgeYears and def.AgeYears * 10) or 12) * 0.7)
	end

	local totalCost = unitPrice * currentQuantity
	if totalValueLabel then
		totalValueLabel.Text = (currentMode == "Buy")
			and string.format("Total: %s Stones", FormatNumber(totalCost))
			or string.format("Total: +%s Stones", FormatNumber(totalCost))
	end

	if confirmBtnText then
		confirmBtnText.Text = (currentMode == "Buy") and "CONFIRM EXCHANGE" or "CONFIRM SALE"
	end
end

function MarketController.ConfirmTransaction()
	if not selectedItemId or currentQuantity <= 0 then return end

	if currentMode == "Buy" then
		marketActionRemote:FireServer({
			Action = "BuyItem",
			ItemId = selectedItemId,
			Amount = currentQuantity,
		})
	else
		marketActionRemote:FireServer({
			Action = "SellItem",
			ItemId = selectedItemId,
			Amount = currentQuantity,
		})
	end
end

function MarketController.Open()
	local now = os.clock()
	if isOpen or (now - lastOpenTime < 0.35) then return end
	lastOpenTime = now
	isOpen = true

	if not EnsureUI() or not marketGui or not mainFrame then return end

	local mgr = GetModalManager()
	if mgr then mgr.RequestOpen("Market") end

	PlayPanelClickSFX()

	marketGui.Enabled = true
	mainFrame.Visible = true

	if windowScale then
		windowScale.Scale = 0.75
		TweenService:Create(windowScale, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.0
		}):Play()
	end

	MarketController.UpdateCurrencies()
	MarketController.UpdateTabHighlights()
	MarketController.UpdateGridCellSize()
	MarketController.RenderCatalog()
	MarketController.UpdateDetailsPane()

	if itemGridScroll then
		itemGridScroll.CanvasPosition = Vector2.zero
	end

	marketActionRemote:FireServer({ Action = "RequestMarketData" })
end

function MarketController.Close()
	if not isOpen or not marketGui or not mainFrame then return end
	isOpen = false
	PlayPanelClickSFX()

	local mgr = GetModalManager()
	if mgr then mgr.NotifyClosed("Market") end

	mainFrame.Visible = false
	marketGui.Enabled = false
end

function MarketController.Toggle()
	if isOpen then
		MarketController.Close()
	else
		MarketController.Open()
	end
end

function MarketController.IsOpen(): boolean
	return isOpen
end

local function UpdateInventoryFromData(inventoryData: any)
	if type(inventoryData) ~= "table" then return end
	table.clear(playerInventoryCache)

	for _, slot in pairs(inventoryData) do
		if type(slot) == "table" and slot.ItemId and slot.Count then
			local id = tostring(slot.ItemId)
			local count = tonumber(slot.Count) or 1
			playerInventoryCache[id] = (playerInventoryCache[id] or 0) + count
		end
	end

	if isOpen then
		MarketController.RenderCatalog()
		MarketController.UpdateDetailsPane()
	end
end

function MarketController.Init()
	EnsureUI()

	marketActionRemote = RemoteEvents.GetRemote("MarketAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	marketActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "OpenShop" then
			MarketController.Open()

		elseif payload.Action == "MarketData" then
			if type(payload.Catalog) == "table" then
				serverCatalog = payload.Catalog
			end
			if type(payload.Inventory) == "table" then
				UpdateInventoryFromData(payload.Inventory)
			end
			if isOpen then
				MarketController.RenderCatalog()
				MarketController.UpdateDetailsPane()
			end

		elseif payload.Action == "TransactionSuccess" then
			EmitToast(string.format("%s %dx %s Successful!",
				(payload.Type == "Buy") and "Purchased" or "Sold",
				payload.Amount or 1,
				payload.ItemId or "Item"))

			currentQuantity = 1

			-- Instantly update cached inventory with server-returned inventory
			if type(payload.Inventory) == "table" then
				UpdateInventoryFromData(payload.Inventory)
			end
			MarketController.UpdateCurrencies()
			MarketController.RenderCatalog()
			MarketController.UpdateDetailsPane()

		elseif payload.Action == "TransactionFailed" then
			EmitToast(payload.Message or "Transaction Failed!")
		end
	end)

	updateInventoryRemote.OnClientEvent:Connect(UpdateInventoryFromData)

	player:GetAttributeChangedSignal("SpiritStones"):Connect(MarketController.UpdateCurrencies)
	player:GetAttributeChangedSignal("ContributionPoints"):Connect(MarketController.UpdateCurrencies)
	player:GetAttributeChangedSignal("SectRank"):Connect(MarketController.UpdateCurrencies)

	print("[ASCEND] MarketController Initialized (Responsive Mobile Grid & Live Sync Active).")
end

return MarketController