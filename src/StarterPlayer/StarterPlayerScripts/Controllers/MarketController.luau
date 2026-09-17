--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Authoritative Client-Side Market Controller for SectMerchantMarketGui.
    - Bidirectional handshake with MarketAction remote (BuyItem / SellItem / RequestMarketData)
    - Pouch Inventory sync on open and after every transaction
    - Mode Switching (Buy Goods vs Sell Loot) with "CONFIRM SALE" text toggle
    - Category Filtering (ALL, CORES, ELIXIRS, HERBS) with Swords strictly barred
    - Dynamic Quantity Stepper (- / + / MAX) with real-time Total calculations
    - Clean Non-Hardcoded Empty State displays (EmptyNoticeFrame & EmptyDossierFrame)
    - Global Toast Feedback via HUDController.ShowToast
    - Spring Pop-Up open/close animations and Universal Click SFX (rbxassetid://138567614125924)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local MarketController = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

-- Universal Audio Asset
local CLICK_SFX = "rbxassetid://138567614125924"
local function PlayClick()
	local s = Instance.new("Sound")
	s.SoundId = CLICK_SFX
	s.Volume = 0.55
	s.PlaybackSpeed = math.random(98, 102) / 100
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 1.0)
end

local ICON_PILL = "rbxassetid://136942657595135"

-- GUI Hierarchy References
local marketGui: ScreenGui?
local overlay: Frame?
local mainFrame: Frame?
local windowScale: UIScale?
local headerFrame: Frame?
local titleLabel: TextLabel?
local closeBtn: GuiButton?

-- Upper Currency Badges
local upperFrame: Frame?
local stonesLabel: TextLabel?
local rankLabel: TextLabel?
local cpLabel: TextLabel?

-- Secondary Tabs
local secondaryFrame: Frame?
local tabBuyGoods: GuiButton?
local tabSellLoot: GuiButton?
local filterAll: GuiButton?
local filterCores: GuiButton?
local filterElixirs: GuiButton?
local filterHerbs: GuiButton?

-- Content Containers
local tertiaryFrame: Frame?
local innerFrame1: Frame?
local itemGridScroll: ScrollingFrame?
local templateSlotFrame: GuiButton?
local emptyNoticeFrame: Frame?
local activeSlotClones: { GuiButton } = {}

local innerFrame2: Frame?
local itemSpecsFrame: Frame?
local inspectTopTitle: TextLabel?
local inspectItemImage: ImageLabel?
local inspectGrade: TextLabel?
local inspectSpiritAge: TextLabel?
local inspectEffectsDesc: TextLabel?

local minusBtn: GuiButton?
local plusBtn: GuiButton?
local maxBtn: GuiButton?
local countLabel: TextLabel?

local totalFrame: Frame?
local totalValueLabel: TextLabel?
local confirmExchangeBtn: GuiButton?
local confirmBtnText: TextLabel?
local emptyDossierFrame: Frame?

-- State Variables
local isOpen = false
local currentMode: "Buy" | "Sell" = "Buy"
local currentCategory: "ALL" | "CORES" | "ELIXIRS" | "HERBS" = "ALL"
local selectedItemId: string? = nil
local selectedUnitPrice: number = 0
local selectedQuantity: number = 1
local maxAvailableQuantity: number = 1

local playerInventoryCache: { [any]: { ItemId: string, Count: number, Quality: string? } } = {}

-- Network Remotes
local marketActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent

-- Cached HUDController reference for Global Toast Feedback
local hudControllerRef: any = nil
local function getHUDController(): any
	if not hudControllerRef then
		local ctrl = script.Parent:FindFirstChild("HUDController")
		if ctrl then
			hudControllerRef = require(ctrl)
		end
	end
	return hudControllerRef
end

-- =============================================================================
-- 1. HELPER FUNCTIONS
-- =============================================================================
local function GetItemCategory(itemDef: any): string
	if not itemDef then return "ALL" end
	local id = tostring(itemDef.Id or "")
	local t = tostring(itemDef.Type or ""):lower()
	local cat = tostring(itemDef.Category or ""):lower()

	if t == "core" or cat:find("core") or id:find("Core") then
		return "CORES"
	elseif t == "pill" or t == "consumable" or cat:find("elixir") or id:find("Dan") or id:find("Pill") then
		return "ELIXIRS"
	elseif t == "herb" or t == "material" or cat:find("herb") or id:find("Grass") or id:find("Vine") or id:find("Dew") or id:find("Ash") then
		return "HERBS"
	end
	return "HERBS"
