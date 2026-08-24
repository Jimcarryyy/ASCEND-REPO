--!strict
--[[
    CombatStateManager.luau
    Location: src/ServerScriptService/Server/State/CombatStateManager.luau
    Unified Server-Side Combat & CC State Machine for ASCEND.
    Authoritatively manages Action States, CC States, Posture, Guard-Break,
    Stun Immunity (Hyperarmor), Qi Dash I-Frames, and In-Combat lockouts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type ActionState = "Idle" | "Windup" | "Active" | "Recovery" | "Blocking" | "Dashing"
export type CCState = "None" | "Staggered" | "Stunned" | "GuardBroken" | "CCImmune"

export type PlayerCombatState = {
	ActionState: ActionState,
	CCState: CCState,
	CCImmunityEndTime: number,
	RecoveryEndTime: number,
	BlockStartTime: number,
	IsBlocking: boolean,
	Posture: number,
	MaxPosture: number,
	LastBlockReleaseTime: number,
	IFrameEndTime: number,
	InCombatEndTime: number,
	Cooldowns: { [string]: number },
	ActiveStrike: { SkillKey: string, StartTime: number }?,
}

local CombatStateManager = {}
local playerStates: { [Player]: PlayerCombatState } = {}

local combatActionRemote: RemoteEvent
local combatVFXRemote: RemoteEvent
local syncCooldownRemote: RemoteEvent

function CombatStateManager.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	syncCooldownRemote = RemoteEvents.GetRemote("SyncCooldown")

	Players.PlayerAdded:Connect(CombatStateManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CombatStateManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		CombatStateManager.OnPlayerAdded(player)
	end

	-- Master State & Posture Regen Loop (60Hz Server Tick)
	RunService.Heartbeat:Connect(CombatStateManager.UpdateHeartbeat)

	-- Remote Event Gateway
	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end

		-- 1. Sheath Toggle (R)
		if payload.ToggleSheath then
			local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
			WeaponManager.ToggleSheath(player)
			return
		end

		-- 2. Guard / Block Stance (F)
		if payload.Action == "BlockStart" then
			CombatStateManager.StartBlock(player, payload.Timestamp)
			return
		elseif payload.Action == "BlockEnd" then
			CombatStateManager.EndBlock(player)
			return
		end

		-- 3. Dash (Shift)
		if payload.SkillKey == "Shift" then
			CombatStateManager.ExecuteDash(player, payload)
			return
		end

		-- 4. Combat Skills / M1
		if type(payload.SkillKey) == "string" then
			CombatStateManager.HandleSkillRequest(player, payload.SkillKey, payload)
		end
	end)

	print("[ASCEND] Unified CombatStateManager Initialized (Full CC & Posture Engine Active).")
end

function CombatStateManager.OnPlayerAdded(player: Player)
	playerStates[player] = {
		ActionState = "Idle",
		CCState = "None",
		CCImmunityEndTime = 0,
		RecoveryEndTime = 0,
		BlockStartTime = 0,
		IsBlocking = false,
		Posture = FlyingSwordConfig.Posture.MaxPosture,
		MaxPosture = FlyingSwordConfig.Posture.MaxPosture,
		LastBlockReleaseTime = 0,
		IFrameEndTime = 0,
		InCombatEndTime = 0,
		Cooldowns = {},
		ActiveStrike = nil,
	}

	player.CharacterAdded:Connect(function(character)
		local state = playerStates[player]
		if state then
			state.ActionState = "Idle"
			state.CCState = "None"
			state.CCImmunityEndTime = 0
			state.RecoveryEndTime = 0
			state.IsBlocking = false
			state.Posture = state.MaxPosture
			state.IFrameEndTime = 0
			state.InCombatEndTime = 0
			state.ActiveStrike = nil
		end
		character:SetAttribute("InCombat", false)
		character:SetAttribute("CCState", "None")
		character:SetAttribute("IsBlocking", false)
	end)
end

function CombatStateManager.OnPlayerRemoving(player: Player)
	playerStates[player] = nil
end

function CombatStateManager.GetState(player: Player): PlayerCombatState?
	return playerStates[player]
end

-- =============================================================================
-- 1. POSTURE & RECOVERY HEARTBEAT
-- =============================================================================
function CombatStateManager.UpdateHeartbeat(dt: number)
	local now = os.clock()

	for player, state in pairs(playerStates) do
		local char = player.Character
		if not char or not char.Parent then continue end

		-- CC Immunity Expiration
		if state.CCState == "CCImmune" and now >= state.CCImmunityEndTime then
			state.CCState = "None"
			char:SetAttribute("CCState", "None")
		end

		-- Recovery Expiration
		if state.ActionState == "Recovery" and now >= state.RecoveryEndTime then
			state.ActionState = "Idle"
		end

		-- Active Strike Expiration
		if state.ActiveStrike and (now - state.ActiveStrike.StartTime) > 0.35 then
			state.ActiveStrike = nil
		end

		-- In-Combat Tagging Expiration
		local inCombat = (now < state.InCombatEndTime)
		if char:GetAttribute("InCombat") ~= inCombat then
			char:SetAttribute("InCombat", inCombat)
		end

		-- Posture Regeneration (Only when not blocking and out of CC)
		if not state.IsBlocking and state.CCState == "None" then
			if (now - state.LastBlockReleaseTime) >= FlyingSwordConfig.Posture.RegenDelay then
				if state.Posture < state.MaxPosture then
					state.Posture = math.min(state.MaxPosture, state.Posture + (FlyingSwordConfig.Posture.RegenRate * dt))
					char:SetAttribute("Posture", math.floor(state.Posture))
				end
			end
		end
	end
end

-- =============================================================================
-- 2. IN-COMBAT TAGGING
-- =============================================================================
function CombatStateManager.TagInCombat(player: Player)
	local state = playerStates[player]
	if not state then return end

	state.InCombatEndTime = os.clock() + FlyingSwordConfig.CC.InCombatDuration
	local char = player.Character
	if char then
		char:SetAttribute("InCombat", true)
	end
end

function CombatStateManager.IsInCombat(player: Player): boolean
	local state = playerStates[player]
	return (state ~= nil) and (os.clock() < state.InCombatEndTime)
end

-- =============================================================================
-- 3. UNIFIED CC & HYPERARMOR ENGINE
-- =============================================================================
function CombatStateManager.ApplyCC(player: Player, ccType: CCState, duration: number): boolean
	local state = playerStates[player]
	if not state then return false end

	local now = os.clock()

	-- Reject if player has active CC-Immunity (Hyperarmor)
	if state.CCState == "CCImmune" or (now < state.CCImmunityEndTime) then
		return false
	end

	-- Cancel active attacks and blocks cleanly
	state.IsBlocking = false
	state.ActiveStrike = nil
	state.ActionState = "Idle"
	state.CCState = ccType

	local char = player.Character
	if char then
		char:SetAttribute("CCState", ccType)
		char:SetAttribute("IsBlocking", false)

		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then hum.WalkSpeed = 0 end
	end

	-- Replicate CC state to all clients
	combatActionRemote:FireAllClients(player, "StatusEffect", { Effect = ccType, Duration = duration })

	task.delay(duration, function()
		if player.Parent and playerStates[player] == state and state.CCState == ccType then
			-- Transition cleanly into 0.6s CC-Immunity window
			state.CCState = "CCImmune"
			state.CCImmunityEndTime = os.clock() + FlyingSwordConfig.CC.StunImmunityDuration
			state.ActionState = "Idle"

			if char and char.Parent then
				char:SetAttribute("CCState", "CCImmune")
				local hum = char:FindFirstChildOfClass("Humanoid")
				if hum then
					local inArena = char:GetAttribute("InArena") == true
					hum.WalkSpeed = inArena and 16 or 18
				end
			end
		end
	end)

	return true
end

-- =============================================================================
-- 4. BLOCK & PARRY GATEWAY
-- =============================================================================
function CombatStateManager.StartBlock(player: Player, clientTimestamp: number?)
	local state = playerStates[player]
	if not state then return end

	local now = os.clock()
	if state.CCState == "Stunned" or state.CCState == "GuardBroken" or state.ActionState == "Windup" or state.ActionState == "Active" then
		return
	end

	local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	-- Clamp client timestamp against ping tolerance
	local clampedStart = now
	if clientTimestamp and type(clientTimestamp) == "number" then
		local pingDelta = math.clamp(now - clientTimestamp, 0, FlyingSwordConfig.CC.MaxPingTolerance)
		clampedStart = now - pingDelta
	end

	state.IsBlocking = true
	state.BlockStartTime = clampedStart
	state.ActionState = "Blocking"

	local char = player.Character
	if char then
		char:SetAttribute("IsBlocking", true)
		char:SetAttribute("BlockStartTime", clampedStart)
	end

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			combatActionRemote:FireClient(other, player, "BlockStart", {})
		end
	end
end

function CombatStateManager.EndBlock(player: Player)
	local state = playerStates[player]
	if not state then return end

	state.IsBlocking = false
	state.LastBlockReleaseTime = os.clock()
	if state.ActionState == "Blocking" then
		state.ActionState = "Idle"
	end

	local char = player.Character
	if char then
		char:SetAttribute("IsBlocking", false)
	end

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			combatActionRemote:FireClient(other, player, "BlockEnd", {})
		end
	end
end

-- =============================================================================
-- 5. QI DASH & I-FRAMES
-- =============================================================================
function CombatStateManager.ExecuteDash(player: Player, payload: any)
	local state = playerStates[player]
	if not state then return end

	local now = os.clock()
	if state.CCState == "Stunned" or state.CCState == "GuardBroken" then return end

	local lastDash = state.Cooldowns["Shift"] or 0
	if (now - lastDash) < FlyingSwordConfig.Skills.Shift.Cooldown then return end

	state.Cooldowns["Shift"] = now
	state.ActionState = "Dashing"
	state.IFrameEndTime = now + FlyingSwordConfig.CC.IFrameDuration

	task.delay(0.24, function()
		if state.ActionState == "Dashing" then
			state.ActionState = "Idle"
		end
	end)

	combatActionRemote:FireAllClients(player, "Shift", payload)
end

-- =============================================================================
-- 6. SKILL & M1 EXECUTION GATEWAY (ANTI-ANIMATION CANCELING)
-- =============================================================================
function CombatStateManager.HandleSkillRequest(player: Player, skillKey: string, payload: any?): boolean
	local state = playerStates[player]
	if not state then return false end

	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	-- CC and Lockout Gate
	if state.CCState == "Stunned" or state.CCState == "GuardBroken" then return false end
	if state.ActionState == "Windup" or state.ActionState == "Recovery" then return false end

	local now = os.clock()

	-- Cooldown Gate
	local cdDuration = if skillKey == "M1" then 0.28 else (FlyingSwordConfig.Skills[skillKey] and FlyingSwordConfig.Skills[skillKey].Cooldown or 1.0)
	local lastUsed = state.Cooldowns[skillKey] or 0
	if (now - lastUsed) < cdDuration then return false end

	-- Auto-draw weapon
	local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	-- Dynamic Qi Consumption (For Q and E skills)
	if skillKey ~= "M1" then
		local cultMgr = require(ServerScriptService.Server.Cultivation.CultivationManager)
		local pData = if cultMgr then cultMgr.GetPlayerData(player) else nil

		if pData then
			local cultivatedCap = pData.CultivatedQi or 1000
			local costPercent = (FlyingSwordConfig.Skills[skillKey] and FlyingSwordConfig.Skills[skillKey].QiCostPercent) or 0
			local dynamicQiCost = math.floor(cultivatedCap * costPercent)

			if dynamicQiCost > 0 and cultMgr and cultMgr.ConsumeQi then
				local hasQi = cultMgr.ConsumeQi(player, dynamicQiCost)
				if not hasQi then return false end
			end
		end
	end

	-- Record Cooldown atomically
	state.Cooldowns[skillKey] = now
	state.ActiveStrike = { SkillKey = skillKey, StartTime = now }
	state.ActionState = "Active"

	CombatStateManager.TagInCombat(player)

	-- Calculate Recovery duration to prevent animation cancel exploits
	local recoveryTime = 0.20
	if skillKey == "M1" then
		local stepIdx = (payload and payload.ComboIndex) or 1
		local stepData = FlyingSwordConfig.M1Combo[stepIdx] or FlyingSwordConfig.M1Combo[1]
		recoveryTime = stepData.Recovery
	elseif FlyingSwordConfig.Skills[skillKey] then
		recoveryTime = FlyingSwordConfig.Skills[skillKey].Recovery
	end

	state.RecoveryEndTime = now + recoveryTime

	-- Execute Server Attack Engine
	local FlyingSwordServer = require(ServerScriptService.Server.Combat.Weapons.FlyingSwordServer)
	payload = FlyingSwordServer.ExecuteAttack(player, skillKey, payload)

	-- Broadcast atomic combat results
	combatActionRemote:FireAllClients(player, skillKey, payload)

	return true
end

return CombatStateManager