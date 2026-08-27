--!strict
--[[
    HitboxManager.luau
    Location: src/ServerScriptService/Server/Combat/HitboxManager.luau
    Authoritative spatial engine with Velocity Lag Compensation,
    I-Frame checks, Posture/Guard-Break resolution, and Sword Clashes.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HitboxManager = {}
local combatVFXRemote: RemoteEvent? = nil

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

local function GetRemotes()
	if not combatVFXRemote then
		combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	end
end

-- Box Hitbox with Target Velocity Compensation
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

function HitboxManager.ApplyCombatResolution(
	attackerPlayer: Player,
	targetResult: HitResult,
	rawDamage: number,
	postureDamage: number,
	knockbackVector: Vector3?
): HitResolution
	GetRemotes()
	local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
	local targetChar = targetResult.Character
	local humanoid = targetResult.Humanoid
	local targetHrp = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerChar = attackerPlayer.Character
	local attackerHrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local targetPlayer = targetResult.TargetPlayer
	local targetState = if targetPlayer then CombatStateManager.GetState(targetPlayer) else nil
	local attackerState = CombatStateManager.GetState(attackerPlayer)

	local now = os.clock()

	-- 1. I-Frame Dodge Check
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

	-- 2. Sword Clash Check (Simultaneous strikes within 0.08s window)
	if targetState and targetState.ActiveStrike and (now - targetState.ActiveStrike.StartTime) <= FlyingSwordConfig.CC.ClashWindow then
		if targetHrp and attackerHrp then
			local dot = targetHrp.CFrame.LookVector:Dot(attackerHrp.CFrame.LookVector)
			if dot < -0.3 then -- Facing each other
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

	-- 3. Guard & Perfect Parry Resolution
	if targetState and targetState.IsBlocking and targetHrp and attackerHrp then
		local toAttacker = (attackerHrp.Position - targetHrp.Position).Unit
		local dot = targetHrp.CFrame.LookVector:Dot(toAttacker)

		if dot >= 0 then -- Front 180-degree guard arc
			local parryWindow = FlyingSwordConfig.Posture.ParryWindow
			local blockElapsed = now - targetState.BlockStartTime

			if blockElapsed <= parryWindow then
				-- =============================================================
				-- PERFECT PARRY
				-- =============================================================
				wasParried = true
				finalDamage = 0
				finalKnockback = nil

				-- Attacker Stagger (Subject to CC-Immunity)
				CombatStateManager.ApplyCC(attackerPlayer, "Stunned", FlyingSwordConfig.Posture.ParryStunDuration)

				-- Defender Qi Reward (+5%)
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
				-- =============================================================
				-- STANDARD BLOCK (POSTURE DRAIN & GUARD-BREAK)
				-- =============================================================
				targetState.Posture = targetState.Posture - postureDamage
				targetChar:SetAttribute("Posture", math.max(0, math.floor(targetState.Posture)))

				if targetState.Posture <= 0 then
					-- GUARD BREAK!
					wasGuardBroken = true
					targetState.Posture = 30 -- Reset small buffer
					CombatStateManager.ApplyCC(targetPlayer, "GuardBroken", FlyingSwordConfig.Posture.GuardBreakStunDuration)
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

	-- Apply Damage (Tag both in combat)
	if finalDamage > 0 then
		humanoid:TakeDamage(finalDamage)
		CombatStateManager.TagInCombat(attackerPlayer)
		if targetPlayer then
			CombatStateManager.TagInCombat(targetPlayer)
		else
			-- Target has no controlling player (a mob/NPC) — record who actually damaged it
			-- so MobAIManager can credit the correct killer instead of guessing.
			local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)
			MobAIManager.RegisterDamage(targetChar, attackerPlayer, finalDamage)
		end
	end

	-- Apply Physical Knockback
	if finalKnockback and targetHrp and finalKnockback.Magnitude > 0 then
		local orientation = if attackerHrp then attackerHrp.CFrame else CFrame.new()
		local worldKnockback = orientation:VectorToWorldSpace(finalKnockback)

		local attachment = Instance.new("Attachment")
		attachment.Parent = targetHrp

		local linearVel = Instance.new("LinearVelocity")
		linearVel.Attachment0 = attachment
		linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		linearVel.MaxAxesForce = Vector3.new(250000, 100000, 250000)
		linearVel.VectorVelocity = worldKnockback
		linearVel.Parent = targetHrp

		task.delay(0.15, function()
			linearVel:Destroy()
			attachment:Destroy()
		end)
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