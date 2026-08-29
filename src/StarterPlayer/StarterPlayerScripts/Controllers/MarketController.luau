--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Bound directly to Studio StarterGui.SectMerchantMarketGui hierarchy:
    - Zero hardcoded UI elements / positions
    - Binds to HeaderFrame, UpperFrame, SecondaryFrame, and TertiaryFrame
    - Real-time sync with ItemConfig, SectConfig, VendorManager, and PlayerDataManager
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local MarketController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Network Remotes
local marketActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent

-- GUI Root & Frames (from SectMerchantMarketGui hierarchy)
local marketGui: ScreenGui?
local mainFrame: ImageLabel?
local headerFrame: Frame?
local upperFrame: Frame?
local secondaryFrame: Frame?
local tertiaryFrame: Frame?

-- Header & Close
local closeBtn: ImageButton?
local titleLabel: TextLabel?

-- UpperFrame Stats (Left = Stones, Center = Rank, Right = CP)
local stonesLabel: TextLabel?
local rankLabel: TextLabel?
local cpLabel: TextLabel?

-- SecondaryFrame (Tabs & Filters)
local tabBuyGoods: ImageButton?
local tabSellLoot: ImageButton?
local filterAll: ImageButton?
local filterCores: ImageButton?
local filterElixirs: ImageButton?
local filterHerbs: ImageButton?
local filterTalismans: ImageButton?

-- TertiaryFrame -> InnerFrame1 (Item Catalog Grid)
local itemGridScroll: ScrollingFrame?
local templateSlotFrame: ImageLabel?

-- TertiaryFrame -> InnerFrame2 (Inspect & Checkout Panel)
local inspectItemImage: ImageLabel?
local inspectPillName: TextLabel?
local inspectGrade: TextLabel?
local inspectSpiritAge: TextLabel?
local inspectEffectsDesc: TextLabel?
local countLabel: TextLabel?
local minusBtn: ImageButton?
local plusBtn: ImageButton?
local maxBtn: ImageButton?
local totalValueLabel: TextLabel?
local confirmExchangeBtn: ImageButton?
local confirmBtnText: TextLabel?

-- Controller State
local currentMode: "Buy" | "Sell" = "Buy"
local currentCategory: "ALL" | "CORES" | "ELIXIRS" | "HERBS" | "TALISMANS" = "ALL"
local selectedItemId: string? = nil
local selectedQuantity: number = 1
local currentInventory: { [number]: { ItemId: string, Count: number, Quality: any? } } = {}
local activeSlotClones: { Instance } = {}

local function PlayClickSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://101735926591481"
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

local function FormatNum(val: number): string
	return CultivationConfig.FormatNumber(val)
end

local function FormatRank(rawRank: any): string
	local rankDef = SectConfig.GetRank(tostring(rawRank) :: any)
	return if rankDef then rankDef.DisplayName:upper() else tostring(rawRank or "OUTER DISCIPLE"):upper()
end

