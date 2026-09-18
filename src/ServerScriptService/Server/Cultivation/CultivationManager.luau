--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND:
    - Synchronous zero-delay CharacterAdded stat binding
    - Dynamic Bloodline Tier Aura Lifecycle during Meditation (Tier 1 to 4 from AuraTemplates)
    - 12-Lineage Custom Multi-Keypoint ColorSequence Gradient & Light Harmonization
    - Calibrated 10-Realm passive Qi loop: expansionRate = realmInfo.GatherRate * qiNodeMult * sectMult * samsaraRefineMult
    - +30% Qi refining/meditation speed boost per Samsara cycle (Phase 5)
    - Breakthrough Dan consumption requirement
    - Inner Demon Tribulation QTE Engine with non-lethal Qi Deviation Backlash
    - Ultimate Pinnacle Samsara Rebirth Gate & Loop (Immortal Ascension Order 9 -> Qi Condensation Order 1)
    - Phase 1: Synchronous lazy session cache fallback inside GetPlayerData to eliminate race condition
    - Phase 2: CharacterAdded connection lifecycle tracking and locomotion speed normalization
    - Phase 4: Dynamic Realm-Scaled Airborne Flight Qi Drain & Zero-Qi Auto-Dismount
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerCultivationData = {
	Realm: CultivationConfig.RealmTier,
	Order: number,
	CurrentQi: number,
	CultivatedQi: number,
	MaxQiGoal: number,
	IsMeditating: boolean,
	IsTribulationActive: boolean,
	TribulationWave: number,
	TotalWaves: number,
}

local REALM_BREAKTHROUGH_DAN: { [CultivationConfig.RealmTier]: { ItemId: string, DisplayName: string } } = {
	FoundationEstablishment = { ItemId = "FoundationGatheringDan", DisplayName = "Foundation Gathering Dan" },
	GoldenCore = { ItemId = "GoldenCoreDan", DisplayName = "Golden Core Dan" },
	NascentSoul = { ItemId = "NascentSoulDan", DisplayName = "Nascent Soul Dan" },
	SpiritSevering = { ItemId = "SpiritSeveringDan", DisplayName = "Spirit Severing Dan" },
	VoidRefining = { ItemId = "VoidRefiningDan", DisplayName = "Void Refining Dan" },
	BodyIntegration = { ItemId = "BodyIntegrationDan", DisplayName = "Body Integration Dan" },
	Mahayana = { ItemId = "MahayanaDan", DisplayName = "Mahayana Dan" },
	TribulationTranscending = { ItemId = "TribulationTranscendingDan", DisplayName = "Tribulation Transcending Dan" },
	ImmortalAscension = { ItemId = "ImmortalAscensionDan", DisplayName = "Immortal Ascension Dan" },
}

-- =============================================================================
-- 12 UNIQUE BLOODLINE AURA PALETTES (Multi-Keypoint ColorSequence & Light Tints)
-- =============================================================================
type AuraPalette = {
	Gradient: ColorSequence,
	LightColor: Color3,
}

local BLOODLINE_AURA_PALETTES: { [string]: AuraPalette } = {
	-- Tier 1 Common
	["MortalSwordBone"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(210, 225, 240)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 205, 225)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(140, 175, 200)),
		}),
		LightColor = Color3.fromRGB(190, 210, 225),
	},
	["IronMeridianRoot"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 145, 95)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 110, 60)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 65, 30)),
		}),
		LightColor = Color3.fromRGB(180, 115, 65),
	},
	["BreezeSpiritVein"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(170, 250, 215)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 230, 195)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(90, 200, 170)),
		}),
		LightColor = Color3.fromRGB(150, 235, 200),
	},

	-- Tier 2 Rare
	["AzureDragonMeridian"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(60, 230, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(34, 211, 238)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(245, 190, 40)),
		}),
		LightColor = Color3.fromRGB(34, 211, 238),
	},
	["VerdantLifeCore"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(110, 245, 175)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(52, 211, 153)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(20, 150, 95)),
		}),
		LightColor = Color3.fromRGB(52, 211, 153),
	},
	["ThunderSoulVessel"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 140, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(192, 132, 252)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(130, 60, 230)),
		}),
		LightColor = Color3.fromRGB(192, 132, 252),
	},

	-- Tier 3 Legendary
	["AsuraSlaughterBloodline"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 70, 90)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(220, 20, 60)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(110, 10, 25)),
		}),
		LightColor = Color3.fromRGB(220, 20, 60),
	},
	["EightBladeCelestialHalo"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 250, 210)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 204, 21)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 135, 10)),
		}),
		LightColor = Color3.fromRGB(250, 204, 21),
	},
	["HeavenlySwordBody"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 250, 210)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(250, 204, 21)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(200, 135, 10)),
		}),
		LightColor = Color3.fromRGB(250, 204, 21),
	},
	["GlacialPhoenixMeridian"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(215, 245, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 230, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(50, 135, 255)),
		}),
		LightColor = Color3.fromRGB(160, 230, 255),
	},
	["VoidSpiritRoot"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(200, 120, 255)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(147, 51, 234)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(55, 15, 125)),
		}),
		LightColor = Color3.fromRGB(147, 51, 234),
	},

	-- Tier 4 Mythic
	["ChaosPrimordialDaoBody"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 230)),
			ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 235, 120)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(235, 160, 30)),
		}),
		LightColor = Color3.fromRGB(255, 235, 120),
	},
	["NineNetherSovereign"] = {
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(110, 255, 230)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 220, 190)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(10, 85, 75)),
		}),
		LightColor = Color3.fromRGB(30, 220, 190),
	},
}