end

local function GetPlayerRank(): string
	local r = LocalPlayer:GetAttribute("SectRank")
	return if type(r) == "string" then r else "OuterDisciple"
end

local function GetPlayerSect(): string
	local s = LocalPlayer:GetAttribute("Sect")
	return if type(s) == "string" then s else "Azure Cloud Sect"
end

local function GetPlayerStones(): number
	local s = LocalPlayer:GetAttribute("SpiritStones")
	return if type(s) == "number" then s else 0
end

local function FormatNumber(n: number): string
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

-- =============================================================================
-- 2. GUI DATA SYNCHRONIZATION
-- =============================================================================
function MarketController.SyncPlayerData()
	if stonesLabel then
		stonesLabel.Text = FormatNumber(GetPlayerStones())
	end
	if rankLabel then
		rankLabel.Text = tostring(GetPlayerRank()):gsub("(%l)(%u)", "%1 %2")
	end
	if cpLabel then
		local cp = LocalPlayer:GetAttribute("ContributionPoints") or 0
		cpLabel.Text = tostring(cp) .. " CP"
	end
end

-- =============================================================================
-- 3. INSPECTION & QUANTITY MATH
-- =============================================================================
function MarketController.UpdateExchangeTotal()
	if countLabel then
		countLabel.Text = tostring(selectedQuantity)
	end

	local totalAmount = selectedQuantity * selectedUnitPrice
	if totalValueLabel then
		if currentMode == "Buy" then
			totalValueLabel.Text = string.format("Total: %s Stones", FormatNumber(totalAmount))
		else
			totalValueLabel.Text = string.format("Total: +%s Stones", FormatNumber(totalAmount))
		end
	end

	if confirmBtnText then
		if currentMode == "Buy" then
			confirmBtnText.Text = "CONFIRM PURCHASE"
		else
			confirmBtnText.Text = "CONFIRM SALE"
		end
	end
end

function MarketController.SelectItem(itemId: string, unitPrice: number, maxStock: number)
	selectedItemId = itemId
	selectedUnitPrice = unitPrice
	selectedQuantity = 1
	maxAvailableQuantity = math.max(1, maxStock)

	local itemDef = ItemConfig.GetItem(itemId)

	-- Show Inspector Panels & Hide Empty Dossier
	if itemSpecsFrame then itemSpecsFrame.Visible = true end
	if totalFrame then totalFrame.Visible = true end
	if confirmExchangeBtn then confirmExchangeBtn.Visible = true end
	if emptyDossierFrame then emptyDossierFrame.Visible = false end

	if inspectTopTitle then
		inspectTopTitle.Text = itemDef and (itemDef.DisplayName or itemDef.Name) or itemId
	end

	if inspectItemImage then
		inspectItemImage.Image = itemDef and (itemDef.Texture or itemDef.Icon or itemDef.IconId) or ICON_PILL
	end

	if inspectGrade then
		local grade = itemDef and (itemDef.Grade or itemDef.Rarity or "Mortal-Rank") or "Mortal-Rank"
		inspectGrade.Text = "Grade: " .. tostring(grade)
	end

	if inspectSpiritAge then
		local age = itemDef and (itemDef.SpiritAge or itemDef.Age or "100-Yr") or "100-Yr"
		inspectSpiritAge.Text = "Spirit Age: " .. tostring(age)
	end

	if inspectEffectsDesc then
		local desc = itemDef and itemDef.Description or "A refined cultivation resource."
		inspectEffectsDesc.Text = desc
	end

	MarketController.UpdateExchangeTotal()
end

function MarketController.ClearSelection()
	selectedItemId = nil
	selectedUnitPrice = 0
	selectedQuantity = 1

	-- Hide Inspector Panels & Show Clean Empty Dossier
	if itemSpecsFrame then itemSpecsFrame.Visible = false end
	if totalFrame then totalFrame.Visible = false end
	if confirmExchangeBtn then confirmExchangeBtn.Visible = false end
	if emptyDossierFrame then emptyDossierFrame.Visible = true end
end

