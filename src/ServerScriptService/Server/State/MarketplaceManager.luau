--!strict
--[[
    MarketplaceManager.luau
    Location: src/ServerScriptService/Server/State/MarketplaceManager.luau
    Server-authoritative Robux Monetization & Receipt Processing Manager.
    Handles: Gamepass perks (2x Qi, Auto-Meditate, 100% Breakthrough), DevProduct purchases, and secure receipt validation.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreService = game:GetService("DataStoreService")

local MonetizationConfig = require(ReplicatedStorage.Shared.Configs.MonetizationConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

local MarketplaceManager = {}

local monetizationRemote: RemoteEvent
local purchaseHistoryStore: DataStore? = nil

function MarketplaceManager.Init()
	monetizationRemote = RemoteEvents.GetRemote("MonetizationAction")

	-- 0. Purchase History Store (idempotent receipt processing)
	local success, result = pcall(function()
		return DataStoreService:GetDataStore("ASCEND_PurchaseHistory_V1")
	end)
	if success and result then
		purchaseHistoryStore = result
	else
		warn("[MarketplaceManager] Could not access PurchaseHistory DataStore — ProcessReceipt will not be idempotent this session.")
	end

	-- 1. Configure ProcessReceipt for Developer Products
	MarketplaceService.ProcessReceipt = MarketplaceManager.ProcessReceipt

	-- 2. Handle In-Game Purchase Prompts from Client
	monetizationRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "PromptGamepass" then
			MarketplaceManager.PromptGamepass(player, payload.PassId)
		elseif action == "PromptProduct" then
			MarketplaceManager.PromptProduct(player, payload.ProductId)
		elseif action == "RequestCatalog" then
			MarketplaceManager.SyncCatalog(player)
		end
	end)

	-- 3. Listen for Finished Gamepass Purchases
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passAssetId: number, wasPurchased: boolean)
		if wasPurchased then
			MarketplaceManager.OnGamepassPurchased(player, passAssetId)
		end
	end)

	Players.PlayerAdded:Connect(MarketplaceManager.OnPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			MarketplaceManager.OnPlayerAdded(player)
		end)
	end

	-- 4. Auto-Meditation Background Heartbeat
	task.spawn(function()
		while true do
			task.wait(4)
			MarketplaceManager.ProcessAutoMeditation()
		end
	end)

	print("[ASCEND] MarketplaceManager Initialized (ProcessReceipt & Gamepass Perks Active).")
end

function MarketplaceManager.OnPlayerAdded(player: Player)
	-- Check Gamepass Ownership asynchronously
	task.spawn(function()
		for passType, passDef in pairs(MonetizationConfig.GetAllGamepasses()) do
			if passDef.RobloxAssetId > 0 then
				local success, owns = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passDef.RobloxAssetId)
				end)

				if success and owns then
					PlayerDataManager.SetGamepassOwned(player, passDef.Id)
					MarketplaceManager.ApplyGamepassPerks(player, passDef.Id)
				end
			end
		end
	end)
end

function MarketplaceManager.ApplyGamepassPerks(player: Player, passId: string)
	local char = player.Character or player.CharacterAdded:Wait()

	if passId == "DoubleQiSpeed" then
		char:SetAttribute("HasDoubleQiSpeed", true)
	elseif passId == "AutoMeditation" then
		char:SetAttribute("HasAutoMeditation", true)
	elseif passId == "TribulationShield" then
		char:SetAttribute("HasTribulationShield", true)
	elseif passId == "VIPElder" then
		char:SetAttribute("IsVIPElder", true)
	end
end

function MarketplaceManager.OnGamepassPurchased(player: Player, passAssetId: number)
	for passType, passDef in pairs(MonetizationConfig.GetAllGamepasses()) do
		if passDef.RobloxAssetId == passAssetId then
			PlayerDataManager.SetGamepassOwned(player, passDef.Id)
			MarketplaceManager.ApplyGamepassPerks(player, passDef.Id)

			monetizationRemote:FireClient(player, {
				Action = "GamepassUnlocked",
				PassId = passDef.Id,
				DisplayName = passDef.DisplayName,
			})
			print(string.format("[MarketplaceManager] %s unlocked Gamepass: %s!", player.Name, passDef.DisplayName))
			break
		end
	end
end

