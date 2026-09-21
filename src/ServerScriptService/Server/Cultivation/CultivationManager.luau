--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Server-authoritative engine for Qi cultivation, realm breakthrough, and zone locks.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CultivationManager = {}

-- Robust UserId-keyed server state
local playerData: { [number]: any } = {}
local characterConnections: { [Player]: { RBXScriptConnection } } = {}

-- Lazy Getters
local combatActionRemoteRef: RemoteEvent? = nil
local cultivationActionRemoteRef: RemoteEvent? = nil
local updateCultivationRemoteRef: RemoteEvent? = nil
local playerDataManagerRef: any = nil
local weaponManagerRef: any = nil
local sectManagerRef: any = nil

local function getCombatActionRemote(): RemoteEvent?
	if not combatActionRemoteRef then
		combatActionRemoteRef = RemoteEvents.GetRemote("CombatAction")
	end
	return combatActionRemoteRef
end

local function getCultivationActionRemote(): RemoteEvent?
	if not cultivationActionRemoteRef then
		cultivationActionRemoteRef = RemoteEvents.GetRemote("CultivationAction")
	end
	return cultivationActionRemoteRef
end

local function getUpdateCultivationRemote(): RemoteEvent?
	if not updateCultivationRemoteRef then
		updateCultivationRemoteRef = RemoteEvents.GetRemote("UpdateCultivation")
	end
	return updateCultivationRemoteRef
end

local function getPlayerDataManager(): any
	if not playerDataManagerRef then
		playerDataManagerRef = require(ServerScriptService.Server.State.PlayerDataManager)
	end
	return playerDataManagerRef
end

local function getWeaponManager(): any
	if not weaponManagerRef then
		weaponManagerRef = require(ServerScriptService.Server.Combat.WeaponManager)
	end
	return weaponManagerRef
end

local function getSectManager(): any
	if not sectManagerRef then
		sectManagerRef = require(ServerScriptService.Server.Cultivation.SectManager)
	end
	return sectManagerRef
end

-- Core Stat & Realm Application
local function ApplyRealmStats(player: Player, character: Model, realm: any, order: number)
	local realmInfo = CultivationConfig[realm]
	if not realmInfo then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local maxHp = CultivationConfig.GetOrderMaxHealth(realm, order)
		humanoid.MaxHealth = maxHp
		humanoid.Health = maxHp
	end
end

-- Cylindrical Qi Zone Detection: Returns 1.0 baseline if outside or under-leveled (never blocks controls)
local function GetQiNodeMultiplier(character: Model): (number, boolean, string?, number?)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 1.0, false, nil, nil end

	local qiNodesFolder = Workspace:FindFirstChild("QiNodes")
	if not qiNodesFolder then return 1.0, false, nil, nil end

	local rawRealm = character:GetAttribute("Realm")
	local cleanRealm = if type(rawRealm) == "string" then rawRealm:gsub("%s*[-–].*", ""):gsub("%s+", "") else "QiCondensation"
	local realmInfo = CultivationConfig[cleanRealm]
	local playerTier = if realmInfo and realmInfo.Tier then realmInfo.Tier else 1

	for _, nodePart in ipairs(qiNodesFolder:GetChildren()) do
		if nodePart:IsA("BasePart") then
			local flatDist = Vector3.new(hrp.Position.X - nodePart.Position.X, 0, hrp.Position.Z - nodePart.Position.Z).Magnitude
			local flatRadius = math.max(nodePart.Size.X, nodePart.Size.Z) / 2 + 8
			local vertDist = math.abs(hrp.Position.Y - nodePart.Position.Y)
			local vertMax = (nodePart.Size.Y / 2) + 35

			if flatDist <= flatRadius and vertDist <= vertMax then
				local reqTier = tonumber(nodePart:GetAttribute("RequiredTier") or nodePart:GetAttribute("MinTier")) or 1
				local reqRealm = tostring(nodePart:GetAttribute("RequiredRealm") or "Higher Realm")

				if playerTier < reqTier then
					-- Under-leveled: Falls back to 1.0x baseline (no node bonus)
					return 1.0, true, reqRealm, reqTier
				end

				local customMultiplier = nodePart:GetAttribute("QiMultiplier")
				if type(customMultiplier) == "number" and customMultiplier > 0 then
					return math.clamp(customMultiplier, 1.0, 15.0), false, nil, nil
				end
				return 1.5, false, nil, nil
			end
		end
	end

	return 1.0, false, nil, nil
end

local function GetSectQiBuffMultiplier(player: Player): number
	local sectMgr = getSectManager()
	if sectMgr and sectMgr.GetSectQiBuff then
		return sectMgr.GetSectQiBuff(player)
	end
	return 1.0
end

