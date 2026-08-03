--!strict
--[[
    InventoryController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
    Client UI controller for ASCEND inventory.
    Triggered via Hotkey 'K'. Respects Studio layout/positioning, populates item grid,
    renders distinct item icons, tooltips, and handles pill/weapon usage.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local InventoryController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local inventoryGui: ScreenGui
local mainModal: GuiObject
local itemGrid: Frame
local slotTemplate: Frame
local tooltipFrame: Frame
local tooltipTitle: TextLabel
local tooltipCategory: TextLabel
local tooltipDesc: TextLabel
local tooltipStats: TextLabel

local slotButtons: { [number]: Frame } = {}
local currentInventory: { [number]: any } = {}
local selectedSlot: number? = nil

local updateInventoryRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent

local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(46, 204, 113),
	Rare      = Color3.fromRGB(52, 152, 219),
	Epic      = Color3.fromRGB(155, 89, 182),
	Legendary = Color3.fromRGB(241, 196, 15),
	Immortal  = Color3.fromRGB(231, 76, 60),
}

function InventoryController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	inventoryGui = playerGui:WaitForChild("InventoryGui", 10) :: ScreenGui
	if not inventoryGui then
		warn("[InventoryController] 'InventoryGui' ScreenGui not found in PlayerGui!")
		return
	end

	inventoryGui.Enabled = true

	mainModal = inventoryGui:WaitForChild("MainModal", 5) :: GuiObject
	if not mainModal then
		warn("[InventoryController] 'MainModal' not found inside InventoryGui!")
		return
	end

	-- Do NOT override Position or Size (Preserve Studio layout!)
	mainModal.Visible = false

	-- Header Banner Title
	local headerBanner = mainModal:FindFirstChild("HeaderBanner")
	if headerBanner then
		local titleLabel = headerBanner:FindFirstChild("Title") or headerBanner:FindFirstChildOfClass("TextLabel")
		if titleLabel and titleLabel:IsA("TextLabel") then
			titleLabel.Text = "🎒 SPIRIT POUCH & INVENTORY"
		end
	end

	-- Close Button Connection
	local closeBtn = mainModal:FindFirstChild("CloseButton")
	if closeBtn then
		local btnComponent = if closeBtn:IsA("GuiButton") then closeBtn else closeBtn:FindFirstChildOfClass("GuiButton")
		if btnComponent then
			(btnComponent :: GuiButton).MouseButton1Click:Connect(function()
				mainModal.Visible = false
				if tooltipFrame then tooltipFrame.Visible = false end
			end)
		end
	end

	itemGrid = mainModal:WaitForChild("ItemGrid", 5) :: Frame
	slotTemplate = itemGrid:WaitForChild("SlotTemplate", 5) :: Frame
	slotTemplate.Visible = false

	InventoryController.SetupGrid()
	InventoryController.SetupTooltip()

	-- Sync Server Inventory
	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventory = inventoryData
		InventoryController.RefreshGrid()
	end)

	-- Hotkey 'K' Trigger Listener
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.K then
			mainModal.Visible = not mainModal.Visible
			if mainModal.Visible then
				InventoryController.RefreshGrid()
			elseif tooltipFrame then
				tooltipFrame.Visible = false
			end
		elseif input.KeyCode == Enum.KeyCode.One then
			InventoryController.UseSlot(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			InventoryController.UseSlot(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			InventoryController.UseSlot(3)
		end
	end)

	print("[ASCEND] InventoryController Bound to Hotkey 'K' Successfully.")
end

function InventoryController.SetupGrid()
	for i = 1, 30 do
		local slot = slotTemplate:Clone()
		slot.Name = "Slot_" .. i
		slot.LayoutOrder = i
		slot.Visible = true
		slot.Parent = itemGrid

		local icon = slot:FindFirstChild("ItemIcon") or slot:FindFirstChild("Icon") or slot:FindFirstChildOfClass("ImageLabel")
		if not icon or not icon:IsA("ImageLabel") then
			local newIcon = Instance.new("ImageLabel")
			newIcon.Name = "ItemIcon"
			newIcon.Size = UDim2.new(1, -10, 1, -10)
			newIcon.Position = UDim2.new(0, 5, 0, 5)
			newIcon.BackgroundTransparency = 1
			newIcon.Visible = false
			newIcon.Parent = slot
		end

		local countLabel = slot:FindFirstChild("CountLabel") or slot:FindFirstChild("Count") or slot:FindFirstChildOfClass("TextLabel")
		if not countLabel or not countLabel:IsA("TextLabel") then
			local newCount = Instance.new("TextLabel")
			newCount.Name = "CountLabel"
			newCount.Size = UDim2.new(1, -4, 0, 16)
			newCount.Position = UDim2.new(0, 0, 1, -18)
			newCount.BackgroundTransparency = 1
			newCount.TextColor3 = Color3.fromRGB(255, 255, 255)
			newCount.TextStrokeTransparency = 0
			newCount.Font = Enum.Font.GothamBold
			newCount.TextSize = 12
			newCount.TextXAlignment = Enum.TextXAlignment.Right
			newCount.Text = ""
			newCount.Parent = slot
		end

		local stroke = slot:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Name = "RarityStroke"
			stroke.Thickness = 1.5
			stroke.Color = Color3.fromRGB(50, 55, 70)
			stroke.Parent = slot
		end

		local btn = slot:FindFirstChildOfClass("TextButton") or slot:FindFirstChildOfClass("ImageButton")
		if not btn then
			local newBtn = Instance.new("TextButton")
			newBtn.Size = UDim2.new(1, 0, 1, 0)
			newBtn.BackgroundTransparency = 1
			newBtn.Text = ""
			newBtn.Parent = slot
			btn = newBtn
		end

		local clickable = btn :: GuiButton
		clickable.MouseButton1Click:Connect(function()
			InventoryController.OnSlotClicked(i)
		end)

		slot.MouseEnter:Connect(function()
			InventoryController.ShowTooltip(i)
		end)

		slot.MouseLeave:Connect(function()
			if tooltipFrame then tooltipFrame.Visible = false end
		end)

		slotButtons[i] = slot
	end
end

function InventoryController.SetupTooltip()
	tooltipFrame = Instance.new("Frame")
	tooltipFrame.Name = "InventoryTooltip"
	tooltipFrame.Size = UDim2.new(0, 220, 0, 130)
	tooltipFrame.BackgroundColor3 = Color3.fromRGB(12, 14, 20)
	tooltipFrame.BorderSizePixel = 0
	tooltipFrame.Visible = false
	tooltipFrame.ZIndex = 100
	tooltipFrame.Parent = inventoryGui

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 8)
	tCorner.Parent = tooltipFrame

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(0, 180, 255)
	tStroke.Thickness = 1.5
	tStroke.Parent = tooltipFrame

	tooltipTitle = Instance.new("TextLabel")
	tooltipTitle.Size = UDim2.new(1, -16, 0, 24)
	tooltipTitle.Position = UDim2.new(0, 8, 0, 6)
	tooltipTitle.BackgroundTransparency = 1
	tooltipTitle.Font = Enum.Font.GothamBold
	tooltipTitle.TextSize = 14
	tooltipTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	tooltipTitle.TextXAlignment = Enum.TextXAlignment.Left
	tooltipTitle.ZIndex = 101
	tooltipTitle.Parent = tooltipFrame

	tooltipCategory = Instance.new("TextLabel")
	tooltipCategory.Size = UDim2.new(1, -16, 0, 18)
	tooltipCategory.Position = UDim2.new(0, 8, 0, 30)
	tooltipCategory.BackgroundTransparency = 1
	tooltipCategory.Font = Enum.Font.GothamMedium
	tooltipCategory.TextSize = 11
	tooltipCategory.TextColor3 = Color3.fromRGB(160, 170, 190)
	tooltipCategory.TextXAlignment = Enum.TextXAlignment.Left
	tooltipCategory.ZIndex = 101
	tooltipCategory.Parent = tooltipFrame

	tooltipDesc = Instance.new("TextLabel")
	tooltipDesc.Size = UDim2.new(1, -16, 0, 42)
	tooltipDesc.Position = UDim2.new(0, 8, 0, 50)
	tooltipDesc.BackgroundTransparency = 1
	tooltipDesc.Font = Enum.Font.Gotham
	tooltipDesc.TextSize = 11
	tooltipDesc.TextColor3 = Color3.fromRGB(200, 205, 220)
	tooltipDesc.TextWrapped = true
	tooltipDesc.TextXAlignment = Enum.TextXAlignment.Left
	tooltipDesc.ZIndex = 101
	tooltipDesc.Parent = tooltipFrame

	tooltipStats = Instance.new("TextLabel")
	tooltipStats.Size = UDim2.new(1, -16, 0, 20)
	tooltipStats.Position = UDim2.new(0, 8, 0, 100)
	tooltipStats.BackgroundTransparency = 1
	tooltipStats.Font = Enum.Font.GothamBold
	tooltipStats.TextSize = 12
	tooltipStats.TextColor3 = Color3.fromRGB(46, 204, 113)
	tooltipStats.TextXAlignment = Enum.TextXAlignment.Left
	tooltipStats.ZIndex = 101
	tooltipStats.Parent = tooltipFrame
