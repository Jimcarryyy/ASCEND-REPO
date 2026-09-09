local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local MobConfig = require(ReplicatedStorage.Shared.Configs.MobConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local InventoryManager = require(script.Parent.Parent.State.InventoryManager)
local PlayerDataManager = require(script.Parent.Parent.State.PlayerDataManager)
local SectManager = require(script.Parent.Parent.Cultivation.SectManager)

local MobAIManager = {}

type MobState = "Patrol" | "Chase" | "Attack" | "Leash"

type ActiveMob = {
	Id: string,
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	Config: any,
	AnchorPart: BasePart,
	SpawnRadius: number,
	RespawnTime: number,
	State: MobState,
	TargetPlayer: Player?,
	CurrentPath: Path?,
	CurrentWaypointIndex: number,
	Waypoints: { PathWaypoint },
	LastAttackTime: number,
	LastPatrolTime: number,
	PatrolTarget: Vector3,
	LastDamagePlayer: Player?,
	LastDamageTime: number,
	HealthGui: BillboardGui?,
	HealthBar: Frame?,
	WalkTrack: AnimationTrack?,
	AttackTracks: { AnimationTrack }?,
}

local activeMobs: { ActiveMob } = {}

-- Safe config resolver (handles MobConfig.Mobs, GetMobConfig, or direct table)
local function GetMobConfig(mobId: string): any
	if (MobConfig :: any).Mobs and (MobConfig :: any).Mobs[mobId] then
		return (MobConfig :: any).Mobs[mobId]
	elseif type((MobConfig :: any).GetMobConfig) == "function" then
		return (MobConfig :: any).GetMobConfig(mobId)
	else
		return (MobConfig :: any)[mobId]
	end
end

-- Spatial grid for fast, low-cost player lookups
local playerGrid: { [string]: { Player } } = {}
local GRID_CELL_SIZE = 50

local function GetGridKey(pos: Vector3): string
	local cx = math.floor(pos.X / GRID_CELL_SIZE)
	local cz = math.floor(pos.Z / GRID_CELL_SIZE)
	return cx .. ":" .. cz
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
				if not playerGrid[key] then
					playerGrid[key] = {}
				end
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

local function CreateHealthUI(model: Model, displayName: string): (BillboardGui?, Frame?)
	local head = model:FindFirstChild("Head") or model.PrimaryPart
	if not head then return nil, nil end

	local bb = Instance.new("BillboardGui")
	bb.Name = "MobHealthUI"
	bb.Size = UDim2.new(0, 120, 0, 24)
	bb.StudsOffset = Vector3.new(0, 2.5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 60
	bb.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0, 14)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = displayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Font = Enum.Font.SourceSansBold
	nameLabel.TextSize = 13
	nameLabel.Parent = bb

	local barBg = Instance.new("Frame")
	barBg.Name = "BarBg"
	barBg.Size = UDim2.new(1, 0, 0, 6)
	barBg.Position = UDim2.new(0, 0, 0, 16)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	barBg.BorderSizePixel = 0
	barBg.Parent = bb

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	fill.BorderSizePixel = 0
	fill.Parent = barBg

	return bb, fill
end

local function CreateFallbackR6Rig(mobId: string, displayName: string, config: any): Model
	local model = Instance.new("Model")
	model.Name = mobId

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Transparency = 1
	hrp.CanCollide = false
	hrp.Parent = model
	model.PrimaryPart = hrp

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.Color = Color3.fromRGB(60, 40, 50)
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.Color = Color3.fromRGB(200, 180, 160)
	head.Parent = model

	local headMesh = Instance.new("SpecialMesh")
	headMesh.MeshType = Enum.MeshType.Head
	headMesh.Scale = Vector3.new(1.25, 1.25, 1.25)
	headMesh.Parent = head

	local rArm = Instance.new("Part")
	rArm.Name = "Right Arm"
	rArm.Size = Vector3.new(1, 2, 1)
	rArm.Color = Color3.fromRGB(200, 180, 160)
	rArm.Parent = model

	local lArm = Instance.new("Part")
	lArm.Name = "Left Arm"
	lArm.Size = Vector3.new(1, 2, 1)
	lArm.Color = Color3.fromRGB(200, 180, 160)
	lArm.Parent = model

	local rLeg = Instance.new("Part")
	rLeg.Name = "Right Leg"
	rLeg.Size = Vector3.new(1, 2, 1)
	rLeg.Color = Color3.fromRGB(40, 40, 45)
	rLeg.Parent = model

	local lLeg = Instance.new("Part")
	lLeg.Name = "Left Leg"
	lLeg.Size = Vector3.new(1, 2, 1)
	lLeg.Color = Color3.fromRGB(40, 40, 45)
	lLeg.Parent = model

	local function AddMotor(name: string, p0: BasePart, p1: BasePart, c0: CFrame, c1: CFrame)
		local m = Instance.new("Motor6D")
		m.Name = name
		m.Part0 = p0
		m.Part1 = p1
		m.C0 = c0
		m.C1 = c1
		m.Parent = p0
	end

	AddMotor("RootJoint", hrp, torso, CFrame.new(0, 0, 0) * CFrame.Angles(-math.pi/2, 0, math.pi), CFrame.new(0, 0, 0) * CFrame.Angles(-math.pi/2, 0, math.pi))
	AddMotor("Neck", torso, head, CFrame.new(0, 1, 0) * CFrame.Angles(-math.pi/2, 0, math.pi), CFrame.new(0, -0.5, 0) * CFrame.Angles(-math.pi/2, 0, math.pi))
	AddMotor("Right Shoulder", torso, rArm, CFrame.new(1, 0.5, 0) * CFrame.Angles(0, math.pi/2, 0), CFrame.new(-0.5, 0.5, 0) * CFrame.Angles(0, math.pi/2, 0))
	AddMotor("Left Shoulder", torso, lArm, CFrame.new(-1, 0.5, 0) * CFrame.Angles(0, -math.pi/2, 0), CFrame.new(0.5, 0.5, 0) * CFrame.Angles(0, -math.pi/2, 0))
	AddMotor("Right Hip", torso, rLeg, CFrame.new(1, -1, 0) * CFrame.Angles(0, math.pi/2, 0), CFrame.new(0.5, 1, 0) * CFrame.Angles(0, math.pi/2, 0))
	AddMotor("Left Hip", torso, lLeg, CFrame.new(-1, -1, 0) * CFrame.Angles(0, -math.pi/2, 0), CFrame.new(-0.5, 1, 0) * CFrame.Angles(0, -math.pi/2, 0))

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R6
	humanoid.MaxHealth = config.MaxHealth
	humanoid.Health = config.MaxHealth
	humanoid.WalkSpeed = config.WalkSpeed
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.Parent = model

	return model
end

local function OnMobDied(mob: ActiveMob)
	if mob.WalkTrack then
		pcall(function() mob.WalkTrack:Stop(0.1) end)
	end
	if mob.AttackTracks then
		for _, track in ipairs(mob.AttackTracks) do
			pcall(function() track:Stop(0.1) end)
		end
	end

	local killer = mob.LastDamagePlayer
	local now = os.clock()

	if killer and (now - mob.LastDamageTime) <= 15 then
		local config = mob.Config
		local profile = PlayerDataManager.GetProfile(killer)
		local multiplier = 1.0

		if profile and profile.Cultivation then
			local realmIdx = profile.Cultivation.MajorRealm or 1
			multiplier = 1 + (realmIdx - 1) * 0.35
		end

		local ssReward = math.round((config.Rewards and config.Rewards.SpiritStones or 10) * multiplier)
		local qiReward = math.round((config.Rewards and config.Rewards.CultivatedQi or 20) * multiplier)

		if profile and profile.Stats then
			profile.Stats.SpiritStones = (profile.Stats.SpiritStones or 0) + ssReward
		end

		if profile and profile.Cultivation then
			profile.Cultivation.Qi = math.min(
				(profile.Cultivation.Qi or 0) + qiReward,
				profile.Cultivation.MaxQi or 1000
			)
		end

		if config.Drops then
			for _, drop in ipairs(config.Drops) do
				local roll = math.random() * 100
				if roll <= drop.Chance then
					local count = math.random(drop.MinCount or 1, drop.MaxCount or 1)
					InventoryManager.AddItem(killer, drop.ItemId, count)
				end
			end
		end

		SectManager.AddQuestProgress(killer, "DefeatMob", mob.Id, 1)
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
		warn(string.format("[MobAIManager] Could not find config for mob: '%s' in MobConfig.Mobs!", tostring(mobId)))
		return
	end

	local angle = math.random() * math.pi * 2
	local dist = math.random() * (spawnRadius * 0.5)
	local spawnPos = anchorPart.Position + Vector3.new(math.cos(angle) * dist, 2, math.sin(angle) * dist)

	-- 1. Grab master template from ReplicatedStorage.MobModels
	local model: Model
	local mobFolder = ReplicatedStorage:FindFirstChild("MobModels")
	local template = mobFolder and mobFolder:FindFirstChild(mobId)

	if template and template:IsA("Model") then
		model = template:Clone()
	else
		model = CreateFallbackR6Rig(mobId, config.DisplayName, config)
	end

	model:PivotTo(CFrame.new(spawnPos))

	-- Unanchor all parts so the mob can walk freely
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
		end
	end

	model.Parent = Workspace

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

	-- 2. Setup Health UI
	local healthGui = model:FindFirstChild("MobHealthUI", true) :: BillboardGui?
	local healthBar = nil
	if healthGui then
		local barBg = healthGui:FindFirstChild("BarBg")
		healthBar = barBg and barBg:FindFirstChild("Fill") :: Frame?
	else
		healthGui, healthBar = CreateHealthUI(model, config.DisplayName)
	end

	-- 3. Load Animation Tracks
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end

	local walkTrack: AnimationTrack? = nil
	local attackTracks: { AnimationTrack } = {}

	local animFolder = model:FindFirstChild("Animations")
	if animator and animFolder then
		local walkAnim = animFolder:FindFirstChild("WalkAnimation") :: Animation?
		if walkAnim and walkAnim.AnimationId ~= "" then
			pcall(function()
				walkTrack = animator:LoadAnimation(walkAnim)
				walkTrack.Looped = true
				walkTrack.Priority = Enum.AnimationPriority.Movement
			end)
		end

		for _, attName in ipairs({ "Attack1", "Attack2" }) do
			local attAnim = animFolder:FindFirstChild(attName) :: Animation?
			if attAnim and attAnim.AnimationId ~= "" then
				pcall(function()
					local track = animator:LoadAnimation(attAnim)
					track.Looped = false
					track.Priority = Enum.AnimationPriority.Action
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
		SpawnRadius = spawnRadius,
		RespawnTime = respawnTime,
		State = "Patrol",
		TargetPlayer = nil,
		CurrentPath = nil,
		CurrentWaypointIndex = 1,
		Waypoints = {},
		LastAttackTime = 0,
		LastPatrolTime = os.clock() + math.random(1, 4),
		PatrolTarget = spawnPos,
		LastDamagePlayer = nil,
		LastDamageTime = 0,
		HealthGui = healthGui,
		HealthBar = healthBar,
		WalkTrack = walkTrack,
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

	print(string.format("[MobAIManager] Successfully spawned '%s' at (%.1f, %.1f, %.1f)!", mobId, spawnPos.X, spawnPos.Y, spawnPos.Z))
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

local function StepAI()
	RebuildPlayerGrid()
	local now = os.clock()

	for _, mob in ipairs(activeMobs) do
		local rootPart = mob.RootPart
		local humanoid = mob.Humanoid
		local config = mob.Config
		local anchor = mob.AnchorPart

		if not rootPart or not rootPart.Parent or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local rootPos = rootPart.Position
		local anchorPos = anchor.Position
		local distFromAnchor = (rootPos - anchorPos).Magnitude

		if distFromAnchor > (mob.SpawnRadius * 2.2) and mob.State ~= "Leash" then
			mob.State = "Leash"
			mob.TargetPlayer = nil
		end

		local state = mob.State

		-- Animation Walk Cycle Update
		if mob.WalkTrack then
			local isMoving = humanoid.MoveDirection.Magnitude > 0.05
			if isMoving and not mob.WalkTrack.IsPlaying then
				mob.WalkTrack:Play(0.2)
			elseif not isMoving and mob.WalkTrack.IsPlaying then
				mob.WalkTrack:Stop(0.2)
			end
		end

		if state == "Patrol" then
			humanoid.WalkSpeed = config.WalkSpeed * 0.7

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
			humanoid.WalkSpeed = config.WalkSpeed
			local target = mob.TargetPlayer
			local targetChar = target and target.Character
			local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart") :: BasePart?
			local targetHum = targetChar and targetChar:FindFirstChild("Humanoid") :: Humanoid?

			if targetHrp and targetHum and targetHum.Health > 0 then
				local dist = (targetHrp.Position - rootPos).Magnitude
				if dist <= config.AttackRange then
					mob.State = "Attack"
				else
					local path = PathfindingService:CreatePath({
						AgentRadius = 2.5,
						AgentHeight = 5,
						AgentCanJump = false,
					})
					local success = pcall(function()
						path:ComputeAsync(rootPos, targetHrp.Position)
					end)

					if success and path.Status == Enum.PathStatus.Success then
						local wps = path:GetWaypoints()
						if #wps >= 2 then
							humanoid:MoveTo(wps[2].Position)
						else
							humanoid:MoveTo(targetHrp.Position)
						end
					else
						humanoid:MoveTo(targetHrp.Position)
					end
				end
			else
				mob.TargetPlayer = nil
				mob.State = "Patrol"
			end

		elseif state == "Attack" then
			if mob.TargetPlayer and mob.TargetPlayer.Character then
				local targetHrp = mob.TargetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				local targetHum = mob.TargetPlayer.Character:FindFirstChild("Humanoid") :: Humanoid?

				if targetHrp and targetHum and targetHum.Health > 0 then
					local dist = (targetHrp.Position - rootPos).Magnitude
					if dist <= config.AttackRange then
						rootPart.CFrame = CFrame.lookAt(rootPos, Vector3.new(targetHrp.Position.X, rootPos.Y, targetHrp.Position.Z))

						if now - mob.LastAttackTime >= config.AttackCooldown then
							mob.LastAttackTime = now

							if mob.WalkTrack and mob.WalkTrack.IsPlaying then
								mob.WalkTrack:Stop(0.15)
							end

							if mob.AttackTracks and #mob.AttackTracks > 0 then
								local track = mob.AttackTracks[math.random(1, #mob.AttackTracks)]
								track:Play(0.1)
							end

							targetHum:TakeDamage(config.BaseDamage)
						end
					else
						mob.State = "Chase"
					end
				else
					mob.TargetPlayer = nil
					mob.State = "Patrol"
				end
			else
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

		print(string.format("[MobAIManager] Activating Spawner anchor '%s' for '%s' (Count: %d, Radius: %d studs)...", anchor.Name, mobId, maxCount, spawnRadius))

		for _ = 1, maxCount do
			MobAIManager.SpawnMob(mobId, anchor, spawnRadius, respawnTime)
		end
	end

	for _, child in ipairs(spawnFolder:GetChildren()) do
		InitSpawner(child)
	end

	spawnFolder.ChildAdded:Connect(InitSpawner)

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