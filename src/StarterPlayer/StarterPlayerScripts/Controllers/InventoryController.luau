--!strict
--[[
    InventoryController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
    Directly bound to StarterGui.SpiritPouchInventoryGui:
    - Dual-device adaptive grid: 6 slots/row on PC ({0, 100}, {0, 100}), 4 slots/row on Phone ({0, 56}, {0, 56})
    - SelectedGlow alignment guarantee (fits slot frame precisely on all resolutions)
    - Universal 3D Viewport Engine: 3D models for Swords (Weapons) & Herbs (Herbs)
    - Dynamic 3D spinning inspection preview for all 3D items
    - 2D Sprite fallback for pills and flat icons
    - Real-time DataStore item population, search, category filtering, and rarity sorting
    - Integrated Panel Click Audio (rbxassetid://138567614125924)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local InventoryController = {}
InventoryController.__index = InventoryController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons") :: Folder?
local herbsFolder = ReplicatedStorage:FindFirstChild("Herbs") :: Folder?
local itemsFolder = ReplicatedStorage:FindFirstChild("Items") or ReplicatedStorage:FindFirstChild("Models") :: Folder?

local inventoryActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent

-- Panel Click Audio
local PANEL_CLICK_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.PanelClick) or "rbxassetid://138567614125924"

local function PlayPanelClickSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = PANEL_CLICK_SOUND_ID
	sound.Volume = 0.55
	sound.PlaybackSpeed = math.random(98, 102) / 100
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

-- UI Element References
local screenGui: ScreenGui
local overlayBackdrop: Frame
local mainFrame: GuiObject
local headerFrame: Frame
local closeButton: GuiButton
local tabContainer: GuiObject
local tabFrame: Frame
local gridSection: GuiObject
local itemGridScroll: ScrollingFrame
local gridLayout: UIGridLayout
local slotTemplate: GuiObject
local searchBox: TextBox
local sortImageButton: GuiButton
local sortTextLabel: TextLabel?
local inspectionSection: GuiObject
local itemNameLabel: TextLabel
local itemRarityLabel: TextLabel
local itemPreviewFrame: Frame
local itemIconLarge: ImageLabel
local inspectionViewport: ViewportFrame?
local activeInspectionSpinCleanup: (() -> ())?
local statBox: Frame
local statLabel: TextLabel
local descriptionLabel: TextLabel
local useImageButton: GuiButton
local useTextLabel: TextLabel?
local dropImageButton: GuiButton
local dropTextLabel: TextLabel?

-- State Cache
local inventoryCache: { [number]: { ItemId: string, Count: number, Quality: string? } } = {}
local activeSlotClones: { GuiObject } = {}
local selectedSlotIndex: number? = nil
local currentCategory: string = "ALL"
local searchQuery: string = ""
local currentSortMode: "Rarity" | "Name" | "Count" = "Rarity"
local isOpen: boolean = false

local CATEGORY_MAP: { [string]: { string } } = {
	["ALL"]         = {},
	["CONSUMABLES"] = { "Consumable", "Pill", "Dan" },
	["SUPPLIES"]    = { "Consumable", "Pill", "Dan" },
	["CURRENCIES"]  = { "Currency", "SpiritStones" },
	["MONEY"]       = { "Currency", "SpiritStones" },
	["INGREDIENTS"] = { "Material", "Herb", "Ingredient" },
	["MATS"]        = { "Material", "Herb", "Ingredient" },
	["EQUIPMENT"]   = { "Weapon", "FlyingSword", "Sword", "Equipment", "Artifact", "Armor", "Crest" },
	["GEAR"]        = { "Weapon", "FlyingSword", "Sword", "Equipment", "Artifact", "Armor", "Crest" },
}

-- Rarity Palette
type RarityColorToken = { Color: Color3, TextColor: Color3 }

local RARITY_COLORS: { [string]: RarityColorToken } = {
	["Mortal"]    = { Color = Color3.fromHex("#64748B"), TextColor = Color3.fromHex("#FFFFFF") },
	["Common"]    = { Color = Color3.fromHex("#64748B"), TextColor = Color3.fromHex("#FFFFFF") },
	["Spiritual"] = { Color = Color3.fromHex("#10B981"), TextColor = Color3.fromHex("#FFFFFF") },
	["Uncommon"]  = { Color = Color3.fromHex("#10B981"), TextColor = Color3.fromHex("#FFFFFF") },
	["Earth"]     = { Color = Color3.fromHex("#3B82F6"), TextColor = Color3.fromHex("#FFFFFF") },
	["Rare"]      = { Color = Color3.fromHex("#3B82F6"), TextColor = Color3.fromHex("#FFFFFF") },
	["Heaven"]    = { Color = Color3.fromHex("#A855F7"), TextColor = Color3.fromHex("#FFFFFF") },
	["Epic"]      = { Color = Color3.fromHex("#A855F7"), TextColor = Color3.fromHex("#FFFFFF") },
	["Legendary"] = { Color = Color3.fromHex("#F59E0B"), TextColor = Color3.fromHex("#FFFFFF") },
	["Mythic"]    = { Color = Color3.fromHex("#E11D48"), TextColor = Color3.fromHex("#FFFFFF") },
	["Sovereign"] = { Color = Color3.fromHex("#22D3EE"), TextColor = Color3.fromHex("#FFFFFF") },
	["Celestial"] = { Color = Color3.fromHex("#F8FAFC"), TextColor = Color3.fromHex("#1E232A") },
}

local DEFAULT_RARITY_TOKEN: RarityColorToken = {
	Color = Color3.fromHex("#64748B"),
	TextColor = Color3.fromHex("#FFFFFF"),
}

local function GetRarityToken(rarityName: string): RarityColorToken
	return RARITY_COLORS[rarityName] or DEFAULT_RARITY_TOKEN
end

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function IsPositionInsideGui(guiObject: GuiObject, x: number, y: number): boolean
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return x >= pos.X and x <= (pos.X + size.X) and y >= pos.Y and y <= (pos.Y + size.Y)
end

-- =============================================================================
-- UNIVERSAL 3D MODEL RESOLVER
-- =============================================================================
local function Find3DItemModel(itemId: string): Instance?
	if weaponsFolder then
		local m = weaponsFolder:FindFirstChild(itemId)
		if m then return m end
	end

	if not herbsFolder then
		herbsFolder = ReplicatedStorage:FindFirstChild("Herbs") :: Folder?
	end
	if herbsFolder then
		local m = herbsFolder:FindFirstChild(itemId)
		if m then return m end
		local baseName = itemId:gsub("_%d+Yr", "")
		m = herbsFolder:FindFirstChild(baseName)
		if m then return m end
	end

	if not itemsFolder then
		itemsFolder = ReplicatedStorage:FindFirstChild("Items") or ReplicatedStorage:FindFirstChild("Models") :: Folder?
	end
	if itemsFolder then
		local m = itemsFolder:FindFirstChild(itemId)
		if m then return m end
	end

	local rootModel = ReplicatedStorage:FindFirstChild(itemId)
	if rootModel and (rootModel:IsA("Model") or rootModel:IsA("BasePart")) then
		return rootModel
	end

	return nil
end

-- =============================================================================
-- 3D VIEWPORT RENDERER
-- =============================================================================
local function Setup3DViewport(viewport: ViewportFrame, itemModel: Instance, spin: boolean): (() -> ())?
	viewport:ClearAllChildren()

	local clone = itemModel:Clone()
	if clone:IsA("BasePart") then
		clone.CFrame = CFrame.new(0, 0, 0)
		clone.Anchored = true
	elseif clone:IsA("Model") then
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		if primary then
			clone:PivotTo(CFrame.new(0, 0, 0))
		end
	end
	clone.Parent = viewport

	for _, child in ipairs(clone:GetDescendants()) do
		if child:IsA("Script") or child:IsA("LocalScript") then
			child:Destroy()
		end
	end

	local camera = Instance.new("Camera")
	camera.FieldOfView = 30

	local size = if clone:IsA("BasePart") then clone.Size else (clone:IsA("Model") and clone:GetExtentsSize() or Vector3.new(1, 4, 1))
	local maxDim = math.max(size.X, size.Y, size.Z)
	local dist = math.max(2.4, maxDim * 1.05)

	camera.CFrame = CFrame.lookAt(Vector3.new(0, 0, dist), Vector3.new(0, 0, 0))
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	viewport.Ambient = Color3.fromRGB(210, 215, 230)
	viewport.LightColor = Color3.fromRGB(255, 255, 255)
	viewport.LightDirection = Vector3.new(-1, -1.2, -1).Unit

	if spin then
		local angle = 0
		local conn: RBXScriptConnection?
		conn = RunService.RenderStepped:Connect(function(dt)
			if not viewport.Parent or not clone.Parent then
				if conn then conn:Disconnect() end
				return
			end
			angle = (angle + 35 * dt) % 360
			local rotCFrame = CFrame.Angles(0, math.rad(angle), math.rad(25))
			if clone:IsA("BasePart") then
				clone.CFrame = rotCFrame
			elseif clone:IsA("Model") then
				clone:PivotTo(rotCFrame)
			end
		end)
		return function()
			if conn then conn:Disconnect() end
		end
	else
		local staticCFrame = CFrame.Angles(0, math.rad(135), math.rad(35))
		if clone:IsA("BasePart") then
			clone.CFrame = staticCFrame
		elseif clone:IsA("Model") then
			clone:PivotTo(staticCFrame)
		end
		return nil
	end
end

function InventoryController.Init()
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	screenGui = playerGui:WaitForChild("SpiritPouchInventoryGui", 10) :: ScreenGui
	if not screenGui then
		warn("[InventoryController] SpiritPouchInventoryGui not found in PlayerGui!")
		return
	end

	screenGui.DisplayOrder = 10
	screenGui.Enabled = false

	overlayBackdrop = screenGui:WaitForChild("OverlayBackdrop", 5) :: Frame
	mainFrame = screenGui:WaitForChild("MainFrame", 5) :: GuiObject
	mainFrame.Active = true

	-- 1. Header Frame
	headerFrame = mainFrame:WaitForChild("HeaderFrame", 5) :: Frame
	closeButton = (headerFrame:FindFirstChild("CloseButton") or headerFrame:FindFirstChild("TextButton") or headerFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton

	-- 2. TabContainer & TabFrame
	tabContainer = mainFrame:WaitForChild("TabContainer", 5) :: GuiObject
	tabFrame = (tabContainer:FindFirstChild("TabFrame") or tabContainer) :: Frame

	-- 3. GridSection & TopBar
	gridSection = mainFrame:WaitForChild("GridSection", 5) :: GuiObject
	gridSection.Active = true

	local topBar = gridSection:WaitForChild("TopBar", 5) :: Frame
	local searchContainer = topBar:FindFirstChild("SearchBarContainer") or topBar
	searchBox = (searchContainer:FindFirstChild("SearchBox") or topBar:FindFirstChild("SearchBox", true)) :: TextBox
	if searchBox then
		searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
		searchBox.PlaceholderColor3 = Color3.fromRGB(160, 175, 195)
	end

	sortImageButton = (topBar:FindFirstChild("SortImageButton") or topBar:FindFirstChild("SortButton") or topBar:FindFirstChildWhichIsA("GuiButton")) :: GuiButton
	sortTextLabel = sortImageButton:FindFirstChild("SortTextLabel") or sortImageButton:FindFirstChildOfClass("TextLabel")

	itemGridScroll = gridSection:WaitForChild("ItemGridScroll", 5) :: ScrollingFrame
	itemGridScroll.Active = true
	itemGridScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	itemGridScroll.ScrollBarThickness = 6

	itemGridScroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		InventoryController.UpdateGridCellSize()
	end)

	gridLayout = itemGridScroll:WaitForChild("UIGridLayout", 5) :: UIGridLayout
	InventoryController.UpdateGridCellSize()

	local foundTemplate = (itemGridScroll:FindFirstChild("SlotFrame") or itemGridScroll:FindFirstChild("SlotTemplate")) :: GuiObject?
	if not foundTemplate then
		foundTemplate = itemGridScroll:WaitForChild("SlotFrame", 5) :: GuiObject
	end
	slotTemplate = foundTemplate:Clone()
	slotTemplate.Visible = false
	foundTemplate.Visible = false

	-- 4. InspectionSection
	inspectionSection = mainFrame:WaitForChild("InspectionSection", 5) :: GuiObject
	inspectionSection.Active = true
	itemNameLabel = inspectionSection:WaitForChild("ItemNameLabel", 5) :: TextLabel
	itemRarityLabel = inspectionSection:WaitForChild("ItemRarityLabel", 5) :: TextLabel
	descriptionLabel = inspectionSection:WaitForChild("DescriptionLabel", 5) :: TextLabel

	itemPreviewFrame = inspectionSection:WaitForChild("ItemPreviewFrame", 5) :: Frame
	itemIconLarge = itemPreviewFrame:WaitForChild("ItemIconLarge", 5) :: ImageLabel

	inspectionViewport = itemPreviewFrame:FindFirstChild("InspectionViewport") :: ViewportFrame?
	if not inspectionViewport then
		inspectionViewport = Instance.new("ViewportFrame")
		inspectionViewport.Name = "InspectionViewport"
		inspectionViewport.Size = UDim2.new(1, 0, 1, 0)
		inspectionViewport.Position = UDim2.new(0, 0, 0, 0)
		inspectionViewport.BackgroundTransparency = 1
		inspectionViewport.BorderSizePixel = 0
		inspectionViewport.Visible = false
		inspectionViewport.ZIndex = 4
		inspectionViewport.Parent = itemPreviewFrame
	end

	statBox = inspectionSection:WaitForChild("StatBox", 5) :: Frame
	statLabel = statBox:WaitForChild("StatLabel", 5) :: TextLabel

	local actionContainer = inspectionSection:WaitForChild("ActionButtonsContainer", 5) :: Frame
	useImageButton = (actionContainer:FindFirstChild("UseImageButton") or actionContainer:FindFirstChild("UseButton") or actionContainer:FindFirstChildWhichIsA("GuiButton")) :: GuiButton
	useTextLabel = useImageButton:FindFirstChild("UseTextLabel") or useImageButton:FindFirstChildOfClass("TextLabel")

	dropImageButton = (actionContainer:FindFirstChild("DropImageButton") or actionContainer:FindFirstChild("DropButton") or actionContainer:FindFirstChildWhichIsA("GuiButton")) :: GuiButton
	dropTextLabel = dropImageButton:FindFirstChild("DropTextLabel") or dropImageButton:FindFirstChildOfClass("TextLabel")

	-- 5. Bind Button Events with Panel Click SFX
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			InventoryController.Close()
		end)
	end

	if overlayBackdrop then
		overlayBackdrop.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local clickPos = input.Position
				if not IsPositionInsideGui(mainFrame, clickPos.X, clickPos.Y) then
					PlayPanelClickSFX()
					InventoryController.Close()
				end
			end
		end)
	end

	local tabList = tabFrame:GetChildren()
	for _, child in ipairs(tabList) do
		if child:IsA("GuiButton") then
			local tabName = child.Name:upper()
			local cleanKey = tabName:gsub("TAB_", "")
			child.MouseButton1Click:Connect(function()
				PlayPanelClickSFX()
				currentCategory = cleanKey
				InventoryController.RenderGrid()
			end)
		end
	end

	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			searchQuery = searchBox.Text:lower()
			InventoryController.RenderGrid()
		end)
	end

	if sortImageButton then
		sortImageButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			if currentSortMode == "Rarity" then
				currentSortMode = "Name"
				InventoryController.SetSortButtonText("Sort by Name")
			elseif currentSortMode == "Name" then
				currentSortMode = "Count"
				InventoryController.SetSortButtonText("Sort by Count")
			else
				currentSortMode = "Rarity"
				InventoryController.SetSortButtonText("Sort by Rarity")
			end
			InventoryController.RenderGrid()
		end)
	end

	if useImageButton then
		useImageButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			if not selectedSlotIndex or not inventoryCache[selectedSlotIndex] then return end
			local slotData = inventoryCache[selectedSlotIndex]
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if not itemDef then return end

			inventoryActionRemote:FireServer({ Action = "UseItem", SlotIndex = selectedSlotIndex })
		end)
	end

	if dropImageButton then
		dropImageButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			if not selectedSlotIndex or not inventoryCache[selectedSlotIndex] then return end
			inventoryActionRemote:FireServer({ Action = "DropItem", SlotIndex = selectedSlotIndex })
		end)
	end

	updateInventoryRemote.OnClientEvent:Connect(function(newInventory: { [number]: any })
		inventoryCache = newInventory or {}
		InventoryController.RenderGrid()
	end)

	task.defer(function()
		task.wait(0.5)
		inventoryActionRemote:FireServer({ Action = "RequestSync" })
	end)

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.I then
			InventoryController.Toggle()
		end
	end)

	print("[ASCEND] InventoryController Initialized (Adaptive 6-Col PC / 4-Col Phone Active).")
