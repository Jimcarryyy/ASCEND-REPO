--!strict
--[[
    InputController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
    Handles client inputs:
    - Dash Sprint Preservation (Holding W smoothly resumes sprint after dash)
    - Strict UI & Dialogue Input Gating (Blocks attacks & jumps while in menus/alchemy)
    - R Key Sheath Blocked During Meditation
    - 3.0s Dash Cooldown & 5-Hit M1 Broadsword Combo
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

export type ActionPayload = {
	SkillKey: string,
	ComboIndex: number?,
	DashIndex: number?,
	TargetPosition: Vector3,
	AimDirection: Vector3,
	Timestamp: number,
}

local InputController = {}
InputController.__index = InputController

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local combatActionRemote: RemoteEvent
local updateCultivationRemote: RemoteEvent

local enabled = true
local isMeditating = false
local isSprinting = false

-- Debounce & Combo Tracking
local lastWPressTime = 0
local DOUBLE_TAP_WINDOW = 0.28
local lastCPress = 0
local lastRPress = 0
local lastM1Press = 0
local lastDashPress = 0
local dashStep = 1
local DASH_COOLDOWN = 3.0

local currentAttackLockout = 0
local m1ComboIndex = 1
local COMBO_TIMEOUT = 1.3

local function GetLocomotionSpeeds(): (number, number)
	local character = player.Character
	local inArena = character and (character:GetAttribute("InArena") == true)
	if inArena then
		return 16, 28
	else
		return 18, 52
	end
end

-- Check if any fullscreen menu/modal is open
local function IsAnyMenuOpen(): boolean
	if UserInputService:GetFocusedTextBox() ~= nil then return true end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return false end

	local uiNames = { "SpiritPouchInventoryGui", "AlchemyFurnaceGui", "SectMarketGui", "DialogueGui", "ArenaRegistrationGui" }
	for _, name in ipairs(uiNames) do
		local gui = playerGui:FindFirstChild(name)
		if gui and gui:IsA("ScreenGui") and gui.Enabled then
			local backdrop = gui:FindFirstChild("OverlayBackdrop") or gui:FindFirstChild("MainFrame") or gui:FindFirstChild("MainModal")
			if backdrop and (backdrop :: Frame).Visible then
				return true
			end
		end
	end
	return false
end

function InputController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	updateCultivationRemote.OnClientEvent:Connect(function(data: any)
		if type(data) == "table" and data.IsMeditating ~= nil then
			isMeditating = (data.IsMeditating == true)
			if isMeditating and isSprinting then
				InputController.StopSprint()
			end
		end
	end)

	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	UserInputService.InputEnded:Connect(InputController.OnInputEnded)

	print("[ASCEND] InputController Initialized with UI Gating & Dash Sprint Preservation.")
end

function InputController.SetEnabled(state: boolean)
	enabled = state
	if not enabled then
		InputController.StopSprint()
	end
end

function InputController.IsSprinting(): boolean
	return isSprinting
end

function InputController.StartSprint()
	if isMeditating or not enabled then return end
	local character = player.Character
	if character and character:GetAttribute("IsDashing") == true then return end

	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		local _, sprintSpeed = GetLocomotionSpeeds()
		isSprinting = true
		humanoid.WalkSpeed = sprintSpeed
	end
end

function InputController.StopSprint()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		local walkSpeed, _ = GetLocomotionSpeeds()
		isSprinting = false
		humanoid.WalkSpeed = walkSpeed
	end
end

function InputController.GetTargetPayload(skillKey: string, comboIndex: number?, dashIndex: number?): ActionPayload
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local origin = if hrp then hrp.Position else Vector3.zero
	local targetPos = mouse.Hit.Position
	local aimDir = if (targetPos - origin).Magnitude > 0 then (targetPos - origin).Unit else Vector3.new(0, 0, -1)

	return {
		SkillKey = skillKey,
		ComboIndex = comboIndex,
		DashIndex = dashIndex,
		TargetPosition = targetPos,
		AimDirection = aimDir,
		Timestamp = os.clock(),
	}
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	-- Strict UI Gating
	if gameProcessed or IsAnyMenuOpen() then return end

	local character = player.Character
	if character and character:GetAttribute("IsDashing") == true then return end

	-- 1. Double-Tap W to Sprint
	if input.KeyCode == Enum.KeyCode.W then
		local now = os.clock()
		if (now - lastWPressTime) <= DOUBLE_TAP_WINDOW then
			InputController.StartSprint()
		end
		lastWPressTime = now
		return
	end

	-- 2. LeftShift: 2-Stage Qi Dash (Preserves Sprinting if Holding W)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if isMeditating or not enabled then return end
		local now = os.clock()
		if (now - lastDashPress) < DASH_COOLDOWN then return end
		lastDashPress = now

		local wasSprintingBeforeDash = isSprinting

		local currentDashStep = dashStep
		dashStep = if dashStep == 1 then 2 else 1

		local AnimationController = require(script.Parent.AnimationController)
		AnimationController.PerformDash(player, currentDashStep)

		local payload = InputController.GetTargetPayload("Shift", nil, currentDashStep)
		combatActionRemote:FireServer(payload)

		-- Resume sprinting automatically after dash if still holding W
		task.delay(0.24, function()
			if wasSprintingBeforeDash and UserInputService:IsKeyDown(Enum.KeyCode.W) and not isMeditating then
				InputController.StartSprint()
			end
		end)
		return
	end

	-- 3. C: Cultivation / Meditation Toggle
	if input.KeyCode == Enum.KeyCode.C then
		local now = os.clock()
		if now - lastCPress < 0.8 then return end
		lastCPress = now
		combatActionRemote:FireServer({ ToggleMeditation = true })
		return
	end

	-- 4. R: Sheath / Draw Sword Toggle (STRICTLY BLOCKED DURING MEDITATION)
	if input.KeyCode == Enum.KeyCode.R then
		if isMeditating then return end
		local now = os.clock()
		if now - lastRPress < 0.5 then return end
		lastRPress = now
		combatActionRemote:FireServer({ ToggleSheath = true })
		return
	end

	if not enabled or isMeditating then return end

	-- 5. B: Breakthrough Request
	if input.KeyCode == Enum.KeyCode.B then
		combatActionRemote:FireServer({ RequestBreakthrough = true })
		return
	end

	-- 6. M1: Heavy Broadsword Consecutive Combo
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local now = os.clock()

		if (now - lastM1Press) < currentAttackLockout then
			return
		end

		if isSprinting then
			InputController.StopSprint()
		end

		if (now - lastM1Press) > COMBO_TIMEOUT then
			m1ComboIndex = 1
		end

		local currentStep = m1ComboIndex
		local animKey = "M1_" .. tostring(currentStep)
		local swordCfg = AnimationConfig.FlyingSword :: any
		local animDef = if swordCfg then swordCfg[animKey] else nil

		currentAttackLockout = if animDef then (animDef.CastDuration * 0.88) else 0.38
		m1ComboIndex = if m1ComboIndex >= 5 then 1 else m1ComboIndex + 1
		lastM1Press = now

		local AnimationController = require(script.Parent.AnimationController)
		AnimationController.PlayAttackAnimation(player, "M1", currentStep)

		local payload = InputController.GetTargetPayload("M1", currentStep)
		combatActionRemote:FireServer(payload)
		return
	end

	-- 7. Skills (Q, E, F)
	local requestedSkill: string? = nil
	if input.KeyCode == Enum.KeyCode.Q then
		requestedSkill = "Q"
	elseif input.KeyCode == Enum.KeyCode.E then
		requestedSkill = "E"
	elseif input.KeyCode == Enum.KeyCode.F then
		requestedSkill = "F"
	end

	if requestedSkill then
		local payload = InputController.GetTargetPayload(requestedSkill)
		combatActionRemote:FireServer(payload)
	end
end

function InputController.OnInputEnded(input: InputObject, gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.W then
		if isSprinting then
			InputController.StopSprint()
		end
	end
end

return InputController