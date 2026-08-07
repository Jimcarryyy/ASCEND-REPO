--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Master Client HUD Controller for ASCEND.
    Light-Mode Flat 2D UI with 100% type-safe strict Luau signatures.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HUDController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- BOLD COMPACT FONT
local UI_FONT = Enum.Font.FredokaOne

-- LIGHT-MODE FLAT 2D PALETTE
local COLOR_LIGHT_MAIN     = Color3.fromRGB(248, 250, 249) -- #F8FAF9 Crisp Light Panel
local COLOR_LIGHT_PANEL    = Color3.fromRGB(241, 245, 249) -- #F1F5F9 Soft Slate Card/Slot Background
local COLOR_LIGHT_BORDER   = Color3.fromRGB(203, 213, 225) -- #CBD5E1 Muted Slate Border

local COLOR_TEXT_MAIN      = Color3.fromRGB(15, 23, 42)    -- #0F172A Deep Charcoal Text
local COLOR_TEXT_SUB       = Color3.fromRGB(100, 116, 139)  -- #64748B Muted Subtext
local COLOR_AZURE          = Color3.fromRGB(59, 130, 246)   -- #3B82F6 Sapphire Blue Qi Fill
local COLOR_HP_GREEN       = Color3.fromRGB(16, 185, 129)  -- #10B981 Emerald Green HP Fill
local COLOR_ACTION_GOLD    = Color3.fromRGB(217, 119, 6)   -- #D97706 Warm Amber Gold
local COLOR_DANGER_RED     = Color3.fromRGB(225, 29, 72)   -- #E11D48 Carmine Red

local hudGui: ScreenGui? = nil
local mainHudPanel: Frame? = nil

-- Vitality & Cultivation Meters
local hpFillBar: Frame? = nil
local hpTextLabel: TextLabel? = nil
local cultivationFillBar: Frame? = nil
local realmTitleLabel: TextLabel? = nil
local qiProgressLabel: TextLabel? = nil

-- Action Prompt
local actionHotkeyPrompt: TextLabel? = nil

-- Skill Hotbar Slots
local activeSlots: { [string]: Frame } = {}
local activeCooldowns: { [string]: thread } = {}

function HUDController.Init()
	local foundGui = playerGui:WaitForChild("HUDGui", 10)
	if foundGui and foundGui:IsA("ScreenGui") then
		hudGui = foundGui :: ScreenGui
	else
		local newGui = Instance.new("ScreenGui")
		newGui.Name = "HUDGui"
		newGui.ResetOnSpawn = false
		newGui.DisplayOrder = 10
		newGui.Parent = playerGui
		hudGui = newGui
	end

	HUDController.BuildSharpPanelHUD()

	-- Connect Health Updates
	local character = player.Character or player.CharacterAdded:Wait()
	HUDController.HookCharacterEvents(character)
	player.CharacterAdded:Connect(HUDController.HookCharacterEvents)

	-- Connect Cultivation Updates
	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		HUDController.UpdateCultivationHUD(data)
	end)

	-- Connect Skill Cooldowns & Weapon State
	local syncCooldownRemote = RemoteEvents.GetRemote("SyncCooldown")
	syncCooldownRemote.OnClientEvent:Connect(function(skillKey: string, cooldownDuration: number)
		HUDController.TriggerCooldown(skillKey, cooldownDuration)
	end)

	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")
	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string, skillIcons: { [string]: string })
		for key, iconAsset in pairs(skillIcons) do
			local slot = activeSlots[key]
			if slot then
				local iconLabel = slot:FindFirstChild("Icon")
				if iconLabel and iconLabel:IsA("ImageLabel") then
					iconLabel.Image = iconAsset or ""
				end
			end
		end
	end)

	print("[ASCEND] Light-Mode Flat 2D HUD Controller Initialized.")
end

function HUDController.HookCharacterEvents(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid or not humanoid:IsA("Humanoid") then return end
	local hum: Humanoid = humanoid :: Humanoid

	local function updateHp()
		if not hpFillBar or not hpTextLabel then return end
		local fill: Frame = hpFillBar :: Frame
		local textLbl: TextLabel = hpTextLabel :: TextLabel

		local pct = math.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
		
		TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(pct, 0, 1, 0),
		}):Play()

		textLbl.Text = string.format("%s / %s HP", CultivationConfig.FormatNumber(hum.Health), CultivationConfig.FormatNumber(hum.MaxHealth))
	end

	hum.HealthChanged:Connect(updateHp)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(updateHp)
	updateHp()
end

