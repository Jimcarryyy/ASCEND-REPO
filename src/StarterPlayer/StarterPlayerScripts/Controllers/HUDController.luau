--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Client HUD Engine for ASCEND.
    Features: Hooks into StarterGui.TopMenuGUI and VitalHUDGui (Zero hardcoded dock creation).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local HUDSkinConfig = require(ReplicatedStorage.Shared.Configs.HUDSkinConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HUDController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI_FONT   = Enum.Font.FredokaOne
local UI_FONT_2 = Enum.Font.LuckiestGuy
local T         = UIAssets.Theme

local CLICK_SOUND_ID = "rbxassetid://6895079853"

local hudScreenGui: ScreenGui?
local topMenuGui: ScreenGui?
local vitalFrame: ImageLabel?
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

local currentInventoryData: { [number]: any } = {}
local activeSkinId: string = "DefaultBronze"
local activeBreakthroughToast: Frame? = nil

local updateInventoryRemote: RemoteEvent
local updateCultivationRemote: RemoteEvent
local combatActionRemote: RemoteEvent

local function PlayClickAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)
end

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
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	HUDController.HookExplorerHUD()
	HUDController.HookTopMenu()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventoryData = inventoryData or {}
		HUDController.UpdateHotbar()
	end)

	updateCultivationRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" then
			if payload.Action == "BreakthroughRejected" and payload.Message then
				HUDController.ShowEncouragingToast(payload.Message)
				return
			end

			local curQi = payload.CurrentQi or 1000
			local maxQi = payload.MaxQi or 1000
			local tier = payload.Tier
			local order = payload.Order

			HUDController.UpdateQiValues(curQi, maxQi)

			if tier ~= nil and order ~= nil and levelBadgeText then
				local totalLevel = ((tier - 1) * 9) + order
				levelBadgeText.Text = string.format("<b>%d</b>", totalLevel)
			end
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

	print("[ASCEND] HUDController Initialized (Hooked to Studio TopMenuGUI & VitalHUDGui).")
end

-- Binds to your Studio TopMenuGUI Frame
function HUDController.HookTopMenu()
	topMenuGui = playerGui:WaitForChild("TopMenuGUI", 10) :: ScreenGui?
	if not topMenuGui then return end

	local topMenu = topMenuGui:WaitForChild("TopMenu", 5) :: Frame?
	if not topMenu then return end

	local function BindMenuClick(menuName: string, onClick: () -> ())
		local menuContainer = topMenu:FindFirstChild(menuName)
		if not menuContainer then return end

		local function trigger()
			PlayClickAudio()
			onClick()
		end

		if menuContainer:IsA("GuiButton") then
			menuContainer.MouseButton1Click:Connect(trigger)
		else
			-- If container is a Frame, bind to click/touch anywhere inside it
			menuContainer.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					trigger()
				end
			end)
		end
	end

	-- 1. Bag Menu
	BindMenuClick("BagMenu", function()
		local controllers = player.PlayerScripts:FindFirstChild("Controllers")
		if controllers then
			local invCtrl = controllers:FindFirstChild("InventoryController")
			if invCtrl then
				local req = require(invCtrl) :: any
				if req.Toggle then req.Toggle() end
			end
		end
	end)

	-- 2. Meditate Menu
	BindMenuClick("MeditateMenu", function()
		combatActionRemote:FireServer({ ToggleMeditation = true })
	end)

	-- 3. Arena Menu
	BindMenuClick("ArenaMenu", function()
		local controllers = player.PlayerScripts:FindFirstChild("Controllers")
		if controllers then
			local arenaCtrl = controllers:FindFirstChild("ArenaController")
			if arenaCtrl then
				local req = require(arenaCtrl) :: any
				if req.OpenRegistrationModal then req.OpenRegistrationModal() end
			end
		end
	end)

	-- 4. Settings Menu (Placeholder ready)
	BindMenuClick("SettingsMenu", function()
		print("[HUDController] Settings Menu clicked.")
	end)
end

