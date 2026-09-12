--!strict
--[[
    MobAIManager.luau
    Location: src/ServerScriptService/Server/Combat/MobAIManager.luau
    Server-authoritative Mob & Beast encounter engine:
      - Contextual Locomotion: Martial Walk during Patrol, Sprint Run during Chase
      - Smart Teammate Flocking: Mobs fan out into open angles and surround players
      - Boids Separation: Repulsion force prevents mobs from colliding or stacking
      - Fluid 5-Step M1 Attack Combo Chain
      - Full Combat Resolution: Physical knockback, parrying, blocking & posture damage
      - Fondamento Font & Vibrant Red UIGradient Overhead Mob HUDs
]]

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")
local ServerScriptService = game:GetService("ServerScriptService")

local MobConfig = require(ReplicatedStorage.Shared.Configs.MobConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local HitboxManager = require(ServerScriptService.Server.Combat.HitboxManager)

local MobAIManager = {}
local combatActionRemote: RemoteEvent

type MobState = "Patrol" | "Chase" | "Attack" | "Leash"

type ActiveMob = {
	Id: string,
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Config: any,
	AnchorPart: BasePart?,
	SpawnPos: Vector3,
	SpawnRadius: number,
	RespawnTime: number,
	State: MobState,
	TargetPlayer: Player?,
	CurrentPath: Path?,
	CurrentWaypointIndex: number,
	Waypoints: { PathWaypoint },
	LastAttackTime: number,
	ComboStep: number,
	LastPatrolTime: number,
	PatrolTarget: Vector3,
	LastDamagePlayer: Player?,
	LastDamageTime: number,
	HealthGui: BillboardGui?,
	HealthBar: Frame?,
	WalkTrack: AnimationTrack?,
	RunTrack: AnimationTrack?,
	AttackTracks: { AnimationTrack },
}

local activeMobs: { ActiveMob } = {}

local function GetMobConfig(mobId: string): any
	local cleanId = string.match(tostring(mobId), "^%s*(.-)%s*$") or tostring(mobId)

	if type(MobConfig.GetMobConfig) == "function" then
		local res = MobConfig.GetMobConfig(cleanId)
		if res then return res end
	end
	if type(MobConfig.GetMob) == "function" then
		local res = MobConfig.GetMob(cleanId)
		if res then return res end
	end

	if type(MobConfig.Mobs) == "table" and MobConfig.Mobs[cleanId] then
		return MobConfig.Mobs[cleanId]
	end
	if MobConfig[cleanId] then
		return MobConfig[cleanId]
	end

	local lowerTarget = cleanId:lower()
	local targets = { MobConfig.Mobs, MobConfig }
	for _, tbl in ipairs(targets) do
		if type(tbl) == "table" then
			for k, v in pairs(tbl) do
				if type(k) == "string" and k:lower() == lowerTarget and type(v) == "table" then
					return v
				end
			end
		end
	end

	return nil
end

-- Spatial player lookup grid
local playerGrid: { [string]: { Player } } = {}
local GRID_CELL_SIZE = 50

local function GetGridKey(pos: Vector3): string
	return math.floor(pos.X / GRID_CELL_SIZE) .. ":" .. math.floor(pos.Z / GRID_CELL_SIZE)
end

local function RebuildPlayerGrid()
	table.clear(playerGrid)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char:FindFirstChild("Humanoid") :: Humanoid?
			if hrp and hum and hum.Health > 0 then
				local key = GetGridKey(hrp.Position)
				if not playerGrid[key] then playerGrid[key] = {} end
				table.insert(playerGrid[key], player)
			end
		end
	end
end

local function GetNearbyPlayers(pos: Vector3, radius: number): { Player }
	local found: { Player } = {}
	local cellRadius = math.ceil(radius / GRID_CELL_SIZE)
	local cx = math.floor(pos.X / GRID_CELL_SIZE)
	local cz = math.floor(pos.Z / GRID_CELL_SIZE)

	for dx = -cellRadius, cellRadius do
		for dz = -cellRadius, cellRadius do
			local key = (cx + dx) .. ":" .. (cz + dz)
			local cell = playerGrid[key]
			if cell then
				for _, player in ipairs(cell) do
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp and (hrp.Position - pos).Magnitude <= radius then
						table.insert(found, player)
					end
				end
			end
		end
	end
	return found
end

--------------------------------------------------------------------------------
-- VIBRANT RED FONDAMENTO MOB OVERHEAD BUILDER
--------------------------------------------------------------------------------
local function CreateHealthUI(model: Model, displayName: string): (BillboardGui?, Frame?)
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not head then return nil, nil end

	local bb = Instance.new("BillboardGui")
	bb.Name = "MobHealthUI"
	bb.Size = UDim2.new(0, 130, 0, 26)
	bb.StudsOffset = Vector3.new(0, 2.8, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 65
	bb.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 16)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.Font = Enum.Font.Fondamento
	nameLabel.TextSize = 16
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.Parent = bb

	local nameStroke = Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(0, 0, 0)
	nameStroke.Thickness = 1.4
	nameStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	nameStroke.Parent = nameLabel

	local nameGrad = Instance.new("UIGradient")
	nameGrad.Name = "RedGradient"
	nameGrad.Rotation = 90
	nameGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 120, 120)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 40, 40)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 15, 15)),
	})
	nameGrad.Parent = nameLabel

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0, 7)
	barBg.Position = UDim2.new(0, 0, 0, 18)
	barBg.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
	barBg.BackgroundTransparency = 0.2
	barBg.BorderSizePixel = 0
	barBg.ClipsDescendants = true
	barBg.Parent = bb

	local bgStroke = Instance.new("UIStroke")
	bgStroke.Color = Color3.fromRGB(0, 0, 0)
	bgStroke.Thickness = 1.0
	bgStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	bgStroke.Parent = barBg

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.BorderSizePixel = 0
	fill.Parent = barBg

	local fillGrad = Instance.new("UIGradient")
	fillGrad.Rotation = 0
	fillGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(235, 30, 30)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 10, 10)),
	})
	fillGrad.Parent = fill

	return bb, fill