-- =============================================================================
-- 4. GRID POPULATION (BUY CATALOG VS SELL INVENTORY)
-- =============================================================================
function MarketController.PopulateGrid()
	if not itemGridScroll or not templateSlotFrame then return end

	-- Clean old slot clones
	for _, clone in ipairs(activeSlotClones) do
		clone:Destroy()
	end
	table.clear(activeSlotClones)

	MarketController.ClearSelection()
	itemGridScroll.CanvasPosition = Vector2.new(0, 0)

	local itemCount = 0

	if currentMode == "Buy" then
		-- BUY MODE: Load catalog from SectConfig.GetAllMarketItems()
		local catalog = SectConfig.GetAllMarketItems()

		for itemId, vendorItem in pairs(catalog) do
			local def = ItemConfig.GetItem(itemId)
			if not def then continue end

			-- PURGE SWORDS: Weapons are never sold at this general goods merchant
			if def.Type == "Weapon" then continue end

			local category = GetItemCategory(def)
			if currentCategory ~= "ALL" and category ~= currentCategory then
				continue
			end

			itemCount += 1
			local slot = templateSlotFrame:Clone()
			slot.Name = "Slot_" .. itemId
			slot.Visible = true

			local slotImg = slot:FindFirstChild("ItemImage") :: ImageLabel?
			if slotImg then
				slotImg.Image = def.Texture or def.Icon or def.IconId or ICON_PILL
			end

			local descLbl = slot:FindFirstChild("PillDescription") :: TextLabel?
			if descLbl then
				descLbl.Text = def.DisplayName or def.Name or itemId
			end

			local stockLbl = slot:FindFirstChild("StockValue") :: TextLabel?
			if stockLbl then
				local rankReq = tostring(vendorItem.RequiredRank or "OuterDisciple"):gsub("Disciple", ""):gsub("Sect", "")
				stockLbl.Text = "Rank: " .. rankReq
			end

			local buyPrice = vendorItem.BuyPrice or def.Price or 50
			local amtBox = slot:FindFirstChild("Amount")
			local amtTxt = amtBox and amtBox:FindFirstChild("TextLabel") :: TextLabel?
			if amtTxt then
				amtTxt.Text = tostring(buyPrice)
			end

			slot.MouseButton1Click:Connect(function()
				PlayClick()
				MarketController.SelectItem(itemId, buyPrice, 99)
			end)

			slot.Parent = itemGridScroll
			table.insert(activeSlotClones, slot)

			if itemCount == 1 then
				MarketController.SelectItem(itemId, buyPrice, 99)
			end
		end
	else
		-- SELL MODE: Aggregate player pouch inventory by ItemId (Excluding Weapons!)
		local aggregatedPouch: { [string]: number } = {}
		for _, entry in pairs(playerInventoryCache) do
			if entry and entry.ItemId and entry.Count and entry.Count > 0 then
				local def = ItemConfig.GetItem(entry.ItemId)
				-- STRICT BAN: Weapons can never be sold at this merchant
				if def and def.Type ~= "Weapon" then
					aggregatedPouch[entry.ItemId] = (aggregatedPouch[entry.ItemId] or 0) + entry.Count
				end
			end
		end

		for itemId, count in pairs(aggregatedPouch) do
			local def = ItemConfig.GetItem(itemId)
			if not def then continue end

			local category = GetItemCategory(def)
			if currentCategory ~= "ALL" and category ~= currentCategory then
				continue
			end

			itemCount += 1
			local slot = templateSlotFrame:Clone()
			slot.Name = "Slot_Sell_" .. itemId
			slot.Visible = true

			local slotImg = slot:FindFirstChild("ItemImage") :: ImageLabel?
			if slotImg then
				slotImg.Image = def.Texture or def.Icon or def.IconId or ICON_PILL
			end

			local descLbl = slot:FindFirstChild("PillDescription") :: TextLabel?
			if descLbl then
				descLbl.Text = def.DisplayName or def.Name or itemId
			end

			local stockLbl = slot:FindFirstChild("StockValue") :: TextLabel?
			if stockLbl then
				stockLbl.Text = "Owned: " .. tostring(count)
			end

			local unitSellPrice = math.max(1, math.floor((def.SellPrice or def.Price or 20) * 0.6))
			local amtBox = slot:FindFirstChild("Amount")
			local amtTxt = amtBox and amtBox:FindFirstChild("TextLabel") :: TextLabel?
			if amtTxt then
				amtTxt.Text = tostring(unitSellPrice)
			end

			slot.MouseButton1Click:Connect(function()
				PlayClick()
				MarketController.SelectItem(itemId, unitSellPrice, count)
			end)

			slot.Parent = itemGridScroll
			table.insert(activeSlotClones, slot)

			if itemCount == 1 then
				MarketController.SelectItem(itemId, unitSellPrice, count)
			end
		end
	end

	-- Toggle Empty State Panels
	if itemCount == 0 then
		if emptyNoticeFrame then emptyNoticeFrame.Visible = true end
		MarketController.ClearSelection()
	else
		if emptyNoticeFrame then emptyNoticeFrame.Visible = false end
	end
