--!strict
--[[
    PlayerDataManager.luau
    Location: src/ServerScriptService/Server/State/PlayerDataManager.luau
    Server-authoritative DataStore persistence manager for ASCEND.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

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

export type SavedBloodlinePity = {
	SpinsSinceLegendary: number?,
	SpinsSinceMythic: number?,
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
	Bloodline: string?,
	BloodlineSpins: number?,
	BloodlineSlots: { [string]: string }?,
	MaxBloodlineSlots: number?,
	BloodlinePity: SavedBloodlinePity?,
	SamsaraCycle: number?,
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

local function ToRoman(num: number): string
	local romanNumerals = {
		{ 10, "X" }, { 9, "IX" }, { 5, "V" }, { 4, "IV" }, { 1, "I" }
	}
	local result = ""
	local remaining = num
	for _, pair in ipairs(romanNumerals) do
		local val, sym = pair[1], pair[2]
		while remaining >= val do
			result ..= sym
			remaining -= val
		end
	end
	return if result ~= "" then result else "I"
end

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

local playerRawDataCache: { [Player]: any } = {}
local playerAlchemyData: { [Player]: { Exp: number, Level: number } } = {}
local playerEconomyData: { [Player]: { SpiritStones: number, SectRank: SectConfig.DiscipleRank, ContributionPoints: number } } = {}
local playerGamepasses: { [Player]: { [string]: boolean } } = {}
local playerSkinData: { [Player]: { EquippedSkin: string, UnlockedSkins: { [string]: boolean } } } = {}

local playerBloodlines: {
	[Player]: {
		Current: string,
		Spins: number,
		Slots: { [number]: string },
		MaxSlots: number,
		Pity: { SpinsSinceLegendary: number, SpinsSinceMythic: number },
	}
} = {}

local playerSamsaraData: { [Player]: number } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}

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
	Bloodline = "MortalSwordBone",
	BloodlineSpins = 5,
	BloodlineSlots = { ["1"] = "MortalSwordBone" },
	MaxBloodlineSlots = 1,
	BloodlinePity = {
		SpinsSinceLegendary = 0,
		SpinsSinceMythic = 0,
	},
	SamsaraCycle = 0,
	LastStipendClaim = 0,
}

local function GetPrimarySpawnLocation(): SpawnLocation?
	local spawnLoc = Workspace:FindFirstChild("SpawnLocation")
		or Workspace:FindFirstChildWhichIsA("SpawnLocation", true)

	if spawnLoc and spawnLoc:IsA("SpawnLocation") and spawnLoc.Enabled then
		return spawnLoc
	end
	return nil
end

local function RouteToSpawnDais(character: Model)
	if not character or not character.Parent then return end
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hrp or not character.Parent then return end

	local daisSpawn = GetPrimarySpawnLocation()
	if daisSpawn then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		local targetCF = daisSpawn.CFrame * CFrame.new(0, (daisSpawn.Size.Y / 2) + 3.5, 0)
		character:PivotTo(targetCF)
	end
end

local function AttachBloodlineVisual(char: Model, bloodlineId: string)
	local old = char:FindFirstChild("BloodlineArtifact")
	if old then old:Destroy() end

	local def = BloodlineConfig.GetBloodline(bloodlineId)
	if not def or not def.VisualArtifact then return end

	local vSpec = def.VisualArtifact
	local parentPart = char:FindFirstChild(vSpec.AttachmentPoint) :: BasePart?
		or char:FindFirstChild("UpperTorso") :: BasePart?
		or char:FindFirstChild("Torso") :: BasePart?
	if not parentPart then return end

	local modelsFolder = ReplicatedStorage:FindFirstChild("Bloodlines")
		or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Bloodlines"))
	local preMadeModel = modelsFolder and modelsFolder:FindFirstChild(vSpec.ArtifactName) :: Model?

	if not preMadeModel then return end

	local artifactModel = preMadeModel:Clone()
	artifactModel.Name = "BloodlineArtifact"
	for _, p in ipairs(artifactModel:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = false
			p.CanCollide = false
			p.Massless = true
		end
	end

	local prim = artifactModel.PrimaryPart or artifactModel:FindFirstChildWhichIsA("BasePart", true)
	if prim then
		artifactModel.Parent = char
		local offset = if vSpec.AttachmentPoint == "Head" then Vector3.new(0, 1.4, 0) else Vector3.new(0, 0.4, 0.95)
		prim.CFrame = parentPart.CFrame * CFrame.new(offset)

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = parentPart
		weld.Part1 = prim
		weld.Parent = prim
	end
end

local function AttachSamsaraCelestialAura(character: Model, cycle: number)
	if cycle <= 0 then return end
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end

	local existing = character:FindFirstChild("SamsaraCelestialAura")
	if existing then existing:Destroy() end

	local auraFolder = Instance.new("Folder")
	auraFolder.Name = "SamsaraCelestialAura"
	auraFolder.Parent = character

	local attCenter = Instance.new("Attachment")
	attCenter.Name = "SamsaraCenterAtt"
	attCenter.Position = Vector3.new(0, -2.5, 0)
	attCenter.Parent = root

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "CelestialLotusParticles"
	particles.Texture = "rbxassetid://6015897843"
	particles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 120)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 240, 255)),
	})
	particles.LightEmission = 0.9
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.4),
		NumberSequenceKeypoint.new(1.0, 1.2),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.2),
		NumberSequenceKeypoint.new(0.8, 0.6),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	particles.Lifetime = NumberRange.new(1.2, 1.8)
	particles.Rate = math.min(10 + cycle * 4, 30)
	particles.Speed = NumberRange.new(0.5, 1.5)
	particles.SpreadAngle = Vector2.new(180, 20)
	particles.Parent = attCenter

	for _, footName in ipairs({ "LeftFoot", "RightFoot", "Left Leg", "Right Leg" }) do
		local footPart = character:FindFirstChild(footName) :: BasePart?
		if footPart and not footPart:FindFirstChild("SamsaraTrail") then
			local a0 = Instance.new("Attachment")
			a0.Name = "TrailAtt0"
			a0.Position = Vector3.new(0, -0.6, 0)
			a0.Parent = footPart

			local a1 = Instance.new("Attachment")
			a1.Name = "TrailAtt1"
			a1.Position = Vector3.new(0, -0.9, 0)
			a1.Parent = footPart

			local trail = Instance.new("Trail")
			trail.Name = "SamsaraTrail"
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = 0.4
			trail.MinLength = 0.1
			trail.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 235, 130)),
				ColorSequenceKeypoint.new(1.0, Color3.fromRGB(140, 210, 255)),
			})
			trail.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0.0, 0.15),
				NumberSequenceKeypoint.new(1.0, 1.0),
			})
			trail.Parent = footPart
		end
	end
