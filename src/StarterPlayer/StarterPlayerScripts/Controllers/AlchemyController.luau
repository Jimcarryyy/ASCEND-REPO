--!strict
--[[
    AlchemyController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AlchemyController.luau
    Client controller binding strictly to pre-existing StarterGui.AlchemyGui templates.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local AlchemyController = {}

local alchemyActionRemote: RemoteEvent
local updateInventoryRemote: RemoteEvent

local gui: ScreenGui?
local backdrop: Frame?
local window: Frame?
local closeBtn: TextButton?
local refineBtn: TextButton?

local herbScroll: ScrollingFrame?
local matchedFormulaLabel: TextLabel?
local estimatedSuccessLabel: TextLabel?
local expectedQualityLabel: TextLabel?
local requiredQiLabel: TextLabel?
local rankTitleLabel: TextLabel?
local expBarFill: Frame?
local expTextLabel: TextLabel?

local slotButtons: { TextButton } = {}
local selectedInventorySlots: { [number]: number } = {}
local currentInventory: { [number]: any } = {}
local isInitialized = false

local function EnsureUI(): boolean
	if isInitialized and gui and backdrop then return true end

	gui = (playerGui:FindFirstChild("AlchemyGui") or playerGui:WaitForChild("AlchemyGui", 8)) :: ScreenGui?
	if not gui then return false end
	gui.DisplayOrder = 50

	backdrop = (gui:FindFirstChild("OverlayBackdrop") or gui:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not backdrop then return false end

	window = (backdrop:FindFirstChild("MainFrame") or backdrop:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not window then return false end

	closeBtn = window:FindFirstChild("CloseButton") :: TextButton?
	
	local masteryFrame = window:FindFirstChild("MasteryFrame") :: Frame?
	if masteryFrame then
		rankTitleLabel = masteryFrame:FindFirstChild("RankTitle") :: TextLabel?
		local expBg = masteryFrame:FindFirstChild("ExpBarBackground") :: Frame?
		if expBg then
			expBarFill = expBg:FindFirstChild("ExpBarFill") :: Frame?
			expTextLabel = expBg:FindFirstChild("ExpText") :: TextLabel?
		end
	end

	local content = window:FindFirstChild("ContentContainer") :: Frame?
	if content then
		local leftPanel = content:FindFirstChild("LeftPanel_HerbPicker") :: Frame?
		if leftPanel then
			herbScroll = leftPanel:FindFirstChild("HerbScrollFrame") :: ScrollingFrame?
		end

		local centerPanel = content:FindFirstChild("CenterPanel_Cauldron") :: Frame?
		if centerPanel then
			refineBtn = centerPanel:FindFirstChild("RefineButton") :: TextButton?
			local slotsBox = centerPanel:FindFirstChild("SlotsContainer") :: Frame?
			if slotsBox then
				table.clear(slotButtons)
				for s = 1, 3 do
					local slotBtn = slotsBox:FindFirstChild("Slot" .. s) :: TextButton?
					if slotBtn then
						slotButtons[s] = slotBtn
						slotBtn.Activated:Connect(function()
							selectedInventorySlots[s] = nil
							AlchemyController.UpdateSlotsUI()
							AlchemyController.UpdateMetrics()
						end)
					end
				end
			end

			local metricsBox = centerPanel:FindFirstChild("MetricsBox") :: Frame?
			if metricsBox then
				matchedFormulaLabel = metricsBox:FindFirstChild("MatchedFormulaLabel") :: TextLabel?
				estimatedSuccessLabel = metricsBox:FindFirstChild("EstimatedSuccessLabel") :: TextLabel?
				expectedQualityLabel = metricsBox:FindFirstChild("ExpectedQualityLabel") :: TextLabel?
				requiredQiLabel = metricsBox:FindFirstChild("RequiredQiLabel") :: TextLabel?
			end
		end
	end

	if closeBtn then
		closeBtn.Activated:Connect(function()
			if gui then gui.Enabled = false end
			if backdrop then backdrop.Visible = false end
		end)
	end

	if refineBtn then
		refineBtn.Activated:Connect(function()
			local indices: { number } = {}
			for s = 1, 3 do
				if selectedInventorySlots[s] then
					table.insert(indices, selectedInventorySlots[s])
				end
			end
			if #indices > 0 then
				alchemyActionRemote:FireServer({
					Action = "RefineManualCombination",
					SelectedSlotIndices = indices,
					FlamePrecision = 0.85,
				})
			end
		end)
	end

	isInitialized = true
	return true
end

function AlchemyController.Init()
	alchemyActionRemote = RemoteEvents.GetRemote("AlchemyAction")
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	EnsureUI()
	if gui then gui.Enabled = false end
	if backdrop then backdrop.Visible = false end

	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= localPlayer then return end
		local act = prompt.ActionText:lower()
		if act == "refine alchemy pills" or act == "open alchemy refinement" or (prompt.Parent and (prompt.Parent.Name == "Sect_NPC_MasterShen" or prompt.Parent.Name == "EightTrigramsCauldron" or prompt.Parent.Name == "Sect_AlchemyStation")) then
			if EnsureUI() and backdrop and gui then
				gui.Enabled = true
				backdrop.Visible = true
				alchemyActionRemote:FireServer({ Action = "RequestMasterySync" })
				local invRemote = RemoteEvents.GetRemote("InventoryAction")
				invRemote:FireServer({ Action = "RequestSync" })
			end
		end
	end)

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: any)
		if type(inventoryData) == "table" then
			currentInventory = inventoryData
			if EnsureUI() then AlchemyController.RefreshHerbGrid() end
		end
	end)

	alchemyActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		if not EnsureUI() then return end

		if payload.Action == "SyncMastery" then
			local exp = payload.Exp or 0
			local lvl = payload.Level or 1
			local maxExp = lvl * 100
			if rankTitleLabel then rankTitleLabel.Text = string.format("RANK %d — ALCHEMY MASTER", lvl) end
			if expTextLabel then expTextLabel.Text = string.format("%d / %d EXP", exp, maxExp) end
			if expBarFill then expBarFill.Size = UDim2.new(math.clamp(exp / maxExp, 0, 1), 0, 1, 0) end
		elseif payload.Action == "RefineResult" then
			selectedInventorySlots = {}
			AlchemyController.UpdateSlotsUI()
			AlchemyController.UpdateMetrics()
			local invRemote = RemoteEvents.GetRemote("InventoryAction")
			invRemote:FireServer({ Action = "RequestSync" })
		end
	end)

	print("[ASCEND] AlchemyController Initialized.")
