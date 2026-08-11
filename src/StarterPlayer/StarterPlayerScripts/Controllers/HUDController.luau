--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Client HUD engine for ASCEND.
    Supports Monetized HUD Skin Equipping (HUDSkinConfig), FredokaOne titles, Bangers vital text, and 800 Max Qi sync.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local HUDSkinConfig = require(ReplicatedStorage.Shared.Configs.HUDSkinConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HUDController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI_FONT   = Enum.Font.FredokaOne
local UI_FONT_2 = Enum.Font.LuckiestGuy

-- LIGHT-MODE PALETTE & HUD ACCENTS
local COLOR_LIGHT_PANEL  = Color3.fromRGB(241, 245, 249)
local COLOR_LIGHT_CARD   = Color3.fromRGB(255, 255, 255)
local COLOR_LIGHT_BORDER = Color3.fromRGB(203, 213, 225)
local COLOR_TEXT_MAIN    = Color3.fromRGB(15, 23, 42)
local COLOR_HP_GREEN     = Color3.fromRGB(16, 185, 129)

local hudScreenGui: ScreenGui
local vitalFrame: ImageLabel
local portraitMaskFrame: Frame?
local avatarHeadshot: ImageLabel?
local levelBadgeText: TextLabel?
local nameAndRealmText: TextLabel?

local hpSlotFrame: Frame?
local hpBarFill: Frame?
local hpBarText: TextLabel?
local hpLeftLabel: TextLabel?
local hpFillYScale: number = 1
local hpFillYOffset: number = 0

local qiSlotFrame: Frame?
local qiBarFill: Frame?
local qiBarText: TextLabel?
local qiLeftLabel: TextLabel?
local qiFillYScale: number = 1
local qiFillYOffset: number = 0

local hotbarFrame: Frame?
local toastContainer: Frame?
local hotbarSlots: { [number]: Frame } = {}
local hotbarKeybinds = { "1", "2", "3", "4", "5", "K" }

local currentInventoryData: { [number]: any } = {}
local activeSkinId: string = "DefaultBronze"

local updateInventoryRemote: RemoteEvent
local updateCultivationRemote: RemoteEvent

local function FindChildCaseInsensitive(parent: Instance, targetName: string): Instance?
	local targetLower = targetName:lower()
	for _, child in ipairs(parent:GetChildren()) do
		if child.Name:lower() == targetLower then
			return child
		end
	end
	return nil
end

function HUDController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	HUDController.HookExplorerHUD()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventoryData = inventoryData or {}
		HUDController.UpdateHotbar()
	end)

	-- Direct Cultivation Qi Sync from Server
	updateCultivationRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" then
			local curQi = payload.CurrentQi or 800
			HUDController.UpdateQiValues(curQi, 800)
		end
	end)

	player.CharacterAdded:Connect(function(character)
		HUDController.HookCharacter(character)
		HUDController.ListenSkinChanges(character)
	end)

	if player.Character then
		HUDController.HookCharacter(player.Character)
		HUDController.ListenSkinChanges(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local keyNum = tonumber(input.KeyCode.Name:sub(-1))
		if keyNum and keyNum >= 1 and keyNum <= 5 then
			local inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")
			inventoryActionRemote:FireServer({
				Action = "UseItem",
				SlotIndex = keyNum,
			})
		end
	end)

	print("[ASCEND] HUDController Initialized with Monetized HUD Skin Support.")
end