end

-- =============================================================================
-- 5. OPEN & CLOSE ANIMATIONS (SPRING ENGINE)
-- =============================================================================
function MarketController.Open()
	if isOpen or not overlay or not windowScale or not marketGui then return end
	isOpen = true
	PlayClick()

	MarketController.SyncPlayerData()
	marketActionRemote:FireServer({ Action = "RequestMarketData" })

	selectedQuantity = 1
	MarketController.PopulateGrid()

	overlay.BackgroundTransparency = 1
	overlay.Visible = true
	marketGui.Enabled = true
	windowScale.Scale = 0.75

	TweenService:Create(overlay, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.55
	}):Play()

	TweenService:Create(windowScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0
	}):Play()
end

function MarketController.Close()
	if not isOpen or not overlay or not windowScale then return end
	isOpen = false
	PlayClick()

	local scaleTween = TweenService:Create(windowScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0.75 })
	local fadeTween = TweenService:Create(overlay, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})

	scaleTween:Play()
	fadeTween:Play()
	scaleTween.Completed:Connect(function()
		if not isOpen then
			overlay.Visible = false
			windowScale.Scale = 1.0
		end
	end)
end

-- =============================================================================
-- 6. CONFIRM TRANSACTION (SERVER HANDSHAKE)
-- =============================================================================
function MarketController.ConfirmExchange()
	if not selectedItemId or selectedQuantity <= 0 then return end
	PlayClick()

	if currentMode == "Buy" then
		marketActionRemote:FireServer({
			Action = "BuyItem",
			ItemId = selectedItemId,
			Amount = selectedQuantity,
		})
	else
		marketActionRemote:FireServer({
			Action = "SellItem",
			ItemId = selectedItemId,
			Amount = selectedQuantity,
		})
	end
end