function HUDController.BuildSharpPanelHUD()
	if not hudGui then return end
	local currentGui: ScreenGui = hudGui :: ScreenGui

	local oldMain = currentGui:FindFirstChild("MainHUDPanel")
	if oldMain then oldMain:Destroy() end

	-- Enclosing Main Panel
	local panel = Instance.new("Frame")
	panel.Name = "MainHUDPanel"
	panel.Size = UDim2.new(0, 500, 0, 185)
	panel.Position = UDim2.new(0.5, -250, 1, -200)
	panel.BackgroundColor3 = COLOR_LIGHT_MAIN
	panel.BorderSizePixel = 0
	panel.Parent = currentGui
	mainHudPanel = panel

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = COLOR_LIGHT_BORDER
	pStroke.Thickness = 1.5
	pStroke.Parent = panel

	----------------------------------------------------------------------------
	-- 1. THICK HP BAR BOX (Height: 28px)
	----------------------------------------------------------------------------
	local hpBox = Instance.new("Frame")
	hpBox.Name = "HpBox"
	hpBox.Size = UDim2.new(1, -24, 0, 28)
	hpBox.Position = UDim2.new(0, 12, 0, 12)
	hpBox.BackgroundColor3 = COLOR_LIGHT_PANEL
	hpBox.BorderSizePixel = 0
	hpBox.Parent = panel

	local hpBoxStroke = Instance.new("UIStroke")
	hpBoxStroke.Color = COLOR_LIGHT_BORDER
	hpBoxStroke.Thickness = 1
	hpBoxStroke.Parent = hpBox

	local hpBg = Instance.new("Frame")
	hpBg.Name = "HpBg"
	hpBg.Size = UDim2.new(1, 0, 1, 0)
	hpBg.BackgroundColor3 = COLOR_LIGHT_PANEL
	hpBg.BorderSizePixel = 0
	hpBg.Parent = hpBox

	local newHpFill = Instance.new("Frame")
	newHpFill.Name = "HpFill"
	newHpFill.Size = UDim2.new(1, 0, 1, 0)
	newHpFill.BackgroundColor3 = COLOR_HP_GREEN
	newHpFill.BorderSizePixel = 0
	newHpFill.ZIndex = 2
	newHpFill.Parent = hpBg
	hpFillBar = newHpFill

	local hpHeader = Instance.new("TextLabel")
	hpHeader.Name = "HpHeader"
	hpHeader.Size = UDim2.new(0.3, 0, 1, 0)
	hpHeader.Position = UDim2.new(0, 10, 0, 0)
	hpHeader.BackgroundTransparency = 1
	hpHeader.Text = "HP"
	hpHeader.TextColor3 = COLOR_TEXT_MAIN
	hpHeader.Font = UI_FONT
	hpHeader.TextSize = 14
	hpHeader.TextXAlignment = Enum.TextXAlignment.Left
	hpHeader.ZIndex = 3
	hpHeader.Parent = hpBox

	local newHpText = Instance.new("TextLabel")
	newHpText.Name = "HpText"
	newHpText.Size = UDim2.new(0.7, -10, 1, 0)
	newHpText.Position = UDim2.new(0.3, 0, 0, 0)
	newHpText.BackgroundTransparency = 1
	newHpText.Text = "100 / 100 HP"
	newHpText.TextColor3 = COLOR_TEXT_MAIN
	newHpText.Font = UI_FONT
	newHpText.TextSize = 14
	newHpText.TextXAlignment = Enum.TextXAlignment.Right
	newHpText.ZIndex = 3
	newHpText.Parent = hpBox
	hpTextLabel = newHpText

	----------------------------------------------------------------------------
	-- 2. THICK CULTIVATION QI BAR BOX (Height: 28px)
	----------------------------------------------------------------------------
	local qiBox = Instance.new("Frame")
	qiBox.Name = "QiBox"
	qiBox.Size = UDim2.new(1, -24, 0, 28)
	qiBox.Position = UDim2.new(0, 12, 0, 48)
	qiBox.BackgroundColor3 = COLOR_LIGHT_PANEL
	qiBox.BorderSizePixel = 0
	qiBox.Parent = panel

	local qiBoxStroke = Instance.new("UIStroke")
	qiBoxStroke.Color = COLOR_LIGHT_BORDER
	qiBoxStroke.Thickness = 1
	qiBoxStroke.Parent = qiBox

	local qiBg = Instance.new("Frame")
	qiBg.Name = "QiBg"
	qiBg.Size = UDim2.new(1, 0, 1, 0)
	qiBg.BackgroundColor3 = COLOR_LIGHT_PANEL
	qiBg.BorderSizePixel = 0
	qiBg.Parent = qiBox

	local newQiFill = Instance.new("Frame")
	newQiFill.Name = "FillBar"
	newQiFill.Size = UDim2.new(0, 0, 1, 0)
	newQiFill.BackgroundColor3 = COLOR_AZURE
	newQiFill.BorderSizePixel = 0
	newQiFill.ZIndex = 2
	newQiFill.Parent = qiBg
	cultivationFillBar = newQiFill

	local newRealmTitle = Instance.new("TextLabel")
	newRealmTitle.Name = "RealmTitle"
	newRealmTitle.Size = UDim2.new(0.65, 0, 1, 0)
	newRealmTitle.Position = UDim2.new(0, 10, 0, 0)
	newRealmTitle.BackgroundTransparency = 1
	newRealmTitle.Text = "Golden Core — Order 1"
	newRealmTitle.TextColor3 = COLOR_TEXT_MAIN
	newRealmTitle.Font = UI_FONT
	newRealmTitle.TextSize = 14
	newRealmTitle.TextXAlignment = Enum.TextXAlignment.Left
	newRealmTitle.ZIndex = 3
	newRealmTitle.Parent = qiBox
	realmTitleLabel = newRealmTitle

	local newQiProgress = Instance.new("TextLabel")
	newQiProgress.Name = "QiProgress"
	newQiProgress.Size = UDim2.new(0.35, -10, 1, 0)
	newQiProgress.Position = UDim2.new(0.65, 0, 0, 0)
	newQiProgress.BackgroundTransparency = 1
	newQiProgress.Text = "0 / 800 (0.0%)"
	newQiProgress.TextColor3 = COLOR_TEXT_MAIN
	newQiProgress.Font = UI_FONT
	newQiProgress.TextSize = 14
	newQiProgress.TextXAlignment = Enum.TextXAlignment.Right
	newQiProgress.ZIndex = 3
	newQiProgress.Parent = qiBox
	qiProgressLabel = newQiProgress

	----------------------------------------------------------------------------
	-- 3. ACTION PROMPT LINE
	----------------------------------------------------------------------------
	local newPrompt = Instance.new("TextLabel")
	newPrompt.Name = "HotkeyPrompt"
	newPrompt.Size = UDim2.new(1, -24, 0, 22)
	newPrompt.Position = UDim2.new(0, 12, 0, 84)
	newPrompt.BackgroundTransparency = 1
	newPrompt.Text = "[G] HOLD TO MEDITATE"
	newPrompt.TextColor3 = COLOR_TEXT_SUB
	newPrompt.Font = UI_FONT
	newPrompt.TextSize = 15
	newPrompt.Parent = panel
	actionHotkeyPrompt = newPrompt

	----------------------------------------------------------------------------
	-- 4. SKILL HOTBAR SLOTS
	----------------------------------------------------------------------------
	local actionSkillBar = Instance.new("Frame")
	actionSkillBar.Name = "ActionSkillBar"
	actionSkillBar.Size = UDim2.new(1, -24, 0, 58)
	actionSkillBar.Position = UDim2.new(0, 12, 0, 114)
	actionSkillBar.BackgroundTransparency = 1
	actionSkillBar.Parent = panel

	local slotsConfig = {
		{ Key = "M1", BindText = "LMB", Icon = UIAssets.Skills.M1_SwordArt },
		{ Key = "F", BindText = "F", Icon = UIAssets.Skills.M2_HeavySlam },
		{ Key = "Q", BindText = "Q", Icon = UIAssets.Skills.SwordTempest },
		{ Key = "E", BindText = "E", Icon = UIAssets.Skills.DragonRoar },
		{ Key = "R", BindText = "R", Icon = UIAssets.Skills.TribulationBolt },
		{ Key = "Shift", BindText = "SHIFT", Icon = UIAssets.Skills.DodgeWindstep },
	}

	for idx, config in ipairs(slotsConfig) do
		local slot = Instance.new("Frame")
		slot.Name = "Slot_" .. config.Key
		slot.Size = UDim2.new(0, 54, 0, 54)
		slot.Position = UDim2.new(0, (idx - 1) * 72 + 22, 0, 0)
		slot.BackgroundColor3 = COLOR_LIGHT_PANEL
		slot.BorderSizePixel = 0
		slot.Parent = actionSkillBar

		local sStroke = Instance.new("UIStroke")
		sStroke.Name = "Stroke"
		sStroke.Color = COLOR_LIGHT_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, -12, 1, -12)
		iconLabel.Position = UDim2.new(0, 6, 0, 6)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = config.Icon or ""
		iconLabel.ScaleType = Enum.ScaleType.Fit
		iconLabel.Parent = slot

		local keyBadge = Instance.new("Frame")
		keyBadge.Name = "KeyBadge"
		keyBadge.Size = UDim2.new(0, 24, 0, 14)
		keyBadge.Position = UDim2.new(1, -26, 1, -16)
		keyBadge.BackgroundColor3 = COLOR_LIGHT_MAIN
		keyBadge.BorderSizePixel = 0
		keyBadge.ZIndex = 3
		keyBadge.Parent = slot

		local kbStroke = Instance.new("UIStroke")
		kbStroke.Color = COLOR_LIGHT_BORDER
		kbStroke.Thickness = 1
		kbStroke.Parent = keyBadge

		local keyText = Instance.new("TextLabel")
		keyText.Name = "KeyText"
		keyText.Size = UDim2.new(1, 0, 1, 0)
		keyText.BackgroundTransparency = 1
		keyText.Text = config.BindText
		keyText.TextColor3 = COLOR_TEXT_MAIN
		keyText.Font = UI_FONT
		keyText.TextSize = 10
		keyText.Parent = keyBadge

		local mask = Instance.new("Frame")
		mask.Name = "CooldownMask"
		mask.Size = UDim2.new(1, 0, 0, 0)
		mask.Position = UDim2.new(0, 0, 0, 0)
		mask.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		mask.BackgroundTransparency = 0.55
		mask.Visible = false
		mask.ZIndex = 4
		mask.Parent = slot

		local cdText = Instance.new("TextLabel")
		cdText.Name = "CooldownText"
		cdText.Size = UDim2.new(1, 0, 1, 0)
		cdText.BackgroundTransparency = 1
		cdText.TextColor3 = COLOR_TEXT_MAIN
		cdText.Font = UI_FONT
		cdText.TextSize = 16
		cdText.Visible = false
		cdText.ZIndex = 5
		cdText.Parent = slot

		activeSlots[config.Key] = slot
	end
