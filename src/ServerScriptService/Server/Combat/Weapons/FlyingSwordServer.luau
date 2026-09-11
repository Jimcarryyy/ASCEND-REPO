--!strict
--[[
    FlyingSwordServer.luau
    Location: src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
    Authoritative server attack & movement engine:
    - Server-Authoritative F Ultimate Blink Movement (LinearVelocity PerAxis + Y-Clamp + Tween Decay)
    - Anti-Trip Ground Physics & Attribute Gating (IsChargingF, IsBlinking)
    - Dual Hitbox Q Skill (Point-Blank Melee + 3x Traveling Waves)
    - 100-Slash Spherical Domain F Skill Damage Resolution
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)

local FlyingSwordServer = {}
local playerCombos: { [Player]: { Step: number, LastTime: number } } = {}
local activeBlinkTweens: { [Player]: Tween } = {}

local function GetEquippedWeaponBaseDamage(player: Player): number
	local weaponId = WeaponManager.GetEquippedWeapon(player)
	local itemDef = ItemConfig.GetItem(weaponId)
	if itemDef and itemDef.Stats and itemDef.Stats.Damage then
		return itemDef.Stats.Damage
	end
	return 15
end

local function ResolveAimDirection(payload: any?, fallback: Vector3): Vector3
	if payload and typeof(payload.AimDirection) == "Vector3" and payload.AimDirection.Magnitude > 0 then
		return payload.AimDirection
	end
	return fallback
end

-- =============================================================================
-- SERVER-AUTHORITATIVE BLINK PHYSICS ENGINE (MIRRORS WORKING SHIFT DASH)
-- =============================================================================
function FlyingSwordServer.StartChargeF(player: Player)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	-- Clamp existing vertical velocity and arrest horizontal velocity safely
	local currentY = math.clamp(hrp.AssemblyLinearVelocity.Y, -2, 2)
	hrp.AssemblyLinearVelocity = Vector3.new(0, currentY, 0)
	hrp.AssemblyAngularVelocity = Vector3.zero

	character:SetAttribute("IsChargingF", true)
	character:SetAttribute("IsAttacking", true)
	hum.WalkSpeed = 0
end

function FlyingSwordServer.ExecuteBlinkMovement(player: Player, charForward: Vector3, travelDistance: number, speed: number)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	-- 1. Set State Attributes
	character:SetAttribute("IsChargingF", false)
	character:SetAttribute("IsBlinking", true)

	-- 2. Clamp AssemblyLinearVelocity.Y to safe range BEFORE applying blink force
	local currentY = math.clamp(hrp.AssemblyLinearVelocity.Y, -2, 2)
	hrp.AssemblyLinearVelocity = Vector3.new(0, currentY, 0)
	hrp.AssemblyAngularVelocity = Vector3.zero

	-- 3. Create Attachment + LinearVelocity (ForceLimitMode.PerAxis)
	local rootAttachment = hrp:FindFirstChild("BlinkAttachment") :: Attachment?
	if not rootAttachment then
		rootAttachment = Instance.new("Attachment")
		rootAttachment.Name = "BlinkAttachment"
		rootAttachment.Parent = hrp
	end

	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "BlinkLinearVelocity"
	linearVel.Attachment0 = rootAttachment
	linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	-- ZERO Y-FORCE: Physically impossible to push character into ground or launch into sky
	linearVel.MaxAxesForce = Vector3.new(350000, 0, 350000)
	linearVel.VectorVelocity = charForward * speed
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.Parent = hrp

	local totalDuration = travelDistance / speed
	local sustainDuration = totalDuration * 0.65 -- Full speed duration
	local decayDuration = totalDuration * 0.35   -- Smooth deceleration duration

	task.delay(sustainDuration, function()
		if not linearVel.Parent then return end

		-- 4. Smooth Decay via TweenService before Destroy()
		local decayTween = TweenService:Create(
			linearVel,
			TweenInfo.new(decayDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ VectorVelocity = charForward * 12 }
		)
		activeBlinkTweens[player] = decayTween
		decayTween:Play()

		decayTween.Completed:Connect(function()
			-- 5. Cleanup Constraints
			if linearVel then linearVel:Destroy() end
			if rootAttachment then rootAttachment:Destroy() end
			activeBlinkTweens[player] = nil

			if hrp and hrp.Parent then
				hrp.AssemblyLinearVelocity = Vector3.new(0, math.clamp(hrp.AssemblyLinearVelocity.Y, -2, 2), 0)
				hrp.AssemblyAngularVelocity = Vector3.zero

				-- Clean upright orientation lock
				local _, currentYaw, _ = hrp.CFrame:ToOrientation()
				hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, currentYaw, 0)
			end

			-- 6. Restore Movement Attributes only AFTER decay completes
			character:SetAttribute("IsBlinking", false)
			character:SetAttribute("IsAttacking", false)

			-- Notify client to restore locomotion speeds
			local remoteFolder = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Network")
			local RemoteEventsMod = remoteFolder and require(remoteFolder:FindFirstChild("RemoteEvents"))
			local combatActionRemote = RemoteEventsMod and RemoteEventsMod.GetRemote("CombatAction")
			if combatActionRemote then
				combatActionRemote:FireClient(player, player, "F_Finished", {})
			end
		end)
	end)
