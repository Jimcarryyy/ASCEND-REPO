--!strict
--[[
    GatheringManager.luau
    Location: src/ServerScriptService/Server/World/GatheringManager.luau
    Server-authoritative resource gathering:
    - Waits for the channeled duration (1.8s for SpiritGrass) before awarding loot
    - Resolves Parts and Models seamlessly so nodes never fail to harvest
    - Calls SectManager.AddQuestProgress strictly ONCE with 1 count
    - Fires HarvestSuccess to trigger GatheringController line 394
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local GatheringConfig = require(ReplicatedStorage.Shared.Configs.GatheringConfig)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)

local GatheringManager = {}

local activeNodes: { [Instance]: boolean } = {}
local gatheringActionRemote: RemoteEvent

local NODE_DURATIONS: { [string]: number } = {
	SpiritGrass = 1.8,
	DragonBloodVine = 2.2,
	GaleWindLotus = 2.0,
	CelestialSpring = 2.2,
	JadeOre = 2.5,
}

local function GetConfig(nodeType: string): any
	local cleanType = nodeType:gsub("%s+", ""):gsub("^Spawner_", "")
	if type(GatheringConfig.GetNode) == "function" then
		local def = GatheringConfig.GetNode(cleanType) or GatheringConfig.GetNode(nodeType)
		if def then return def end
	end
	if type((GatheringConfig :: any).Nodes) == "table" then
		local def = (GatheringConfig :: any).Nodes[cleanType] or (GatheringConfig :: any).Nodes[nodeType]
		if def then return def end
	end
	for id, def in pairs(GatheringConfig.GetAllNodes and GatheringConfig.GetAllNodes() or {}) do
		if id:lower() == cleanType:lower() or (def.DisplayName and def.DisplayName:lower() == nodeType:lower()) then
			return def
		end
	end
	return (GatheringConfig :: any)[cleanType] or (GatheringConfig :: any)[nodeType]
end

local function ResolveNode(inst: Instance?): (Instance?, string?, any?)
	if not inst then return nil, nil, nil end

	if activeNodes[inst] then
		local nodeType = inst:GetAttribute("NodeType") or inst.Name
		local cfg = GetConfig(nodeType)
		if cfg then return inst, nodeType, cfg end
	end

	if inst.Parent and activeNodes[inst.Parent] then
		local nodeType = inst.Parent:GetAttribute("NodeType") or inst.Parent.Name
		local cfg = GetConfig(nodeType)
		if cfg then return inst.Parent, nodeType, cfg end
	end

	local curr: Instance? = inst
	while curr and curr ~= workspace and curr ~= workspace:FindFirstChild("GatheringNodes") do
		if activeNodes[curr] then
			local nodeType = curr:GetAttribute("NodeType") or curr.Name
			local cfg = GetConfig(nodeType)
			if cfg then return curr, nodeType, cfg end
		end
		curr = curr.Parent
	end

	return nil, nil, nil
end

local function PickRandomDrop(dropList: { any }): (string, number)
	local totalWeight = 0
	for _, drop in ipairs(dropList) do
		totalWeight += drop.Weight or 1
	end

	local roll = math.random(1, math.max(1, totalWeight))
	local current = 0

	for _, drop in ipairs(dropList) do
		current += drop.Weight or 1
		if roll <= current then
			local count = math.random(drop.MinCount or 1, drop.MaxCount or 1)
			return drop.ItemId, count
		end
	end

	return "SpiritGrass_1Yr", 1
end

function GatheringManager.Init()
	gatheringActionRemote = RemoteEvents.GetRemote("GatheringAction")

	local nodesFolder = workspace:FindFirstChild("GatheringNodes")
	if nodesFolder then
		for _, child in ipairs(nodesFolder:GetChildren()) do
			GatheringManager.SetupNodeModel(child)
		end
		nodesFolder.ChildAdded:Connect(function(child)
			task.wait(0.1)
			GatheringManager.SetupNodeModel(child)
		end)
	end

	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:GetAttribute("NodeType") ~= nil then
			GatheringManager.SetupNodeModel(desc)
		end
	end

	print("[ASCEND] GatheringManager Initialized.")
end

function GatheringManager.SetupNodeModel(nodeInstance: Instance)
	if not nodeInstance:IsA("BasePart") and not nodeInstance:IsA("Model") then return end
	if activeNodes[nodeInstance] then return end

	local nodeType = nodeInstance:GetAttribute("NodeType") or nodeInstance.Name
	local config = GetConfig(nodeType)
	if not config then return end

	activeNodes[nodeInstance] = true

	local promptPart: BasePart? = nil
	if nodeInstance:IsA("BasePart") then
		promptPart = nodeInstance
	elseif nodeInstance:IsA("Model") then
		promptPart = nodeInstance.PrimaryPart or nodeInstance:FindFirstChildWhichIsA("BasePart")
	end

	if not promptPart then return end

	local prompt = promptPart:FindFirstChild("GatherPrompt") or promptPart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GatherPrompt"
		prompt.ActionText = config.PromptText or "Harvest"
		prompt.ObjectText = config.DisplayName or nodeType
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 11
		prompt.RequiresLineOfSight = false
		prompt.Parent = promptPart
	else
		prompt.Name = "GatherPrompt"
		prompt.HoldDuration = 0
	end

	prompt.Triggered:Connect(function(player: Player)
		GatheringManager.ProcessHarvest(player, nodeInstance)
	end)
end

function GatheringManager.ProcessHarvest(player: Player, nodeInstance: Instance)
	local resolvedNode, nodeType, config = ResolveNode(nodeInstance)
	if not resolvedNode or not config then return end

	if not activeNodes[resolvedNode] then return end
	activeNodes[resolvedNode] = false

	local promptPart: BasePart? = nil
	if resolvedNode:IsA("BasePart") then
		promptPart = resolvedNode
	elseif resolvedNode:IsA("Model") then
		promptPart = resolvedNode.PrimaryPart or resolvedNode:FindFirstChildWhichIsA("BasePart")
	end

	local prompt = promptPart and (promptPart:FindFirstChild("GatherPrompt") or promptPart:FindFirstChildOfClass("ProximityPrompt"))
	if prompt then
		prompt.Enabled = false
	end

	local cleanType = nodeType:gsub("%s+", "")
	local channelDuration = NODE_DURATIONS[cleanType] or config.HoldDuration or 1.8

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local startPos = hrp and hrp.Position

	-- Server waits for the channel duration in sync with GatheringController's progress bar
	task.delay(channelDuration, function()
		if not player.Parent or not hrp or not hrp.Parent then
			activeNodes[resolvedNode] = true
			if prompt then prompt.Enabled = true end
			return
		end

		if startPos and (hrp.Position - startPos).Magnitude > 12 then
			activeNodes[resolvedNode] = true
			if prompt then prompt.Enabled = true end
			return
		end

		local dropList = config.Drops or config.AgeDrops or {
			{ ItemId = "SpiritGrass_1Yr", Weight = 60, MinCount = 1, MaxCount = 1 },
		}

		local selectedItemId, count = PickRandomDrop(dropList)

		-- 1. Add item to inventory
		InventoryManager.AddItem(player, selectedItemId, count)

		-- 2. Advance Sect Duty strictly ONCE with 1 count
		SectManager.AddQuestProgress(player, "Gather", config.NodeId or nodeType, 1)

		-- 3. Notify GatheringController line 394 to complete exit tween and show toast
		gatheringActionRemote:FireClient(player, {
			Action = "HarvestSuccess",
			ItemId = selectedItemId,
			Count = count,
			Node = resolvedNode,
		})

		-- Visual depletion
		local originalTransparency: { [BasePart]: number } = {}
		for _, part in ipairs(resolvedNode:GetDescendants()) do
			if part:IsA("BasePart") then
				originalTransparency[part] = part.Transparency
				part.Transparency = 0.85
			end
		end
		if resolvedNode:IsA("BasePart") then
			originalTransparency[resolvedNode] = resolvedNode.Transparency
			resolvedNode.Transparency = 0.85
		end

		-- Respawn timer
		local respawnTime = config.RespawnTime or 12
		task.delay(respawnTime, function()
			for part, trans in pairs(originalTransparency) do
				if part and part.Parent then
					part.Transparency = trans
				end
			end
			if prompt then
				prompt.Enabled = true
			end
			activeNodes[resolvedNode] = true
		end)
	end)
end

return GatheringManager