-- =============================================================================
-- 7. INITIALIZATION & HIERARCHY BINDINGS
-- =============================================================================
local function BindHierarchy(): boolean
	marketGui = PlayerGui:WaitForChild("SectMerchantMarketGui", 8) :: ScreenGui?
	if not marketGui then return false end

	overlay = marketGui:WaitForChild("OverlayBackdrop", 5) :: Frame?
	if not overlay then return false end

	mainFrame = overlay:WaitForChild("MainFrame", 5) :: Frame?
	if not mainFrame then return false end

	windowScale = mainFrame:FindFirstChild("UIScale") :: UIScale?
	if not windowScale then
		windowScale = Instance.new("UIScale")
		windowScale.Name = "UIScale"
		windowScale.Scale = 1.0
		windowScale.Parent = mainFrame
	end

	headerFrame = mainFrame:FindFirstChild("HeaderFrame") :: Frame?
	if headerFrame then
		titleLabel = headerFrame:FindFirstChild("TitleLabel") :: TextLabel?
		closeBtn = headerFrame:FindFirstChild("CloseImageButton") :: GuiButton?
	end

	upperFrame = mainFrame:FindFirstChild("UpperFrame") :: Frame?
	if upperFrame then
		local left = upperFrame:FindFirstChild("Left")
		stonesLabel = left and left:FindFirstChild("TextLabel") :: TextLabel?
		local center = upperFrame:FindFirstChild("Center")
		rankLabel = center and center:FindFirstChild("TextLabel") :: TextLabel?
		local right = upperFrame:FindFirstChild("Right")
		cpLabel = right and right:FindFirstChild("TextLabel") :: TextLabel?
	end

	secondaryFrame = mainFrame:FindFirstChild("SecondaryFrame") :: Frame?
	if secondaryFrame then
		local tabF1 = secondaryFrame:FindFirstChild("TabFrame")
		if tabF1 then
			tabBuyGoods = tabF1:FindFirstChild("Tab_BUYGOODS") :: GuiButton?
			tabSellLoot = tabF1:FindFirstChild("Tab_SELLLOOT") :: GuiButton?
		end

		local tabF2 = secondaryFrame:FindFirstChild("TabFrame2")
		if tabF2 then
			filterAll = tabF2:FindFirstChild("Tab_ALL") :: GuiButton?
			filterCores = tabF2:FindFirstChild("Tab_CORES") :: GuiButton?
			filterElixirs = tabF2:FindFirstChild("Tab_ELIXIRS") :: GuiButton?
			filterHerbs = tabF2:FindFirstChild("Tab_HERBS") :: GuiButton?
		end
	end

	tertiaryFrame = mainFrame:FindFirstChild("TertiaryFrame") :: Frame?
	if tertiaryFrame then
		innerFrame1 = tertiaryFrame:FindFirstChild("InnerFrame1") :: Frame?
		if innerFrame1 then
			emptyNoticeFrame = innerFrame1:FindFirstChild("EmptyNoticeFrame") :: Frame?
			itemGridScroll = innerFrame1:FindFirstChild("ItemGridScroll") :: ScrollingFrame?
			if itemGridScroll then
				templateSlotFrame = itemGridScroll:FindFirstChild("SlotFrame") :: GuiButton?
				if templateSlotFrame then
					templateSlotFrame.Visible = false
				end
			end
		end

		innerFrame2 = tertiaryFrame:FindFirstChild("InnerFrame2") :: Frame?
		if innerFrame2 then
			emptyDossierFrame = innerFrame2:FindFirstChild("EmptyDossierFrame") :: Frame?
			itemSpecsFrame = innerFrame2:FindFirstChild("ItemSpecsFrame") :: Frame?
			if itemSpecsFrame then
				inspectTopTitle = itemSpecsFrame:FindFirstChild("PillDescription") :: TextLabel?

				local firstInner = itemSpecsFrame:FindFirstChild("FirstInnerFrame")
				if firstInner then
					inspectItemImage = firstInner:FindFirstChild("ItemImage") :: ImageLabel?
					local descF = firstInner:FindFirstChild("DescriptionFrame")
					if descF then
						inspectGrade = descF:FindFirstChild("Grade") :: TextLabel?
						inspectSpiritAge = descF:FindFirstChild("SpiritAge") :: TextLabel?
						inspectEffectsDesc = descF:FindFirstChild("EffectsDescription") :: TextLabel?
					end
				end

				local secondInner = itemSpecsFrame:FindFirstChild("SecondInnerFrame")
				if secondInner then
					minusBtn = secondInner:FindFirstChild("MinusBtn") :: GuiButton?
					plusBtn = secondInner:FindFirstChild("PlusBtn") :: GuiButton?
					maxBtn = secondInner:FindFirstChild("MAXBtn") :: GuiButton?
					local countF = secondInner:FindFirstChild("Count")
					countLabel = countF and countF:FindFirstChild("TextLabel") :: TextLabel?
				end
			end

			totalFrame = innerFrame2:FindFirstChild("TotalFrame") :: Frame?
			totalValueLabel = totalFrame and totalFrame:FindFirstChild("TotalValue") :: TextLabel?

			confirmExchangeBtn = innerFrame2:FindFirstChild("ConfirmExchangeBtn") :: GuiButton?
			confirmBtnText = confirmExchangeBtn and confirmExchangeBtn:FindFirstChild("TextLabel") :: TextLabel?
		end
	end

	return true
end

