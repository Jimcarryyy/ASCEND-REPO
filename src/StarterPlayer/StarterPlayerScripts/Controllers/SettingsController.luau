--!strict
--[[
    SettingsController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SettingsController.luau
    Authoritative Settings Controller bound to StarterGui.SettingsGui hierarchy:
      - ModalBackdrop -> MainWindow (Scale 0.75 <-> 1.0 with Back easing)
      - Row_BackgroundMusic, Row_CameraShake, Row_MasterVolume, Row_MountainWind, Row_VFXQuality
      - Binds 'O' and 'K' keybinds
      - Integrates with ModalWindowManager ("Settings")
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local ModalWindowManager = require(script.Parent.ModalWindowManager)

local localPlayer = Players.LocalPlayer

local SettingsController = {}

local CLICK_SFX = "rbxassetid://138567614125924"
local isOpen = false

-- UI references
local screenGui: ScreenGui? = nil
local modal: Frame? = nil
local window: Frame? = nil
local windowScale: UIScale? = nil

local function PlayClick()
	local s = Instance.new("Sound")
	s.SoundId = CLICK_SFX
	s.Volume = 0.55
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, 1.0)
end

local function SetPillText(btn: TextButton, text: string)
	local lbl = btn:FindFirstChild("ButtonText") :: TextLabel?
	if lbl then
		lbl.Text = text
	else
		btn.Text = text
	end
end

function SettingsController.Open()
	if isOpen or not modal or not windowScale or not screenGui then return end
	isOpen = true

	ModalWindowManager.RequestOpen("Settings")
	screenGui.Enabled = true
	PlayClick()

	modal.BackgroundTransparency = 1
	modal.Visible = true
	windowScale.Scale = 0.75

	TweenService:Create(modal, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.45
	}):Play()

	TweenService:Create(windowScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0
	}):Play()
end

function SettingsController.Close()
	if not isOpen or not modal or not windowScale or not screenGui then return end
	isOpen = false

	ModalWindowManager.NotifyClosed("Settings")
	PlayClick()

	local tInfo = TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In)
	local scaleTween = TweenService:Create(windowScale, tInfo, { Scale = 0.75 })
	local fadeTween = TweenService:Create(modal, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 1
	})

	scaleTween:Play()
	fadeTween:Play()
	scaleTween.Completed:Connect(function()
		if not isOpen and modal and screenGui then
			modal.Visible = false
			windowScale.Scale = 1.0
			screenGui.Enabled = false
		end
	end)
end

function SettingsController.Toggle()
	if isOpen then
		SettingsController.Close()
	else
		SettingsController.Open()
	end
end

