--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Handles:
      1. Elevated Action & Sword Intent HUD
      2. Bottom Vital Cultivation Gauges (HP & Qi Progress Bars)
      3. Live 360° Cultivator Compass
      4. Bottom-Left Trigger & Book Menu Drawer (Pouch, Arena, Sect)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

local SkillBarController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = Workspace.CurrentCamera

local UI_FONT = Enum.Font.Bangers
local TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INTENT_BAR_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DRAWER_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

local screenGui: ScreenGui?
local swordIntentFill: Frame?
local swordIntentText: TextLabel?
local hpFillBar: Frame?
local hpValueText: TextLabel?
local qiFillBar: Frame?
local qiValueText: TextLabel?
local compassHeadingText: TextLabel?
local compassDegreeText: TextLabel?
local actionButtons: { [string]: { Button: ImageButton, Scale: UIScale, CooldownOverlay: Frame? } } = {}

local isMenuOpen = false
local menuDrawerFrame: Frame?
local menuDrawerScale: UIScale?
local combatActionRemote: RemoteEvent
local compassConnection: RBXScriptConnection?

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function FormatNum(num: number): string
	if CultivationConfig and CultivationConfig.FormatNumber then
		return CultivationConfig.FormatNumber(num)
	end
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

-- =============================================================================
-- PURGE LEGACY STUDIO TOP-RIGHT ICONS
-- =============================================================================
local function PurgeLegacyTopIcons()
	local function checkAndPurge(instance: Instance)
		if screenGui and instance:IsDescendantOf(screenGui) then return end
		local nameLower = instance.Name:lower()

		if nameLower == "topmenugui" or nameLower == "topmenu" or nameLower == "toprightmenu" or nameLower == "toprighticons" or nameLower == "toprightmenucluster" then
			instance:Destroy()
			return
		end

		if (nameLower:find("settings") or nameLower:find("arena") or nameLower:find("pouch")) 
			and (instance:IsA("ImageButton") or instance:IsA("ImageLabel") or instance:IsA("Frame") or instance:IsA("TextButton")) then
			if instance:IsA("GuiObject") then
				local vp = Camera.ViewportSize
				if instance.AbsolutePosition.X > vp.X * 0.65 and instance.AbsolutePosition.Y < vp.Y * 0.45 then
					instance.Visible = false
					instance:Destroy()
				end
			end
		end
	end

	for _, gui in ipairs(PlayerGui:GetChildren()) do
		if gui ~= screenGui and (gui:IsA("ScreenGui") or gui:IsA("BillboardGui")) then
			for _, child in ipairs(gui:GetDescendants()) do
				checkAndPurge(child)
			end
			gui.DescendantAdded:Connect(checkAndPurge)
		end
	end
end

local function TriggerM1()
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			local req = require(inputCtrl) :: any
			if req.TriggerM1 then
				req.TriggerM1()
				return
			end
		end
	end
	combatActionRemote:FireServer({ SkillKey = "M1", AimDirection = Vector3.new(0, 0, -1), Timestamp = os.clock() })
end