end

local function OnMobDied(mob: ActiveMob)
	if mob.WalkTrack then pcall(function() mob.WalkTrack:Stop(0.1) end) end
	if mob.RunTrack then pcall(function() mob.RunTrack:Stop(0.1) end) end
	if mob.AttackTracks then
		for _, track in ipairs(mob.AttackTracks) do pcall(function() track:Stop(0.1) end) end
	end

	local killer = mob.LastDamagePlayer
	local now = os.clock()

	if killer and killer.Parent and (now - mob.LastDamageTime) <= 15 then
		local config = mob.Config or {}
		local multiplier = 1.0

		local cultData = CultivationManager.GetPlayerData(killer)
		if cultData and cultData.Realm then
			local realmInfo = CultivationConfig[cultData.Realm]
			local realmTier = if realmInfo then realmInfo.Tier else 1
			multiplier = 1 + (realmTier - 1) * 0.35
		end

		local ssReward = math.round((config.BaseSpiritStones or (config.Rewards and config.Rewards.SpiritStones) or 15) * multiplier)
		local qiReward = math.round((config.BaseQiReward or (config.Rewards and config.Rewards.CultivatedQi) or 35) * multiplier)

		if ssReward > 0 then
			PlayerDataManager.AddSpiritStones(killer, ssReward)
		end

		if qiReward > 0 then
			CultivationManager.AddInternalQi(killer, qiReward)
		end

		local drops = config.DropTable or config.Drops
		if drops then
			for _, drop in ipairs(drops) do
				local roll = math.random()
				local chance = drop.Chance
				if chance > 1 then chance = chance / 100 end
				if roll <= chance then
					local count = math.random(drop.MinCount or 1, drop.MaxCount or 1)
					InventoryManager.AddItem(killer, drop.ItemId, count)
				end
			end
		end

		pcall(function()
			local sectModule = ServerScriptService.Server.Cultivation:FindFirstChild("SectManager")
			if sectModule and sectModule:IsA("ModuleScript") then
				local SectManager = require(sectModule) :: any
				if type(SectManager.AddQuestProgress) == "function" then
					SectManager.AddQuestProgress(killer, "DefeatMob", mob.Id, 1)
				elseif type(SectManager.UpdateQuestProgress) == "function" then
					SectManager.UpdateQuestProgress(killer, "DefeatMob", mob.Id, 1)
				end
			end
		end)
	end

	for i, m in ipairs(activeMobs) do
		if m == mob then
			table.remove(activeMobs, i)
			break
		end
	end

	Debris:AddItem(mob.Model, 2)

	task.delay(mob.RespawnTime, function()
		if mob.AnchorPart and mob.AnchorPart.Parent then
			MobAIManager.SpawnMob(mob.Id, mob.AnchorPart, mob.SpawnRadius, mob.RespawnTime)
		end
	end)
