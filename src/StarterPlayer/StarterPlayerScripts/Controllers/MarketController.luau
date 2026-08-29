--!strict
--[[
    MarketController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
    Bound directly to Studio StarterGui.SectMerchantMarketGui hierarchy:
    - SWORDS Category Tab replaces Talismans (Displays Tier 2-8 Flying Swords)
    - Enforces Sect Rank Requirements per Sword (Outer, Inner, Core, Elder, Patriarch)
    - Live synced Spirit Stones, Sect Rank, CP, and Dynamic Item Inspect Panel
    - Integrated Top-Center Bangers Toast Notifications
    - Fixed 3-Column Responsive Grid (Always 3/row, auto-growing scroll canvas)
    - Dynamic SelectedGlow activation on selected SlotFrame
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- GUI Root & Frames
local marketGui: ScreenGui?
local mainFrame: ImageLabel?
local headerFrame: Frame?
local upperFrame: Frame?
local secondaryFrame: Frame?
local tertiaryFrame: Frame?

-- Header & Close
local closeBtn: ImageButton?
local titleLabel: TextLabel?

-- UpperFrame Stats
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
local filterSwords: ImageButton?

-- TertiaryFrame -> InnerFrame1 (Item Catalog Grid)
local itemGridScroll: ScrollingFrame?
local templateSlotFrame: ImageLabel?
local gridLayout: UIGridLayout?
local gridResizeConnected: boolean = false

-- TertiaryFrame -> InnerFrame2 (Inspect & Checkout Panel)
local inspectTopTitle: TextLabel?
local inspectItemImage: ImageLabel?
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
local currentCategory: "ALL" | "CORES" | "ELIXIRS" | "HERBS" | "SWORDS" = "ALL"
local selectedItemId: string? = nil
local selectedQuantity: number = 1
local currentInventory: { [number]: { ItemId: string, Count: number, Quality: any? } } = {}
local activeSlotClones: { Instance } = {}

-- =============================================================================
-- FIXED 3-COLUMN RESPONSIVE GRID
-- =============================================================================
local MARKET_GRID_COLUMNS = 3
local MARKET_GRID_PADDING = 5
local MARKET_MIN_CELL_SIZE = 60
local MARKET_MAX_CELL_SIZE = 200

local function UpdateMarketGridCellSize()
	if not gridLayout or not itemGridScroll then return end

	local containerWidth = itemGridScroll.AbsoluteSize.X
	if containerWidth <= 0 then
		task.defer(UpdateMarketGridCellSize)
		return
	end

	local totalPadding = MARKET_GRID_PADDING * (MARKET_GRID_COLUMNS - 1)
	local cellSize = math.clamp((containerWidth - totalPadding) / MARKET_GRID_COLUMNS, MARKET_MIN_CELL_SIZE, MARKET_MAX_CELL_SIZE)

	gridLayout.FillDirectionMaxCells = MARKET_GRID_COLUMNS
	gridLayout.CellPadding = UDim2.new(0, MARKET_GRID_PADDING, 0, MARKET_GRID_PADDING)
	gridLayout.CellSize = UDim2.new(0, cellSize, 0, cellSize)
end

-- =============================================================================
-- BUTTON GRADIENT STYLING
-- =============================================================================
local function ApplyGradient(button: GuiButton?, colorA: Color3, colorB: Color3, rotation: number?)
	if not button then return end

	local gradient = button:FindFirstChildOfClass("UIGradient")
	if not gradient then
		gradient = Instance.new("UIGradient")
		gradient.Parent = button
	end

	gradient.Color = ColorSequence.new(colorA, colorB)
	gradient.Rotation = rotation or 90
end

local GRADIENT_GOLD_TOP = Color3.fromHex("#F5D06B")
local GRADIENT_GOLD_BOTTOM = Color3.fromHex("#B8860B")
local GRADIENT_NAVY_TOP = Color3.fromHex("#2A3752")
local GRADIENT_NAVY_BOTTOM = Color3.fromHex("#141B29")
local GRADIENT_SLATE_TOP = Color3.fromHex("#6A7BA3")
local GRADIENT_SLATE_BOTTOM = Color3.fromHex("#3D4866")
local GRADIENT_MAROON_TOP = Color3.fromHex("#A8493F")
local GRADIENT_MAROON_BOTTOM = Color3.fromHex("#5C2420")
local GRADIENT_GREY_TOP = Color3.fromHex("#9AA3B0")
local GRADIENT_GREY_BOTTOM = Color3.fromHex("#5C6470")

local function ApplyMarketButtonGradients()
	ApplyGradient(tabBuyGoods, GRADIENT_NAVY_TOP, GRADIENT_NAVY_BOTTOM)
	ApplyGradient(tabSellLoot, GRADIENT_NAVY_TOP, GRADIENT_NAVY_BOTTOM)

	ApplyGradient(filterAll, GRADIENT_SLATE_TOP, GRADIENT_SLATE_BOTTOM)
	ApplyGradient(filterCores, GRADIENT_SLATE_TOP, GRADIENT_SLATE_BOTTOM)
	ApplyGradient(filterElixirs, GRADIENT_SLATE_TOP, GRADIENT_SLATE_BOTTOM)
	ApplyGradient(filterHerbs, GRADIENT_SLATE_TOP, GRADIENT_SLATE_BOTTOM)
	ApplyGradient(filterSwords, GRADIENT_SLATE_TOP, GRADIENT_SLATE_BOTTOM)

	ApplyGradient(confirmExchangeBtn, GRADIENT_MAROON_TOP, GRADIENT_MAROON_BOTTOM)

	ApplyGradient(minusBtn, GRADIENT_GOLD_TOP, GRADIENT_GOLD_BOTTOM)
	ApplyGradient(plusBtn, GRADIENT_GOLD_TOP, GRADIENT_GOLD_BOTTOM)
	ApplyGradient(maxBtn, GRADIENT_GREY_TOP, GRADIENT_GREY_BOTTOM)
end

-- Toast Helper
local function ShowToast(message: string, toastType: string?)
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local hudCtrl = controllers:FindFirstChild("HUDController")
		if hudCtrl then
			local req = require(hudCtrl) :: any
			if req.ShowGlobalToast then
				req.ShowGlobalToast(message, toastType or "Success", 3.0)
				return
			end
		end
	end
end

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

local function GetPlayerStones(): number
	local stones = LocalPlayer:GetAttribute("SpiritStones")
	if stones == nil and LocalPlayer.Character then
		stones = LocalPlayer.Character:GetAttribute("SpiritStones")
	end
	return tonumber(stones) or 0
end

local function GetPlayerRank(): string
	local r = LocalPlayer:GetAttribute("SectRank") or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("SectRank")) or "OuterDisciple"
	return tostring(r)
end

local function GetOwnedCount(itemId: string): number
	local total = 0
	for _, slotData in pairs(currentInventory) do
		if slotData and slotData.ItemId == itemId then
			total += (slotData.Count or 1)
		end
	end
	return total
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

	-- 2. UpperFrame
	upperFrame = mainFrame:FindFirstChild("UpperFrame") :: Frame?
	if upperFrame then
		local leftFrame = upperFrame:FindFirstChild("Left")
		if leftFrame then stonesLabel = leftFrame:FindFirstChild("TextLabel") :: TextLabel? end

		local centerFrame = upperFrame:FindFirstChild("Center")
		if centerFrame then rankLabel = centerFrame:FindFirstChild("TextLabel") :: TextLabel? end

		local rightFrame = upperFrame:FindFirstChild("Right")
		if rightFrame then cpLabel = rightFrame:FindFirstChild("TextLabel") :: TextLabel? end
	end

	-- 3. SecondaryFrame
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
			filterSwords = (tabFrame2:FindFirstChild("Tab_SWORDS") or tabFrame2:FindFirstChild("Tab_TALISMANS")) :: ImageButton?

			if filterSwords then
				local lbl = filterSwords:FindFirstChildOfClass("TextLabel")
				if lbl then lbl.Text = "SWORDS" end
			end
		end
	end

	-- 4. TertiaryFrame
	tertiaryFrame = mainFrame:FindFirstChild("TertiaryFrame") :: Frame?
	if tertiaryFrame then
		local inner1 = tertiaryFrame:FindFirstChild("InnerFrame1")
		if inner1 then
			itemGridScroll = inner1:FindFirstChild("ItemGridScroll") :: ScrollingFrame?
			if itemGridScroll then
				templateSlotFrame = itemGridScroll:FindFirstChild("SlotFrame") :: ImageLabel?
				if templateSlotFrame then
					templateSlotFrame.Visible = false
				end

				itemGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
				itemGridScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
				itemGridScroll.ScrollBarThickness = 6

				gridLayout = itemGridScroll:FindFirstChildOfClass("UIGridLayout")

				if gridLayout and not gridResizeConnected then
					gridResizeConnected = true
					itemGridScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateMarketGridCellSize)
				end

				UpdateMarketGridCellSize()
			end
		end

		local inner2 = tertiaryFrame:FindFirstChild("InnerFrame2")
		if inner2 then
			inspectTopTitle = inner2:FindFirstChild("PillDescription", true) :: TextLabel?

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

	-- Format and enlarge Minus, Plus, and MAX button labels
	local function StyleQuantityGlyph(btn: ImageButton?, glyph: string)
		if not btn then return end

		local lbl = btn:FindFirstChildOfClass("TextLabel")
		if lbl then
			lbl.Text = glyph
			lbl.Font = Enum.Font.Bangers
			lbl.TextSize = 34
			lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
			lbl.Active = false

			local stroke = lbl:FindFirstChildOfClass("UIStroke") :: UIStroke?
			if not stroke then
				stroke = Instance.new("UIStroke")
				stroke.Parent = lbl
			end
			stroke.Thickness = 2
			stroke.Color = Color3.fromRGB(60, 40, 5)
		end
	end

	StyleQuantityGlyph(minusBtn, "-")
	StyleQuantityGlyph(plusBtn, "+")

	if maxBtn then
		local lbl = maxBtn:FindFirstChildOfClass("TextLabel")
		if lbl then
			lbl.Text = "MAX"
			lbl.Font = Enum.Font.Bangers
			lbl.Active = false
		end
	end

	ApplyMarketButtonGradients()

	return true
