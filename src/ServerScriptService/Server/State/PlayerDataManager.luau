--!strict
--[[
    PlayerDataManager.luau
    Location: src/ServerScriptService/Server/State/PlayerDataManager.luau
    Server-authoritative DataStore persistence manager for ASCEND.
    Persists: Cultivation (Realm, Order, Qi), Inventory, Spirit Stones, Sect Rank, Contribution Points, and Gamepasses.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

export type SavedInventorySlot = {
	ItemId: string,
	Count: number,
	Quality: string?,
}

export type SavedPlayerData = {
	Version: number,
	Cultivation: {
		Realm: CultivationConfig.RealmTier,
		Order: number?,
		CurrentQi: number,
		CultivatedQi: number?,
	},
	EquippedWeapon: WeaponManager.WeaponType,
	Inventory: { [number]: SavedInventorySlot },
	Sect: string?,
	SectRank: SectConfig.DiscipleRank?,
	ContributionPoints: number?,
	SpiritStones: number?,
	AlchemyExp: number?,
	AlchemyLevel: number?,
	OwnedGamepasses: { [string]: boolean }?,
	UnlockedSkins: { [string]: boolean }?,
	EquippedSkin: string?,
}

local PlayerDataManager = {}

local DATA_STORE_NAME = "ASCEND_PlayerData_V2"
local MAX_RETRIES = 3
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes

local playerDataStore: DataStore? = nil
local isLoadedMap: { [Player]: boolean } = {}
local playerAlchemyData: { [Player]: { Exp: number, Level: number } } = {}
local playerEconomyData: { [Player]: { SpiritStones: number, SectRank: SectConfig.DiscipleRank, ContributionPoints: number } } = {}
local playerGamepasses: { [Player]: { [string]: boolean } } = {}
local playerSkinData: { [Player]: { EquippedSkin: string, UnlockedSkins: { [string]: boolean } } } = {}

local DEFAULT_PLAYER_DATA: SavedPlayerData = {
	Version = 2,
	Cultivation = {
		Realm = "QiCondensation",
		Order = 1,
		CurrentQi = 200,
		CultivatedQi = 200,
	},
	EquippedWeapon = "FlyingSwordItem",
	Inventory = {
		[1] = { ItemId = "SpiritHealingDan", Count = 5 },
		[2] = { ItemId = "FoundationGatheringDan", Count = 3 },
		[3] = { ItemId = "SpiritGrass", Count = 12 },
		[4] = { ItemId = "FlyingSwordItem", Count = 1 },
		[5] = { ItemId = "GauntletItem", Count = 1 },
		[6] = { ItemId = "SpearItem", Count = 1 },
	},
	Sect = "Azure Cloud Sect",
	SectRank = "OuterDisciple",
	ContributionPoints = 0,
	SpiritStones = 250, -- Starting spirit stone allowance
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
		print("[PlayerDataManager] DataStore V2 initialized successfully.")
	else
		warn("[PlayerDataManager] Could not access DataStoreService. API access may be disabled in Studio settings. Running with local session memory.")
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
		PlayerDataManager.SaveAllPlayers()
		task.wait(2)
	end)

	print("[PlayerDataManager] Engine Initialized with Sect Economy & DataStore V2 Schema.")
end

function PlayerDataManager.OnPlayerAdded(player: Player)
	local dataKey = "Player_" .. player.UserId
	local loadedData: SavedPlayerData? = nil

	if playerDataStore then
		for attempt = 1, MAX_RETRIES do
			local success, result = pcall(function()
				return playerDataStore:GetAsync(dataKey)
			end)

			if success then
				if type(result) == "table" then
					loadedData = result :: SavedPlayerData
				end
				break
			else
				warn(string.format("[PlayerDataManager] GetAsync attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
				task.wait(1)
			end
		end
	end

	if not loadedData then
		print(string.format("[PlayerDataManager] No saved data found for %s. Applying default starter profile.", player.Name))
		loadedData = {
			Version = DEFAULT_PLAYER_DATA.Version,
			Cultivation = {
				Realm = DEFAULT_PLAYER_DATA.Cultivation.Realm,
				Order = DEFAULT_PLAYER_DATA.Cultivation.Order or 1,
				CurrentQi = DEFAULT_PLAYER_DATA.Cultivation.CurrentQi,
				CultivatedQi = DEFAULT_PLAYER_DATA.Cultivation.CultivatedQi or 200,
			},
			EquippedWeapon = DEFAULT_PLAYER_DATA.EquippedWeapon,
			Inventory = table.clone(DEFAULT_PLAYER_DATA.Inventory),
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
		print(string.format("[PlayerDataManager] Successfully loaded data for %s (Realm: %s, Order: %d, CultivatedQi: %s, Stones: %d, Rank: %s).", 
			player.Name, 
			loadedData.Cultivation.Realm, 
			loadedData.Cultivation.Order or 1, 
			CultivationConfig.FormatNumber(loadedData.Cultivation.CultivatedQi or 200),
			loadedData.SpiritStones or 250,
			loadedData.SectRank or "OuterDisciple"
		))
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

	-- Restore saved CultivatedQi and Order into CultivationManager
	CultivationManager.SetPlayerData(
		player, 
		loadedData.Cultivation.Realm, 
		loadedData.Cultivation.CurrentQi, 
		loadedData.Cultivation.Order or 1, 
		loadedData.Cultivation.CultivatedQi
	)
	
	InventoryManager.SetInventory(player, loadedData.Inventory)
	WeaponManager.EquipWeapon(player, loadedData.EquippedWeapon or "FlyingSwordItem")

	-- Set Character Attributes for client replication
	local character = player.Character or player.CharacterAdded:Wait()
	character:SetAttribute("Sect", loadedData.Sect or "Azure Cloud Sect")
	character:SetAttribute("SectRank", playerEconomyData[player].SectRank)
	character:SetAttribute("SpiritStones", playerEconomyData[player].SpiritStones)
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	PlayerDataManager.SaveData(player)
	isLoadedMap[player] = nil
	playerAlchemyData[player] = nil
	playerEconomyData[player] = nil
	playerGamepasses[player] = nil
	playerSkinData[player] = nil
end

-- ECONOMY & SPIRIT STONES
function PlayerDataManager.GetSpiritStones(player: Player): number
	local data = playerEconomyData[player]
	return data and data.SpiritStones or 0
end

function PlayerDataManager.AddSpiritStones(player: Player, amount: number): number
	local data = playerEconomyData[player]
	if not data then return 0 end
	data.SpiritStones = math.max(0, data.SpiritStones + amount)
	if player.Character then
		player.Character:SetAttribute("SpiritStones", data.SpiritStones)
	end
	return data.SpiritStones
end

function PlayerDataManager.RemoveSpiritStones(player: Player, amount: number): boolean
	local data = playerEconomyData[player]
	if not data or data.SpiritStones < amount then return false end
	data.SpiritStones -= amount
	if player.Character then
		player.Character:SetAttribute("SpiritStones", data.SpiritStones)
	end
	return true
end

-- SECT RANK & CONTRIBUTION
function PlayerDataManager.GetSectRank(player: Player): SectConfig.DiscipleRank
	local data = playerEconomyData[player]
	return data and data.SectRank or "OuterDisciple"
end

function PlayerDataManager.SetSectRank(player: Player, rank: SectConfig.DiscipleRank)
	local data = playerEconomyData[player]
	if not data then return end
	data.SectRank = rank
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
	return data.ContributionPoints
end

-- GAMEPASSES & SKINS
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

-- ALCHEMY DATA
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
	if not isLoadedMap[player] or not playerDataStore then
		return false
	end

	local cultivation = CultivationManager.GetPlayerData(player)
	local inventory = InventoryManager.GetInventory(player)
	local equippedWeapon = WeaponManager.GetEquippedWeapon(player)
	local alchemy = playerAlchemyData[player] or { Exp = 0, Level = 1 }
	local economy = playerEconomyData[player] or { SpiritStones = 250, SectRank = "OuterDisciple", ContributionPoints = 0 }
	local gamepasses = playerGamepasses[player] or {}
	local skinData = playerSkinData[player] or { EquippedSkin = "DefaultBronze", UnlockedSkins = { ["DefaultBronze"] = true } }

	if not cultivation then return false end

	local serializedInventory: { [number]: SavedInventorySlot } = {}
	for slotIdx, slot in pairs(inventory) do
		if slot then
			serializedInventory[slotIdx] = {
				ItemId = slot.ItemId,
				Count = slot.Count,
				Quality = slot.Quality,
			}
		end
	end

	local dataToSave: SavedPlayerData = {
		Version = 2,
		Cultivation = {
			Realm = cultivation.Realm,
			Order = cultivation.Order,
			CurrentQi = cultivation.CurrentQi,
			CultivatedQi = cultivation.CultivatedQi,
		},
		EquippedWeapon = equippedWeapon,
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
			task.wait(1)
		end
	end

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