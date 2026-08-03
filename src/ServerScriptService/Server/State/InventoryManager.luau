--!strict
--[[
    InventoryManager.luau
    Location: src/ServerScriptService/Server/State/InventoryManager.luau
    Server-authoritative inventory engine. Manages 30 player inventory slots,
    item consumption (Pill healing & Qi restore), item equip calls, and real-time network sync.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type InventorySlot = {
	ItemId: string,
	Count: number,
}

local InventoryManager = {}
local MAX_SLOTS = 30

-- Player inventory stores: [Player] -> { [number]: InventorySlot? }
local playerInventories: { [Player]: { [number]: InventorySlot? } } = {}

local updateInventoryRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent

function InventoryManager.Init()
	-- Fetch network remotes inside Init() after RemoteEvents finishes setup
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	Players.PlayerAdded:Connect(InventoryManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(InventoryManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		InventoryManager.OnPlayerAdded(player)
	end

	inventoryActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "UseItem" and type(payload.SlotIndex) == "number" then
			InventoryManager.UseItem(player, payload.SlotIndex)
		elseif payload.Action == "SwapSlots" and type(payload.FromSlot) == "number" and type(payload.ToSlot) == "number" then
			InventoryManager.SwapSlots(player, payload.FromSlot, payload.ToSlot)
		elseif payload.Action == "DropItem" and type(payload.SlotIndex) == "number" then
			InventoryManager.DropItem(player, payload.SlotIndex)
		end
	end)

	print("[ASCEND] InventoryManager Engine Initialized.")
end

function InventoryManager.OnPlayerAdded(player: Player)
	playerInventories[player] = {}

	-- Populate Starter Items
	InventoryManager.AddItem(player, "SpiritHealingDan", 5)
	InventoryManager.AddItem(player, "FoundationGatheringDan", 3)
	InventoryManager.AddItem(player, "SpiritGrass", 12)
	InventoryManager.AddItem(player, "FlyingSwordItem", 1)
	InventoryManager.AddItem(player, "GauntletItem", 1)
	InventoryManager.AddItem(player, "SpearItem", 1)

	task.wait(1.0)
	InventoryManager.SyncClient(player)
end

function InventoryManager.OnPlayerRemoving(player: Player)
	playerInventories[player] = nil
end

function InventoryManager.GetInventory(player: Player): { [number]: InventorySlot? }
	return playerInventories[player] or {}
end

function InventoryManager.AddItem(player: Player, itemId: string, count: number): boolean
	local itemDef = ItemConfig[itemId]
	if not itemDef then return false end

	local inv = playerInventories[player]
	if not inv then return false end

	local remaining = count

	-- 1. Try stacking into existing slots
	for slotIdx = 1, MAX_SLOTS do
		local slot = inv[slotIdx]
		if slot and slot.ItemId == itemId and slot.Count < itemDef.MaxStack then
			local space = itemDef.MaxStack - slot.Count
			local toAdd = math.min(space, remaining)
			slot.Count += toAdd
			remaining -= toAdd
			if remaining <= 0 then break end
		end
	end

	-- 2. Place into new empty slots
	if remaining > 0 then
		for slotIdx = 1, MAX_SLOTS do
			if not inv[slotIdx] then
				local toAdd = math.min(itemDef.MaxStack, remaining)
				inv[slotIdx] = {
					ItemId = itemId,
					Count = toAdd,
				}
				remaining -= toAdd
				if remaining <= 0 then break end
			end
		end
	end

	InventoryManager.SyncClient(player)
	return remaining == 0
end

function InventoryManager.UseItem(player: Player, slotIndex: number)
	local inv = playerInventories[player]
	if not inv or slotIndex < 1 or slotIndex > MAX_SLOTS then return end

	local slot = inv[slotIndex]
	if not slot then return end

	local itemDef = ItemConfig[slot.ItemId]
	if not itemDef then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- Consumable Execution
	if itemDef.Category == "Consumable" then
		local used = false

		-- Heal HP
		if itemDef.HealAmount and itemDef.HealAmount > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + itemDef.HealAmount)
			used = true
		end

		-- Restore Qi
		if itemDef.QiAmount and itemDef.QiAmount > 0 then
			local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
			local pData = CultivationManager.GetPlayerData(player)
			if pData then
				pData.CurrentQi = math.min(10000, pData.CurrentQi + itemDef.QiAmount)
				CultivationManager.SyncClient(player)
				used = true
			end
		end

		if used then
			slot.Count -= 1
			if slot.Count <= 0 then
				inv[slotIndex] = nil
			end
			print(string.format("[InventoryManager] %s consumed %s", player.Name, itemDef.Name))
		end

	-- Weapon Equip Execution
	elseif itemDef.Category == "Weapon" and itemDef.WeaponType then
		local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
		WeaponManager.EquipWeapon(player, itemDef.WeaponType)
		print(string.format("[InventoryManager] %s equipped weapon: %s", player.Name, itemDef.Name))
	end

	InventoryManager.SyncClient(player)
end

function InventoryManager.SwapSlots(player: Player, fromSlot: number, toSlot: number)
	local inv = playerInventories[player]
	if not inv then return end
	if fromSlot < 1 or fromSlot > MAX_SLOTS or toSlot < 1 or toSlot > MAX_SLOTS then return end

	local temp = inv[fromSlot]
	inv[fromSlot] = inv[toSlot]
	inv[toSlot] = temp

	InventoryManager.SyncClient(player)
end

function InventoryManager.DropItem(player: Player, slotIndex: number)
	local inv = playerInventories[player]
	if not inv or slotIndex < 1 or slotIndex > MAX_SLOTS then return end

	local slot = inv[slotIndex]
	if slot then
		print(string.format("[InventoryManager] %s dropped item from slot %d", player.Name, slotIndex))
		inv[slotIndex] = nil
		InventoryManager.SyncClient(player)
	end
end

function InventoryManager.SyncClient(player: Player)
	local inv = playerInventories[player] or {}
	if updateInventoryRemote then
		updateInventoryRemote:FireClient(player, inv)
	end
end

return InventoryManager