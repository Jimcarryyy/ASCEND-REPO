--!strict
--[[
    PlayerDataManager.luau
    Location: src/ServerScriptService/Server/State/PlayerDataManager.luau
    Server-authoritative DataStore persistence manager for ASCEND:
    - DataVersion 3 Persistence Pipeline with Legacy Test Sword Sanitizer
    - Developer Exclusive Arsenal Engine (Auto-grants all present & future swords to Han_jueee only)
    - Normal Player Grind Isolation (Regular players / alts only have MortalIronJian and must buy/earn swords one-by-one)
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

export type SavedInventorySlot = {
	ItemId: string,
	Count: number,
	Quality: string?,
}

export type SavedQuestState = {
	QuestId: string,
	Tier: number,
	CurrentAmount: number,
	AllTiersCompleted: boolean,
}

export type SavedPlayerData = {
	Version: number,
	Cultivation: {
		Realm: CultivationConfig.RealmTier,
		Order: number?,
		CurrentQi: number,
		CultivatedQi: number?,
	},
	EquippedWeapon: string,
	Inventory: { [string]: SavedInventorySlot },
	Sect: string?,
	SectRank: SectConfig.DiscipleRank?,
	ContributionPoints: number?,
	SpiritStones: number?,
	AlchemyExp: number?,
	AlchemyLevel: number?,
	OwnedGamepasses: { [string]: boolean }?,
	UnlockedSkins: { [string]: boolean }?,
	EquippedSkin: string?,
	QuestProgress: { [string]: SavedQuestState }?,
	LastStipendClaim: number?,
}

local PlayerDataManager = {}

local DATA_STORE_NAME = "ASCEND_PlayerData_V3"
local CURRENT_VERSION = 3
local MAX_RETRIES = 3
local AUTO_SAVE_INTERVAL = 300
local SHUTDOWN_SAVE_TIMEOUT = 25
local STARTER_WEAPON = "MortalIronJian"

-- Developer Whitelist for Exclusive Arsenal Access
local DEVELOPER_USERNAMES: { [string]: boolean } = {
	["Han_jueee"] = true,
}

local function IsDeveloper(player: Player): boolean
	if DEVELOPER_USERNAMES[player.Name] then return true end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then return true end
	return false
end

-- Legacy test swords to purge from regular players migrating from V2
local LEGACY_TEST_SWORDS: { [string]: boolean } = {
	["AzureCloudDiscipleJian"] = true,
	["FlowingQiSpiritSword"] = true,
	["VerdantJadeFlyingSword"] = true,
	["BreezeWhisperJian"] = true,
	["VerdantBambooJian"] = true,
	["CrimsonFlameDao"] = true,
}

local playerDataStore: DataStore? = nil
local isLoadedMap: { [Player]: boolean } = {}
local isSavingMap: { [Player]: boolean } = {}

local playerAlchemyData: { [Player]: { Exp: number, Level: number } } = {}
local playerEconomyData: { [Player]: { SpiritStones: number, SectRank: SectConfig.DiscipleRank, ContributionPoints: number } } = {}
local playerGamepasses: { [Player]: { [string]: boolean } } = {}
local playerSkinData: { [Player]: { EquippedSkin: string, UnlockedSkins: { [string]: boolean } } } = {}

local sectManagerRef: any = nil
local function getSectManager(): any
	if not sectManagerRef then
		sectManagerRef = require(ServerScriptService.Server.Cultivation.SectManager)
	end
	return sectManagerRef
end

local DEFAULT_PLAYER_DATA: SavedPlayerData = {
	Version = CURRENT_VERSION,
	Cultivation = {
		Realm = "QiCondensation",
		Order = 1,
		CurrentQi = 200,
		CultivatedQi = 200,
	},
	EquippedWeapon = "MortalIronJian",
	Inventory = {
		["1"] = { ItemId = "MortalIronJian", Count = 1 },
		["2"] = { ItemId = "SpiritHealingDan", Count = 5 },
	},
	Sect = "Azure Cloud Sect",
	SectRank = "OuterDisciple",
	ContributionPoints = 0,
	SpiritStones = 250,
	AlchemyExp = 0,
	AlchemyLevel = 1,
	OwnedGamepasses = {},
	UnlockedSkins = { ["DefaultBronze"] = true },
	EquippedSkin = "DefaultBronze",
}

function PlayerDataManager.Init()
	local success, result = pcall(function()
		return DataStoreService:GetDataStore(DATA_STORE_NAME)
	end)

	if success and result then
		playerDataStore = result
		print("[PlayerDataManager] DataStore V3 initialized successfully.")
	else
		warn("[PlayerDataManager] Could not access DataStoreService. Running with local session memory.")
	end

	Players.PlayerAdded:Connect(PlayerDataManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(PlayerDataManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerDataManager.OnPlayerAdded(player)
		end)
	end

	task.spawn(function()
		while true do
			task.wait(AUTO_SAVE_INTERVAL)
			PlayerDataManager.SaveAllPlayers()
		end
	end)

	game:BindToClose(function()
		print("[PlayerDataManager] Server shutting down... Executing final save for all players.")
		local players = Players:GetPlayers()
		local remaining = #players
		if remaining == 0 then return end

		for _, player in ipairs(players) do
			task.spawn(function()
				PlayerDataManager.SaveData(player)
				remaining -= 1
			end)
		end

		local waited = 0
		while remaining > 0 and waited < SHUTDOWN_SAVE_TIMEOUT do
			task.wait(0.5)
			waited += 0.5
		end
	end)

	print("[PlayerDataManager] Engine Initialized with Strict Weapon Isolation & Version 3 Schema.")
end

function PlayerDataManager.OnPlayerAdded(player: Player)
	local dataKey = "Player_" .. player.UserId
	local loadedData: any = nil

	if playerDataStore then
		for attempt = 1, MAX_RETRIES do
			local success, result = pcall(function()
				return playerDataStore:GetAsync(dataKey)
			end)

			if success then
				if type(result) == "table" then
					loadedData = result
				end
				break
			else
				warn(string.format("[PlayerDataManager] GetAsync attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
				task.wait(1)
			end
		end
	end

	-- Fallback to V2 store if V3 has no record yet
	local isMigratedFromV2 = false
	if not loadedData then
		pcall(function()
			local v2Store = DataStoreService:GetDataStore("ASCEND_PlayerData_V2")
			local oldResult = v2Store:GetAsync(dataKey)
			if oldResult and type(oldResult) == "table" then
				loadedData = oldResult
				isMigratedFromV2 = true
			end
		end)
	end

	if not loadedData then
		print(string.format("[PlayerDataManager] Creating brand new profile for %s.", player.Name))
		loadedData = {
			Version = CURRENT_VERSION,
			Cultivation = {
				Realm = DEFAULT_PLAYER_DATA.Cultivation.Realm,
				Order = DEFAULT_PLAYER_DATA.Cultivation.Order or 1,
				CurrentQi = DEFAULT_PLAYER_DATA.Cultivation.CurrentQi,
				CultivatedQi = DEFAULT_PLAYER_DATA.Cultivation.CultivatedQi or 200,
			},
			EquippedWeapon = DEFAULT_PLAYER_DATA.EquippedWeapon,
			Inventory = {
				[1] = { ItemId = "MortalIronJian", Count = 1 },
				[2] = { ItemId = "SpiritHealingDan", Count = 5 },
			},
			Sect = DEFAULT_PLAYER_DATA.Sect,
			SectRank = DEFAULT_PLAYER_DATA.SectRank or "OuterDisciple",
			ContributionPoints = DEFAULT_PLAYER_DATA.ContributionPoints or 0,
			SpiritStones = DEFAULT_PLAYER_DATA.SpiritStones or 250,
			AlchemyExp = 0,
			AlchemyLevel = 1,
			OwnedGamepasses = {},
			UnlockedSkins = { ["DefaultBronze"] = true },
			EquippedSkin = "DefaultBronze",
		}
	else
		if not loadedData.Version or loadedData.Version < CURRENT_VERSION then
			print(string.format("[PlayerDataManager] Migrating %s data to Version 3 schema.", player.Name))
			loadedData.Version = CURRENT_VERSION
		end
	end

	isLoadedMap[player] = true

	playerAlchemyData[player] = {
		Exp = loadedData.AlchemyExp or 0,
		Level = loadedData.AlchemyLevel or 1,
	}

	playerEconomyData[player] = {
		SpiritStones = loadedData.SpiritStones or 250,
		SectRank = loadedData.SectRank or "OuterDisciple",
		ContributionPoints = loadedData.ContributionPoints or 0,
	}

	playerGamepasses[player] = loadedData.OwnedGamepasses or {}

	playerSkinData[player] = {
		EquippedSkin = loadedData.EquippedSkin or "DefaultBronze",
		UnlockedSkins = loadedData.UnlockedSkins or { ["DefaultBronze"] = true },
	}

	CultivationManager.SetPlayerData(
		player,
		loadedData.Cultivation.Realm,
		loadedData.Cultivation.CurrentQi,
		loadedData.Cultivation.Order or 1,
		loadedData.Cultivation.CultivatedQi
	)

	-- Normalize inventory keys
	local normalizedInventory: { [number]: SavedInventorySlot } = {}
	local isDev = IsDeveloper(player)

	if loadedData.Inventory and type(loadedData.Inventory) == "table" then
		for slotKey, slotData in pairs(loadedData.Inventory) do
			local slotNum = tonumber(slotKey)
			if slotNum and slotData and slotData.ItemId then
				-- If regular player migrating from V2, purge the legacy free test swords
				if not isDev and isMigratedFromV2 and LEGACY_TEST_SWORDS[slotData.ItemId] then
					continue
				end

				normalizedInventory[slotNum] = {
					ItemId = slotData.ItemId,
					Count = slotData.Count or 1,
					Quality = slotData.Quality,
				}
			end
		end
	end

	-- =========================================================================
	-- WEAPON ACCESS MANAGEMENT
	-- =========================================================================
	if isDev then
		-- Developer: Auto-grant every weapon defined in the game
		print(string.format("[PlayerDataManager] Developer detected (%s) — injecting full weapon arsenal.", player.Name))
		local allItems = ItemConfig.GetAllItems()

		for itemId, itemDef in pairs(allItems) do
			if itemDef.Type == "Weapon" then
				local alreadyOwned = false
				for _, slot in pairs(normalizedInventory) do
					if slot.ItemId == itemId then
						alreadyOwned = true
						break
					end
				end

				if not alreadyOwned then
					local targetSlot = 1
					while normalizedInventory[targetSlot] ~= nil do
						targetSlot += 1
					end
					normalizedInventory[targetSlot] = { ItemId = itemId, Count = 1 }
				end
			end
		end
	else
		-- Regular Player / Alt: Ensure ONLY MortalIronJian is given if no weapon is possessed
		local hasWeapon = false
		for _, slot in pairs(normalizedInventory) do
			local itemDef = ItemConfig.GetItem(slot.ItemId)
			if itemDef and itemDef.Type == "Weapon" then
				hasWeapon = true
				break
			end
		end

		if not hasWeapon then
			local targetSlot = 1
			while normalizedInventory[targetSlot] ~= nil do
				targetSlot += 1
			end
			normalizedInventory[targetSlot] = { ItemId = STARTER_WEAPON, Count = 1 }
			loadedData.EquippedWeapon = STARTER_WEAPON
		end
	end

	InventoryManager.SetInventory(player, normalizedInventory)
	WeaponManager.EquipWeapon(player, loadedData.EquippedWeapon or STARTER_WEAPON)

	local SectManager = getSectManager()
	if SectManager.SetQuestState then
		SectManager.SetQuestState(player, loadedData.QuestProgress)
	end
	if SectManager.SetLastStipendClaim then
		SectManager.SetLastStipendClaim(player, loadedData.LastStipendClaim)
	end

	-- Sync Player Attributes
	player:SetAttribute("Sect", loadedData.Sect or "Azure Cloud Sect")
	player:SetAttribute("SectRank", playerEconomyData[player].SectRank)
	player:SetAttribute("SpiritStones", playerEconomyData[player].SpiritStones)
	player:SetAttribute("ContributionPoints", playerEconomyData[player].ContributionPoints)
	player:SetAttribute("EquippedHUDSkin", loadedData.EquippedSkin or "DefaultBronze")

	local function bindChar(character: Model)
		character:SetAttribute("Sect", loadedData.Sect or "Azure Cloud Sect")
		character:SetAttribute("SectRank", playerEconomyData[player].SectRank)
		character:SetAttribute("SpiritStones", playerEconomyData[player].SpiritStones)
		character:SetAttribute("ContributionPoints", playerEconomyData[player].ContributionPoints)
	end

	if player.Character then
		bindChar(player.Character)
	end
	player.CharacterAdded:Connect(bindChar)

	print(string.format("[PlayerDataManager] Successfully loaded data for %s (Realm: %s, Order: %d, Stones: %d, Rank: %s).",
		player.Name,
		loadedData.Cultivation.Realm,
		loadedData.Cultivation.Order or 1,
		loadedData.SpiritStones or 250,
		loadedData.SectRank or "OuterDisciple"
	))
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	PlayerDataManager.SaveData(player)
	task.delay(1.5, function()
		isLoadedMap[player] = nil
		playerAlchemyData[player] = nil
		playerEconomyData[player] = nil
		playerGamepasses[player] = nil
		playerSkinData[player] = nil
	end)
end

function PlayerDataManager.GetSpiritStones(player: Player): number
	local data = playerEconomyData[player]
	return data and data.SpiritStones or 0
end

function PlayerDataManager.AddSpiritStones(player: Player, amount: number): number
	local data = playerEconomyData[player]
	if not data then return 0 end
	data.SpiritStones = math.max(0, data.SpiritStones + amount)
	player:SetAttribute("SpiritStones", data.SpiritStones)
	if player.Character then
		player.Character:SetAttribute("SpiritStones", data.SpiritStones)
	end
	return data.SpiritStones
end

function PlayerDataManager.RemoveSpiritStones(player: Player, amount: number): boolean
	local data = playerEconomyData[player]
	if not data or data.SpiritStones < amount then return false end
	data.SpiritStones -= amount
	player:SetAttribute("SpiritStones", data.SpiritStones)
	if player.Character then
		player.Character:SetAttribute("SpiritStones", data.SpiritStones)
	end
	return true
end

function PlayerDataManager.GetSectRank(player: Player): SectConfig.DiscipleRank
	local data = playerEconomyData[player]
	return data and data.SectRank or "OuterDisciple"
end

function PlayerDataManager.SetSectRank(player: Player, rank: SectConfig.DiscipleRank)
	local data = playerEconomyData[player]
	if not data then return end
	data.SectRank = rank
	player:SetAttribute("SectRank", rank)
	if player.Character then
		player.Character:SetAttribute("SectRank", rank)
	end
end

function PlayerDataManager.GetContributionPoints(player: Player): number
	local data = playerEconomyData[player]
	return data and data.ContributionPoints or 0
end

function PlayerDataManager.AddContributionPoints(player: Player, amount: number): number
	local data = playerEconomyData[player]
	if not data then return 0 end
	data.ContributionPoints = math.max(0, data.ContributionPoints + amount)
	player:SetAttribute("ContributionPoints", data.ContributionPoints)
	if player.Character then
		player.Character:SetAttribute("ContributionPoints", data.ContributionPoints)
	end
	return data.ContributionPoints
end

function PlayerDataManager.HasGamepass(player: Player, passId: string): boolean
	local passes = playerGamepasses[player]
	return passes and passes[passId] == true or false
end

function PlayerDataManager.SetGamepassOwned(player: Player, passId: string)
	local passes = playerGamepasses[player]
	if not passes then
		passes = {}
		playerGamepasses[player] = passes
	end
	passes[passId] = true
end

function PlayerDataManager.AddAlchemyExp(player: Player, expGained: number): (number, number)
	local data = playerAlchemyData[player]
	if not data then
		data = { Exp = 0, Level = 1 }
		playerAlchemyData[player] = data
	end

	data.Exp += expGained
	local requiredExp = data.Level * 100

	while data.Exp >= requiredExp do
		data.Exp -= requiredExp
		data.Level += 1
		requiredExp = data.Level * 100
		print(string.format("[PlayerDataManager] %s leveled up Alchemy to Rank %d!", player.Name, data.Level))
	end

	return data.Exp, data.Level
end

function PlayerDataManager.GetAlchemyData(player: Player): (number, number)
	local data = playerAlchemyData[player]
	if not data then return 0, 1 end
	return data.Exp, data.Level
end

function PlayerDataManager.SaveData(player: Player): boolean
	if not isLoadedMap[player] or not playerDataStore or isSavingMap[player] then
		return false
	end
	isSavingMap[player] = true

	local cultivation = CultivationManager.GetPlayerData(player)
	local inventory = InventoryManager.GetInventory(player)
	local equippedWeapon = WeaponManager.GetEquippedWeapon(player)
	local alchemy = playerAlchemyData[player] or { Exp = 0, Level = 1 }
	local economy = playerEconomyData[player] or { SpiritStones = 250, SectRank = "OuterDisciple", ContributionPoints = 0 }
	local gamepasses = playerGamepasses[player] or {}
	local skinData = playerSkinData[player] or { EquippedSkin = "DefaultBronze", UnlockedSkins = { ["DefaultBronze"] = true } }

	local SectManager = getSectManager()
	local questProgress = SectManager.GetQuestState and SectManager.GetQuestState(player) or nil
	local lastStipendClaim = SectManager.GetLastStipendClaim and SectManager.GetLastStipendClaim(player) or nil

	if not cultivation then
		isSavingMap[player] = false
		return false
	end

	local serializedInventory: { [string]: SavedInventorySlot } = {}
	for slotIdx, slot in pairs(inventory) do
		if slot and slot.ItemId then
			serializedInventory[tostring(slotIdx)] = {
				ItemId = slot.ItemId,
				Count = slot.Count or 1,
				Quality = slot.Quality,
			}
		end
	end

	local dataToSave: SavedPlayerData = {
		Version = CURRENT_VERSION,
		Cultivation = {
			Realm = cultivation.Realm,
			Order = cultivation.Order,
			CurrentQi = cultivation.CurrentQi,
			CultivatedQi = cultivation.CultivatedQi,
		},
		EquippedWeapon = equippedWeapon or STARTER_WEAPON,
		Inventory = serializedInventory,
		Sect = (player.Character and player.Character:GetAttribute("Sect") :: string?) or "Azure Cloud Sect",
		SectRank = economy.SectRank,
		ContributionPoints = economy.ContributionPoints,
		SpiritStones = economy.SpiritStones,
		AlchemyExp = alchemy.Exp,
		AlchemyLevel = alchemy.Level,
		OwnedGamepasses = gamepasses,
		UnlockedSkins = skinData.UnlockedSkins,
		EquippedSkin = skinData.EquippedSkin,
		QuestProgress = questProgress,
		LastStipendClaim = lastStipendClaim,
	}

	local dataKey = "Player_" .. player.UserId
	local saveSuccess = false

	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			playerDataStore:SetAsync(dataKey, dataToSave)
		end)

		if success then
			saveSuccess = true
			print(string.format("[PlayerDataManager] Successfully saved data for %s.", player.Name))
			break
		else
			warn(string.format("[PlayerDataManager] SetAsync attempt %d failed for %s: %s", attempt, player.Name, tostring(err)))
			task.wait(0.5)
		end
	end

	isSavingMap[player] = false
	return saveSuccess
end

function PlayerDataManager.SaveAllPlayers()
	print("[PlayerDataManager] Auto-saving data for all connected players...")
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			PlayerDataManager.SaveData(player)
		end)
	end
end

return PlayerDataManager