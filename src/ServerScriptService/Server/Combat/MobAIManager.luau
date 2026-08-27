--!strict
--[[
    MobAIManager.luau
    Location: src/ServerScriptService/Server/Combat/MobAIManager.luau
    Server-authoritative R6 Zone Mob Spawner & AI Combat Manager.
    Features: PathfindingService-driven movement, aggro/leash cycles,
    damage-attributed kill credit, dynamic realm reward scaling, and quest kill sync.
]]

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")

local MobConfig = require(ReplicatedStorage.Shared.Configs.MobConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)

type ActiveMob = {
	Model: Model,
	Humanoid: Humanoid,
	RootPart: BasePart,
	MobDef: MobConfig.MobDefinition,
	SpawnAnchor: BasePart,
	SpawnRadius: number,
	RespawnTime: number,
	State: "Patrol" | "Chase" | "Attack" | "Leash" | "Dead",
	TargetPlayer: Player?,
	LastAttackTime: number,
	LastPatrolTime: number,
	-- Pathfinding
	PathWaypoints: { PathWaypoint }?,
	PathWaypointIndex: number,
	PathTargetPos: Vector3?,
	LastPathComputeTime: number,
	-- Damage attribution (for correct kill credit)
	LastDamagePlayer: Player?,
	LastDamageTime: number,
}

local MobAIManager = {}

local activeMobs: { [Model]: ActiveMob } = {}
local mobFolder: Folder

-- Pathfinding tuning
local PATH_RECOMPUTE_INTERVAL = 1.0 -- seconds between path recomputes per mob while chasing
local PATH_TARGET_MOVE_THRESHOLD = 4 -- studs; recompute early if target moved this far from last computed target
local PATH_WAYPOINT_REACH_DIST = 4 -- studs; distance to consider a waypoint "reached"
local PATH_AGENT_PARAMS = {
	AgentRadius = 3,
	AgentHeight = 5,
	AgentCanJump = false,
	WaypointSpacing = 4,
}

-- Kill-credit attribution window
local DAMAGE_ATTRIBUTION_WINDOW = 15 -- seconds; last hit must be this recent to count for kill credit

function MobAIManager.Init()
	mobFolder = Workspace:FindFirstChild("ActiveMobs") :: Folder
	if not mobFolder then
		mobFolder = Instance.new("Folder")
		mobFolder.Name = "ActiveMobs"
		mobFolder.Parent = Workspace
	end

	task.spawn(MobAIManager.SetupSpawners)

	-- Heartbeat AI update loop (Runs every 0.25s for high server performance)
	task.spawn(function()
		while true do
			task.wait(0.25)
			MobAIManager.UpdateAI()
		end
	end)

	print("[ASCEND] MobAIManager Initialized (PathfindingService Movement & Attributed Kill Credit Active).")
end

function MobAIManager.SetupSpawners()
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
		local maxCount = anchor:GetAttribute("MaxCount") :: number? or 2
		local respawnTime = anchor:GetAttribute("RespawnTime") :: number? or 20

		for _ = 1, maxCount do
			MobAIManager.SpawnMob(mobId, anchor, spawnRadius, respawnTime)
		end
	end

	for _, child in ipairs(spawnFolder:GetChildren()) do
		InitSpawner(child)
	end

	spawnFolder.ChildAdded:Connect(InitSpawner)
end

function MobAIManager.CreateR6Rig(mobDef: MobConfig.MobDefinition): (Model, Humanoid, BasePart)
	local model = Instance.new("Model")
	model.Name = mobDef.DisplayName

	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2, 2, 1)
	rootPart.Transparency = 1
	rootPart.CanCollide = false
	rootPart.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new("Dark stone grey")
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1.2, 1.2, 1.2)
	head.BrickColor = BrickColor.new("Pastel brown")
	head.Parent = model

	local rootJoint = Instance.new("Motor6D")
	rootJoint.Name = "RootJoint"
	rootJoint.Part0 = rootPart
	rootJoint.Part1 = torso
	rootJoint.Parent = rootPart

	local neck = Instance.new("Motor6D")
	neck.Name = "Neck"
	neck.Part0 = torso
	neck.Part1 = head
	neck.C0 = CFrame.new(0, 1, 0)
	neck.C1 = CFrame.new(0, -0.5, 0)
	neck.Parent = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = mobDef.MaxHealth
	humanoid.Health = mobDef.MaxHealth
	humanoid.WalkSpeed = mobDef.WalkSpeed
	humanoid.Parent = model

	model.PrimaryPart = rootPart

	-- 3D Overhead Health Bar
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "MobHealthUI"
	billboard.Size = UDim2.new(4, 0, 0.6, 0)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 60
	billboard.Parent = head

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = mobDef.DisplayName
	nameLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextScaled = true
	nameLabel.Parent = billboard

	local barBg = Instance.new("Frame")
	barBg.Size = UDim2.new(1, 0, 0.35, 0)
	barBg.Position = UDim2.new(0, 0, 0.45, 0)
	barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	barBg.BorderSizePixel = 0
	barBg.Parent = billboard

	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	humanoid.HealthChanged:Connect(function(health)
		barFill.Size = UDim2.new(math.clamp(health / humanoid.MaxHealth, 0, 1), 0, 1, 0)
	end)

	return model, humanoid, rootPart
