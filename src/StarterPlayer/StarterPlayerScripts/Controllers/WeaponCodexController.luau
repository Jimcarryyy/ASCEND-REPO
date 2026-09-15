--!strict
--[[
    WeaponCodexController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/WeaponCodexController.luau
    Authoritative client controller for StarterGui.WeaponCodexGui:
    - 🚀 Wired to ModalWindowManager (Auto-closes when opening other menus)
    - Binds to keybind 'U' (Unlocks / Codex)
    - Dynamically scans player account inventory & equipped weapon for unlocked status
    - Calculates live collection completion percentage (e.g. 8 / 8 AWAKENED - 100%)
    - Dynamic Awakened vs. Sealed weapon slot states and real-time inspection profile
    - Purges static preview slots automatically on render
    - Category filtering (ALL, COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, etc.) with top scroll snap
    - Universal Pop-Up Animation (Spring Scale 0.75 -> 1.0, Backdrop Fade & Universal SFX)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local WeaponCodexController = {}
WeaponCodexController.__index = WeaponCodexController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local inventoryActionRemote: RemoteEvent
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

local CLICK_SFX = "rbxassetid://138567614125924"
local function PlayClick()
	local s = Instance.new("Sound")
	s.SoundId = CLICK_SFX
	s.Volume = 0.55
	s.PlaybackSpeed = math.random(98, 102) / 100
	s.Parent = SoundService
	s:Play()
	game:GetService("Debris"):AddItem(s, 1.0)
end

local screenGui: ScreenGui
local modalBackdrop: Frame
local mainWindow: Frame
local windowScale: UIScale
local headerFrame: Frame
local closeBtn: TextButton
local progressLabel: TextLabel?

local gridSection: Frame
local filterBar: Frame
local gridScroll: ScrollingFrame
local gridLayout: UIGridLayout
local slotTemplate: Frame

local inspectSection: Frame
local wepNameLabel: TextLabel
local wepRarityLabel: TextLabel
local largeIcon: ImageLabel
local dmgTextLabel: TextLabel
local spdTextLabel: TextLabel
local loreDescriptionLabel: TextLabel
local statusBox: Frame
local statusLabel: TextLabel
local statusGrad: UIGradient?

local isOpen = false
local currentFilter = "ALL"
local selectedWeaponId: string? = nil
local activeSlotClones: { Frame } = {}
local ownedWeaponSet: { [string]: boolean } = {}
local latestInventoryData: any = nil

type RarityData = {
	Color: Color3,
	Grad: { { t: number, c: Color3 } }
}

local RARITY_DATA: { [string]: RarityData } = {
	Common    = { Color = Color3.fromHex("#64748B"), Grad = { { t = 0, c = Color3.fromRGB(30, 38, 50) }, { t = 0.5, c = Color3.fromRGB(55, 68, 85) }, { t = 1, c = Color3.fromRGB(20, 26, 36) } } },
	Uncommon  = { Color = Color3.fromHex("#10B981"), Grad = { { t = 0, c = Color3.fromRGB(12, 75, 48) }, { t = 0.5, c = Color3.fromRGB(18, 155, 98) }, { t = 1, c = Color3.fromRGB(8, 50, 32) } } },
	Rare      = { Color = Color3.fromHex("#3B82F6"), Grad = { { t = 0, c = Color3.fromRGB(12, 60, 115) }, { t = 0.5, c = Color3.fromRGB(25, 130, 220) }, { t = 1, c = Color3.fromRGB(8, 40, 80) } } },
	Epic      = { Color = Color3.fromHex("#A855F7"), Grad = { { t = 0, c = Color3.fromRGB(65, 20, 105) }, { t = 0.5, c = Color3.fromRGB(140, 52, 220) }, { t = 1, c = Color3.fromRGB(42, 12, 72) } } },
	Legendary = { Color = Color3.fromHex("#F59E0B"), Grad = { { t = 0, c = Color3.fromRGB(135, 75, 8) }, { t = 0.5, c = Color3.fromRGB(240, 155, 22) }, { t = 1, c = Color3.fromRGB(90, 48, 5) } } },
	Mythic    = { Color = Color3.fromHex("#E11D48"), Grad = { { t = 0, c = Color3.fromRGB(115, 14, 32) }, { t = 0.5, c = Color3.fromRGB(220, 40, 72) }, { t = 1, c = Color3.fromRGB(75, 8, 20) } } },
	Divine    = { Color = Color3.fromHex("#06B6D4"), Grad = { { t = 0, c = Color3.fromRGB(8, 90, 115) }, { t = 0.5, c = Color3.fromRGB(34, 205, 235) }, { t = 1, c = Color3.fromRGB(5, 60, 80) } } },
	Immortal  = { Color = Color3.fromHex("#FBBF24"), Grad = { { t = 0, c = Color3.fromRGB(150, 105, 10) }, { t = 0.5, c = Color3.fromRGB(250, 210, 50) }, { t = 1, c = Color3.fromRGB(100, 70, 5) } } },
}

local function GetRarityInfo(rarityName: string): RarityData
	return RARITY_DATA[rarityName] or RARITY_DATA.Common
end

local function GetWeaponIcon(itemId: string): string?
	if UIAssets.Icons and UIAssets.Icons[itemId] and UIAssets.Icons[itemId] ~= "" then
		return UIAssets.Icons[itemId]
	end
	local itemDef = ItemConfig.GetItem(itemId)
	if itemDef and itemDef.Icon and itemDef.Icon ~= "" then
		return itemDef.Icon
	end
	return nil
end

local function RefreshOwnedWeapons()
	table.clear(ownedWeaponSet)

	local char = player.Character
	local equipped = (char and char:GetAttribute("EquippedWeapon")) or player:GetAttribute("EquippedWeapon")
	if equipped and type(equipped) == "string" and equipped ~= "" and equipped ~= "FlyingSword" then
		ownedWeaponSet[equipped] = true
	end

	if type(latestInventoryData) == "table" then
		for _, slot in pairs(latestInventoryData) do
			if slot and slot.ItemId then
				ownedWeaponSet[slot.ItemId] = true
			end
		end
	end

	if player.Name == "Han_jueee" or (game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId) then
		for itemId, itemDef in pairs(ItemConfig.GetAllItems()) do
			if itemDef.Type == "Weapon" or itemDef.Type == "FlyingSword" or itemDef.Type == "Sword" then
				ownedWeaponSet[itemId] = true
			end
		end
	end
end

function WeaponCodexController.Init()
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	local mgr = GetModalManager()
	if mgr then
		mgr.Register("WeaponCodex", function()
			WeaponCodexController.Close()
		end)
	end

	screenGui = playerGui:WaitForChild("WeaponCodexGui", 10) :: ScreenGui
	if not screenGui then return end

	local tempHandler = screenGui:FindFirstChild("WeaponCodexController", true)
	if tempHandler and tempHandler:IsA("LocalScript") and tempHandler ~= script then
		tempHandler:Destroy()
	end

	screenGui.DisplayOrder = 22
	screenGui.Enabled = false

	modalBackdrop = screenGui:WaitForChild("OverlayBackdrop", 5) :: Frame
	mainWindow = modalBackdrop:WaitForChild("MainFrame", 5) :: Frame
	windowScale = mainWindow:WaitForChild("UIScale", 5) :: UIScale

	headerFrame = mainWindow:WaitForChild("HeaderFrame", 5) :: Frame
	closeBtn = headerFrame:WaitForChild("CloseButton", 5) :: TextButton

	local pill = headerFrame:FindFirstChild("ProgressPill") :: Frame?
	if pill then
		progressLabel = pill:FindFirstChild("ProgressLabel") :: TextLabel?
	end

	gridSection = mainWindow:WaitForChild("CodexGridSection", 5) :: Frame
	filterBar = gridSection:WaitForChild("FilterBar", 5) :: Frame
	gridScroll = gridSection:WaitForChild("WeaponGridScroll", 5) :: ScrollingFrame
	gridLayout = gridScroll:WaitForChild("UIGridLayout", 5) :: UIGridLayout

	local foundTemplate = gridScroll:WaitForChild("SlotTemplate", 5) :: Frame
	slotTemplate = foundTemplate:Clone()
	slotTemplate.Visible = false
	foundTemplate.Visible = false

	inspectSection = mainWindow:WaitForChild("CodexInspectionSection", 5) :: Frame
	wepNameLabel = inspectSection:WaitForChild("WeaponNameLabel", 5) :: TextLabel
	wepRarityLabel = inspectSection:WaitForChild("WeaponRarityLabel", 5) :: TextLabel

	local plaque = inspectSection:WaitForChild("PreviewPlaque", 5) :: Frame
	largeIcon = plaque:WaitForChild("LargeIcon", 5) :: ImageLabel

	local statContainer = inspectSection:WaitForChild("StatContainer", 5) :: Frame
	local dmgPill = statContainer:WaitForChild("DamagePill", 5) :: Frame
	dmgTextLabel = dmgPill:WaitForChild("DamageText", 5) :: TextLabel

	local spdPill = statContainer:WaitForChild("SpeedPill", 5) :: Frame
	spdTextLabel = spdPill:WaitForChild("SpeedText", 5) :: TextLabel

	local loreBox = inspectSection:WaitForChild("LoreBox", 5) :: Frame
	loreDescriptionLabel = loreBox:WaitForChild("LoreDescription", 5) :: TextLabel

	statusBox = inspectSection:WaitForChild("StatusPlaque", 5) :: Frame
	statusLabel = statusBox:WaitForChild("StatusLabel", 5) :: TextLabel
	statusGrad = statusBox:FindFirstChildOfClass("UIGradient")

	closeBtn.MouseButton1Click:Connect(function()
		WeaponCodexController.Close()
	end)

	modalBackdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local clickPos = input.Position
			local pos = mainWindow.AbsolutePosition
			local size = mainWindow.AbsoluteSize
			local inside = clickPos.X >= pos.X and clickPos.X <= (pos.X + size.X) and clickPos.Y >= pos.Y and clickPos.Y <= (pos.Y + size.Y)
			if not inside then
				WeaponCodexController.Close()
			end
		end
	end)

	for _, tab in ipairs(filterBar:GetChildren()) do
		if tab:IsA("TextButton") then
			local tabName = tab.Name:upper():gsub("FILTER_", "")
			tab.MouseButton1Click:Connect(function()
				PlayClick()
				currentFilter = tabName
				WeaponCodexController.UpdateFilterTabsVisual()
				if gridScroll then
					gridScroll.CanvasPosition = Vector2.zero
				end
				WeaponCodexController.RenderCodex()
			end)
		end
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() ~= nil then return end
		if input.KeyCode == Enum.KeyCode.U then
			WeaponCodexController.Toggle()
		end
	end)

	updateInventoryRemote.OnClientEvent:Connect(function(invData: any)
		latestInventoryData = invData
		RefreshOwnedWeapons()
		if isOpen then
			WeaponCodexController.RenderCodex()
		end
	end)

	print("[ASCEND] WeaponCodexController Initialized (Modal Exclusion & 'U' Keybind Active).")
