--!strict
--[[
    CombatStateManager.luau
    Server-authoritative combat state engine for ASCEND.
    Tracks player combat states, manages server-side cooldowns,
    and validates skill activation requests to prevent client exploits.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local SpearServer = require(ServerScriptService.Server.Combat.Weapons.SpearServer)
local FlyingSwordServer = require(ServerScriptService.Server.Combat.Weapons.FlyingSwordServer)
local GauntletServer = require(ServerScriptService.Server.Combat.Weapons.GauntletServer)

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerState = "Idle" | "Casting" | "Cooldown" | "Stunned" | "QiDeviation" | "IFrame"

export type SkillCooldownData = {
	Duration: number,
	Timestamp: number,
}

local CombatStateManager = {}
CombatStateManager.__index = CombatStateManager

-- Player State Storage: [Player] -> State
local playerStates: { [Player]: PlayerState } = {}

-- Server Cooldown Storage: [Player] -> { [SkillKey]: SkillCooldownData }
local playerCooldowns: { [Player]: { [string]: SkillCooldownData } } = {}

-- Base Skill Cooldown Definitions (Server Truth)
local SKILL_COOLDOWNS: { [string]: number } = {
	M1 = 0.6,
	F = 1.5,
	Q = 3.0,
	E = 5.0,
	R = 8.0,
	Shift = 2.0,
}

local combatActionRemote: RemoteEvent
local syncCooldownRemote: RemoteEvent

function CombatStateManager.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	syncCooldownRemote = RemoteEvents.GetRemote("SyncCooldown")

	Players.PlayerAdded:Connect(CombatStateManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CombatStateManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		CombatStateManager.OnPlayerAdded(player)
	end

    combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "string" then
			CombatStateManager.HandleSkillRequest(player, payload, nil)
		elseif type(payload) == "table" and type(payload.SkillKey) == "string" then
			CombatStateManager.HandleSkillRequest(player, payload.SkillKey, payload)
		end
	end)

	print("[ASCEND] CombatStateManager Server Engine Initialized.")
end

function CombatStateManager.OnPlayerAdded(player: Player)
	playerStates[player] = "Idle"
	playerCooldowns[player] = {}
end

function CombatStateManager.OnPlayerRemoving(player: Player)
	playerStates[player] = nil
	playerCooldowns[player] = nil
end

function CombatStateManager.GetPlayerState(player: Player): PlayerState
	return playerStates[player] or "Idle"
end

function CombatStateManager.SetPlayerState(player: Player, newState: PlayerState)
	playerStates[player] = newState
end

function CombatStateManager.IsSkillOnCooldown(player: Player, skillKey: string): boolean
	local cooldowns = playerCooldowns[player]
	if not cooldowns then return false end

	local data = cooldowns[skillKey]
	if not data then return false end

	local elapsed = os.clock() - data.Timestamp
	return elapsed < data.Duration
end

function CombatStateManager.GetRemainingCooldown(player: Player, skillKey: string): number
	local cooldowns = playerCooldowns[player]
	if not cooldowns then return 0 end

	local data = cooldowns[skillKey]
	if not data then return 0 end

	local elapsed = os.clock() - data.Timestamp
	return math.max(0, data.Duration - elapsed)
end

function CombatStateManager.HandleSkillRequest(player: Player, skillKey: string, payload: any?): boolean
	-- 1. Validate character health
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	-- 2. Validate player combat state (reject if stunned or in Qi Deviation)
	local currentState = CombatStateManager.GetPlayerState(player)
	if currentState == "Stunned" or currentState == "QiDeviation" then
		warn(string.format("[CombatStateManager] Request rejected for %s: player is %s", player.Name, currentState))
		return false
	end

	-- 3. Validate skill key definition
	local cooldownDuration = SKILL_COOLDOWNS[skillKey]
	if not cooldownDuration then
		warn(string.format("[CombatStateManager] Unknown skill key requested: %s by %s", skillKey, player.Name))
		return false
	end

	-- 4. Check server cooldown
	if CombatStateManager.IsSkillOnCooldown(player, skillKey) then
		local remaining = CombatStateManager.GetRemainingCooldown(player, skillKey)
		warn(string.format("[CombatStateManager] Skill %s on cooldown for %s (%.1fs remaining)", skillKey, player.Name, remaining))
		return false
	end

	-- 5. Record server cooldown
	playerCooldowns[player][skillKey] = {
		Duration = cooldownDuration,
		Timestamp = os.clock(),
	}

	-- 6. Trigger client UI cooldown sync
	syncCooldownRemote:FireClient(player, skillKey, cooldownDuration)

	-- 7. Broadcast skill execution with targeting payload to nearby players for VFX/SFX
	combatActionRemote:FireAllClients(player, skillKey, payload)

    -- 7. Execute weapon attack mechanics & hitboxes based on equipped weapon
	local equippedWeapon = WeaponManager.GetEquippedWeapon(player)
	if equippedWeapon == "Spear" then
		payload = SpearServer.ExecuteAttack(player, skillKey, payload)
	elseif equippedWeapon == "Gauntlet" then
		payload = GauntletServer.ExecuteAttack(player, skillKey, payload)
	else
		payload = FlyingSwordServer.ExecuteAttack(player, skillKey, payload)
	end

	-- 8. Broadcast skill execution with targeting payload to nearby players for VFX/SFX
	combatActionRemote:FireAllClients(player, skillKey, payload)

	local targetPosText = if payload and payload.TargetPosition then string.format(" at target (%.1f, %.1f, %.1f)", payload.TargetPosition.X, payload.TargetPosition.Y, payload.TargetPosition.Z) else ""
	print(string.format("[CombatStateManager] Player %s executed skill %s%s (Cooldown: %.1fs)", player.Name, skillKey, targetPosText, cooldownDuration))
	return true
end

return CombatStateManager