--!strict
--[[
    InputController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
    Handles client inputs for Keyboard, Mouse, and Mobile Dynamic Thumbstick Auto-Run.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

export type ActionPayload = {
	SkillKey: string,
	ComboIndex: number?,
	DashIndex: number?,
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
local isBlocking = false

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

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function GetLocomotionSpeeds(): (number, number)
	local character = player.Character
	local inArena = character and (character:GetAttribute("InArena") == true)
	if inArena then
		return 16, 28
	else
		return 18, 52
	end
end

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

	player.CharacterAdded:Connect(function(newChar)
		isMeditating = false
		isSprinting = false
		isBlocking = false
		m1ComboIndex = 1
		currentAttackLockout = 0
	end)

	updateCultivationRemote.OnClientEvent:Connect(function(data: any)
		if type(data) == "table" and data.IsMeditating ~= nil then
			isMeditating = (data.IsMeditating == true)
			if isMeditating and isSprinting then
				InputController.StopSprint()
			end
			if isMeditating and isBlocking then
				InputController.StopBlock()
			end
		end
	end)

	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	UserInputService.InputEnded:Connect(InputController.OnInputEnded)

	-- =========================================================================
	-- MOBILE JOYSTICK AUTO-SPRINT ENGINE
	-- =========================================================================
	RunService.Heartbeat:Connect(function()
		if not IsTouchDevice() then return end

		local character = player.Character
		if not character or isMeditating or isBlocking or not enabled then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then return end

		local moveMag = humanoid.MoveDirection.Magnitude

		-- If pushing joystick all the way forward -> auto-sprint
		if moveMag > 0.85 and not isSprinting and character:GetAttribute("IsDashing") ~= true then
			InputController.StartSprint()
		elseif moveMag < 0.20 and isSprinting then
			InputController.StopSprint()
		end
	end)

	print("[ASCEND] InputController Initialized (With Joystick Auto-Sprint).")
end

function InputController.SetEnabled(state: boolean)
	enabled = state
	if not enabled then
		InputController.StopSprint()
		InputController.StopBlock()
	end
end

function InputController.StartBlock()
	if isMeditating or not enabled or isBlocking then return end
	local character = player.Character
	if character and (character:GetAttribute("IsDashing") == true or character:GetAttribute("IsStunned") == true) then return end

	isBlocking = true
	if isSprinting then
		InputController.StopSprint()
	end

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.StartBlock()
	combatActionRemote:FireServer({ Action = "BlockStart", Timestamp = os.clock() })

	local SkillBarController = require(script.Parent.SkillBarController)
	SkillBarController.TriggerCooldown("F")
end

function InputController.StopBlock()
	if not isBlocking then return end
	isBlocking = false

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.StopBlock()
	combatActionRemote:FireServer({ Action = "BlockEnd", Timestamp = os.clock() })
end

function InputController.StartSprint()
	if isMeditating or not enabled or isBlocking then return end
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
		AimDirection = aimDir,
		Timestamp = os.clock(),
	}
end

function InputController.TriggerDash()
	if isMeditating or not enabled or isBlocking then return end
	local now = os.clock()
	if (now - lastDashPress) < DASH_COOLDOWN then return end
	lastDashPress = now

	local wasSprintingBeforeDash = isSprinting
	local currentDashStep = dashStep
	dashStep = if dashStep == 1 then 2 else 1

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.PerformDash(currentDashStep)

	local payload = InputController.GetTargetPayload("Shift", nil, currentDashStep)
	combatActionRemote:FireServer(payload)

	local SkillBarController = require(script.Parent.SkillBarController)
	SkillBarController.TriggerCooldown("Dash")

	task.delay(0.24, function()
		if wasSprintingBeforeDash and not isMeditating then
			InputController.StartSprint()
		end
	end)
end

function InputController.TriggerM1()
	if not enabled or isMeditating or isBlocking or IsAnyMenuOpen() then return end
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
	AnimationController.PlayAttackAnimation("M1", currentStep)

	local payload = InputController.GetTargetPayload("M1", currentStep)
	combatActionRemote:FireServer(payload)

	local SkillBarController = require(script.Parent.SkillBarController)
	SkillBarController.TriggerCooldown("M1")
end

function InputController.TriggerSkill(skillKey: string)
	if not enabled or isMeditating or isBlocking or IsAnyMenuOpen() then return end

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.PlayAttackAnimation(skillKey, nil)

	local payload = InputController.GetTargetPayload(skillKey)
	combatActionRemote:FireServer(payload)

	local SkillBarController = require(script.Parent.SkillBarController)
	SkillBarController.TriggerCooldown(skillKey)
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed or IsAnyMenuOpen() then return end

	local character = player.Character
	if character and character:GetAttribute("IsDashing") == true then return end

	if input.KeyCode == Enum.KeyCode.F then
		InputController.StartBlock()
		return
	end

	if input.KeyCode == Enum.KeyCode.W then
		local now = os.clock()
		if (now - lastWPressTime) <= DOUBLE_TAP_WINDOW then
			InputController.StartSprint()
		end
		lastWPressTime = now
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		InputController.TriggerDash()
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		local now = os.clock()
		if now - lastCPress < 0.8 then return end
		lastCPress = now
		combatActionRemote:FireServer({ ToggleMeditation = true })
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		if isMeditating then return end
		local now = os.clock()
		if now - lastRPress < 0.5 then return end
		lastRPress = now
		combatActionRemote:FireServer({ ToggleSheath = true })
		return
	end

	if not enabled or isMeditating or isBlocking then return end

	if input.KeyCode == Enum.KeyCode.B then
		combatActionRemote:FireServer({ RequestBreakthrough = true })
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		InputController.TriggerM1()
		return
	end

	if input.KeyCode == Enum.KeyCode.Q then
		InputController.TriggerSkill("Q")
	elseif input.KeyCode == Enum.KeyCode.E then
		InputController.TriggerSkill("E")
	end
end

function InputController.OnInputEnded(input: InputObject, gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.F then
		InputController.StopBlock()
	elseif input.KeyCode == Enum.KeyCode.W then
		if isSprinting then
			InputController.StopSprint()
		end
	end
end

return InputController