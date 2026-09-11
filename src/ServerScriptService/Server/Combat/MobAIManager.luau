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

-- Real MobConfig resolver (No fallbacks)
local function GetMobConfig(mobId: string): any
	local cleanId = string.match(tostring(mobId), "^%s*(.-)%s*$") or tostring(mobId)

	-- 1. Official getter function
	if type(MobConfig.GetMobConfig) == "function" then
		local res = MobConfig.GetMobConfig(cleanId)
		if res then return res end
	end
	if type(MobConfig.GetMob) == "function" then
		local res = MobConfig.GetMob(cleanId)
		if res then return res end
	end

	-- 2. Direct dictionary lookup
	if type(MobConfig.Mobs) == "table" and MobConfig.Mobs[cleanId] then
		return MobConfig.Mobs[cleanId]
	end
	if MobConfig[cleanId] then
		return MobConfig[cleanId]
	end

	-- 3. Case-insensitive search
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

local function OnMobDied(mob: ActiveMob)
	if mob.WalkTrack then pcall(function() mob.WalkTrack:Stop(0.1) end) end
	if mob.AttackTracks then
		for _, track in ipairs(mob.AttackTracks) do pcall(function() track:Stop(0.1) end) end
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

		local ssReward = math.round((config.BaseSpiritStones or (config.Rewards and config.Rewards.SpiritStones) or 15) * multiplier)
		local qiReward = math.round((config.BaseQiReward or (config.Rewards and config.Rewards.CultivatedQi) or 35) * multiplier)

		if profile and profile.Stats then
			profile.Stats.SpiritStones = (profile.Stats.SpiritStones or 0) + ssReward
		end

		if profile and profile.Cultivation then
			profile.Cultivation.Qi = math.min((profile.Cultivation.Qi or 0) + qiReward, profile.Cultivation.MaxQi or 1000)
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
		warn(string.format("[MobAIManager] ERROR: '%s' not found in MobConfig. Check spelling in MobConfig.luau!", tostring(mobId)))
		return
	end

	local angle = math.random() * math.pi * 2
	local dist = math.random() * (spawnRadius * 0.5)
	local targetX = anchorPart.Position.X + math.cos(angle) * dist
	local targetZ = anchorPart.Position.Z + math.sin(angle) * dist

	-- Raycast down to find ground level
	local rayOrigin = Vector3.new(targetX, anchorPart.Position.Y + 30, targetZ)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { Workspace }
	rayParams.IgnoreWater = true
	local hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -60, 0), rayParams)
	local spawnY = if hit then hit.Position.Y + 3.5 else anchorPart.Position.Y + 3.5
	local finalSpawnPos = Vector3.new(targetX, spawnY, targetZ)

	-- Clone template from ReplicatedStorage.MobModels
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

	-- PARENT DIRECTLY TO MobSpawns FOLDER
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

	-- Health UI
	local healthGui = model:FindFirstChild("MobHealthUI", true) :: BillboardGui?
	local healthBar = nil
	if healthGui then
		local barBg = healthGui:FindFirstChild("BarBg")
		healthBar = barBg and barBg:FindFirstChild("Fill") :: Frame?
	else
		healthGui, healthBar = CreateHealthUI(model, config.DisplayName)
	end

	-- Animation Tracks
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local walkTrack: AnimationTrack? = nil
	local attackTracks: { AnimationTrack } = {}

	local animFolder = model:FindFirstChild("Animations")
	if animFolder then
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
		SpawnPos = finalSpawnPos,
		SpawnRadius = spawnRadius,
		RespawnTime = respawnTime,
		State = "Patrol",
		TargetPlayer = nil,
		CurrentPath = nil,
		CurrentWaypointIndex = 1,
		Waypoints = {},
		LastAttackTime = 0,
		LastPatrolTime = os.clock() + math.random(1, 4),
		PatrolTarget = finalSpawnPos,
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

	print(string.format("[MobAIManager] Spawned real '%s' (HP: %.0f, Dmg: %.0f) into MobSpawns folder at (%.1f, %.1f, %.1f)!", config.DisplayName, config.MaxHealth, config.BaseDamage, finalSpawnPos.X, finalSpawnPos.Y, finalSpawnPos.Z))
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
		local anchorPos = anchor and anchor.Position or mob.SpawnPos
		local distFromAnchor = (rootPos - anchorPos).Magnitude

		if distFromAnchor > (mob.SpawnRadius * 2.2) and mob.State ~= "Leash" then
			mob.State = "Leash"
			mob.TargetPlayer = nil
		end

		local state = mob.State

		-- Walk Animation update
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
					local path = PathfindingService:CreatePath({ AgentRadius = 2.5, AgentHeight = 5, AgentCanJump = false })
					local success = pcall(function() path:ComputeAsync(rootPos, targetHrp.Position) end)
					if success and path.Status == Enum.PathStatus.Success then
						local wps = path:GetWaypoints()
						humanoid:MoveTo(wps[2] and wps[2].Position or targetHrp.Position)
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