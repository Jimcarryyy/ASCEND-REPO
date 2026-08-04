--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Master Client HUD Controller for ASCEND.
    Restored skill artwork icons & bottom-right keybind badges while maintaining
    thick meters, pure white realm text, and sharp 90° obsidian panels.
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

-- BOLD COMPACT FONT (Exact match with Spirit Pouch)
local UI_FONT = Enum.Font.FredokaOne

-- SPIRIT POUCH SHARP OBSIDIAN PALETTE
local COLOR_OBSIDIAN_MAIN   = Color3.fromRGB(12, 14, 20)  -- #0C0E14 Main Window Panel
local COLOR_OBSIDIAN_PANEL  = Color3.fromRGB(18, 21, 32)  -- #121520 Sub-Boxes & Slots
local COLOR_OBSIDIAN_BORDER = Color3.fromRGB(30, 35, 48)  -- #1E2330 Sharp Edge Border

local COLOR_TEXT_MAIN       = Color3.fromRGB(241, 245, 249) -- #F1F5F9 Crisp Pure White
local COLOR_TEXT_SUB        = Color3.fromRGB(148, 163, 184) -- #94A3B8 Muted Grey
local COLOR_AZURE           = Color3.fromRGB(56, 189, 248)  -- #38BDF8 Qi Cyan
local COLOR_HP_GREEN        = Color3.fromRGB(34, 197, 94)   -- #22C55E Health Green
local COLOR_ACTION_GOLD     = Color3.fromRGB(234, 179, 8)   -- #EAB308 Gold (Prompts Only)
local COLOR_DANGER_RED      = Color3.fromRGB(239, 68, 68)   -- #EF4444 Danger Red

local hudGui: ScreenGui?
local mainHudPanel: Frame?

-- Vitality & Cultivation Meters
local hpFillBar: Frame?
local hpTextLabel: TextLabel?
local cultivationFillBar: Frame?
local realmTitleLabel: TextLabel?
local qiProgressLabel: TextLabel?

-- Action Prompt
local actionHotkeyPrompt: TextLabel?

-- Skill Hotbar Slots
local activeSlots: { [string]: Frame } = {}
local activeCooldowns: { [string]: thread } = {}

function HUDController.Init()
	hudGui = playerGui:WaitForChild("HUDGui", 10) :: ScreenGui?
	if not hudGui then
		hudGui = Instance.new("ScreenGui")
		hudGui.Name = "HUDGui"
		hudGui.ResetOnSpawn = false
		hudGui.DisplayOrder = 10
		hudGui.Parent = playerGui
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
				local iconLabel = slot:FindFirstChild("Icon") :: ImageLabel?
				if iconLabel then
					iconLabel.Image = iconAsset
				end
			end
		end
	end)

	print("[ASCEND] Reverted Skill Hotbar HUD Initialized Successfully.")
end

function HUDController.HookCharacterEvents(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not humanoid then return end

	local function updateHp()
		if not hpFillBar or not hpTextLabel then return end
		local pct = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
		
		TweenService:Create(hpFillBar, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(pct, 0, 1, 0),
		}):Play()

		hpTextLabel.Text = string.format("%s / %s HP", CultivationConfig.FormatNumber(humanoid.Health), CultivationConfig.FormatNumber(humanoid.MaxHealth))
	end

	humanoid.HealthChanged:Connect(updateHp)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHp)
	updateHp()
end