-- =============================================================================
-- HIERARCHY LOCATOR & BINDING
-- =============================================================================
local function BindHierarchy(): boolean
	marketGui = PlayerGui:WaitForChild("SectMerchantMarketGui", 8) :: ScreenGui?
	if not marketGui then return false end

	mainFrame = marketGui:FindFirstChild("MainFrame") :: ImageLabel?
	if not mainFrame then return false end

	-- 1. HeaderFrame
	headerFrame = mainFrame:FindFirstChild("HeaderFrame") :: Frame?
	if headerFrame then
		closeBtn = headerFrame:FindFirstChild("CloseImageButton") :: ImageButton?
		titleLabel = headerFrame:FindFirstChild("TitleLabel") :: TextLabel?
	end

	-- 2. UpperFrame (Left = Stones, Center = Rank, Right = CP)
	upperFrame = mainFrame:FindFirstChild("UpperFrame") :: Frame?
	if upperFrame then
		local leftFrame = upperFrame:FindFirstChild("Left")
		if leftFrame then stonesLabel = leftFrame:FindFirstChild("TextLabel") :: TextLabel? end

		local centerFrame = upperFrame:FindFirstChild("Center")
		if centerFrame then rankLabel = centerFrame:FindFirstChild("TextLabel") :: TextLabel? end

		local rightFrame = upperFrame:FindFirstChild("Right")
		if rightFrame then cpLabel = rightFrame:FindFirstChild("TextLabel") :: TextLabel? end
	end

	-- 3. SecondaryFrame (TabFrame & TabFrame2)
	secondaryFrame = mainFrame:FindFirstChild("SecondaryFrame") :: Frame?
	if secondaryFrame then
		local tabFrame = secondaryFrame:FindFirstChild("TabFrame")
		if tabFrame then
			tabBuyGoods = tabFrame:FindFirstChild("Tab_BUYGOODS") :: ImageButton?
			tabSellLoot = tabFrame:FindFirstChild("Tab_SELLLOOT") :: ImageButton?
		end

		local tabFrame2 = secondaryFrame:FindFirstChild("TabFrame2")
		if tabFrame2 then
			filterAll = tabFrame2:FindFirstChild("Tab_ALL") :: ImageButton?
			filterCores = tabFrame2:FindFirstChild("Tab_CORES") :: ImageButton?
			filterElixirs = tabFrame2:FindFirstChild("Tab_ELIXIRS") :: ImageButton?
			filterHerbs = tabFrame2:FindFirstChild("Tab_HERBS") :: ImageButton?
			filterTalismans = tabFrame2:FindFirstChild("Tab_TALISMANS") :: ImageButton?
		end
	end

	-- 4. TertiaryFrame (InnerFrame1 = Grid, InnerFrame2 = Inspect)
	tertiaryFrame = mainFrame:FindFirstChild("TertiaryFrame") :: Frame?
	if tertiaryFrame then
		-- InnerFrame1
		local inner1 = tertiaryFrame:FindFirstChild("InnerFrame1")
		if inner1 then
			itemGridScroll = inner1:FindFirstChild("ItemGridScroll") :: ScrollingFrame?
			if itemGridScroll then
				templateSlotFrame = itemGridScroll:FindFirstChild("SlotFrame") :: ImageLabel?
				if templateSlotFrame then
					templateSlotFrame.Visible = false -- Hide template from display
				end
			end
		end

		-- InnerFrame2
		local inner2 = tertiaryFrame:FindFirstChild("InnerFrame2")
		if inner2 then
			local totalFrame = inner2:FindFirstChild("TotalFrame")
			if totalFrame then
				totalValueLabel = totalFrame:FindFirstChild("TotalValue") :: TextLabel?
			end

			confirmExchangeBtn = inner2:FindFirstChild("ConfirmExchangeBtn") :: ImageButton?
			if confirmExchangeBtn then
				confirmBtnText = confirmExchangeBtn:FindFirstChild("TextLabel") :: TextLabel?
			end

			local specsFrame = inner2:FindFirstChild("ItemSpecsFrame")
			if specsFrame then
				local firstInner = specsFrame:FindFirstChild("FirstInnerFrame")
				if firstInner then
					inspectItemImage = firstInner:FindFirstChild("ItemImage") :: ImageLabel?
					local descFrame = firstInner:FindFirstChild("DescriptionFrame")
					if descFrame then
						inspectGrade = descFrame:FindFirstChild("Grade") :: TextLabel?
						inspectSpiritAge = descFrame:FindFirstChild("SpiritAge") :: TextLabel?
						inspectEffectsDesc = descFrame:FindFirstChild("EffectsDescription") :: TextLabel?
					end
				end

				local secondInner = specsFrame:FindFirstChild("SecondInnerFrame")
				if secondInner then
					inspectPillName = secondInner:FindFirstChild("PillDescription") :: TextLabel?
					minusBtn = secondInner:FindFirstChild("MinusBtn") :: ImageButton?
					plusBtn = secondInner:FindFirstChild("PlusBtn") :: ImageButton?
					maxBtn = secondInner:FindFirstChild("MAXBtn") :: ImageButton?
					local countFrame = secondInner:FindFirstChild("Count")
					if countFrame then
						countLabel = countFrame:FindFirstChild("TextLabel") :: TextLabel?
					end
				end
			end
		end
	end

	return true
end