local TIER_TEMPLATE_MAP: { [BloodlineConfig.BloodlineTier]: string } = {
	Common = "Tier1_Common",
	Rare = "Tier2_Rare",
	Legendary = "Tier3_Legendary",
	Mythic = "Tier4_Mythic",
}

local CultivationManager = {}
local playerData: { [Player]: PlayerCultivationData } = {}
local characterConnections: { [Player]: RBXScriptConnection } = {}
local activeTribulationSessions: { [Player]: { CurrentWave: number, PulseReceived: boolean, PulseDeadline: number } } = {}
local passiveQiLoopThread: thread? = nil
local tribulationThreads: { [Player]: thread } = {}
local lastToggleTimestamp: { [Player]: number } = {}

local updateCultivationRemote: RemoteEvent? = nil
local combatActionRemote: RemoteEvent? = nil
local cultivationActionRemote: RemoteEvent? = nil
local heavenlyAnnouncementRemote: RemoteEvent? = nil
local weaponManagerRef: any = nil
local playerDataManagerRef: any = nil
local inventoryManagerRef: any = nil

local function getUpdateCultivationRemote(): RemoteEvent?
	if not updateCultivationRemote then
		updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	end
	return updateCultivationRemote
end

local function getCombatActionRemote(): RemoteEvent?
	if not combatActionRemote then
		combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	end
	return combatActionRemote
end

local function getCultivationActionRemote(): RemoteEvent?
	if not cultivationActionRemote then
		cultivationActionRemote = RemoteEvents.GetRemote("CultivationAction")
	end
	return cultivationActionRemote
end

local function getHeavenlyAnnouncementRemote(): RemoteEvent?
	if not heavenlyAnnouncementRemote then
		heavenlyAnnouncementRemote = RemoteEvents.GetRemote("HeavenlyAnnouncement")
	end
	return heavenlyAnnouncementRemote
end

local function getWeaponManager(): any
	if not weaponManagerRef then
		weaponManagerRef = require(ServerScriptService.Server.Combat.WeaponManager)
	end
	return weaponManagerRef
end

local function getPlayerDataManager(): any
	if not playerDataManagerRef then
		playerDataManagerRef = require(ServerScriptService.Server.State.PlayerDataManager)
	end
	return playerDataManagerRef
end

local function getInventoryManager(): any
	if not inventoryManagerRef then
		inventoryManagerRef = require(ServerScriptService.Server.State.InventoryManager)
	end
	return inventoryManagerRef
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

local function GetSectQiBuffMultiplier(player: Player): number
	local pdm = getPlayerDataManager()
	if not pdm or not pdm.GetSectRank then return 1.0 end
	local rank = pdm.GetSectRank(player) or "OuterDisciple"
	local rankDef = SectConfig.GetRank(rank)
	return if rankDef and rankDef.QiBuffMultiplier then rankDef.QiBuffMultiplier else 1.0
end

local function GetSamsaraRefineMultiplier(player: Player): number
	local pdm = getPlayerDataManager()
	local cycle = if pdm and pdm.GetSamsaraCycle then pdm.GetSamsaraCycle(player) else (player:GetAttribute("SamsaraCycle") or 0)
	return 1.0 + (cycle * 0.30)
end

local function BroadcastHeavenlyAnnouncement(message: string)
	local announcementRemote = getHeavenlyAnnouncementRemote()
	if announcementRemote then
		announcementRemote:FireAllClients(message)
	end

	local combatRemote = getCombatActionRemote()
	if combatRemote then
		combatRemote:FireAllClients(nil, "ServerAnnouncement", {
			Message = message,
			Color = Color3.fromRGB(255, 215, 0),
		})
	end
end

local function GetQiNodeMultiplier(character: Model): number
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 1.0 end

	local qiNodesFolder = Workspace:FindFirstChild("QiNodes")
	if not qiNodesFolder then return 1.0 end

	for _, nodePart in ipairs(qiNodesFolder:GetChildren()) do
		if nodePart:IsA("BasePart") then
			local distance = (hrp.Position - nodePart.Position).Magnitude
			local maxRadius = math.max(nodePart.Size.X, nodePart.Size.Z) / 2 + 3
			if distance <= maxRadius then
				local customMultiplier = nodePart:GetAttribute("QiMultiplier")
				if type(customMultiplier) == "number" and customMultiplier > 0 then
					return customMultiplier
				end
				return 5.0
			end
		end
	end

	return 1.0
end