end

function WeaponCodexController.UpdateFilterTabsVisual()
	for _, tab in ipairs(filterBar:GetChildren()) do
		if tab:IsA("TextButton") then
			local tabName = tab.Name:upper():gsub("FILTER_", "")
			local isActive = (tabName == currentFilter)
			local g = tab:FindFirstChildOfClass("UIGradient")
			if g then
				if isActive then
					g.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 245, 155)),
						ColorSequenceKeypoint.new(0.45, Color3.fromRGB(245, 158, 11)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(180, 75, 5))
					})
				else
					g.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0.00, Color3.fromRGB(65, 82, 108)),
						ColorSequenceKeypoint.new(0.45, Color3.fromRGB(28, 36, 50)),
						ColorSequenceKeypoint.new(1.00, Color3.fromRGB(14, 18, 26))
					})
				end
			end
		end
	end
end

function WeaponCodexController.Toggle()
	if isOpen then
		WeaponCodexController.Close()
	else
		WeaponCodexController.Open()
	end
end

function WeaponCodexController.Open()
	if isOpen then return end
	isOpen = true

	-- 🚀 Request mutual exclusion open
	local mgr = GetModalManager()
	if mgr then
		mgr.RequestOpen("WeaponCodex")
	end

	PlayClick()
	RefreshOwnedWeapons()

	screenGui.Enabled = true
	mainWindow.Visible = true

	modalBackdrop.BackgroundTransparency = 1
	modalBackdrop.Visible = true
	TweenService:Create(modalBackdrop, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45
	}):Play()

	windowScale.Scale = 0.75
	TweenService:Create(windowScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0
	}):Play()

	if gridScroll then
		gridScroll.CanvasPosition = Vector2.zero
	end

	inventoryActionRemote:FireServer({ Action = "RequestSync" })
	WeaponCodexController.UpdateFilterTabsVisual()
	WeaponCodexController.RenderCodex()