function SettingsController.Init()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	screenGui = playerGui:WaitForChild("SettingsGui", 10) :: ScreenGui?
	if not screenGui then
		warn("[SettingsController] SettingsGui not found in PlayerGui!")
		return
	end

	screenGui.ResetOnSpawn = false
	modal = screenGui:WaitForChild("ModalBackdrop", 5) :: Frame?
	if not modal then
		warn("[SettingsController] ModalBackdrop not found in SettingsGui!")
		return
	end

	window = modal:WaitForChild("MainWindow", 5) :: Frame?
	if not window then return end

	windowScale = window:WaitForChild("UIScale", 5) :: UIScale?
	if not windowScale then return end

	local header = window:WaitForChild("HeaderFrame") :: Frame
	local closeBtn = header:WaitForChild("CloseButton") :: TextButton

	local panel = window:WaitForChild("SettingsOptionsPanel") :: Frame
	local saveBtn = window:WaitForChild("SaveSettingsButton") :: TextButton
	local saveScale = saveBtn:WaitForChild("UIScale") :: UIScale

	-- Register into ModalWindowManager
	ModalWindowManager.Register("Settings", function()
		SettingsController.Close()
	end)

	closeBtn.MouseButton1Click:Connect(function()
		SettingsController.Close()
	end)

	saveBtn.MouseButton1Click:Connect(function()
		SettingsController.Close()
	end)

	-- Hover Animation on Save Button
	saveBtn.MouseEnter:Connect(function()
		TweenService:Create(saveScale, TweenInfo.new(0.15), { Scale = 1.03 }):Play()
	end)
	saveBtn.MouseLeave:Connect(function()
		TweenService:Create(saveScale, TweenInfo.new(0.15), { Scale = 1.0 }):Play()
	end)

	-- 1. Background Music Toggle
	local bgmRow = panel:WaitForChild("Row_BackgroundMusic") :: Frame
	local bgmBtn = bgmRow:WaitForChild("OptionButton") :: TextButton
	local isBgmEnabled = true

	bgmBtn.MouseButton1Click:Connect(function()
		PlayClick()
		isBgmEnabled = not isBgmEnabled
		SetPillText(bgmBtn, isBgmEnabled and "[ ENABLED ]" or "[ MUTED ]")
		for _, sound in ipairs(SoundService:GetDescendants()) do
			if sound:IsA("Sound") and (string.find(sound.Name:lower(), "music") or string.find(sound.Name:lower(), "bgm")) then
				sound.Volume = isBgmEnabled and 0.5 or 0
			end
		end
	end)

	-- 2. Camera Shake Toggle
	local shakeRow = panel:WaitForChild("Row_CameraShake") :: Frame
	local shakeBtn = shakeRow:WaitForChild("OptionButton") :: TextButton
	local isShakeEnabled = true

	shakeBtn.MouseButton1Click:Connect(function()
		PlayClick()
		isShakeEnabled = not isShakeEnabled
		SetPillText(shakeBtn, isShakeEnabled and "[ ENABLED ]" or "[ DISABLED ]")
	end)

	-- 3. Master Volume Cycle
	local volRow = panel:WaitForChild("Row_MasterVolume") :: Frame
	local volBtn = volRow:WaitForChild("OptionButton") :: TextButton
	local volLevels = { "[ 100% ]", "[ 75% ]", "[ 50% ]", "[ 25% ]", "[ MUTED ]" }
	local volIdx = 1

	volBtn.MouseButton1Click:Connect(function()
		PlayClick()
		volIdx = (volIdx % #volLevels) + 1
		SetPillText(volBtn, volLevels[volIdx])
	end)

	-- 4. Mountain Wind Volume Cycle
	local windRow = panel:WaitForChild("Row_MountainWind") :: Frame
	local windBtn = windRow:WaitForChild("OptionButton") :: TextButton
	local windLevels = { "[ 100% ]", "[ 80% ]", "[ 50% ]", "[ 20% ]", "[ OFF ]" }
	local windIdx = 2

	windBtn.MouseButton1Click:Connect(function()
		PlayClick()
		windIdx = (windIdx % #windLevels) + 1
		SetPillText(windBtn, windLevels[windIdx])
		local windSound = SoundService:FindFirstChild("AmbientWindSound") :: Sound?
		if windSound then
			local mults = { 1.0, 0.8, 0.5, 0.2, 0.0 }
			windSound.Volume = 0.35 * mults[windIdx]
		end
	end)

	-- 5. VFX Quality Cycle
	local vfxRow = panel:WaitForChild("Row_VFXQuality") :: Frame
	local vfxBtn = vfxRow:WaitForChild("OptionButton") :: TextButton
	local vfxStates = { "[ LOW ]", "[ MEDIUM ]", "[ HIGH / DETAILED ]" }
	local vfxIdx = 3

	vfxBtn.MouseButton1Click:Connect(function()
		PlayClick()
		vfxIdx = (vfxIdx % #vfxStates) + 1
		SetPillText(vfxBtn, vfxStates[vfxIdx])
	end)

	-- Keybinds: 'O' and 'K'
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if UserInputService:GetFocusedTextBox() ~= nil then return end
		if input.KeyCode == Enum.KeyCode.O or input.KeyCode == Enum.KeyCode.K then
			SettingsController.Toggle()
		end
	end)

	print("[SettingsController] Initialized with verified Studio GUI layout. Press 'O' or 'K' to open.")
end

return SettingsController