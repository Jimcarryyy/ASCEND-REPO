--!strict
--[[
    InputController.luau
    Manages client user inputs, keybind mappings, target positioning,
    and action payload transmission to the server.
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
local lastGPress = 0 -- 1.0s spam protection timestamp for G key

function InputController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	-- Listen for meditation state updates to block combat inputs
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) == "table" and data.IsMeditating ~= nil then
			isMeditating = (data.IsMeditating == true)
		end
	end)

	UserInputService.InputBegan:Connect(InputController.OnInputBegan)

	print("[ASCEND] InputController Initialized.")
end

function InputController.SetEnabled(state: boolean)
	enabled = state
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
	if gameProcessed then return end

	-- Always allow G key to toggle/exit meditation with 1.0s spam protection
	if input.KeyCode == Enum.KeyCode.G then
		local now = os.clock()
		if now - lastGPress < 1.0 then return end -- Reject rapid spam within 1 second
		lastGPress = now
		combatActionRemote:FireServer({ ToggleMeditation = true })
		return
	end

	-- Block weapon swaps and combat actions if controls are disabled or character is meditating
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
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		requestedSkill = "Shift"
	end

	if requestedSkill then
		local payload = InputController.GetTargetPayload(requestedSkill)
		combatActionRemote:FireServer(payload)
	end
end

return InputController