end

function WeaponCodexController.Close()
	if not isOpen then return end
	isOpen = false
	PlayClick()

	local mgr = GetModalManager()
	if mgr then
		mgr.NotifyClosed("WeaponCodex")
	end

	local scaleTween = TweenService:Create(windowScale, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Scale = 0.75
	})
	local fadeTween = TweenService:Create(modalBackdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})

	scaleTween:Play()
	fadeTween:Play()

	scaleTween.Completed:Connect(function()
		if not isOpen then
			screenGui.Enabled = false
			mainWindow.Visible = false
			modalBackdrop.Visible = false
			windowScale.Scale = 1.0
		end
	end)
end

function WeaponCodexController.RenderCodex()
	for _, child in ipairs(gridScroll:GetChildren()) do
		if child:IsA("Frame") and child ~= slotTemplate then
			child:Destroy()
		end
	end
	table.clear(activeSlotClones)

	local allItems = ItemConfig.GetAllItems()
	type WeaponEntry = {
		Id: string,
		Name: string,
		Rarity: string,
		Damage: number,
		Speed: number,
		Description: string,
		IsUnlocked: boolean,
		RankOrder: number,
	}

	local RARITY_ORDER = {
		Common = 1, Mortal = 1,
		Uncommon = 2, Spiritual = 2,
		Rare = 3, Earth = 3,
		Epic = 4, Heaven = 4,
		Legendary = 5,
		Mythic = 6,
		Divine = 7,
		Immortal = 8,
	}

	local weaponList: { WeaponEntry } = {}
	local totalWeapons = 0
	local totalUnlocked = 0

	for itemId, def in pairs(allItems) do
		local isWeapon = (def.Type == "Weapon" or def.Type == "FlyingSword" or def.Type == "Sword")
		if isWeapon then
			totalWeapons += 1
			local isUnlocked = (ownedWeaponSet[itemId] == true)
			if isUnlocked then
				totalUnlocked += 1
			end

			local rarity = def.Rarity or "Common"
			local passesFilter = (currentFilter == "ALL") or (rarity:upper() == currentFilter)

			if passesFilter then
				table.insert(weaponList, {
					Id = itemId,
					Name = def.Name or itemId,
					Rarity = rarity,
					Damage = def.Damage or 25,
					Speed = def.Speed or 1.0,
					Description = def.Description or "An ancient sword forged by immortal hands.",
					IsUnlocked = isUnlocked,
					RankOrder = RARITY_ORDER[rarity] or 1,
				})
			end
		end
	end

	if progressLabel then
		local pct = math.floor((totalUnlocked / math.max(1, totalWeapons)) * 100)
		progressLabel.Text = string.format("AWAKENED: %d / %d (%d%%)", totalUnlocked, totalWeapons, pct)
	end

	table.sort(weaponList, function(a, b)
		if a.IsUnlocked ~= b.IsUnlocked then
			return a.IsUnlocked and not b.IsUnlocked
		end
		if a.RankOrder ~= b.RankOrder then
			return a.RankOrder < b.RankOrder
		end
		return a.Damage < b.Damage
	end)

	for _, wep in ipairs(weaponList) do
		local slot = slotTemplate:Clone()
		slot.Name = "Slot_" .. wep.Id
		slot.Visible = true

		local rInfo = GetRarityInfo(wep.Rarity)
		local ribbon = slot:FindFirstChild("TopRibbon") :: Frame?
		local rLabel = ribbon and ribbon:FindFirstChild("RibbonLabel") :: TextLabel?
		local titleLbl = slot:FindFirstChild("SlotTitle") :: TextLabel?
		local iconImg = slot:FindFirstChild("WeaponIcon") :: ImageLabel?
		local lock = slot:FindFirstChild("LockIcon") :: TextLabel?
		local borderGlow = slot:FindFirstChild("SlotBorderGlow") :: UIStroke?
		local slotGrad = slot:FindFirstChildOfClass("UIGradient")

		local iconAsset = GetWeaponIcon(wep.Id)

		if wep.IsUnlocked then
			if ribbon then ribbon.BackgroundColor3 = rInfo.Color end
			if rLabel then rLabel.Text = wep.Rarity:upper() end
			if titleLbl then titleLbl.Text = wep.Name:upper() end
			if lock then lock.Visible = false end
			if borderGlow then borderGlow.Color = rInfo.Color end

			if iconImg then
				iconImg.Image = iconAsset or ""
				iconImg.ImageTransparency = 0
				iconImg.ImageColor3 = Color3.fromRGB(255, 255, 255)
				iconImg.Visible = (iconAsset ~= nil and iconAsset ~= "")
			end

			if slotGrad then
				local kps = {}
				for _, stop in ipairs(rInfo.Grad) do
					table.insert(kps, ColorSequenceKeypoint.new(stop.t, stop.c))
				end
				slotGrad.Color = ColorSequence.new(kps)
			end
		else
			if ribbon then ribbon.BackgroundColor3 = Color3.fromRGB(38, 44, 56) end
			if rLabel then rLabel.Text = "LOCKED" end
			if titleLbl then titleLbl.Text = "???" end
			if lock then lock.Visible = true end
			if borderGlow then borderGlow.Color = Color3.fromRGB(42, 50, 64) end

			if iconImg then
				if iconAsset and iconAsset ~= "" then
					iconImg.Image = iconAsset
					iconImg.ImageTransparency = 0.85
					iconImg.ImageColor3 = Color3.fromRGB(15, 18, 24)
					iconImg.Visible = true
				else
					iconImg.Visible = false
				end
			end

			if slotGrad then
				slotGrad.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 18, 26)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 10, 15))
				})
			end
		end

		local trigger = slot:FindFirstChild("ClickTrigger") :: GuiButton?
		if trigger then
			trigger.MouseButton1Click:Connect(function()
				PlayClick()
				selectedWeaponId = wep.Id
				WeaponCodexController.UpdateInspection(wep)
			end)
		end

		slot.Parent = gridScroll
		table.insert(activeSlotClones, slot)
	end

	if #weaponList > 0 then
		local targetWep = weaponList[1]
		if selectedWeaponId then
			for _, w in ipairs(weaponList) do
				if w.Id == selectedWeaponId then
					targetWep = w
					break
				end
			end
		end
		selectedWeaponId = targetWep.Id
		WeaponCodexController.UpdateInspection(targetWep)
	else
		WeaponCodexController.ClearInspection()
	end
