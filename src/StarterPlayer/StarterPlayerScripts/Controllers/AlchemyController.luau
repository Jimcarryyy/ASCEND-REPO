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
				for s = 1, 4 do
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
			for s = 1, 4 do
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
				if herbScroll then
					herbScroll.CanvasPosition = Vector2.new(0, 0)
				end
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

local gridConnections: { RBXScriptConnection } = {}

local RARITY_RANKS: { [string]: number } = {
	["Mortal"] = 1, ["Common"] = 1,
	["Spiritual"] = 2, ["Uncommon"] = 2,
	["Earth"] = 3, ["Rare"] = 3,
	["Heaven"] = 4, ["Epic"] = 4,
	["Legendary"] = 5,
	["Mythic"] = 6,
	["Divine"] = 7,
	["Immortal"] = 8,
	["Sovereign"] = 9,
	["Celestial"] = 10,
}

local GEAR_TYPES = {
	Weapon = true, FlyingSword = true, Sword = true,
	Equipment = true, Artifact = true, Armor = true, Crest = true,
}

local MATS_AND_SUPPLIES_TYPES = {
	Material = true, Herb = true, Ingredient = true,
	Consumable = true, Pill = true, Dan = true, Rare = true,
}

function AlchemyController.RefreshHerbGrid()
	if not herbScroll then return end

	for _, conn in ipairs(gridConnections) do
		conn:Disconnect()
	end
	table.clear(gridConnections)

	-- Group items strictly by unique ItemId to eliminate duplicate slots
	type SlotRef = { SlotIdx: number, Count: number }
	type ConsolidatedEntry = {
		ItemId: string,
		TotalCount: number,
		Slots: { SlotRef },
		ItemDef: any,
	}

	local consolidated: { [string]: ConsolidatedEntry } = {}

	for slotIdx = 1, 60 do
		local slotData = currentInventory[slotIdx] or currentInventory[tostring(slotIdx) :: any]
		if slotData and slotData.ItemId and slotData.ItemId ~= "" then
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef then
				local itemType = itemDef.Type or ""

				-- Strictly exclude gear/weapons
				if not GEAR_TYPES[itemType] then
					local itemIdLower = slotData.ItemId:lower()
					local isMatsOrSupplies = MATS_AND_SUPPLIES_TYPES[itemType] == true
					local isHerbKeyword = string.find(itemIdLower, "grass") or 
					                      string.find(itemIdLower, "dew") or 
					                      string.find(itemIdLower, "vine") or 
					                      string.find(itemIdLower, "lotus") or 
					                      string.find(itemIdLower, "core")
					local isPillKeyword = string.find(itemIdLower, "dan") or 
					                      string.find(itemIdLower, "pill")

					if isMatsOrSupplies or isHerbKeyword or isPillKeyword then
						local id = slotData.ItemId
						if not consolidated[id] then
							consolidated[id] = {
								ItemId = id,
								TotalCount = 0,
								Slots = {},
								ItemDef = itemDef,
							}
						end

						local count = slotData.Count or 1
						consolidated[id].TotalCount += count
						table.insert(consolidated[id].Slots, {
							SlotIdx = slotIdx,
							Count = count,
						})
					end
				end
			end
		end
	end

	-- Convert consolidated table to a list
	local herbItems = {}
	for _, entry in pairs(consolidated) do
		table.insert(herbItems, entry)
	end

	-- Sort strictly by Rarity (Mythic -> Rare -> Uncommon -> Common), then alphabetically by Name
	table.sort(herbItems, function(a, b)
		local rA = RARITY_RANKS[a.ItemDef.Rarity] or 1
		local rB = RARITY_RANKS[b.ItemDef.Rarity] or 1
		if rA ~= rB then
			return rA > rB
		end
		local nameA = a.ItemDef.Name or a.ItemId
		local nameB = b.ItemDef.Name or b.ItemId
		return nameA < nameB
	end)

	local totalUniqueItems = #herbItems
	local template1 = herbScroll:FindFirstChild("SlotTemplate_1") :: TextButton?

	-- Dynamically clone template buttons if player holds more unique items than existing templates
	for i = 1, totalUniqueItems do
		local slotBtn = herbScroll:FindFirstChild("SlotTemplate_" .. i) :: TextButton?
		if not slotBtn and template1 then
			slotBtn = template1:Clone()
			slotBtn.Name = "SlotTemplate_" .. i
			slotBtn.Parent = herbScroll
		end
	end

	-- Populate slots
	for _, child in ipairs(herbScroll:GetChildren()) do
		if child:IsA("GuiObject") and string.find(child.Name, "SlotTemplate_") then
			local idxStr = string.gsub(child.Name, "SlotTemplate_", "")
			local i = tonumber(idxStr)
			if i then
				local data = herbItems[i]
				if data then
					local icon = child:FindFirstChild("HerbIcon") :: ImageLabel?
					local countLbl = child:FindFirstChild("CountLabel") :: TextLabel?

					if icon then
						icon.Image = data.ItemDef.Icon or (UIAssets.Icons and UIAssets.Icons[data.ItemId]) or ""
						icon.Visible = true
					end
					if countLbl then
						countLbl.Text = "x" .. tostring(data.TotalCount)
					end

					child.Visible = true

					local conn = (child :: TextButton).Activated:Connect(function()
						-- Count how many of this item are already placed across the 4 cauldron slots
						local usedCountsBySlot: { [number]: number } = {}
						for s = 1, 4 do
							local usedIdx = selectedInventorySlots[s]
							if usedIdx then
								usedCountsBySlot[usedIdx] = (usedCountsBySlot[usedIdx] or 0) + 1
							end
						end

						-- Find the first available inventory slot for this item that still has count remaining
						local chosenSlotIdx: number? = nil
						for _, sInfo in ipairs(data.Slots) do
							local alreadyUsed = usedCountsBySlot[sInfo.SlotIdx] or 0
							if alreadyUsed < sInfo.Count then
								chosenSlotIdx = sInfo.SlotIdx
								break
							end
						end

						if chosenSlotIdx then
							-- Insert into first empty cauldron slot (1..4)
							for s = 1, 4 do
								if not selectedInventorySlots[s] then
									selectedInventorySlots[s] = chosenSlotIdx
									break
								end
							end
							AlchemyController.UpdateSlotsUI()
							AlchemyController.UpdateMetrics()
						end
					end)
					table.insert(gridConnections, conn)
				else
					child.Visible = false
				end
			end
		end
	end

	-- Dynamically calculate scroll height for 3-column grid
	local rows = math.ceil(math.max(1, totalUniqueItems) / 3)
	local neededScaleY = (rows * 0.33) + 0.12
	herbScroll.CanvasSize = UDim2.new(0, 0, neededScaleY, 0)