function CultivationManager.Init()
	local updateRemote = getUpdateCultivationRemote()
	local combatRemote = getCombatActionRemote()
	local actionRemote = getCultivationActionRemote()
	local announcementRemote = getHeavenlyAnnouncementRemote()

	Players.PlayerAdded:Connect(CultivationManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CultivationManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		CultivationManager.OnPlayerAdded(player)
	end

	if combatRemote then
		combatRemote.OnServerEvent:Connect(function(player: Player, payload: any)
			if type(payload) == "table" then
				if payload.ToggleMeditation then
					CultivationManager.ToggleMeditation(player)
				elseif payload.RequestBreakthrough or payload.RequestSamsara then
					CultivationManager.AttemptBreakthrough(player)
				end
			end
		end)
	end

	if actionRemote then
		actionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
			if type(payload) ~= "table" then return end
			if payload.Action == "FocusPulse" and type(payload.Wave) == "number" then
				local session = activeTribulationSessions[player]
				if session and session.CurrentWave == payload.Wave and os.clock() <= session.PulseDeadline then
					session.PulseReceived = true
				end
			elseif payload.Action == "RequestSamsara" then
				CultivationManager.AttemptBreakthrough(player)
			end
		end)
	end

	-- Master Passive Qi Loop
	passiveQiLoopThread = task.spawn(function()
		while true do
			task.wait(0.5)
			for player, pData in pairs(playerData) do
				if player.Parent and pData and not pData.IsTribulationActive then
					local character = player.Character
					if character and character.Parent then
						local isMeditating = pData.IsMeditating
						local isFlying = (character:GetAttribute("IsFlying") == true)

						if isFlying then
							local flightCfg = FlyingSwordConfig.Flight
							local realmFlight = if flightCfg and flightCfg.Realms then flightCfg.Realms[pData.Realm] else nil
							local drainPercent = if realmFlight then realmFlight.QiDrainPercent else 0.01
							local flatDrain = if realmFlight then realmFlight.FlatDrain else 10
							local drainPerSec = (pData.CultivatedQi * drainPercent) + flatDrain
							local drainThisTick = drainPerSec * 0.5

							pData.CurrentQi = math.max(0, pData.CurrentQi - drainThisTick)

							if pData.CurrentQi <= 0 then
								local weaponMgr = getWeaponManager()
								if weaponMgr and weaponMgr.ToggleFlight then
									weaponMgr.ToggleFlight(player)
								end
							end

							CultivationManager.SyncClient(player)
						else
							local sectMult = GetSectQiBuffMultiplier(player)
							local samsaraRefineMult = GetSamsaraRefineMultiplier(player)
							local recoveryRate = if isMeditating then ((pData.CultivatedQi / 10.0) * sectMult * samsaraRefineMult) else (pData.CultivatedQi / 60.0)

							if pData.CurrentQi < pData.CultivatedQi then
								local qiGained = recoveryRate * 0.5
								pData.CurrentQi = math.min(pData.CultivatedQi, pData.CurrentQi + qiGained)
							end

							if isMeditating and pData.CultivatedQi < pData.MaxQiGoal then
								local realmInfo = CultivationConfig[pData.Realm]
								local baseGather = if realmInfo and realmInfo.GatherRate then realmInfo.GatherRate else 20
								local qiNodeMult = GetQiNodeMultiplier(character)
								local expansionRate = baseGather * qiNodeMult * sectMult * samsaraRefineMult
								pData.CultivatedQi = math.min(pData.MaxQiGoal, pData.CultivatedQi + (expansionRate * 0.5))
							end

							pData.CultivatedQi = math.clamp(pData.CultivatedQi, 0, pData.MaxQiGoal)
							pData.CurrentQi = math.clamp(pData.CurrentQi, 0, pData.CultivatedQi)

							CultivationManager.SyncClient(player)
						end
					end
				end
			end
		end
	end)

	print("[ASCEND] CultivationManager Initialized with Bloodline Tier Aura Engine.")
end

function CultivationManager.OnPlayerAdded(player: Player)
	if not playerData[player] then
		local startTarget = CultivationConfig.GetOrderTargetQi("QiCondensation", 1)
		local startCap = CultivationConfig.GetOrderStartingMaxQi("QiCondensation", 1)
		playerData[player] = {
			Realm = "QiCondensation",
			Order = 1,
			CurrentQi = startCap,
			CultivatedQi = startCap,
			MaxQiGoal = startTarget,
			IsMeditating = false,
			IsTribulationActive = false,
			TribulationWave = 0,
			TotalWaves = 0,
		}
	end

	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end

	characterConnections[player] = player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			local pData = CultivationManager.GetPlayerData(player)
			if pData then
				local maxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
				humanoid.MaxHealth = maxHp
				humanoid.Health = maxHp
				character:SetAttribute("MaxHealth", maxHp)
				character:SetAttribute("Health", maxHp)
				character:SetAttribute("IsMeditating", pData.IsMeditating)
			end
		end
		CultivationManager.ApplyRealmStats(player)
	end)
end