function HUDController.HookExplorerHUD()
	hudScreenGui = (playerGui:WaitForChild("VitalHUDGui", 8) or playerGui:WaitForChild("AscendMainHUD", 8)) :: ScreenGui?
	if not hudScreenGui then
		hudScreenGui = playerGui:FindFirstChildOfClass("ScreenGui")
	end
	if not hudScreenGui then return end

	vitalFrame = (hudScreenGui:WaitForChild("VitalHUDFrame", 5) or hudScreenGui:FindFirstChild("VitalHUDFrame", true)) :: ImageLabel?
	if not vitalFrame then return end

	portraitMaskFrame = FindChildCaseInsensitive(vitalFrame, "PortraitMask") :: Frame?
	if portraitMaskFrame then
		portraitMaskFrame.BackgroundTransparency = 1
		avatarHeadshot = FindChildCaseInsensitive(portraitMaskFrame, "AvatarHeadshot") :: ImageLabel?
		if avatarHeadshot then
			avatarHeadshot.BackgroundTransparency = 1
			avatarHeadshot.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", player.UserId)
		end
	end

	levelBadgeText = FindChildCaseInsensitive(vitalFrame, "LevelBadgeText") :: TextLabel?
	if levelBadgeText then
		levelBadgeText.BackgroundTransparency = 1
		levelBadgeText.Font = UI_FONT
		levelBadgeText.RichText = true
		levelBadgeText.TextYAlignment = Enum.TextYAlignment.Center
		levelBadgeText.Text = "<b>1</b>"
	end

	nameAndRealmText = FindChildCaseInsensitive(vitalFrame, "NameAndRealmText") :: TextLabel?
	if nameAndRealmText then
		nameAndRealmText.BackgroundTransparency = 1
		nameAndRealmText.Font = UI_FONT
		nameAndRealmText.RichText = true
		nameAndRealmText.TextYAlignment = Enum.TextYAlignment.Center
		nameAndRealmText.Text = string.format("<b>%s</b>", player.DisplayName)
	end

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
			hpLeftLabel.TextColor3 = T.PrimaryText
			hpLeftLabel.Font = UI_FONT_2
			hpLeftLabel.TextSize = 13
			hpLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			hpLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			hpLeftLabel.ZIndex = 10
			hpLeftLabel.Parent = hpSlotFrame
		end
	end

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
			qiLeftLabel.TextColor3 = T.PrimaryText
			qiLeftLabel.Font = UI_FONT_2
			qiLeftLabel.TextSize = 13
			qiLeftLabel.TextXAlignment = Enum.TextXAlignment.Left
			qiLeftLabel.TextYAlignment = Enum.TextYAlignment.Center
			qiLeftLabel.ZIndex = 10
			qiLeftLabel.Parent = qiSlotFrame
		end
	end

	hotbarFrame = FindChildCaseInsensitive(hudScreenGui, "HotbarFrame") :: Frame?
	if hotbarFrame then
		for i = 1, 6 do
			local slot = FindChildCaseInsensitive(hotbarFrame, "HotbarSlot_" .. i) :: Frame?
			if slot then
				hotbarSlots[i] = slot
			end
		end
	end

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

	local offsets = skin.SlotOffsets
	if offsets then
		if hpSlotFrame and offsets.HPSlotPosition then hpSlotFrame.Position = offsets.HPSlotPosition end
		if hpSlotFrame and offsets.HPSlotSize then hpSlotFrame.Size = offsets.HPSlotSize end
		if qiSlotFrame and offsets.QISlotPosition then qiSlotFrame.Position = offsets.QISlotPosition end
		if qiSlotFrame and offsets.QISlotSize then qiSlotFrame.Size = offsets.QISlotSize end
		if portraitMaskFrame and offsets.PortraitPosition then portraitMaskFrame.Position = offsets.PortraitPosition end
		if portraitMaskFrame and offsets.PortraitSize then portraitMaskFrame.Size = offsets.PortraitSize end
		if levelBadgeText and offsets.LevelBadgePosition then levelBadgeText.Position = offsets.LevelBadgePosition end
		if nameAndRealmText and offsets.NameAndRealmPosition then nameAndRealmText.Position = offsets.NameAndRealmPosition end
	end
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
			hpBarText.Text = string.format("%s / %s", CultivationConfig.FormatNumber(hp), CultivationConfig.FormatNumber(maxHp))
		end
	end

	local function updateQi()
		local rawQi = character:GetAttribute("Qi") or 1000
		local maxQi = character:GetAttribute("MaxQi") or 1000
		local level = character:GetAttribute("Level")

		HUDController.UpdateQiValues(rawQi, maxQi)
		if level ~= nil and levelBadgeText then
			levelBadgeText.Text = string.format("<b>%d</b>", level)
		end
	end

	humanoid.HealthChanged:Connect(updateHP)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHP)
	character:GetAttributeChangedSignal("Qi"):Connect(updateQi)
	character:GetAttributeChangedSignal("MaxQi"):Connect(updateQi)
	character:GetAttributeChangedSignal("Level"):Connect(updateQi)

	updateHP()
	updateQi()
end

function HUDController.UpdateQiValues(currentQi: number, maxQi: number)
	local cultivatedCap = math.max(1, maxQi or 1000)
	local curEnergy = math.clamp(currentQi or 0, 0, cultivatedCap)
	local ratio = math.clamp(curEnergy / cultivatedCap, 0, 1)

	if qiBarFill then
		qiBarFill.Size = UDim2.new(ratio, 0, qiFillYScale, qiFillYOffset)
	end

	if qiBarText then
		qiBarText.Text = string.format("%s / %s", CultivationConfig.FormatNumber(curEnergy), CultivationConfig.FormatNumber(cultivatedCap))
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
			slotFrame.BackgroundColor3 = T.RaisedSurface
			if stroke then stroke.Color = T.MainBorder end
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