-- =============================================================================
-- DATA REFRESH & INSPECT LOGIC
-- =============================================================================
local function GetItemCategory(itemDef: ItemConfig.ItemDefinition): string
	if itemDef.Id == "DemonBeastCore" or itemDef.Type == "Crest" then
		return "CORES"
	elseif itemDef.Type == "Consumable" or itemDef.Id:match("Dan$") or itemDef.Id:match("Pill$") then
		return "ELIXIRS"
	elseif itemDef.Type == "Material" then
		return "HERBS"
	elseif itemDef.Type == ("Talisman" :: any) then
		return "TALISMANS"
	end
	return "HERBS"
end

local function GetMaxAffordableCount(unitPrice: number, ownedAmount: number): number
	if currentMode == "Buy" then
		local stones = tonumber(LocalPlayer:GetAttribute("SpiritStones")) or 0
		if unitPrice <= 0 then return 99 end
		return math.clamp(math.floor(stones / unitPrice), 1, 99)
	else
		return math.max(1, ownedAmount)
	end
end

local function UpdateInspectPanel()
	if not selectedItemId then
		if inspectPillName then inspectPillName.Text = "SELECT AN ITEM" end
		if inspectGrade then inspectGrade.Text = "Grade: ---" end
		if inspectSpiritAge then inspectSpiritAge.Text = "Spirit Age: ---" end
		if inspectEffectsDesc then inspectEffectsDesc.Text = "Select an item to view effects." end
		if totalValueLabel then totalValueLabel.Text = "Total: 0 Stones" end
		if countLabel then countLabel.Text = "0" end
		return
	end

	local itemDef = ItemConfig.GetItem(selectedItemId)
	local vendorDef = SectConfig.GetMarketItem(selectedItemId)
	if not itemDef then return end

	local unitPrice = if currentMode == "Buy" then (vendorDef and vendorDef.BuyPrice or 50) else (vendorDef and vendorDef.SellPrice or 20)

	-- 1. Display Details
	if inspectItemImage then
		inspectItemImage.Image = itemDef.Icon or ""
	end
	if inspectPillName then
		inspectPillName.Text = itemDef.Name
	end
	if inspectGrade then
		inspectGrade.Text = string.format("Grade: %s-Rank", itemDef.Rarity)
	end
	if inspectSpiritAge then
		inspectSpiritAge.Text = if itemDef.AgeYears then string.format("Spirit Age: %d-Yr", itemDef.AgeYears) else "Spirit Age: Immortal"
	end
	if inspectEffectsDesc then
		if itemDef.Stats and itemDef.Stats.QiGrant then
			inspectEffectsDesc.Text = string.format("+%s Usable Qi", FormatNum(itemDef.Stats.QiGrant))
		elseif itemDef.Stats and itemDef.Stats.HealAmount then
			inspectEffectsDesc.Text = string.format("+%s Health Recovery", FormatNum(itemDef.Stats.HealAmount))
		else
			inspectEffectsDesc.Text = itemDef.Description
		end
	end

	-- 2. Quantity & Total Cost
	if countLabel then
		countLabel.Text = tostring(selectedQuantity)
	end

	local totalCost = unitPrice * selectedQuantity
	if totalValueLabel then
		totalValueLabel.Text = string.format("Total: %s Stones", FormatNum(totalCost))
	end

	if confirmBtnText then
		confirmBtnText.Text = if currentMode == "Buy" then "CONFIRM EXCHANGE" else "SELL ITEMS"
	end
end