local function CreateActionSlot(parent: Instance, keybind: string, actionName: string, size: UDim2, layoutOrder: number, isTouch: boolean): (ImageButton, UIScale, Frame)
	local button = Instance.new("ImageButton")
	button.Name = "Slot_" .. keybind
	button.LayoutOrder = layoutOrder
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	button.BackgroundTransparency = 0.35
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Active = true
	button.Selectable = true
	button.ClipsDescendants = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, if isTouch then 6 else 8)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(160, 180, 205)
	stroke.Thickness = if isTouch then 1.2 else 1.5
	stroke.Transparency = 0.4
	stroke.Parent = button

	local uiScale = Instance.new("UIScale")
	uiScale.Scale = 1.0
	uiScale.Parent = button

	local cdOverlay = Instance.new("Frame")
	cdOverlay.Name = "CooldownOverlay"
	cdOverlay.Size = UDim2.new(1, 0, 0, 0)
	cdOverlay.Position = UDim2.new(0, 0, 1, 0)
	cdOverlay.AnchorPoint = Vector2.new(0, 1)
	cdOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	cdOverlay.BackgroundTransparency = 0.55
	cdOverlay.BorderSizePixel = 0
	cdOverlay.ZIndex = 4
	cdOverlay.Parent = button

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "KeyLabel"
	keyLabel.Size = UDim2.new(1, -6, 0, if isTouch then 14 else 18)
	keyLabel.Position = UDim2.new(0, if isTouch then 4 else 6, 0, 2)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = UI_FONT
	keyLabel.TextSize = if isTouch then 11 else 14
	keyLabel.TextColor3 = Color3.fromRGB(255, 220, 120)
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.ZIndex = 5
	keyLabel.Text = keybind
	keyLabel.Parent = button

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Color3.fromRGB(10, 10, 15)
	keyStroke.Thickness = 1
	keyStroke.Parent = keyLabel

	local actionLabel = Instance.new("TextLabel")
	actionLabel.Name = "ActionLabel"
	actionLabel.Size = UDim2.new(1, -4, 0, if isTouch then 18 else 22)
	actionLabel.Position = UDim2.new(0, 2, 0.5, if isTouch then -1 else 0)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Font = UI_FONT
	actionLabel.TextSize = if isTouch then 10 else 13
	actionLabel.TextColor3 = Color3.fromRGB(230, 238, 245)
	actionLabel.TextWrapped = true
	actionLabel.ZIndex = 5
	actionLabel.Text = actionName
	actionLabel.Parent = button

	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = Color3.fromRGB(10, 10, 15)
	actionStroke.Thickness = 1
	actionStroke.Parent = actionLabel

	button.MouseEnter:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO, { Scale = 1.08 }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = 0.1, Color = Color3.fromRGB(245, 215, 125) }):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO, { Scale = 1.0 }):Play()
		TweenService:Create(stroke, TWEEN_INFO, { Transparency = 0.4, Color = Color3.fromRGB(160, 180, 205) }):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO, { Scale = 0.92 }):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(uiScale, TWEEN_INFO, { Scale = 1.08 }):Play()
	end)

	return button, uiScale, cdOverlay
end