function CultivationManager.OnPlayerRemoving(player: Player)
	if characterConnections[player] then
		characterConnections[player]:Disconnect()
		characterConnections[player] = nil
	end
	if tribulationThreads[player] then
		task.cancel(tribulationThreads[player])
		tribulationThreads[player] = nil
	end
	activeTribulationSessions[player] = nil
	lastToggleTimestamp[player] = nil
	playerData[player] = nil
end

function CultivationManager.GetPlayerData(player: Player): PlayerCultivationData?
	local data = playerData[player]
	if not data and player.Parent then
		local rawRealm = player:GetAttribute("Realm")
		local cleanRealm = if type(rawRealm) == "string" then rawRealm:gsub("%s*[-–].*", ""):gsub("%s+", "") else "QiCondensation"
		local realmKey: any = if CultivationConfig[cleanRealm] then cleanRealm else "QiCondensation"
		local order = (player:GetAttribute("Order") :: number?) or 1
		local curQi = (player:GetAttribute("Qi") :: number?) or 200
		local cultQi = (player:GetAttribute("CultivatedQi") :: number?) or (player:GetAttribute("MaxQi") :: number?) or curQi
		CultivationManager.SetPlayerData(player, realmKey, curQi, order, cultQi)
		data = playerData[player]
	end
	return data
end

function CultivationManager.AddInternalQi(player: Player, amount: number)
	local pData = CultivationManager.GetPlayerData(player)
	if not pData then return end

	local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
	pData.CultivatedQi = math.clamp(pData.CultivatedQi + amount, 0, maxQiGoal)
	pData.CurrentQi = math.clamp(pData.CurrentQi + amount, 0, pData.CultivatedQi)

	CultivationManager.SyncClient(player)
end

function CultivationManager.AddCultivatedQi(player: Player, amount: number)
	CultivationManager.AddInternalQi(player, amount)
end

function CultivationManager.SetPlayerData(player: Player, realm: CultivationConfig.RealmTier, currentQi: number, order: number?, cultivatedQi: number?)
	local orderNum = math.clamp(order or 1, 1, 9)
	local targetGoal = CultivationConfig.GetOrderTargetQi(realm, orderNum)
	local startingQi = CultivationConfig.GetOrderStartingMaxQi(realm, orderNum)
	local savedCultivated = cultivatedQi or startingQi
	local cultivatedCap = math.clamp(savedCultivated, startingQi, targetGoal)
	local activeEnergy = math.clamp(currentQi or cultivatedCap, 0, cultivatedCap)

	playerData[player] = {
		Realm = realm or "QiCondensation",
		Order = orderNum,
		CurrentQi = activeEnergy,
		CultivatedQi = cultivatedCap,
		MaxQiGoal = targetGoal,
		IsMeditating = false,
		IsTribulationActive = false,
		TribulationWave = 0,
		TotalWaves = 0,
	}

	if player.Character then
		CultivationManager.ApplyRealmStats(player)
	end
end

function CultivationManager.ApplyRealmStats(player: Player)
	local pData = CultivationManager.GetPlayerData(player)
	if not pData then return end

	local character = player.Character
	if not character then return end

	local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
	local startingQi = CultivationConfig.GetOrderStartingMaxQi(pData.Realm, pData.Order)
	pData.MaxQiGoal = maxQiGoal

	pData.CultivatedQi = math.clamp(pData.CultivatedQi or startingQi, startingQi, maxQiGoal)
	pData.CurrentQi = math.clamp(pData.CurrentQi or pData.CultivatedQi, 0, pData.CultivatedQi)

	local maxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = maxHp
		humanoid.Health = math.clamp(humanoid.Health, 1, maxHp)
	end

	local realmInfo = CultivationConfig[pData.Realm]
	local realmText = if realmInfo then string.format("%s - Order %d", realmInfo.Name, pData.Order) else "Qi Condensation - Order 1"

	character:SetAttribute("MaxHealth", maxHp)
	character:SetAttribute("Health", if humanoid then humanoid.Health else maxHp)
	character:SetAttribute("Realm", realmText)
	character:SetAttribute("IsMeditating", pData.IsMeditating)
	player:SetAttribute("Realm", realmText)
	player:SetAttribute("Order", pData.Order)
	character:SetAttribute("AlchemyRank", character:GetAttribute("AlchemyRank") or "Mortal Alchemist - Rank 1")

	CultivationManager.SyncClient(player)
end

function CultivationManager.ConsumeQi(player: Player, amount: number): boolean
	local pData = CultivationManager.GetPlayerData(player)
	if not pData then return false end

	if pData.CurrentQi < amount then
		return false
	end

	pData.CurrentQi = math.max(0, pData.CurrentQi - amount)
	CultivationManager.SyncClient(player)
	return true
end