end

-- =============================================================================
-- DATA REFRESH & INSPECT LOGIC
-- =============================================================================
local function GetItemCategory(itemDef: ItemConfig.ItemDefinition): string
	if itemDef.Type == "Weapon" then
		return "SWORDS"
	elseif itemDef.Id == "DemonBeastCore" or itemDef.Type == "Crest" then
		return "CORES"
	elseif itemDef.Type == "Consumable" or itemDef.Id:match("Dan$") or itemDef.Id:match("Pill$") then
		return "ELIXIRS"
	elseif itemDef.Type == "Material" then
		return "HERBS"
	end
	return "HERBS"
end

local function GetMaxAllowedQuantity(unitPrice: number): number
	if currentMode == "Buy" then
		if selectedItemId and ItemConfig.GetItem(selectedItemId) and ItemConfig.GetItem(selectedItemId).Type == "Weapon" then
			return 1
		end
		local stones = GetPlayerStones()
		if unitPrice <= 0 then return 99 end
		local affordable = math.floor(stones / unitPrice)
		return math.clamp(affordable, 1, 99)
	else
		if not selectedItemId then return 1 end
		local owned = GetOwnedCount(selectedItemId)
		return math.max(1, owned)
	end
end

local function UpdateInspectPanel()
	if not selectedItemId then
		if inspectTopTitle then inspectTopTitle.Text = "SELECT AN ITEM" end
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

	-- 1. Dynamic Titles & Specs
	if inspectTopTitle then
		inspectTopTitle.Text = itemDef.Name
	end
	if inspectItemImage then
		inspectItemImage.Image = itemDef.Icon or ""
	end
	if inspectGrade then
		inspectGrade.Text = string.format("Grade: %s-Rank", itemDef.Rarity)
	end
	if inspectSpiritAge then
		if itemDef.Type == "Weapon" then
			local reqRank = vendorDef and vendorDef.RequiredRank or "OuterDisciple"
			inspectSpiritAge.Text = string.format("Req: %s", FormatRank(reqRank))
		else
			inspectSpiritAge.Text = if itemDef.AgeYears then string.format("Spirit Age: %d-Yr", itemDef.AgeYears) else "Spirit Age: Immortal"
		end
	end
	if inspectEffectsDesc then
		if itemDef.Type == "Weapon" then
			inspectEffectsDesc.Text = string.format("+%d Physical Attack\n%s", itemDef.Damage or 20, itemDef.Description)
		elseif itemDef.Stats and itemDef.Stats.QiGrant then
			inspectEffectsDesc.Text = string.format("+%s Usable Qi\n%s", FormatNum(itemDef.Stats.QiGrant), itemDef.Description)
		elseif itemDef.Stats and itemDef.Stats.HealAmount then
			inspectEffectsDesc.Text = string.format("+%s Health Recovery\n%s", FormatNum(itemDef.Stats.HealAmount), itemDef.Description)
		else
			inspectEffectsDesc.Text = itemDef.Description
		end
	end

	-- 2. Quantity & Total Stones Counter
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

	UpdateMarketGridCellSize()

	-- Snap scrollbar to the top
	itemGridScroll.CanvasPosition = Vector2.new(0, 0)

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
							StockOrOwned = string.format("Rank: %s", vendorItem.RequiredRank:gsub("Disciple", ""):gsub("Sect", "")),
							Count = 99,
						})
					end
				end
			end
		end
	else
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

	-- Create Grid Slots
	for _, itemInfo in ipairs(candidateItems) do
		local itemDef = ItemConfig.GetItem(itemInfo.ItemId)
		if not itemDef then continue end

		local slot = templateSlotFrame:Clone()
		slot.Name = "Slot_" .. itemInfo.ItemId
		slot.Visible = true
		slot.Parent = itemGridScroll
		table.insert(activeSlotClones, slot)

		-- SelectedGlow initial state
		local selectedGlow = slot:FindFirstChild("SelectedGlow") :: ImageLabel?
		if selectedGlow then
			selectedGlow.Visible = (itemInfo.ItemId == selectedItemId)
		end

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

		local function selectThis()
			PlayClickSound()
			selectedItemId = itemInfo.ItemId
			selectedQuantity = 1

			-- Dynamically toggle SelectedGlow on all active slot clones
			for _, s in ipairs(activeSlotClones) do
				local glow = s:FindFirstChild("SelectedGlow") :: ImageLabel?
				if glow then
					glow.Visible = (s.Name == "Slot_" .. itemInfo.ItemId)
				end
			end

			UpdateInspectPanel()
		end

		local clickTrigger = slot:FindFirstChildWhichIsA("GuiButton") or slot
		if clickTrigger:IsA("GuiButton") then
			clickTrigger.MouseButton1Click:Connect(selectThis)
		else
			slot.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					selectThis()
				end
			end)
		end
	end

	-- Auto-select first item or preserve valid selection
	if #candidateItems > 0 then
		local found = false
		for _, info in ipairs(candidateItems) do
			if info.ItemId == selectedItemId then
				found = true
				break
			end
		end
		if not found then
			selectedItemId = candidateItems[1].ItemId
			selectedQuantity = 1
		end
	else
		selectedItemId = nil
		selectedQuantity = 0
	end

	-- Update SelectedGlow visibility across all slots
	for _, s in ipairs(activeSlotClones) do
		local glow = s:FindFirstChild("SelectedGlow") :: ImageLabel?
		if glow then
			glow.Visible = (s.Name == "Slot_" .. (selectedItemId or ""))
		end
	end

	UpdateInspectPanel()