-- =============================================================================
-- BOTTOM-LEFT TRIGGER & BOOK MENU DRAWER
-- =============================================================================
local function BuildBottomLeftMenu(parentGui: ScreenGui)
	local menuRoot = Instance.new("Frame")
	menuRoot.Name = "BottomLeftMenuRoot"
	menuRoot.Size = UDim2.new(0, 80, 0, 80)
	menuRoot.Position = UDim2.new(0, 16, 1, -16)
	menuRoot.AnchorPoint = Vector2.new(0, 1)
	menuRoot.BackgroundTransparency = 1
	menuRoot.Parent = parentGui

	-- 1. Main Clickable Trigger Button (Single button always visible)
	local triggerBtn = Instance.new("TextButton")
	triggerBtn.Name = "MenuTriggerBtn"
	triggerBtn.Size = UDim2.new(0, 72, 0, 36)
	triggerBtn.Position = UDim2.new(0, 0, 1, 0)
	triggerBtn.AnchorPoint = Vector2.new(0, 1)
	triggerBtn.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	triggerBtn.BackgroundTransparency = 0.25
	triggerBtn.Text = "◈ MENU"
	triggerBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
	triggerBtn.Font = UI_FONT
	triggerBtn.TextSize = 13
	triggerBtn.AutoButtonColor = false
	triggerBtn.Parent = menuRoot

	local trigCorner = Instance.new("UICorner", triggerBtn)
	trigCorner.CornerRadius = UDim.new(0, 6)

	local trigStroke = Instance.new("UIStroke", triggerBtn)
	trigStroke.Color = Color3.fromRGB(212, 175, 55)
	trigStroke.Thickness = 1.2
	trigStroke.Transparency = 0.4

	-- 2. Expandable Drawer Container (Pops up above the trigger like a book opening)
	menuDrawerFrame = Instance.new("Frame")
	menuDrawerFrame.Name = "MenuDrawer"
	menuDrawerFrame.Size = UDim2.new(0, 210, 0, 42)
	menuDrawerFrame.Position = UDim2.new(0, 0, 1, -44)
	menuDrawerFrame.AnchorPoint = Vector2.new(0, 1)
	menuDrawerFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	menuDrawerFrame.BackgroundTransparency = 0.2
	menuDrawerFrame.BorderSizePixel = 0
	menuDrawerFrame.Visible = false
	menuDrawerFrame.Parent = menuRoot

	Instance.new("UICorner", menuDrawerFrame).CornerRadius = UDim.new(0, 6)
	local drawerStroke = Instance.new("UIStroke", menuDrawerFrame)
	drawerStroke.Color = Color3.fromRGB(212, 175, 55)
	drawerStroke.Thickness = 1.2
	drawerStroke.Transparency = 0.45

	menuDrawerScale = Instance.new("UIScale", menuDrawerFrame)
	menuDrawerScale.Scale = 0.8

	local drawerLayout = Instance.new("UIListLayout", menuDrawerFrame)
	drawerLayout.FillDirection = Enum.FillDirection.Horizontal
	drawerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	drawerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	drawerLayout.Padding = UDim.new(0, 6)

	local drawerItems = {
		{
			Id = "Pouch",
			Label = "POUCH",
			Callback = function()
				local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
				if controllers then
					local inv = controllers:FindFirstChild("InventoryController")
					if inv then
						local req = require(inv) :: any
						if req.Toggle then req.Toggle() end
					end
				end
			end,
		},
		{
			Id = "Arena",
			Label = "ARENA",
			Callback = function()
				local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
				if controllers then
					local arena = controllers:FindFirstChild("ArenaController")
					if arena then
						local req = require(arena) :: any
						if req.ToggleModal then req.ToggleModal() end
					end
				end
			end,
		},
		{
			Id = "Sect",
			Label = "SECT",
			Callback = function()
				local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
				if controllers then
					local sect = controllers:FindFirstChild("SectController")
					if sect then
						local req = require(sect) :: any
						if req.Open then req.Open() elseif req.Toggle then req.Toggle() end
					end
				end
			end,
		},
	}

	for _, item in ipairs(drawerItems) do
		local btn = Instance.new("TextButton")
		btn.Name = item.Id .. "Btn"
		btn.Size = UDim2.new(0, 62, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(20, 26, 36)
		btn.BackgroundTransparency = 0.3
		btn.Text = item.Label
		btn.TextColor3 = Color3.fromRGB(235, 240, 250)
		btn.Font = UI_FONT
		btn.TextSize = 12
		btn.AutoButtonColor = false
		btn.Parent = menuDrawerFrame

		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
		local bStroke = Instance.new("UIStroke", btn)
		bStroke.Color = Color3.fromRGB(180, 150, 60)
		bStroke.Thickness = 1
		bStroke.Transparency = 0.6

		btn.MouseEnter:Connect(function()
			TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(38, 48, 65) }):Play()
			btn.TextColor3 = Color3.fromRGB(255, 220, 100)
		end)

		btn.MouseLeave:Connect(function()
			TweenService:Create(btn, TWEEN_INFO, { BackgroundColor3 = Color3.fromRGB(20, 26, 36) }):Play()
			btn.TextColor3 = Color3.fromRGB(235, 240, 250)
		end)

		btn.MouseButton1Click:Connect(item.Callback)
	end

	-- Toggle Drawer on Click
	local function toggleDrawer()
		isMenuOpen = not isMenuOpen
		if not menuDrawerFrame or not menuDrawerScale then return end

		if isMenuOpen then
			menuDrawerFrame.Visible = true
			triggerBtn.Text = "✕ CLOSE"
			triggerBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
			TweenService:Create(menuDrawerScale, DRAWER_TWEEN, { Scale = 1.0 }):Play()
			TweenService:Create(menuDrawerFrame, DRAWER_TWEEN, { BackgroundTransparency = 0.2 }):Play()
		else
			triggerBtn.Text = "◈ MENU"
			triggerBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
			local tw = TweenService:Create(menuDrawerScale, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.8 })
			TweenService:Create(menuDrawerFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { BackgroundTransparency = 1 }):Play()
			tw:Play()
			tw.Completed:Connect(function()
				if not isMenuOpen and menuDrawerFrame then
					menuDrawerFrame.Visible = false
				end
			end)
		end
	end

	triggerBtn.MouseButton1Click:Connect(toggleDrawer)