function HUDController.ShowEncouragingToast(message: string)
	if not hudScreenGui then
		HUDController.HookExplorerHUD()
	end
	if not hudScreenGui then return end

	if activeBreakthroughToast and activeBreakthroughToast.Parent then
		activeBreakthroughToast:Destroy()
	end

	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "BreakthroughEncouragingToast"
	toastFrame.Size = UDim2.new(0, 420, 0, 48)
	toastFrame.Position = UDim2.new(0.5, -210, 0.65, 0)
	toastFrame.BackgroundColor3 = T.DeepBackground
	toastFrame.BackgroundTransparency = 1
	toastFrame.BorderSizePixel = 0
	toastFrame.ZIndex = 50
	toastFrame.Parent = hudScreenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = toastFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = T.HighlightBorder
	stroke.Thickness = 1.5
	stroke.Transparency = 1
	stroke.Parent = toastFrame

	local textLbl = Instance.new("TextLabel")
	textLbl.Name = "ToastMessage"
	textLbl.Size = UDim2.new(1, -20, 1, 0)
	textLbl.Position = UDim2.new(0, 10, 0, 0)
	textLbl.BackgroundTransparency = 1
	textLbl.Text = message
	textLbl.TextColor3 = T.PrimaryText
	textLbl.TextTransparency = 1
	textLbl.Font = UI_FONT_2
	textLbl.TextSize = 15
	textLbl.TextWrapped = true
	textLbl.TextXAlignment = Enum.TextXAlignment.Center
	textLbl.TextYAlignment = Enum.TextYAlignment.Center
	textLbl.ZIndex = 51
	textLbl.Parent = toastFrame

	activeBreakthroughToast = toastFrame

	local tweenIn = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(toastFrame, tweenIn, { BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, tweenIn, { Transparency = 0 }):Play()
	TweenService:Create(textLbl, tweenIn, { TextTransparency = 0 }):Play()

	task.delay(2.5, function()
		if toastFrame and toastFrame.Parent then
			local tweenOut = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			TweenService:Create(toastFrame, tweenOut, { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, tweenOut, { Transparency = 1 }):Play()
			local fadeText = TweenService:Create(textLbl, tweenOut, { TextTransparency = 1 })
			fadeText:Play()

			fadeText.Completed:Connect(function()
				if toastFrame and toastFrame.Parent then
					toastFrame:Destroy()
				end
				if activeBreakthroughToast == toastFrame then
					activeBreakthroughToast = nil
				end
			end)
		end
	end)
end

function HUDController.ShowItemToast(itemId: string, count: number, qualityText: any?)
	if not toastContainer then
		HUDController.HookExplorerHUD()
	end
	if not toastContainer then return end

	local itemDef = ItemConfig.GetItem(itemId)
	local itemName = if itemDef then itemDef.Name else itemId
	local iconAsset = if itemDef then itemDef.Icon else nil

	local qualityStr: string? = nil
	if qualityText ~= nil then
		qualityStr = tostring(qualityText)
	end

	local colorData = UIAssets.RarityCardColors[if itemDef then itemDef.Rarity else "Common"]
	if qualityStr and UIAssets.GradeCardColors[qualityStr] then
		colorData = UIAssets.GradeCardColors[qualityStr]
	end

	local cardBg = if colorData then colorData.Background else T.RaisedSurface
	local borderCol = if colorData then colorData.Border else T.JadeAccent

	local toastText = string.format("+%d  %s", count, itemName)
	if qualityStr and qualityStr ~= "" then
		local cleanQuality = string.gsub(qualityStr, " Quality", "")
		toastText = string.format("+%d  [%s] %s", count, cleanQuality, itemName)
	end

	local toastFrame = Instance.new("Frame")
	toastFrame.Name = "ItemToast"
	toastFrame.Size = UDim2.new(1, 0, 0, 42)
	toastFrame.BackgroundColor3 = cardBg
	toastFrame.BackgroundTransparency = 0
	toastFrame.BorderSizePixel = 0
	toastFrame.Parent = toastContainer

	local stroke = Instance.new("UIStroke")
	stroke.Color = borderCol
	stroke.Thickness = 1.5
	stroke.Transparency = 0
	stroke.Parent = toastFrame

	local iconLabel = Instance.new("ImageLabel")
	iconLabel.Name = "ToastIcon"
	iconLabel.Size = UDim2.new(0, 30, 0, 30)
	iconLabel.Position = UDim2.new(0, 6, 0, 6)
	iconLabel.BackgroundTransparency = 1
	iconLabel.ScaleType = Enum.ScaleType.Fit
	iconLabel.Image = iconAsset or ""
	iconLabel.ImageTransparency = 0
	iconLabel.Parent = toastFrame

	local textLbl = Instance.new("TextLabel")
	textLbl.Name = "ToastText"
	textLbl.Size = UDim2.new(1, -48, 1, 0)
	textLbl.Position = UDim2.new(0, 42, 0, 0)
	textLbl.BackgroundTransparency = 1
	textLbl.Text = toastText
	textLbl.TextColor3 = T.PrimaryText
	textLbl.TextTransparency = 0
	textLbl.Font = UI_FONT
	textLbl.TextSize = 13
	textLbl.TextXAlignment = Enum.TextXAlignment.Left
	textLbl.TextYAlignment = Enum.TextYAlignment.Center
	textLbl.Parent = toastFrame

	task.delay(3.0, function()
		if toastFrame and toastFrame.Parent then
			toastFrame:Destroy()
		end
	end)
end

return HUDController