end

function AlchemyController.RefreshHerbGrid()
	if not herbScroll then return end

	-- Use pre-built template slots in the static GUI without runtime instantiation
	local herbItems = {}
	for slotIdx, slotData in pairs(currentInventory) do
		local itemDef = ItemConfig.GetItem(slotData.ItemId)
		local itemIdLower = slotData.ItemId:lower()

		local isHerb = itemDef and (
			itemDef.Type == "Material" or 
			string.find(itemIdLower, "grass") or 
			string.find(itemIdLower, "dew") or 
			string.find(itemIdLower, "vine") or 
			string.find(itemIdLower, "lotus") or 
			string.find(itemIdLower, "core")
		)

		if isHerb and itemDef then
			table.insert(herbItems, { slotIdx = slotIdx, itemDef = itemDef, count = slotData.Count, itemId = slotData.ItemId })
		end
	end

	for i = 1, 12 do
		local slotBtn = herbScroll:FindFirstChild("SlotTemplate_" .. i) :: TextButton?
		if slotBtn then
			local data = herbItems[i]
			if data then
				local icon = slotBtn:FindFirstChild("HerbIcon") :: ImageLabel?
				local countLbl = slotBtn:FindFirstChild("CountLabel") :: TextLabel?

				if icon then
					icon.Image = data.itemDef.Icon or (UIAssets.Icons and UIAssets.Icons[data.itemId]) or ""
				end
				if countLbl then
					countLbl.Text = "x" .. tostring(data.count)
				end

				slotBtn.Visible = true

				slotBtn.Activated:Connect(function()
					for s = 1, 3 do
						if not selectedInventorySlots[s] then
							selectedInventorySlots[s] = data.slotIdx
							break
						end
					end
					AlchemyController.UpdateSlotsUI()
					AlchemyController.UpdateMetrics()
				end)
			else
				slotBtn.Visible = false
			end
		end
	end
end

function AlchemyController.UpdateSlotsUI()
	for s = 1, 3 do
		local slotBtn = slotButtons[s]
		if slotBtn then
			local invSlotIdx = selectedInventorySlots[s]
			local promptLbl = slotBtn:FindFirstChild("SlotPrompt") :: TextLabel?
			local slotIcon = slotBtn:FindFirstChild("SlotIcon") :: ImageLabel?

			if invSlotIdx and currentInventory[invSlotIdx] then
				local itemDef = ItemConfig.GetItem(currentInventory[invSlotIdx].ItemId)
				if itemDef then
					if promptLbl then
						promptLbl.Text = itemDef.Name
						promptLbl.TextColor3 = Color3.fromRGB(255, 215, 110)
					end
					if slotIcon then
						slotIcon.Image = itemDef.Icon or (UIAssets.Icons and UIAssets.Icons[currentInventory[invSlotIdx].ItemId]) or ""
						slotIcon.Visible = true
					end
				end
			else
				if promptLbl then
					promptLbl.Text = "+ Add Herb"
					promptLbl.TextColor3 = Color3.fromRGB(0, 220, 255)
				end
				if slotIcon then
					slotIcon.Visible = false
				end
			end
		end
	end
end

function AlchemyController.UpdateMetrics()
	if not matchedFormulaLabel or not estimatedSuccessLabel or not expectedQualityLabel or not requiredQiLabel then return end

	local insertedIds: { string } = {}
	for s = 1, 3 do
		local idx = selectedInventorySlots[s]
		if idx and currentInventory[idx] then
			table.insert(insertedIds, currentInventory[idx].ItemId)
		end
	end

	if #insertedIds == 0 then
		matchedFormulaLabel.Text = "MATCHED FORMULA: NONE"
		estimatedSuccessLabel.Text = "Estimated Success Rate: 0%"
		expectedQualityLabel.Text = "Expected Quality: Standard Grade"
		requiredQiLabel.Text = "Required Spirit Qi: 0 Qi"
		return
	end

	local formula, successRate, potency, quality = AlchemyConfig.CalculateCombinationMetrics(insertedIds)
	if formula then
		matchedFormulaLabel.Text = "MATCHED FORMULA: " .. string.upper(formula.Name)
		estimatedSuccessLabel.Text = string.format("Estimated Success Rate: %d%%", math.floor(successRate * 100))
		expectedQualityLabel.Text = string.format("Expected Quality: %s", quality)
		requiredQiLabel.Text = string.format("Required Spirit Qi: %d Qi", formula.BaseQiCost)
	else
		matchedFormulaLabel.Text = "MATCHED FORMULA: UNSTABLE MIX"
		estimatedSuccessLabel.Text = "Estimated Success Rate: 0%"
		expectedQualityLabel.Text = "Expected Quality: Ash Waste"
		requiredQiLabel.Text = "Required Spirit Qi: 0 Qi"
	end
end

return AlchemyController