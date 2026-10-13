--!strict
--[[
    HitboxManager.luau
    Location: src/ServerScriptService/Server/Combat/HitboxManager.luau
    Authoritative server-side spatial query & combat resolution module.
    Updates:
      - Always triggers floating damage numbers on player when attacked by mobs/monsters.
      - Auto-detects World CFrame vs Local Offset in CastCompensatedBox.
      - Restricts Karmic Retribution strictly to PVP (players vs players).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local MonsterUtil = require(ReplicatedStorage.Shared.Utils.MonsterUtil)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)

export type HitResult = {
	Character: Model,
	Humanoid: Humanoid?,
	HitPart: BasePart,
	TargetPlayer: Player?,
	IsMonster: boolean?,
}

export type ResolutionResult = {
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

local function GetRemotes()
	if not combatVFXRemote then
		combatVFXRemote = RemoteEvents.GetRemote("CombatVFX") :: RemoteEvent?
	end
	if not combatActionRemote then
		combatActionRemote = RemoteEvents.GetRemote("CombatAction") :: RemoteEvent?
	end
end

local function GetRealmTier(realmName: string?): number
	if not realmName then return 1 end
	local def = (CultivationConfig :: any)[realmName]
	if def and typeof(def) == "table" and def.Tier then
		return def.Tier
	end
	return 1
end

-- =============================================================================
-- 1. SPATIAL QUERIES
-- =============================================================================

function HitboxManager.CastCompensatedBox(
	attacker: Model,
	offsetOrWorldCFrame: CFrame,
	size: Vector3,
	options: any?
): any
	local rootPart = attacker.PrimaryPart or attacker:FindFirstChild("HumanoidRootPart") or MonsterUtil.GetRootPart(attacker)
	if not rootPart or not rootPart:IsA("BasePart") then
		return {}
	end

	local worldCFrame: CFrame
	local distToRoot = (offsetOrWorldCFrame.Position - rootPart.Position).Magnitude
	if distToRoot < 45 and offsetOrWorldCFrame.Position.Magnitude > 10 then
		worldCFrame = offsetOrWorldCFrame
	else
		worldCFrame = rootPart.CFrame * offsetOrWorldCFrame
	end

	local overlapParams = OverlapParams.new()
	local filter: { Instance } = { attacker }
	if options then
		if options.FilterDescendants and typeof(options.FilterDescendants) == "table" then
			for _, inst in ipairs(options.FilterDescendants) do
				table.insert(filter, inst)
			end
		elseif typeof(options) == "table" and not options.FilterDescendants then
			for _, inst in ipairs(options) do
				if typeof(inst) == "Instance" then
					table.insert(filter, inst)
				end
			end
		end
	end
	overlapParams.FilterDescendantsInstances = filter
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local partsInBox = Workspace:GetPartBoundsInBox(worldCFrame, size, overlapParams)
	local results: any = {}
	local hitCharacters = {}

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
					IsMonster = false,
				})
			elseif MonsterUtil.IsMonster(model) then
				local mHealth = MonsterUtil.GetHealth(model)
				if mHealth > 0 then
					hitCharacters[model] = true
					table.insert(results, {
						Character = model,
						Humanoid = nil,
						HitPart = part,
						TargetPlayer = nil,
						IsMonster = true,
					})
				end
			end
		end
	end

	if results[1] then
		results.Character = results[1].Character
		results.Humanoid = results[1].Humanoid
		results.HitPart = results[1].HitPart
		results.TargetPlayer = results[1].TargetPlayer
		results.IsMonster = results[1].IsMonster
	end

	return results
end

-- =============================================================================
-- 2. COMBAT RESOLUTION PIPELINE
-- =============================================================================

