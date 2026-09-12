--!strict
--[[
    GatheringManager.luau
    Location: src/ServerScriptService/Server/World/GatheringManager.luau
    Server-authoritative manager for world resource harvesting nodes.
    Grants randomized herb ages, updates Sect Quests, and replicates depletion state to clients.
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

local function GetConfig(nodeType: string): any
	if type((GatheringConfig :: any).GetNodeConfig) == "function" then
		return (GatheringConfig :: any).GetNodeConfig(nodeType)
	elseif type((GatheringConfig :: any).Nodes) == "table" then
		return (GatheringConfig :: any).Nodes[nodeType]
	else
		return (GatheringConfig :: any)[nodeType]
	end
end

function GatheringManager.Init()
	gatheringActionRemote = RemoteEvents.GetRemote("GatheringAction")

	local folder = workspace:FindFirstChild("GatheringNodes")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			GatheringManager.SetupNodeModel(child)
		end
		folder.ChildAdded:Connect(function(child)
			GatheringManager.SetupNodeModel(child)
		end)
	end

	for _, nodeModel in ipairs(CollectionService:GetTagged("GatheringNode")) do
		GatheringManager.SetupNodeModel(nodeModel)
	end

	CollectionService:GetInstanceAddedSignal("GatheringNode"):Connect(function(instance)
		GatheringManager.SetupNodeModel(instance)
	end)

	print("[ASCEND] GatheringManager Engine Initialized (Server-Authoritative Prompt Triggers, Depletion Sync & Quest Sync Enabled).")
end

function GatheringManager.SetupNodeModel(nodeInstance: Instance)
	if not nodeInstance:IsA("Model") and not nodeInstance:IsA("BasePart") then return end

	local nodeType = nodeInstance:GetAttribute("NodeType") or nodeInstance.Name
	local config = GetConfig(nodeType)
	if not config then return end

	if nodeInstance:IsA("Model") and not nodeInstance.PrimaryPart then
		nodeInstance.PrimaryPart = nodeInstance:FindFirstChildWhichIsA("BasePart")
	end

	nodeInstance:SetAttribute("Depleted", false)

	local prompt = nodeInstance:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GatherPrompt"
		prompt.Parent = nodeInstance
	end

	prompt.ObjectText = config.NodeName
	prompt.ActionText = config.PromptText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = config.MaxDistance
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.KeyboardKeyCode = Enum.KeyCode.E

	if not prompt:GetAttribute("_GatheringServerConnected") then
		prompt:SetAttribute("_GatheringServerConnected", true)
		prompt.Triggered:Connect(function(playerWhoTriggered: Player)
			GatheringManager.ProcessHarvest(playerWhoTriggered, nodeInstance)
		end)
	end
end

function GatheringManager.ProcessHarvest(player: Player, nodeInstance: Instance)
	if depletedNodes[nodeInstance] or activeHarvests[player] then return end

	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end

	local primaryPart = if nodeInstance:IsA("Model") then (nodeInstance.PrimaryPart or nodeInstance:FindFirstChildWhichIsA("BasePart")) else nodeInstance
	if not primaryPart then return end

	local nodeType = nodeInstance:GetAttribute("NodeType") or nodeInstance.Name
	local config = GetConfig(nodeType)
	if not config then return end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
	local dist = (hrp.Position - (primaryPart :: BasePart).Position).Magnitude
	if dist > (config.MaxDistance + 5) then
		warn(string.format("[GatheringManager] %s attempted to harvest %s from too far away (%.1f studs)", player.Name, nodeInstance.Name, dist))
		return
	end

	activeHarvests[player] = true
	local prompt = nodeInstance:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled = false end
	nodeInstance:SetAttribute("Depleted", true)

	task.wait(config.HarvestDuration or 1.8)

	local stillAlive = character:FindFirstChild("Humanoid") and (character.Humanoid :: Humanoid).Health > 0
	local stillNearby = (hrp.Position - (primaryPart :: BasePart).Position).Magnitude <= (config.MaxDistance + 6)

	if not stillAlive or not stillNearby then
		activeHarvests[player] = nil
		nodeInstance:SetAttribute("Depleted", false)
		if prompt then prompt.Enabled = true end
		return
	end

	depletedNodes[nodeInstance] = true
	activeHarvests[player] = nil

	if not config.KeepModelVisible then
		for _, descendant in ipairs(nodeInstance:GetDescendants()) do
			if descendant:IsA("BasePart") then
				descendant.Transparency = 0.8
			elseif descendant:IsA("ParticleEmitter") then
				descendant.Enabled = false
			end
		end
	end

	local dropList = config.AgeDrops or config.Drops
	local selectedItemId = "SpiritGrass_1Yr"

	if dropList and #dropList > 0 then
		local roll = math.random()
		local cumulativeChance = 0
		selectedItemId = dropList[1].ItemId

		for _, drop in ipairs(dropList) do
			local chance = drop.Chance
			if chance > 1 then chance = chance / 100 end
			cumulativeChance += chance
			if roll <= cumulativeChance then
				selectedItemId = drop.ItemId
				break
			end
		end
	end

	InventoryManager.AddItem(player, selectedItemId, 1)
	SectManager.AddQuestProgress(player, "Gather", config.NodeName, 1)
	SectManager.AddQuestProgress(player, "Gather", nodeType, 1)

	print(string.format("[GatheringManager] %s harvested %s from %s", player.Name, selectedItemId, config.NodeName))

	gatheringActionRemote:FireClient(player, {
		Action = "HarvestSuccess",
		ItemId = selectedItemId,
		Count = 1,
	})

	-- Respawn Node after delay
	task.delay(config.RespawnTime or 12.0, function()
		depletedNodes[nodeInstance] = nil
		nodeInstance:SetAttribute("Depleted", false)
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