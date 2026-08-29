--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Client HUD & Pure-Text Floating Toast Engine for ASCEND:
    - Master Top-Center Pure-Text Toast Engine (No boxes, no frames, pure floating Bangers words)
    - TopMenuGUI 3-Icon Setup with Responsive Hover Zoom and Hand Cursor
    - Vital HUD, Qi, Health, and Skin syncing
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

local TOAST_FONT = Enum.Font.Bangers
local UI_FONT    = Enum.Font.FredokaOne
local T          = UIAssets.Theme

local SELECT_MENU_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.MenuSelect) or "rbxassetid://101735926591481"
local HOVER_TWEEN_INFO = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DEFAULT_SCALE = 1.0
local HOVER_SCALE   = 1.10
local PRESS_SCALE   = 0.95

local hudScreenGui: ScreenGui?
local topMenuGui: ScreenGui?
local toastScreenGui: ScreenGui?
local topToastContainer: Frame?

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
local hotbarSlots: { [number]: Frame } = {}

local currentInventoryData: { [number]: any } = {}
local activeSkinId: string = "DefaultBronze"

local updateInventoryRemote: RemoteEvent
local updateCultivationRemote: RemoteEvent
local combatActionRemote: RemoteEvent

local function PlayMenuSelectAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = SELECT_MENU_SOUND_ID
	sound.Volume = 0.65
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.5)
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

-- =============================================================================
-- MASTER TOP-CENTER PURE TEXT TOAST ENGINE (Font: Bangers | No Boxes | Float In/Out)
-- =============================================================================
local function EnsureToastContainer(): Frame
	if topToastContainer and topToastContainer.Parent then
		return topToastContainer
	end

	if not toastScreenGui or not toastScreenGui.Parent then
		toastScreenGui = Instance.new("ScreenGui")
		toastScreenGui.Name = "AscendPureToastGui"
		toastScreenGui.ResetOnSpawn = false
		toastScreenGui.DisplayOrder = 100
		toastScreenGui.IgnoreGuiInset = true
		toastScreenGui.Parent = playerGui
	end

	local container = Instance.new("Frame")
	container.Name = "TopToastContainer"
	container.Size = UDim2.new(0, 500, 0, 200)
	container.Position = UDim2.new(0.5, 0, 0, 55)
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.BackgroundTransparency = 1
	container.Parent = toastScreenGui

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = container

	topToastContainer = container
	return container
end