end

function FlyingSwordServer.ExecuteAttack(player: Player, skillKey: string, payload: any?): any?
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.IsMeditating then return payload end

	local character = player.Character
	if not character then return payload end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return payload end

	local inArena = (character:GetAttribute("InArena") == true)
	local hits: { HitboxManager.HitResult } = {}
	local damage = 0
	local wasParried = false
	local wasBlocked = false
	local wasGuardBroken = false
	local isCrit = false

	if skillKey == "StartChargeF" then
		FlyingSwordServer.StartChargeF(player)
		return payload
	end

	if skillKey == "M1" then
		hits, damage, wasParried, wasBlocked, wasGuardBroken, isCrit = FlyingSwordServer.ExecuteM1Combo(player, hrp, inArena, payload)
	else
		hits, damage, wasParried, wasBlocked, wasGuardBroken, isCrit = FlyingSwordServer.ExecuteSkill(player, skillKey, hrp, inArena, payload)
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
		payload.WasGuardBroken = wasGuardBroken
		payload.TargetPosition = hits[1].HitPart.Position
		payload.Hits = hits
	else
		payload.HasHit = false
		payload.HitCount = 0
		payload.Damage = 0
		payload.IsCrit = false
		payload.WasParried = false
		payload.WasBlocked = false
		payload.WasGuardBroken = false
		payload.TargetPosition = nil
		payload.Hits = {}
	end

	return payload
end

function FlyingSwordServer.ExecuteM1Combo(player: Player, hrp: BasePart, inArena: boolean, payload: any?): ({ HitboxManager.HitResult }, number, boolean, boolean, boolean, boolean)
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

	local isCrit = (comboData.Step == 5) or (math.random(1, 100) <= 20)
	local critMult = if isCrit then 1.75 else 1.0

	local finalDamage = 0
	if inArena then
		finalDamage = math.floor(currentStepData.ArenaDamage * critMult)
	else
		local pData = CultivationManager.GetPlayerData(player)
		local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
		local weaponBaseDmg = GetEquippedWeaponBaseDamage(player)
		finalDamage = math.floor((weaponBaseDmg + currentStepData.Damage) * powerMult * critMult)
	end

	local aimDir = ResolveAimDirection(payload, hrp.CFrame.LookVector)
	local flatAimDir = Vector3.new(aimDir.X, 0, aimDir.Z).Unit
	local orientationCFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatAimDir)
	local hitboxCFrame = orientationCFrame * CFrame.new(currentStepData.Offset)

	local hits = HitboxManager.CastCompensatedBox(hrp.Parent :: Model, hitboxCFrame, currentStepData.Range)

	local anyParried = false
	local anyBlocked = false
	local anyGuardBroken = false

	for _, hit in ipairs(hits) do
		local ok, res = pcall(function()
			return HitboxManager.ApplyCombatResolution(player, hit, finalDamage, currentStepData.PostureDamage, currentStepData.Knockback)
		end)

		if ok and res then
			if res.WasParried then anyParried = true end
			if res.WasBlocked then anyBlocked = true end
			if res.WasGuardBroken then anyGuardBroken = true end
		else
			local victimHum = hit.Character and hit.Character:FindFirstChildOfClass("Humanoid")
			if victimHum then victimHum:TakeDamage(finalDamage) end
		end

		if hit.Character then
			MobAIManager.RecordDamage(hit.Character, player)
		end
	end

	comboData.Step = if comboData.Step >= 5 then 1 else comboData.Step + 1
	comboData.LastTime = now
	playerCombos[player] = comboData

	return hits, finalDamage, anyParried, anyBlocked, anyGuardBroken, isCrit
