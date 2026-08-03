--!strict
--[[
    InventoryController.luau
    Manages inventory modal window, item grid population, dynamic rarity border updates,
    and modal opening/closing input.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local RarityConfig = require(ReplicatedStorage.Shared.Configs.RarityConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

export type InventoryItemData = {
	ID: string,
	Name: string,
	IconAsset: string,
	Rarity: RarityConfig.RarityTier,
	Quantity: number,
}

local InventoryController = {}
InventoryController.__index = InventoryController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local inventoryGui: ScreenGui
local mainModal: ImageLabel
local itemGrid: ScrollingFrame
local slotTemplate: Frame
local closeButton: ImageButton

local isOpen = false

function InventoryController.Init()
	inventoryGui = playerGui:WaitForChild("InventoryGui") :: ScreenGui
	mainModal = inventoryGui:WaitForChild("MainModal") :: ImageLabel
	itemGrid = mainModal:WaitForChild("ItemGrid") :: ScrollingFrame
	slotTemplate = itemGrid:WaitForChild("SlotTemplate") :: Frame
	closeButton = mainModal:WaitForChild("CloseButton") :: ImageButton

	slotTemplate.Visible = false

	closeButton.MouseButton1Click:Connect(function()
		InventoryController.ToggleInventory(false)
	end)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.Tab or input.KeyCode == Enum.KeyCode.I then
			InventoryController.ToggleInventory(not isOpen)
		end
	end)

	-- Sample testing inventory items
	InventoryController.PopulateInventory({
		{ ID = "1", Name = "Flying Sword", IconAsset = UIAssets.Weapons.FlyingSword, Rarity = "Heaven", Quantity = 1 },
		{ ID = "2", Name = "Low Spirit Stone", IconAsset = UIAssets.Currencies.SpiritStoneLow, Rarity = "Mortal", Quantity = 150 },
		{ ID = "3", Name = "Breakthrough Pill", IconAsset = UIAssets.Currencies.PillBreakthrough, Rarity = "Divine", Quantity = 3 },
		{ ID = "4", Name = "Demon Core", IconAsset = UIAssets.Currencies.DemonCore, Rarity = "Immortal", Quantity = 1 },
	})
end

function InventoryController.ToggleInventory(visible: boolean)
	isOpen = visible
	inventoryGui.Enabled = isOpen
end

function InventoryController.PopulateInventory(items: { InventoryItemData })
	-- Clear existing grid children except template and layout
	for _, child in ipairs(itemGrid:GetChildren()) do
		if child:IsA("Frame") and child ~= slotTemplate then
			child:Destroy()
		end
	end

	for index, item in ipairs(items) do
		local slot = slotTemplate:Clone()
		slot.Name = "Slot_" .. tostring(index)
		slot.Visible = true

		local iconLabel = slot:FindFirstChild("ItemIcon") :: ImageLabel
		if iconLabel then
			iconLabel.Image = item.IconAsset
		end

		local amountLabel = slot:FindFirstChild("AmountText") :: TextLabel
		if amountLabel then
			amountLabel.Text = if item.Quantity > 1 then "x" .. tostring(item.Quantity) else ""
		end

		-- Apply UIStroke rarity border dynamically
		local stroke = slot:FindFirstChildOfClass("UIStroke")
		if stroke then
			local rarityData = RarityConfig[item.Rarity]
			if rarityData then
				stroke.Color = rarityData.Color
			else
				stroke.Color = RarityConfig.Mortal.Color
			end
		end

		slot.Parent = itemGrid
	end
end

return InventoryController