function CultivationManager.ToggleMeditation(player: Player)
	local pData = CultivationManager.GetPlayerData(player)
	if not pData or pData.IsTribulationActive then return end

	local character = player.Character
	if not character then return end

	if character:GetAttribute("IsFlying") == true then
		return
	end

	local now = os.clock()
	local lastTime = lastToggleTimestamp[player] or 0
	if now - lastTime < 0.8 then return end
	lastToggleTimestamp[player] = now

	pData.IsMeditating = not pData.IsMeditating
	local weaponMgr = getWeaponManager()

	if pData.IsMeditating then
		if weaponMgr and weaponMgr.SetWeaponState then
			weaponMgr.SetWeaponState(player, "Back", true)
		end
		CultivationManager.StartGroundedMeditation(player, character, pData.Realm, false)
	else
		if weaponMgr and weaponMgr.SetWeaponState then
			weaponMgr.SetWeaponState(player, "Back", true)
		end
		CultivationManager.StopGroundedMeditation(player, character)
	end

	character:SetAttribute("IsMeditating", pData.IsMeditating)
	CultivationManager.SyncClient(player)
end

-- =============================================================================
-- PHASE 5.2: DYNAMIC BLOODLINE TIER AURA & PALETTE WELDER
-- =============================================================================
function CultivationManager.StartGroundedMeditation(player: Player, character: Model, realm: CultivationConfig.RealmTier, isBreakthrough: boolean)
	CultivationManager.StopGroundedMeditation(player, character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	-- 1. Resolve Active Bloodline, Tier Template & Custom Palette
	local pdm = getPlayerDataManager()
	local bloodlineId = if pdm and pdm.GetBloodline then pdm.GetBloodline(player) else (player:GetAttribute("Bloodline") or "MortalSwordBone")
	local bloodlineDef = BloodlineConfig.GetBloodline(bloodlineId)
	local tier: BloodlineConfig.BloodlineTier = if bloodlineDef then bloodlineDef.Tier else "Common"
	local templateName = TIER_TEMPLATE_MAP[tier] or "Tier1_Common"

	local palette = BLOODLINE_AURA_PALETTES[bloodlineId]
	if not palette then
		local fallbackColor = if bloodlineDef and bloodlineDef.VisualArtifact then bloodlineDef.VisualArtifact.AuraColor else Color3.fromRGB(0, 220, 255)
		palette = {
			Gradient = ColorSequence.new(fallbackColor),
			LightColor = fallbackColor,
		}
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	character:SetAttribute("IsMeditating", true)

	-- 2. Clean Spirit Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = palette.LightColor
	highlight.FillTransparency = if isBreakthrough then 0.82 else 0.90
	highlight.OutlineColor = palette.LightColor
	highlight.OutlineTransparency = 0.25
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	-- 3. Raycast Leg Ground Adjustment
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), raycastParams)
	local groundY = if rayResult then rayResult.Position.Y else (hrp.Position.Y - 3.0)
	hrp.CFrame = CFrame.new(hrp.Position.X, groundY + 4.8, hrp.Position.Z) * hrp.CFrame.Rotation

	-- 4. Locate Modular Aura Template Folder
	local auraFolder = ReplicatedStorage:FindFirstChild("AuraTemplates") 
		or Workspace:FindFirstChild("AuraTemplates")
	local tierTemplate = auraFolder and auraFolder:FindFirstChild(templateName) :: Folder?

	if tierTemplate then
		local clonedAttachments: { [string]: Attachment } = {}

		-- Pass 1: Clone all attachments to HumanoidRootPart
		for _, child in ipairs(tierTemplate:GetChildren()) do
			if child:IsA("Attachment") then
				local attClone = child:Clone()
				attClone.Name = "Aura_" .. child.Name
				attClone.Parent = hrp
				clonedAttachments[child.Name] = attClone

				-- Smart-Tint: Preserves high-contrast white centers and deep shadow waves
				for _, desc in ipairs(attClone:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then
						local origEmission = desc:GetAttribute("OriginalEmission") or desc.LightEmission
						if origEmission == 0 then
							-- Deep shadow / dark wave: blend dark accent of bloodline
							desc.Color = ColorSequence.new(Color3.fromRGB(20, 20, 30))
						elseif desc.Name == "Eye" then
							-- Spirit Eye core: keep bright sacred white
							desc.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
						else
							-- Main energy: apply the custom Bloodline palette
							desc.Color = palette.Gradient
						end
						desc.Enabled = true
					elseif desc:IsA("PointLight") then
						desc.Color = palette.LightColor
						desc.Enabled = true
					end
				end
			end
		end

		-- Pass 2: Rewire Beams (e.g. Tier 4 Skyward Vortex)
		local pillarBottomClone = clonedAttachments["PillarBottom"]
		local pillarTopClone = clonedAttachments["PillarTop"]
		if pillarBottomClone and pillarTopClone then
			for _, desc in ipairs(pillarBottomClone:GetDescendants()) do
				if desc:IsA("Beam") then
					desc.Attachment0 = pillarBottomClone
					desc.Attachment1 = pillarTopClone
					desc.Color = palette.Gradient
					desc.Enabled = true
				end
			end
		end
	end

	hrp.Anchored = true
end

function CultivationManager.StopGroundedMeditation(player: Player, character: Model)
	-- 1. Destroy Character Highlights
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "QiMeditationHighlight" or child.Name == "QiMeditationAura" then
			child:Destroy()
		end
	end

	-- 2. Destroy Cloned Aura Attachments on HumanoidRootPart
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		for _, child in ipairs(hrp:GetChildren()) do
			if child:IsA("Attachment") and (child.Name:match("^Aura_") or child.Name:match("^RootAttachment") or child.Name:match("^GroundAttachment")) then
				child:Destroy()
			end
		end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterDescendantsInstances = { character }
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), raycastParams)

		if rayResult then
			local groundY = rayResult.Position.Y
			hrp.CFrame = CFrame.new(hrp.Position.X, groundY + 3.0, hrp.Position.Z) * hrp.CFrame.Rotation
		end

		hrp.Anchored = false
	end

	character:SetAttribute("IsMeditating", false)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local inArena = character:GetAttribute("InArena") == true
		humanoid.WalkSpeed = if inArena then 16.0 else 13.5
		humanoid.JumpPower = 50.0
		humanoid.AutoRotate = true
	end