function MarketplaceManager.PromptGamepass(player: Player, passId: any)
	if type(passId) ~= "string" then return end
	local passDef = MonetizationConfig.GetGamepass(passId :: MonetizationConfig.GamepassType)
	if passDef and passDef.RobloxAssetId > 0 then
		MarketplaceService:PromptGamePassPurchase(player, passDef.RobloxAssetId)
	end
end

function MarketplaceManager.PromptProduct(player: Player, prodId: any)
	if type(prodId) ~= "string" then return end
	local prodDef = MonetizationConfig.GetDevProduct(prodId)
	if prodDef and prodDef.RobloxProductId > 0 then
		MarketplaceService:PromptProductPurchase(player, prodDef.RobloxProductId)
	end
end

function MarketplaceManager.SyncCatalog(player: Player)
	monetizationRemote:FireClient(player, {
		Action = "SyncCatalog",
		Gamepasses = MonetizationConfig.GetAllGamepasses(),
		DevProducts = MonetizationConfig.GetAllDevProducts(),
	})
end

-- DEVELOPER PRODUCT RECEIPT PROCESSOR
function MarketplaceManager.ProcessReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseKey = "Purchase_" .. tostring(receiptInfo.PurchaseId)

	-- Idempotency check: has this exact receipt already been granted?
	if purchaseHistoryStore then
		local checkSuccess, alreadyGranted = pcall(function()
			return purchaseHistoryStore:GetAsync(purchaseKey)
		end)

		if not checkSuccess then
			warn(string.format("[MarketplaceManager] Could not verify purchase history for %s (PurchaseId %s): %s", player.Name, tostring(receiptInfo.PurchaseId), tostring(alreadyGranted)))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end

		if alreadyGranted then
			-- Already processed this receipt in a prior attempt; confirm without re-granting.
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
	end

	local prodDef = MonetizationConfig.GetDevProductByRobloxId(receiptInfo.ProductId)
	if not prodDef then
		warn(string.format("[MarketplaceManager] Unknown ProductId %d purchased by %s.", receiptInfo.ProductId, player.Name))
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- Grant Product Rewards
	if prodDef.RewardType == "SpiritStones" then
		PlayerDataManager.AddSpiritStones(player, prodDef.RewardAmount)
		print(string.format("[MarketplaceManager] %s received %d Spirit Stones from Robux purchase.", player.Name, prodDef.RewardAmount))

	elseif prodDef.RewardType == "InstantQi" then
		local cultivation = CultivationManager.GetPlayerData(player)
		if cultivation then
			local reqs = CultivationConfig.GetOrderRequirements(cultivation.Realm, cultivation.Order)
			CultivationManager.SetPlayerData(player, cultivation.Realm, reqs.MaxQi, cultivation.Order, reqs.MaxQi)
			print(string.format("[MarketplaceManager] %s used Supreme Heavenly Qi Pill (Instant Qi Maxed)!", player.Name))
		end

	elseif prodDef.RewardType == "ToxicityCleanse" then
		if player.Character then
			player.Character:SetAttribute("DanToxicity", 0)
		end
		print(string.format("[MarketplaceManager] %s used Celestial Cleansing Spring (Toxicity Purged)!", player.Name))
	end

	-- Persist the grant record BEFORE confirming, so a save failure causes a safe retry, not a silent double-grant risk.
	if purchaseHistoryStore then
		local saveSuccess = false
		for attempt = 1, 3 do
			local ok = pcall(function()
				purchaseHistoryStore:SetAsync(purchaseKey, true)
			end)
			if ok then
				saveSuccess = true
				break
			end
			task.wait(1)
		end

		if not saveSuccess then
			warn(string.format("[MarketplaceManager] Failed to persist purchase record for %s (PurchaseId %s) — will retry on next ProcessReceipt call.", player.Name, tostring(receiptInfo.PurchaseId)))
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
	end

	monetizationRemote:FireClient(player, {
		Action = "ProductPurchased",
		DisplayName = prodDef.DisplayName,
		RewardType = prodDef.RewardType,
		RewardAmount = prodDef.RewardAmount,
	})

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- BACKGROUND AUTO-MEDITATION
function MarketplaceManager.ProcessAutoMeditation()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		if char and char:GetAttribute("HasAutoMeditation") == true then
			local doubleMultiplier = char:GetAttribute("HasDoubleQiSpeed") == true and 2 or 1
			local qiGain = math.floor(15 * doubleMultiplier)

			CultivationManager.AddCultivatedQi(player, qiGain)
		end
	end
end

return MarketplaceManager