function HUDController.ShowGlobalToast(message: string, toastType: string?, duration: number?)
	local container = EnsureToastContainer()
	local toastDuration = duration or 2.6
	local kind = toastType or "Success"

	-- Dynamic Color by category
	local textColor = Color3.fromRGB(255, 225, 120) -- Default Gold
	if kind == "Item" or kind == "Gather" then
		textColor = Color3.fromRGB(130, 245, 175) -- Spiritual Jade
	elseif kind == "Breakthrough" or kind == "Qi" then
		textColor = Color3.fromRGB(140, 220, 255) -- Celestial Cyan
	elseif kind == "Reward" or kind == "Sect" then
		textColor = Color3.fromRGB(255, 215, 80) -- Radiant Gold
	elseif kind == "Warning" or kind == "Error" then
		textColor = Color3.fromRGB(255, 95, 95) -- Crimson
	end

	-- Pure Text Label (No Background Frame)
	local textLbl = Instance.new("TextLabel")
	textLbl.Name = "PureToast"
	textLbl.Size = UDim2.new(1, 0, 0, 28)
	textLbl.Position = UDim2.new(0, 0, 0, -8) -- Start slightly offset for drop-in
	textLbl.BackgroundTransparency = 1
	textLbl.Font = TOAST_FONT
	textLbl.TextSize = 22
	textLbl.TextColor3 = textColor
	textLbl.TextTransparency = 1
	textLbl.Text = message
	textLbl.TextXAlignment = Enum.TextXAlignment.Center
	textLbl.TextYAlignment = Enum.TextYAlignment.Center
	textLbl.Parent = container

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(10, 10, 15)
	textStroke.Thickness = 1.8
	textStroke.Transparency = 1
	textStroke.Parent = textLbl

	-- 1. Fade-in and float down smoothly
	local fadeInInfo = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(textLbl, fadeInInfo, {
		TextTransparency = 0,
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()
	TweenService:Create(textStroke, fadeInInfo, {
		Transparency = 0
	}):Play()

	-- 2. Hold and then float up and fade out
	task.delay(toastDuration, function()
		if textLbl and textLbl.Parent then
			local fadeOutInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			local fadeText = TweenService:Create(textLbl, fadeOutInfo, {
				TextTransparency = 1,
				Position = UDim2.new(0, 0, 0, -14)
			})
			TweenService:Create(textStroke, fadeOutInfo, {
				Transparency = 1
			}):Play()
			fadeText:Play()

			fadeText.Completed:Connect(function()
				if textLbl and textLbl.Parent then
					textLbl:Destroy()
				end
			end)
		end
	end)
end

function HUDController.ShowEncouragingToast(message: string)
	HUDController.ShowGlobalToast(message, "Breakthrough", 3.0)
end

function HUDController.ShowItemToast(itemId: string, count: number, qualityText: any?)
	local itemDef = ItemConfig.GetItem(itemId)
	local itemName = if itemDef then itemDef.Name else itemId

	local toastText = string.format("+%d %s", count, itemName:upper())
	if qualityText ~= nil and tostring(qualityText) ~= "" then
		local cleanQuality = string.gsub(tostring(qualityText), " Quality", "")
		toastText = string.format("+%d [%s] %s", count, cleanQuality:upper(), itemName:upper())
	end

	HUDController.ShowGlobalToast(toastText, "Item", 2.6)
end

-- =============================================================================
-- CONTROLLER INITIALIZATION
-- =============================================================================
function HUDController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	EnsureToastContainer()
	HUDController.HookExplorerHUD()
	HUDController.HookTopMenu()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventoryData = inventoryData or {}
		HUDController.UpdateHotbar()
	end)

	updateCultivationRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) == "table" then
			if payload.Action == "BreakthroughRejected" and payload.Message then
				HUDController.ShowGlobalToast(payload.Message, "Warning", 3.2)
				return
			elseif payload.Action == "BreakthroughSuccess" then
				HUDController.ShowGlobalToast("BREAKTHROUGH ACHIEVED!", "Breakthrough", 3.8)
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

	print("[ASCEND] HUDController Initialized (Pure Floating Bangers Toast Active).")
end

