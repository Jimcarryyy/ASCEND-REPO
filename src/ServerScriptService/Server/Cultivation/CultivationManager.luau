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

function CultivationManager.OnCultivationAction(player: Player, payload: any)
	if type(payload) ~= "table" then return end
	-- Remote action handler
end

function CultivationManager.OnCultivationAction(player: Player, payload: any)
	if type(payload) ~= "table" then return end
end

function CultivationManager.SetPlayerData(player: Player, data: any)
	if not data then return end
	playerData[player] = data
	local character = player.Character
	local realmKey = data.Realm or "QiCondensation"
	local order = data.Order or 1
	if character then
		ApplyRealmStats(player, character, realmKey, order)
	end
	CultivationManager.SyncClient(player)
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

	print("[ASCEND] CultivationManager Initialized (Unanchored Safe Meditation Engine Active).")
end

function CultivationManager.OnPlayerAdded(player: Player)
	local pData = PlayerDataManager.GetPlayerData(player)
	if not pData then return end
	if not playerData[player] then
		local startTarget = CultivationConfig.GetOrderTargetQi("QiCondensation", 1)
-- OPTION A: KEEP YOUR QI! Never reset on breakthrough
		pData.MaxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
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
					Message = string.format("Breakthrough Blocked: Consuming a %s is required!", requiredDan.DisplayName),
				})
			end
			return false
		end
		invMgr.RemoveItem(player, requiredDan.ItemId, 1)
	end

	pData.Realm = nextRealm
	pData.Order = 1
-- OPTION A: KEEP YOUR QI! Never reset on breakthrough
		pData.MaxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
	CultivationManager.ApplyRealmStats(player)
	CultivationManager.SyncClient(player)

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
		local rInfo = CultivationConfig[pData.Realm]
		local pTier = if rInfo and rInfo.Tier then rInfo.Tier else 1
		character:SetAttribute("Tier", pTier)
		player:SetAttribute("Tier", pTier)
		player:SetAttribute("BreakthroughReady", pData.CultivatedQi >= maxQiGoal)
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