end

-- =============================================================================
-- RESPONSIVE GRID ADAPTATION (GRADUAL 6 -> 4 COLUMNS BY AVAILABLE WIDTH)
-- =============================================================================
local GRID_MAX_COLUMNS = 6
local GRID_MIN_COLUMNS = 4
local GRID_MAX_CELL_SIZE = 100
local GRID_MIN_CELL_SIZE = 64
local GRID_CELL_PADDING = 5

function InventoryController.UpdateGridCellSize()
	if not gridLayout or not itemGridScroll then return end

	local containerWidth = itemGridScroll.AbsoluteSize.X
	if containerWidth <= 0 then
		task.defer(InventoryController.UpdateGridCellSize)
		return
	end

	local chosenColumns = GRID_MIN_COLUMNS
	local chosenCellSize = GRID_MIN_CELL_SIZE

	for columns = GRID_MAX_COLUMNS, GRID_MIN_COLUMNS, -1 do
		local totalPadding = GRID_CELL_PADDING * (columns - 1)
		local cellSize = (containerWidth - totalPadding) / columns
		if cellSize >= GRID_MIN_CELL_SIZE then
			chosenColumns = columns
			chosenCellSize = math.min(cellSize, GRID_MAX_CELL_SIZE)
			break
		end
	end

	gridLayout.FillDirectionMaxCells = chosenColumns
	gridLayout.CellPadding = UDim2.new(0, GRID_CELL_PADDING, 0, GRID_CELL_PADDING)
	gridLayout.CellSize = UDim2.new(0, chosenCellSize, 0, chosenCellSize)