end

function MobAIManager.SpawnMob(mobId: string, anchorPart: BasePart, spawnRadius: number, respawnTime: number)
	local config = GetMobConfig(mobId)
	if not config then
		warn(string.format("[MobAIManager] ERROR: '%s' not found in MobConfig. Check spelling in MobConfig.luau!", tostring(mobId)))
		return
	end

	local angle = math.random() * math.pi * 2
	local dist = math.random() * (spawnRadius * 0.5)
	local targetX = anchorPart.Position.X + math.cos(angle) * dist
	local targetZ = anchorPart.Position.Z + math.sin(angle) * dist

	local rayOrigin = Vector3.new(targetX, anchorPart.Position.Y + 30, targetZ)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { Workspace }
	rayParams.IgnoreWater = true
	local hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -60, 0), rayParams)
	local spawnY = if hit then hit.Position.Y + 3.5 else anchorPart.Position.Y + 3.5
	local finalSpawnPos = Vector3.new(targetX, spawnY, targetZ)

	local model: Model? = nil
	local mobFolder = ReplicatedStorage:FindFirstChild("MobModels")
	local template = mobFolder and mobFolder:FindFirstChild(mobId)

	if template and template:IsA("Model") then
		model = template:Clone()
	else
		warn(string.format("[MobAIManager] Template '%s' missing in ReplicatedStorage.MobModels!", mobId))
		return
	end

	model:PivotTo(CFrame.new(finalSpawnPos))

	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
		end
	end

	local spawnContainer = anchorPart.Parent
	if spawnContainer and spawnContainer.Name == "MobSpawns" then
		model.Parent = spawnContainer
	else
		model.Parent = Workspace:FindFirstChild("MobSpawns") or Workspace
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart") :: BasePart?

	if not humanoid or not rootPart then
		model:Destroy()
		warn("[MobAIManager] Spawned mob is missing Humanoid or HumanoidRootPart!")
		return
	end

	humanoid.MaxHealth = config.MaxHealth
	humanoid.Health = config.MaxHealth
	humanoid.WalkSpeed = config.WalkSpeed

	local oldHealthGui = model:FindFirstChild("MobHealthUI", true)
	if oldHealthGui then oldHealthGui:Destroy() end

	local healthGui, healthBar = CreateHealthUI(model, config.DisplayName)

	-- =========================================================================
	-- ANIMATIONS: WALK, RUN & 5-STEP M1 ATTACK COMBO
	-- =========================================================================
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local walkTrack: AnimationTrack? = nil
	local runTrack: AnimationTrack? = nil
	local attackTracks: { AnimationTrack } = {}

	-- 1. Martial Walk Animation (Patrol)
	local walkAnimId = AnimationConfig.Movement and (AnimationConfig.Movement :: any).Walk
	if walkAnimId and walkAnimId ~= "" then
		pcall(function()
			local animObj = Instance.new("Animation")
			animObj.AnimationId = walkAnimId
			walkTrack = animator:LoadAnimation(animObj)
			walkTrack.Looped = true
			walkTrack.Priority = Enum.AnimationPriority.Movement
		end)
	end

	-- 2. Martial Run Animation (Sprint Chase when player detected)
	local runAnimId = AnimationConfig.Movement and (AnimationConfig.Movement :: any).Run
	if runAnimId and runAnimId ~= "" then
		pcall(function()
			local animObj = Instance.new("Animation")
			animObj.AnimationId = runAnimId
			runTrack = animator:LoadAnimation(animObj)
			runTrack.Looped = true
			runTrack.Priority = Enum.AnimationPriority.Movement
		end)
	end

	-- 3. 5-Hit Attack Combo Sequence (M1_1 through M1_5)
	local swordCfg = AnimationConfig.FlyingSword :: any
	if swordCfg then
		for step = 1, 5 do
			local stepDef = swordCfg["M1_" .. tostring(step)]
			if stepDef and stepDef.AnimationId and stepDef.AnimationId ~= "" then
				pcall(function()
					local animObj = Instance.new("Animation")
					animObj.AnimationId = stepDef.AnimationId
					local track = animator:LoadAnimation(animObj)
					track.Looped = false
					track.Priority = Enum.AnimationPriority.Action4
					table.insert(attackTracks, track)
				end)
			end
		end
	end

	local mob: ActiveMob = {
		Id = mobId,
		Model = model,
		Humanoid = humanoid,
		RootPart = rootPart,
		Config = config,
		AnchorPart = anchorPart,
		SpawnPos = finalSpawnPos,
		SpawnRadius = spawnRadius,
		RespawnTime = respawnTime,
		State = "Patrol",
		TargetPlayer = nil,
		CurrentPath = nil,
		CurrentWaypointIndex = 1,
		Waypoints = {},
		LastAttackTime = 0,
		ComboStep = 1,
		LastPatrolTime = os.clock() + math.random(1, 4),
		PatrolTarget = finalSpawnPos,
		LastDamagePlayer = nil,
		LastDamageTime = 0,
		HealthGui = healthGui,
		HealthBar = healthBar,
		WalkTrack = walkTrack,
		RunTrack = runTrack,
		AttackTracks = attackTracks,
	}

	table.insert(activeMobs, mob)

	humanoid.HealthChanged:Connect(function(newHealth)
		if healthBar then
			local pct = math.clamp(newHealth / config.MaxHealth, 0, 1)
			healthBar.Size = UDim2.new(pct, 0, 1, 0)
		end
	end)

	humanoid.Died:Connect(function()
		OnMobDied(mob)
	end)

	print(string.format("[MobAIManager] Spawned '%s' with Walk, Run & Attack Combos!", config.DisplayName))