end

function HUDController.UpdateCultivationHUD(data: any)
	if not cultivationFillBar or not realmTitleLabel or not qiProgressLabel or not actionHotkeyPrompt then return end
	local fill: Frame = cultivationFillBar :: Frame
	local realmLabel: TextLabel = realmTitleLabel :: TextLabel
	local qiLabel: TextLabel = qiProgressLabel :: TextLabel
	local promptLabel: TextLabel = actionHotkeyPrompt :: TextLabel

	local realmName = data.RealmName or "Qi Condensation"
	local order = data.Order or 1
	local maxQi = data.MaxQi or 800
	local rawQi = data.CurrentQi or 0
	local currentQi = math.min(rawQi, maxQi)
	local isMeditating = data.IsMeditating or false

	realmLabel.Text = string.format("%s — Order %d", realmName, order)
	realmLabel.TextColor3 = COLOR_TEXT_MAIN

	local pct = math.clamp(currentQi / maxQi, 0, 1)
	local formattedCurrent = CultivationConfig.FormatNumber(currentQi)
	local formattedMax = CultivationConfig.FormatNumber(maxQi)

	qiLabel.Text = string.format("%s / %s (%.1f%%)", formattedCurrent, formattedMax, pct * 100)

	TweenService:Create(fill, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0),
	}):Play()

	if pct >= 1.0 then
		if order == 9 then
			promptLabel.Text = "PRESS 'B' FOR MAJOR HEAVENLY TRIBULATION!"
			promptLabel.TextColor3 = COLOR_DANGER_RED
		else
			promptLabel.Text = "PRESS 'B' FOR MINOR BREAKTHROUGH"
			promptLabel.TextColor3 = COLOR_ACTION_GOLD
		end
	elseif isMeditating then
		promptLabel.Text = "MEDITATING... PRESS [G] TO STOP"
		promptLabel.TextColor3 = COLOR_HP_GREEN
	else
		promptLabel.Text = "[G] HOLD TO MEDITATE"
		promptLabel.TextColor3 = COLOR_TEXT_SUB
	end
