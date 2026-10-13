--!strict
--[[
    MonsterAIManager.luau
    Location: src/ServerScriptService/Server/Combat/MonsterAIManager.luau
    Authoritative server-side AI and locomotion engine for Non-Humanoid Monsters.
    Features:
      - Intelligent Terrain Lookahead: Detects upcoming grass/rock inclines and ledges.
      - Auto-Climb & Obstacle Jump: Bounds up terrain lips and ledges smoothly.
      - Wolf Airborne Pounce Attack: Leaps through the air toward the player with a bite strike.
      - Boar Head-Down Ram: Charges forward with tusk knockback.
      - Single-spawn lock and automatic duplicate purge.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local MonsterConfig = require(ReplicatedStorage.Shared.Configs.MonsterConfig)
local MonsterUtil = require(ReplicatedStorage.Shared.Utils.MonsterUtil)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)

type MonsterRuntime = {
	Model: Model,
	RootPart: BasePart,
	Config: MonsterConfig.MonsterDefinition,
	SpawnCFrame: CFrame,
	AlignOrientation: AlignOrientation,
	LinearVelocity: LinearVelocity,
	TargetPlayer: Player?,
	ThreatTable: { [Player]: number },
	NextAttackTime: number,
	IsAttacking: boolean,
	IsDead: boolean,
	PatrolTarget: Vector3?,
	PatrolWaitUntil: number,
	LastHitTime: number,
	IsJumping: boolean,
}

local MonsterAIManager = {}

local activeMonsters: { [Model]: MonsterRuntime } = {}
local monsterTemplates: { [string]: Model } = {}
local activeContainer: Folder? = nil

local function GetActiveContainer(): Folder
	if not activeContainer then
		local found = Workspace:FindFirstChild("ActiveMonsters") :: Folder?
		if not found then
			found = Instance.new("Folder")
			found.Name = "ActiveMonsters"
			found.Parent = Workspace
		end
		activeContainer = found
	end
	return activeContainer :: Folder
end

-- =============================================================================
-- 1. PHYSICS SETUP & UPRIGHT CONSTRAINTS
-- =============================================================================

local function SetupLocomotionConstraints(model: Model, rootPart: BasePart): (AlignOrientation, LinearVelocity)
	for _, child in ipairs(rootPart:GetChildren()) do
		if child.Name == "MonsterAttachment" or child.Name == "MonsterOrientation" or child.Name == "MonsterVelocity" then
			child:Destroy()
		end
	end

	local lowFriction = PhysicalProperties.new(0.6, 0.01, 0.5, 1, 1)

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CollisionGroup = "Characters"
			part.CustomPhysicalProperties = lowFriction
		end
	end

	rootPart.CanCollide = true

	local attachment = Instance.new("Attachment")
	attachment.Name = "MonsterAttachment"
	attachment.Parent = rootPart

	local alignOrientation = Instance.new("AlignOrientation")
	alignOrientation.Name = "MonsterOrientation"
	alignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	alignOrientation.Attachment0 = attachment
	alignOrientation.Responsiveness = 35
	alignOrientation.MaxTorque = math.huge
	alignOrientation.PrimaryAxisOnly = false
	alignOrientation.CFrame = rootPart.CFrame
	alignOrientation.Parent = rootPart

	local linearVelocity = Instance.new("LinearVelocity")
	linearVelocity.Name = "MonsterVelocity"
	linearVelocity.Attachment0 = attachment
	linearVelocity.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVelocity.ForceLimitsEnabled = true
	linearVelocity.MaxAxesForce = Vector3.new(2e9, 2e9, 2e9)
	linearVelocity.VectorVelocity = Vector3.zero
	linearVelocity.Parent = rootPart

	pcall(function()
		rootPart:SetNetworkOwner(nil)
	end)

	return alignOrientation, linearVelocity
end

-- =============================================================================
-- 2. SPAWNING & ELEVATION
-- =============================================================================

local function InitializeMonsterEntity(model: Model, spawnCFrame: CFrame, def: MonsterConfig.MonsterDefinition)
	local rootPart = MonsterUtil.GetRootPart(model)
	if not rootPart then return end

	local adjustedCFrame = spawnCFrame + Vector3.new(0, 0.25, 0)
	model:PivotTo(adjustedCFrame)

	MonsterUtil.InitMonster(model, {
		Id = def.Id,
		DisplayName = def.DisplayName,
		Zone = def.Zone,
		MaxHealth = def.MaxHealth,
		MaxPosture = def.MaxPosture,
		IsBoss = false,
	})

	local alignOri, linearVel = SetupLocomotionConstraints(model, rootPart)

	local runtime: MonsterRuntime = {
		Model = model,
		RootPart = rootPart,
		Config = def,
		SpawnCFrame = adjustedCFrame,
		AlignOrientation = alignOri,
		LinearVelocity = linearVel,
		TargetPlayer = nil,
		ThreatTable = {},
		NextAttackTime = 0,
		IsAttacking = false,
		IsDead = false,
		PatrolTarget = nil,
		PatrolWaitUntil = 0,
		LastHitTime = 0,
		IsJumping = false,
	}

	activeMonsters[model] = runtime

	model:GetAttributeChangedSignal("ActionState"):Connect(function()
		if model:GetAttribute("ActionState") == "Dead" and not runtime.IsDead then
			MonsterAIManager.HandleDeath(model)
		end
	end)
end

local function SpawnMonsterFromTemplate(templateName: string, spawnCFrame: CFrame): Model?
	local template = monsterTemplates[templateName]
	if not template then return nil end

	local def = MonsterConfig.GetMonster(templateName)
	if not def then return nil end

	local clone = template:Clone()
	clone.Parent = GetActiveContainer()
	InitializeMonsterEntity(clone, spawnCFrame, def)
	return clone
end

-- =============================================================================
-- 3. TARGETING
-- =============================================================================

local function FindBestTarget(runtime: MonsterRuntime): Player?
	local rootPos = runtime.RootPart.Position
	local aggroRadius = runtime.Config.AggroRadius

	local highestThreatPlayer: Player? = nil
	local highestThreat = 0

	for player, threat in pairs(runtime.ThreatTable) do
		if player.Character and player.Character.Parent then
			local pHrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			local pHum = player.Character:FindFirstChildOfClass("Humanoid")
			if pHrp and pHum and pHum.Health > 0 then
				local dist = (pHrp.Position - rootPos).Magnitude
				if dist <= aggroRadius * 1.6 and threat > highestThreat then
					highestThreat = threat
					highestThreatPlayer = player
				end
			end
		end
	end

	if highestThreatPlayer then return highestThreatPlayer end

	local nearestPlayer: Player? = nil
	local shortestDist = aggroRadius

	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char.Parent then
			local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local pHum = char:FindFirstChildOfClass("Humanoid")
			if pHrp and pHum and pHum.Health > 0 then
				local dist = (pHrp.Position - rootPos).Magnitude
				if dist < shortestDist then
					shortestDist = dist
					nearestPlayer = player
				end
			end
		end
	end

	return nearestPlayer
end

-- =============================================================================
-- 4. INTELLIGENT TERRAIN LOOKAHEAD & STEP-CLIMBING ENGINE
-- =============================================================================

local function ComputeIntelligentTerrainVelocity(
	runtime: MonsterRuntime,
	flatDir: Vector3,
	speed: number
): Vector3
	local rootPos = runtime.RootPart.Position
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { Workspace.Terrain, Workspace:FindFirstChild("Map") or Workspace }

	-- 1. Center Ground Ray (Underneath the beast)
	local centerRay = Workspace:Raycast(rootPos + Vector3.new(0, 5, 0), Vector3.new(0, -15, 0), rayParams)
	local centerGroundY = if centerRay then centerRay.Position.Y else rootPos.Y

	-- 2. Forward Lookahead Ray (3 studs in front of chest)
	local lookaheadOffset = flatDir * 3.0
	local forwardRay = Workspace:Raycast(rootPos + lookaheadOffset + Vector3.new(0, 6, 0), Vector3.new(0, -16, 0), rayParams)

	if forwardRay then
		local forwardGroundY = forwardRay.Position.Y
		local heightDiff = forwardGroundY - centerGroundY

		-- A. Obstacle / Steep Ledge Auto-Jump
		if heightDiff > 1.6 and not runtime.IsJumping then
			runtime.IsJumping = true
			MonsterUtil.SetActionState(runtime.Model, "Jumping" :: any)

			task.delay(0.45, function()
				if runtime.Model and runtime.Model.Parent then
					runtime.IsJumping = false
				end
			end)

			-- Upward leap burst over the ledge
			return (flatDir * speed) + Vector3.new(0, 18, 0)
		end

		-- B. Continuous Slope Climbing Vector
		local groundVector = (forwardRay.Position - (if centerRay then centerRay.Position else rootPos))
		if groundVector.Magnitude > 0.01 then
			local climbDir = groundVector.Unit
			return climbDir * speed
		end
	end

	if centerRay then
		local normal = centerRay.Normal
		local slopeVector = flatDir - normal * flatDir:Dot(normal)
		if slopeVector.Magnitude > 0.01 then
			return slopeVector.Unit * speed
		end
	end

	return flatDir * speed
end

-- =============================================================================
-- 5. ATTACK PIPELINE (WOLF AIRBORNE POUNCE & BOAR RAM)
-- =============================================================================

local function ExecuteMonsterAttack(runtime: MonsterRuntime, targetPlayer: Player)
	runtime.IsAttacking = true
	local targetChar = targetPlayer.Character
	local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetHrp then
		runtime.IsAttacking = false
		return
	end

	local toPlayer = (targetHrp.Position - runtime.RootPart.Position) * Vector3.new(1, 0, 1)
	local attackDir = if toPlayer.Magnitude > 0.01 then toPlayer.Unit else runtime.RootPart.CFrame.LookVector
	runtime.AlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, attackDir, Vector3.new(0, 1, 0))

	local isWolf = string.find(runtime.Config.Id:lower(), "wolf") ~= nil or string.find(runtime.Config.Id:lower(), "hound") ~= nil

	if isWolf then
		-- =====================================================================
		-- WOLF / HOUND AIRBORNE POUNCE ATTACK
		-- =====================================================================
		-- 1. Crouch windup
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		MonsterUtil.SetActionState(runtime.Model, "Attacking")
		task.wait(0.25)

		if runtime.IsDead or not runtime.Model.Parent or os.clock() < runtime.LastHitTime + 0.40 then
			runtime.IsAttacking = false
			MonsterUtil.SetActionState(runtime.Model, "Idle")
			return
		end

		-- 2. High-speed airborne leap toward player
		MonsterUtil.SetActionState(runtime.Model, "LeapAttack" :: any)
		runtime.LinearVelocity.VectorVelocity = (attackDir * 36.0) + Vector3.new(0, 14.0, 0)
		task.wait(0.35)

		-- 3. Landing impact & bite
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		local hits = HitboxManager.CastCompensatedBox(runtime.Model, CFrame.new(0, 0, -4.5), Vector3.new(8, 7, 8), { runtime.Model })
		for _, hit in ipairs(hits) do
			if hit.TargetPlayer == targetPlayer then
				local postureDmg = math.floor(runtime.Config.BaseDamage * 0.45)
				HitboxManager.ApplyCombatResolution(nil, hit, runtime.Config.BaseDamage, postureDmg, attackDir * 20, runtime.Model, "WolfBite")
			end
		end

		task.wait(0.30)
	else
		-- =====================================================================
		-- BOAR HEAD-DOWN RAM ATTACK
		-- =====================================================================
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		MonsterUtil.SetActionState(runtime.Model, "Attacking")
		task.wait(0.35)

		if runtime.IsDead or not runtime.Model.Parent or os.clock() < runtime.LastHitTime + 0.40 then
			runtime.IsAttacking = false
			MonsterUtil.SetActionState(runtime.Model, "Idle")
			return
		end

		-- Forward thrust
		runtime.LinearVelocity.VectorVelocity = attackDir * 24.0
		task.wait(0.20)
		runtime.LinearVelocity.VectorVelocity = Vector3.zero

		local hits = HitboxManager.CastCompensatedBox(runtime.Model, CFrame.new(0, 0, -5), Vector3.new(8, 7, 8), { runtime.Model })
		for _, hit in ipairs(hits) do
			if hit.TargetPlayer == targetPlayer then
				local postureDmg = math.floor(runtime.Config.BaseDamage * 0.5)
				HitboxManager.ApplyCombatResolution(nil, hit, runtime.Config.BaseDamage, postureDmg, attackDir * 22, runtime.Model, "BoarRam")
			end
		end

		task.wait(0.30)
	end

	runtime.IsAttacking = false
	runtime.NextAttackTime = os.clock() + runtime.Config.AttackCooldown
	MonsterUtil.SetActionState(runtime.Model, "Idle")