end

local function BuildHUD()
	local existing = PlayerGui:FindFirstChild("BottomSkillHUD")
	if existing then existing:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "BottomSkillHUD"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.IgnoreGuiInset = false
	screenGui.Parent = PlayerGui

	local isTouch = IsTouchDevice()

	-- 1. Build Bottom-Left Book Trigger & Drawer
	BuildBottomLeftMenu(screenGui)

	-- 2. Purge old top-right Studio buttons
	PurgeLegacyTopIcons()

	-- =========================================================================
	-- 3. ELEVATED COMBAT CONTAINER (Sword Intent Bar + Keybind Slots)
	-- =========================================================================
	local combatContainer = Instance.new("Frame")
	combatContainer.Name = "ElevatedCombatContainer"
	combatContainer.Size = if isTouch then UDim2.new(0, 215, 0, 66) else UDim2.new(0, 335, 0, 88)
	combatContainer.Position = UDim2.new(0.5, 0, 1, if isTouch then -58 else -72)
	combatContainer.AnchorPoint = Vector2.new(0.5, 1)
	combatContainer.BackgroundTransparency = 1
	combatContainer.Parent = screenGui

	-- Sword Intent Bar
	local intentBg = Instance.new("Frame")
	intentBg.Name = "SwordIntentBackground"
	intentBg.Size = UDim2.new(1, 0, 0, if isTouch then 10 else 13)
	intentBg.Position = UDim2.new(0, 0, 0, 0)
	intentBg.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	intentBg.BackgroundTransparency = 0.2
	intentBg.BorderSizePixel = 0
	intentBg.ClipsDescendants = true
	intentBg.Parent = combatContainer

	local intentCorner = Instance.new("UICorner")
	intentCorner.CornerRadius = UDim.new(0, 4)
	intentCorner.Parent = intentBg

	local intentStroke = Instance.new("UIStroke")
	intentStroke.Color = Color3.fromRGB(215, 175, 75)
	intentStroke.Thickness = if isTouch then 1 else 1.4
	intentStroke.Transparency = 0.3
	intentStroke.Parent = intentBg

	swordIntentFill = Instance.new("Frame")
	swordIntentFill.Name = "Fill"
	swordIntentFill.Size = UDim2.new(1, 0, 1, 0)
	swordIntentFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	swordIntentFill.BorderSizePixel = 0
	swordIntentFill.Parent = intentBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = swordIntentFill

	local intentGradient = Instance.new("UIGradient")
	intentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 235, 120)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(240, 170, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(190, 80, 20)),
	})
	intentGradient.Parent = swordIntentFill

	swordIntentText = Instance.new("TextLabel")
	swordIntentText.Name = "IntentText"
	swordIntentText.Size = UDim2.new(1, 0, 1, 0)
	swordIntentText.BackgroundTransparency = 1
	swordIntentText.Font = UI_FONT
	swordIntentText.TextSize = if isTouch then 9 else 11.5
	swordIntentText.TextColor3 = Color3.fromRGB(255, 255, 255)
	swordIntentText.Text = "SWORD INTENT · 100%"
	swordIntentText.ZIndex = 3
	swordIntentText.Parent = intentBg

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(15, 15, 20)
	textStroke.Thickness = 1
	textStroke.Parent = swordIntentText

	-- Action Button Row
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.Size = UDim2.new(1, 0, 0, if isTouch then 50 else 64)
	buttonRow.Position = UDim2.new(0, 0, 0, if isTouch then 14 else 18)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = combatContainer

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, if isTouch then 6 else 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = buttonRow

	local slotSize = if isTouch then UDim2.new(0, 46, 0, 46) else UDim2.new(0, 58, 0, 58)

	if not isTouch then
		local m1Btn, m1Scale, m1Cd = CreateActionSlot(buttonRow, "M1", "STRIKE", slotSize, 1, false)
		actionButtons["M1"] = { Button = m1Btn, Scale = m1Scale, CooldownOverlay = m1Cd }
		m1Btn.MouseButton1Click:Connect(TriggerM1)
	end

	local rBtn, rScale, rCd = CreateActionSlot(buttonRow, "R", "DRAW", slotSize, 2, isTouch)
	local vBtn, vScale, vCd = CreateActionSlot(buttonRow, "V", "FLIGHT", slotSize, 3, isTouch)
	local bBtn, bScale, bCd = CreateActionSlot(buttonRow, "B", "BREAK", slotSize, 4, isTouch)
	local mBtn, mScale, mCd = CreateActionSlot(buttonRow, "M", "MEDITATE", slotSize, 5, isTouch)

	actionButtons["R"] = { Button = rBtn, Scale = rScale, CooldownOverlay = rCd }
	actionButtons["V"] = { Button = vBtn, Scale = vScale, CooldownOverlay = vCd }
	actionButtons["B"] = { Button = bBtn, Scale = bScale, CooldownOverlay = bCd }
	actionButtons["M"] = { Button = mBtn, Scale = mScale, CooldownOverlay = mCd }

	rBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ ToggleSheath = true })
	end)

	vBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ ToggleFlight = true })
	end)

	bBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ RequestBreakthrough = true })
	end)

	mBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ ToggleMeditation = true })
	end)

	-- =========================================================================
	-- 4. BOTTOM VITAL CULTIVATION GAUGES (HP & QI PROGRESS BARS)
	-- =========================================================================
	local vitalsContainer = Instance.new("Frame")
	vitalsContainer.Name = "BottomVitalsContainer"
	vitalsContainer.Size = if isTouch then UDim2.new(0, 260, 0, 42) else UDim2.new(0, 390, 0, 48)
	vitalsContainer.Position = UDim2.new(0.5, 0, 1, -10)
	vitalsContainer.AnchorPoint = Vector2.new(0.5, 1)
	vitalsContainer.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	vitalsContainer.BackgroundTransparency = 0.25
	vitalsContainer.BorderSizePixel = 0
	vitalsContainer.Parent = screenGui

	local vitalsCorner = Instance.new("UICorner")
	vitalsCorner.CornerRadius = UDim.new(0, 6)
	vitalsCorner.Parent = vitalsContainer

	local vitalsStroke = Instance.new("UIStroke")
	vitalsStroke.Color = Color3.fromRGB(212, 175, 55)
	vitalsStroke.Thickness = 1.2
	vitalsStroke.Transparency = 0.45
	vitalsStroke.Parent = vitalsContainer

	-- HP Gauge (Emerald Gradient)
	local hpTrack = Instance.new("Frame")
	hpTrack.Name = "HPTrack"
	hpTrack.Size = UDim2.new(1, -16, 0, if isTouch then 14 else 17)
	hpTrack.Position = UDim2.new(0, 8, 0, 5)
	hpTrack.BackgroundColor3 = Color3.fromRGB(20, 26, 34)
	hpTrack.BorderSizePixel = 0
	hpTrack.ClipsDescendants = true
	hpTrack.Parent = vitalsContainer
	Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(0, 4)

	hpFillBar = Instance.new("Frame")
	hpFillBar.Name = "HPFill"
	hpFillBar.Size = UDim2.new(1, 0, 1, 0)
	hpFillBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hpFillBar.BorderSizePixel = 0
	hpFillBar.Parent = hpTrack
	Instance.new("UICorner", hpFillBar).CornerRadius = UDim.new(0, 4)

	local hpGrad = Instance.new("UIGradient")
	hpGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 130, 76)),
	})
	hpGrad.Parent = hpFillBar

	hpValueText = Instance.new("TextLabel")
	hpValueText.Name = "HPValue"
	hpValueText.Size = UDim2.new(1, 0, 1, 0)
	hpValueText.BackgroundTransparency = 1
	hpValueText.Font = UI_FONT
	hpValueText.TextSize = if isTouch then 9.5 else 12
	hpValueText.TextColor3 = Color3.fromRGB(240, 255, 240)
	hpValueText.Text = "HP  100% (100 / 100)"
	hpValueText.ZIndex = 3
	hpValueText.Parent = hpTrack
	local hpTextStroke = Instance.new("UIStroke", hpValueText)
	hpTextStroke.Color = Color3.fromRGB(10, 10, 15)
	hpTextStroke.Thickness = 1

	-- Qi Gauge (Celestial Cyan Gradient)
	local qiTrack = Instance.new("Frame")
	qiTrack.Name = "QiTrack"
	qiTrack.Size = UDim2.new(1, -16, 0, if isTouch then 14 else 17)
	qiTrack.Position = UDim2.new(0, 8, 0, if isTouch then 22 else 25)
	qiTrack.BackgroundColor3 = Color3.fromRGB(20, 26, 34)
	qiTrack.BorderSizePixel = 0
	qiTrack.ClipsDescendants = true
	qiTrack.Parent = vitalsContainer
	Instance.new("UICorner", qiTrack).CornerRadius = UDim.new(0, 4)

	qiFillBar = Instance.new("Frame")
	qiFillBar.Name = "QiFill"
	qiFillBar.Size = UDim2.new(1, 0, 1, 0)
	qiFillBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	qiFillBar.BorderSizePixel = 0
	qiFillBar.Parent = qiTrack
	Instance.new("UICorner", qiFillBar).CornerRadius = UDim.new(0, 4)

	local qiGrad = Instance.new("UIGradient")
	qiGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 195, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 110, 210)),
	})
	qiGrad.Parent = qiFillBar

	qiValueText = Instance.new("TextLabel")
	qiValueText.Name = "QiValue"
	qiValueText.Size = UDim2.new(1, 0, 1, 0)
	qiValueText.BackgroundTransparency = 1
	qiValueText.Font = UI_FONT
	qiValueText.TextSize = if isTouch then 9.5 else 12
	qiValueText.TextColor3 = Color3.fromRGB(220, 245, 255)
	qiValueText.Text = "QI  100% (100 / 100)"
	qiValueText.ZIndex = 3
	qiValueText.Parent = qiTrack
	local qiTextStroke = Instance.new("UIStroke", qiValueText)
	qiTextStroke.Color = Color3.fromRGB(10, 10, 15)
	qiTextStroke.Thickness = 1

	-- =========================================================================
	-- 5. SIDE CULTIVATOR COMPASS
	-- =========================================================================
	local compassFrame = Instance.new("Frame")
	compassFrame.Name = "SideCompass"
	compassFrame.Size = UDim2.new(0, 48, 0, 48)
	compassFrame.Position = UDim2.new(1, 10, 0, 0)
	compassFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	compassFrame.BackgroundTransparency = 0.25
	compassFrame.BorderSizePixel = 0
	compassFrame.Parent = vitalsContainer

	local compCorner = Instance.new("UICorner")
	compCorner.CornerRadius = UDim.new(1, 0)
	compCorner.Parent = compassFrame

	local compStroke = Instance.new("UIStroke")
	compStroke.Color = Color3.fromRGB(212, 175, 55)
	compStroke.Thickness = 1.2
	compStroke.Transparency = 0.4
	compStroke.Parent = compassFrame

	compassHeadingText = Instance.new("TextLabel")
	compassHeadingText.Name = "Heading"
	compassHeadingText.Size = UDim2.new(1, 0, 0.52, 0)
	compassHeadingText.Position = UDim2.new(0, 0, 0.08, 0)
	compassHeadingText.BackgroundTransparency = 1
	compassHeadingText.Font = UI_FONT
	compassHeadingText.TextSize = 14
	compassHeadingText.TextColor3 = Color3.fromRGB(255, 220, 100)
	compassHeadingText.Text = "N"
	compassHeadingText.Parent = compassFrame

	compassDegreeText = Instance.new("TextLabel")
	compassDegreeText.Name = "Degrees"
	compassDegreeText.Size = UDim2.new(1, 0, 0.35, 0)
	compassDegreeText.Position = UDim2.new(0, 0, 0.55, 0)
	compassDegreeText.BackgroundTransparency = 1
	compassDegreeText.Font = Enum.Font.GothamBold
	compassDegreeText.TextSize = 9
	compassDegreeText.TextColor3 = Color3.fromRGB(180, 190, 205)
	compassDegreeText.Text = "0°"
	compassDegreeText.Parent = compassFrame

	if compassConnection then compassConnection:Disconnect() end
	local cardinals = { "N", "NE", "E", "SE", "S", "SW", "W", "NW" }
	compassConnection = RunService.RenderStepped:Connect(function()
		local look = Camera.CFrame.LookVector
		local angle = math.deg(math.atan2(-look.X, -look.Z))
		if angle < 0 then angle = angle + 360 end
		local idx = math.floor((angle + 22.5) / 45) % 8 + 1
		if compassHeadingText then compassHeadingText.Text = cardinals[idx] end
		if compassDegreeText then compassDegreeText.Text = string.format("%d°", math.floor(angle)) end
	end)