end

function MobAIManager.SpawnMob(mobId: string, spawnAnchor: BasePart, spawnRadius: number, respawnTime: number)
	local mobDef = MobConfig.GetMob(mobId) or MobConfig.GetMob("RogueDisciple") :: MobConfig.MobDefinition
	local model, humanoid, rootPart = MobAIManager.CreateR6Rig(mobDef)

	local angle = math.random() * math.pi * 2
	local dist = math.random() * spawnRadius
	local spawnPos = spawnAnchor.Position + Vector3.new(math.cos(angle) * dist, 2, math.sin(angle) * dist)
	model:PivotTo(CFrame.new(spawnPos))
	model.Parent = mobFolder

	local activeMobData: ActiveMob = {
		Model = model,
		Humanoid = humanoid,
		RootPart = rootPart,
		MobDef = mobDef,
		SpawnAnchor = spawnAnchor,
		SpawnRadius = spawnRadius,
		RespawnTime = respawnTime,
		State = "Patrol",
		TargetPlayer = nil,
		LastAttackTime = 0,
		LastPatrolTime = 0,
		PathWaypoints = nil,
		PathWaypointIndex = 1,
		PathTargetPos = nil,
		LastPathComputeTime = 0,
		LastDamagePlayer = nil,
		LastDamageTime = 0,
	}

	activeMobs[model] = activeMobData

	humanoid.Died:Connect(function()
		MobAIManager.OnMobDied(activeMobData)
	end)
end

-- Called by HitboxManager whenever a mob takes damage from a player, so kill credit
-- reflects who actually fought the mob instead of whoever happened to have aggro.
function MobAIManager.RegisterDamage(mobModel: Model, player: Player, damage: number)
	local mob = activeMobs[mobModel]
	if not mob then return end
	mob.LastDamagePlayer = player
	mob.LastDamageTime = os.time()
end

-- Computes (or reuses) a path to `destination` for this mob, throttled to avoid
-- calling PathfindingService every 0.25s tick per mob.
function MobAIManager.ComputePathTo(mob: ActiveMob, destination: Vector3)
	local now = os.clock()

	local recentlyComputed = (now - mob.LastPathComputeTime) < PATH_RECOMPUTE_INTERVAL
	local targetBarelyMoved = mob.PathTargetPos and (mob.PathTargetPos - destination).Magnitude < PATH_TARGET_MOVE_THRESHOLD

	if recentlyComputed and targetBarelyMoved and mob.PathWaypoints then
		return -- Reuse the existing path; nothing meaningful has changed
	end

	mob.LastPathComputeTime = now
	mob.PathTargetPos = destination

	local path = PathfindingService:CreatePath(PATH_AGENT_PARAMS)
	local ok = pcall(function()
		path:ComputeAsync(mob.RootPart.Position, destination)
	end)

	if ok and path.Status == Enum.PathStatus.Success then
		mob.PathWaypoints = path:GetWaypoints()
		mob.PathWaypointIndex = 2 -- Waypoint 1 is always the mob's current position
	else
		mob.PathWaypoints = nil
		mob.PathWaypointIndex = 1
	end
end

-- Advances the mob one step along its currently computed path.
-- Returns false if there's no usable path (caller should fall back to direct MoveTo).
function MobAIManager.FollowPath(mob: ActiveMob): boolean
	local waypoints = mob.PathWaypoints
	if not waypoints or #waypoints == 0 then
		return false
	end

	if mob.PathWaypointIndex > #waypoints then
		mob.PathWaypoints = nil
		return false
	end

	local mobPos = mob.RootPart.Position
	local waypoint = waypoints[mob.PathWaypointIndex]
	local flatDist = (Vector3.new(waypoint.Position.X, mobPos.Y, waypoint.Position.Z) - mobPos).Magnitude

	if flatDist <= PATH_WAYPOINT_REACH_DIST then
		mob.PathWaypointIndex += 1
		if mob.PathWaypointIndex > #waypoints then
			mob.PathWaypoints = nil
			return false
		end
		waypoint = waypoints[mob.PathWaypointIndex]
	end

	if waypoint.Action == Enum.PathWaypointAction.Jump then
		mob.Humanoid.Jump = true
	end

	mob.Humanoid:MoveTo(waypoint.Position)
	return true
end