end

-- =============================================================================
-- EVENT LISTENERS & LIFECYCLE
-- =============================================================================
function MarketController.SyncPlayerData()
	local stones = GetPlayerStones()
	local rank = GetPlayerRank()
	local cp = LocalPlayer:GetAttribute("ContributionPoints") or (LocalPlayer.Character and LocalPlayer.Character:GetAttribute("ContributionPoints")) or 0

	if stonesLabel then stonesLabel.Text = FormatNum(stones) end
	if rankLabel then rankLabel.Text = FormatRank(rank) end
	if cpLabel then cpLabel.Text = string.format("%s CP", FormatNum(tonumber(cp) or 0)) end
end

function MarketController.Open()
	if not marketGui and not BindHierarchy() then return end
	if not marketGui or not mainFrame then return end

	MarketController.SyncPlayerData()
	marketActionRemote:FireServer({ Action = "RequestMarketData" })

	selectedQuantity = 1
	UpdateMarketGridCellSize()
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
	BindFilter(filterSwords, "SWORDS")

	-- 4. Quantity Adjusters (- / + / MAX)
	local function AdjustMinus()
		PlayClickSound()
		selectedQuantity = math.max(1, selectedQuantity - 1)
		UpdateInspectPanel()
	end

	local function AdjustPlus()
		PlayClickSound()
		local isWeapon = selectedItemId and ItemConfig.GetItem(selectedItemId) and ItemConfig.GetItem(selectedItemId).Type == "Weapon"
		if isWeapon then
			selectedQuantity = 1
			ShowToast("SWORDS ARE UNIQUE ARTIFACTS (MAX 1)", "Warning")
			return
		end
		local limit = if currentMode == "Buy" then 99 else GetOwnedCount(selectedItemId or "")
		selectedQuantity = math.min(math.max(1, limit), selectedQuantity + 1)
		UpdateInspectPanel()
	end

	local function AdjustMax()
		PlayClickSound()
		if selectedItemId then
			local vendorDef = SectConfig.GetMarketItem(selectedItemId)
			local unitPrice = if currentMode == "Buy" then (vendorDef and vendorDef.BuyPrice or 50) else (vendorDef and vendorDef.SellPrice or 20)
			selectedQuantity = GetMaxAllowedQuantity(unitPrice)
		end
		UpdateInspectPanel()
	end

	if minusBtn then
		minusBtn.MouseButton1Click:Connect(AdjustMinus)
		minusBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then AdjustMinus() end
		end)
	end

	if plusBtn then
		plusBtn.MouseButton1Click:Connect(AdjustPlus)
		plusBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then AdjustPlus() end
		end)
	end

	if maxBtn then
		maxBtn.MouseButton1Click:Connect(AdjustMax)
		maxBtn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch then AdjustMax() end
		end)
	end

	-- 5. Confirm Exchange Action
	if confirmExchangeBtn then
		local function ExecuteExchange()
			PlayClickSound()
			if not selectedItemId or selectedQuantity <= 0 then
				ShowToast("PLEASE SELECT AN ITEM", "Warning")
				return
			end

			local vendorDef = SectConfig.GetMarketItem(selectedItemId)
			if currentMode == "Buy" then
				if not vendorDef or not vendorDef.BuyPrice then
					ShowToast("ITEM NOT FOR SALE!", "Warning")
					return
				end

				local playerRank = GetPlayerRank()
				if not SectConfig.CanPurchase(playerRank :: any, vendorDef.RequiredRank) then
					ShowToast(string.format("REQUIRES %s RANK!", FormatRank(vendorDef.RequiredRank)), "Warning")
					return
				end

				local totalCost = vendorDef.BuyPrice * selectedQuantity
				if GetPlayerStones() < totalCost then
					ShowToast("INSUFFICIENT SPIRIT STONES!", "Warning")
					return
				end

				marketActionRemote:FireServer({
					Action = "BuyItem",
					ItemId = selectedItemId,
					Amount = selectedQuantity,
				})
			else
				local owned = GetOwnedCount(selectedItemId)
				if owned < selectedQuantity then
					ShowToast("NOT ENOUGH ITEMS TO SELL!", "Warning")
					return
				end

				marketActionRemote:FireServer({
					Action = "SellItem",
					ItemId = selectedItemId,
					Amount = selectedQuantity,
				})
			end
		end

		confirmExchangeBtn.MouseButton1Click:Connect(ExecuteExchange)
	end

	-- 6. Server Payloads & Toast Feedback
	marketActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "OpenShop" then
			MarketController.Open()
		elseif payload.Action == "SyncBalance" then
			MarketController.SyncPlayerData()
		elseif payload.Action == "TransactionSuccess" then
			local itemDef = ItemConfig.GetItem(payload.ItemId or selectedItemId or "")
			local itemName = if itemDef then itemDef.Name else (payload.ItemId or "ITEM")
			local amount = payload.Amount or selectedQuantity

			if payload.Type == "Buy" then
				ShowToast(string.format("PURCHASED +%d %s!", amount, itemName:upper()), "Success")
			else
				local payout = payload.TotalPayout or 0
				ShowToast(string.format("SOLD %d %s (+%s STONES)!", amount, itemName:upper(), FormatNum(payout)), "Reward")
			end

			MarketController.SyncPlayerData()
			selectedQuantity = 1
			PopulateGrid()
		elseif payload.Action == "TransactionFailed" then
			ShowToast(payload.Message or "TRANSACTION FAILED!", "Warning")
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

	UpdateMarketGridCellSize()

	print("[ASCEND] MarketController Initialized (Swords Category & Sect Rank Gate Active, Fixed 3-Col Grid).")
end

return MarketController