--!strict
--[[
    CombatStateManager.luau
    Location: src/ServerScriptService/Server/State/CombatStateManager.luau
    Updates:
      - Continuous Moving M1: Server-authoritative step sequence with 2.20s finisher recovery lockout.
      - Full combo reset on Dash, CC, Death, and Sheath.
      - Posture regen, parry latency compensation, and decoupled WalkSpeed attributes preserved.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type ActionState = "Idle" | "Windup" | "Active" | "ChargingF" | "Recovery" | "Blocking" | "Dashing"
export type CCState = "None" | "Staggered" | "Stunned" | "GuardBroken" | "CCImmune"

export type PlayerCombatState = {
	ActionState: ActionState,
	CCState: CCState,
	CCImmunityEndTime: number,
	ActiveEndTime: number,
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
	LastReplicatedPosture: number,
	M1Step: number,
	LastM1Time: number,
}

local CombatStateManager = {}
local playerStates: { [Player]: PlayerCombatState } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}

local weaponManagerRef: any = nil
local function getWeaponManager(): any
	if not weaponManagerRef then
		weaponManagerRef = require(ServerScriptService.Server.Combat.WeaponManager)
	end
	return weaponManagerRef
end

local cultivationManagerRef: any = nil
local function getCultivationManager(): any
	if not cultivationManagerRef then
		cultivationManagerRef = require(ServerScriptService.Server.Cultivation.CultivationManager)
	end
	return cultivationManagerRef
end

local flyingSwordServerRef: any = nil
local function getFlyingSwordServer(): any
	if not flyingSwordServerRef then
		flyingSwordServerRef = require(ServerScriptService.Server.Combat.Weapons.FlyingSwordServer)
	end
	return flyingSwordServerRef
end

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

	RunService.Heartbeat:Connect(CombatStateManager.UpdateHeartbeat)

	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end

		if payload.ToggleSheath then
			local WeaponManager = getWeaponManager()
			WeaponManager.ToggleSheath(player)
			CombatStateManager.ResetM1Combo(player)
			return
		end

		if payload.ToggleFlight then
			local WeaponManager = getWeaponManager()
			WeaponManager.ToggleFlight(player)
			return
		end

		if payload.Action == "BlockStart" then
			CombatStateManager.StartBlock(player, payload.Timestamp)
			return
		elseif payload.Action == "BlockEnd" then
			CombatStateManager.EndBlock(player)
			return
		end

		if payload.SkillKey == "Shift" then
			CombatStateManager.ExecuteDash(player, payload)
			return
		end

		if payload.Action == "StartChargeF" or payload.SkillKey == "StartChargeF" then
			CombatStateManager.HandleStartChargeF(player)
			return
		end

		if type(payload.SkillKey) == "string" then
			CombatStateManager.HandleSkillRequest(player, payload.SkillKey, payload)
		end
	end)

	print("[ASCEND] CombatStateManager Initialized (A6 Server Decoupled & Fast M1 Active).")
end

function CombatStateManager.OnPlayerAdded(player: Player)
	playerStates[player] = {
		ActionState = "Idle",
		CCState = "None",
		CCImmunityEndTime = 0,
		ActiveEndTime = 0,
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
		LastReplicatedPosture = FlyingSwordConfig.Posture.MaxPosture,
		M1Step = 0,
		LastM1Time = 0,
	}

	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		local state = playerStates[player]
		if state then
			state.ActionState = "Idle"
			state.CCState = "None"
			state.CCImmunityEndTime = 0
			state.ActiveEndTime = 0
			state.RecoveryEndTime = 0
			state.IsBlocking = false
			state.Posture = state.MaxPosture
			state.LastReplicatedPosture = state.MaxPosture
			state.IFrameEndTime = 0
			state.InCombatEndTime = 0
			state.ActiveStrike = nil
			state.M1Step = 0
			state.LastM1Time = 0
		end
		character:SetAttribute("InCombat", false)
		character:SetAttribute("CCState", "None")
		character:SetAttribute("IsBlocking", false)
		character:SetAttribute("IsFlying", false)
		character:SetAttribute("IsChargingF", false)
		character:SetAttribute("IsBlinking", false)
		character:SetAttribute("Posture", FlyingSwordConfig.Posture.MaxPosture)
	end)
end