end

-- Exported GetPlayerData function
function PlayerDataManager.GetPlayerData(player: Player): any
	return playerRawDataCache[player]
end

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

	print("[PlayerDataManager] Engine Initialized with Authoritative SpawnLocation Router, Bloodlines & Samsara Rebirth.")
end

function PlayerDataManager.OnPlayerAdded(player: Player)
	local dataKey = "Player_" .. player.UserId
	local loadedData: any = nil
	local isDev = IsDeveloper(player)
	local defaultEquipped = if isDev then "VoidStarCleaverDao" else STARTER_WEAPON

	local daisSpawn = GetPrimarySpawnLocation()
	if daisSpawn then
		player.RespawnLocation = daisSpawn
	end

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

	if not loadedData then
		pcall(function()
			local v2Store = DataStoreService:GetDataStore("ASCEND_PlayerData_V2")
			local oldResult = v2Store:GetAsync(dataKey)
			if oldResult and type(oldResult) == "table" then
				loadedData = oldResult
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
			EquippedWeapon = defaultEquipped,
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
			Bloodline = "MortalSwordBone",
			BloodlineSpins = 5,
			BloodlineSlots = { ["1"] = "MortalSwordBone" },
			MaxBloodlineSlots = 1,
			BloodlinePity = {
				SpinsSinceLegendary = 0,
				SpinsSinceMythic = 0,
			},
			SamsaraCycle = 0,
			LastStipendClaim = 0,
		}
	else
		if not loadedData.Version or loadedData.Version < CURRENT_VERSION then
			print(string.format("[PlayerDataManager] Migrating %s data to Version 3 schema.", player.Name))
			loadedData.Version = CURRENT_VERSION
		end

		local eq = tostring(loadedData.EquippedWeapon or "")
		if eq == "" or eq == "FlyingSword" or eq == "Celestial Thunder Sovereign Sword" or string.find(eq:lower(), "flyingsword") or (isDev and eq == "MortalIronJian") then
			loadedData.EquippedWeapon = defaultEquipped
			print(string.format("[PlayerDataManager] Sanitized equipped weapon for %s -> '%s'", player.Name, defaultEquipped))
		end
	end

	-- DEVELOPER AUTORECOVERY: Restore Han_jueee to Nascent Soul Order 5
	if player.Name == "Han_jueee" and (not loadedData.Cultivation or loadedData.Cultivation.Realm == "QiCondensation" or loadedData.Cultivation.Realm == nil) then
		loadedData.Cultivation = {
			Realm = "NascentSoul",
			Order = 5,
			CurrentQi = 180000,
			CultivatedQi = 180000,
		}
		print("[PlayerDataManager] Auto-restored developer Han_jueee to Nascent Soul (Order 5).")
	end

	isLoadedMap[player] = true
	playerRawDataCache[player] = loadedData

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

	-- Hydrate Meridian Storage Slots
	local activeBloodline = loadedData.Bloodline or "MortalSwordBone"
	local hydratedSlots: { [number]: string } = { [1] = activeBloodline }
	if loadedData.BloodlineSlots and type(loadedData.BloodlineSlots) == "table" then
		for slotKey, bloodlineId in pairs(loadedData.BloodlineSlots) do
			local slotNum = tonumber(slotKey)
			if slotNum and type(bloodlineId) == "string" then
				hydratedSlots[slotNum] = bloodlineId
			end
		end
	end

	local loadedPity = loadedData.BloodlinePity or {}
	local pityData = {
		SpinsSinceLegendary = loadedPity.SpinsSinceLegendary or 0,
		SpinsSinceMythic = loadedPity.SpinsSinceMythic or 0,
	}

	playerBloodlines[player] = {
		Current = activeBloodline,
		Spins = loadedData.BloodlineSpins or 5,
		Slots = hydratedSlots,
		MaxSlots = loadedData.MaxBloodlineSlots or 1,
		Pity = pityData,
	}

	playerSamsaraData[player] = loadedData.SamsaraCycle or 0

	local cData = loadedData.Cultivation or {}
	CultivationManager.SetPlayerData(
		player,
		cData.Realm or "QiCondensation",
		cData.CurrentQi or 200,
		cData.Order or 1,
		cData.CultivatedQi or 200
	)

	local normalizedInventory: { [number]: SavedInventorySlot } = {}

	if loadedData.Inventory and type(loadedData.Inventory) == "table" then
		for slotKey, slotData in pairs(loadedData.Inventory) do
			local slotNum = tonumber(slotKey)
			if slotNum and slotData and slotData.ItemId then
				if not isDev and LEGACY_TEST_SWORDS[slotData.ItemId] then
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

	if isDev then
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
	WeaponManager.EquipWeapon(player, loadedData.EquippedWeapon or defaultEquipped)

	local SectManager = getSectManager()
	if SectManager.SetQuestState then
		SectManager.SetQuestState(player, loadedData.QuestProgress)
	end
	if SectManager.SetLastStipendClaim then
		SectManager.SetLastStipendClaim(player, loadedData.LastStipendClaim)
	end

	-- Sync Attributes
	local currentRealmText = tostring(cData.Realm or "QiCondensation")
	player:SetAttribute("Sect", loadedData.Sect or "Azure Cloud Sect")
	player:SetAttribute("SectRank", playerEconomyData[player].SectRank)
	player:SetAttribute("SpiritStones", playerEconomyData[player].SpiritStones)
	player:SetAttribute("ContributionPoints", playerEconomyData[player].ContributionPoints)
	player:SetAttribute("EquippedHUDSkin", loadedData.EquippedSkin or "DefaultBronze")
	player:SetAttribute("Bloodline", playerBloodlines[player].Current)
	player:SetAttribute("BloodlineSpins", playerBloodlines[player].Spins)
	player:SetAttribute("MaxBloodlineSlots", playerBloodlines[player].MaxSlots)
	player:SetAttribute("LegendaryPity", playerBloodlines[player].Pity.SpinsSinceLegendary)
	player:SetAttribute("MythicPity", playerBloodlines[player].Pity.SpinsSinceMythic)
	player:SetAttribute("SamsaraCycle", playerSamsaraData[player])
	player:SetAttribute("LastStipendClaim", loadedData.LastStipendClaim or 0)
	player:SetAttribute("Realm", currentRealmText)

	if playerSamsaraData[player] > 0 then
		player:SetAttribute("SamsaraTitle", string.format("[Samsara %s]", ToRoman(playerSamsaraData[player])))
	end

	local function bindChar(character: Model)
		character:SetAttribute("Sect", loadedData.Sect or "Azure Cloud Sect")
		character:SetAttribute("SectRank", playerEconomyData[player].SectRank)
		character:SetAttribute("SpiritStones", playerEconomyData[player].SpiritStones)
		character:SetAttribute("ContributionPoints", playerEconomyData[player].ContributionPoints)
		character:SetAttribute("Bloodline", player:GetAttribute("Bloodline"))
		character:SetAttribute("Realm", currentRealmText)
		local cycle = playerSamsaraData[player] or 0
		character:SetAttribute("SamsaraCycle", cycle)
		if cycle > 0 then
			character:SetAttribute("SamsaraTitle", string.format("[Samsara %s]", ToRoman(cycle)))
			AttachSamsaraCelestialAura(character, cycle)
		end

		RouteToSpawnDais(character)

		task.defer(function()
			local targetWeapon = loadedData.EquippedWeapon or defaultEquipped
			if targetWeapon == "FlyingSword" or string.find(tostring(targetWeapon):lower(), "flyingsword") then
				targetWeapon = defaultEquipped
			end
			WeaponManager.EquipWeapon(player, targetWeapon, "Hand")
			AttachBloodlineVisual(character, (player:GetAttribute("Bloodline") :: string?) or "MortalSwordBone")
		end)
	end

	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	if player.Character then
		bindChar(player.Character)
	end
	characterConnections[player] = player.CharacterAdded:Connect(bindChar)

	-- Safe line 661 format string
	print(string.format("[PlayerDataManager] Successfully loaded data for %s (Realm: %s, Order: %d, Stones: %d, Rank: %s, Samsara: %d, Bloodline: %s, Slots: %d).",
		player.Name,
		currentRealmText,
		tonumber(cData.Order) or 1,
		loadedData.SpiritStones or 250,
		tostring(loadedData.SectRank or "OuterDisciple"),
		playerSamsaraData[player] or 0,
		tostring(playerBloodlines[player].Current or "MortalSwordBone"),
		playerBloodlines[player].MaxSlots or 1
	))
