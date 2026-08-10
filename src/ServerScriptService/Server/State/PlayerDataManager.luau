--!strict
--[[
    PlayerDataManager.luau
    Location: src/ServerScriptService/Server/State/PlayerDataManager.luau
    Server-authoritative DataStore persistence manager for ASCEND.
    Saves and restores Player Realm, Qi, Inventory items, Equipped Weapon, and Alchemy Mastery EXP.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(game:GetService("ReplicatedStorage").Shared.Configs.CultivationConfig)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

export type SavedInventorySlot = {
	ItemId: string,
	Count: number,
}

export type SavedPlayerData = {
	Version: number,
	Cultivation: {
		Realm: CultivationConfig.RealmTier,
		CurrentQi: number,
	},
	EquippedWeapon: WeaponManager.WeaponType,
	Inventory: { [number]: SavedInventorySlot },
	Sect: string?,
	AlchemyExp: number?,
	AlchemyLevel: number?,
}

local PlayerDataManager = {}

local DATA_STORE_NAME = "ASCEND_PlayerData_V2"
local MAX_RETRIES = 3
local AUTO_SAVE_INTERVAL = 300 -- 5 minutes

local playerDataStore: DataStore? = nil
local isLoadedMap: { [Player]: boolean } = {}
local playerAlchemyData: { [Player]: { Exp: number, Level: number } } = {}

local DEFAULT_PLAYER_DATA: SavedPlayerData = {
	Version = 2,
	Cultivation = {
		Realm = "QiCondensation",
		CurrentQi = 0,
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
	AlchemyExp = 0,
	AlchemyLevel = 1,
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

	print("[PlayerDataManager] Engine Initialized with Alchemy Mastery Tracking.")
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
				CurrentQi = DEFAULT_PLAYER_DATA.Cultivation.CurrentQi,
			},
			EquippedWeapon = DEFAULT_PLAYER_DATA.EquippedWeapon,
			Inventory = table.clone(DEFAULT_PLAYER_DATA.Inventory),
			Sect = DEFAULT_PLAYER_DATA.Sect,
			AlchemyExp = 0,
			AlchemyLevel = 1,
		}
	else
		print(string.format("[PlayerDataManager] Successfully loaded data for %s (Realm: %s, Weapon: %s).", player.Name, loadedData.Cultivation.Realm, loadedData.EquippedWeapon))
	end

	isLoadedMap[player] = true
	playerAlchemyData[player] = {
		Exp = loadedData.AlchemyExp or 0,
		Level = loadedData.AlchemyLevel or 1,
	}

	CultivationManager.SetPlayerData(player, loadedData.Cultivation.Realm, loadedData.Cultivation.CurrentQi)
	InventoryManager.SetInventory(player, loadedData.Inventory)
	WeaponManager.EquipWeapon(player, loadedData.EquippedWeapon or "FlyingSwordItem")
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	PlayerDataManager.SaveData(player)
	isLoadedMap[player] = nil
	playerAlchemyData[player] = nil
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
	if not isLoadedMap[player] or not playerDataStore then
		return false
	end

	local cultivation = CultivationManager.GetPlayerData(player)
	local inventory = InventoryManager.GetInventory(player)
	local equippedWeapon = WeaponManager.GetEquippedWeapon(player)
	local alchemy = playerAlchemyData[player] or { Exp = 0, Level = 1 }

	if not cultivation then return false end

	local serializedInventory: { [number]: SavedInventorySlot } = {}
	for slotIdx, slot in pairs(inventory) do
		if slot then
			serializedInventory[slotIdx] = {
				ItemId = slot.ItemId,
				Count = slot.Count,
			}
		end
	end

	local dataToSave: SavedPlayerData = {
		Version = 2,
		Cultivation = {
			Realm = cultivation.Realm,
			CurrentQi = cultivation.CurrentQi,
		},
		EquippedWeapon = equippedWeapon,
		Inventory = serializedInventory,
		Sect = (player.Character and player.Character:GetAttribute("Sect") :: string?) or "Azure Cloud Sect",
		AlchemyExp = alchemy.Exp,
		AlchemyLevel = alchemy.Level,
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