function CombatStateManager.OnPlayerRemoving(player: Player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end
	playerStates[player] = nil
end

function CombatStateManager.GetState(player: Player): PlayerCombatState?
	local state = playerStates[player]
	if not state and player and player.Parent then
		CombatStateManager.OnPlayerAdded(player)
		state = playerStates[player]
	end
	return state
end

function CombatStateManager.ResetM1Combo(player: Player)
	local state = playerStates[player]
	if state then
		state.M1Step = 0
		state.LastM1Time = 0
	end
end

function CombatStateManager.UpdateHeartbeat(dt: number)
	local now = Workspace:GetServerTimeNow()

	for player, state in pairs(playerStates) do
		local char = player.Character
		if not char or not char.Parent then continue end

		if state.CCState == "CCImmune" and now >= state.CCImmunityEndTime then
			state.CCState = "None"
			char:SetAttribute("CCState", "None")
		end

		if state.ActionState == "Active" and now >= state.ActiveEndTime then
			state.ActionState = "Recovery"
		end

		if state.ActionState == "Recovery" and now >= state.RecoveryEndTime then
			state.ActionState = "Idle"
		end

		if state.ActiveStrike and (now - state.ActiveStrike.StartTime) > 0.25 then
			state.ActiveStrike = nil
		end

		local inCombat = (now < state.InCombatEndTime)
		if char:GetAttribute("InCombat") ~= inCombat then
			char:SetAttribute("InCombat", inCombat)
		end

		if not state.IsBlocking and state.CCState == "None" then
			if (now - state.LastBlockReleaseTime) >= FlyingSwordConfig.Posture.RegenDelay then
				if state.Posture < state.MaxPosture then
					state.Posture = math.min(state.MaxPosture, state.Posture + (FlyingSwordConfig.Posture.RegenRate * dt))
					local roundedPosture = math.floor(state.Posture)
					if roundedPosture ~= state.LastReplicatedPosture then
						state.LastReplicatedPosture = roundedPosture
						char:SetAttribute("Posture", roundedPosture)
					end
				end
			end
		end
	end
end

function CombatStateManager.TagInCombat(player: Player)
	local state = playerStates[player]
	if not state then return end

	state.InCombatEndTime = Workspace:GetServerTimeNow() + FlyingSwordConfig.CC.InCombatDuration
	local char = player.Character
	if char then
		char:SetAttribute("InCombat", true)
		if char:GetAttribute("IsFlying") == true then
			local WeaponManager = getWeaponManager()
			WeaponManager.ToggleFlight(player)
		end
	end
end

function CombatStateManager.IsInCombat(player: Player): boolean
	local state = playerStates[player]
	return (state ~= nil) and (Workspace:GetServerTimeNow() < state.InCombatEndTime)
end

function CombatStateManager.ApplyCC(player: Player, ccType: CCState, duration: number): boolean
	local state = playerStates[player]
	if not state then return false end

	local now = Workspace:GetServerTimeNow()
	if state.CCState == "CCImmune" or (now < state.CCImmunityEndTime) then
		return false
	end

	state.IsBlocking = false
	state.ActiveStrike = nil
	state.ActionState = "Idle"
	state.CCState = ccType
	state.M1Step = 0
	state.LastM1Time = 0

	local char = player.Character
	if char then
		char:SetAttribute("CCState", ccType)
		char:SetAttribute("IsBlocking", false)
		char:SetAttribute("IsChargingF", false)
		char:SetAttribute("IsBlinking", false)

		if char:GetAttribute("IsFlying") == true then
			local WeaponManager = getWeaponManager()
			WeaponManager.ToggleFlight(player)
		end
	end

	combatActionRemote:FireAllClients(player, "StatusEffect", { Effect = ccType, Duration = duration })

	task.delay(duration, function()
		if player.Parent and playerStates[player] == state and state.CCState == ccType then
			state.CCState = "CCImmune"
			state.CCImmunityEndTime = Workspace:GetServerTimeNow() + FlyingSwordConfig.CC.StunImmunityDuration
			state.ActionState = "Idle"

			if char and char.Parent then
				char:SetAttribute("CCState", "CCImmune")
			end
		end
	end)

	return true
end

function CombatStateManager.StartBlock(player: Player, clientTimestamp: number?)
	local state = playerStates[player]
	if not state then return end

	local now = Workspace:GetServerTimeNow()
	if state.CCState == "Stunned" or state.CCState == "GuardBroken" or state.CCState == "Staggered" or state.ActionState == "Windup" or state.ActionState == "Active" then
		return
	end

	local char = player.Character
	if char and char:GetAttribute("IsFlying") == true then
		local WeaponManager = getWeaponManager()
		WeaponManager.ToggleFlight(player)
	end

	local WeaponManager = getWeaponManager()
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	local clampedStart = now
	if clientTimestamp and type(clientTimestamp) == "number" then
		local pingDelta = math.clamp(now - clientTimestamp, 0, FlyingSwordConfig.CC.MaxPingTolerance)
		clampedStart = now - pingDelta
	end

	state.IsBlocking = true
	state.BlockStartTime = clampedStart
	state.ActionState = "Blocking"

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
	state.LastBlockReleaseTime = Workspace:GetServerTimeNow()
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

function CombatStateManager.ExecuteDash(player: Player, payload: any)
	local state = playerStates[player]
	if not state or state.CCState == "Stunned" or state.CCState == "GuardBroken" or state.CCState == "Staggered" then
		return
	end

	local now = Workspace:GetServerTimeNow()
	local lastDash = state.Cooldowns["Shift"] or 0
	if (now - lastDash) < FlyingSwordConfig.Skills.Shift.Cooldown then return end

	state.Cooldowns["Shift"] = now
	state.ActionState = "Dashing"
	state.IFrameEndTime = now + FlyingSwordConfig.CC.IFrameDuration

	if FlyingSwordConfig.DASH_CANCELS_M1 then
		state.M1Step = 0
		state.LastM1Time = 0
	end

	task.delay(0.30, function()
		if state.ActionState == "Dashing" then
			state.ActionState = "Idle"
		end
	end)

	combatActionRemote:FireAllClients(player, "Shift", payload)
end

function CombatStateManager.HandleStartChargeF(player: Player): boolean
	local state = playerStates[player]
	if not state or state.CCState == "Stunned" or state.CCState == "GuardBroken" or state.CCState == "Staggered" then
		return false
	end

	local cultMgr = getCultivationManager()
	local pData = if cultMgr then cultMgr.GetPlayerData(player) else nil
	if not pData then return false end

	local cultivatedCap = pData.CultivatedQi or 1000
	local costPercent = (FlyingSwordConfig.Skills.F and FlyingSwordConfig.Skills.F.QiCostPercent) or 0.20
	local requiredQi = math.floor(cultivatedCap * costPercent)

	if (pData.CurrentQi or 0) < requiredQi then
		return false
	end

	state.ActionState = "ChargingF"
	state.RecoveryEndTime = 0

	local FlyingSwordServer = getFlyingSwordServer()
	FlyingSwordServer.StartChargeF(player)
	return true
end

function CombatStateManager.HandleSkillRequest(player: Player, skillKey: string, payload: any?): boolean
	local state = playerStates[player]
	if not state then return false end

	local character = player.Character
	if not character then return false end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end

	if state.CCState == "Stunned" or state.CCState == "GuardBroken" or state.CCState == "Staggered" then
		return false
	end

	if skillKey == "F" and state.ActionState == "ChargingF" then
		-- Allowed
	elseif skillKey == "M1" then
		-- Allowed: chains seamlessly
	elseif state.ActionState == "Windup" or state.ActionState == "Active" or state.ActionState == "Recovery" then
		return false
	end

	if character:GetAttribute("IsFlying") == true then
		local WeaponManager = getWeaponManager()
		WeaponManager.ToggleFlight(player)
	end

	local now = Workspace:GetServerTimeNow()
	local targetStep = 1

	if skillKey == "M1" then
		local timeSinceLastM1 = now - (state.LastM1Time or 0)
		local lastStep = state.M1Step or 0

		-- Finisher recovery lockout check on server
		if lastStep == 5 then
			local finisherCd = (FlyingSwordConfig.M1Combo[5] and FlyingSwordConfig.M1Combo[5].Cooldown or 2.20) * 0.72
			if timeSinceLastM1 < finisherCd then
				return false
			else
				targetStep = 1
			end
		elseif timeSinceLastM1 <= (FlyingSwordConfig.SERVER_COMBO_TIMEOUT or 1.2) and lastStep >= 1 and lastStep < 5 then
			targetStep = lastStep + 1
		else
			targetStep = 1
		end

		local stepData = FlyingSwordConfig.M1Combo[targetStep] or FlyingSwordConfig.M1Combo[1]
		local cdDuration = (stepData.Cooldown or 0.30) * 0.72
		local lastUsed = state.Cooldowns["M1"] or 0
		if (now - lastUsed) < cdDuration then return false end
	elseif FlyingSwordConfig.Skills[skillKey] then
		local cdDuration = FlyingSwordConfig.Skills[skillKey].Cooldown or 1.0
		local lastUsed = state.Cooldowns[skillKey] or 0
		if (now - lastUsed) < cdDuration then return false end
	end

	local WeaponManager = getWeaponManager()
	if WeaponManager.GetWeaponState(player) == "Back" then
		WeaponManager.SetWeaponState(player, "Hand")
	end

	if skillKey ~= "M1" then
		local cultMgr = getCultivationManager()
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

	if skillKey == "M1" then
		state.M1Step = targetStep
		state.LastM1Time = now
	end

	state.Cooldowns[skillKey] = now
	state.ActiveStrike = { SkillKey = skillKey, StartTime = now }
	state.ActionState = "Active"

	CombatStateManager.TagInCombat(player)

	local activeTime = 0.24
	local recoveryTime = 0.06
	if skillKey == "M1" then
		local timing = FlyingSwordConfig.GetM1Timing(targetStep)
		activeTime = timing.ActiveTime
		recoveryTime = timing.RecoveryTime
	elseif FlyingSwordConfig.Skills[skillKey] then
		activeTime = (FlyingSwordConfig.Skills[skillKey].CastDuration or 0.50) * 0.5
		recoveryTime = FlyingSwordConfig.Skills[skillKey].Recovery or 0.2
	end

	state.ActiveEndTime = now + activeTime
	state.RecoveryEndTime = now + activeTime + recoveryTime

	local attackPayload = payload
	if skillKey == "M1" then
		if typeof(payload) == "table" then
			attackPayload = table.clone(payload)
			attackPayload.ComboIndex = targetStep
		else
			attackPayload = { ComboIndex = targetStep }
		end
	end

	local FlyingSwordServer = getFlyingSwordServer()
	attackPayload = FlyingSwordServer.ExecuteAttack(player, skillKey, attackPayload)

	combatActionRemote:FireAllClients(player, skillKey, attackPayload)

	return true
end

return CombatStateManager