end

function FlyingSwordServer.ExecuteSkill(player: Player, skillKey: string, hrp: BasePart, inArena: boolean, payload: any?): ({ HitboxManager.HitResult }, number, boolean, boolean, boolean, boolean)
	local skillData = FlyingSwordConfig.Skills[skillKey]
	if not skillData then return {}, 0, false, false, false, false end

	local isCrit = (math.random(1, 100) <= 25)
	local critMult = if isCrit then 1.75 else 1.0

	local finalDamage = 0
	if inArena then
		finalDamage = math.floor(skillData.ArenaDamage * critMult)
	else
		local pData = CultivationManager.GetPlayerData(player)
		local powerMult = if pData then CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order) else 1.0
		local weaponBaseDmg = GetEquippedWeaponBaseDamage(player)
		finalDamage = math.floor((weaponBaseDmg + skillData.Damage) * powerMult * critMult)
	end

	local aimDir = ResolveAimDirection(payload, hrp.CFrame.LookVector)
	local flatAimDir = Vector3.new(aimDir.X, 0, aimDir.Z).Unit

	local hits: { HitboxManager.HitResult } = {}
	local anyParried = false
	local anyBlocked = false
	local anyGuardBroken = false
	local char = hrp.Parent :: Model

	if skillKey == "Q" then
		-- =============================================================
		-- SKILL Q: DUAL HITBOX (POINT-BLANK MELEE + 3x TRAVELING WAVES)
		-- =============================================================
		local torsoOrigin = hrp.Position + Vector3.new(0, -0.40, 0)
		local orientationCFrame = CFrame.lookAt(torsoOrigin, torsoOrigin + flatAimDir)
		local hitCharacters: { [Model]: boolean } = {}

		-- 1. Point-blank melee slice
		local meleeBox = orientationCFrame * CFrame.new(0, 0, -3.5)
		local meleeHits = HitboxManager.CastCompensatedBox(char, meleeBox, Vector3.new(12, 4, 7))
		local meleeDmg = math.floor(finalDamage * 0.40)

		for _, hit in ipairs(meleeHits) do
			if not hitCharacters[hit.Character] then
				hitCharacters[hit.Character] = true
				table.insert(hits, hit)

				local ok, res = pcall(function()
					return HitboxManager.ApplyCombatResolution(player, hit, meleeDmg, skillData.PostureDamage * 0.4, skillData.Knockback * 0.5)
				end)
				if ok and res then
					if res.WasParried then anyParried = true end
					if res.WasBlocked then anyBlocked = true end
					if res.WasGuardBroken then anyGuardBroken = true end
				else
					local vHum = hit.Character and hit.Character:FindFirstChildOfClass("Humanoid")
					if vHum then vHum:TakeDamage(meleeDmg) end
				end
				if hit.Character then MobAIManager.RecordDamage(hit.Character, player) end
			end
		end

		-- 2. 3x Traveling Waves (36 studs @ 70 studs/s)
		local waveDmg = math.floor(finalDamage * 0.25)
		local waveLifetime = 36 / 70
		for waveIdx = 1, 3 do
			task.delay((waveIdx - 1) * 0.08, function()
				local startPos = torsoOrigin + flatAimDir * (1.8 + waveIdx * 0.4)
				local elapsed = 0

				local conn: RBXScriptConnection?
				conn = RunService.Heartbeat:Connect(function(dt)
					elapsed += dt
					local currPos = startPos + flatAimDir * (70 * elapsed)
					local currCF = CFrame.lookAt(currPos, currPos + flatAimDir)

					local waveHits = HitboxManager.CastCompensatedBox(char, currCF, Vector3.new(16, 4.5, 10))
					for _, hit in ipairs(waveHits) do
						local ok, res = pcall(function()
							return HitboxManager.ApplyCombatResolution(player, hit, waveDmg, skillData.PostureDamage * 0.25, skillData.Knockback)
						end)
						if ok and res then
							if res.WasParried then anyParried = true end
							if res.WasBlocked then anyBlocked = true end
							if res.WasGuardBroken then anyGuardBroken = true end
						else
							local vHum = hit.Character and hit.Character:FindFirstChildOfClass("Humanoid")
							if vHum then vHum:TakeDamage(waveDmg) end
						end
						if hit.Character then MobAIManager.RecordDamage(hit.Character, player) end
					end

					if elapsed >= waveLifetime then
						if conn then conn:Disconnect() end
					end
				end)
			end)
		end

	elseif skillKey == "F" then
		-- =============================================================
		-- SKILL F: SERVER-AUTHORITATIVE BLINK & 100-SLASH SPHERE
		-- =============================================================
		local travelDist = skillData.DashDistance or 28.0
		local speed = skillData.DashSpeed or 150.0

		-- 1. Authoritative Physics Movement Execution
		FlyingSwordServer.ExecuteBlinkMovement(player, flatAimDir, travelDist, speed)

		-- 2. Multi-Tick Damage Sphere at the 14-stud midpoint
		local sphereCenter = hrp.Position + flatAimDir * (travelDist * 0.5) + Vector3.new(0, -0.40, 0)
		local shredRadius = 18.0 -- 36-stud diameter
		local tickDmg = math.floor(finalDamage * 0.20) -- 5 ticks x 20% = 100% damage

		local hitCooldowns: { [Model]: number } = {}
		local shredDuration = 0.70
		local elapsed = 0

		local conn: RBXScriptConnection?
		conn = RunService.Heartbeat:Connect(function(dt)
			elapsed += dt
			local now = os.clock()

			local overlap = OverlapParams.new()
			overlap.FilterType = Enum.RaycastFilterType.Exclude
			overlap.FilterDescendantsInstances = { char }

			local partsInSphere = workspace:GetPartBoundsInRadius(sphereCenter, shredRadius, overlap)
			for _, part in ipairs(partsInSphere) do
				local targetModel = part:FindFirstAncestorOfClass("Model")
				local targetHum = targetModel and targetModel:FindFirstChildOfClass("Humanoid")

				if targetHum and targetModel ~= char and targetHum.Health > 0 then
					if not hitCooldowns[targetModel] or (now - hitCooldowns[targetModel]) >= 0.12 then
						hitCooldowns[targetModel] = now

						local fakeHit: HitboxManager.HitResult = {
							HitPart = part,
							Character = targetModel,
							Position = part.Position,
							Normal = Vector3.new(0, 1, 0),
							Distance = (part.Position - sphereCenter).Magnitude,
						}
						table.insert(hits, fakeHit)

						local ok, res = pcall(function()
							return HitboxManager.ApplyCombatResolution(player, fakeHit, tickDmg, skillData.PostureDamage * 0.2, skillData.Knockback * 0.2)
						end)
						if ok and res then
							if res.WasParried then anyParried = true end
							if res.WasBlocked then anyBlocked = true end
							if res.WasGuardBroken then anyGuardBroken = true end
						else
							targetHum:TakeDamage(tickDmg)
						end

						MobAIManager.RecordDamage(targetModel, player)
					end
				end
			end

			if elapsed >= shredDuration then
				if conn then conn:Disconnect() end
			end
		end)

	else
		local torsoOrigin = hrp.Position + Vector3.new(0, -0.40, 0)
		local orientationCFrame = CFrame.lookAt(torsoOrigin, torsoOrigin + flatAimDir)
		local hitboxCFrame = orientationCFrame * CFrame.new(skillData.Offset)

		if finalDamage > 0 then
			hits = HitboxManager.CastCompensatedBox(char, hitboxCFrame, skillData.Range)
			for _, hit in ipairs(hits) do
				local ok, res = pcall(function()
					return HitboxManager.ApplyCombatResolution(player, hit, finalDamage, skillData.PostureDamage, skillData.Knockback)
				end)
				if ok and res then
					if res.WasParried then anyParried = true end
					if res.WasBlocked then anyBlocked = true end
					if res.WasGuardBroken then anyGuardBroken = true end
				else
					local vHum = hit.Character and hit.Character:FindFirstChildOfClass("Humanoid")
					if vHum then vHum:TakeDamage(finalDamage) end
				end
				if hit.Character then MobAIManager.RecordDamage(hit.Character, player) end
			end
		end
	end

	return hits, finalDamage, anyParried, anyBlocked, anyGuardBroken, isCrit
end

return FlyingSwordServer