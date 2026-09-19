--!strict
--[[
    HitboxManager.luau
    Location: src/ServerScriptService/Server/Combat/HitboxManager.luau
    Authoritative hit detection & combat resolution:
    Phase 1 Updates:
      - E1 & E2: Supports attackerCharOverride for mobs, allowing players to block,
        parry, and dodge mob attacks through the unified combat pipeline.
      - Parrying a mob stuns the beast for 1.2s and restores Qi to the player.
      - A1: Victim knockback routed to owning client with zero Freefall Y launch.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)

export type HitResult = {
	Character: Model,
	Humanoid: Humanoid,
	HitPart: BasePart,
	TargetPlayer: Player?,
}

export type HitResolution = {
	WasParried: boolean,
	WasBlocked: boolean,
	WasGuardBroken: boolean,
	WasIframeDodged: boolean,
	WasClashed: boolean,
	DamageApplied: number,
}

local HitboxManager = {}
local combatVFXRemote: RemoteEvent? = nil
local combatActionRemote: RemoteEvent? = nil
local arenaManagerRef: any = nil

local function GetRemotes()
	if not combatVFXRemote then
		combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	end
	if not combatActionRemote then
		combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	end
end

local function getArenaManager(): any
	if not arenaManagerRef then
		arenaManagerRef = require(ServerScriptService.Server.Combat.ArenaManager)
	end
	return arenaManagerRef
end

function HitboxManager.Init()
	GetRemotes()
end

function HitboxManager.CastCompensatedBox(
	attacker: Model,
	cframe: CFrame,
	size: Vector3,
	ignoreList: { Instance }?
): { HitResult }
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local filterInstances: { Instance } = { attacker }
	if ignoreList then
		for _, inst in ipairs(ignoreList) do
			table.insert(filterInstances, inst)
		end
	end
	overlapParams.FilterDescendantsInstances = filterInstances

	local partsInBox = Workspace:GetPartBoundsInBox(cframe, size, overlapParams)
	local hitCharacters: { [Model]: boolean } = {}
	local results: { HitResult } = {}

	for _, part in ipairs(partsInBox) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitCharacters[model] and model ~= attacker then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				hitCharacters[model] = true
				local targetPlayer = Players:GetPlayerFromCharacter(model)
				table.insert(results, {
					Character = model,
					Humanoid = humanoid,
					HitPart = part,
					TargetPlayer = targetPlayer,
				})
			end
		end
	end

	return results
end

-- =============================================================================
-- E1 & E2 FIX: SUPPORTS BOTH PLAYERS AND MOB ATTACKERS IN COMBAT RESOLUTION
-- =============================================================================
function HitboxManager.ApplyCombatResolution(
	attackerPlayer: Player?,
	targetResult: HitResult,
	rawDamage: number,
	postureDamage: number,
	knockbackVector: Vector3?,
	attackerCharOverride: Model?
): HitResolution
	GetRemotes()

	local targetChar = targetResult.Character
	local humanoid = targetResult.Humanoid
	local targetHrp = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?

	local attackerChar = if attackerCharOverride then attackerCharOverride else (if attackerPlayer then attackerPlayer.Character else nil)
	local attackerHrp = if attackerChar then (attackerChar:FindFirstChild("HumanoidRootPart") or attackerChar.PrimaryPart) :: BasePart? else nil

	local targetPlayer = targetResult.TargetPlayer
	local targetState = if targetPlayer then CombatStateManager.GetState(targetPlayer) else nil

	local now = Workspace:GetServerTimeNow()
	local arenaMgr = getArenaManager()

	-- A. PVP, SPARRING & SAFE ZONE RESOLUTION
	if targetChar and targetHrp then
		local areDueling = (attackerPlayer and targetPlayer) and arenaMgr and arenaMgr.AreDueling(attackerPlayer, targetPlayer)

		if areDueling then
			local currentHp = humanoid.Health
			local prospectiveHp = currentHp - rawDamage

			if prospectiveHp <= 1 then
				humanoid.Health = 1
				local session = arenaMgr.GetActiveDuel(attackerPlayer)
				if session and session.IsActive then
					arenaMgr.EndOnDemandDuel(session, attackerPlayer, "Sparring Knockdown Concession")
				end
				return {
					WasParried = false,
					WasBlocked = false,
					WasGuardBroken = false,
					WasIframeDodged = false,
					WasClashed = false,
					DamageApplied = currentHp - 1,
				}
			end
		elseif arenaMgr then
			local inSafeZone = arenaMgr.IsInSafeZone(targetHrp.Position) or (attackerHrp and arenaMgr.IsInSafeZone(attackerHrp.Position))
			if inSafeZone then
				return {
					WasParried = false,
					WasBlocked = false,
					WasGuardBroken = false,
					WasIframeDodged = false,
					WasClashed = false,
					DamageApplied = 0,
				}
			end

			local aRealm = (attackerChar and attackerChar:GetAttribute("CultivationRealm"))
				or (attackerPlayer and attackerPlayer:GetAttribute("CultivationRealm"))
				or "QiCondensation"

			local tRealm = (targetChar and targetChar:GetAttribute("CultivationRealm"))
				or (targetPlayer and targetPlayer:GetAttribute("CultivationRealm"))
				or "QiCondensation"

			local aTier = (CultivationConfig[aRealm] and CultivationConfig[aRealm].Tier) or 1
			local tTier = (CultivationConfig[tRealm] and CultivationConfig[tRealm].Tier) or 1

			if aTier >= (tTier + 2) then
				local penalizedDamage = math.floor(rawDamage * 0.25)
				local reflectedBacklash = math.floor(rawDamage * 0.50)

				if attackerChar then
					attackerChar:SetAttribute("KarmicRetribution", true)
					local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
					if attackerHum then
						attackerHum:TakeDamage(reflectedBacklash)
					end
				end

				humanoid:TakeDamage(penalizedDamage)
				return {
					WasParried = false,
					WasBlocked = false,
					WasGuardBroken = false,
					WasIframeDodged = false,
					WasClashed = false,
					DamageApplied = penalizedDamage,
				}
			end
		end
	end

	-- B. I-Frame Dodge Check (Dash Dodges Player & Mob Attacks)
	if targetState and now < targetState.IFrameEndTime then
		return {
			WasParried = false,
			WasBlocked = false,
			WasGuardBroken = false,
			WasIframeDodged = true,
			WasClashed = false,
			DamageApplied = 0,
		}
	end

	-- C. Sword Clash Check (Player vs Player)
	if attackerPlayer and targetState and targetState.ActiveStrike and (now - targetState.ActiveStrike.StartTime) <= FlyingSwordConfig.CC.ClashWindow then
		if targetHrp and attackerHrp then
			local dot = targetHrp.CFrame.LookVector:Dot(attackerHrp.CFrame.LookVector)
			if dot < -0.3 then
				if combatVFXRemote then
					combatVFXRemote:FireAllClients({
						EffectType = "ParryClash",
						Position = (attackerHrp.Position + targetHrp.Position) / 2 + Vector3.new(0, 1, 0),
					})
				end
				return {
					WasParried = false,
					WasBlocked = false,
					WasGuardBroken = false,
					WasIframeDodged = false,
					WasClashed = true,
					DamageApplied = 0,
				}
			end
		end
	end

	local wasParried = false
	local wasBlocked = false
	local wasGuardBroken = false
	local finalDamage = rawDamage
	local finalKnockback = knockbackVector

	-- D. Guard & Perfect Parry Resolution (Works Against Players and Mobs)
	if targetState and targetState.IsBlocking and targetHrp then
		local toAttacker = if attackerHrp then (attackerHrp.Position - targetHrp.Position).Unit else targetHrp.CFrame.LookVector
		local dot = targetHrp.CFrame.LookVector:Dot(toAttacker)

		if dot >= -0.25 then
			local parryWindow = FlyingSwordConfig.Posture.ParryWindow
			local blockElapsed = now - targetState.BlockStartTime

			if blockElapsed <= parryWindow then
				wasParried = true
				finalDamage = 0
				finalKnockback = nil

				if attackerPlayer then
					CombatStateManager.ApplyCC(attackerPlayer, "Stunned", FlyingSwordConfig.Posture.ParryStunDuration)
				elseif attackerChar then
					-- Parrying a mob stuns the beast for 1.2s
					attackerChar:SetAttribute("IsStunned", true)
					local mobHum = attackerChar:FindFirstChildOfClass("Humanoid")
					if mobHum then
						local prevSpeed = mobHum.WalkSpeed
						mobHum.WalkSpeed = 0
						task.delay(FlyingSwordConfig.Posture.ParryStunDuration, function()
							if attackerChar and attackerChar.Parent then
								attackerChar:SetAttribute("IsStunned", false)
								mobHum.WalkSpeed = prevSpeed
							end
						end)
					end
				end

				if targetPlayer then
					local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
					local pData = CultivationManager.GetPlayerData(targetPlayer)
					if pData then
						local qiGain = math.floor(pData.CultivatedQi * FlyingSwordConfig.Posture.ParryQiRestorePercent)
						CultivationManager.AddInternalQi(targetPlayer, qiGain)
					end
				end

				if combatVFXRemote then
					combatVFXRemote:FireAllClients({
						EffectType = "ParryClash",
						Position = targetHrp.Position + (targetHrp.CFrame.LookVector * 2) + Vector3.new(0, 1, 0),
					})
				end
			else
				targetState.Posture = targetState.Posture - postureDamage
				targetChar:SetAttribute("Posture", math.max(0, math.floor(targetState.Posture)))

				if targetState.Posture <= 0 then
					wasGuardBroken = true
					targetState.Posture = 30
					if targetPlayer then
						CombatStateManager.ApplyCC(targetPlayer, "GuardBroken", FlyingSwordConfig.Posture.GuardBreakStunDuration)
					end
					finalDamage = math.floor(rawDamage * (1 + FlyingSwordConfig.Posture.GuardBreakBonusDamagePercent))

					if combatVFXRemote then
						combatVFXRemote:FireAllClients({
							EffectType = "ParryClash",
							Position = targetHrp.Position + Vector3.new(0, 1.5, 0),
						})
					end
				else
					wasBlocked = true
					finalDamage = math.floor(rawDamage * (1 - FlyingSwordConfig.Posture.BlockDamageReduction))
					if finalKnockback then finalKnockback = finalKnockback * 0.3 end

					if combatVFXRemote then
						combatVFXRemote:FireAllClients({
							EffectType = "BlockSparks",
							Position = targetHrp.Position + (targetHrp.CFrame.LookVector * 2) + Vector3.new(0, 1, 0),
						})
					end
				end
			end
		end
	end

	-- E. Apply Damage & Tag Combat
	if finalDamage > 0 then
		humanoid:TakeDamage(finalDamage)
		if attackerPlayer then
			CombatStateManager.TagInCombat(attackerPlayer)
		end
		if targetPlayer then
			CombatStateManager.TagInCombat(targetPlayer)
		else
			local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)
			MobAIManager.RegisterDamage(targetChar, attackerPlayer, finalDamage)
		end
	end

	-- F. Flat Client-Side Knockback
	if finalKnockback and targetHrp and finalKnockback.Magnitude > 0 then
		local orientation = if attackerHrp then attackerHrp.CFrame else CFrame.lookAt(targetHrp.Position, targetHrp.Position - finalKnockback)
		local worldKnockback = orientation:VectorToWorldSpace(finalKnockback)
		local flatKnockback = Vector3.new(worldKnockback.X, 0, worldKnockback.Z).Unit * math.min(worldKnockback.Magnitude, 38)

		if targetPlayer then
			if combatActionRemote then
				combatActionRemote:FireClient(targetPlayer, attackerPlayer, "ApplyClientKnockback", {
					KnockbackVelocity = flatKnockback,
					Duration = 0.16,
				})
			end
		else
			local mass = targetHrp.AssemblyMass
			targetHrp:ApplyImpulse(flatKnockback * (mass * 0.85))
		end
	end

	return {
		WasParried = wasParried,
		WasBlocked = wasBlocked,
		WasGuardBroken = wasGuardBroken,
		WasIframeDodged = false,
		WasClashed = false,
		DamageApplied = finalDamage,
	}
end

return HitboxManager