function HUDController.HookExplorerHUD()
	hudScreenGui = playerGui:WaitForChild("AscendMainHUD") :: ScreenGui
	vitalFrame = hudScreenGui:WaitForChild("VitalHUDFrame") :: ImageLabel

	-- 1. Headshot Image
	portraitMaskFrame = FindChildCaseInsensitive(vitalFrame, "PortraitMask") :: Frame?
	if portraitMaskFrame then
		portraitMaskFrame.BackgroundTransparency = 1
		avatarHeadshot = FindChildCaseInsensitive(portraitMaskFrame, "AvatarHeadshot") :: ImageLabel?
		if avatarHeadshot then
			avatarHeadshot.BackgroundTransparency = 1
			avatarHeadshot.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", player.UserId)
		end
	end

	-- 2. Level Badge & Player Name
	levelBadgeText = FindChildCaseInsensitive(vitalFrame, "LevelBadgeText") :: TextLabel?
	if levelBadgeText then
		levelBadgeText.BackgroundTransparency = 1
		levelBadgeText.Font = UI_FONT
		levelBadgeText.RichText = true
		levelBadgeText.TextYAlignment = Enum.TextYAlignment.Center
		levelBadgeText.Text = "<b>100</b>"
	end

	nameAndRealmText = FindChildCaseInsensitive(vitalFrame, "NameAndRealmText") :: TextLabel?
	if nameAndRealmText then
		nameAndRealmText.BackgroundTransparency = 1
		nameAndRealmText.Font = UI_FONT
		nameAndRealmText.RichText = true
		nameAndRealmText.TextYAlignment = Enum.TextYAlignment.Center
		nameAndRealmText.Text = string.format("<b>%s</b>", player.DisplayName)
	end

	-- 3. Bind HP Slot
	hpSlotFrame = FindChildCaseInsensitive(vitalFrame, "HPSlotFrame") :: Frame?
	if hpSlotFrame then
		hpSlotFrame.BackgroundTransparency = 1
		hpSlotFrame.ClipsDescendants = true

		hpBarFill = FindChildCaseInsensitive(hpSlotFrame, "HPBarFill") :: Frame?
		if hpBarFill then
			hpFillYScale = hpBarFill.Size.Y.Scale
			hpFillYOffset = hpBarFill.Size.Y.Offset
		end

		hpBarText = FindChildCaseInsensitive(hpSlotFrame, "HPBarText") :: TextLabel?
		if hpBarText then
			hpBarText.BackgroundTransparency = 1
			hpBarText.Font = UI_FONT_2
			hpBarText.TextSize = 13
			hpBarText.Position = UDim2.new(0, 0, 0, 0)
			hpBarText.Size = UDim2.new(1, -18, 1, 0)
			hpBarText.TextXAlignment = Enum.TextXAlignment.Right
			hpBarText.TextYAlignment = Enum.TextYAlignment.Center
			hpBarText.ZIndex = 8
		end

		hpLeftLabel = FindChildCaseInsensitive(hpSlotFrame, "HPLabel") :: TextLabel?
		if not hpLeftLabel then
			hpLeftLabel = Instance.new("TextLabel")
			hpLeftLabel.Name = "HPLabel"
			hpLeftLabel.Size = UDim2.new(0, 40, 1, 0)
			hpLeftLabel.Position = UDim2.new(0, 14, 0, 0)
			hpLeftLabel.BackgroundTransparency = 1
			hpLeftLabel.Text = "HP"
			hpLeftLabel.TextColor3 = COLOR_LIGHT_CARD
			hpLeftLabel.Font = UI_FONT_2
			hpLeftLabel.TextSize = 13
			hpLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			hpLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			hpLeftLabel.ZIndex = 10
			hpLeftLabel.Parent = hpSlotFrame
		else
			hpLeftLabel.BackgroundTransparency = 1
			hpLeftLabel.Text = "HP"
			hpLeftLabel.Font = UI_FONT_2
			hpLeftLabel.TextSize = 13
			hpLeftLabel.Position = UDim2.new(0, 14, 0, 0)
			hpLeftLabel.Size = UDim2.new(0, 40, 1, 0)
			hpLeftLabel.TextColor3 = COLOR_LIGHT_CARD
			hpLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			hpLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			hpLeftLabel.ZIndex = 10
			hpLeftLabel.Visible = true
		end
	end

	-- 4. Bind QI Slot
	qiSlotFrame = FindChildCaseInsensitive(vitalFrame, "QiSlotFrame") :: Frame?
	if qiSlotFrame then
		qiSlotFrame.BackgroundTransparency = 1
		qiSlotFrame.ClipsDescendants = true

		qiBarFill = FindChildCaseInsensitive(qiSlotFrame, "QiBarFill") :: Frame?
		if qiBarFill then
			qiFillYScale = qiBarFill.Size.Y.Scale
			qiFillYOffset = qiBarFill.Size.Y.Offset
		end

		qiBarText = FindChildCaseInsensitive(qiSlotFrame, "QiBarText") :: TextLabel?
		if qiBarText then
			qiBarText.BackgroundTransparency = 1
			qiBarText.Font = UI_FONT_2
			qiBarText.TextSize = 13
			qiBarText.Position = UDim2.new(0, 0, 0, 0)
			qiBarText.Size = UDim2.new(1, -18, 1, 0)
			qiBarText.TextXAlignment = Enum.TextXAlignment.Right
			qiBarText.TextYAlignment = Enum.TextYAlignment.Center
			qiBarText.ZIndex = 8
		end

		qiLeftLabel = FindChildCaseInsensitive(qiSlotFrame, "QILabel") :: TextLabel?
		if not qiLeftLabel then
			qiLeftLabel = Instance.new("TextLabel")
			qiLeftLabel.Name = "QILabel"
			qiLeftLabel.Size = UDim2.new(0, 40, 1, 0)
			qiLeftLabel.Position = UDim2.new(0, 14, 0, 0)
			qiLeftLabel.BackgroundTransparency = 1
			qiLeftLabel.Text = "QI"
			qiLeftLabel.TextColor3 = COLOR_LIGHT_CARD
			qiLeftLabel.Font = UI_FONT_2
			qiLeftLabel.TextSize = 13
			qiLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			qiLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			qiLeftLabel.ZIndex = 10
			qiLeftLabel.Parent = qiSlotFrame
		else
			qiLeftLabel.BackgroundTransparency = 1
			qiLeftLabel.Text = "QI"
			qiLeftLabel.Font = UI_FONT_2
			qiLeftLabel.TextSize = 13
			qiLeftLabel.Position = UDim2.new(0, 14, 0, 0)
			qiLeftLabel.Size = UDim2.new(0, 40, 1, 0)
			qiLeftLabel.TextColor3 = COLOR_LIGHT_CARD
			qiLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			qiLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			qiLeftLabel.ZIndex = 10
			qiLeftLabel.Visible = true
		end
	end

	-- 5. Bind Hotbar Frame
	hotbarFrame = FindChildCaseInsensitive(hudScreenGui, "HotbarFrame") :: Frame?
	if hotbarFrame then
		for i = 1, 6 do
			local slot = FindChildCaseInsensitive(hotbarFrame, "HotbarSlot_" .. i) :: Frame?
			if slot then
				hotbarSlots[i] = slot
			end
		end
	end

	-- 6. Bind Toast Container
	toastContainer = FindChildCaseInsensitive(hudScreenGui, "ToastContainer") :: Frame?
