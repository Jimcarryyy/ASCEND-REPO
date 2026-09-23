--!strict
--[[
    FlyingSwordServer.luau
    Location: src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
    Updates:
      - Pass character as attacker to CastCompensatedBox across all attack steps.
      - Phase 5.4: Reads Skill Q hitbox size and Skill F domain radius directly from FlyingSwordConfig
        instead of hardcoded inline overrides.
      - E Skill Piercing Void Thrust: High-velocity swept thrust with target penetration.
      - F Skill 100-Slash Domain: High-velocity blink and omnidirectional slice domain.
      - Q Skill: ZERO knockback (slices in-place without pushing targets away).
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)
local ArenaManager = require(ServerScriptService.Server.Combat.ArenaManager)

local FlyingSwordServer = {}

type ComboTracker = {
	Step: number,
	LastTime: number,
}

local playerCombos: { [Player]: ComboTracker } = {}

local cultivationManagerRef: any = nil
local function getCultivationManager(): any
	if not cultivationManagerRef then
		cultivationManagerRef = require(ServerScriptService.Server.Cultivation.CultivationManager)
	end
	return cultivationManagerRef
end

local function ResolveAimDirection(hrp: BasePart, requestedAimDir: Vector3?): Vector3
	if requestedAimDir and typeof(requestedAimDir) == "Vector3" then
		local dir = requestedAimDir
		if dir.X == dir.X and dir.Y == dir.Y and dir.Z == dir.Z and dir.Magnitude > 0.001 then
			return dir.Unit
		end
	end
	return hrp.CFrame.LookVector
end

local function GetEquippedWeaponBaseDamage(player: Player): number
	local character = player.Character
	local weaponId = if character then (character:GetAttribute("EquippedWeapon") :: string?) else nil
	if not weaponId or weaponId == "" then return 15 end

	local itemDef = ItemConfig.GetItem(weaponId)
	local baseDmg = (itemDef and itemDef.Stats and itemDef.Stats.Damage) or 15

	local samsaraCycle = (character and character:GetAttribute("SamsaraCycle"))
		or player:GetAttribute("SamsaraCycle")
		or 0
	local cycleBonus = 1.0 + math.min(0.20, (tonumber(samsaraCycle) or 0) * 0.05)

	return math.floor(baseDmg * cycleBonus)
end

function FlyingSwordServer.StartChargeF(player: Player)
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local currentY = math.clamp(hrp.AssemblyLinearVelocity.Y, -2, 2)
	hrp.AssemblyLinearVelocity = Vector3.new(0, currentY, 0)
	hrp.AssemblyAngularVelocity = Vector3.zero

	character:SetAttribute("IsChargingF", true)
	character:SetAttribute("IsAttacking", true)
end

function FlyingSwordServer.ExecuteSpatialBlink(player: Player, aimDirection: Vector3, distance: number): Vector3
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return Vector3.zero end

	character:SetAttribute("IsChargingF", false)
	character:SetAttribute("IsBlinking", true)

	local targetDist = distance or 32.0
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }

	local wallRay = Workspace:Raycast(hrp.Position, aimDirection * targetDist, rayParams)
	local actualDist = if wallRay then math.max(4, wallRay.Distance - 2) else targetDist
	local destination = hrp.Position + aimDirection * actualDist

	task.delay(0.35, function()
		if character and character.Parent and hrp and hrp.Parent then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.AssemblyAngularVelocity = Vector3.zero
			character:SetAttribute("IsBlinking", false)
			character:SetAttribute("IsAttacking", false)

			local combatRemote = RemoteEvents.GetRemote("CombatAction")
			if combatRemote then
				combatRemote:FireClient(player, player, "F_Finished", {})
			end
		end
	end)

	return destination
end