end

function InventoryController.RefreshGrid()
	for i = 1, 30 do
		local slotFrame = slotButtons[i]
		if not slotFrame then continue end

		local icon = (slotFrame:FindFirstChild("ItemIcon") or slotFrame:FindFirstChild("Icon") or slotFrame:FindFirstChildOfClass("ImageLabel")) :: ImageLabel?
		local countLabel = (slotFrame:FindFirstChild("CountLabel") or slotFrame:FindFirstChild("Count") or slotFrame:FindFirstChildOfClass("TextLabel")) :: TextLabel?
		local stroke = slotFrame:FindFirstChildOfClass("UIStroke")

		local slotData = currentInventory[i]
		if slotData then
			local itemDef = ItemConfig[slotData.ItemId]
			if itemDef then
				if icon then
					icon.Image = itemDef.Icon
					icon.Visible = true
				end
				if countLabel then
					countLabel.Text = if slotData.Count > 1 then "x" .. slotData.Count else ""
				end
				if stroke then
					stroke.Color = RARITY_COLORS[itemDef.Rarity] or Color3.fromRGB(180, 180, 180)
					stroke.Thickness = 2
				end
			end
		else
			if icon then icon.Visible = false end
			if countLabel then countLabel.Text = "" end
			if stroke then
				stroke.Color = Color3.fromRGB(50, 55, 70)
				stroke.Thickness = 1.5
			end
		end
	end