end

function HUDController.ListenSkinChanges(character: Model)
	local equippedSkin = character:GetAttribute("EquippedHUDSkin") :: string?
	if equippedSkin then
		HUDController.ApplySkin(equippedSkin)
	end

	character:GetAttributeChangedSignal("EquippedHUDSkin"):Connect(function()
		local newSkin = character:GetAttribute("EquippedHUDSkin") :: string?
		if newSkin then
			HUDController.ApplySkin(newSkin)
		end
	end)
end

function HUDController.ApplySkin(skinId: string)
	local skin = HUDSkinConfig.GetSkin(skinId)
	if not skin or not vitalFrame then return end

	activeSkinId = skin.SkinId
	vitalFrame.Image = skin.AssetId

	-- Apply Skin Slot Coordinate Offsets
	local offsets = skin.SlotOffsets
	if offsets then
		if hpSlotFrame and offsets.HPSlotPosition then
			hpSlotFrame.Position = offsets.HPSlotPosition
		end
		if hpSlotFrame and offsets.HPSlotSize then
			hpSlotFrame.Size = offsets.HPSlotSize
		end

		if qiSlotFrame and offsets.QISlotPosition then
			qiSlotFrame.Position = offsets.QISlotPosition
		end
		if qiSlotFrame and offsets.QISlotSize then
			qiSlotFrame.Size = offsets.QISlotSize
		end

		if portraitMaskFrame and offsets.PortraitPosition then
			portraitMaskFrame.Position = offsets.PortraitPosition
		end
		if portraitMaskFrame and offsets.PortraitSize then
			portraitMaskFrame.Size = offsets.PortraitSize
		end

		if levelBadgeText and offsets.LevelBadgePosition then
			levelBadgeText.Position = offsets.LevelBadgePosition
		end

		if nameAndRealmText and offsets.NameAndRealmPosition then
			nameAndRealmText.Position = offsets.NameAndRealmPosition
		end
	end

	print(string.format("[ASCEND] Equipped HUD Skin '%s' (%s).", skin.Name, skin.SkinId))