function FlyingSwordServer.ExecuteAttack(player: Player, skillKey: string, payload: any?): any
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return payload end

	local cultMgr = getCultivationManager()
	local pData = if cultMgr then cultMgr.GetPlayerData(player) else nil

	local now = os.clock()
	local comboData = playerCombos[player]
	if not comboData then
		comboData = { Step = 1, LastTime = now }
		playerCombos[player] = comboData
	end

	if skillKey == "M1" then
		local requestedStep = (payload and payload.ComboIndex) or 1
		comboData.Step = requestedStep
		comboData.LastTime = now

		local currentStepData = FlyingSwordConfig.M1Combo[requestedStep] or FlyingSwordConfig.M1Combo[1]
		local aimDirection = ResolveAimDirection(hrp, payload and payload.AimDirection)
		local flatAim = Vector3.new(aimDirection.X, 0, aimDirection.Z).Unit

		local inArena = (character:GetAttribute("InArena") == true) or (character:GetAttribute("InSparringRing") == true)
		local critRoll = math.random()
		local isCrit = if requestedStep == 5 then true else (critRoll <= 0.20)
		local critMult = if isCrit then 1.75 else 1.0

		local finalDamage = 0
		if inArena then
			finalDamage = math.floor(currentStepData.ArenaDamage * critMult)
		else
			local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
			local weaponBaseDmg = GetEquippedWeaponBaseDamage(player)
			finalDamage = math.floor((weaponBaseDmg + currentStepData.Damage) * powerMult * critMult)
		end

		local offsetPosition = hrp.Position + (flatAim * math.abs(currentStepData.Offset.Z)) + Vector3.new(0, currentStepData.Offset.Y, 0)
		local hitboxCF = CFrame.lookAt(offsetPosition, offsetPosition + flatAim)
		local filter = { character, Workspace.Terrain }

		local hitResult = HitboxManager.CastCompensatedBox(character, hitboxCF, currentStepData.Range, filter)
		local hasHit = false
		local targetPos: Vector3? = nil

		if hitResult and hitResult.Humanoid and hitResult.Humanoid.Health > 0 then
			hasHit = true
			targetPos = hitResult.HitPart.Position

			local knockbackDir = flatAim
			local knockbackVector = knockbackDir * math.abs(currentStepData.Knockback.Z)

			local res = HitboxManager.ApplyCombatResolution(
				player,
				hitResult,
				finalDamage,
				currentStepData.PostureDamage,
				knockbackVector,
				character
			)

			return {
				HasHit = true,
				Damage = finalDamage,
				IsCrit = isCrit,
				WasBlocked = res.WasBlocked,
				WasParried = res.WasParried,
				WasGuardBroken = res.WasGuardBroken,
				TargetPosition = targetPos,
				AttackerCFrame = hrp.CFrame,
				Hits = { { Character = hitResult.Character } },
			}
		end

		return {
			HasHit = false,
			Damage = finalDamage,
			IsCrit = isCrit,
			AttackerCFrame = hrp.CFrame,
		}

	elseif skillKey == "Q" then
		local aimDirection = ResolveAimDirection(hrp, payload and payload.AimDirection)
		local flatAim = Vector3.new(aimDirection.X, 0, aimDirection.Z).Unit
		local qSkill = FlyingSwordConfig.Skills.Q

		local inArena = (character:GetAttribute("InArena") == true) or (character:GetAttribute("InSparringRing") == true)
		local critRoll = math.random()
		local isCrit = (critRoll <= 0.25)
		local critMult = if isCrit then 1.75 else 1.0

		local rawDmg = if inArena then qSkill.ArenaDamage else qSkill.Damage
		local powerMult = if (not inArena and pData) then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
		local weaponBase = if not inArena then GetEquippedWeaponBaseDamage(player) else 0
		local totalSkillDamage = math.floor((weaponBase + rawDmg) * powerMult * critMult)

		local waveDamage = math.max(1, math.floor(totalSkillDamage / 3))
		local wavePosture = math.max(1, math.floor(qSkill.PostureDamage / 3))

		local meleeHitboxCF = CFrame.lookAt(hrp.Position + flatAim * 4.0, hrp.Position + flatAim * 5.0)
		local qRange = qSkill.Range or Vector3.new(12, 5, 8)
		local meleeHits = HitboxManager.CastCompensatedBox(character, meleeHitboxCF, qRange, { character, Workspace.Terrain })

		if meleeHits and meleeHits.Humanoid and meleeHits.Humanoid.Health > 0 then
			HitboxManager.ApplyCombatResolution(
				player,
				meleeHits,
				waveDamage,
				wavePosture,
				Vector3.zero,
				character
			)
		end

		for waveIdx = 1, 3 do
			task.delay((waveIdx - 1) * 0.08, function()
				if not character.Parent or not hrp.Parent then return end
				local hitLogged = false
				local waveOrigin = hrp.Position + flatAim * (2.0 + waveIdx * 1.5)
				local waveCF = CFrame.lookAt(waveOrigin, waveOrigin + flatAim)

				local currentCF = waveCF
				local elapsed = 0
				local lifetime = 36 / 70

				local conn: RBXScriptConnection?
				conn = RunService.Heartbeat:Connect(function(dt)
					elapsed += dt
					local nextPos = currentCF.Position + flatAim * (70 * dt)
					currentCF = CFrame.new(nextPos) * (currentCF - currentCF.Position)

					if not hitLogged then
						local hit = HitboxManager.CastCompensatedBox(character, currentCF, Vector3.new(9, 3, 9), { character, Workspace.Terrain })
						if hit and hit.Humanoid and hit.Humanoid.Health > 0 then
							hitLogged = true
							HitboxManager.ApplyCombatResolution(
								player,
								hit,
								waveDamage,
								wavePosture,
								Vector3.zero,
								character
							)
						end
					end

					if elapsed >= lifetime or hitLogged then
						if conn then conn:Disconnect() end
					end
				end)
			end)
		end

		return {
			HasHit = true,
			Damage = totalSkillDamage,
			IsCrit = isCrit,
			AimDirection = flatAim,
			AttackerCFrame = hrp.CFrame,
		}

	elseif skillKey == "E" then
		local aimDirection = ResolveAimDirection(hrp, payload and payload.AimDirection)
		local flatAim = Vector3.new(aimDirection.X, 0, aimDirection.Z).Unit
		local eSkill = FlyingSwordConfig.Skills.E

		local inArena = (character:GetAttribute("InArena") == true) or (character:GetAttribute("InSparringRing") == true)
		local critRoll = math.random()
		local isCrit = (critRoll <= 0.25)
		local critMult = if isCrit then 1.75 else 1.0

		local rawDmg = if inArena then eSkill.ArenaDamage else eSkill.Damage
		local powerMult = if (not inArena and pData) then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
		local weaponBase = if not inArena then GetEquippedWeaponBaseDamage(player) else 0
		local finalDamage = math.floor((weaponBase + rawDmg) * powerMult * critMult)

		local eRange = eSkill.Range or Vector3.new(5, 5, 12)
		local offsetPos = hrp.Position + flatAim * 6.5
		local thrustCF = CFrame.lookAt(offsetPos, offsetPos + flatAim)

		local hitResult = HitboxManager.CastCompensatedBox(character, thrustCF, eRange, { character, Workspace.Terrain })
		if hitResult and hitResult.Humanoid and hitResult.Humanoid.Health > 0 then
			local knockback = flatAim * math.abs(eSkill.Knockback.Z)
			local res = HitboxManager.ApplyCombatResolution(
				player,
				hitResult,
				finalDamage,
				eSkill.PostureDamage,
				knockback,
				character
			)
			return {
				HasHit = true,
				Damage = finalDamage,
				IsCrit = isCrit,
				WasBlocked = res.WasBlocked,
				WasParried = res.WasParried,
				WasGuardBroken = res.WasGuardBroken,
				TargetPosition = hitResult.HitPart.Position,
				AttackerCFrame = hrp.CFrame,
				Hits = { { Character = hitResult.Character } },
			}
		end

		return {
			HasHit = false,
			Damage = finalDamage,
			IsCrit = isCrit,
			AttackerCFrame = hrp.CFrame,
		}

	elseif skillKey == "F" then
		local aimDirection = ResolveAimDirection(hrp, payload and payload.AimDirection)
		local flatAim = Vector3.new(aimDirection.X, 0, aimDirection.Z).Unit
		local fSkill = FlyingSwordConfig.Skills.F

		local inArena = (character:GetAttribute("InArena") == true) or (character:GetAttribute("InSparringRing") == true)
		local critRoll = math.random()
		local isCrit = (critRoll <= 0.30)
		local critMult = if isCrit then 1.75 else 1.0

		local rawDmg = if inArena then fSkill.ArenaDamage else fSkill.Damage
		local powerMult = if (not inArena and pData) then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
		local weaponBase = if not inArena then GetEquippedWeaponBaseDamage(player) else 0
		local totalDamage = math.floor((weaponBase + rawDmg) * powerMult * critMult)

		local domainCenter = if payload and payload.Origin then payload.Origin else (hrp.Position + flatAim * 14.0)

		local shredRadius = if fSkill.Range then (fSkill.Range.X / 2) else 18.0
		local sliceTickDamage = math.max(1, math.floor(totalDamage * 0.12))
		local finalBurstDamage = math.max(1, math.floor(totalDamage * 0.40))

		local victimTracker: { [Humanoid]: boolean } = {}
		local hitsList: { { Character: Model } } = {}

		local overlap = OverlapParams.new()
		overlap.FilterType = Enum.RaycastFilterType.Exclude
		overlap.FilterDescendantsInstances = { character, Workspace.Terrain }

		task.spawn(function()
			for tickIdx = 1, 5 do
				task.wait(0.08)
				local parts = Workspace:GetPartBoundsInRadius(domainCenter, shredRadius, overlap)
				for _, p in ipairs(parts) do
					local m = p:FindFirstAncestorOfClass("Model")
					local hum = m and m:FindFirstChildOfClass("Humanoid")
					local root = m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
					if m and hum and hum.Health > 0 and root and m ~= character then
						if not victimTracker[hum] then
							victimTracker[hum] = true
							table.insert(hitsList, { Character = m })
						end
						HitboxManager.ApplyCombatResolution(
							player,
							{ Character = m, Humanoid = hum, HitPart = root, TargetPlayer = Players:GetPlayerFromCharacter(m) },
							sliceTickDamage,
							math.floor(fSkill.PostureDamage * 0.15),
							Vector3.zero,
							character
						)
					end
				end
			end

			task.wait(0.12)
			local finisherParts = Workspace:GetPartBoundsInRadius(domainCenter, shredRadius + 2.0, overlap)
			for _, p in ipairs(finisherParts) do
				local m = p:FindFirstAncestorOfClass("Model")
				local hum = m and m:FindFirstChildOfClass("Humanoid")
				local root = m and m:FindFirstChild("HumanoidRootPart") :: BasePart?
				if m and hum and hum.Health > 0 and root and m ~= character then
					local toCenter = (root.Position - domainCenter)
					local knockbackDir = if toCenter.Magnitude > 0.1 then toCenter.Unit else flatAim
					HitboxManager.ApplyCombatResolution(
						player,
						{ Character = m, Humanoid = hum, HitPart = root, TargetPlayer = Players:GetPlayerFromCharacter(m) },
						finalBurstDamage,
						math.floor(fSkill.PostureDamage * 0.50),
						knockbackDir * math.abs(fSkill.Knockback.Z),
						character
					)
				end
			end
		end)

		return {
			HasHit = true,
			Damage = totalDamage,
			IsCrit = isCrit,
			Origin = domainCenter,
			AttackerCFrame = hrp.CFrame,
			Hits = hitsList,
		}
	end

	return payload
end

return FlyingSwordServer