end

function AlchemyController.UpdateSlotsUI()
	for s = 1, 4 do
		local slotBtn = slotButtons[s]
		if slotBtn then
			local invSlotIdx = selectedInventorySlots[s]
			local promptLbl = slotBtn:FindFirstChild("SlotPrompt") :: TextLabel?
			local slotIcon = slotBtn:FindFirstChild("SlotIcon") :: ImageLabel?

			if invSlotIdx and currentInventory[invSlotIdx] then
				local slotData = currentInventory[invSlotIdx]
				local itemDef = ItemConfig.GetItem(slotData.ItemId)
				local displayName = (itemDef and itemDef.Name) or slotData.ItemId

				if promptLbl then
					promptLbl.Text = displayName
					promptLbl.TextColor3 = Color3.fromRGB(255, 215, 110)
				end
				if slotIcon then
					slotIcon.Image = (itemDef and itemDef.Icon) or (UIAssets.Icons and UIAssets.Icons[slotData.ItemId]) or ""
					slotIcon.Visible = true
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
	for s = 1, 4 do
		local idx = selectedInventorySlots[s]
		if idx and currentInventory[idx] then
			table.insert(insertedIds, currentInventory[idx].ItemId)
		end
	end

	if #insertedIds < 4 then
		matchedFormulaLabel.Text = string.format("MATCHED FORMULA: NONE (%d/4 Herbs)", #insertedIds)
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