end

function CultivationManager.TriggerSamsaraRebirth(player: Player): boolean
	local pData = CultivationManager.GetPlayerData(player)
	if not pData then return false end

	local updateRemote = getUpdateCultivationRemote()

	if pData.Realm ~= "ImmortalAscension" or pData.Order < 9 then
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughRejected",
				Message = "Samsara Rebirth requires reaching the ultimate pinnacle: Immortal Ascension (Order 9)!",
				CurrentQi = pData.CultivatedQi,
				TargetQi = pData.MaxQiGoal,
				Percentage = math.floor((pData.CultivatedQi / math.max(1, pData.MaxQiGoal)) * 100),
			})
		end
		return false
	end

	if pData.CultivatedQi < pData.MaxQiGoal then
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughRejected",
				Message = "Your Dantian must be 100% saturated with Immortal Qi to initiate Samsara Rebirth!",
				CurrentQi = pData.CultivatedQi,
				TargetQi = pData.MaxQiGoal,
				Percentage = math.floor((pData.CultivatedQi / math.max(1, pData.MaxQiGoal)) * 100),
			})
		end
		return false
	end

	local character = player.Character
	if character then
		CultivationManager.StopGroundedMeditation(player, character)
	end

	local pdm = getPlayerDataManager()
	local newCycle = if pdm and pdm.IncrementSamsara then pdm.IncrementSamsara(player) else 1
	local roman = ToRoman(newCycle)
	local fullTitle = string.format("[Samsara %s]", roman)

	CultivationManager.SetPlayerData(player, "QiCondensation", 200, 1, 200)

	if character then
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if root then
			local pillar = Instance.new("Part")
			pillar.Name = "CelestialLightPillar"
			pillar.Anchored = true
			pillar.CanCollide = false
			pillar.CanTouch = false
			pillar.CanQuery = false
			pillar.Material = Enum.Material.Neon
			pillar.Color = Color3.fromRGB(255, 230, 140)
			pillar.Transparency = 0.25
			pillar.Size = Vector3.new(8, 350, 8)
			pillar.CFrame = root.CFrame * CFrame.new(0, 175, 0)
			pillar.Parent = Workspace

			task.spawn(function()
				for _ = 1, 25 do
					pillar.Transparency += 0.03
					pillar.Size = pillar.Size + Vector3.new(0.4, 0, 0.4)
					task.wait(0.04)
				end
				pillar:Destroy()
			end)
		end
	end

	if updateRemote then
		updateRemote:FireClient(player, {
			Action = "BreakthroughSuccess",
			IsMajor = true,
			Realm = "QiCondensation",
			RealmName = string.format("SAMSARA REBIRTH %s", roman),
			Order = 1,
			HpGain = 0,
			QiGain = 0,
			PowerMultiplier = 1.0,
		})
	end

	local combatRemote = getCombatActionRemote()
	if combatRemote then
		combatRemote:FireAllClients(player, "AscensionBurst", {
			AuraColor = Color3.fromRGB(255, 220, 120),
		})
	end

	BroadcastHeavenlyAnnouncement(string.format(
		"[HEAVENLY SAMSARA] Cultivator %s reached the Ultimate Pinnacle and underwent Samsara Rebirth %s! Returning from the Immortal Void into the Mortal Realm.",
		player.DisplayName,
		fullTitle
	))

	return true
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = CultivationManager.GetPlayerData(player)
	if not pData or pData.IsTribulationActive then return false end

	local updateRemote = getUpdateCultivationRemote()

	if pData.CultivatedQi < pData.MaxQiGoal then
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughRejected",
				Message = "Keep cultivating! Your Qi isn't ready for breakthrough yet.",
				CurrentQi = pData.CultivatedQi,
				TargetQi = pData.MaxQiGoal,
				Percentage = math.floor((pData.CultivatedQi / math.max(1, pData.MaxQiGoal)) * 100),
			})
		end
		return false
	end

	if pData.Order < 9 then
		local oldMaxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
		local oldMaxQi = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)

		pData.Order += 1
		local startingQi = CultivationConfig.GetOrderStartingMaxQi(pData.Realm, pData.Order)
		pData.CultivatedQi = startingQi
		pData.CurrentQi = startingQi

		CultivationManager.ApplyRealmStats(player)
		CultivationManager.SyncClient(player)

		local newMaxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
		local newMaxQi = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
		local powerMult = CultivationConfig.GetPowerMultiplier(pData.Realm, pData.Order)

		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughSuccess",
				IsMajor = false,
				Realm = pData.Realm,
				RealmName = CultivationConfig[pData.Realm].Name,
				Order = pData.Order,
				HpGain = math.max(0, newMaxHp - oldMaxHp),
				QiGain = math.max(0, newMaxQi - oldMaxQi),
				PowerMultiplier = powerMult,
			})
		end
		return true
	end

	if pData.Realm == "ImmortalAscension" and pData.Order == 9 then
		return CultivationManager.TriggerSamsaraRebirth(player)
	end

	local nextRealmMap: { [CultivationConfig.RealmTier]: CultivationConfig.RealmTier } = {
		QiCondensation = "FoundationEstablishment",
		FoundationEstablishment = "GoldenCore",
		GoldenCore = "NascentSoul",
		NascentSoul = "SpiritSevering",
		SpiritSevering = "VoidRefining",
		VoidRefining = "BodyIntegration",
		BodyIntegration = "Mahayana",
		Mahayana = "TribulationTranscending",
		TribulationTranscending = "ImmortalAscension",
	}

	local nextRealm = nextRealmMap[pData.Realm]
	if not nextRealm then return false end

	local requiredDan = REALM_BREAKTHROUGH_DAN[nextRealm]
	local invMgr = getInventoryManager()
	if requiredDan and invMgr then
		if not invMgr.HasItem(player, requiredDan.ItemId, 1) then
			if updateRemote then
				updateRemote:FireClient(player, {
					Action = "BreakthroughRejected",
					Message = string.format("Breakthrough Blocked: Consuming a %s is required to stabilize your meridians!", requiredDan.DisplayName),
					CurrentQi = pData.CultivatedQi,
					TargetQi = pData.MaxQiGoal,
					Percentage = 100,
				})
			end
			return false
		end
		invMgr.RemoveItem(player, requiredDan.ItemId, 1)
	end

	local oldMaxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
	local oldMaxQi = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
	local tribulationSpec = CultivationConfig[pData.Realm].Tribulation

	if tribulationSpec.StrikeCount <= 0 then
		pData.Realm = nextRealm
		pData.Order = 1
		local startingQi = CultivationConfig.GetOrderStartingMaxQi(nextRealm, 1)
		pData.CultivatedQi = startingQi
		pData.CurrentQi = startingQi

		CultivationManager.ApplyRealmStats(player)
		CultivationManager.SyncClient(player)

		local newMaxHp = CultivationConfig.GetOrderMaxHealth(nextRealm, 1)
		local newMaxQi = CultivationConfig.GetOrderTargetQi(nextRealm, 1)
		local powerMult = CultivationConfig.GetPowerMultiplier(nextRealm, 1)
		local realmName = CultivationConfig[nextRealm].Name

		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughSuccess",
				IsMajor = true,
				Realm = nextRealm,
				RealmName = realmName,
				Order = 1,
				HpGain = math.max(0, newMaxHp - oldMaxHp),
				QiGain = math.max(0, newMaxQi - oldMaxQi),
				PowerMultiplier = powerMult,
			})
		end

		BroadcastHeavenlyAnnouncement(string.format("[HEAVENLY DAO] Cultivator %s (@%s) has ascended to %s!", player.DisplayName, player.Name, realmName))
		return true
	end

	pData.IsTribulationActive = true
	pData.TotalWaves = tribulationSpec.StrikeCount
	pData.TribulationWave = 0

	local character = player.Character
	if not character then
		pData.IsTribulationActive = false
		return false
	end

	CultivationManager.StartGroundedMeditation(player, character, pData.Realm, true)
	CultivationManager.SyncClient(player)

	local actionRemote = getCultivationActionRemote()
	if actionRemote then
		actionRemote:FireClient(player, {
			Action = "InnerDemonStart",
			AuraColor = tribulationSpec.AuraColor,
			TotalWaves = tribulationSpec.StrikeCount,
		})
	end

	tribulationThreads[player] = task.spawn(function()
		for wave = 1, tribulationSpec.StrikeCount do
			if not player.Parent or not character.Parent then break end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid or humanoid.Health <= 0 then break end

			pData.TribulationWave = wave
			CultivationManager.SyncClient(player)

			local focusWindow = math.clamp(tribulationSpec.TelegraphTime or 1.2, 0.9, 1.6)
			local deadline = os.clock() + focusWindow
			activeTribulationSessions[player] = {
				CurrentWave = wave,
				PulseReceived = false,
				PulseDeadline = deadline,
			}

			if actionRemote then
				actionRemote:FireClient(player, {
					Action = "FocusPulsePrompt",
					Wave = wave,
					TotalWaves = tribulationSpec.StrikeCount,
					Window = focusWindow,
					AuraColor = tribulationSpec.AuraColor,
				})
			end

			local startTime = os.clock()
			while (os.clock() - startTime) < focusWindow do
				if activeTribulationSessions[player] and activeTribulationSessions[player].PulseReceived then
					break
				end
				task.wait(0.05)
			end

			local session = activeTribulationSessions[player]
			local pulseSucceeded = session and session.PulseReceived == true

			if not pulseSucceeded then
				activeTribulationSessions[player] = nil
				pData.IsTribulationActive = false
				pData.TribulationWave = 0
				CultivationManager.StopGroundedMeditation(player, character)

				humanoid.Health = 1
				character:SetAttribute("Health", 1)
				character:SetAttribute("QiDeviation", true)
				humanoid.PlatformStand = true

				task.delay(3.0, function()
					if character and character.Parent then
						character:SetAttribute("QiDeviation", false)
						local h = character:FindFirstChildOfClass("Humanoid")
						if h then h.PlatformStand = false end
					end
				end)

				local baseQi = CultivationConfig.GetOrderStartingMaxQi(pData.Realm, 9)
				pData.CultivatedQi = baseQi
				pData.CurrentQi = baseQi
				CultivationManager.SyncClient(player)

				if actionRemote then
					actionRemote:FireClient(player, {
						Action = "InnerDemonBacklash",
						Message = "Your mind wavered! Inner Demon Backlash struck — meridians collapsed to 20% Qi.",
					})
				end
				return
			end

			task.wait(tribulationSpec.StrikeInterval or 1.0)
		end

		activeTribulationSessions[player] = nil
		pData.Realm = nextRealm
		pData.Order = 1
		pData.IsTribulationActive = false
		pData.TribulationWave = 0
		local startingQi = CultivationConfig.GetOrderStartingMaxQi(nextRealm, 1)
		pData.CultivatedQi = startingQi
		pData.CurrentQi = startingQi

		CultivationManager.StopGroundedMeditation(player, character)
		CultivationManager.ApplyRealmStats(player)

		local newMaxHp = CultivationConfig.GetOrderMaxHealth(nextRealm, 1)
		local newMaxQi = CultivationConfig.GetOrderTargetQi(nextRealm, 1)
		local powerMult = CultivationConfig.GetPowerMultiplier(nextRealm, 1)
		local realmName = CultivationConfig[nextRealm].Name

		if actionRemote then
			actionRemote:FireClient(player, { Action = "InnerDemonSuccess" })
		end

		local combatRemote = getCombatActionRemote()
		if combatRemote then
			combatRemote:FireAllClients(player, "AscensionBurst", {
				AuraColor = CultivationConfig[nextRealm].AuraColor,
			})
		end

		local upRemote = getUpdateCultivationRemote()
		if upRemote then
			upRemote:FireClient(player, {
				Action = "BreakthroughSuccess",
				IsMajor = true,
				Realm = nextRealm,
				RealmName = realmName,
				Order = 1,
				HpGain = math.max(0, newMaxHp - oldMaxHp),
				QiGain = math.max(0, newMaxQi - oldMaxQi),
				PowerMultiplier = powerMult,
			})
		end

		BroadcastHeavenlyAnnouncement(string.format("[HEAVENLY DAO] Cultivator %s conquered their Inner Demon Tribulation and ascended to %s!", player.DisplayName, realmName))
	end)

	return true
