--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Bottom-Center Action HUD & Sword Intent Engine with Non-Overlapping Mobile Layout:
    - Top: Proportional Sword Intent Bar
    - PC Center-Bottom: [M1] Strike | [R] Draw/Sheath | [V] Flight | [B] Breakthrough | [M] Meditate
    - Mobile Layout: Ergonomic Center-Bottom Utility (R, V, B, M) + Clear-of-Jump Combat Cluster (M1, Dash)
    - Full Cooldown Animation Support for InputController integration
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local SkillBarController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UI_FONT = Enum.Font.FredokaOne
local TWEEN_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INTENT_BAR_TWEEN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local screenGui: ScreenGui?
local swordIntentFill: Frame?
local swordIntentText: TextLabel?
local actionButtons: { [string]: { Button: ImageButton, Scale: UIScale, CooldownOverlay: Frame? } } = {}

local combatActionRemote: RemoteEvent

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

-- Safely trigger M1 attack via InputController
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

-- Safely trigger Dash via InputController
local function TriggerDash()
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			local req = require(inputCtrl) :: any
			if req.TriggerDash then
				req.TriggerDash()
				return
			end
		end
	end
	combatActionRemote:FireServer({ SkillKey = "Shift", AimDirection = Vector3.new(0, 0, -1), Timestamp = os.clock() })
end

