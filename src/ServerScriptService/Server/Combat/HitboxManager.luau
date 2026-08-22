--!strict
--[[
    HitboxManager.luau
    Location: src/ServerScriptService/Server/Combat/HitboxManager.luau
    Server-authoritative spatial query engine with Block & Perfect Parry defense resolution.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HitboxManager = {}
local combatVFXRemote: RemoteEvent? = nil
local combatActionRemote: RemoteEvent? = nil

local function GetRemotes()
	if not combatVFXRemote then
		combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	end
	if not combatActionRemote then
		combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	end
end

export type HitResult = {
	Character: Model,
	Humanoid: Humanoid,
	HitPart: BasePart,
	TargetPlayer: Player?,
}

export type HitResolution = {
	WasParried: boolean,
	WasBlocked: boolean,
	DamageApplied: number,
}

function HitboxManager.CastBoxHitbox(
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

function HitboxManager.ApplyDamageAndKnockback(
	attackerPlayer: Player,
	targetResult: HitResult,
	damage: number,
	knockbackVector: Vector3?
): HitResolution
	GetRemotes()
	local humanoid = targetResult.Humanoid
	local targetChar = targetResult.Character
	local targetHrp = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	local attackerChar = attackerPlayer.Character
	local attackerHrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local isTargetBlocking = targetChar:GetAttribute("IsBlocking") == true
	local blockStartTime = targetChar:GetAttribute("BlockStartTime") or 0
	local now = os.clock()

	local wasParried = false
	local wasBlocked = false
	local finalDamage = damage
	local finalKnockback = knockbackVector

	if isTargetBlocking and targetHrp and attackerHrp then
		local toAttacker = (attackerHrp.Position - targetHrp.Position).Unit
		local lookVec = targetHrp.CFrame.LookVector
		local dot = lookVec:Dot(toAttacker)

		-- Front 180-degree blocking arc
		if dot >= 0 then
			local parryWindow = FlyingSwordConfig.Block.ParryWindow
			if (now - blockStartTime) <= parryWindow then
				-- =============================================================
				-- 1. PERFECT PARRY TRIGGERED
				-- =============================================================
				wasParried = true
				finalDamage = 0
				finalKnockback = nil

				-- Attacker Posture Stagger / Mini-Stun
				local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
				CombatStateManager.ApplyStun(attackerPlayer, FlyingSwordConfig.Block.ParryStunDuration)

				-- Target Qi Reward (+5% CultivatedQi)
				if targetResult.TargetPlayer then
					local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
					local pData = CultivationManager.GetPlayerData(targetResult.TargetPlayer)
					if pData then
						local qiGain = math.floor(pData.CultivatedQi * FlyingSwordConfig.Block.ParryQiRestorePercent)
						CultivationManager.AddInternalQi(targetResult.TargetPlayer, qiGain)
					end
				end

				-- Broadcast Parry Deflection Clash VFX & SFX
				if combatVFXRemote then
					combatVFXRemote:FireAllClients({
						EffectType = "ParryClash",
						Position = targetHrp.Position + (lookVec * 2) + Vector3.new(0, 1, 0),
						Attacker = attackerPlayer,
						Defender = targetResult.TargetPlayer,
					})
				end
			else
				-- =============================================================
				-- 2. STANDARD BLOCK
				-- =============================================================
				wasBlocked = true
				finalDamage = math.floor(damage * (1 - FlyingSwordConfig.Block.DamageReduction))
				if finalKnockback then
					finalKnockback = finalKnockback * 0.3
				end

				if combatVFXRemote then
					combatVFXRemote:FireAllClients({
						EffectType = "BlockSparks",
						Position = targetHrp.Position + (lookVec * 2) + Vector3.new(0, 1, 0),
					})
				end
			end
		end
	end

	-- Apply Damage
	if finalDamage > 0 then
		humanoid:TakeDamage(finalDamage)
	end

	-- Apply Knockback
	if finalKnockback and targetHrp and finalKnockback.Magnitude > 0 then
		local orientation = if attackerHrp then attackerHrp.CFrame else CFrame.new()
		local worldKnockback = orientation:VectorToWorldSpace(finalKnockback)

		local attachment = Instance.new("Attachment")
		attachment.Parent = targetHrp

		local vectorVelocity = Instance.new("LinearVelocity")
		vectorVelocity.Attachment0 = attachment
		vectorVelocity.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		vectorVelocity.MaxAxesForce = Vector3.new(150000, 100000, 150000)
		vectorVelocity.VectorVelocity = worldKnockback
		vectorVelocity.Parent = targetHrp

		task.delay(0.15, function()
			vectorVelocity:Destroy()
			attachment:Destroy()
		end)
	end

	return {
		WasParried = wasParried,
		WasBlocked = wasBlocked,
		DamageApplied = finalDamage,
	}
end

return HitboxManager