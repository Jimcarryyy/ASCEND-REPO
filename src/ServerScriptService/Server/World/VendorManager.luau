--!strict
--[[
    VendorManager.luau
    Location: src/ServerScriptService/Server/World/VendorManager.luau
    Server-authoritative vendor transaction and NPC merchant manager for ASCEND:
    - Binds ProximityPrompts for NPC merchants across Workspace (Merchant Qian & Sect Bazaar)
    - Handles MarketAction server events (BuyItem, SellItem, RequestMarketData)
    - Bulk Transaction Support: Allows selling and purchasing up to 9,999 items at once
    - Fixed: Delivers updated Inventory payload on BOTH BuyItem and SellItem transactions
    - Authoritative Spirit Stone deduction and inventory item addition/removal
    - Strict Sword Trading Ban (weapons cannot be bought or sold at general merchants)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

local VendorManager = {}
local marketActionRemote: RemoteEvent

local function BindMerchantPrompt(prompt: ProximityPrompt)
	if prompt:GetAttribute("VendorBound") == true then return end
	prompt:SetAttribute("VendorBound", true)

	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = 14
	prompt.Enabled = true

	prompt.Triggered:Connect(function(player: Player)
		marketActionRemote:FireClient(player, { Action = "OpenShop" })
	end)
end

function VendorManager.Init()
	marketActionRemote = RemoteEvents.GetRemote("MarketAction")

	-- Transaction Gateway
	marketActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end
		local action = payload.Action
		local itemId = payload.ItemId
		local amount = math.clamp(tonumber(payload.Amount) or 1, 1, 9999)

		if action == "RequestMarketData" or action == "GetMarketCatalog" then
			marketActionRemote:FireClient(player, {
				Action = "MarketData",
				Catalog = SectConfig.GetAllMarketItems(),
				Inventory = InventoryManager.GetInventory(player),
			})
			return
		end

		if not itemId or type(itemId) ~= "string" then return end
		local itemDef = ItemConfig.GetItem(itemId)
		if not itemDef then return end

		-- SERVER SECURITY POLICY: Weapons cannot be traded at General Merchant
		if itemDef.Type == "Weapon" then
			warn(string.format("[SECURITY] %s attempted to trade weapon '%s' at General Merchant! Blocked.", player.Name, itemId))
			marketActionRemote:FireClient(player, {
				Action = "TransactionFailed",
				Message = "Swords are sacred artifacts and cannot be traded here!",
			})
			return
		end

		if action == "BuyItem" or action == "BuyGoods" then
			local catalogItem = SectConfig.GetMarketItem(itemId)
			local unitPrice = (catalogItem and catalogItem.BuyPrice) or (itemDef.AgeYears and itemDef.AgeYears * 15) or 50
			local totalCost = unitPrice * amount

			if catalogItem and catalogItem.RequiredRank then
				local playerRank = (player:GetAttribute("SectRank") :: any) or "OuterDisciple"
				if not SectConfig.CanPurchase(playerRank, catalogItem.RequiredRank) then
					marketActionRemote:FireClient(player, {
						Action = "TransactionFailed",
						Message = string.format("Requires %s rank to purchase!", tostring(catalogItem.RequiredRank):gsub("Disciple", "")),
					})
					return
				end
			end

			if PlayerDataManager.GetSpiritStones(player) >= totalCost then
				PlayerDataManager.RemoveSpiritStones(player, totalCost)
				InventoryManager.AddItem(player, itemId, amount)
				print(string.format("[VENDOR] %s bought %dx %s for %d Stones.", player.Name, amount, itemDef.Name or itemId, totalCost))

				-- Deliver fresh inventory payload back to client
				marketActionRemote:FireClient(player, {
					Action = "TransactionSuccess",
					Type = "Buy",
					ItemId = itemId,
					Amount = amount,
					Inventory = InventoryManager.GetInventory(player),
				})
			else
				marketActionRemote:FireClient(player, {
					Action = "TransactionFailed",
					Message = "Insufficient Spirit Stones!",
				})
			end

		elseif action == "SellItem" or action == "SellLoot" then
			local catalogItem = SectConfig.GetMarketItem(itemId)
			local unitSellPrice = (catalogItem and catalogItem.SellPrice) or math.max(1, math.floor(((itemDef.AgeYears and itemDef.AgeYears * 10) or 12) * 0.7))
			local totalPayout = unitSellPrice * amount

			if InventoryManager.HasItem(player, itemId, amount) then
				InventoryManager.RemoveItem(player, itemId, amount)
				PlayerDataManager.AddSpiritStones(player, totalPayout)
				print(string.format("[VENDOR] %s sold %dx %s for +%d Stones.", player.Name, amount, itemDef.Name or itemId, totalPayout))

				marketActionRemote:FireClient(player, {
					Action = "TransactionSuccess",
					Type = "Sell",
					ItemId = itemId,
					Amount = amount,
					TotalPayout = totalPayout,
					Inventory = InventoryManager.GetInventory(player),
				})
			else
				marketActionRemote:FireClient(player, {
					Action = "TransactionFailed",
					Message = "You do not have enough items to sell!",
				})
			end
		end
	end)

	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then
			local parentName = desc.Parent and desc.Parent.Name or ""
			local ancestorName = desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or ""
			local actionText = desc.ActionText or ""
			local objectText = desc.ObjectText or ""

			if string.find(parentName:lower(), "merchant") or string.find(ancestorName:lower(), "merchant")
				or string.find(parentName:lower(), "qian") or string.find(ancestorName:lower(), "qian")
				or string.find(actionText:lower(), "goods") or string.find(actionText:lower(), "trade")
				or string.find(objectText:lower(), "merchant") or string.find(objectText:lower(), "trader") then
				BindMerchantPrompt(desc)
			end
		end
	end

	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then
			local parentName = desc.Parent and desc.Parent.Name or ""
			local ancestorName = desc.Parent and desc.Parent.Parent and desc.Parent.Parent.Name or ""
			local actionText = desc.ActionText or ""
			local objectText = desc.ObjectText or ""

			if string.find(parentName:lower(), "merchant") or string.find(ancestorName:lower(), "merchant")
				or string.find(parentName:lower(), "qian") or string.find(ancestorName:lower(), "qian")
				or string.find(actionText:lower(), "goods") or string.find(actionText:lower(), "trade")
				or string.find(objectText:lower(), "merchant") or string.find(objectText:lower(), "trader") then
				BindMerchantPrompt(desc)
			end
		end
	end)

	print("[ASCEND] VendorManager Initialized (Refreshed Inventory Delivery on Purchases Active).")
end

return VendorManager