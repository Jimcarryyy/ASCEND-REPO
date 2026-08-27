--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND.
    Supports 10 Major Realms (90 Orders), Strict CurrentQi <= CultivatedQi <= MaxQiGoal Invariant,
    Continuous Gradual Meditation Qi Recovery, Dynamic Full Body Aura, and Sword Sheathing to Back.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerCultivationData = {
	Realm: CultivationConfig.RealmTier,
	Order: number,        -- 1 through 9
	CurrentQi: number,    -- Active Usable Energy for skills (CurrentQi <= CultivatedQi)
	CultivatedQi: number, -- Current Cultivated Capacity (CultivatedQi <= MaxQiGoal)
	MaxQiGoal: number,    -- Internal Breakthrough Goal Threshold
	IsMeditating: boolean,
	IsTribulationActive: boolean,
	TribulationWave: number,
	TotalWaves: number,
}

local CultivationManager = {}
local playerData: { [Player]: PlayerCultivationData } = {}
local passiveQiLoopThread: thread? = nil
local tribulationThreads: { [Player]: thread } = {}
local lastToggleTimestamp: { [Player]: number } = {}

local updateCultivationRemote: RemoteEvent
local combatActionRemote: RemoteEvent
local weaponManagerRef: any = nil

local function getWeaponManager(): any
	if not weaponManagerRef then
		weaponManagerRef = require(ServerScriptService.Server.Combat.WeaponManager)
	end
	return weaponManagerRef
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
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	Players.PlayerAdded:Connect(CultivationManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CultivationManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		CultivationManager.OnPlayerAdded(player)
	end

	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "table" then
			if payload.ToggleMeditation then
				CultivationManager.ToggleMeditation(player)
			elseif payload.RequestBreakthrough then
				CultivationManager.AttemptBreakthrough(player)
			end
		end
	end)

	passiveQiLoopThread = task.spawn(function()
		while true do
			task.wait(0.5)
			for player, pData in pairs(playerData) do
				if player.Parent and pData and not pData.IsTribulationActive then
					local character = player.Character
					if character and character.Parent then
						local isMeditating = pData.IsMeditating
						local recoveryRate = if isMeditating then (pData.CultivatedQi / 10.0) else (pData.CultivatedQi / 60.0)
						
						if pData.CurrentQi < pData.CultivatedQi then
							local qiGained = recoveryRate * 0.5
							pData.CurrentQi = math.min(pData.CultivatedQi, pData.CurrentQi + qiGained)
						end

						if isMeditating and pData.CultivatedQi < pData.MaxQiGoal then
							local qiNodeMult = GetQiNodeMultiplier(character)
							local expansionRate = (pData.MaxQiGoal * 0.001) * qiNodeMult
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

	print("[ASCEND] CultivationManager Engine Initialized (Dynamic Aura & Sheath Sync Active).")
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
		task.wait(0.2)
		CultivationManager.ApplyRealmStats(player)
	end)
end

function CultivationManager.OnPlayerRemoving(player: Player)
	if tribulationThreads[player] then
		task.cancel(tribulationThreads[player])
		tribulationThreads[player] = nil
	end
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

-- Alias for AddInternalQi. MobAIManager (kill rewards) and MarketplaceManager
-- (auto-meditation gamepass ticks) both call this name; kept as a separate
-- entry point in case its growth curve needs to diverge from AddInternalQi later.
function CultivationManager.AddCultivatedQi(player: Player, amount: number)
	CultivationManager.AddInternalQi(player, amount)
end