end

function MobAIManager.RecordDamage(mobModel: Model, attacker: Player)
	for _, mob in ipairs(activeMobs) do
		if mob.Model == mobModel then
			mob.LastDamagePlayer = attacker
			mob.LastDamageTime = os.clock()
			if mob.State == "Patrol" then
				mob.TargetPlayer = attacker
				mob.State = "Chase"
			end
			break
		end
	end
end

function MobAIManager.RegisterDamage(mobModel: Model, attacker: Player, _damage: number?)
	MobAIManager.RecordDamage(mobModel, attacker)
end

-- =============================================================================
-- SMART FLOCKING & BOIDS SEPARATION
-- =============================================================================
local function GetFlockSeparationVector(currentMob: ActiveMob): Vector3
	local repulsion = Vector3.zero
	local currentPos = currentMob.RootPart.Position
	local SEPARATION_RADIUS = 5.5

	for _, other in ipairs(activeMobs) do
		if other ~= currentMob and other.RootPart and other.RootPart.Parent and other.Humanoid.Health > 0 then
			local delta = currentPos - other.RootPart.Position
			local dist = delta.Magnitude
			if dist > 0.001 and dist < SEPARATION_RADIUS then
				-- Stronger push the closer they get
				local pushStrength = (SEPARATION_RADIUS - dist) / SEPARATION_RADIUS
				repulsion += Vector3.new(delta.X, 0, delta.Z).Unit * (pushStrength * 4.5)
			end
		end
	end

	return repulsion
end