local function GetSamsaraRefineMultiplier(player: Player): number
	local pData = playerData[player.UserId]
	if not pData then return 1.0 end
	local cycle = tonumber(pData.SamsaraCycle) or 0
	return 1.0 + (cycle * 0.15)
end

-- Grounded Meditation Helpers: Locks movement securely
local function StartGroundedMeditation(player: Player, character: Model, realm: any, isRebirth: boolean)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if humanoid and hrp then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
		hrp.AssemblyLinearVelocity = Vector3.zero
	end
end

local function StopGroundedMeditation(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
	end
end

-- Public Lifecycle Methods
function CultivationManager.GetPlayerData(player: Player): any
	local pData = playerData[player.UserId]
	if not pData then
		local char = player.Character
		if char then
			local r = tostring(char:GetAttribute("Realm") or "QiCondensation")
			local cleanR = r:gsub("%s*[-–].*", ""):gsub("%s+", "")
			local o = tonumber(char:GetAttribute("Order")) or 1
			local cQi = tonumber(char:GetAttribute("Qi")) or 200
			local mQi = tonumber(char:GetAttribute("MaxQi")) or cQi
			local maxGoal = CultivationConfig.GetOrderTargetQi(cleanR, o)

			pData = {
				Realm = cleanR,
				Order = o,
				CurrentQi = cQi,
				CultivatedQi = mQi,
				MaxQiGoal = maxGoal,
				IsMeditating = char:GetAttribute("IsMeditating") == true,
			}
			playerData[player.UserId] = pData
		end
	end
	return pData
end

function CultivationManager.OnPlayerRemoving(player: Player)
	playerData[player.UserId] = nil
	if characterConnections[player] then
		for _, conn in ipairs(characterConnections[player]) do conn:Disconnect() end
		characterConnections[player] = nil
	end
end

function CultivationManager.OnCultivationAction(player: Player, payload: any)
	if type(payload) ~= "table" then return end
end

-- Handles both Table and 5-argument signatures from PlayerDataManager
function CultivationManager.SetPlayerData(player: Player, realmOrTable: any, currentQi: any, order: any, cultivatedQi: any)
	local r = "QiCondensation"
	local o = 1
	local cQi = 200
	local mQi = 200

	if type(realmOrTable) == "table" then
		r = tostring(realmOrTable.Realm or "QiCondensation")
		o = tonumber(realmOrTable.Order) or 1
		cQi = tonumber(realmOrTable.CurrentQi) or 200
		mQi = tonumber(realmOrTable.CultivatedQi) or cQi
	else
		r = tostring(realmOrTable or "QiCondensation")
		cQi = tonumber(currentQi) or 200
		o = tonumber(order) or 1
		mQi = tonumber(cultivatedQi) or cQi
	end

	local cleanRealm = r:gsub("%s*[-–].*", ""):gsub("%s+", "")
	local maxGoal = CultivationConfig.GetOrderTargetQi(cleanRealm, o)

	playerData[player.UserId] = {
		Realm = cleanRealm,
		Order = o,
		CurrentQi = cQi,
		CultivatedQi = mQi,
		MaxQiGoal = maxGoal,
		IsMeditating = false,
	}

	local character = player.Character
	if character then
		ApplyRealmStats(player, character, cleanRealm, o)
	end

	CultivationManager.SyncClient(player)
end

function CultivationManager.Init()
	local combatRemote = getCombatActionRemote()
	local actionRemote = getCultivationActionRemote()

	Players.PlayerAdded:Connect(CultivationManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CultivationManager.OnPlayerRemoving)

	if actionRemote then
		actionRemote.OnServerEvent:Connect(CultivationManager.OnCultivationAction)
	end

	-- Heartbeat Cultivation Loop (0.5s)
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local pData = CultivationManager.GetPlayerData(player)
				local character = player.Character

				if character and character.Parent and pData then
					local realmInfo = CultivationConfig[pData.Realm]
					local baseGather = if realmInfo and realmInfo.GatherRate then realmInfo.GatherRate else 20
					local maxGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order or 1)
					pData.MaxQiGoal = maxGoal

					local qiNodeMult = GetQiNodeMultiplier(character)

					if pData.IsMeditating and (pData.CultivatedQi or 0) < maxGoal then
						local sectMult = GetSectQiBuffMultiplier(player)
						local samsaraRefineMult = GetSamsaraRefineMultiplier(player)
						local maxClamp = math.max(5.0, (realmInfo and realmInfo.Tier or 1) * 2.0)
						local combinedMult = math.clamp(qiNodeMult * sectMult * samsaraRefineMult, 1.0, maxClamp)
						local expansionRate = baseGather * combinedMult
						pData.CultivatedQi = math.min(maxGoal, (pData.CultivatedQi or 0) + (expansionRate * 0.5))
					end

					-- Internal Combat Qi Recovery (Guarded from nil)
					local cultivated = pData.CultivatedQi or 0
					local sectMult = GetSectQiBuffMultiplier(player)
					local samsaraRefineMult = GetSamsaraRefineMultiplier(player)
					local recoveryRate = if pData.IsMeditating
						then ((cultivated / 10.0) * sectMult * samsaraRefineMult)
						else (cultivated / 60.0)

					if (pData.CurrentQi or 0) < cultivated then
						pData.CurrentQi = math.min(cultivated, (pData.CurrentQi or 0) + (recoveryRate * 0.5))
					end

					CultivationManager.SyncClient(player)
				end
			end
		end
	end)

	print("[ASCEND] CultivationManager Initialized Successfully.")