function HUDController.BuildSharpPanelHUD()
	if not hudGui then return end

	local oldMain = hudGui:FindFirstChild("MainHUDPanel")
	if oldMain then oldMain:Destroy() end

	-- Enclosing Main Panel (SHARP 90° CORNERS, NO UICORNER)
	mainHudPanel = Instance.new("Frame")
	mainHudPanel.Name = "MainHUDPanel"
	mainHudPanel.Size = UDim2.new(0, 500, 0, 185)
	mainHudPanel.Position = UDim2.new(0.5, -250, 1, -200)
	mainHudPanel.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
	mainHudPanel.BorderSizePixel = 0
	mainHudPanel.Parent = hudGui

	local pStroke = Instance.new("UIStroke")
	pStroke.Color = COLOR_OBSIDIAN_BORDER
	pStroke.Thickness = 1.5
	pStroke.Parent = mainHudPanel

	----------------------------------------------------------------------------
	-- 1. THICK HP BAR BOX (Height: 28px, Sharp Corners)
	----------------------------------------------------------------------------
	local hpBox = Instance.new("Frame")
	hpBox.Name = "HpBox"
	hpBox.Size = UDim2.new(1, -24, 0, 28)
	hpBox.Position = UDim2.new(0, 12, 0, 12)
	hpBox.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	hpBox.BorderSizePixel = 0
	hpBox.Parent = mainHudPanel

	local hpBoxStroke = Instance.new("UIStroke")
	hpBoxStroke.Color = COLOR_OBSIDIAN_BORDER
	hpBoxStroke.Thickness = 1
	hpBoxStroke.Parent = hpBox

	local hpBg = Instance.new("Frame")
	hpBg.Name = "HpBg"
	hpBg.Size = UDim2.new(1, 0, 1, 0)
	hpBg.Position = UDim2.new(0, 0, 0, 0)
	hpBg.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	hpBg.BorderSizePixel = 0
	hpBg.Parent = hpBox

	hpFillBar = Instance.new("Frame")
	hpFillBar.Name = "HpFill"
	hpFillBar.Size = UDim2.new(1, 0, 1, 0)
	hpFillBar.BackgroundColor3 = COLOR_HP_GREEN
	hpFillBar.BorderSizePixel = 0
	hpFillBar.ZIndex = 2
	hpFillBar.Parent = hpBg

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

	hpTextLabel = Instance.new("TextLabel")
	hpTextLabel.Name = "HpText"
	hpTextLabel.Size = UDim2.new(0.7, -10, 1, 0)
	hpTextLabel.Position = UDim2.new(0.3, 0, 0, 0)
	hpTextLabel.BackgroundTransparency = 1
	hpTextLabel.Text = "50.0K / 50.0K HP"
	hpTextLabel.TextColor3 = COLOR_TEXT_MAIN
	hpTextLabel.Font = UI_FONT
	hpTextLabel.TextSize = 14
	hpTextLabel.TextXAlignment = Enum.TextXAlignment.Right
	hpTextLabel.ZIndex = 3
	hpTextLabel.Parent = hpBox

	----------------------------------------------------------------------------
	-- 2. THICK CULTIVATION QI BAR BOX (Height: 28px, Sharp Corners)
	----------------------------------------------------------------------------
	local qiBox = Instance.new("Frame")
	qiBox.Name = "QiBox"
	qiBox.Size = UDim2.new(1, -24, 0, 28)
	qiBox.Position = UDim2.new(0, 12, 0, 48)
	qiBox.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	qiBox.BorderSizePixel = 0
	qiBox.Parent = mainHudPanel

	local qiBoxStroke = Instance.new("UIStroke")
	qiBoxStroke.Color = COLOR_OBSIDIAN_BORDER
	qiBoxStroke.Thickness = 1
	qiBoxStroke.Parent = qiBox

	local qiBg = Instance.new("Frame")
	qiBg.Name = "QiBg"
	qiBg.Size = UDim2.new(1, 0, 1, 0)
	qiBg.Position = UDim2.new(0, 0, 0, 0)
	qiBg.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
	qiBg.BorderSizePixel = 0
	qiBg.Parent = qiBox

	cultivationFillBar = Instance.new("Frame")
	cultivationFillBar.Name = "FillBar"
	cultivationFillBar.Size = UDim2.new(0, 0, 1, 0)
	cultivationFillBar.BackgroundColor3 = COLOR_AZURE
	cultivationFillBar.BorderSizePixel = 0
	cultivationFillBar.ZIndex = 2
	cultivationFillBar.Parent = qiBg

	-- Realm Title Text ALWAYS Pure Crisp White
	realmTitleLabel = Instance.new("TextLabel")
	realmTitleLabel.Name = "RealmTitle"
	realmTitleLabel.Size = UDim2.new(0.65, 0, 1, 0)
	realmTitleLabel.Position = UDim2.new(0, 10, 0, 0)
	realmTitleLabel.BackgroundTransparency = 1
	realmTitleLabel.Text = "Golden Core — Order 1"
	realmTitleLabel.TextColor3 = COLOR_TEXT_MAIN -- PURE WHITE ALWAYS
	realmTitleLabel.Font = UI_FONT
	realmTitleLabel.TextSize = 14
	realmTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	realmTitleLabel.ZIndex = 3
	realmTitleLabel.Parent = qiBox

	qiProgressLabel = Instance.new("TextLabel")
	qiProgressLabel.Name = "QiProgress"
	qiProgressLabel.Size = UDim2.new(0.35, -10, 1, 0)
	qiProgressLabel.Position = UDim2.new(0.65, 0, 0, 0)
	qiProgressLabel.BackgroundTransparency = 1
	qiProgressLabel.Text = "0 / 10.0K (0.0%)"
	qiProgressLabel.TextColor3 = COLOR_TEXT_MAIN
	qiProgressLabel.Font = UI_FONT
	qiProgressLabel.TextSize = 14
	qiProgressLabel.TextXAlignment = Enum.TextXAlignment.Right
	qiProgressLabel.ZIndex = 3
	qiProgressLabel.Parent = qiBox

	----------------------------------------------------------------------------
	-- 3. ACTION PROMPT LINE (Clean Text, No Emojis)
	----------------------------------------------------------------------------
	actionHotkeyPrompt = Instance.new("TextLabel")
	actionHotkeyPrompt.Name = "HotkeyPrompt"
	actionHotkeyPrompt.Size = UDim2.new(1, -24, 0, 22)
	actionHotkeyPrompt.Position = UDim2.new(0, 12, 0, 84)
	actionHotkeyPrompt.BackgroundTransparency = 1
	actionHotkeyPrompt.Text = "[G] HOLD TO MEDITATE"
	actionHotkeyPrompt.TextColor3 = COLOR_TEXT_SUB
	actionHotkeyPrompt.Font = UI_FONT
	actionHotkeyPrompt.TextSize = 15
	actionHotkeyPrompt.Parent = mainHudPanel

	----------------------------------------------------------------------------
	-- 4. RESTORED SKILL HOTBAR SLOTS (With Artwork & Bottom-Right Keybadges)
	----------------------------------------------------------------------------
	local actionSkillBar = Instance.new("Frame")
	actionSkillBar.Name = "ActionSkillBar"
	actionSkillBar.Size = UDim2.new(1, -24, 0, 58)
	actionSkillBar.Position = UDim2.new(0, 12, 0, 114)
	actionSkillBar.BackgroundTransparency = 1
	actionSkillBar.Parent = mainHudPanel

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
		slot.BackgroundColor3 = COLOR_OBSIDIAN_PANEL
		slot.BorderSizePixel = 0
		slot.Parent = actionSkillBar

		local sStroke = Instance.new("UIStroke")
		sStroke.Name = "Stroke"
		sStroke.Color = COLOR_OBSIDIAN_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		-- Skill Artwork Icon
		local iconLabel = Instance.new("ImageLabel")
		iconLabel.Name = "Icon"
		iconLabel.Size = UDim2.new(1, -12, 1, -12)
		iconLabel.Position = UDim2.new(0, 6, 0, 6)
		iconLabel.BackgroundTransparency = 1
		iconLabel.Image = config.Icon
		iconLabel.ScaleType = Enum.ScaleType.Fit
		iconLabel.Parent = slot

		-- Bottom Right Keybind Badge Box (Prevents overlap with center cooldown text)
		local keyBadge = Instance.new("Frame")
		keyBadge.Name = "KeyBadge"
		keyBadge.Size = UDim2.new(0, 24, 0, 14)
		keyBadge.Position = UDim2.new(1, -26, 1, -16)
		keyBadge.BackgroundColor3 = COLOR_OBSIDIAN_MAIN
		keyBadge.BorderSizePixel = 0
		keyBadge.ZIndex = 3
		keyBadge.Parent = slot

		local kbStroke = Instance.new("UIStroke")
		kbStroke.Color = COLOR_OBSIDIAN_BORDER
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

		-- Cooldown Mask (Centered text)
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

	local realmName = data.RealmName or "Qi Condensation"
	local order = data.Order or 1
	local currentQi = data.CurrentQi or 0
	local maxQi = data.MaxQi or 100000
	local isMeditating = data.IsMeditating or false

	realmTitleLabel.Text = string.format("%s — Order %d", realmName, order)
	realmTitleLabel.TextColor3 = COLOR_TEXT_MAIN -- PURE WHITE ALWAYS

	local pct = math.clamp(currentQi / maxQi, 0, 1)
	local formattedCurrent = CultivationConfig.FormatNumber(currentQi)
	local formattedMax = CultivationConfig.FormatNumber(maxQi)

	qiProgressLabel.Text = string.format("%s / %s (%.1f%%)", formattedCurrent, formattedMax, pct * 100)

	TweenService:Create(cultivationFillBar, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(pct, 0, 1, 0),
	}):Play()

	if pct >= 1.0 then
		if order == 9 then
			actionHotkeyPrompt.Text = "PRESS 'B' FOR MAJOR HEAVENLY TRIBULATION!"
			actionHotkeyPrompt.TextColor3 = COLOR_DANGER_RED
		else
			actionHotkeyPrompt.Text = "PRESS 'B' FOR MINOR BREAKTHROUGH"
			actionHotkeyPrompt.TextColor3 = COLOR_ACTION_GOLD
		end
	elseif isMeditating then
		actionHotkeyPrompt.Text = "MEDITATING... PRESS [G] TO STOP"
		actionHotkeyPrompt.TextColor3 = COLOR_HP_GREEN
	else
		actionHotkeyPrompt.Text = "[G] HOLD TO MEDITATE"
		actionHotkeyPrompt.TextColor3 = COLOR_TEXT_SUB
	end
end

function HUDController.TriggerCooldown(slotKey: string, duration: number)
	local slot = activeSlots[slotKey]
	if not slot then return end

	local mask = slot:FindFirstChild("CooldownMask") :: Frame?
	local cdText = slot:FindFirstChild("CooldownText") :: TextLabel?
	if not mask then return end

	if activeCooldowns[slotKey] then
		task.cancel(activeCooldowns[slotKey])
		activeCooldowns[slotKey] = nil
	end

	mask.Visible = true
	mask.Size = UDim2.new(1, 0, 1, 0)

	if cdText then
		cdText.Visible = true
		cdText.Text = string.format("%.1f", duration)
	end

	TweenService:Create(mask, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0)
	}):Play()

	local startTime = os.clock()
	activeCooldowns[slotKey] = task.spawn(function()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, duration - elapsed)

			if cdText then
				if remaining > 0 then
					cdText.Text = string.format("%.1f", remaining)
				else
					cdText.Text = ""
				end
			end

			if remaining <= 0 then break end
			task.wait(0.03)
		end

		mask.Visible = false
		if cdText then
			cdText.Visible = false
			cdText.Text = ""
		end
		activeCooldowns[slotKey] = nil
	end)
end

return HUDController