function CultivationManager.SetPlayerData(player: Player, realm: CultivationConfig.RealmTier, currentQi: number, order: number?, cultivatedQi: number?)
	local orderNum = math.clamp(order or 1, 1, 9)
	local targetGoal = CultivationConfig.GetOrderTargetQi(realm, orderNum)
	local savedCultivated = cultivatedQi or CultivationConfig.GetOrderStartingMaxQi(realm, orderNum)
	local cultivatedCap = math.clamp(savedCultivated, 100, targetGoal)
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
	pData.MaxQiGoal = maxQiGoal

	pData.CultivatedQi = math.clamp(pData.CultivatedQi or (maxQiGoal * 0.20), 1, maxQiGoal)
	pData.CurrentQi = math.clamp(pData.CurrentQi or pData.CultivatedQi, 0, pData.CultivatedQi)

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local maxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
		humanoid.MaxHealth = maxHp
		humanoid.Health = maxHp
	end

	local realmInfo = CultivationConfig[pData.Realm]
	if realmInfo then
		character:SetAttribute("Realm", string.format("%s — Order %d", realmInfo.Name, pData.Order))
	end
	character:SetAttribute("AlchemyRank", character:GetAttribute("AlchemyRank") or "Mortal Alchemist — Rank 1")

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

	local now = os.clock()
	local lastTime = lastToggleTimestamp[player] or 0
	if now - lastTime < 0.8 then return end
	lastToggleTimestamp[player] = now

	pData.IsMeditating = not pData.IsMeditating
	local character = player.Character
	if not character then return end

	local weaponMgr = getWeaponManager()

	if pData.IsMeditating then
		-- Automatically sheathe sword to back on meditation
		if weaponMgr and weaponMgr.SetWeaponState then
			weaponMgr.SetWeaponState(player, "Back")
		end
		CultivationManager.StartGroundedMeditation(player, character, pData.Realm, false)
	else
		-- Keep sword on back upon exiting meditation
		if weaponMgr and weaponMgr.SetWeaponState then
			weaponMgr.SetWeaponState(player, "Back")
		end
		CultivationManager.StopGroundedMeditation(player, character)
	end

	CultivationManager.SyncClient(player)
end

