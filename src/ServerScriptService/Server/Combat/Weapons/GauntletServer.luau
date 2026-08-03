--!strict
--[[
    GauntletServer.luau
    Location: src/ServerScriptService/Server/Combat/Weapons/GauntletServer.luau
    Server-side combat handler for Gauntlet martial arts weapon attacks,
    close-quarters Qi punches, 360° Hundred Palms, and Ground Slam shockwaves.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local GauntletConfig = require(ReplicatedStorage.Shared.Configs.Weapons.GauntletConfig)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)

local GauntletServer = {}

-- Player M1 combo tracking: [Player] -> { Step = number, LastTime = number }
local playerCombos: { [Player]: { Step: number, LastTime: number } } = {}

function GauntletServer.ExecuteAttack(player: Player, skillKey: string, payload: any?): any?
	local character = player.Character
	if not character then return payload end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return payload end

	local hits, damage
	if skillKey == "M1" then
		hits, damage = GauntletServer.ExecuteM1Combo(player, hrp)
	else
		hits, damage = GauntletServer.ExecuteSkill(player, skillKey, hrp, payload)
	end

	-- Attach hit position, damage, and explicit WeaponType for client sound/VFX broadcast
	payload = payload or {}
	payload.WeaponType = "Gauntlet"

	if hits and #hits > 0 then
		local firstHit = hits[1]
		payload.Damage = damage
		payload.TargetPosition = firstHit.HitPart.Position
	end

	return payload
end

function GauntletServer.ExecuteM1Combo(player: Player, hrp: BasePart): ({ HitboxManager.HitResult }, number)
	local now = os.clock()
	local comboData = playerCombos[player] or { Step = 1, LastTime = 0 }

	if now - comboData.LastTime > 1.2 then
		comboData.Step = 1
	end

	local currentStepData = GauntletConfig.M1Combo[comboData.Step]
	if not currentStepData then
		comboData.Step = 1
		currentStepData = GauntletConfig.M1Combo[1]
	end

	-- Fast forward punch lunge physics
	if currentStepData.ForwardLunge then
		local lungeDir = hrp.CFrame.LookVector * currentStepData.ForwardLunge
		hrp:ApplyImpulse(lungeDir * hrp:GetMass())
	end

	-- Calculate hitbox CFrame
	local hitboxCFrame = hrp.CFrame * CFrame.new(currentStepData.Offset)
	local hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, currentStepData.Range)

	for _, hit in ipairs(hits) do
		HitboxManager.ApplyDamageAndKnockback(player, hit, currentStepData.Damage, currentStepData.Knockback)
	end

	print(string.format("[GauntletServer] %s Gauntlet M1 Step %d hit %d targets for %d damage", player.Name, comboData.Step, #hits, currentStepData.Damage))

	comboData.Step = if comboData.Step >= 4 then 1 else comboData.Step + 1
	comboData.LastTime = now
	playerCombos[player] = comboData

	return hits, currentStepData.Damage
end

function GauntletServer.ExecuteSkill(player: Player, skillKey: string, hrp: BasePart, payload: any?): ({ HitboxManager.HitResult }, number)
	local skillData = GauntletConfig.Skills[skillKey]
	if not skillData then return {}, 0 end

	local hits = {}
	if skillData.Damage > 0 then
		local hitboxCFrame = hrp.CFrame * CFrame.new(skillData.Offset)
		hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, skillData.Range)

		for _, hit in ipairs(hits) do
			HitboxManager.ApplyDamageAndKnockback(player, hit, skillData.Damage, skillData.Knockback)
		end

		print(string.format("[GauntletServer] %s executed %s (%s) hitting %d targets for %d damage", player.Name, skillData.Name, skillKey, #hits, skillData.Damage))
	else
		print(string.format("[GauntletServer] %s executed utility/defensive skill %s (%s)", player.Name, skillData.Name, skillKey))
	end

	return hits, skillData.Damage
end

return GauntletServer