end

-- =============================================================================
-- 6. AI UPDATE TICK WITH SMART TERRAIN NAVIGATION
-- =============================================================================

local function UpdateMonster(runtime: MonsterRuntime, now: number)
	if runtime.IsDead or not runtime.Model.Parent then return end

	if MonsterUtil.IsStunned(runtime.Model) then
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		return
	end

	-- Stagger recovery
	if now < runtime.LastHitTime + 0.50 then
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		runtime.IsAttacking = false
		return
	end

	if runtime.IsAttacking then return end

	local targetPlayer = FindBestTarget(runtime)
	runtime.TargetPlayer = targetPlayer
	local rootPos = runtime.RootPart.Position

	-- 1. UNAGGROED: CALM SLOW STROLL (12 studs/s)
	if not targetPlayer or not targetPlayer.Character then
		if now < runtime.PatrolWaitUntil then
			runtime.LinearVelocity.VectorVelocity = Vector3.zero
			MonsterUtil.SetActionState(runtime.Model, "Idle")
			return
		end

		if not runtime.PatrolTarget then
			local angle = math.random() * math.pi * 2
			local dist = math.random(8, 20)
			runtime.PatrolTarget = runtime.SpawnCFrame.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
		end

		local toTarget = runtime.PatrolTarget - rootPos
		local flatDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude

		if flatDist > 3.0 then
			local flatDir = Vector3.new(toTarget.X, 0, toTarget.Z).Unit
			runtime.AlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatDir, Vector3.new(0, 1, 0))
			runtime.LinearVelocity.VectorVelocity = ComputeIntelligentTerrainVelocity(runtime, flatDir, runtime.Config.WalkSpeed)
			if not runtime.IsJumping then
				MonsterUtil.SetActionState(runtime.Model, "Walking" :: any)
			end
		else
			runtime.PatrolTarget = nil
			runtime.PatrolWaitUntil = now + math.random(4, 7)
			runtime.LinearVelocity.VectorVelocity = Vector3.zero
			MonsterUtil.SetActionState(runtime.Model, "Idle")
		end
		return
	end

	-- 2. GLIMPSE OF PLAYER: SPRINT PURSUIT (38 studs/s)
	runtime.PatrolTarget = nil
	runtime.PatrolWaitUntil = 0

	local targetHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not targetHrp then return end

	local toTarget = targetHrp.Position - rootPos
	local flatDist = Vector3.new(toTarget.X, 0, toTarget.Z).Magnitude
	local flatDir = if flatDist > 0.01 then Vector3.new(toTarget.X, 0, toTarget.Z).Unit else Vector3.new(0, 0, -1)

	runtime.AlignOrientation.CFrame = CFrame.lookAt(Vector3.zero, flatDir, Vector3.new(0, 1, 0))

	-- Melee Attack Range Check
	if flatDist <= runtime.Config.AttackRange then
		runtime.LinearVelocity.VectorVelocity = Vector3.zero
		if now >= runtime.NextAttackTime then
			task.spawn(ExecuteMonsterAttack, runtime, targetPlayer)
		end
		return
	end

	-- Intelligent Terrain Pursuit
	runtime.LinearVelocity.VectorVelocity = ComputeIntelligentTerrainVelocity(runtime, flatDir, runtime.Config.RunSpeed)
	if not runtime.IsJumping then
		MonsterUtil.SetActionState(runtime.Model, "Running")
	end