function MobAIManager.UpdateAI()
	local now = os.time()

	for model, mob in pairs(activeMobs) do
		if mob.State == "Dead" or mob.Humanoid.Health <= 0 then continue end

		local mobPos = mob.RootPart.Position
		local anchorPos = mob.SpawnAnchor.Position
		local distFromAnchor = (mobPos - anchorPos).Magnitude

		-- Leash check: Return if pulled too far from spawner
		if distFromAnchor > mob.SpawnRadius * 2.2 then
			mob.State = "Leash"
			mob.TargetPlayer = nil
			mob.PathWaypoints = nil
			mob.Humanoid.WalkSpeed = mob.MobDef.WalkSpeed * 1.5
			mob.Humanoid:MoveTo(anchorPos)
			mob.Humanoid.Health = math.min(mob.Humanoid.MaxHealth, mob.Humanoid.Health + 20)
			if (mobPos - anchorPos).Magnitude < 6 then
				mob.State = "Patrol"
				mob.Humanoid.WalkSpeed = mob.MobDef.WalkSpeed
			end
			continue
		end

		-- Target detection
		local targetPlayer: Player? = nil
		local closestDist = mob.MobDef.AggroRadius

		for _, player in ipairs(Players:GetPlayers()) do
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char and char:FindFirstChild("Humanoid") :: Humanoid?

			if hrp and hum and hum.Health > 0 then
				local dist = (hrp.Position - mobPos).Magnitude
				if dist < closestDist then
					closestDist = dist
					targetPlayer = player
				end
			end
		end

		mob.TargetPlayer = targetPlayer

		if targetPlayer and targetPlayer.Character then
			local playerHrp = targetPlayer.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if playerHrp then
				local distToPlayer = (playerHrp.Position - mobPos).Magnitude

				if distToPlayer <= mob.MobDef.AttackRange then
					-- Attack State
					mob.State = "Attack"
					mob.PathWaypoints = nil
					mob.Humanoid:MoveTo(mobPos) -- Stop moving to attack

					if now - mob.LastAttackTime >= mob.MobDef.AttackCooldown then
						mob.LastAttackTime = now
						local playerHum = targetPlayer.Character:FindFirstChild("Humanoid") :: Humanoid?
						if playerHum and playerHum.Health > 0 then
							playerHum:TakeDamage(mob.MobDef.BaseDamage)
						end
					end
				else
					-- Chase State (PathfindingService-driven, with direct-MoveTo fallback)
					mob.State = "Chase"
					mob.Humanoid.WalkSpeed = mob.MobDef.WalkSpeed
					MobAIManager.ComputePathTo(mob, playerHrp.Position)
					if not MobAIManager.FollowPath(mob) then
						mob.Humanoid:MoveTo(playerHrp.Position)
					end
				end
			end
		else
			-- Patrol State (PathfindingService-driven, with direct-MoveTo fallback)
			mob.State = "Patrol"
			if now - mob.LastPatrolTime > 5 then
				mob.LastPatrolTime = now
				local angle = math.random() * math.pi * 2
				local dist = math.random() * (mob.SpawnRadius * 0.7)
				local targetPos = anchorPos + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
				mob.Humanoid.WalkSpeed = mob.MobDef.WalkSpeed * 0.7
				MobAIManager.ComputePathTo(mob, targetPos)
			end
			if not MobAIManager.FollowPath(mob) and mob.PathTargetPos then
				mob.Humanoid:MoveTo(mob.PathTargetPos)
			end
		end
	end
end

function MobAIManager.OnMobDied(mob: ActiveMob)
	mob.State = "Dead"
	activeMobs[mob.Model] = nil

	local killer: Player? = nil
	if mob.LastDamagePlayer and (os.time() - mob.LastDamageTime) <= DAMAGE_ATTRIBUTION_WINDOW then
		killer = mob.LastDamagePlayer
	end

	if killer then
		local cultivation = CultivationManager.GetPlayerData(killer)
		local realmIndex = cultivation and CultivationConfig.GetRealmIndex(cultivation.Realm) or 1

		-- Realm-Ranked Reward Scaling Formula
		local multiplier = 1 + (realmIndex - 1) * 0.35
		local scaledStones = math.floor(mob.MobDef.BaseSpiritStones * multiplier)
		local scaledQi = math.floor(mob.MobDef.BaseQiReward * multiplier)

		PlayerDataManager.AddSpiritStones(killer, scaledStones)
		CultivationManager.AddCultivatedQi(killer, scaledQi)

		-- Drop Table Rolls
		for _, drop in ipairs(mob.MobDef.DropTable) do
			if math.random() <= drop.Chance then
				local count = math.random(drop.MinCount, drop.MaxCount)
				InventoryManager.AddItem(killer, drop.ItemId, count)
			end
		end

		-- Sync Quest Kill Progress
		SectManager.AddQuestProgress(killer, "DefeatMob", mob.MobDef.MobId, 1)

		print(string.format("[MobAIManager] %s defeated %s (+%d Stones, +%d Qi [Mult: %.2f]).",
			killer.Name, mob.MobDef.DisplayName, scaledStones, scaledQi, multiplier))
	else
		print(string.format("[MobAIManager] %s died with no valid recent damager on record — no rewards granted.", mob.MobDef.DisplayName))
	end

	Debris:AddItem(mob.Model, 2)

	-- Respawn after timer
	task.delay(mob.RespawnTime, function()
		MobAIManager.SpawnMob(mob.MobDef.MobId, mob.SpawnAnchor, mob.SpawnRadius, mob.RespawnTime)
	end)
end

return MobAIManager