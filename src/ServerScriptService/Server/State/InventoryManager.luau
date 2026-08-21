--!strict
--[[
    InventoryManager.luau
    Location: src/ServerScriptService/Server/State/InventoryManager.luau
    Server-authoritative inventory engine for ASCEND.
    Capped at 60 slots with dynamic testing items injection and weapon equipping.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type InventorySlot = {
	ItemId: string,
	Count: number,
	Quality: string?,
}

local InventoryManager = {}
local MAX_SLOTS = 60

local playerInventories: { [Player]: { [number]: InventorySlot? } } = {}

local updateInventoryRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent

function InventoryManager.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	Players.PlayerAdded:Connect(InventoryManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(InventoryManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		InventoryManager.OnPlayerAdded(player)
	end

	inventoryActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "RequestSync" then
			InventoryManager.EnsureTestItems(player)
			InventoryManager.SyncClient(player)
		elseif payload.Action == "UseItem" and type(payload.SlotIndex) == "number" then
			InventoryManager.UseItem(player, payload.SlotIndex)
		elseif payload.Action == "SwapSlots" and type(payload.FromSlot) == "number" and type(payload.ToSlot) == "number" then
			InventoryManager.SwapSlots(player, payload.FromSlot, payload.ToSlot)
		elseif payload.Action == "DropItem" and type(payload.SlotIndex) == "number" then
			InventoryManager.DropItem(player, payload.SlotIndex)
		end
	end)

	print("[ASCEND] InventoryManager Engine Initialized with 60 Slots & Dynamic Sword Equipping.")
end

function InventoryManager.OnPlayerAdded(player: Player)
	if not playerInventories[player] then
		playerInventories[player] = {}
		InventoryManager.EnsureTestItems(player)
	end
end

function InventoryManager.EnsureTestItems(player: Player)
	local inv = playerInventories[player]
	if not inv then
		inv = {}
		playerInventories[player] = inv
	end

	-- Inject consumable pills & herbs
	if not InventoryManager.HasItem(player, "SpiritHealingDan", 1) then
		InventoryManager.AddItem(player, "SpiritHealingDan", 5, "Standard Quality")
		InventoryManager.AddItem(player, "FoundationGatheringDan", 3, "Standard Quality")
		InventoryManager.AddItem(player, "SpiritGrass_10Yr", 12)
	end

	-- Inject all 4 swords into Spirit Pouch for testing
	local testSwords = {
		"MortalIronJian",
		"AzureCloudDiscipleJian",
		"FlowingQiSpiritSword",
		"VerdantJadeFlyingSword",
	}

	for _, swordId in ipairs(testSwords) do
		if not InventoryManager.HasItem(player, swordId, 1) then
			InventoryManager.AddItem(player, swordId, 1)
		end
	end
end

function InventoryManager.OnPlayerRemoving(player: Player)
	playerInventories[player] = nil
end

function InventoryManager.GetInventory(player: Player): { [number]: InventorySlot? }
	return playerInventories[player] or {}
end

function InventoryManager.AddItem(player: Player, itemId: string, count: number, quality: string?): boolean
	local itemDef = ItemConfig.GetItem(itemId)
	if not itemDef then return false end

	local inv = playerInventories[player]
	if not inv then return false end

	local maxStack = itemDef.MaxStack or 1
	local remaining = count

	-- 1. Stack into existing slots
	for slotIdx = 1, MAX_SLOTS do
		local slot = inv[slotIdx]
		if slot and slot.ItemId == itemId and slot.Quality == quality and slot.Count < maxStack then
			local space = maxStack - slot.Count
			local toAdd = math.min(space, remaining)
			slot.Count += toAdd
			remaining -= toAdd
			if remaining <= 0 then break end
		end
	end

	-- 2. Populate empty slots
	if remaining > 0 then
		for slotIdx = 1, MAX_SLOTS do
			if not inv[slotIdx] then
				local toAdd = math.min(maxStack, remaining)
				inv[slotIdx] = {
					ItemId = itemId,
					Count = toAdd,
					Quality = quality,
				}
				remaining -= toAdd
				if remaining <= 0 then break end
			end
		end
	end

	InventoryManager.SyncClient(player)
	return remaining == 0
end

function InventoryManager.SetInventory(player: Player, inventoryData: { [number]: InventorySlot? })
	playerInventories[player] = {}

	if inventoryData then
		for slotIdx, slot in pairs(inventoryData) do
			if slot and type(slot.ItemId) == "string" and type(slot.Count) == "number" then
				playerInventories[player][slotIdx] = {
					ItemId = slot.ItemId,
					Count = slot.Count,
					Quality = slot.Quality,
				}
			end
		end
	end

	InventoryManager.EnsureTestItems(player)
	task.wait(0.2)
	InventoryManager.SyncClient(player)
end

function InventoryManager.UseItem(player: Player, slotIndex: number)
	local inv = playerInventories[player]
	if not inv or slotIndex < 1 or slotIndex > MAX_SLOTS then return end

	local slot = inv[slotIndex]
	if not slot then return end

	local itemDef = ItemConfig.GetItem(slot.ItemId)
	if not itemDef then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	if itemDef.Type == "Consumable" then
		local used = false

		if itemDef.Stats and itemDef.Stats.HealAmount and itemDef.Stats.HealAmount > 0 then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + itemDef.Stats.HealAmount)
			used = true
		end

		if itemDef.Stats and itemDef.Stats.QiGrant and itemDef.Stats.QiGrant > 0 then
			local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
			local pData = CultivationManager.GetPlayerData(player)
			if pData then
				pData.CurrentQi = math.min(800, pData.CurrentQi + itemDef.Stats.QiGrant)
				CultivationManager.SyncClient(player)
				used = true
			end
		end

		if used then
			slot.Count -= 1
			if slot.Count <= 0 then
				inv[slotIndex] = nil
			end
		end

	elseif itemDef.Type == "Weapon" or itemDef.Type == "Crest" then
		-- Dynamically equip weapon on character
		local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
		WeaponManager.EquipWeapon(player, itemDef.Id)
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

function InventoryManager.HasItem(player: Player, itemId: string, requiredCount: number): boolean
	local inv = playerInventories[player]
	if not inv then return false end

	local total = 0
	for _, slot in pairs(inv) do
		if slot and slot.ItemId == itemId then
			total += slot.Count
			if total >= requiredCount then
				return true
			end
		end
	end
	return false
end

function InventoryManager.RemoveItem(player: Player, itemId: string, countToRemove: number): boolean
	if not InventoryManager.HasItem(player, itemId, countToRemove) then
		return false
	end

	local inv = playerInventories[player]
	if not inv then return false end

	local remaining = countToRemove

	for slotIdx = 1, MAX_SLOTS do
		local slot = inv[slotIdx]
		if slot and slot.ItemId == itemId then
			if slot.Count <= remaining then
				remaining -= slot.Count
				inv[slotIdx] = nil
			else
				slot.Count -= remaining
				remaining = 0
			end

			if remaining <= 0 then
				break
			end
		end
	end

	InventoryManager.SyncClient(player)
	return true
end

function InventoryManager.DropItem(player: Player, slotIndex: number)
	local inv = playerInventories[player]
	if not inv or slotIndex < 1 or slotIndex > MAX_SLOTS then return end

	local slot = inv[slotIndex]
	if slot then
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