end

function InventoryController.SetSortButtonText(text: string)
	if sortTextLabel then
		sortTextLabel.Text = text
	elseif sortImageButton and sortImageButton:IsA("TextButton") then
		(sortImageButton :: TextButton).Text = text
	end
end

function InventoryController.Toggle()
	if isOpen then
		InventoryController.Close()
	else
		InventoryController.Open()
	end
end

function InventoryController.Open()
	isOpen = true
	screenGui.Enabled = true
	mainFrame.Visible = true
	if overlayBackdrop then overlayBackdrop.Visible = true end

	InventoryController.UpdateGridCellSize()
	inventoryActionRemote:FireServer({ Action = "RequestSync" })
	InventoryController.RenderGrid()
end

function InventoryController.Close()
	isOpen = false
	screenGui.Enabled = false
	mainFrame.Visible = false
	if overlayBackdrop then overlayBackdrop.Visible = false end

	if activeInspectionSpinCleanup then
		activeInspectionSpinCleanup()
		activeInspectionSpinCleanup = nil
	end
end

-- =============================================================================
-- POPULATE GRID WITH REAL ITEMS & ALIGNED SELECTED GLOW
-- =============================================================================
function InventoryController.RenderGrid()
	for _, clone in ipairs(activeSlotClones) do
		clone:Destroy()
	end
	table.clear(activeSlotClones)

	InventoryController.UpdateGridCellSize()

	type SlotEntry = { SlotIndex: number, ItemId: string, Count: number, Quality: string?, ItemDef: any }
	local filteredSlots: { SlotEntry } = {}

	for slotIdx = 1, 60 do
		local slotData = inventoryCache[slotIdx]
		if slotData and slotData.ItemId and slotData.ItemId ~= "" then
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef then
				local allowedTypes = CATEGORY_MAP[currentCategory] or {}
				local passesCategory = (#allowedTypes == 0) or table.find(allowedTypes, itemDef.Type) ~= nil
				local passesSearch = (searchQuery == "") or (itemDef.Name:lower():find(searchQuery, 1, true) ~= nil)

				if passesCategory and passesSearch then
					table.insert(filteredSlots, {
						SlotIndex = slotIdx,
						ItemId = slotData.ItemId,
						Count = slotData.Count or 1,
						Quality = slotData.Quality,
						ItemDef = itemDef,
					})
				end
			end
		end
	end

	-- Sorting
	local RARITY_RANKS = {
		["Mortal"]    = 1, ["Common"]    = 1,
		["Spiritual"] = 2, ["Uncommon"]  = 2,
		["Earth"]     = 3, ["Rare"]      = 3,
		["Heaven"]    = 4, ["Epic"]      = 4,
		["Legendary"] = 5,
		["Mythic"]    = 6,
		["Sovereign"] = 7,
		["Celestial"] = 8,
	}

	if currentSortMode == "Rarity" then
		table.sort(filteredSlots, function(a, b)
			local rA = RARITY_RANKS[a.ItemDef.Rarity] or 1
			local rB = RARITY_RANKS[b.ItemDef.Rarity] or 1
			return rA > rB
		end)
	elseif currentSortMode == "Name" then
		table.sort(filteredSlots, function(a, b)
			return a.ItemDef.Name < b.ItemDef.Name
		end)
	elseif currentSortMode == "Count" then
		table.sort(filteredSlots, function(a, b)
			return a.Count > b.Count
		end)
	end

	-- Populate Slots
	for _, entry in ipairs(filteredSlots) do
		local slotObj = slotTemplate:Clone()
		slotObj.Name = "Slot_" .. tostring(entry.SlotIndex)
		slotObj.Visible = true

		local rarityName = entry.ItemDef.Rarity or "Common"
		local token = GetRarityToken(rarityName)

		-- 1. Header Ribbon & Text
		local headerRibbon = slotObj:FindFirstChild("HeaderRibbon") :: ImageLabel?
		local rarityLabel: TextLabel? = nil
		if headerRibbon then
			headerRibbon.Size = UDim2.new(1, 0, 0.22, 0)
			headerRibbon.Position = UDim2.new(0, 0, 0, 0)
			headerRibbon.AnchorPoint = Vector2.new(0, 0)
			headerRibbon.ImageColor3 = token.Color
			rarityLabel = (headerRibbon:FindFirstChild("TextLabel") or headerRibbon:FindFirstChildWhichIsA("TextLabel")) :: TextLabel?
		else
			rarityLabel = (slotObj:FindFirstChild("RarityBadge") or slotObj:FindFirstChild("TextLabel")) :: TextLabel?
		end

		if rarityLabel then
			rarityLabel.Size = UDim2.new(1, 0, 1, 0)
			rarityLabel.Position = UDim2.new(0, 0, 0, 0)
			rarityLabel.TextScaled = true
			rarityLabel.Text = rarityName:upper()
			rarityLabel.TextColor3 = token.TextColor
			rarityLabel.Visible = true
		end

		-- 2. Aligned Selected Glow
		local GLOW_OVERSCAN = 0.08
		local selectedGlow = slotObj:FindFirstChild("SelectedGlow") :: ImageLabel?
		if selectedGlow then
			selectedGlow.Size = UDim2.new(1 + GLOW_OVERSCAN, 0, 1 + GLOW_OVERSCAN, 0)
			selectedGlow.Position = UDim2.new(0.5, 0, 0.5, 0)
			selectedGlow.AnchorPoint = Vector2.new(0.5, 0.5)
			selectedGlow.ZIndex = 5
			selectedGlow.Visible = (selectedSlotIndex == entry.SlotIndex)
		end

		if slotObj:IsA("GuiObject") then
			(slotObj :: GuiObject).ClipsDescendants = false
		end

		-- 3. Universal 3D/2D Item Rendering
		local itemIcon = slotObj:FindFirstChild("ItemIcon") :: ImageLabel?
		local item3DModel = Find3DItemModel(entry.ItemId)

		if item3DModel then
			if itemIcon then itemIcon.Visible = false end

			local slotViewport = slotObj:FindFirstChild("Slot3DViewport") :: ViewportFrame?
			if not slotViewport then
				slotViewport = Instance.new("ViewportFrame")
				slotViewport.Name = "Slot3DViewport"
				slotViewport.Size = UDim2.new(0.85, 0, 0.72, 0)
				slotViewport.Position = UDim2.new(0.5, 0, 0.60, 0)
				slotViewport.AnchorPoint = Vector2.new(0.5, 0.5)
				slotViewport.BackgroundTransparency = 1
				slotViewport.BorderSizePixel = 0
				slotViewport.ZIndex = 3
				slotViewport.Parent = slotObj
			end
			slotViewport.Visible = true
			Setup3DViewport(slotViewport, item3DModel, false)
		else
			local slotViewport = slotObj:FindFirstChild("Slot3DViewport") :: ViewportFrame?
			if slotViewport then slotViewport.Visible = false end

			local iconAsset = (UIAssets.Icons and UIAssets.Icons[entry.ItemId]) or entry.ItemDef.Icon
			if itemIcon then
				itemIcon.BackgroundColor3 = token.Color
				if iconAsset and iconAsset ~= "" then
					itemIcon.Image = iconAsset
					itemIcon.Visible = true
				else
					itemIcon.Visible = false
				end
			end
		end

		-- 4. Quantity Label
		local quantityLabel = slotObj:FindFirstChild("QuantityLabel") :: TextLabel?
		if quantityLabel then
			quantityLabel.Text = if entry.Count > 1 then "x" .. tostring(entry.Count) else ""
			quantityLabel.Visible = (entry.Count > 1)
		end

		local function selectSlot()
			PlayPanelClickSFX()
			selectedSlotIndex = entry.SlotIndex
			InventoryController.UpdateInspection(entry.ItemDef, entry.Count, entry.Quality)
			InventoryController.RenderGrid()
		end

		if slotObj:IsA("GuiButton") then
			slotObj.MouseButton1Click:Connect(selectSlot)
		else
			slotObj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					selectSlot()
				end
			end)
		end

		slotObj.Parent = itemGridScroll
		table.insert(activeSlotClones, slotObj)
	end

	-- Auto-select first item or maintain selection
	if not selectedSlotIndex and #filteredSlots > 0 then
		selectedSlotIndex = filteredSlots[1].SlotIndex
		InventoryController.UpdateInspection(filteredSlots[1].ItemDef, filteredSlots[1].Count, filteredSlots[1].Quality)
	elseif #filteredSlots == 0 then
		InventoryController.ClearInspection()
	end