-- =============================================================================
-- TOP MENU HOOK
-- =============================================================================
function HUDController.HookTopMenu()
	topMenuGui = (playerGui:FindFirstChild("TopMenuGUI") or playerGui:WaitForChild("TopMenuGUI", 10)) :: ScreenGui?
	if not topMenuGui then return end

	topMenuGui.Enabled = true

	local topMenu = (topMenuGui:FindFirstChild("TopMenu") or topMenuGui:WaitForChild("TopMenu", 5)) :: Frame?
	if not topMenu then return end

	topMenu.Visible = true
	for _, child in ipairs(topMenu:GetChildren()) do
		if child:IsA("GuiObject") then
			child.Visible = true
		end
	end

	local oldMeditate = topMenu:FindFirstChild("Tab_MEDITATE") 
		or topMenu:FindFirstChild("MeditateMenu") 
		or topMenu:FindFirstChild("MeditateButton")
	if oldMeditate then
		oldMeditate:Destroy()
	end

	local function BindMenuIconButton(menuNames: { string }, onClick: () -> ())
		local menuContainer: Instance? = nil
		for _, name in ipairs(menuNames) do
			menuContainer = topMenu:FindFirstChild(name)
			if menuContainer then break end
		end
		if not menuContainer or not menuContainer:IsA("GuiObject") then return end

		local guiObj = menuContainer :: GuiObject
		guiObj.Active = true
		guiObj.Selectable = true

		local uiScale = guiObj:FindFirstChildOfClass("UIScale")
		if not uiScale then
			uiScale = Instance.new("UIScale")
			uiScale.Scale = DEFAULT_SCALE
			uiScale.Parent = guiObj
		end

		guiObj.MouseEnter:Connect(function()
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = HOVER_SCALE }):Play()
		end)

		guiObj.MouseLeave:Connect(function()
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = DEFAULT_SCALE }):Play()
		end)

		local function trigger()
			PlayMenuSelectAudio()
			TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = PRESS_SCALE }):Play()
			task.delay(0.12, function()
				if uiScale and uiScale.Parent then
					TweenService:Create(uiScale, HOVER_TWEEN_INFO, { Scale = DEFAULT_SCALE }):Play()
				end
			end)
			onClick()
		end

		if guiObj:IsA("GuiButton") then
			guiObj.MouseButton1Click:Connect(trigger)
		else
			guiObj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					trigger()
				end
			end)
		end
	end

	BindMenuIconButton({ "Tab_BAG", "BagMenu", "BagButton", "PouchButton", "PouchMenu" }, function()
		local controllers = player.PlayerScripts:FindFirstChild("Controllers")
		if controllers then
			local invCtrl = controllers:FindFirstChild("InventoryController")
			if invCtrl then
				local req = require(invCtrl) :: any
				if req.Toggle then req.Toggle() end
			end
		end
	end)

	BindMenuIconButton({ "Tab_ARENA", "ArenaMenu", "ArenaButton" }, function()
		local controllers = player.PlayerScripts:FindFirstChild("Controllers")
		if controllers then
			local arenaCtrl = controllers:FindFirstChild("ArenaController")
			if arenaCtrl then
				local req = require(arenaCtrl) :: any
				if req.OpenRegistrationModal then
					req.OpenRegistrationModal()
				elseif req.ToggleModal then
					req.ToggleModal()
				end
			end
		end
	end)

	BindMenuIconButton({ "Tab_SETTINGS", "SettingsMenu", "SettingsButton" }, function()
		local settingsGui = playerGui:FindFirstChild("SettingsGui") or playerGui:FindFirstChild("GameSettingsGui")
		if settingsGui and settingsGui:IsA("ScreenGui") then
			settingsGui.Enabled = not settingsGui.Enabled
		else
			HUDController.ShowGlobalToast("SETTINGS MENU OPENED", "Success", 2.0)
		end
	end)
end

-- =============================================================================
-- VITAL HUD HOOK
-- =============================================================================
function HUDController.HookExplorerHUD()
	hudScreenGui = (playerGui:FindFirstChild("VitalHUDGui") or playerGui:FindFirstChild("AscendMainHUD")) :: ScreenGui?
	if not hudScreenGui then
		hudScreenGui = playerGui:FindFirstChildOfClass("ScreenGui")
	end
	if not hudScreenGui then return end

	hudScreenGui.Enabled = true

	vitalFrame = (hudScreenGui:FindFirstChild("VitalHUDFrame") or hudScreenGui:FindFirstChild("VitalHUDFrame", true)) :: ImageLabel?
	if vitalFrame then
		vitalFrame.Visible = true
	else
		return
	end

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
			hpBarText.Font = UI_FONT
			hpBarText.TextSize = 13
			hpBarText.Position = UDim2.new(0, 0, 0, 0)
			hpBarText.Size = UDim2.new(1, -18, 1, 0)
			hpBarText.TextXAlignment = Enum.TextXAlignment.Right
			hpBarText.TextYAlignment = Enum.TextYAlignment.Center
			hpBarText.ZIndex = 8
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
			qiBarText.Font = UI_FONT
			qiBarText.TextSize = 13
			qiBarText.Position = UDim2.new(0, 0, 0, 0)
			qiBarText.Size = UDim2.new(1, -18, 1, 0)
			qiBarText.TextXAlignment = Enum.TextXAlignment.Right
			qiBarText.TextYAlignment = Enum.TextYAlignment.Center
			qiBarText.ZIndex = 8
		end
	end

	hotbarFrame = FindChildCaseInsensitive(hudScreenGui, "HotbarFrame") :: Frame?
	if hotbarFrame then
		hotbarFrame.Visible = true
		for i = 1, 6 do
			local slot = FindChildCaseInsensitive(hotbarFrame, "HotbarSlot_" .. i) :: Frame?
			if slot then
				hotbarSlots[i] = slot
			end
		end
	end
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

return HUDController