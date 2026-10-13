--!strict
--[[
    LootChestManager.luau
    Location: src/ServerScriptService/Server/World/LootChestManager.luau
    Authoritative world loot chest engine for Sovereign Boss victories.
    Calculates exact terrain floor contact so the chest never floats in mid-air.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local MonsterConfig = require(ReplicatedStorage.Shared.Configs.MonsterConfig)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local LootChestManager = {}

local activeChests: { [Model]: { [number]: boolean } } = {}
local chestContainer: Folder? = nil

local function GetChestContainer(): Folder
	if not chestContainer then
		local found = Workspace:FindFirstChild("ActiveLootChests") :: Folder?
		if not found then
			found = Instance.new("Folder")
			found.Name = "ActiveLootChests"
			found.Parent = Workspace
		end
		chestContainer = found
	end
	return chestContainer :: Folder
end

local function GetChestTemplate(): Model?
	local template = ReplicatedStorage:FindFirstChild("Assets")
		and ReplicatedStorage.Assets:FindFirstChild("Rewards")
		and ReplicatedStorage.Assets.Rewards:FindFirstChild("BossChest") :: Model?

	if not template then
		template = Workspace:FindFirstChild("WorldMaterial")
			and Workspace.WorldMaterial:FindFirstChild("Rewards")
			and Workspace.WorldMaterial.Rewards:FindFirstChild("BossChest") :: Model?
	end

	return template
end

-- =============================================================================
-- 3D CHEST INSTANTIATION WITH FLUSH GROUND CONTACT
-- =============================================================================

local function CreateChestInstance(displayName: string, groundPosition: Vector3): Model
	local template = GetChestTemplate()
	local chestModel: Model

	if template then
		chestModel = template:Clone()
		chestModel.Name = displayName .. " Chest"
		if not chestModel.PrimaryPart then
			chestModel.PrimaryPart = chestModel:FindFirstChildWhichIsA("BasePart")
		end
	else
		chestModel = Instance.new("Model")
		chestModel.Name = displayName .. " Chest"
		local base = Instance.new("Part")
		base.Name = "ChestBase"
		base.Size = Vector3.new(4, 2.5, 3)
		base.Material = Enum.Material.Slate
		base.Color = Color3.fromRGB(40, 30, 25)
		base.Anchored = true
		base.Parent = chestModel
		chestModel.PrimaryPart = base
	end

	-- Lock all child parts
	for _, part in ipairs(chestModel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = true
		end
	end

	-- Compute bounding box to set exact ground contact height
	local _, boxSize = chestModel:GetBoundingBox()
	local targetY = groundPosition.Y + (boxSize.Y * 0.5)
	local flushCFrame = CFrame.new(groundPosition.X, targetY, groundPosition.Z)
	chestModel:PivotTo(flushCFrame)

	local rootPart = chestModel.PrimaryPart or chestModel:FindFirstChildWhichIsA("BasePart")
	if rootPart then
		-- Spirit Glow Light
		local light = Instance.new("PointLight")
		light.Name = "ChestGlow"
		light.Color = Color3.fromRGB(255, 215, 80)
		light.Brightness = 2.8
		light.Range = 22
		light.Parent = rootPart

		-- Vertical Celestial Beacon Beam
		local beacon = Instance.new("Part")
		beacon.Name = "Beacon"
		beacon.Size = Vector3.new(1.2, 50, 1.2)
		beacon.Material = Enum.Material.Neon
		beacon.Color = Color3.fromRGB(255, 220, 100)
		beacon.Transparency = 0.65
		beacon.Anchored = true
		beacon.CanCollide = false
		beacon.CFrame = flushCFrame * CFrame.new(0, 25, 0)
		beacon.Parent = chestModel

		-- Golden Spirit Particle Emitter
		local emitter = Instance.new("ParticleEmitter")
		emitter.Name = "GoldenMotes"
		emitter.Texture = "rbxassetid://6034444583"
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 90))
		emitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 0),
		})
		emitter.Lifetime = NumberRange.new(1.6, 2.4)
		emitter.Rate = 20
		emitter.Speed = NumberRange.new(2, 5)
		emitter.SpreadAngle = Vector2.new(35, 35)
		emitter.EmissionDirection = Enum.NormalId.Top
		emitter.Parent = rootPart
	end

	return chestModel
end

