--!strict
--[[
    FlyingSwordServer.luau
    Location: src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
    Server-side combat engine with Critical Strike calculations (Step 5 Guaranteed Crit, 20% Base Crit).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)

local FlyingSwordServer = {}

-- Player M1 combo tracking: [Player] -> { Step = number, LastTime = number }
local playerCombos: { [Player]: { Step: number, LastTime: number } } = {}

local function GetEquippedWeaponBaseDamage(player: Player): number
	local weaponId = WeaponManager.GetEquippedWeapon(player)
	local itemDef = ItemConfig.GetItem(weaponId)
	if itemDef and itemDef.Stats and itemDef.Stats.Damage then
		return itemDef.Stats.Damage
	end
	return 15
end

function FlyingSwordServer.ExecuteAttack(player: Player, skillKey: string, payload: any?): any?
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then
		return payload
	end

	local character = player.Character
	if not character then return payload end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return payload end

	local hits: { HitboxManager.HitResult } = {}
	local damage = 0
	local wasParried = false
	local wasBlocked = false
	local isCrit = false

	if skillKey == "M1" then
		hits, damage, wasParried, wasBlocked, isCrit = FlyingSwordServer.ExecuteM1Combo(player, hrp, payload)
	else
		hits, damage, wasParried, wasBlocked, isCrit = FlyingSwordServer.ExecuteSkill(player, skillKey, hrp, payload)
	end

	payload = payload or {}
	payload.WeaponType = "FlyingSword"

	if hits and #hits > 0 then
		payload.HasHit = true
		payload.HitCount = #hits
		payload.Damage = damage
		payload.IsCrit = isCrit
		payload.WasParried = wasParried
		payload.WasBlocked = wasBlocked
		payload.TargetPosition = hits[1].HitPart.Position
	else
		payload.HasHit = false
		payload.HitCount = 0
		payload.Damage = 0
		payload.IsCrit = false
		payload.WasParried = false
		payload.WasBlocked = false
		payload.TargetPosition = nil
	end

	return payload
end

function FlyingSwordServer.ExecuteM1Combo(player: Player, hrp: BasePart, payload: any?): ({ HitboxManager.HitResult }, number, boolean, boolean, boolean)
	local now = os.clock()
	local comboData = playerCombos[player] or { Step = 1, LastTime = 0 }

	if now - comboData.LastTime > 1.3 then
		comboData.Step = 1
	end

	local currentStepData = FlyingSwordConfig.M1Combo[comboData.Step]
	if not currentStepData then
		comboData.Step = 1
		currentStepData = FlyingSwordConfig.M1Combo[1]
	end

	local pData = CultivationManager.GetPlayerData(player)
	local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
	local weaponBaseDmg = GetEquippedWeaponBaseDamage(player)
	local totalBaseDmg = weaponBaseDmg + currentStepData.Damage

	-- Critical Strike roll (Step 5 Guaranteed Crit, or 20% Base Crit)
	local isCrit = (comboData.Step == 5) or (math.random(1, 100) <= 20)
	local critMult = if isCrit then 1.75 else 1.0
	local finalDamage = math.floor(totalBaseDmg * powerMult * critMult)

	-- Aim-projected hitbox
	local aimDir = if payload and payload.AimDirection and payload.AimDirection.Magnitude > 0 
		then payload.AimDirection 
		else hrp.CFrame.LookVector
	local flatAimDir = Vector3.new(aimDir.X, 0, aimDir.Z).Unit
	local orientationCFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatAimDir)
	local hitboxCFrame = orientationCFrame * CFrame.new(currentStepData.Offset)

	local hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, currentStepData.Range)

	local anyParried = false
	local anyBlocked = false

	for _, hit in ipairs(hits) do
		local res = HitboxManager.ApplyDamageAndKnockback(player, hit, finalDamage, currentStepData.Knockback)
		if res.WasParried then anyParried = true end
		if res.WasBlocked then anyBlocked = true end
	end

	comboData.Step = if comboData.Step >= 5 then 1 else comboData.Step + 1
	comboData.LastTime = now
	playerCombos[player] = comboData

	return hits, finalDamage, anyParried, anyBlocked, isCrit
end

function FlyingSwordServer.ExecuteSkill(player: Player, skillKey: string, hrp: BasePart, payload: any?): ({ HitboxManager.HitResult }, number, boolean, boolean, boolean)
	local skillData = FlyingSwordConfig.Skills[skillKey]
	if not skillData then return {}, 0, false, false, false end

	local pData = CultivationManager.GetPlayerData(player)
	local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
	local weaponBaseDmg = GetEquippedWeaponBaseDamage(player)
	local totalBaseDmg = weaponBaseDmg + skillData.Damage

	local isCrit = (math.random(1, 100) <= 25)
	local critMult = if isCrit then 1.75 else 1.0
	local finalDamage = math.floor(totalBaseDmg * powerMult * critMult)

	local aimDir = if payload and payload.AimDirection and payload.AimDirection.Magnitude > 0 
		then payload.AimDirection 
		else hrp.CFrame.LookVector
	local flatAimDir = Vector3.new(aimDir.X, 0, aimDir.Z).Unit
	local orientationCFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatAimDir)
	local hitboxCFrame = orientationCFrame * CFrame.new(skillData.Offset)

	local hits = {}
	local anyParried = false
	local anyBlocked = false

	if finalDamage > 0 then
		hits = HitboxManager.CastBoxHitbox(hrp.Parent :: Model, hitboxCFrame, skillData.Range)
		for _, hit in ipairs(hits) do
			local res = HitboxManager.ApplyDamageAndKnockback(player, hit, finalDamage, skillData.Knockback)
			if res.WasParried then anyParried = true end
			if res.WasBlocked then anyBlocked = true end
		end
	end

	return hits, finalDamage, anyParried, anyBlocked, isCrit
end

return FlyingSwordServer