end

function InventoryController.OnSlotClicked(slotIdx: number)
	if selectedSlot == nil then
		if currentInventory[slotIdx] then
			selectedSlot = slotIdx
			local stroke = slotButtons[slotIdx]:FindFirstChildOfClass("UIStroke")
			if stroke then stroke.Color = Color3.fromRGB(255, 255, 255) end
		end
	else
		if selectedSlot == slotIdx then
			-- Double click to consume/equip
			InventoryController.UseSlot(slotIdx)
			selectedSlot = nil
		else
			-- Swap slots
			inventoryActionRemote:FireServer({
				Action = "SwapSlots",
				FromSlot = selectedSlot,
				ToSlot = slotIdx,
			})
			selectedSlot = nil
		end
		InventoryController.RefreshGrid()
	end
end

function InventoryController.UseSlot(slotIdx: number)
	if currentInventory[slotIdx] then
		inventoryActionRemote:FireServer({
			Action = "UseItem",
			SlotIndex = slotIdx,
		})
	end
end

function InventoryController.ShowTooltip(slotIdx: number)
	local slotData = currentInventory[slotIdx]
	if not slotData then
		if tooltipFrame then tooltipFrame.Visible = false end
		return
	end

	local itemDef = ItemConfig[slotData.ItemId]
	if not itemDef then return end

	local mousePos = UserInputService:GetMouseLocation()
	tooltipFrame.Position = UDim2.new(0, mousePos.X + 15, 0, mousePos.Y - 20)
	tooltipFrame.Visible = true

	tooltipTitle.Text = itemDef.Name
	tooltipTitle.TextColor3 = RARITY_COLORS[itemDef.Rarity] or Color3.fromRGB(255, 255, 255)
	tooltipCategory.Text = string.format("‹ %s — %s ›", itemDef.Rarity, itemDef.Category)
	tooltipDesc.Text = itemDef.Description

	local statText = ""
	if itemDef.HealAmount and itemDef.HealAmount > 0 then
		statText ..= string.format("💚 Restores +%d HP  ", itemDef.HealAmount)
	end
	if itemDef.QiAmount and itemDef.QiAmount > 0 then
		statText ..= string.format("⚡ Restores +%d Spirit Qi", itemDef.QiAmount)
	end
	tooltipStats.Text = statText
end

return InventoryController