local function PopulateGrid()
	if not itemGridScroll or not templateSlotFrame then return end

	-- Clean up previous cloned tiles
	for _, clone in ipairs(activeSlotClones) do
		clone:Destroy()
	end
	table.clear(activeSlotClones)

	local candidateItems: { { ItemId: string, UnitPrice: number, StockOrOwned: string, Count: number } } = {}

	if currentMode == "Buy" then
		local catalog = SectConfig.GetAllMarketItems()
		for itemId, vendorItem in pairs(catalog) do
			if vendorItem.BuyPrice then
				local itemDef = ItemConfig.GetItem(itemId)
				if itemDef then
					local itemCat = GetItemCategory(itemDef)
					if currentCategory == "ALL" or currentCategory == itemCat then
						table.insert(candidateItems, {
							ItemId = itemId,
							UnitPrice = vendorItem.BuyPrice,
							StockOrOwned = string.format("Rank: %s", vendorItem.RequiredRank:gsub("Disciple", "")),
							Count = 99,
						})
					end
				end
			end
		end
	else
		-- Sell Mode: Group inventory by ItemId
		local inventoryCounts: { [string]: number } = {}
		for _, slotData in pairs(currentInventory) do
			if slotData and slotData.ItemId then
				inventoryCounts[slotData.ItemId] = (inventoryCounts[slotData.ItemId] or 0) + (slotData.Count or 1)
			end
		end

		for itemId, count in pairs(inventoryCounts) do
			local itemDef = ItemConfig.GetItem(itemId)
			local vendorItem = SectConfig.GetMarketItem(itemId)
			if itemDef and vendorItem and vendorItem.SellPrice > 0 then
				local itemCat = GetItemCategory(itemDef)
				if currentCategory == "ALL" or currentCategory == itemCat then
					table.insert(candidateItems, {
						ItemId = itemId,
						UnitPrice = vendorItem.SellPrice,
						StockOrOwned = string.format("Stock: %d", count),
						Count = count,
					})
				end
			end
		end
	end

	-- Create Clones
	for _, itemInfo in ipairs(candidateItems) do
		local itemDef = ItemConfig.GetItem(itemInfo.ItemId)
		if not itemDef then continue end

		local slot = templateSlotFrame:Clone()
		slot.Name = "Slot_" .. itemInfo.ItemId
		slot.Visible = true
		slot.Parent = itemGridScroll
		table.insert(activeSlotClones, slot)

		local iconImg = slot:FindFirstChild("ItemImage") :: ImageLabel?
		if iconImg then iconImg.Image = itemDef.Icon or "" end

		local pillDesc = slot:FindFirstChild("PillDescription") :: TextLabel?
		if pillDesc then pillDesc.Text = itemDef.Name end

		local stockLbl = slot:FindFirstChild("StockValue") :: TextLabel?
		if stockLbl then stockLbl.Text = itemInfo.StockOrOwned end

		local amountFrame = slot:FindFirstChild("Amount")
		if amountFrame then
			local priceLbl = amountFrame:FindFirstChild("TextLabel") :: TextLabel?
			if priceLbl then priceLbl.Text = tostring(itemInfo.UnitPrice) end
		end

		-- Click selection
		local clickTrigger = slot:FindFirstChildWhichIsA("GuiButton") or slot
		if clickTrigger:IsA("GuiButton") then
			clickTrigger.MouseButton1Click:Connect(function()
				PlayClickSound()
				selectedItemId = itemInfo.ItemId
				selectedQuantity = 1
				UpdateInspectPanel()
			end)
		else
			slot.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					PlayClickSound()
					selectedItemId = itemInfo.ItemId
					selectedQuantity = 1
					UpdateInspectPanel()
				end
			end)
		end
	end

	-- Auto-select first item if current selection is invalid
	if #candidateItems > 0 and (not selectedItemId or not ItemConfig.GetItem(selectedItemId)) then
		selectedItemId = candidateItems[1].ItemId
		selectedQuantity = 1
	elseif #candidateItems == 0 then
		selectedItemId = nil
	end

	UpdateInspectPanel()
end

-- =============================================================================
-- EVENT LISTENERS & LIFECYCLE
-- =============================================================================
function MarketController.SyncPlayerData()
	local stones = tonumber(LocalPlayer:GetAttribute("SpiritStones")) or 0
	local rank = LocalPlayer:GetAttribute("SectRank") or LocalPlayer:GetAttribute("Rank") or "OuterDisciple"
	local cp = tonumber(LocalPlayer:GetAttribute("ContributionPoints")) or 0

	if stonesLabel then stonesLabel.Text = FormatNum(stones) end
	if rankLabel then rankLabel.Text = FormatRank(rank) end
	if cpLabel then cpLabel.Text = string.format("%s CP", FormatNum(cp)) end
end

function MarketController.Open()
	if not marketGui and not BindHierarchy() then return end
	if not marketGui or not mainFrame then return end

	MarketController.SyncPlayerData()
	selectedQuantity = 1
	PopulateGrid()
	mainFrame.Visible = true
	marketGui.Enabled = true
end

function MarketController.Close()
	if mainFrame then mainFrame.Visible = false end
	if marketGui then marketGui.Enabled = false end
end

function MarketController.Toggle()
	if marketGui and marketGui.Enabled and mainFrame and mainFrame.Visible then
		MarketController.Close()
	else
		MarketController.Open()
	end
