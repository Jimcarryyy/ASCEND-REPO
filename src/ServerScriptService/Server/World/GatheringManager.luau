--!strict
--[[
    GatheringManager.luau
    Location: src/ServerScriptService/Server/World/GatheringManager.luau
    Server-authoritative manager for world resource harvesting nodes.
    Grants randomized herb ages, updates Sect Quests, and triggers harvest audio/toasts on client.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local GatheringConfig = require(ReplicatedStorage.Shared.Configs.GatheringConfig)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local GatheringManager = {}
local depletedNodes: { [Instance]: boolean } = {}
local activeHarvests: { [Player]: boolean } = {}

local gatheringActionRemote: RemoteEvent

function GatheringManager.Init()
	gatheringActionRemote = RemoteEvents.GetRemote("GatheringAction")

	-- 1. Check workspace.GatheringNodes Folder
	local folder = workspace:FindFirstChild("GatheringNodes")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			GatheringManager.SetupNodeModel(child)
		end
		folder.ChildAdded:Connect(function(child)
			GatheringManager.SetupNodeModel(child)
		end)
	end

	-- 2. Check CollectionService Tag "GatheringNode"
	for _, nodeModel in ipairs(CollectionService:GetTagged("GatheringNode")) do
		GatheringManager.SetupNodeModel(nodeModel)
	end

	CollectionService:GetInstanceAddedSignal("GatheringNode"):Connect(function(instance)
		GatheringManager.SetupNodeModel(instance)
	end)

	gatheringActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "CompleteHarvest" and payload.NodeInstance then
			GatheringManager.ProcessHarvest(player, payload.NodeInstance)
		end
	end)

	print("[ASCEND] GatheringManager Engine Initialized (Randomized Herb Ages & Quest Sync Enabled).")
end

function GatheringManager.SetupNodeModel(nodeInstance: Instance)
	if not nodeInstance:IsA("Model") and not nodeInstance:IsA("BasePart") then return end

	local nodeType = nodeInstance:GetAttribute("NodeType") or nodeInstance.Name
	local config = GatheringConfig.GetNodeConfig(nodeType)
	if not config then return end

	if nodeInstance:IsA("Model") and not nodeInstance.PrimaryPart then
		nodeInstance.PrimaryPart = nodeInstance:FindFirstChildWhichIsA("BasePart")
	end

	local existingPrompt = nodeInstance:FindFirstChildOfClass("ProximityPrompt")
	if not existingPrompt then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GatherPrompt"
		prompt.ObjectText = config.NodeName
		prompt.ActionText = config.PromptText
		prompt.HoldDuration = config.HarvestDuration
		prompt.MaxActivationDistance = config.MaxDistance
		prompt.RequiresLineOfSight = false
		prompt.Parent = nodeInstance
	end
end

function GatheringManager.ProcessHarvest(player: Player, nodeInstance: Instance)
	if depletedNodes[nodeInstance] or activeHarvests[player] then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local primaryPart = if nodeInstance:IsA("Model") then (nodeInstance.PrimaryPart or nodeInstance:FindFirstChildWhichIsA("BasePart")) else nodeInstance
	if not primaryPart then return end

	local nodeType = nodeInstance:GetAttribute("NodeType") or nodeInstance.Name
	local config = GatheringConfig.GetNodeConfig(nodeType)
	if not config then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local dist = (hrp.Position - (primaryPart :: BasePart).Position).Magnitude
	if dist > (config.MaxDistance + 5) then
		warn(string.format("[GatheringManager] %s attempted to harvest %s from too far away (%.1f studs)", player.Name, nodeInstance.Name, dist))
		return
	end

	activeHarvests[player] = true
	depletedNodes[nodeInstance] = true

	local prompt = nodeInstance:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = false end

	-- Fade model out on harvest ONLY if KeepModelVisible is false
	if not config.KeepModelVisible then
		for _, descendant in ipairs(nodeInstance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 0.8
			elseif descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
	end

	-- Weighted Random Roll for Herb Age
	local roll = math.random()
	local cumulativeChance = 0
	local selectedItemId = config.AgeDrops[1].ItemId -- Default fallback

	for _, drop in ipairs(config.AgeDrops) do
		cumulativeChance += drop.Chance
		if roll <= cumulativeChance then
			selectedItemId = drop.ItemId
			break
		end
	end

	-- Grant Loot
	InventoryManager.AddItem(player, selectedItemId, 1)

	-- Sync Sect Quest Progress for Herb Harvesting
	SectManager.AddQuestProgress(player, "Gather", config.NodeName, 1)
	SectManager.AddQuestProgress(player, "Gather", nodeType, 1)

	print(string.format("[GatheringManager] %s harvested %s from %s (Random Roll: %.2f)", player.Name, selectedItemId, config.NodeName, roll))

	-- Notify Client to Play Harvest Sound and Show Toast Notification
	gatheringActionRemote:FireClient(player, {
		Action = "HarvestSuccess",
		ItemId = selectedItemId,
		Count = 1,
	})

	activeHarvests[player] = nil

	-- Respawn Node after delay
	task.delay(config.RespawnTime, function()
		depletedNodes[nodeInstance] = nil
		if prompt then prompt.Enabled = true end

		if not config.KeepModelVisible then
			for _, descendant in ipairs(nodeInstance:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = 0
					elseif descendant:IsA("ParticleEmitter") then
					descendant.Enabled = true
				end
			end
		end
	end)
end

return GatheringManager