end

function CultivationManager.SyncClient(player: Player)
	local pData = CultivationManager.GetPlayerData(player)
	if not pData then return end

	local realmInfo = CultivationConfig[pData.Realm]
	if not realmInfo then return end

	local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
	local realmText = string.format("%s - Order %d", realmInfo.Name, pData.Order)

	local character = player.Character
	if character then
		local totalLevel = ((realmInfo.Tier - 1) * 9) + pData.Order
		character:SetAttribute("Qi", pData.CurrentQi)
		character:SetAttribute("MaxQi", pData.CultivatedQi)
		character:SetAttribute("TargetQi", maxQiGoal)
		character:SetAttribute("Realm", realmText)
		character:SetAttribute("Level", totalLevel)
		character:SetAttribute("IsMeditating", pData.IsMeditating)
	end

	player:SetAttribute("Realm", realmText)
	player:SetAttribute("Order", pData.Order)
	player:SetAttribute("Qi", pData.CurrentQi)
	player:SetAttribute("CultivatedQi", pData.CultivatedQi)
	player:SetAttribute("MaxQi", pData.CultivatedQi)

	local remote = getUpdateCultivationRemote()
	if remote then
		remote:FireClient(player, {
			RealmName = realmInfo.Name,
			Tier = realmInfo.Tier,
			Order = pData.Order,
			CurrentQi = pData.CurrentQi,
			MaxQi = pData.CultivatedQi,
			TargetQi = maxQiGoal,
			IsMeditating = pData.IsMeditating,
			IsTribulationActive = pData.IsTribulationActive,
			TribulationWave = pData.TribulationWave,
			TotalWaves = pData.TotalWaves,
			HealthMultiplier = realmInfo.HealthMultiplier,
		})
	end
end

return CultivationManager