end

function WeaponCodexController.UpdateInspection(wep: { Id: string, Name: string, Rarity: string, Damage: number, Speed: number, Description: string, IsUnlocked: boolean })
	local rInfo = GetRarityInfo(wep.Rarity)
	local iconAsset = GetWeaponIcon(wep.Id)

	if wep.IsUnlocked then
		wepNameLabel.Text = wep.Name:upper()
		wepRarityLabel.Text = string.format("%s SPIRIT SWORD", wep.Rarity:upper())
		wepRarityLabel.TextColor3 = rInfo.Color

		if largeIcon then
			largeIcon.Image = iconAsset or ""
			largeIcon.ImageTransparency = 0
			largeIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			largeIcon.Visible = (iconAsset ~= nil and iconAsset ~= "")
		end

		dmgTextLabel.Text = string.format("+%d BASE DMG", wep.Damage)
		spdTextLabel.Text = string.format("%.2fX CADENCE", wep.Speed)
		loreDescriptionLabel.Text = wep.Description

		statusLabel.Text = "✦ STATUS: AWAKENED IN ARSENAL ✦"
		statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		if statusGrad then
			statusGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(135, 255, 195)),
				ColorSequenceKeypoint.new(0.45, Color3.fromRGB(16, 215, 130)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(4, 115, 70))
			})
		end
	else
		wepNameLabel.Text = "??? (UNAWAKENED)"
		wepRarityLabel.Text = string.format("%s SPIRIT SWORD (SEALED)", wep.Rarity:upper())
		wepRarityLabel.TextColor3 = Color3.fromRGB(140, 150, 165)

		if largeIcon then
			if iconAsset and iconAsset ~= "" then
				largeIcon.Image = iconAsset
				largeIcon.ImageTransparency = 0.85
				largeIcon.ImageColor3 = Color3.fromRGB(15, 18, 25)
				largeIcon.Visible = true
			else
				largeIcon.Visible = false
			end
		end

		dmgTextLabel.Text = "??? BASE DMG"
		spdTextLabel.Text = "??? CADENCE"
		loreDescriptionLabel.Text = "This ancient weapon remains sealed within the sect archives. Forge, discover, or awaken this blade through martial cultivation and boss trials."

		statusLabel.Text = "✦ STATUS: SEALED — NOT YET UNLOCKED ✦"
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
		if statusGrad then
			statusGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(160, 30, 45)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(110, 20, 32)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(60, 10, 18))
			})
		end
	end
end

function WeaponCodexController.ClearInspection()
	wepNameLabel.Text = "NO WEAPONS FOUND"
	wepRarityLabel.Text = "EMPTY ARCHIVE"
	if largeIcon then largeIcon.Visible = false end
	dmgTextLabel.Text = "-"
	spdTextLabel.Text = "-"
	loreDescriptionLabel.Text = "No martial weapons match the selected rarity filter."
	statusLabel.Text = "✦ EMPTY ✦"
end

return WeaponCodexController