end

function HUDController.HookCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local function updateHP()
		local hp = humanoid.Health
		local maxHp = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(hp / maxHp, 0, 1)

		if hpBarFill then
			hpBarFill.Size = UDim2.new(ratio, 0, hpFillYScale, hpFillYOffset)
		end
		if hpBarText then
			hpBarText.Text = string.format("%d / %d", math.floor(hp), math.floor(maxHp))
		end
	end

	local function updateQi()
		local rawQi = character:GetAttribute("Qi") or 800
		HUDController.UpdateQiValues(rawQi, 800)
	end

	humanoid.HealthChanged:Connect(updateHP)
	character:GetAttributeChangedSignal("Qi"):Connect(updateQi)
	character:GetAttributeChangedSignal("MaxQi"):Connect(updateQi)

	updateHP()
	updateQi()
end

function HUDController.UpdateQiValues(currentQi: number, maxQi: number)
	local targetMax = 800 -- Enforced 800 Max Qi
	local clampedQi = math.clamp(currentQi or 0, 0, targetMax)
	local clampedMax = math.clamp(maxQi or 800, 1, targetMax)
	local ratio = math.clamp(clampedQi / clampedMax, 0, 1)

	if qiBarFill then
		qiBarFill.Size = UDim2.new(ratio, 0, qiFillYScale, qiFillYOffset)
	end
	if qiBarText then
		qiBarText.Text = string.format("%d / %d", math.floor(clampedQi), clampedMax)
	end
end

function HUDController.UpdateHotbar()
	for i = 1, 5 do
		local slotFrame = hotbarSlots[i]
		if not slotFrame then continue end

		local icon = FindChildCaseInsensitive(slotFrame, "Icon") :: ImageLabel?
		local countLbl = FindChildCaseInsensitive(slotFrame, "CountLabel") :: TextLabel?
		local stroke = slotFrame:FindFirstChildOfClass("UIStroke")

		local slotData = currentInventoryData[i]
		if slotData then
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef then
				if icon then
					icon.Image = itemDef.Icon or ""
					icon.Visible = (itemDef.Icon ~= nil)
				end

				local colorData = UIAssets.RarityCardColors[itemDef.Rarity]
				if slotData.Quality and UIAssets.GradeCardColors[slotData.Quality] then
					colorData = UIAssets.GradeCardColors[slotData.Quality]
				end

				if colorData then
					slotFrame.BackgroundColor3 = colorData.Background
					if stroke then stroke.Color = colorData.Border end
				end

				if countLbl then countLbl.Text = if slotData.Count > 1 then "x" .. slotData.Count else "" end
			end
		else
			slotFrame.BackgroundColor3 = COLOR_LIGHT_CARD
			if stroke then stroke.Color = COLOR_LIGHT_BORDER end
			if icon then icon.Visible = false end
			if countLbl then countLbl.Text = "" end
		end
	end

	local slot6 = hotbarSlots[6]
	if slot6 then
		local countLbl = FindChildCaseInsensitive(slot6, "CountLabel") :: TextLabel?
		if countLbl then countLbl.Text = "POUCH" end
	end