function MarketController.Init()
	marketActionRemote = RemoteEvents.GetRemote("MarketAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	if not BindHierarchy() then
		warn("[MarketController] Failed to bind GUI hierarchy.")
		return
	end

	-- Connect Close Button
	if closeBtn then
		closeBtn.MouseButton1Click:Connect(MarketController.Close)
	end

	-- Connect Mode Switcher
	if tabBuyGoods then
		tabBuyGoods.MouseButton1Click:Connect(function()
			PlayClick()
			currentMode = "Buy"
			MarketController.PopulateGrid()
		end)
	end

	if tabSellLoot then
		tabSellLoot.MouseButton1Click:Connect(function()
			PlayClick()
			currentMode = "Sell"
			MarketController.PopulateGrid()
		end)
	end

	-- Connect Category Filters
	if filterAll then
		filterAll.MouseButton1Click:Connect(function()
			PlayClick()
			currentCategory = "ALL"
			MarketController.PopulateGrid()
		end)
	end

	if filterCores then
		filterCores.MouseButton1Click:Connect(function()
			PlayClick()
			currentCategory = "CORES"
			MarketController.PopulateGrid()
		end)
	end

	if filterElixirs then
		filterElixirs.MouseButton1Click:Connect(function()
			PlayClick()
			currentCategory = "ELIXIRS"
			MarketController.PopulateGrid()
		end)
	end

	if filterHerbs then
		filterHerbs.MouseButton1Click:Connect(function()
			PlayClick()
			currentCategory = "HERBS"
			MarketController.PopulateGrid()
		end)
	end

	-- Connect Quantity Steppers (- / + / MAX)
	if minusBtn then
		minusBtn.MouseButton1Click:Connect(function()
			PlayClick()
			if selectedQuantity > 1 then
				selectedQuantity -= 1
				MarketController.UpdateExchangeTotal()
			end
		end)
	end

	if plusBtn then
		plusBtn.MouseButton1Click:Connect(function()
			PlayClick()
			if selectedQuantity < maxAvailableQuantity then
				selectedQuantity += 1
				MarketController.UpdateExchangeTotal()
			end
		end)
	end

	if maxBtn then
		maxBtn.MouseButton1Click:Connect(function()
			PlayClick()
			if currentMode == "Buy" and selectedUnitPrice > 0 then
				local maxAffordable = math.floor(GetPlayerStones() / selectedUnitPrice)
				selectedQuantity = math.clamp(maxAffordable, 1, maxAvailableQuantity)
			else
				selectedQuantity = maxAvailableQuantity
			end
			MarketController.UpdateExchangeTotal()
		end)
	end

	-- Connect Confirm Exchange Button
	if confirmExchangeBtn then
		confirmExchangeBtn.MouseButton1Click:Connect(MarketController.ConfirmExchange)
	end

	-- Listen for Server Remotes
	marketActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "OpenShop" then
			MarketController.Open()
		elseif payload.Action == "MarketData" then
			if payload.Inventory then
				playerInventoryCache = payload.Inventory
				if isOpen and currentMode == "Sell" then
					MarketController.PopulateGrid()
				end
			end
		elseif payload.Action == "TransactionSuccess" then
			MarketController.SyncPlayerData()
			if payload.Inventory then
				playerInventoryCache = payload.Inventory
			end
			MarketController.PopulateGrid()

			-- Global Toast Feedback
			local hud = getHUDController()
			if hud and hud.ShowToast then
				local itemDef = if payload.ItemId then ItemConfig.GetItem(payload.ItemId) else nil
				local itemName = if itemDef then (itemDef.DisplayName or itemDef.Name) else (payload.ItemId or "Item")

				if payload.Type == "Buy" then
					hud.ShowToast(string.format("Purchased %dx %s", payload.Amount or 1, itemName), 3.0)
				elseif payload.Type == "Sell" then
					hud.ShowToast(string.format("Sold %dx %s (+%s Stones)", payload.Amount or 1, itemName, FormatNumber(payload.TotalPayout or 0)), 3.0)
				end
			end
		elseif payload.Action == "TransactionFailed" and payload.Message then
			warn("[MarketController] Transaction Failed:", payload.Message)
			local hud = getHUDController()
			if hud and hud.ShowToast then
				hud.ShowToast(payload.Message, 2.5)
			end
		end
	end)

	-- Listen for Inventory Updates
	updateInventoryRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" and payload.Inventory then
			playerInventoryCache = payload.Inventory
			if isOpen and currentMode == "Sell" then
				MarketController.PopulateGrid()
			end
		end
	end)

	-- Real-time Currency Sync
	local currencyAttrs = { "SpiritStones", "ContributionPoints", "SectRank", "Sect" }
	for _, attr in ipairs(currencyAttrs) do
		LocalPlayer:GetAttributeChangedSignal(attr):Connect(MarketController.SyncPlayerData)
	end

	-- Hide modal initially
	if overlay then
		overlay.Visible = false
	end

	print("[ASCEND] MarketController Initialized (Pouch Sync, Global Toasts & Clean Empty States Active).")
end

return MarketController