local function CreateActionSlot(parent: Instance, keybind: string, actionName: string, size: UDim2, layoutOrder: number): (ImageButton, UIScale, Frame)
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
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(160, 180, 205)
	stroke.Thickness = 1.2
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
	keyLabel.Size = UDim2.new(1, -4, 0, 12)
	keyLabel.Position = UDim2.new(0, 4, 0, 2)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = UI_FONT
	keyLabel.TextSize = 9.5
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
	actionLabel.Size = UDim2.new(1, -2, 0, 16)
	actionLabel.Position = UDim2.new(0, 1, 0.5, -1)
	actionLabel.BackgroundTransparency = 1
	actionLabel.Font = UI_FONT
	actionLabel.TextSize = 8.5
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

	-- 1. Center-Bottom Container
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = if isTouch then UDim2.new(0, 205, 0, 64) else UDim2.new(0, 255, 0, 68)
	container.Position = UDim2.new(0.5, 0, 1, -12)
	container.AnchorPoint = Vector2.new(0.5, 1)
	container.BackgroundTransparency = 1
	container.Parent = screenGui

	-- Sleek Sword Intent Bar
	local intentBg = Instance.new("Frame")
	intentBg.Name = "SwordIntentBackground"
	intentBg.Size = UDim2.new(1, 0, 0, 9)
	intentBg.Position = UDim2.new(0, 0, 0, 0)
	intentBg.BackgroundColor3 = Color3.fromRGB(12, 16, 22)
	intentBg.BackgroundTransparency = 0.2
	intentBg.BorderSizePixel = 0
	intentBg.ClipsDescendants = true
	intentBg.Parent = container

	local intentCorner = Instance.new("UICorner")
	intentCorner.CornerRadius = UDim.new(0, 3)
	intentCorner.Parent = intentBg

	local intentStroke = Instance.new("UIStroke")
	intentStroke.Color = Color3.fromRGB(215, 175, 75)
	intentStroke.Thickness = 1
	intentStroke.Transparency = 0.3
	intentStroke.Parent = intentBg

	swordIntentFill = Instance.new("Frame")
	swordIntentFill.Name = "Fill"
	swordIntentFill.Size = UDim2.new(1, 0, 1, 0)
	swordIntentFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	swordIntentFill.BorderSizePixel = 0
	swordIntentFill.Parent = intentBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 3)
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
	swordIntentText.TextSize = 7.5
	swordIntentText.TextColor3 = Color3.fromRGB(255, 255, 255)
	swordIntentText.Text = "SWORD INTENT · 100%"
	swordIntentText.ZIndex = 3
	swordIntentText.Parent = intentBg

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(15, 15, 20)
	textStroke.Thickness = 1
	textStroke.Parent = swordIntentText

	-- Action Buttons Row
	local buttonRow = Instance.new("Frame")
	buttonRow.Name = "ButtonRow"
	buttonRow.Size = UDim2.new(1, 0, 0, 48)
	buttonRow.Position = UDim2.new(0, 0, 0, 14)
	buttonRow.BackgroundTransparency = 1
	buttonRow.Parent = container

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 6)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = buttonRow

	local slotSize = if isTouch then UDim2.new(0, 44, 0, 44) else UDim2.new(0, 46, 0, 46)

	-- On PC: M1 slot is included in center row
	if not isTouch then
		local m1Btn, m1Scale, m1Cd = CreateActionSlot(buttonRow, "M1", "STRIKE", slotSize, 1)
		actionButtons["M1"] = { Button = m1Btn, Scale = m1Scale, CooldownOverlay = m1Cd }
		m1Btn.MouseButton1Click:Connect(TriggerM1)
	end

	-- Center Utilities: R, V, B, M
	local rBtn, rScale, rCd = CreateActionSlot(buttonRow, "R", "DRAW", slotSize, 2)
	local vBtn, vScale, vCd = CreateActionSlot(buttonRow, "V", "FLIGHT", slotSize, 3)
	local bBtn, bScale, bCd = CreateActionSlot(buttonRow, "B", "BREAK", slotSize, 4)
	local mBtn, mScale, mCd = CreateActionSlot(buttonRow, "M", "MEDITATE", slotSize, 5)

	actionButtons["R"] = { Button = rBtn, Scale = rScale, CooldownOverlay = rCd }
	actionButtons["V"] = { Button = vBtn, Scale = vScale, CooldownOverlay = vCd }
	actionButtons["B"] = { Button = bBtn, Scale = bScale, CooldownOverlay = bCd }
	actionButtons["M"] = { Button = mBtn, Scale = mScale, CooldownOverlay = mCd }

	rBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ ToggleSheath = true })
	end)

	vBtn.MouseButton1Click:Connect(function()
		print("[ASCEND] Flying Sword Flight Engine: Pending activation.")
	end)

	bBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ RequestBreakthrough = true })
	end)

	mBtn.MouseButton1Click:Connect(function()
		combatActionRemote:FireServer({ ToggleMeditation = true })
	end)

	-- 2. Mobile Combat Cluster (Carefully positioned to avoid Roblox Jump Button)
	if isTouch then
		local mobileCluster = Instance.new("Frame")
		mobileCluster.Name = "MobileCombatCluster"
		mobileCluster.Size = UDim2.new(0, 220, 0, 180)
		mobileCluster.Position = UDim2.new(1, -20, 1, -20)
		mobileCluster.AnchorPoint = Vector2.new(1, 1)
		mobileCluster.BackgroundTransparency = 1
		mobileCluster.Parent = screenGui

		-- Strike Button (Positioned to the left of the Jump Button area)
		local m1Mobile = Instance.new("ImageButton")
		m1Mobile.Name = "Mobile_M1"
		m1Mobile.Size = UDim2.new(0, 62, 0, 62)
		m1Mobile.Position = UDim2.new(1, -115, 1, -15) -- Clears the Jump button completely
		m1Mobile.AnchorPoint = Vector2.new(1, 1)
		m1Mobile.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
		m1Mobile.BackgroundTransparency = 0.2
		m1Mobile.ClipsDescendants = true
		m1Mobile.Active = true
		m1Mobile.Parent = mobileCluster

		local m1Corner = Instance.new("UICorner")
		m1Corner.CornerRadius = UDim.new(1, 0)
		m1Corner.Parent = m1Mobile

		local m1Stroke = Instance.new("UIStroke")
		m1Stroke.Color = Color3.fromRGB(245, 215, 125)
		m1Stroke.Thickness = 2
		m1Stroke.Parent = m1Mobile

		local m1Scale = Instance.new("UIScale")
		m1Scale.Parent = m1Mobile

		local m1Cd = Instance.new("Frame")
		m1Cd.Name = "CooldownOverlay"
		m1Cd.Size = UDim2.new(1, 0, 0, 0)
		m1Cd.Position = UDim2.new(0, 0, 1, 0)
		m1Cd.AnchorPoint = Vector2.new(0, 1)
		m1Cd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		m1Cd.BackgroundTransparency = 0.55
		m1Cd.BorderSizePixel = 0
		m1Cd.ZIndex = 4
		m1Cd.Parent = m1Mobile

		actionButtons["M1"] = { Button = m1Mobile, Scale = m1Scale, CooldownOverlay = m1Cd }

		local m1Text = Instance.new("TextLabel")
		m1Text.Size = UDim2.new(1, 0, 1, 0)
		m1Text.BackgroundTransparency = 1
		m1Text.Font = UI_FONT
		m1Text.TextSize = 12
		m1Text.TextColor3 = Color3.fromRGB(255, 255, 255)
		m1Text.ZIndex = 5
		m1Text.Text = "⚔️\nSTRIKE"
		m1Text.Parent = m1Mobile

		m1Mobile.MouseButton1Down:Connect(function()
			TweenService:Create(m1Scale, TWEEN_INFO, { Scale = 0.92 }):Play()
		end)
		m1Mobile.MouseButton1Up:Connect(function()
			TweenService:Create(m1Scale, TWEEN_INFO, { Scale = 1.0 }):Play()
		end)
		m1Mobile.MouseButton1Click:Connect(TriggerM1)

		-- Dash Button (Positioned above Strike)
		local dashBtn = Instance.new("ImageButton")
		dashBtn.Name = "Mobile_Dash"
		dashBtn.Size = UDim2.new(0, 48, 0, 48)
		dashBtn.Position = UDim2.new(1, -122, 1, -88)
		dashBtn.AnchorPoint = Vector2.new(1, 1)
		dashBtn.BackgroundColor3 = Color3.fromRGB(18, 24, 34)
		dashBtn.BackgroundTransparency = 0.25
		dashBtn.ClipsDescendants = true
		dashBtn.Active = true
		dashBtn.Parent = mobileCluster

		local dashCorner = Instance.new("UICorner")
		dashCorner.CornerRadius = UDim.new(1, 0)
		dashCorner.Parent = dashBtn

		local dashStroke = Instance.new("UIStroke")
		dashStroke.Color = Color3.fromRGB(140, 200, 255)
		dashStroke.Thickness = 1.5
		dashStroke.Parent = dashBtn

		local dashScale = Instance.new("UIScale")
		dashScale.Parent = dashBtn

		local dashCd = Instance.new("Frame")
		dashCd.Name = "CooldownOverlay"
		dashCd.Size = UDim2.new(1, 0, 0, 0)
		dashCd.Position = UDim2.new(0, 0, 1, 0)
		dashCd.AnchorPoint = Vector2.new(0, 1)
		dashCd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		dashCd.BackgroundTransparency = 0.55
		dashCd.BorderSizePixel = 0
		dashCd.ZIndex = 4
		dashCd.Parent = dashBtn

		actionButtons["Dash"] = { Button = dashBtn, Scale = dashScale, CooldownOverlay = dashCd }
		actionButtons["Shift"] = actionButtons["Dash"]

		local dashText = Instance.new("TextLabel")
		dashText.Size = UDim2.new(1, 0, 1, 0)
		dashText.BackgroundTransparency = 1
		dashText.Font = UI_FONT
		dashText.TextSize = 10
		dashText.TextColor3 = Color3.fromRGB(255, 255, 255)
		dashText.ZIndex = 5
		dashText.Text = "💨\nDASH"
		dashText.Parent = dashBtn

		dashBtn.MouseButton1Down:Connect(function()
			TweenService:Create(dashScale, TWEEN_INFO, { Scale = 0.92 }):Play()
		end)
		dashBtn.MouseButton1Up:Connect(function()
			TweenService:Create(dashScale, TWEEN_INFO, { Scale = 1.0 }):Play()
		end)
		dashBtn.MouseButton1Click:Connect(TriggerDash)
	end
end

-- Triggers cooldown animation (Called directly by InputController)
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
	local function checkIntent()
		local intent = character:GetAttribute("SwordIntent") 
			or LocalPlayer:GetAttribute("SwordIntent") 
			or 100
		local maxIntent = character:GetAttribute("MaxSwordIntent") 
			or LocalPlayer:GetAttribute("MaxSwordIntent") 
			or 100
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

	character:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)
	character:GetAttributeChangedSignal("WeaponDrawn"):Connect(checkDrawState)
	character:GetAttributeChangedSignal("IsMeditating"):Connect(checkMeditateState)
	LocalPlayer:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)

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

	-- Desktop Keybind Visual Feedback
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

	print("[ASCEND] SkillBarController Initialized (Mobile Attack/Dash Linked & Cooldowns Enabled).")
end

return SkillBarController