-- =============================================================================
-- SPAWN & CLAIM PIPELINE
-- =============================================================================

function LootChestManager.SpawnBossChest(
	position: Vector3,
	bossId: string,
	bossDisplayName: string,
	_eligiblePlayers: { Player }
)
	-- Raycast down to find true floor level (exclude characters, monsters, chests)
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local ignoreList: { Instance } = {}
	local activeMonsters = Workspace:FindFirstChild("ActiveMonsters")
	if activeMonsters then table.insert(ignoreList, activeMonsters) end
	local lootChests = Workspace:FindFirstChild("ActiveLootChests")
	if lootChests then table.insert(ignoreList, lootChests) end
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then table.insert(ignoreList, p.Character) end
	end
	rayParams.FilterDescendantsInstances = ignoreList

	-- Cast straight down from 25 studs above the defeat position
	local rayOrigin = Vector3.new(position.X, position.Y + 25.0, position.Z)
	local rayResult = Workspace:Raycast(rayOrigin, Vector3.new(0, -75, 0), rayParams)
	local groundContactPos = if rayResult then rayResult.Position else position

	local chestModel = CreateChestInstance(bossDisplayName, groundContactPos)
	chestModel.Parent = GetChestContainer()

	activeChests[chestModel] = {}

	-- Broadcast Heavenly Announcement
	local heavenlyRemote = RemoteEvents.GetRemote("HeavenlyAnnouncement") :: RemoteEvent?
	if heavenlyRemote then
		heavenlyRemote:FireAllClients({
			Message = string.format("SOVEREIGN TRIUMPH: The ancient treasure chest of %s has manifested!", bossDisplayName),
			Duration = 6.0,
			BannerColor = "Gold",
		})
	end

	local triggerPart = chestModel.PrimaryPart or chestModel:FindFirstChildWhichIsA("BasePart")
	if not triggerPart then return end

	-- Attach ProximityPrompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = bossDisplayName
	prompt.ActionText = "Claim Sovereign Loot"
	prompt.HoldDuration = 0.8
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = triggerPart

	prompt.Triggered:Connect(function(player: Player)
		local claimed = activeChests[chestModel]
		if not claimed then return end

		if claimed[player.UserId] then
			local vfxRemote = RemoteEvents.GetRemote("CombatVFX") :: RemoteEvent?
			if vfxRemote and player.Character then
				vfxRemote:FireClient(player, {
					EffectType = "MessagePopup",
					Text = "You have already claimed this sovereign treasure!",
				})
			end
			return
		end

		claimed[player.UserId] = true

		-- Award bonus Qi & Spirit Stones
		local mDef = MonsterConfig.GetMonster(bossId)
		local bonusQi = if mDef then math.floor(mDef.BaseQiReward * 0.75) else 8000
		local bonusStones = if mDef then math.floor(mDef.BaseSpiritStones * 0.75) else 3000

		pcall(function()
			PlayerDataManager.AddQi(player, bonusQi)
			PlayerDataManager.AddSpiritStones(player, bonusStones)
		end)

		-- Roll Sovereign Loot Table
		local drops = MonsterConfig.RollDropTable(bossId)
		for _, drop in ipairs(drops) do
			pcall(function()
				InventoryManager.AddItem(player, drop.ItemId, drop.Count)
			end)
		end

		-- Play golden clash burst VFX
		local vfxRemote = RemoteEvents.GetRemote("CombatVFX") :: RemoteEvent?
		if vfxRemote and triggerPart then
			vfxRemote:FireAllClients({
				EffectType = "ParryClash",
				Position = triggerPart.Position + Vector3.new(0, 2, 0),
			})
		end
	end)

	-- Dissolve chest after 90 seconds
	task.delay(90, function()
		if activeChests[chestModel] then
			activeChests[chestModel] = nil
			prompt.Enabled = false

			for _, part in ipairs(chestModel:GetDescendants()) do
				if part:IsA("BasePart") then
					TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Transparency = 1,
					}):Play()
				elseif part:IsA("Light") or part:IsA("ParticleEmitter") then
					part.Enabled = false
				end
			end
			task.wait(1.6)
			chestModel:Destroy()
		end
	end)
end

function LootChestManager.Init()
	GetChestContainer()
	print("[LootChestManager] Sovereign World Loot Chest Engine Initialized (Grounded Flush Placement Active).")
end

return LootChestManager