--!strict
--[[
    CombatStateManager.luau
    Location: src/ServerScriptService/Server/State/CombatStateManager.luau
    Server-authoritative combat state engine for ASCEND.
    Tracks player combat states, manages server-side cooldowns, Block & Stun states,
    and guarantees complete hit feedback replication to all clients including the attacker.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local FlyingSwordServer = require(ServerScriptService.Server.Combat.Weapons.FlyingSwordServer)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerState = "Idle" | "Casting" | "Blocking" | "Cooldown" | "Stunned" | "QiDeviation" | "IFrame"

export type SkillCooldownData = {
	Duration: number,
	Timestamp: number,
}

local CombatStateManager = {}
CombatStateManager.__index = CombatStateManager

local playerStates: { [Player]: PlayerState } = {}
local playerCooldowns: { [Player]: { [string]: SkillCooldownData } } = {}

local SKILL_COOLDOWNS: { [string]: number } = {
	M1 = 0.28,
	F = 1.5,
	Q = 3.0, 
	E = 5.0,
	R = 8.0,
	Shift = 3.0,
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
		elseif type(payload) == "table" then
			-- 1. Sheath Toggle (R key)
			if payload.ToggleSheath then
				WeaponManager.ToggleSheath(player)
				return
			end

			-- 2. Block Stance Handling (MouseButton2)
			if payload.Action == "BlockStart" then
				CombatStateManager.StartBlock(player)
				return
			elseif payload.Action == "BlockEnd" then
				CombatStateManager.EndBlock(player)
				return
			end

			-- 3. Combat Skill / M1 Execution
			if type(payload.SkillKey) == "string" then
				CombatStateManager.HandleSkillRequest(player, payload.SkillKey, payload)
			end
		end
	end)

	print("[ASCEND] CombatStateManager Initialized (Block, Parry & Hit Feedback Active).")
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
	local char = player.Character
	if char then
		char:SetAttribute("CombatState", newState)
	end
end

function CombatStateManager.StartBlock(player: Player)
	local char = player.Character
	if not char then return end
	local currentState = CombatStateManager.GetPlayerState(player)
	if currentState == "Stunned" or currentState == "QiDeviation" then return end

	-- Auto-draw weapon if sheathed on back
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	CombatStateManager.SetPlayerState(player, "Blocking")
	char:SetAttribute("IsBlocking", true)
	char:SetAttribute("BlockStartTime", os.clock())

	-- Replicate block visual state to other players
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			combatActionRemote:FireClient(other, player, "BlockStart", {})
		end
	end
end

function CombatStateManager.EndBlock(player: Player)
	local char = player.Character
	if char then
		char:SetAttribute("IsBlocking", false)
	end
	if CombatStateManager.GetPlayerState(player) == "Blocking" then
		CombatStateManager.SetPlayerState(player, "Idle")
	end

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			combatActionRemote:FireClient(other, player, "BlockEnd", {})
		end
	end
end

function CombatStateManager.ApplyStun(player: Player, duration: number)
	CombatStateManager.SetPlayerState(player, "Stunned")
	local char = player.Character
	if char then
		char:SetAttribute("IsStunned", true)
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 0 end
	end

	-- Broadcast Stun Animation & State to client
	combatActionRemote:FireAllClients(player, "Stunned", { Duration = duration })

	task.delay(duration, function()
		if player.Parent and CombatStateManager.GetPlayerState(player) == "Stunned" then
			CombatStateManager.SetPlayerState(player, "Idle")
			if char and char.Parent then
				char:SetAttribute("IsStunned", false)
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					local inArena = char:GetAttribute("InArena") == true
					hum.WalkSpeed = inArena and 16 or 18
				end
			end
		end
	end)
end

function CombatStateManager.IsSkillOnCooldown(player: Player, skillKey: string): boolean
	local cooldowns = playerCooldowns[player]
	if not cooldowns then return false end

	local data = cooldowns[skillKey]
	if not data then return false end

	local elapsed = os.clock() - data.Timestamp
	return elapsed < data.Duration
end

function CombatStateManager.HandleSkillRequest(player: Player, skillKey: string, payload: any?): boolean
	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	-- Auto-draw weapon to hand if on back
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	local currentState = CombatStateManager.GetPlayerState(player)
	if currentState == "Stunned" or currentState == "QiDeviation" then
		return false
	end

	local cooldownDuration = SKILL_COOLDOWNS[skillKey]
	if not cooldownDuration then return false end

	if CombatStateManager.IsSkillOnCooldown(player, skillKey) then
		return false
	end

	-- Dynamic Qi Consumption for special skills
	if skillKey ~= "M1" then
		local cultMgr = require(ServerScriptService.Server.Cultivation.CultivationManager)
		local pData = if cultMgr then cultMgr.GetPlayerData(player) else nil

		if pData then
			local cultivatedCap = pData.CultivatedQi or 1000
			local costPercent = CultivationConfig.SkillCostPercent[skillKey] or 0
			local dynamicQiCost = math.floor(cultivatedCap * costPercent)

			if dynamicQiCost > 0 and cultMgr and cultMgr.ConsumeQi then
				local hasQi = cultMgr.ConsumeQi(player, dynamicQiCost)
				if not hasQi then
					return false
				end
			end
		end
	end

	-- Record server cooldown
	playerCooldowns[player][skillKey] = {
		Duration = cooldownDuration,
		Timestamp = os.clock(),
	}

	if skillKey ~= "M1" then
		syncCooldownRemote:FireClient(player, skillKey, cooldownDuration)
	end

	-- Execute damage calculation and enrich payload
	payload = FlyingSwordServer.ExecuteAttack(player, skillKey, payload)

	-- Broadcast hit results to ALL clients (including attacker for instant damage numbers & sound)
	combatActionRemote:FireAllClients(player, skillKey, payload)

	return true
end

return CombatStateManager