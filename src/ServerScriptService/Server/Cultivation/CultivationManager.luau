--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Fixes:
      - Removed hrp.Anchored = true/false: Eliminates the 'Network Ownership API cannot be called on Anchored parts' crash.
      - Freezes meditation via velocity zeroing, WalkSpeed, and JumpPower without anchoring the character.
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

type AuraPalette = {
	Gradient: ColorSequence,
	LightColor: Color3,
}

local BLOODLINE_AURA_PALETTES: { [string]: AuraPalette } = {
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

local function GetQiNodeMultiplier(character: Model, playerTier: number): number
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 1.0 end

	local qiNodesFolder = Workspace:FindFirstChild("QiNodes")
	if not qiNodesFolder then return 1.0 end

	for _, nodePart in ipairs(qiNodesFolder:GetChildren()) do
		if nodePart:IsA("BasePart") then
			local distance = (hrp.Position - nodePart.Position).Magnitude
			local maxRadius = math.max(nodePart.Size.X, nodePart.Size.Z) / 2 + 3
			if distance <= maxRadius then
				local reqTier = nodePart:GetAttribute("RequiredTier") or nodePart:GetAttribute("MinTier")
				if type(reqTier) == "number" and playerTier < reqTier then
					return 1.0 -- Locked: realm tier too low
				end
				local customMultiplier = nodePart:GetAttribute("QiMultiplier")
				if type(customMultiplier) == "number" and customMultiplier > 0 then
					return math.clamp(customMultiplier, 1.0, 3.0)
				end
				return 1.5 -- Safe default
			end
		end
	end

	return 1.0
end

function CultivationManager.Init()
	local combatRemote = getCombatActionRemote()
	local actionRemote = getCultivationActionRemote()

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

	task.spawn(function()
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
								local playerTier = if realmInfo and realmInfo.Tier then realmInfo.Tier else 1
		local qiNodeMult = GetQiNodeMultiplier(character, playerTier)
		local combinedMultiplier = math.clamp(qiNodeMult * sectMult * samsaraRefineMult, 1.0, 4.0)
		local expansionRate = baseGather * combinedMultiplier
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

	print("[ASCEND] CultivationManager Initialized (Unanchored Safe Meditation Engine Active).")
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

function CultivationManager.StartGroundedMeditation(player: Player, character: Model, realm: CultivationConfig.RealmTier, isBreakthrough: boolean)
	CultivationManager.StopGroundedMeditation(player, character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

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

	-- Zero velocities and lock humanoid without anchoring BasePart
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	character:SetAttribute("IsMeditating", true)

	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = palette.LightColor
	highlight.FillTransparency = if isBreakthrough then 0.82 else 0.90
	highlight.OutlineColor = palette.LightColor
	highlight.OutlineTransparency = 0.25
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local auraFolder = ReplicatedStorage:FindFirstChild("AuraTemplates") or Workspace:FindFirstChild("AuraTemplates")
	local tierTemplate = auraFolder and auraFolder:FindFirstChild(templateName) :: Folder?

	if tierTemplate then
		local clonedAttachments: { [string]: Attachment } = {}
		for _, child in ipairs(tierTemplate:GetChildren()) do
			if child:IsA("Attachment") then
				local attClone = child:Clone()
				attClone.Name = "Aura_" .. child.Name
				attClone.Parent = hrp
				clonedAttachments[child.Name] = attClone

				for _, desc in ipairs(attClone:GetDescendants()) do
					if desc:IsA("ParticleEmitter") then
						local origEmission = desc:GetAttribute("OriginalEmission") or desc.LightEmission
						if origEmission == 0 then
							desc.Color = ColorSequence.new(Color3.fromRGB(20, 20, 30))
						elseif desc.Name == "Eye" then
							desc.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
						else
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
end

function CultivationManager.StopGroundedMeditation(player: Player, character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "QiMeditationHighlight" or child.Name == "QiMeditationAura" then
			child:Destroy()
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		for _, child in ipairs(hrp:GetChildren()) do
			if child:IsA("Attachment") and (child.Name:match("^Aura_") or child.Name:match("^RootAttachment") or child.Name:match("^GroundAttachment")) then
				child:Destroy()
			end
		end
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
	end

	character:SetAttribute("IsMeditating", false)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local inArena = character:GetAttribute("InArena") == true
		humanoid.WalkSpeed = if inArena then 14.0 else 16.0
		humanoid.JumpPower = 76.0
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
			})
		end
		return false
	end

	if pData.CultivatedQi < pData.MaxQiGoal then
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughRejected",
				Message = "Your Dantian must be 100% saturated with Immortal Qi to initiate Samsara Rebirth!",
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
		"[HEAVENLY SAMSARA] Cultivator %s reached the Ultimate Pinnacle and underwent Samsara Rebirth %s!",
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

	local nextRealm = (nextRealmMap and nextRealmMap[pData.Realm]) or "SoulFormation"
	if not nextRealm then return false end

	local requiredDan = REALM_BREAKTHROUGH_DAN[nextRealm]
	local invMgr = getInventoryManager()
	if requiredDan and invMgr then
		if not invMgr.HasItem(player, requiredDan.ItemId, 1) then
			if updateRemote then
				updateRemote:FireClient(player, {
					Action = "BreakthroughRejected",
					Message = "Bottleneck Blocked: Consuming a " .. requiredDan.DisplayName .. " is required to summon Tribulation!",
				})
			end
			return false
		end
	end

	if pData.IsTribulationActive then return false end
	pData.IsTribulationActive = true

	-- Phase 2.6 & 2.7: Heavenly Tribulation Lightning Sequence
	task.spawn(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local survived = true

		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "TribulationStarted",
				Realm = nextRealm,
				DanName = if requiredDan then requiredDan.DisplayName else "Breakthrough Dan",
				MaxWaves = 3,
			})
		end

		for wave = 1, 3 do
			if not player.Parent or not char or not char.Parent or not hum or hum.Health <= 0 then
				survived = false
				break
			end

			local strikePos = hrp.Position
			local telegraph = Instance.new("Part")
			telegraph.Shape = Enum.PartType.Cylinder
			telegraph.Size = Vector3.new(0.4, 16, 16)
			telegraph.CFrame = CFrame.new(strikePos) * CFrame.Angles(0, 0, math.rad(90))
			telegraph.Anchored = true
			telegraph.CanCollide = false
			telegraph.Material = Enum.Material.Neon
			telegraph.Color = Color3.fromRGB(255, 60, 60)
			telegraph.Transparency = 0.5
			telegraph.Parent = Workspace
			game:GetService("Debris"):AddItem(telegraph, 1.6)

			task.wait(1.3)

			if not player.Parent or not hum or hum.Health <= 0 then
				survived = false
				break
			end

			local bolt = Instance.new("Part")
			bolt.Size = Vector3.new(3, 140, 3)
			bolt.CFrame = CFrame.new(strikePos + Vector3.new(0, 70, 0))
			bolt.Anchored = true
			bolt.CanCollide = false
			bolt.Material = Enum.Material.Neon
			bolt.Color = Color3.fromRGB(220, 240, 255)
			bolt.Parent = Workspace
			game:GetService("Debris"):AddItem(bolt, 0.3)

			local dist = (hrp.Position - strikePos).Magnitude
			local isBlocking = char:GetAttribute("IsBlocking") == true

			if isBlocking then
				local combatVFX = RemoteEvents.GetRemote("CombatVFX")
				if combatVFX then combatVFX:FireAllClients("ParryClash", hrp.Position) end
			elseif dist <= 9 then
				hum:TakeDamage(math.floor(hum.MaxHealth * 0.35))
			end

			if hum.Health <= 0 then
				survived = false
				break
			end

			task.wait(1.4)
		end

		pData.IsTribulationActive = false

		if survived and player.Parent and hum and hum.Health > 0 then
	local invMgr = getInventoryManager()
	if requiredDan and invMgr then
				invMgr.RemoveItem(player, requiredDan.ItemId, 1)
			end
			pData.Realm = nextRealm
			pData.Order = 1
			pData.CultivatedQi = 0
			pData.CurrentQi = 0
			CultivationManager.ApplyRealmStats(player)
			getPlayerDataManager().SetPlayerData(player, pData)
			CultivationManager.SyncClient(player)

			if updateRemote then
				updateRemote:FireClient(player, {
					Action = "BreakthroughSuccess",
					IsMajor = true,
					Realm = pData.Realm,
					RealmName = CultivationConfig[pData.Realm].Name,
					Order = 1,
					HpGain = math.floor((CultivationConfig[pData.Realm].BaseMaxHealth or 3500) * 0.20),
					QiGain = 0,
					PowerMultiplier = CultivationConfig.GetPowerMultiplier(pData.Realm, 1),
				})
			end

			local announceRemote = RemoteEvents.GetRemote("HeavenlyAnnouncement")
			if announceRemote then
				announceRemote:FireAllClients(string.format("%s has conquered the Heavenly Tribulation and ascended to %s!", player.DisplayName, CultivationConfig[pData.Realm].Name))
			end
		else
			pData.CultivatedQi = math.floor((pData.CultivatedQi or 0) * 0.5)
			getPlayerDataManager().SetPlayerData(player, pData)
			CultivationManager.SyncClient(player)

			if updateRemote then
				updateRemote:FireClient(player, {
					Action = "BreakthroughRejected",
					Message = "Tribulation Overwhelmed! Dantian energy recoiled (-50% Qi). Your Dan was spared.",
				})
			end
		end
	end)
	local realmName = CultivationConfig[nextRealm].Name
	if updateRemote then
		updateRemote:FireClient(player, {
			Action = "BreakthroughSuccess",
			IsMajor = true,
			Realm = nextRealm,
			RealmName = realmName,
			Order = 1,
			HpGain = 0,
			QiGain = 0,
			PowerMultiplier = 1.2,
		})
	end

	BroadcastHeavenlyAnnouncement(string.format("[HEAVENLY DAO] Cultivator %s has ascended to %s!", player.DisplayName, realmName))
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
		character:SetAttribute("Qi", pData.CurrentQi)
		character:SetAttribute("MaxQi", pData.CultivatedQi)
		character:SetAttribute("TargetQi", maxQiGoal)
		character:SetAttribute("BreakthroughReady", pData.CultivatedQi >= maxQiGoal)
		character:SetAttribute("Realm", realmText)
		character:SetAttribute("IsMeditating", pData.IsMeditating)
	end

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
		})
	end
end

return CultivationManager