--!strict
--[[
    FlyingSwordServer.luau
    Location: src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
    Server-side combat handler for Flying Sword weapon attacks,
    M1 combo strings, M2 heavy slam, and special skills with dynamic Realm Damage Scaling.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

local FlyingSwordServer = {}

-- Player M1 combo tracking: [Player] -> { Step = number, LastTime = number }
local playerCombos: { [Player]: { Step: number, LastTime: number } } = {}

function FlyingSwordServer.ExecuteAttack(player: Player, skillKey: string, payload: any?): any?
	-- Reject combat executions on server if player is currently meditating
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then
		return payload
	end

	local character = player.Character
	if not character then return payload end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return payload end

	local hits, damage
	if skillKey == "M1" then
		hits, damage = FlyingSwordServer.ExecuteM1Combo(player, hrp)
	else
		hits, damage = FlyingSwordServer.ExecuteSkill(player, skillKey, hrp, payload)
	end

	payload = payload or {}
	payload.WeaponType = "FlyingSword"

	if hits and #hits > 0 then
		local firstHit = hits[1]
		payload.Damage = damage
		payload.TargetPosition = firstHit.HitPart.Position
	end

	return payload
end

function FlyingSwordServer.ExecuteM1Combo(player: Player, hrp: BasePart): ({ HitboxManager.HitResult }, number)
	local now = os.clock()
	local comboData = playerCombos[player] or { Step = 1, LastTime = 0 }

	if now - comboData.LastTime > 1.2 then
		comboData.Step = 1
	end

	local currentStepData = FlyingSwordConfig.M1Combo[comboData.Step]
	if not currentStepData then
		comboData.Step = 1
		currentStepData = FlyingSwordConfig.M1Combo[1]
	end

	local pData = CultivationManager.GetPlayerData(player)
	local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
	local finalDamage = math.floor(currentStepData.Damage * powerMult)

	local hitboxCFrame = hrp.CFrame * CFrame.new(currentStepData.Offset)
	local hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, currentStepData.Range)

	for _, hit in ipairs(hits) do
		HitboxManager.ApplyDamageAndKnockback(player, hit, finalDamage, currentStepData.Knockback)
	end

	comboData.Step = if comboData.Step >= 4 then 1 else comboData.Step + 1
	comboData.LastTime = now
	playerCombos[player] = comboData

	return hits, finalDamage
end

function FlyingSwordServer.ExecuteSkill(player: Player, skillKey: string, hrp: BasePart, payload: any?): ({ HitboxManager.HitResult }, number)
	local skillData = FlyingSwordConfig.Skills[skillKey]
	if not skillData then return {}, 0 end

	local pData = CultivationManager.GetPlayerData(player)
	local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
	local finalDamage = math.floor(skillData.Damage * powerMult)

	local hits = {}
	if finalDamage > 0 then
		local hitboxCFrame = hrp.CFrame * CFrame.new(skillData.Offset)
		hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, skillData.Range)

		for _, hit in ipairs(hits) do
			HitboxManager.ApplyDamageAndKnockback(player, hit, finalDamage, skillData.Knockback)
		end
	end

	return hits, finalDamage
end

return FlyingSwordServer