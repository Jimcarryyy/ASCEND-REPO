--!strict
--[[
    CombatStateManager.luau
    Location: src/ServerScriptService/Server/State/CombatStateManager.luau
    Server-authoritative combat state engine for ASCEND.
    Tracks player combat states, manages server-side cooldowns,
    and validates skill activation requests to prevent client exploits.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
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

local playerStates: { [Player]: PlayerState } = {}
local playerCooldowns: { [Player]: { [string]: SkillCooldownData } } = {}

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
local cultivationManagerRef: any = nil

function CombatStateManager.GetCultivationManager(): any
	if not cultivationManagerRef then
		cultivationManagerRef = require(ServerScriptService.Server.Cultivation.CultivationManager)
	end
	return cultivationManagerRef
end

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

	-- 2. Validate player combat state
	local currentState = CombatStateManager.GetPlayerState(player)
	if currentState == "Stunned" or currentState == "QiDeviation" then
		return false
	end

	-- 3. Validate skill key
	local cooldownDuration = SKILL_COOLDOWNS[skillKey]
	if not cooldownDuration then return false end

	-- 4. Check server cooldown
	if CombatStateManager.IsSkillOnCooldown(player, skillKey) then
		return false
	end

	-- 5. CHECK & CONSUME QI RESOURCE (Lazy-resolved to prevent circular require lock)
	local qiCost = CultivationConfig.SkillCosts[skillKey] or 0
	if qiCost > 0 then
		local cultMgr = CombatStateManager.GetCultivationManager()
		if cultMgr and cultMgr.ConsumeQi then
			local hasQi = cultMgr.ConsumeQi(player, qiCost)
			if not hasQi then
				warn(string.format("[CombatStateManager] Request rejected for %s: Insufficient Qi for skill %s (%d required).", player.Name, skillKey, qiCost))
				return false
			end
		end
	end

	-- 6. Record server cooldown & Sync
	playerCooldowns[player][skillKey] = {
		Duration = cooldownDuration,
		Timestamp = os.clock(),
	}
	syncCooldownRemote:FireClient(player, skillKey, cooldownDuration)

	-- 7. Execute weapon attack mechanics
	local equippedWeapon = WeaponManager.GetEquippedWeapon(player)
	if equippedWeapon == "Spear" then
		payload = SpearServer.ExecuteAttack(player, skillKey, payload)
	elseif equippedWeapon == "Gauntlet" then
		payload = GauntletServer.ExecuteAttack(player, skillKey, payload)
	else
		payload = FlyingSwordServer.ExecuteAttack(player, skillKey, payload)
	end

	combatActionRemote:FireAllClients(player, skillKey, payload)
	return true
end

return CombatStateManager