--!strict
--[[
    SwordAltarManager.luau
    Location: src/ServerScriptService/Server/World/SwordAltarManager.luau
    Server-authoritative Sword Altar Gacha & Communion Engine:
      - Validates player Spirit Stones via PlayerDataManager
      - Delivers swords & items directly via InventoryManager
      - Replicates persistent Pity via Player attributes ("AltarPity")
      - Weighted Xianxia RNG Table (5★ 2.5%, 4★ 12%, 3★ 35.5%, 2★ 50%)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

local SwordAltarManager = {}
local altarRemote: RemoteEvent? = nil

-- Pricing & Pity Limits
local COST_1X = 100
local COST_10X = 900
local HARD_PITY = 50

-- Weighted Drop Pools
local POOL_5_STAR = {
	{ Id = "RadiantImmortalSovereignJian", Name = "Celestial Jade Dragon Jian", Type = "Weapon", Rarity = "Mythic" },
	{ Id = "AzurePatriarchHeritageJian", Name = "Cosmic Void Sovereign Jian", Type = "Weapon", Rarity = "Mythic" },
}

local POOL_4_STAR = {
	{ Id = "CrimsonFlameDao", Name = "Crimson Flame Dao", Type = "Weapon", Rarity = "Legendary" },
	{ Id = "FrostLotusDao", Name = "Frost Lotus Dao", Type = "Weapon", Rarity = "Legendary" },
	{ Id = "VoidStarCleaverDao", Name = "Void Star Cleaver Dao", Type = "Weapon", Rarity = "Legendary" },
}

local POOL_3_STAR = {
	{ Id = "ThunderCragJian", Name = "Thunder Crag Jian", Type = "Weapon", Rarity = "Rare" },
	{ Id = "MortalIronJian", Name = "Refined Iron Jian", Type = "Weapon", Rarity = "Rare" },
}

local POOL_2_STAR = {
	{ Id = "SpiritHerb_SpiritGrass", Name = "Spirit Grass Bundle (x5)", Type = "Item", Quantity = 5, Rarity = "Common" },
	{ Id = "Item_Dan_FoundationPill", Name = "Qi Gathering Dan", Type = "Item", Quantity = 2, Rarity = "Common" },
	{ Id = "SpiritHealingDan", Name = "Spirit Healing Dan (x3)", Type = "Item", Quantity = 3, Rarity = "Common" },
}

local function RollSingleDraw(player: Player): (any, boolean)
	local currentPity = (player:GetAttribute("AltarPity") :: number?) or 0
	local roll = math.random() * 100.0
	local isGuaranteed = (currentPity + 1) >= HARD_PITY

	-- 1. Check Hard Pity or Natural 5-Star (2.5%)
	if isGuaranteed or roll <= 2.5 then
		player:SetAttribute("AltarPity", 0) -- Reset pity
		local pick = POOL_5_STAR[math.random(1, #POOL_5_STAR)]
		return pick, true
	end

	-- Increment Pity for non-5-star pulls
	player:SetAttribute("AltarPity", currentPity + 1)

	-- 2. 4-Star Legendary (12.0% -> roll 2.5 to 14.5)
	if roll <= 14.5 then
		return POOL_4_STAR[math.random(1, #POOL_4_STAR)], false
	end

	-- 3. 3-Star Rare (35.5% -> roll 14.5 to 50.0)
	if roll <= 50.0 then
		return POOL_3_STAR[math.random(1, #POOL_3_STAR)], false
	end

	-- 4. 2-Star Consumables (50.0% -> roll 50.0 to 100.0)
	return POOL_2_STAR[math.random(1, #POOL_2_STAR)], false
end

function SwordAltarManager.ProcessCommune(player: Player, pullCount: number)
	if pullCount ~= 1 and pullCount ~= 10 then return end
	local cost = (pullCount == 1) and COST_1X or COST_10X

	local currentStones = PlayerDataManager.GetSpiritStones(player)
	if currentStones < cost then
		if altarRemote then
			altarRemote:FireClient(player, {
				Success = false,
				Message = string.format("Insufficient Spirit Stones! Required: %d, Owned: %d", cost, currentStones)
			})
		end
		return
	end

	-- Deduct Spirit Stones safely through PlayerDataManager
	local successDeduct = PlayerDataManager.RemoveSpiritStones(player, cost)
	if not successDeduct then
		if altarRemote then
			altarRemote:FireClient(player, {
				Success = false,
				Message = "Transaction failed. Please try again."
			})
		end
		return
	end

	local results = {}
	for _ = 1, pullCount do
		local reward, is5Star = RollSingleDraw(player)

		-- Deliver items & weapons directly into InventoryManager
		InventoryManager.AddItem(player, reward.Id, reward.Quantity or 1)

		table.insert(results, {
			Id = reward.Id,
			Name = reward.Name,
			Type = reward.Type,
			Rarity = reward.Rarity,
			Quantity = reward.Quantity or 1,
			IsMythic = is5Star,
		})
	end

	local newPity = (player:GetAttribute("AltarPity") :: number?) or 0
	local remainingStones = PlayerDataManager.GetSpiritStones(player)

	if altarRemote then
		altarRemote:FireClient(player, {
			Success = true,
			Results = results,
			NewStones = remainingStones,
			NewPity = newPity,
			PullCount = pullCount,
		})
	end

	print(string.format("[SwordAltarManager] %s completed %dX Commune! New Pity: %d, Stones Remaining: %d",
		player.Name, pullCount, newPity, remainingStones))
end

function SwordAltarManager.Init()
	altarRemote = RemoteEvents.GetRemote("AltarAction")

	altarRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "Commune" then
			SwordAltarManager.ProcessCommune(player, tonumber(payload.Count) or 1)
		elseif payload.Action == "GetPity" then
			local pity = (player:GetAttribute("AltarPity") :: number?) or 0
			local stones = PlayerDataManager.GetSpiritStones(player)

			if altarRemote then
				altarRemote:FireClient(player, {
					Action = "PitySync",
					Pity = pity,
					Stones = stones,
				})
			end
		end
	end)

	print("[ASCEND] SwordAltarManager Initialized (Weighted RNG & 50-Pull Hard Pity Active).")
end

return SwordAltarManager