end

-- =============================================================================
-- UPDATE INSPECTION CARD (3D ROTATING MESH & STATS)
-- =============================================================================
function InventoryController.UpdateInspection(itemDef: any, count: number, quality: string?)
	if not itemDef then
		InventoryController.ClearInspection()
		return
	end

	if activeInspectionSpinCleanup then
		activeInspectionSpinCleanup()
		activeInspectionSpinCleanup = nil
	end

	local rarityName = itemDef.Rarity or "Common"
	local token = GetRarityToken(rarityName)

	itemNameLabel.Text = itemDef.Name
	itemRarityLabel.Text = string.format("%s %s", rarityName:upper(), (itemDef.Type or "ITEM"):upper())
	itemRarityLabel.TextColor3 = token.Color
	descriptionLabel.Text = itemDef.Description or "No lore inscription found."

	local item3DModel = Find3DItemModel(itemDef.Id or itemDef.Name)

	if item3DModel and inspectionViewport then
		itemIconLarge.Visible = false
		inspectionViewport.Visible = true
		activeInspectionSpinCleanup = Setup3DViewport(inspectionViewport, item3DModel, true)
	else
		if inspectionViewport then
			inspectionViewport.Visible = false
			inspectionViewport:ClearAllChildren()
		end

		local iconAsset = (UIAssets.Icons and UIAssets.Icons[itemDef.Id]) or itemDef.Icon
		if itemIconLarge then
			itemIconLarge.BackgroundColor3 = token.Color
			if iconAsset and iconAsset ~= "" then
				itemIconLarge.Image = iconAsset
				itemIconLarge.Visible = true
			else
				itemIconLarge.Visible = false
			end
		end
	end

	local statSummary = ""
	if itemDef.Stats then
		if itemDef.Stats.Damage then
			statSummary = string.format("BASE DAMAGE: +%d", itemDef.Stats.Damage)
		elseif itemDef.Stats.HealAmount then
			statSummary = string.format("HEALTH RESTORED: +%d", itemDef.Stats.HealAmount)
		elseif itemDef.Stats.QiGrant then
			statSummary = string.format("SPIRIT QI RESTORED: +%d", itemDef.Stats.QiGrant)
		end
	end

	if quality then
		statSummary = statSummary .. string.format(" [%s Quality]", quality)
	end

	statLabel.Text = if statSummary ~= "" then statSummary else "STANDARD GRADE"

	if useImageButton then
		useImageButton.Visible = true
		local actionText = (itemDef.Type == "Weapon" or itemDef.Type == "FlyingSword" or itemDef.Type == "Crest") and "EQUIP" or "USE"
		if useTextLabel then
			useTextLabel.Text = actionText
		elseif useImageButton:IsA("TextButton") then
			(useImageButton :: TextButton).Text = actionText
		end
	end

	if dropImageButton then
		dropImageButton.Visible = true
	end
end

function InventoryController.ClearInspection()
	selectedSlotIndex = nil
	itemNameLabel.Text = "Select an Item"
	itemRarityLabel.Text = "EMPTY"
	itemRarityLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	descriptionLabel.Text = "Select an item from your spirit pouch to inspect its spiritual properties."
	if itemIconLarge then itemIconLarge.Visible = false end
	if inspectionViewport then
		inspectionViewport.Visible = false
		inspectionViewport:ClearAllChildren()
	end
	if activeInspectionSpinCleanup then
		activeInspectionSpinCleanup()
		activeInspectionSpinCleanup = nil
	end
	statLabel.Text = "-"
	if useImageButton then useImageButton.Visible = false end
	if dropImageButton then dropImageButton.Visible = false end
end

return InventoryController