--!strict
--[[
    HitboxManager.luau
    Location: src/ServerScriptService/Server/Combat/HitboxManager.luau
    Authoritative hit detection, server validation, safe zone peace protection,
    and wilderness Karmic Retribution griefing reflections.
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type HitResult = {
	HitPart: BasePart,
	Character: Model,
	Humanoid: Humanoid,
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
local combatActionRemote: RemoteEvent
local arenaManagerRef: any = nil

local function getArenaManager(): any
	if not arenaManagerRef then
		arenaManagerRef = require(ServerScriptService.Server.Combat.ArenaManager)
	end
	return arenaManagerRef
end

function HitboxManager.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
end

function HitboxManager.PerformHitboxCheck(
	attacker: Player,
	boxSize: Vector3,
	offset: CFrame,
	ignoreList: { Instance }?
): { HitResult }
	local character = attacker.Character
	if not character then return {} end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return {} end

	local hitboxCFrame = hrp.CFrame * offset

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local excludes = { character }
	if ignoreList then
		for _, inst in ipairs(ignoreList) do
			table.insert(excludes, inst)
		end
	end
	overlapParams.FilterDescendantsInstances = excludes

	local parts = Workspace:GetPartBoundsInBox(hitboxCFrame, boxSize, overlapParams)
	local hitResults: { HitResult } = {}
	local hitCharacters: { [Model]: boolean } = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		if model and not hitCharacters[model] then
			local humanoid = model:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				hitCharacters[model] = true
				local targetPlayer = Players:GetPlayerFromCharacter(model)
				table.insert(hitResults, {
					HitPart = part,
					Character = model,
					Humanoid = humanoid,
					TargetPlayer = targetPlayer,
				})
			end
		end
	end

	return hitResults
end

function HitboxManager.ApplyCombatResolution(
	attackerPlayer: Player?,
	targetResult: HitResult,
	rawDamage: number,
	postureDamage: number,
	knockbackVector: Vector3?
): HitResolution
	local targetChar = targetResult.Character
	local humanoid = targetResult.Humanoid
	local targetPlayer = targetResult.TargetPlayer
	local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?

	local attackerChar = if attackerPlayer then attackerPlayer.Character else nil
	local attackerHrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local arenaMgr = getArenaManager()

	-- PVP & SAFE ZONE RESOLUTION
	if targetChar and targetHrp then
		local areDueling = (attackerPlayer and targetPlayer) and arenaMgr and arenaMgr.AreDueling(attackerPlayer, targetPlayer)

		if areDueling then
			-- 1. SPARRING DUEL DAMAGE (Non-Lethal Clamp at 1 HP)
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
			-- 2. SECT SAFE ZONE PEACE CHECK (Zero damage on Sect grounds)
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

			-- 3. WILDERNESS KARMIC RETRIBUTION CHECK (Griefing Penalty)
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

	-- Check target Invulnerability / I-Frames
	local isIframe = targetChar:GetAttribute("IsInvulnerable") == true
	if isIframe then
		return {
			WasParried = false,
			WasBlocked = false,
			WasGuardBroken = false,
			WasIframeDodged = true,
			WasClashed = false,
			DamageApplied = 0,
		}
	end

	-- Evaluate Active Guard / Parry Window
	local isGuarding = targetChar:GetAttribute("IsGuarding") == true
	local parryWindowActive = targetChar:GetAttribute("ParryWindow") == true

	if isGuarding then
		if parryWindowActive then
			if attackerPlayer then
				CombatStateManager.ApplyPostureDamage(attackerPlayer, 25)
				CombatStateManager.SetStunned(attackerPlayer, 0.8)
			end
			if targetPlayer then
				CombatStateManager.RestorePostureOnParry(targetPlayer)
			end

			combatActionRemote:FireAllClients(nil, "PerfectParryVFX", {
				Position = targetResult.HitPart.Position,
			})

			return {
				WasParried = true,
				WasBlocked = false,
				WasGuardBroken = false,
				WasIframeDodged = false,
				WasClashed = false,
				DamageApplied = 0,
			}
		else
			-- Standard Block
			local guardBroken = false
			if targetPlayer then
				guardBroken = CombatStateManager.ApplyPostureDamage(targetPlayer, postureDamage)
			end

			local chipDamage = rawDamage * 0.15
			humanoid:TakeDamage(chipDamage)

			combatActionRemote:FireAllClients(nil, "BlockVFX", {
				Position = targetResult.HitPart.Position,
			})

			return {
				WasParried = false,
				WasBlocked = true,
				WasGuardBroken = guardBroken,
				WasIframeDodged = false,
				WasClashed = false,
				DamageApplied = chipDamage,
			}
		end
	end

	-- Full Hit Landed
	humanoid:TakeDamage(rawDamage)

	if targetPlayer then
		CombatStateManager.ApplyPostureDamage(targetPlayer, postureDamage)
		CombatStateManager.SetStunned(targetPlayer, 0.35)
	end

	if knockbackVector and targetResult.Character.PrimaryPart then
		targetResult.Character.PrimaryPart.AssemblyLinearVelocity = knockbackVector
	end

	return {
		WasParried = false,
		WasBlocked = false,
		WasGuardBroken = false,
		WasIframeDodged = false,
		WasClashed = false,
		DamageApplied = rawDamage,
	}
end

return HitboxManager