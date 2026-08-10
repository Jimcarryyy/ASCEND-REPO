--!strict
--[[
    AlchemyManager.luau
    Location: src/ServerScriptService/Server/Cultivation/AlchemyManager.luau
    Server-authoritative manual cauldron combination alchemy engine.
    Supports Flame Precision Minigames, Alchemy EXP, and Stacking Inventory Delivery.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local CollectionService = game:GetService("CollectionService")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local AlchemyManager = {}
local activeRefiningMap: { [Player]: boolean } = {}

local alchemyActionRemote: RemoteEvent

function AlchemyManager.Init()
	alchemyActionRemote = RemoteEvents.GetRemote("AlchemyAction")

	local folder = workspace:FindFirstChild("AlchemyCauldrons")
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			AlchemyManager.SetupCauldronModel(child)
		end
		folder.ChildAdded:Connect(function(child)
			AlchemyManager.SetupCauldronModel(child)
		end)
	end

	for _, cauldronModel in ipairs(CollectionService:GetTagged("AlchemyCauldron")) do
		AlchemyManager.SetupCauldronModel(cauldronModel)
	end

	CollectionService:GetInstanceAddedSignal("AlchemyCauldron"):Connect(function(instance)
		AlchemyManager.SetupCauldronModel(instance)
	end)

	alchemyActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "RefineManualCombination" and type(payload.SelectedSlotIndices) == "table" then
			local flamePrecision = if type(payload.FlamePrecision) == "number" then payload.FlamePrecision else 0.5
			AlchemyManager.RefineManualCombination(player, payload.SelectedSlotIndices, flamePrecision)
		end
	end)

	print("[ASCEND] Upgraded Flame Precision AlchemyManager Initialized.")
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

function AlchemyManager.RefineManualCombination(player: Player, selectedSlotIndices: { number }, flamePrecision: number)
	if activeRefiningMap[player] then return end

	local playerInventory = InventoryManager.GetInventory(player)
	if not playerInventory then return end

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

	local formula, baseSuccessRate, potencyMult, qualityText = AlchemyConfig.CalculateCombinationMetrics(insertedHerbItemIds)

	if not formula then
		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = "Invalid herb combination! Ingredients burned into furnace ash.",
		})
		return
	end

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

	-- Calculate Flame Bonus (Precision 0.8-1.0 yields +15% success bonus)
	local flameBonus = 0
	local flameRating = "Standard Flame"
	if flamePrecision >= 0.80 then
		flameBonus = 0.15
		flameRating = "Optimal Qi Flame (+15%)"
	elseif flamePrecision < 0.30 then
		flameBonus = -0.10
		flameRating = "Cold Flame (-10%)"
	end

	local finalSuccessRate = math.clamp(baseSuccessRate + flameBonus, 0.05, 1.00)
	local roll = math.random()
	local success = roll <= finalSuccessRate

	if success then
		-- Guaranteed Delivery into Inventory Stacks
		InventoryManager.AddItem(player, formula.ResultItemId, 1)

		-- Grant Alchemy EXP
		local expGained = formula.ExpReward or 30
		if flamePrecision >= 0.80 then expGained = math.floor(expGained * 1.25) end
		local newExp, newLevel = PlayerDataManager.AddAlchemyExp(player, expGained)

		print(string.format("[AlchemyManager] %s refined %s (%s, Flame: %s, Exp: +%d)!", player.Name, formula.Name, qualityText, flameRating, expGained))

		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = true,
			Message = string.format("Refined %s (%s)!\n+ %d Alchemy EXP", formula.Name, qualityText, expGained),
			ResultItemId = formula.ResultItemId,
			ExpGained = expGained,
		})
	else
		print(string.format("[AlchemyManager] %s failed refining (Roll: %.2f vs Rate: %.2f)", player.Name, roll, finalSuccessRate))

		alchemyActionRemote:FireClient(player, {
			Action = "RefineResult",
			Success = false,
			Message = "Refinement Failed! Herbs burned into furnace ash.",
		})
	end

	activeRefiningMap[player] = nil
end

return AlchemyManager