end

function HUDController.TriggerCooldown(slotKey: string, duration: number)
	local slot = activeSlots[slotKey]
	if not slot then return end

	local maskNode = slot:FindFirstChild("CooldownMask")
	local cdTextNode = slot:FindFirstChild("CooldownText")
	if not maskNode or not maskNode:IsA("Frame") then return end
	local mask: Frame = maskNode :: Frame

	if activeCooldowns[slotKey] then
		task.cancel(activeCooldowns[slotKey])
		activeCooldowns[slotKey] = nil
	end

	mask.Visible = true
	mask.Size = UDim2.new(1, 0, 1, 0)

	if cdTextNode and cdTextNode:IsA("TextLabel") then
		cdTextNode.Visible = true
		cdTextNode.Text = string.format("%.1f", duration)
	end

	TweenService:Create(mask, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0)
	}):Play()

	local startTime = os.clock()
	activeCooldowns[slotKey] = task.spawn(function()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, duration - elapsed)

			if cdTextNode and cdTextNode:IsA("TextLabel") then
				if remaining > 0 then
					cdTextNode.Text = string.format("%.1f", remaining)
				else
					cdTextNode.Text = ""
				end
			end

			if remaining <= 0 then break end
			task.wait(0.03)
		end

		mask.Visible = false
		if cdTextNode and cdTextNode:IsA("TextLabel") then
			cdTextNode.Visible = false
			cdTextNode.Text = ""
		end
		activeCooldowns[slotKey] = nil
	end)
end

return HUDController