function CultivationManager.StartGroundedMeditation(player: Player, character: Model, realm: CultivationConfig.RealmTier, isBreakthrough: boolean)
	CultivationManager.StopGroundedMeditation(player, character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local realmInfo = CultivationConfig[realm]
	local auraColor = if realmInfo then (if isBreakthrough then realmInfo.Tribulation.AuraColor else realmInfo.AuraColor) else Color3.fromRGB(0, 220, 255)

	humanoid.Sit = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	-- 1. Realm Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = auraColor
	highlight.FillTransparency = if isBreakthrough then 0.85 else 0.95
	highlight.OutlineColor = auraColor
	highlight.OutlineTransparency = 0.2
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	-- Ground Raycast Alignment
	local raycastParams = RaycastParams.new()
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -20, 0), raycastParams)
	local groundY = if rayResult then rayResult.Position.Y else (hrp.Position.Y - 2.8)
	hrp.CFrame = CFrame.new(hrp.Position.X, groundY + 1.6, hrp.Position.Z) * hrp.CFrame.Rotation

	-- 2. Dynamic Full Body Aura Cloning & Color Tinting
	local auraTemplate = ReplicatedStorage:FindFirstChild("Full body aura") or (ReplicatedStorage:FindFirstChild("Assets") and ReplicatedStorage.Assets:FindFirstChild("Full body aura"))
	if auraTemplate then
		local auraClone = auraTemplate:Clone()
		auraClone.Name = "QiMeditationAura"

		for _, descendant in ipairs(auraClone:GetDescendants()) do
			if descendant:IsA("ParticleEmitter") then
				descendant.Color = ColorSequence.new(auraColor)
				descendant.Enabled = true
			elseif descendant:IsA("PointLight") then
				descendant.Color = auraColor
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
	local aura = character:FindFirstChild("QiMeditationAura")
	if aura then aura:Destroy() end

	local highlight = character:FindFirstChild("QiMeditationHighlight")
	if highlight then highlight:Destroy() end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if hrp then hrp.Anchored = false end
	if humanoid then
		humanoid.Sit = false
		humanoid.WalkSpeed = 18
		humanoid.JumpPower = 65
		humanoid.AutoRotate = true
	end
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = playerData[player]
	if not pData or pData.IsTribulationActive then return false end

	if pData.CultivatedQi < pData.MaxQiGoal then
		updateCultivationRemote:FireClient(player, {
			Action = "BreakthroughRejected",
			Message = "Keep cultivating! Your Qi isn't ready for breakthrough yet."
		})
		return false
	end

	if pData.Order < 9 then
		pData.Order += 1
		CultivationManager.ApplyRealmStats(player)
		CultivationManager.SyncClient(player)
		return true
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

	local tribulationSpec = CultivationConfig[pData.Realm].Tribulation

	if tribulationSpec.StrikeCount <= 0 then
		pData.Realm = nextRealm
		pData.Order = 1
		CultivationManager.ApplyRealmStats(player)
		CultivationManager.SyncClient(player)
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

	tribulationThreads[player] = task.spawn(function()
		local stormCloud = CultivationManager.SpawnStormCloud(character, tribulationSpec.AuraColor)

		for wave = 1, tribulationSpec.StrikeCount do
			if not player.Parent or not character.Parent then break end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not humanoid or humanoid.Health <= 0 or not hrp then break end

			pData.TribulationWave = wave
			CultivationManager.SyncClient(player)

			local targetPos = hrp.Position + Vector3.new(math.random(-2, 2), 0, math.random(-2, 2))

			combatActionRemote:FireAllClients(player, "TribulationTelegraph", {
				TargetPosition = targetPos,
				TelegraphTime = tribulationSpec.TelegraphTime,
				AuraColor = tribulationSpec.AuraColor,
			})

			task.wait(tribulationSpec.TelegraphTime)
			if not humanoid or humanoid.Health <= 0 then break end

			combatActionRemote:FireAllClients(player, "TribulationStrike", {
				TargetPosition = targetPos,
				Damage = tribulationSpec.DamagePerStrike,
				AuraColor = tribulationSpec.AuraColor,
			})

			humanoid:TakeDamage(tribulationSpec.DamagePerStrike)
			if humanoid.Health <= 0 then
				pData.IsTribulationActive = false
				pData.TribulationWave = 0
				if stormCloud then stormCloud:Destroy() end
				CultivationManager.StopGroundedMeditation(player, character)
				CultivationManager.SyncClient(player)
				return
			end

			task.wait(tribulationSpec.StrikeInterval)
		end

		if stormCloud then stormCloud:Destroy() end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			pData.Realm = nextRealm
			pData.Order = 1
			pData.IsTribulationActive = false
			pData.TribulationWave = 0

			CultivationManager.StopGroundedMeditation(player, character)
			CultivationManager.ApplyRealmStats(player)

			combatActionRemote:FireAllClients(player, "AscensionBurst", {
				AuraColor = CultivationConfig[nextRealm].AuraColor,
			})
		else
			pData.IsTribulationActive = false
			pData.TribulationWave = 0
			CultivationManager.StopGroundedMeditation(player, character)
			CultivationManager.SyncClient(player)
		end
	end)

	return true
end

function CultivationManager.SpawnStormCloud(character: Model, auraColor: Color3): Part
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local cloud = Instance.new("Part")
	cloud.Name = "TribulationStormCloud"
	cloud.Size = Vector3.new(28, 2.5, 28)
	if hrp then cloud.Position = hrp.Position + Vector3.new(0, 22, 0) end
	cloud.Color = Color3.fromRGB(15, 15, 22)
	cloud.Material = Enum.Material.SmoothPlastic
	cloud.Transparency = 0.25
	cloud.Anchored = true
	cloud.CanCollide = false
	cloud.Parent = character

	local light = Instance.new("PointLight")
	light.Range = 36
	light.Brightness = 8
	light.Color = auraColor
	light.Parent = cloud

	return cloud
end

function CultivationManager.SyncClient(player: Player)
	local pData = playerData[player]
	if not pData then return end

	local realmInfo = CultivationConfig[pData.Realm]
	if not realmInfo then return end

	local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)

	local character = player.Character
	if character then
		local totalLevel = ((realmInfo.Tier - 1) * 9) + pData.Order
		character:SetAttribute("Qi", pData.CurrentQi)
		character:SetAttribute("MaxQi", pData.CultivatedQi)
		character:SetAttribute("TargetQi", maxQiGoal)
		character:SetAttribute("Realm", string.format("%s — Order %d", realmInfo.Name, pData.Order))
		character:SetAttribute("Level", totalLevel)
	end

	updateCultivationRemote:FireClient(player, {
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

return CultivationManager