end

function SkillBarController.UpdateVitals(curHp: number, maxHp: number, curQi: number, maxQi: number)
	if hpFillBar and hpValueText then
		local hMax = math.max(1, maxHp or 100)
		local hCur = math.clamp(curHp or 0, 0, hMax)
		local hRatio = hCur / hMax
		TweenService:Create(hpFillBar, INTENT_BAR_TWEEN, { Size = UDim2.new(hRatio, 0, 1, 0) }):Play()
		hpValueText.Text = string.format("HP  %s / %s (%d%%)", FormatNum(hCur), FormatNum(hMax), math.floor(hRatio * 100))
	end

	if qiFillBar and qiValueText then
		local qMax = math.max(1, maxQi or 100)
		local qCur = math.clamp(curQi or 0, 0, qMax)
		local qRatio = qCur / qMax
		TweenService:Create(qiFillBar, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play()
		qiValueText.Text = string.format("QI  %s / %s (%d%%)", FormatNum(qCur), FormatNum(qMax), math.floor(qRatio * 100))
	end
end

function SkillBarController.TriggerCooldown(actionKey: string, customDuration: number?)
	local slot = actionButtons[actionKey]
	if not slot or not slot.CooldownOverlay then return end

	local duration = customDuration or (if actionKey == "M1" then 0.38 elseif actionKey == "Dash" or actionKey == "Shift" then 3.0 else 1.0)
	local overlay = slot.CooldownOverlay
	overlay.Size = UDim2.new(1, 0, 1, 0)

	local tween = TweenService:Create(overlay, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0)
	})
	tween:Play()