end

-- ANIMATED ITEM TOAST WITH 2D ICON & DYNAMIC GRADE COLOR
function HUDController.ShowItemToast(itemId: string, count: number, qualityText: string?)
	if not toastContainer then return end

	local itemDef = ItemConfig.GetItem(itemId)
	local itemName = if itemDef then itemDef.Name else itemId
	local iconAsset = if itemDef then itemDef.Icon else nil

	local colorData = UIAssets.RarityCardColors[if itemDef then itemDef.Rarity else "Common"]
	if qualityText and UIAssets.GradeCardColors[qualityText] then
		colorData = UIAssets.GradeCardColors[qualityText]
	end

	local cardBg = if colorData then colorData.Background else COLOR_LIGHT_PANEL
	local borderCol = if colorData then colorData.Border else COLOR_HP_GREEN

	local toastText = string.format("+%d  %s", count, itemName)
	if qualityText then
		toastText = string.format("+%d  [%s] %s", count, qualityText:gsub(" Quality", ""), itemName)
	end

	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "ItemToast"
	toastFrame.Size = UDim2.new(1, 0, 0, 42)
	toastFrame.BackgroundColor3 = cardBg
	toastFrame.BackgroundTransparency = 1
	toastFrame.BorderSizePixel = 0
	toastFrame.Parent = toastContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = borderCol
	stroke.Thickness = 1.5
	stroke.Transparency = 1
	stroke.Parent = toastFrame

	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Name = "ToastIcon"
	iconLabel.Size = UDim2.new(0, 30, 0, 30)
	iconLabel.Position = UDim2.new(0, 6, 0, 6)
	iconLabel.BackgroundTransparency = 1
	iconLabel.ScaleType = Enum.ScaleType.Fit
	iconLabel.Image = iconAsset or ""
	iconLabel.ImageTransparency = 1
	iconLabel.Parent = toastFrame

	local textLbl = Instance.new("TextLabel")
	textLbl.Name = "ToastText"
	textLbl.Size = UDim2.new(1, -48, 1, 0)
	textLbl.Position = UDim2.new(0, 42, 0, 0)
	textLbl.BackgroundTransparency = 1
	textLbl.Text = toastText
	textLbl.TextColor3 = COLOR_TEXT_MAIN
	textLbl.TextTransparency = 1
	textLbl.Font = UI_FONT
	textLbl.TextSize = 13
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.TextYAlignment = Enum.TextYAlignment.Center
	textLbl.Parent = toastFrame

	local tweenInfoIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(toastFrame, tweenInfoIn, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, tweenInfoIn, { Transparency = 0 }):Play()
	TweenService:Create(textLbl, tweenInfoIn, { TextTransparency = 0 }):Play()
	TweenService:Create(iconLabel, tweenInfoIn, { ImageTransparency = 0 }):Play()

	task.delay(2.8, function()
		if not toastFrame.Parent then return end
		local tweenInfoOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local fadeOut = TweenService:Create(toastFrame, tweenInfoOut, { BackgroundTransparency = 1 })
		TweenService:Create(stroke, tweenInfoOut, { Transparency = 1 }):Play()
		TweenService:Create(textLbl, tweenInfoOut, { TextTransparency = 1 }):Play()
		TweenService:Create(iconLabel, tweenInfoOut, { ImageTransparency = 1 }):Play()

		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			toastFrame:Destroy()
		end)
	end)
end

return HUDController