end

function PlayerDataManager.OnPlayerRemoving(player: Player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	PlayerDataManager.SaveData(player)

	task.delay(1.5, function()
		isLoadedMap[player] = nil
		playerRawDataCache[player] = nil
		playerAlchemyData[player] = nil
		playerEconomyData[player] = nil
		playerGamepasses[player] = nil
		playerSkinData[player] = nil
		playerBloodlines[player] = nil
		playerSamsaraData[player] = nil
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

function PlayerDataManager.GetBloodline(player: Player): string
	local data = playerBloodlines[player]
	if not data then
		local attr = player:GetAttribute("Bloodline")
		return if type(attr) == "string" then attr else "MortalSwordBone"
	end
	return data.Current
end

function PlayerDataManager.SetBloodline(player: Player, bloodlineId: string)
	local data = playerBloodlines[player]
	if not data then
		data = {
			Current = bloodlineId,
			Spins = PlayerDataManager.GetBloodlineSpins(player),
			Slots = { [1] = bloodlineId },
			MaxSlots = 1,
			Pity = { SpinsSinceLegendary = 0, SpinsSinceMythic = 0 },
		}
		playerBloodlines[player] = data
	else
		data.Current = bloodlineId
		data.Slots[1] = bloodlineId
	end
	player:SetAttribute("Bloodline", bloodlineId)
	if player.Character then
		player.Character:SetAttribute("Bloodline", bloodlineId)
		AttachBloodlineVisual(player.Character, bloodlineId)
	end
end

function PlayerDataManager.GetBloodlineSpins(player: Player): number
	local data = playerBloodlines[player]
	if not data then
		local attr = player:GetAttribute("BloodlineSpins")
		return if type(attr) == "number" then attr else 5
	end
	return data.Spins
end

function PlayerDataManager.AddBloodlineSpins(player: Player, amount: number): number
	local data = playerBloodlines[player]
	if not data then
		local current = PlayerDataManager.GetBloodlineSpins(player)
		local currentBloodline = PlayerDataManager.GetBloodline(player)
		data = {
			Current = currentBloodline,
			Spins = current,
			Slots = { [1] = currentBloodline },
			MaxSlots = 1,
			Pity = { SpinsSinceLegendary = 0, SpinsSinceMythic = 0 },
		}
		playerBloodlines[player] = data
	end
	data.Spins = math.max(0, data.Spins + amount)
	player:SetAttribute("BloodlineSpins", data.Spins)
	return data.Spins
end

function PlayerDataManager.GetBloodlineSlots(player: Player): { [number]: string }
	local data = playerBloodlines[player]
	if not data then return { [1] = PlayerDataManager.GetBloodline(player) } end
	return data.Slots
end

function PlayerDataManager.GetMaxBloodlineSlots(player: Player): number
	local data = playerBloodlines[player]
	return if data then data.MaxSlots else 2
end

function PlayerDataManager.SetMaxBloodlineSlots(player: Player, maxSlots: number)
	local data = playerBloodlines[player]
	if not data then return end
	data.MaxSlots = math.clamp(maxSlots, 1, 5)
	player:SetAttribute("MaxBloodlineSlots", data.MaxSlots)
end

function PlayerDataManager.SaveBloodlineToSlot(player: Player, slotIndex: number, bloodlineId: string): boolean
	local data = playerBloodlines[player]
	if not data then return false end
	if slotIndex < 1 or slotIndex > data.MaxSlots then return false end

	data.Slots[slotIndex] = bloodlineId
	if slotIndex == 1 then
		PlayerDataManager.SetBloodline(player, bloodlineId)
	end
	return true
end

function PlayerDataManager.EquipBloodlineFromSlot(player: Player, slotIndex: number): boolean
	local data = playerBloodlines[player]
	if not data then return false end
	local targetBloodline = data.Slots[slotIndex]
	if not targetBloodline then return false end

	data.Current = targetBloodline
	player:SetAttribute("Bloodline", targetBloodline)
	if player.Character then
		player.Character:SetAttribute("Bloodline", targetBloodline)
		AttachBloodlineVisual(player.Character, targetBloodline)
	end
	return true
end

function PlayerDataManager.GetBloodlinePity(player: Player): { SpinsSinceLegendary: number, SpinsSinceMythic: number }
	local data = playerBloodlines[player]
	if not data then return { SpinsSinceLegendary = 0, SpinsSinceMythic = 0 } end
	return data.Pity
end

function PlayerDataManager.IncrementBloodlinePity(player: Player): { SpinsSinceLegendary: number, SpinsSinceMythic: number }
	local data = playerBloodlines[player]
	if not data then
		data = {
			Current = PlayerDataManager.GetBloodline(player),
			Spins = PlayerDataManager.GetBloodlineSpins(player),
			Slots = { [1] = PlayerDataManager.GetBloodline(player) },
			MaxSlots = 1,
			Pity = { SpinsSinceLegendary = 0, SpinsSinceMythic = 0 },
		}
		playerBloodlines[player] = data
	end

	data.Pity.SpinsSinceLegendary += 1
	data.Pity.SpinsSinceMythic += 1

	player:SetAttribute("LegendaryPity", data.Pity.SpinsSinceLegendary)
	player:SetAttribute("MythicPity", data.Pity.SpinsSinceMythic)

	return data.Pity
end

function PlayerDataManager.ResetBloodlinePity(player: Player, tier: "Legendary" | "Mythic")
	local data = playerBloodlines[player]
	if not data then return end

	if tier == "Legendary" then
		data.Pity.SpinsSinceLegendary = 0
		player:SetAttribute("LegendaryPity", 0)
	elseif tier == "Mythic" then
		data.Pity.SpinsSinceLegendary = 0
		data.Pity.SpinsSinceMythic = 0
		player:SetAttribute("LegendaryPity", 0)
		player:SetAttribute("MythicPity", 0)
	end
end

function PlayerDataManager.RollBloodline(player: Player): (string?, boolean)
	local currentSpins = PlayerDataManager.GetBloodlineSpins(player)
	if currentSpins <= 0 then return nil, false end

	PlayerDataManager.AddBloodlineSpins(player, -1)
	PlayerDataManager.IncrementBloodlinePity(player)

	local rolledId = BloodlineConfig.RollBloodline()
	PlayerDataManager.SetBloodline(player, rolledId)

	local def = BloodlineConfig.GetBloodline(rolledId)
	if def then
		if def.Tier == "Mythic" then
			PlayerDataManager.ResetBloodlinePity(player, "Mythic")
		elseif def.Tier == "Legendary" then
			PlayerDataManager.ResetBloodlinePity(player, "Legendary")
		end

		if def.Tier == "Legendary" or def.Tier == "Mythic" then
			local remote = RemoteEvents.GetRemote("HeavenlyAnnouncement")
			if remote then
				remote:FireAllClients(string.format("[HEAVENLY FATE] Cultivator %s awakened the [%s] (%s Lineage)!", player.DisplayName, def.Name, def.Tier))
			end
		end
	end

	return rolledId, true
end

function PlayerDataManager.GetSamsaraCycle(player: Player): number
	local cached = playerSamsaraData[player]
	if cached ~= nil then return cached end
	local attr = player:GetAttribute("SamsaraCycle")
	return if type(attr) == "number" then attr else 0
end

function PlayerDataManager.SetSamsaraCycle(player: Player, cycle: number)
	playerSamsaraData[player] = cycle
	player:SetAttribute("SamsaraCycle", cycle)
	local title = string.format("[Samsara %s]", ToRoman(cycle))
	player:SetAttribute("SamsaraTitle", title)

	if player.Character then
		player.Character:SetAttribute("SamsaraCycle", cycle)
		player.Character:SetAttribute("SamsaraTitle", title)
		AttachSamsaraCelestialAura(player.Character, cycle)
	end
end

function PlayerDataManager.IncrementSamsara(player: Player): number
	local current = PlayerDataManager.GetSamsaraCycle(player)
	local newCycle = current + 1
	PlayerDataManager.SetSamsaraCycle(player, newCycle)
	return newCycle
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
	local bData = playerBloodlines[player] or {
		Current = "MortalSwordBone",
		Spins = 5,
		Slots = { [1] = "MortalSwordBone" },
		MaxSlots = 1,
		Pity = { SpinsSinceLegendary = 0, SpinsSinceMythic = 0 },
	}
	local samsaraCycle = playerSamsaraData[player] or 0

	local SectManager = getSectManager()
	local questProgress = SectManager.GetQuestState and SectManager.GetQuestState(player) or nil
	local lastStipendClaim = SectManager.GetLastStipendClaim and SectManager.GetLastStipendClaim(player) or nil

	if not cultivation then
		isSavingMap[player] = false
		return false
	end

	local defaultWep = if IsDeveloper(player) then "VoidStarCleaverDao" else STARTER_WEAPON
	if not equippedWeapon or equippedWeapon == "FlyingSword" or string.find(tostring(equippedWeapon):lower(), "flyingsword") then
		equippedWeapon = defaultWep
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

	local serializedSlots: { [string]: string } = {}
	for slotIdx, bloodlineId in pairs(bData.Slots or {}) do
		serializedSlots[tostring(slotIdx)] = bloodlineId
	end

	local dataToSave: SavedPlayerData = {
		Version = CURRENT_VERSION,
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
		QuestProgress = questProgress,
		LastStipendClaim = lastStipendClaim,
		Bloodline = bData.Current,
		BloodlineSpins = bData.Spins,
		BloodlineSlots = serializedSlots,
		MaxBloodlineSlots = bData.MaxSlots or 1,
		BloodlinePity = {
			SpinsSinceLegendary = bData.Pity and bData.Pity.SpinsSinceLegendary or 0,
			SpinsSinceMythic = bData.Pity and bData.Pity.SpinsSinceMythic or 0,
		},
		SamsaraCycle = samsaraCycle,
	}

	local dataKey = "Player_" .. player.UserId
	local saveSuccess = false

	for attempt = 1, MAX_RETRIES do
		local success, err = pcall(function()
			playerDataStore:SetAsync(dataKey, dataToSave)
		end)

		if success then
			saveSuccess = true
			print(string.format("[PlayerDataManager] Successfully saved data for %s (Equipped: %s, Samsara: %d, Lineage: %s).", player.Name, equippedWeapon, samsaraCycle, bData.Current))
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