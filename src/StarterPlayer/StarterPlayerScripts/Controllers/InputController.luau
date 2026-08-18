--!strict
--[[
    InputController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
    Client controller for keybindings, Shift sprint toggles (WalkSpeed = 32), skill activations, and meditation debounces.
    Features: Strict UI interaction gating to prevent accidental M1 sword attacks while clicking menus.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type ActionPayload = {
	SkillKey: string,
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
local lastGPress = 0
local isSprinting = false

function InputController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	-- Listen for meditation state updates
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) == "table" and data.IsMeditating ~= nil then
			isMeditating = (data.IsMeditating == true)
			if isMeditating then
				InputController.StopSprint()
			end
		end
	end)

	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	UserInputService.InputEnded:Connect(InputController.OnInputEnded)

	print("[ASCEND] InputController Initialized with Fast Shift Sprint & UI Gating.")
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
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		isSprinting = true
		humanoid.WalkSpeed = 32
	end
end

function InputController.StopSprint()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		isSprinting = false
		humanoid.WalkSpeed = 14
	end
end

function InputController.GetTargetPayload(skillKey: string): ActionPayload
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local origin = if hrp then hrp.Position else Vector3.zero
	local targetPos = mouse.Hit.Position
	local aimDir = if (targetPos - origin).Magnitude > 0 then (targetPos - origin).Unit else Vector3.new(0, 0, -1)

	return {
		SkillKey = skillKey,
		TargetPosition = targetPos,
		AimDirection = aimDir,
		Timestamp = os.clock(),
	}
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	-- Strictly ignore input if user is clicking on UI or typing
	if gameProcessed then return end

	-- Always allow G key to toggle/exit meditation with 1.0s debounce
	if input.KeyCode == Enum.KeyCode.G then
		local now = os.clock()
		if now - lastGPress < 1.0 then return end
		lastGPress = now
		combatActionRemote:FireServer({ ToggleMeditation = true })
		return
	end

	-- Hold LeftShift to Sprint
	if input.KeyCode == Enum.KeyCode.LeftShift then
		InputController.StartSprint()
		return
	end

	if not enabled or isMeditating then return end

	-- Weapon swap hotkeys
	if input.KeyCode == Enum.KeyCode.One then
		combatActionRemote:FireServer({ RequestWeaponSwap = "FlyingSword" })
		return
	elseif input.KeyCode == Enum.KeyCode.Two then
		combatActionRemote:FireServer({ RequestWeaponSwap = "Spear" })
		return
	elseif input.KeyCode == Enum.KeyCode.Three then
		combatActionRemote:FireServer({ RequestWeaponSwap = "Gauntlet" })
		return
	elseif input.KeyCode == Enum.KeyCode.B then
		combatActionRemote:FireServer({ RequestBreakthrough = true })
		return
	end

	local requestedSkill: string? = nil

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		requestedSkill = "M1"
	elseif input.KeyCode == Enum.KeyCode.F then
		requestedSkill = "F"
	elseif input.KeyCode == Enum.KeyCode.Q then
		requestedSkill = "Q"
	elseif input.KeyCode == Enum.KeyCode.E then
		requestedSkill = "E"
	elseif input.KeyCode == Enum.KeyCode.R then
		requestedSkill = "R"
	end

	if requestedSkill then
		local payload = InputController.GetTargetPayload(requestedSkill)
		combatActionRemote:FireServer(payload)
	end
end

function InputController.OnInputEnded(input: InputObject, gameProcessed: boolean)
	if input.KeyCode == Enum.KeyCode.LeftShift then
		InputController.StopSprint()
	end
end

return InputController