--!strict
--[[
    VendorManager.luau
    Location: src/ServerScriptService/Server/World/VendorManager.luau
    Server-authoritative Market & Trading Manager for the Jade Pure Sword Sect.
    Handles: Buying, Selling, Spirit Stone transactions, Rank validation, and ProximityPrompt interactions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

local VendorManager = {}

local marketRemote: RemoteEvent

-- Rank weight map to verify rank requirements
local RANK_WEIGHTS: { [SectConfig.DiscipleRank]: number } = {
	["OuterDisciple"] = 1,
	["InnerDisciple"] = 2,
	["CoreDisciple"] = 3,
	["DirectDisciple"] = 4,
	["SectElder"] = 5,
	["GrandElder"] = 6,
}

local function HasRequiredRank(playerRank: SectConfig.DiscipleRank, requiredRank: SectConfig.DiscipleRank): boolean
	local playerWeight = RANK_WEIGHTS[playerRank] or 1
	local reqWeight = RANK_WEIGHTS[requiredRank] or 1
	return playerWeight >= reqWeight
end

function VendorManager.Init()
	marketRemote = RemoteEvents.GetRemote("MarketAction")

	-- Listen for Client Purchase & Sell Requests
	marketRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "BuyItem" then
			VendorManager.ProcessBuy(player, payload.ItemId, payload.Amount or 1)
		elseif action == "SellItem" then
			VendorManager.ProcessSell(player, payload.ItemId, payload.Amount or 1)
		elseif action == "RequestMarketData" then
			VendorManager.SyncMarketData(player)
		end
	end)

	-- Scan Workspace, NPCs, and Functional_Stations for Vendor Prompts
	task.spawn(VendorManager.SetupVendorPrompts)

	print("[ASCEND] VendorManager Initialized (Sect Market & Universal ProximityPrompts Active).")
end

function VendorManager.SetupVendorPrompts()
	local function BindVendorPrompt(prompt: ProximityPrompt)
		if prompt.Name == "VendorPrompt" or prompt.ActionText == "Browse General Goods" or prompt.ActionText == "Trade Goods" or prompt.ActionText == "Open Contribution Shop" then
			prompt.Triggered:Connect(function(player: Player)
				VendorManager.OpenShopForPlayer(player)
			end)
		end
	end

	-- Scan all prompts across Workspace
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			BindVendorPrompt(desc)
		end
	end

	-- Listen for dynamically added vendor models/prompts
	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			BindVendorPrompt(desc)
		end
	end)
end

function VendorManager.OpenShopForPlayer(player: Player)
	local stones = PlayerDataManager.GetSpiritStones(player)
	local rank = PlayerDataManager.GetSectRank(player)
	local items = SectConfig.GetAllMarketItems()

	marketRemote:FireClient(player, {
		Action = "OpenShop",
		SpiritStones = stones,
		SectRank = rank,
		Catalog = items,
	})
end

function VendorManager.SyncMarketData(player: Player)
	local stones = PlayerDataManager.GetSpiritStones(player)
	local rank = PlayerDataManager.GetSectRank(player)

	marketRemote:FireClient(player, {
		Action = "SyncBalance",
		SpiritStones = stones,
		SectRank = rank,
	})
end

function VendorManager.ProcessBuy(player: Player, itemId: any, amount: any)
	if type(itemId) ~= "string" or type(amount) ~= "number" or amount <= 0 then return end
	amount = math.floor(amount)

	local itemDef = SectConfig.GetMarketItem(itemId)
	if not itemDef or not itemDef.BuyPrice then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "Item is not for sale." })
		return
	end

	local playerRank = PlayerDataManager.GetSectRank(player)
	if not HasRequiredRank(playerRank, itemDef.RequiredRank) then
		local rankDef = SectConfig.GetRank(itemDef.RequiredRank)
		marketRemote:FireClient(player, { 
			Action = "TransactionFailed", 
			Message = string.format("Requires rank: %s", rankDef.DisplayName) 
		})
		return
	end

	local catalogDef = ItemConfig.GetItem(itemId)
	if catalogDef and catalogDef.Type == "Weapon" then
		amount = 1
		if InventoryManager.HasItem(player, itemId, 1) then
			marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "You already own this sword." })
			return
		end
	end

	local totalCost = itemDef.BuyPrice * amount
	local currentStones = PlayerDataManager.GetSpiritStones(player)

	if currentStones < totalCost then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "Insufficient Spirit Stones!" })
		return
	end

	local added = InventoryManager.AddItem(player, itemId, amount)
	if not added then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "Spirit Pouch is full!" })
		return
	end

	PlayerDataManager.RemoveSpiritStones(player, totalCost)

	marketRemote:FireClient(player, {
		Action = "TransactionSuccess",
		Type = "Buy",
		ItemId = itemId,
		Amount = amount,
		TotalCost = totalCost,
		NewBalance = PlayerDataManager.GetSpiritStones(player),
	})

	print(string.format("[VendorManager] %s purchased %dx %s for %d Spirit Stones.", player.Name, amount, itemId, totalCost))
end

function VendorManager.ProcessSell(player: Player, itemId: any, amount: any)
	if type(itemId) ~= "string" or type(amount) ~= "number" or amount <= 0 then return end
	amount = math.floor(amount)

	local itemDef = SectConfig.GetMarketItem(itemId)
	if not itemDef or itemDef.SellPrice <= 0 then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "Item cannot be sold." })
		return
	end

	if not InventoryManager.HasItem(player, itemId, amount) then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "You do not have enough of this item." })
		return
	end

	local removed = InventoryManager.RemoveItem(player, itemId, amount)
	if not removed then
		marketRemote:FireClient(player, { Action = "TransactionFailed", Message = "Failed to remove items from bag." })
		return
	end

	local totalPayout = itemDef.SellPrice * amount
	PlayerDataManager.AddSpiritStones(player, totalPayout)

	marketRemote:FireClient(player, {
		Action = "TransactionSuccess",
		Type = "Sell",
		ItemId = itemId,
		Amount = amount,
		TotalPayout = totalPayout,
		NewBalance = PlayerDataManager.GetSpiritStones(player),
	})

	print(string.format("[VendorManager] %s sold %dx %s for %d Spirit Stones.", player.Name, amount, itemId, totalPayout))
end

return VendorManager