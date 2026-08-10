--!strict
--[[
    AlchemyManager.luau
    Location: src/ServerScriptService/Server/Cultivation/AlchemyManager.luau
    Server-authoritative manual cauldron combination alchemy engine.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local AlchemyManager = {}
local activeRefiningMap: { [Player]: boolean } = {}

local alchemyActionRemote: RemoteEvent

function AlchemyManager.Init()
	alchemyActionRemote = RemoteEvents.GetRemote("AlchemyAction")

	-- Check workspace.AlchemyCauldrons Folder
	local folder = workspace:FindFirstChild("AlchemyCauldrons")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			AlchemyManager.SetupCauldronModel(child)
		end
		folder.ChildAdded:Connect(function(child)
			AlchemyManager.SetupCauldronModel(child)
		end)
	end

	-- Check CollectionService Tag "AlchemyCauldron"
	for _, cauldronModel in ipairs(CollectionService:GetTagged("AlchemyCauldron")) do
		AlchemyManager.SetupCauldronModel(cauldronModel)
	end

	CollectionService:GetInstanceAddedSignal("AlchemyCauldron"):Connect(function(instance)
		AlchemyManager.SetupCauldronModel(instance)
	end)

	alchemyActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "RefineManualCombination" and type(payload.SelectedSlotIndices) == "table" then
			AlchemyManager.RefineManualCombination(player, payload.SelectedSlotIndices)
		end
	end)

	print("[ASCEND] Upgraded Manual Combination AlchemyManager Initialized.")
end

function AlchemyManager.SetupCauldronModel(cauldronInstance: Instance)
	if not cauldronInstance:IsA("Model") and not cauldronInstance:IsA("BasePart") then return end

	if cauldronInstance:IsA("Model") and not cauldronInstance.PrimaryPart then
		cauldronInstance.PrimaryPart = cauldronInstance:FindFirstChildWhichIsA("BasePart")
	end

	local existingPrompt = cauldronInstance:FindFirstChildOfClass("ProximityPrompt")
	if not existingPrompt then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CauldronPrompt"
		prompt.ObjectText = "Spirit Cauldron Furnace"
		prompt.ActionText = "Combine & Refine Herbs"
		prompt.HoldDuration = 0.5
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt.Parent = cauldronInstance
	end
end

function AlchemyManager.RefineManualCombination(player: Player, selectedSlotIndices: { number })
	if activeRefiningMap[player] then return end

	local playerInventory = InventoryManager.GetInventory(player)
	if not playerInventory then return end

	-- 1. Extract Selected Herbs from Inventory Slots
	local insertedHerbItemIds: { string } = {}
	local slotsToDeduct: { number } = {}

	for _, slotIdx in ipairs(selectedSlotIndices) do
		local slot = playerInventory[slotIdx]
		if slot and slot.Count >= 1 then
			table.insert(insertedHerbItemIds, slot.ItemId)
			table.insert(slotsToDeduct, slotIdx)
		end
	end

	if #insertedHerbItemIds == 0 then
		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = "Cauldron is empty! Insert at least 1 herb.",
		})
		return
	end

	-- 2. Calculate Combination Formula & Age Success Metrics
	local formula, successRate, potencyMult, qualityText = AlchemyConfig.CalculateCombinationMetrics(insertedHerbItemIds)

	if not formula then
		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = "Invalid herb combination! Ingredients burned into ash.",
		})
		return
	end

	-- 3. Check Player Qi Cost
	local pData = CultivationManager.GetPlayerData(player)
	if pData and pData.CurrentQi < formula.BaseQiCost then
		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = string.format("Insufficient Qi! Requires %d Spirit Qi.", formula.BaseQiCost),
		})
		return
	end

	activeRefiningMap[player] = true

	-- Deduct Qi Cost
	if pData then
		pData.CurrentQi = math.max(0, pData.CurrentQi - formula.BaseQiCost)
		CultivationManager.SyncClient(player)
	end

	-- Deduct Inserted Herbs from Inventory
	for _, slotIdx in ipairs(slotsToDeduct) do
		local slot = playerInventory[slotIdx]
		if slot then
			slot.Count -= 1
			if slot.Count <= 0 then
				playerInventory[slotIdx] = nil
			end
		end
	end

	InventoryManager.SyncClient(player)

	-- Crafting Delay
	task.wait(formula.CraftDuration)

	-- 4. Roll Success Rate
	local roll = math.random()
	local success = roll <= successRate

	if success then
		InventoryManager.AddItem(player, formula.ResultItemId, 1)
		print(string.format("[AlchemyManager] %s refined %s (%s, Rate: %.2f)!", player.Name, formula.Name, qualityText, successRate))

		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = true,
			Message = string.format("Refined %s (%s)!", formula.Name, qualityText),
			ResultItemId = formula.ResultItemId,
		})
	else
		print(string.format("[AlchemyManager] %s failed refining (Roll: %.2f vs Rate: %.2f)", player.Name, roll, successRate))

		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = "Refinement Failed! Herbs burned into furnace ash.",
		})
	end

	activeRefiningMap[player] = nil
end

return AlchemyManager