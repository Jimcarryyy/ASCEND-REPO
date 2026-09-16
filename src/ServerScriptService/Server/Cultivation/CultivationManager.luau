--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND:
    - Synchronous zero-delay CharacterAdded stat binding
    - Full body aura lifecycle during Meditation
    - Sect-buff scaled passive Qi loop and meditation recovery rate
    - Clamped 20% starting Qi per order (eliminating 69% loophole and free Order-2 advances)
    - Breakthrough Dan consumption requirement
    - Inner Demon Tribulation QTE Engine with non-lethal Qi Deviation Backlash
    - Safe lazy remote resolution (immune to initialization sequence order)
    - Remote-routed Heavenly Ascension Announcements (Client-safe TextChatService)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
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

local CultivationManager = {}
local playerData: { [Player]: PlayerCultivationData } = {}
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

local vfxFolder = ReplicatedStorage:WaitForChild("VFX", 5) :: Folder?

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

local function GetSectQiBuffMultiplier(player: Player): number
	local pdm = getPlayerDataManager()
	if not pdm or not pdm.GetSectRank then return 1.0 end
	local rank = pdm.GetSectRank(player) or "OuterDisciple"
	local rankDef = SectConfig.GetRank(rank)
	return if rankDef and rankDef.QiBuffMultiplier then rankDef.QiBuffMultiplier else 1.0
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
				elseif payload.RequestBreakthrough then
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
			end
		end)
	end

	passiveQiLoopThread = task.spawn(function()
		while true do
			task.wait(0.5)
			for player, pData in pairs(playerData) do
				if player.Parent and pData and not pData.IsTribulationActive then
					local character = player.Character
					if character and character.Parent then
						local isMeditating = pData.IsMeditating
						local sectMult = GetSectQiBuffMultiplier(player)
						local recoveryRate = if isMeditating then ((pData.CultivatedQi / 10.0) * sectMult) else (pData.CultivatedQi / 60.0)
						
						if pData.CurrentQi < pData.CultivatedQi then
							local qiGained = recoveryRate * 0.5
							pData.CurrentQi = math.min(pData.CultivatedQi, pData.CurrentQi + qiGained)
						end

						if isMeditating and pData.CultivatedQi < pData.MaxQiGoal then
							local qiNodeMult = GetQiNodeMultiplier(character)
							local expansionRate = (pData.MaxQiGoal * 0.001) * qiNodeMult * sectMult
							pData.CultivatedQi = math.min(pData.MaxQiGoal, pData.CultivatedQi + (expansionRate * 0.5))
						end

						pData.CultivatedQi = math.clamp(pData.CultivatedQi, 0, pData.MaxQiGoal)
						pData.CurrentQi = math.clamp(pData.CurrentQi, 0, pData.CultivatedQi)

						CultivationManager.SyncClient(player)
					end
				end
			end
		end
	end)

	print("[ASCEND] CultivationManager Engine Initialized (Inner Demon & Sect Buff Multipliers Active).")
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

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
		if humanoid then
			local pData = playerData[player]
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
	if tribulationThreads[player] then
		task.cancel(tribulationThreads[player])
		tribulationThreads[player] = nil
	end
	activeTribulationSessions[player] = nil
	lastToggleTimestamp[player] = nil
	playerData[player] = nil
end

function CultivationManager.GetPlayerData(player: Player): PlayerCultivationData?
	return playerData[player]
end

function CultivationManager.AddInternalQi(player: Player, amount: number)
	local pData = playerData[player]
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
	local pData = playerData[player]
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
	local pData = playerData[player]
	if not pData then return false end

	if pData.CurrentQi < amount then
		return false
	end

	pData.CurrentQi = math.max(0, pData.CurrentQi - amount)
	CultivationManager.SyncClient(player)
	return true
end

function CultivationManager.ToggleMeditation(player: Player)
	local pData = playerData[player]
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

	local realmInfo = CultivationConfig[realm]
	local auraColor = if realmInfo then (if isBreakthrough then realmInfo.Tribulation.AuraColor else realmInfo.AuraColor) else Color3.fromRGB(0, 220, 255)

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	character:SetAttribute("IsMeditating", true)

	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = auraColor
	highlight.FillTransparency = if isBreakthrough then 0.85 else 0.95
	highlight.OutlineColor = auraColor
	highlight.OutlineTransparency = 0.2
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), raycastParams)
	local groundY = if rayResult then rayResult.Position.Y else (hrp.Position.Y - 3.0)

	hrp.CFrame = CFrame.new(hrp.Position.X, groundY + 4.8, hrp.Position.Z) * hrp.CFrame.Rotation

	local auraTemplate = (vfxFolder and vfxFolder:FindFirstChild("Full body aura"))
		or (ReplicatedStorage:FindFirstChild("Full body aura", true) :: Instance?)

	if auraTemplate then
		local auraClone = auraTemplate:Clone()
		auraClone.Name = "QiMeditationAura"

		for _, descendant in ipairs(auraClone:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Color = ColorSequence.new(auraColor)
				descendant.Enabled = true
			elseif descendant:IsA("PointLight") then
				descendant.Color = auraColor
				descendant.Enabled = true
			elseif descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanTouch = false
				descendant.CanQuery = false
				descendant.Massless = true
				descendant.Transparency = 1

				descendant.CFrame = hrp.CFrame
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = hrp
				weld.Part1 = descendant
				weld.Parent = descendant
			end
		end

		auraClone.Parent = character
	end

	hrp.Anchored = true
end

function CultivationManager.StopGroundedMeditation(player: Player, character: Model)
	for _, child in ipairs(character:GetChildren()) do
		if child.Name == "QiMeditationAura" or child.Name == "QiMeditationHighlight" then
			for _, emitter in ipairs(child:GetDescendants()) do
				if emitter:IsA("ParticleEmitter") then
					emitter.Enabled = false
				elseif emitter:IsA("PointLight") then
					emitter.Enabled = false
				end
			end
			child:Destroy()
		end
	end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		for _, child in ipairs(hrp:GetChildren()) do
			if child.Name == "QiMeditationAura" or child.Name:match("^Aura") then
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
		humanoid.WalkSpeed = 18
		humanoid.JumpPower = 65
		humanoid.AutoRotate = true
	end
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = playerData[player]
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

	-- Minor Order Breakthrough (Orders 1 through 8)
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

	-- Major Realm Breakthrough (Order 9 -> Next Realm Order 1)
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

	-- 1. Dan Consumption Gate
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

	-- Instant Breakthrough for realms without tribulation strikes
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

	-- 2. Inner Demon Tribulation Engine
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
				-- TRIBULATION BACKLASH (No Permadeath)
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

		-- SUCCESSFUL ASCENSION
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
	local pData = playerData[player]
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