end

function MarketController.Init()
	marketActionRemote = RemoteEvents.GetRemote("MarketAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	if not BindHierarchy() then
		PlayerGui.ChildAdded:Connect(function(child)
			if child.Name == "SectMerchantMarketGui" then
				BindHierarchy()
			end
		end)
	end

	-- 1. Close Button
	if closeBtn then
		closeBtn.MouseButton1Click:Connect(function()
			PlayClickSound()
			MarketController.Close()
		end)
	end

	-- 2. Buy / Sell Tabs
	if tabBuyGoods then
		tabBuyGoods.MouseButton1Click:Connect(function()
			PlayClickSound()
			currentMode = "Buy"
			selectedQuantity = 1
			PopulateGrid()
		end)
	end

	if tabSellLoot then
		tabSellLoot.MouseButton1Click:Connect(function()
			PlayClickSound()
			currentMode = "Sell"
			selectedQuantity = 1
			PopulateGrid()
		end)
	end

	-- 3. Category Filter Buttons
	local function BindFilter(btn: ImageButton?, category: any)
		if not btn then return end
		btn.MouseButton1Click:Connect(function()
			PlayClickSound()
			currentCategory = category
			selectedQuantity = 1
			PopulateGrid()
		end)
	end

	BindFilter(filterAll, "ALL")
	BindFilter(filterCores, "CORES")
	BindFilter(filterElixirs, "ELIXIRS")
	BindFilter(filterHerbs, "HERBS")
	BindFilter(filterTalismans, "TALISMANS")

	-- 4. Quantity Adjusters (- / + / MAX)
	if minusBtn then
		minusBtn.MouseButton1Click:Connect(function()
			PlayClickSound()
			selectedQuantity = math.max(1, selectedQuantity - 1)
			UpdateInspectPanel()
		end)
	end

	if plusBtn then
		plusBtn.MouseButton1Click:Connect(function()
			PlayClickSound()
			if selectedItemId then
				local vendorDef = SectConfig.GetMarketItem(selectedItemId)
				local unitPrice = if currentMode == "Buy" then (vendorDef and vendorDef.BuyPrice or 50) else (vendorDef and vendorDef.SellPrice or 20)
				local maxCap = GetMaxAffordableCount(unitPrice, 99)
				selectedQuantity = math.min(maxCap, selectedQuantity + 1)
			else
				selectedQuantity = selectedQuantity + 1
			end
			UpdateInspectPanel()
		end)
	end

	if maxBtn then
		maxBtn.MouseButton1Click:Connect(function()
			PlayClickSound()
			if selectedItemId then
				local vendorDef = SectConfig.GetMarketItem(selectedItemId)
				local unitPrice = if currentMode == "Buy" then (vendorDef and vendorDef.BuyPrice or 50) else (vendorDef and vendorDef.SellPrice or 20)
				selectedQuantity = GetMaxAffordableCount(unitPrice, 99)
			end
			UpdateInspectPanel()
		end)
	end

	-- 5. Confirm Exchange Button (Fires real VendorManager remotes)
	if confirmExchangeBtn then
		confirmExchangeBtn.MouseButton1Click:Connect(function()
			PlayClickSound()
			if not selectedItemId or selectedQuantity <= 0 then return end

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
		end)
	end

	-- 6. Server Response & Inventory Listeners
	marketActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		if payload.Action == "OpenShop" then
			MarketController.Open()
		elseif payload.Action == "TransactionSuccess" then
			MarketController.SyncPlayerData()
			selectedQuantity = 1
			PopulateGrid()
		end
	end)

	updateInventoryRemote.OnClientEvent:Connect(function(invData: { [number]: any })
		currentInventory = invData or {}
		if marketGui and marketGui.Enabled and currentMode == "Sell" then
			PopulateGrid()
		end
	end)

	LocalPlayer:GetAttributeChangedSignal("SpiritStones"):Connect(MarketController.SyncPlayerData)
	LocalPlayer:GetAttributeChangedSignal("SectRank"):Connect(MarketController.SyncPlayerData)
	LocalPlayer:GetAttributeChangedSignal("ContributionPoints"):Connect(MarketController.SyncPlayerData)

	print("[ASCEND] MarketController Initialized (Bound to SectMerchantMarketGui hierarchy).")
end

return MarketController