function HitboxManager.ApplyCombatResolution(
	arg1: any,
	arg2: any,
	arg3: any?,
	arg4: any?,
	arg5: any?,
	arg6: any?,
	arg7: any?
): ResolutionResult
	local attackerPlayer: Player? = nil
	local targetResult: HitResult
	local rawDamage: number = 10
	local postureDamage: number = 10
	local rawKnockback: Vector3 = Vector3.zero
	local attackerCharOverride: Model? = nil
	local attackType: string? = nil

	if typeof(arg1) == "table" and (arg1.Character or arg1.Humanoid or arg1.IsMonster ~= nil) then
		targetResult = arg1 :: HitResult
		rawDamage = (arg2 :: number?) or 10
		postureDamage = (arg3 :: number?) or 10
		rawKnockback = (arg4 :: Vector3?) or Vector3.zero
		attackerPlayer = arg5 :: Player?
		attackType = arg6 :: string?
		attackerCharOverride = arg7 :: Model?
	else
		attackerPlayer = arg1 :: Player?
		targetResult = arg2 :: HitResult
		rawDamage = (arg3 :: number?) or 10
		postureDamage = (arg4 :: number?) or 10
		rawKnockback = (arg5 :: Vector3?) or Vector3.zero
		attackerCharOverride = arg6 :: Model?
		attackType = arg7 :: string?
	end

	if not targetResult or typeof(targetResult) ~= "table" or not targetResult.Character then
		return {
			WasParried = false,
			WasBlocked = false,
			WasGuardBroken = false,
			WasIframeDodged = false,
			WasClashed = false,
			DamageApplied = 0,
		}
	end

	GetRemotes()

	local targetChar = targetResult.Character
	local humanoid = targetResult.Humanoid
	local targetHrp = (targetChar:FindFirstChild("HumanoidRootPart") or MonsterUtil.GetRootPart(targetChar)) :: BasePart?

	local attackerChar = if attackerCharOverride then attackerCharOverride else (if attackerPlayer then attackerPlayer.Character else nil)
	local attackerHrp = if attackerChar then (attackerChar:FindFirstChild("HumanoidRootPart") or MonsterUtil.GetRootPart(attackerChar) or attackerChar.PrimaryPart) :: BasePart? else nil
	local targetPlayer = targetResult.TargetPlayer

	local successArena, arenaMgr = pcall(function()
		return require(ServerScriptService.Server.Combat.ArenaManager)
	end)

	-- A. PVP, SPARRING & SAFE ZONE RESOLUTION
	if targetChar and targetHrp then
		local areDueling = humanoid and (attackerPlayer and targetPlayer) and successArena and arenaMgr and arenaMgr.AreDueling(attackerPlayer, targetPlayer)

		if areDueling and humanoid then
			local currentHp = humanoid.Health
			if (currentHp - rawDamage) <= 15 then
				arenaMgr.ConcedeMatch(targetPlayer, attackerPlayer)
				return {
					WasParried = false,
					WasBlocked = false,
					WasGuardBroken = false,
					WasIframeDodged = false,
					WasClashed = false,
					DamageApplied = 0,
				}
			end
		end

		local inSafeZone = successArena and arenaMgr and (arenaMgr.IsInSafeZone(targetHrp.Position) or (attackerHrp and arenaMgr.IsInSafeZone(attackerHrp.Position)))
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

		-- Karmic Retribution: Strictly PVP
		if attackerPlayer and targetPlayer and humanoid then
			local aRealm = attackerChar:GetAttribute("CultivationRealm") or "QiCondensation"
			local tRealm = targetChar:GetAttribute("CultivationRealm") or "QiCondensation"
			local aTier = GetRealmTier(aRealm)
			local tTier = GetRealmTier(tRealm)

			if aTier >= (tTier + 2) then
				local penalizedDamage = math.floor(rawDamage * 0.25)
				local reflectedBacklash = math.floor(rawDamage * 0.50)

				attackerChar:SetAttribute("KarmicRetribution", true)
				local attackerHum = attackerChar:FindFirstChildOfClass("Humanoid")
				if attackerHum then
					attackerHum:TakeDamage(reflectedBacklash)
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

	-- B. I-Frame Dodge Check
	local isInvulnerable = targetChar:GetAttribute("Invulnerable") == true
	if isInvulnerable then
		return {
			WasParried = false,
			WasBlocked = false,
			WasGuardBroken = false,
			WasIframeDodged = true,
			WasClashed = false,
			DamageApplied = 0,
		}
	end

	-- C. Clash Detection
	local targetActionState = targetChar:GetAttribute("ActionState")
	local targetIsAttacking = (targetActionState == "Attacking" or targetActionState == "M1Attack")
	local attackerActionState = if attackerChar then attackerChar:GetAttribute("ActionState") else nil
	local attackerIsAttacking = (attackerActionState == "Attacking" or attackerActionState == "M1Attack")

	if targetIsAttacking and attackerIsAttacking and attackType == "LightAttack" then
		if combatVFXRemote and targetHrp then
			combatVFXRemote:FireAllClients({
				EffectType = "WeaponClash",
				Position = targetHrp.Position + Vector3.new(0, 1, 0),
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

	-- D. Guard & Perfect Parry Resolution
	local isBlocking = targetChar:GetAttribute("IsBlocking") == true
	local isParryWindow = targetChar:GetAttribute("IsParrying") == true
	local finalDamage = rawDamage
	local finalKnockback = rawKnockback
	local wasParried = false
	local wasBlocked = false
	local wasGuardBroken = false

	if isParryWindow then
		wasParried = true
		finalDamage = 0
		finalKnockback = Vector3.zero

		if combatVFXRemote and targetHrp then
			combatVFXRemote:FireAllClients({
				EffectType = "ParryClash",
				Position = targetHrp.Position + Vector3.new(0, 1.5, 0),
			})
		end

		if attackerPlayer then
			CombatStateManager.ApplyStun(attackerPlayer, FlyingSwordConfig.Posture.ParryStunDuration)
			if combatActionRemote then
				combatActionRemote:FireClient(attackerPlayer, nil, "ParryStunned", {
					Duration = FlyingSwordConfig.Posture.ParryStunDuration,
				})
			end
		elseif attackerChar then
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
			else
				MonsterUtil.SetStunned(attackerChar, true, FlyingSwordConfig.Posture.ParryStunDuration)
			end
		end

		return {
			WasParried = true,
			WasBlocked = false,
			WasGuardBroken = false,
			WasIframeDodged = false,
			WasClashed = false,
			DamageApplied = 0,
		}
	elseif isBlocking then
		local currentPosture = targetChar:GetAttribute("Posture") or FlyingSwordConfig.Posture.MaxPosture
		local postureDrain = postureDamage or FlyingSwordConfig.Posture.BlockCost

		if (currentPosture - postureDrain) <= 0 then
			wasGuardBroken = true
			targetChar:SetAttribute("Posture", 0)
			finalDamage = math.floor(rawDamage * (1 + FlyingSwordConfig.Posture.GuardBreakBonusDamagePercent))

			if targetPlayer then
				CombatStateManager.ApplyStun(targetPlayer, FlyingSwordConfig.Posture.GuardBreakStunDuration)
				if combatActionRemote then
					combatActionRemote:FireClient(targetPlayer, nil, "GuardBroken", {
						Duration = FlyingSwordConfig.Posture.GuardBreakStunDuration,
					})
				end
			end
		else
			wasBlocked = true
			targetChar:SetAttribute("Posture", currentPosture - postureDrain)
			finalDamage = math.floor(rawDamage * (1 - FlyingSwordConfig.Posture.BlockDamageMitigationPercent))
			finalKnockback = finalKnockback * 0.25

			if combatVFXRemote and targetHrp then
				combatVFXRemote:FireAllClients({
					EffectType = "BlockSparks",
					Position = targetHrp.Position + Vector3.new(0, 1, 0),
				})
			end
		end
	end

	-- D2. Monster Posture Damage & Guard Break Resolution
	if (targetResult.IsMonster or not humanoid) and targetChar then
		local _, wasBroken = MonsterUtil.DamagePosture(targetChar, postureDamage)
		if wasBroken then
			wasGuardBroken = true
			MonsterUtil.SetStunned(targetChar, true, FlyingSwordConfig.Posture.GuardBreakStunDuration or 1.8)
			finalDamage = math.floor(rawDamage * (1 + (FlyingSwordConfig.Posture.GuardBreakBonusDamagePercent or 0.25)))
			if combatVFXRemote and targetHrp then
				combatVFXRemote:FireAllClients({
					EffectType = "ParryClash",
					Position = targetHrp.Position + Vector3.new(0, 1.5, 0),
				})
			end
		end
	end

	-- E. Apply Damage & Broadcast Floating Number on Victim
	if finalDamage > 0 then
		if humanoid then
			humanoid:TakeDamage(finalDamage)
		else
			MonsterUtil.TakeDamage(targetChar, finalDamage)
		end

		-- Floating damage number broadcast for all hits (including mob-on-player)
		if combatVFXRemote and targetHrp then
			combatVFXRemote:FireAllClients({
				EffectType = "DamageNumber",
				Position = targetHrp.Position + Vector3.new(0, 2.2, 0),
				Damage = finalDamage,
				IsCrit = (attackType == "Crit"),
			})
		end

		if attackerPlayer then
			CombatStateManager.TagInCombat(attackerPlayer)
		end

		if targetPlayer then
			CombatStateManager.TagInCombat(targetPlayer)
		elseif humanoid then
			local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)
			MobAIManager.RegisterDamage(targetChar, attackerPlayer, finalDamage)
		else
			local success, monsterAIManager = pcall(function()
				return require(ServerScriptService.Server.Combat.MonsterAIManager)
			end)
			if success and monsterAIManager and monsterAIManager.RegisterDamage then
				monsterAIManager.RegisterDamage(targetChar, attackerPlayer, finalDamage)
			end
		end
	end

	-- F. Flat Knockback
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