local function StepAI()
	RebuildPlayerGrid()
	local now = os.clock()

	-- Track how many mobs are targeting each player to assign surrounding flank slots
	local targetCounts: { [Player]: number } = {}
	for _, mob in ipairs(activeMobs) do
		if mob.TargetPlayer and mob.State == "Chase" then
			targetCounts[mob.TargetPlayer] = (targetCounts[mob.TargetPlayer] or 0) + 1
		end
	end
	local mobIndexPerTarget: { [Player]: number } = {}

	for _, mob in ipairs(activeMobs) do
		local rootPart = mob.RootPart
		local humanoid = mob.Humanoid
		local config = mob.Config
		local anchor = mob.AnchorPart

		if not rootPart or not rootPart.Parent or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local rootPos = rootPart.Position
		local anchorPos = anchor and anchor.Position or mob.SpawnPos
		local distFromAnchor = (rootPos - anchorPos).Magnitude

		if distFromAnchor > (mob.SpawnRadius * 2.2) and mob.State ~= "Leash" then
			mob.State = "Leash"
			mob.TargetPlayer = nil
		end

		local state = mob.State

		-- Horizontal Velocity detection (Guaranteed accurate on server-owned NPCs)
		local horizVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, 0, rootPart.AssemblyLinearVelocity.Z)
		local horizSpeed = horizVelocity.Magnitude
		local isPhysicallyMoving = (horizSpeed > 0.4) and (state ~= "Attack")

		-- =====================================================================
		-- CONTEXTUAL LOCOMOTION ANIMATION MACHINE
		-- =====================================================================
		if state == "Chase" then
			-- RUNNING SPRINT: When chasing players
			if mob.WalkTrack and mob.WalkTrack.IsPlaying then mob.WalkTrack:Stop(0.12) end
			if mob.RunTrack then
				if isPhysicallyMoving and not mob.RunTrack.IsPlaying then
					mob.RunTrack:Play(0.15)
					mob.RunTrack:AdjustSpeed(math.clamp(humanoid.WalkSpeed / 20, 0.9, 1.4))
				elseif not isPhysicallyMoving and mob.RunTrack.IsPlaying then
					mob.RunTrack:Stop(0.15)
				end
			end
		elseif state == "Patrol" or state == "Leash" then
			-- MARTIAL WALK: When calmly patrolling or returning
			if mob.RunTrack and mob.RunTrack.IsPlaying then mob.RunTrack:Stop(0.12) end
			if mob.WalkTrack then
				if isPhysicallyMoving and not mob.WalkTrack.IsPlaying then
					mob.WalkTrack:Play(0.15)
					mob.WalkTrack:AdjustSpeed(math.clamp(humanoid.WalkSpeed / 14, 0.85, 1.3))
				elseif not isPhysicallyMoving and mob.WalkTrack.IsPlaying then
					mob.WalkTrack:Stop(0.15)
				end
			end
		else
			-- ATTACK / IDLE: Silence both
			if mob.WalkTrack and mob.WalkTrack.IsPlaying then mob.WalkTrack:Stop(0.1) end
			if mob.RunTrack and mob.RunTrack.IsPlaying then mob.RunTrack:Stop(0.1) end
		end

		if state == "Patrol" then
			humanoid.WalkSpeed = config.WalkSpeed * 0.65 -- Calm walk speed
			local candidates = GetNearbyPlayers(rootPos, config.AggroRadius)
			if #candidates > 0 then
				mob.TargetPlayer = candidates[1]
				mob.State = "Chase"
			else
				if now - mob.LastPatrolTime >= 5 then
					mob.LastPatrolTime = now
					local angle = math.random() * math.pi * 2
					local dist = math.random() * (mob.SpawnRadius * 0.7)
					mob.PatrolTarget = anchorPos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
					humanoid:MoveTo(mob.PatrolTarget)
				end
			end

		elseif state == "Chase" then
			-- RUN SPEED: Accelerate to full sprint upon player detection
			humanoid.WalkSpeed = config.WalkSpeed * 1.15

			local target = mob.TargetPlayer
			local targetChar = target and target.Character
			local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			local targetHum = targetChar and targetChar:FindFirstChild("Humanoid") :: Humanoid?

			if targetHrp and targetHum and targetHum.Health > 0 and target then
				local dist = (targetHrp.Position - rootPos).Magnitude
				if dist <= (config.AttackRange + 1.5) then
					mob.State = "Attack"
				else
					-- SMART FLOCKING: Calculate surrounding flank slot
					local totalAtTarget = math.max(1, targetCounts[target] or 1)
					local idx = (mobIndexPerTarget[target] or 0) + 1
					mobIndexPerTarget[target] = idx

					local flankAngle = ((idx - 1) / totalAtTarget) * (math.pi * 2)
					local surroundRadius = math.clamp(config.AttackRange * 0.85, 3.5, 6.0)

					-- Position around player + Boids push away from colliding teammates
					local surroundOffset = Vector3.new(math.cos(flankAngle) * surroundRadius, 0, math.sin(flankAngle) * surroundRadius)
					local separation = GetFlockSeparationVector(mob)
					local destination = targetHrp.Position + surroundOffset + separation

					humanoid:MoveTo(destination)
				end
			else
				mob.TargetPlayer = nil
				mob.State = "Patrol"
			end

		elseif state == "Attack" then
			local targetPlayer = mob.TargetPlayer
			local targetChar = targetPlayer and targetPlayer.Character
			local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			local targetHum = targetChar and targetChar:FindFirstChild("Humanoid") :: Humanoid?

			if targetHrp and targetHum and targetHum.Health > 0 then
				local dist = (targetHrp.Position - rootPos).Magnitude
				if dist <= (config.AttackRange + 2.5) then
					rootPart.CFrame = CFrame.lookAt(rootPos, Vector3.new(targetHrp.Position.X, rootPos.Y, targetHrp.Position.Z))

					if now - mob.LastAttackTime >= config.AttackCooldown then
						mob.LastAttackTime = now

						if (now - mob.LastAttackTime) > 2.2 then
							mob.ComboStep = 1
						end

						local currentStep = mob.ComboStep or 1
						if #mob.AttackTracks > 0 then
							local track = mob.AttackTracks[currentStep] or mob.AttackTracks[1]
							if track then
								track:Play(0.06, 1, 1.25)
							end
						end
						mob.ComboStep = if currentStep >= #mob.AttackTracks then 1 else currentStep + 1

						-- Apex Strike Delay (0.12s into slash)
						task.delay(0.12, function()
							if not rootPart.Parent or not targetHum or targetHum.Health <= 0 then return end
							local strikeDist = (targetHrp.Position - rootPart.Position).Magnitude
							if strikeDist > (config.AttackRange + 3.5) then return end

							local flatForward = Vector3.new(targetHrp.Position.X - rootPos.X, 0, targetHrp.Position.Z - rootPos.Z).Unit

							-- 1. Route through HitboxManager with valid HitResult structure
							local fakeHit: HitboxManager.HitResult = {
								Character = targetChar,
								Humanoid = targetHum,
								HitPart = targetHrp,
								TargetPlayer = targetPlayer,
							}

							local knockbackVector = Vector3.new(0, 4, 14)
							local res = HitboxManager.ApplyCombatResolution(nil, fakeHit, config.BaseDamage, 20, knockbackVector)

							-- 2. Broadcast Hit to Target Player for Camera Shake, Slashmarks, Sound & Numbers
							if combatActionRemote and targetPlayer then
								combatActionRemote:FireClient(targetPlayer, nil :: any, "M1", {
									HasHit = true,
									Damage = config.BaseDamage,
									TargetPosition = targetHrp.Position + Vector3.new(0, 0.4, 0),
									AttackerCFrame = rootPart.CFrame,
									AimDirection = flatForward,
									WasParried = if res then res.WasParried else false,
									WasBlocked = if res then res.WasBlocked else false,
									WasGuardBroken = if res then res.WasGuardBroken else false,
									Hits = {
										{
											Character = targetChar,
											HitPart = targetHrp,
											Position = targetHrp.Position,
										}
									}
								})
							end
						end)
					end
				else
					mob.State = "Chase"
				end
			else
				mob.TargetPlayer = nil
				mob.State = "Patrol"
			end

		elseif state == "Leash" then
			humanoid.WalkSpeed = config.WalkSpeed * 1.5
			humanoid:MoveTo(anchorPos)
			humanoid.Health = math.min(humanoid.Health + 20, config.MaxHealth)

			if (rootPos - anchorPos).Magnitude <= 5 then
				mob.State = "Patrol"
				mob.LastPatrolTime = now
			end
		end
	end