end

function SkillBarController.UpdateSwordIntent(current: number, max: number)
	if not swordIntentFill or not swordIntentText then return end
	local maxVal = math.max(1, max or 100)
	local curVal = math.clamp(current or 0, 0, maxVal)
	local ratio = curVal / maxVal

	TweenService:Create(swordIntentFill, INTENT_BAR_TWEEN, {
		Size = UDim2.new(ratio, 0, 1, 0)
	}):Play()

	swordIntentText.Text = string.format("SWORD INTENT · %d%%", math.floor(ratio * 100))
end

local function BindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

	local function checkVitals()
		local curHp = if humanoid then humanoid.Health else (character:GetAttribute("Health") or 100)
		local maxHp = if humanoid then humanoid.MaxHealth else (character:GetAttribute("MaxHealth") or 100)
		local curQi = character:GetAttribute("Qi") or LocalPlayer:GetAttribute("Qi") or 100
		local maxQi = character:GetAttribute("MaxQi") or LocalPlayer:GetAttribute("MaxQi") or 100

		SkillBarController.UpdateVitals(tonumber(curHp) or 100, tonumber(maxHp) or 100, tonumber(curQi) or 100, tonumber(maxQi) or 100)
	end

	local function checkIntent()
		local intent = character:GetAttribute("SwordIntent") or LocalPlayer:GetAttribute("SwordIntent") or 100
		local maxIntent = character:GetAttribute("MaxSwordIntent") or LocalPlayer:GetAttribute("MaxSwordIntent") or 100
		SkillBarController.UpdateSwordIntent(tonumber(intent) or 100, tonumber(maxIntent) or 100)
	end

	local function checkDrawState()
		local rData = actionButtons["R"]
		if rData and rData.Button then
			local actionLbl = rData.Button:FindFirstChild("ActionLabel") :: TextLabel?
			local isDrawn = character:GetAttribute("WeaponDrawn") == true
			if actionLbl then
				actionLbl.Text = if isDrawn then "SHEATH" else "DRAW"
			end
		end
	end

	local function checkMeditateState()
		local mData = actionButtons["M"]
		if mData and mData.Button then
			local actionLbl = mData.Button:FindFirstChild("ActionLabel") :: TextLabel?
			local isMeditating = character:GetAttribute("IsMeditating") == true
			if actionLbl then
				actionLbl.Text = if isMeditating then "STAND" else "MEDITATE"
			end
		end
	end

	if humanoid then
		humanoid:GetPropertyChangedSignal("Health"):Connect(checkVitals)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(checkVitals)
	end

	character:GetAttributeChangedSignal("Qi"):Connect(checkVitals)
	character:GetAttributeChangedSignal("MaxQi"):Connect(checkVitals)
	LocalPlayer:GetAttributeChangedSignal("Qi"):Connect(checkVitals)
	LocalPlayer:GetAttributeChangedSignal("MaxQi"):Connect(checkVitals)

	character:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)
	character:GetAttributeChangedSignal("WeaponDrawn"):Connect(checkDrawState)
	character:GetAttributeChangedSignal("IsMeditating"):Connect(checkMeditateState)
	LocalPlayer:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)

	checkVitals()
	checkIntent()
	checkDrawState()
	checkMeditateState()
end

function SkillBarController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	BuildHUD()

	if LocalPlayer.Character then
		BindCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(BindCharacter)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local keyName = input.KeyCode.Name
		if actionButtons[keyName] then
			TweenService:Create(actionButtons[keyName].Scale, TWEEN_INFO, { Scale = 0.92 }):Play()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, _)
		local keyName = input.KeyCode.Name
		if actionButtons[keyName] then
			TweenService:Create(actionButtons[keyName].Scale, TWEEN_INFO, { Scale = 1.0 }):Play()
		end
	end)

	print("[ASCEND] SkillBarController Initialized (Bottom-Left Menu Drawer Active).")
end

return SkillBarController