end

-- =============================================================================
-- 7. DAMAGE REGISTRATION & GROUNDED DEATH
-- =============================================================================

function MonsterAIManager.RegisterDamage(monsterModel: Model, attackerPlayer: Player?, damage: number)
	local runtime = activeMonsters[monsterModel]
	if not runtime or runtime.IsDead then return end

	local now = os.clock()
	runtime.LastHitTime = now

	-- Attack Lockout
	runtime.IsAttacking = false
	runtime.NextAttackTime = math.max(runtime.NextAttackTime, now + 0.65)
	runtime.LinearVelocity.VectorVelocity = Vector3.zero

	MonsterUtil.SetActionState(monsterModel, "Hit" :: any)
	task.delay(0.40, function()
		if monsterModel and monsterModel.Parent and MonsterUtil.GetActionState(monsterModel) == "Hit" then
			MonsterUtil.SetActionState(monsterModel, "Running")
		end
	end)

	if attackerPlayer then
		runtime.ThreatTable[attackerPlayer] = (runtime.ThreatTable[attackerPlayer] or 0) + damage
		runtime.TargetPlayer = attackerPlayer
	end

	local curHp = MonsterUtil.GetHealth(monsterModel)
	if curHp <= 0 then
		MonsterAIManager.HandleDeath(monsterModel, attackerPlayer)
	end