end

function MobAIManager.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	local spawnFolder = Workspace:FindFirstChild("MobSpawns") or Workspace:FindFirstChild("BeastSpawns")
	if not spawnFolder then
		spawnFolder = Instance.new("Folder")
		spawnFolder.Name = "MobSpawns"
		spawnFolder.Parent = Workspace
	end

	local function InitSpawner(anchor: Instance)
		if not anchor:IsA("BasePart") then return end

		local mobId = anchor:GetAttribute("MobId") :: string? or anchor:GetAttribute("BeastId") :: string? or "RogueDisciple"
		local spawnRadius = anchor:GetAttribute("SpawnRadius") :: number? or 30
		local maxCount = anchor:GetAttribute("MaxCount") :: number? or 3
		local respawnTime = anchor:GetAttribute("RespawnTime") :: number? or 20

		print(string.format("[MobAIManager] Activating Spawner anchor '%s' for '%s' (Count: %d)...", anchor.Name, mobId, maxCount))

		for _ = 1, maxCount do
			MobAIManager.SpawnMob(mobId, anchor, spawnRadius, respawnTime)
		end
	end

	for _, child in ipairs(spawnFolder:GetChildren()) do
		if child:IsA("BasePart") then
			InitSpawner(child)
		end
	end

	spawnFolder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			InitSpawner(child)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local ok, err = pcall(StepAI)
			if not ok then
				warn("[MobAIManager] Error in StepAI: " .. tostring(err))
			end
		end
	end)
end

return MobAIManager