end

function CultivationManager.OnPlayerAdded(player: Player)
	-- PlayerDataManager calls SetPlayerData when DataStore finishes loading
end

function CultivationManager.ToggleMeditation(player: Player)
	local pData = CultivationManager.GetPlayerData(player)
	if not pData or pData.IsTribulationActive then return end
	local character = player.Character
	if not character then return end

	pData.IsMeditating = not pData.IsMeditating
	character:SetAttribute("IsMeditating", pData.IsMeditating)

	local weaponMgr = getWeaponManager()
	if pData.IsMeditating then
		if weaponMgr then weaponMgr.SetWeaponState(player, "Back", true) end
		StartGroundedMeditation(player, character, pData.Realm, false)
	else
		StopGroundedMeditation(player, character)
	end

	CultivationManager.SyncClient(player)
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = CultivationManager.GetPlayerData(player)
	if not pData or pData.IsTribulationActive then return false end
	local updateRemote = getUpdateCultivationRemote()
	local maxGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order or 1)

	if (pData.CultivatedQi or 0) < maxGoal then
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "BreakthroughRejected",
				Message = "Keep cultivating! Your Qi isn't ready for breakthrough yet.",
			})
		end
		return false
	end

	local currentOrder = pData.Order or 1
	if currentOrder < 9 then
		-- PURE PHASE 1 LOOP: Order advances, Dantian empties for the next order
		pData.Order = currentOrder + 1
		pData.CultivatedQi = 0
		pData.CurrentQi = 0
		pData.MaxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)

		local character = player.Character
		if character then
			ApplyRealmStats(player, character, pData.Realm, pData.Order)
		end

		local pdm = getPlayerDataManager()
		if pdm then pdm.SaveData(player) end
		CultivationManager.SyncClient(player)

		if updateRemote then
			local realmInfo = CultivationConfig[pData.Realm]
			local hpGain = math.floor((realmInfo and realmInfo.BaseMaxHealth or 1000) * 0.05)
			local powerMult = (realmInfo and realmInfo.DamageMultiplier or 1.0) * (1.0 + (pData.Order - 1) * 0.05)
			updateRemote:FireClient(player, {
				Action = "BreakthroughSuccess",
				IsMajor = false,
				Order = pData.Order,
				NewOrder = pData.Order,
				Realm = pData.Realm,
				RealmName = realmInfo and realmInfo.Name or pData.Realm,
				HpGain = hpGain,
				QiGain = 0,
				PowerMultiplier = powerMult,
			})
		end
		return true
	end

	return false
end

function CultivationManager.SyncClient(player: Player)
	local pData = playerData[player.UserId]
	if not pData then return end
	local character = player.Character
	local maxGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order or 1)
	local realmInfo = CultivationConfig[pData.Realm]
	local pTier = if realmInfo and realmInfo.Tier then realmInfo.Tier else 1
	local isReady = ((pData.CultivatedQi or 0) >= maxGoal)

	if character then
		character:SetAttribute("Qi", pData.CurrentQi or 0)
		character:SetAttribute("MaxQi", pData.CultivatedQi or 0)
		character:SetAttribute("TargetQi", maxGoal)
		character:SetAttribute("BreakthroughReady", isReady)
		character:SetAttribute("Tier", pTier)
		character:SetAttribute("Realm", tostring(pData.Realm or "QiCondensation"))
		character:SetAttribute("IsMeditating", pData.IsMeditating == true)
	end

	player:SetAttribute("Tier", pTier)
	player:SetAttribute("BreakthroughReady", isReady)

	local updateRemote = getUpdateCultivationRemote()
	if updateRemote then
		updateRemote:FireClient(player, {
			RealmName = realmInfo and realmInfo.Name or pData.Realm,
			Realm = pData.Realm,
			Tier = pTier,
			Order = pData.Order or 1,
			CurrentQi = pData.CurrentQi or 0,
			MaxQi = pData.CultivatedQi or 0,
			TargetQi = maxGoal,
			IsMeditating = pData.IsMeditating == true,
		})
	end
end

return CultivationManager