end

function MonsterAIManager.HandleDeath(monsterModel: Model, killerPlayer: Player?)
	local runtime = activeMonsters[monsterModel]
	if not runtime or runtime.IsDead then return end

	runtime.IsDead = true
	activeMonsters[monsterModel] = nil

	runtime.LinearVelocity.VectorVelocity = Vector3.zero
	runtime.RootPart.Anchored = true
	runtime.RootPart.CanCollide = false
	MonsterUtil.SetActionState(monsterModel, "Dead")

	local killer = killerPlayer or runtime.TargetPlayer

	if killer then
		pcall(function()
			PlayerDataManager.AddQi(killer, runtime.Config.BaseQiReward)
			PlayerDataManager.AddSpiritStones(killer, runtime.Config.BaseSpiritStones)
		end)

		pcall(function()
			SectManager.AddQuestProgress(killer, "DefeatMonster", runtime.Config.Id, 1)
			SectManager.AddQuestProgress(killer, "DefeatMob", runtime.Config.Id, 1)
		end)

		local drops = MonsterConfig.RollDropTable(runtime.Config.Id)
		for _, drop in ipairs(drops) do
			pcall(function()
				InventoryManager.AddItem(killer, drop.ItemId, drop.Count)
			end)
		end
	end

	-- Lies collapsed on terrain for 1.8s, then fades over 2.0s
	task.spawn(function()
		task.wait(1.8)
		local steps = 25
		for i = 1, steps do
			local alpha = i / steps
			for _, part in ipairs(monsterModel:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Transparency = math.clamp(alpha, 0, 1)
				end
			end
			task.wait(0.08)
		end

		monsterModel:Destroy()

		task.wait(runtime.Config.RespawnTime)
		SpawnMonsterFromTemplate(runtime.Config.Id, runtime.SpawnCFrame)
	end)
end

-- =============================================================================
-- 8. INITIALIZATION
-- =============================================================================

function MonsterAIManager.Init()
	local oldFolder = Workspace:FindFirstChild("MobSpawns") and Workspace.MobSpawns:FindFirstChild("NewMonsterMobs")
	if oldFolder then oldFolder:Destroy() end
	local rootOldFolder = Workspace:FindFirstChild("NewMonsterMobs")
	if rootOldFolder then rootOldFolder:Destroy() end

	local activeFolder = GetActiveContainer()
	activeFolder:ClearAllChildren()

	local rsAssets = ReplicatedStorage:FindFirstChild("Assets")
	local rsMonsters = rsAssets and rsAssets:FindFirstChild("Monsters")

	if rsMonsters then
		for _, template in ipairs(rsMonsters:GetChildren()) do
			if template:IsA("Model") then
				monsterTemplates[template.Name] = template
			end
		end
	end

	-- Auto-Hide loose Spawner_* pads only
	local mobSpawns = Workspace:FindFirstChild("MobSpawns")
	if mobSpawns then
		for _, desc in ipairs(mobSpawns:GetDescendants()) do
			if desc:IsA("BasePart") and string.find(desc.Name, "Spawner_") and not desc:FindFirstAncestorOfClass("Model") then
				desc.Transparency = 1
				desc.CanCollide = false
				desc.CastShadow = false
			end
		end
	end

	local spawnerFolder = mobSpawns and mobSpawns:FindFirstChild("MonsterSpawners") or mobSpawns
	local spawnerParts: { BasePart } = {}

	if spawnerFolder then
		for _, child in ipairs(spawnerFolder:GetChildren()) do
			if child:IsA("BasePart") and (child:GetAttribute("MonsterId") ~= nil or string.find(child.Name, "Spawner_")) and not child:FindFirstAncestorOfClass("Model") then
				table.insert(spawnerParts, child)
			end
		end
	end

	-- Spawn all duplicated spawner parts
	for _, spawner in ipairs(spawnerParts) do
		spawner.Transparency = 1
		spawner.CanCollide = false

		local mobId = tostring(spawner:GetAttribute("MonsterId") or string.gsub(spawner.Name, "Spawner_", ""))
		local def = MonsterConfig.GetMonster(mobId)
		if def then
			SpawnMonsterFromTemplate(def.Id, spawner.CFrame)
		end
	end

	task.spawn(function()
		while true do
			task.wait(0.1)
			local now = os.clock()
			for _, runtime in pairs(activeMonsters) do
				task.spawn(UpdateMonster, runtime, now)
			end
		end
	end)

	print(string.format("[MonsterAIManager] Smart Terrain Navigation Active (%d spawners online).", #spawnerParts))
end

return MonsterAIManager