--!strict
--[[
    CultivationManager.luau
    Location: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND.
    Includes PlatformStand physics stabilization and slow 3-second celestial floating.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local TweenService = game:GetService("TweenService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerCultivationData = {
	Realm: CultivationConfig.RealmTier,
	Order: number, -- 1 through 9
	CurrentQi: number,
	IsMeditating: boolean,
	IsTribulationActive: boolean,
	TribulationWave: number,
	TotalWaves: number,
}

local CultivationManager = {}
local playerData: { [Player]: PlayerCultivationData } = {}
local meditationThreads: { [Player]: thread } = {}
local levitationTweens: { [Player]: Tween } = {}
local tribulationThreads: { [Player]: thread } = {}

local updateCultivationRemote: RemoteEvent
local combatActionRemote: RemoteEvent
local weaponManagerRef: any = nil

local function getWeaponManager(): any
	if not weaponManagerRef then
		weaponManagerRef = require(ServerScriptService.Server.Combat.WeaponManager)
	end
	return weaponManagerRef
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

	print("[ASCEND] CultivationManager Engine Initialized (Celestial Float System).")
end

function CultivationManager.OnPlayerAdded(player: Player)
	if not playerData[player] then
		playerData[player] = {
			Realm = "QiCondensation",
			Order = 1,
			CurrentQi = 0,
			IsMeditating = false,
			IsTribulationActive = false,
			TribulationWave = 0,
			TotalWaves = 0,
		}
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.5)
		CultivationManager.ApplyRealmStats(player)
	end)
end

function CultivationManager.OnPlayerRemoving(player: Player)
	if meditationThreads[player] then
		task.cancel(meditationThreads[player])
		meditationThreads[player] = nil
	end
	if levitationTweens[player] then
		levitationTweens[player]:Cancel()
		levitationTweens[player] = nil
	end
	if tribulationThreads[player] then
		task.cancel(tribulationThreads[player])
		tribulationThreads[player] = nil
	end
	playerData[player] = nil
end

function CultivationManager.GetPlayerData(player: Player): PlayerCultivationData?
	return playerData[player]
end

function CultivationManager.SetPlayerData(player: Player, realm: CultivationConfig.RealmTier, currentQi: number, order: number?)
	playerData[player] = {
		Realm = realm or "QiCondensation",
		Order = math.clamp(order or 1, 1, 9),
		CurrentQi = currentQi or 0,
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

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local maxHp = CultivationConfig.GetOrderMaxHealth(pData.Realm, pData.Order)
		humanoid.MaxHealth = maxHp
		humanoid.Health = math.min(humanoid.Health, maxHp)
	end

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

	pData.IsMeditating = not pData.IsMeditating
	local character = player.Character
	if not character then return end

	local weaponMgr = getWeaponManager()

	if pData.IsMeditating then
		-- Hide weapon when entering meditation
		if weaponMgr and weaponMgr.SetWeaponVisibility then
			weaponMgr.SetWeaponVisibility(player, false)
		end

		CultivationManager.StartCelestialLevitation(player, character, pData.Realm, false)

		meditationThreads[player] = task.spawn(function()
			while pData.IsMeditating and player.Parent and character.Parent do
				local maxQi = CultivationConfig.GetOrderMaxQi(pData.Realm, pData.Order)
				local realmInfo = CultivationConfig[pData.Realm]
				if not realmInfo then break end

				local isRecovering = pData.CurrentQi < maxQi
				local rate = realmInfo.GatherRate * (if isRecovering then realmInfo.RegenMultiplier else 1.0)

				pData.CurrentQi = math.min(maxQi, pData.CurrentQi + (rate * 0.5))
				CultivationManager.SyncClient(player)

				task.wait(0.5)
			end
		end)
	else
		if meditationThreads[player] then
			task.cancel(meditationThreads[player])
			meditationThreads[player] = nil
		end

		-- Restore weapon visibility when exiting meditation
		if weaponMgr and weaponMgr.SetWeaponVisibility then
			weaponMgr.SetWeaponVisibility(player, true)
		end

		CultivationManager.StopCelestialLevitation(player, character)
	end

	CultivationManager.SyncClient(player)
end

-- Inside CultivationManager.StartCelestialLevitation:
function CultivationManager.StartCelestialLevitation(player: Player, character: Model, realm: CultivationConfig.RealmTier, isBreakthrough: boolean)
	CultivationManager.StopCelestialLevitation(player, character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local realmInfo = CultivationConfig[realm]
	local auraColor = if realmInfo then (if isBreakthrough then realmInfo.Tribulation.AuraColor else realmInfo.AuraColor) else Color3.fromRGB(0, 220, 255)

	humanoid.Sit = true
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = auraColor
	highlight.FillTransparency = if isBreakthrough then 0.85 else 0.95
	highlight.OutlineColor = auraColor
	highlight.OutlineTransparency = 0.2
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	local auraPart = Instance.new("Part")
	auraPart.Name = "QiMeditationAura"
	auraPart.Size = Vector3.new(10, 0.2, 10)
	auraPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.8, hrp.Position.Z)
	auraPart.CanCollide = false
	auraPart.Transparency = 1
	auraPart.Anchored = true
	auraPart.Parent = character

	hrp.Anchored = true
	local startY = hrp.Position.Y
	local levitateBaseHeight = if isBreakthrough then 3.2 else 2.0

	-- Step 1: Smooth 1.0s initial ascension to levitation height
	local riseTween = TweenService:Create(hrp, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		CFrame = CFrame.new(hrp.Position.X, startY + levitateBaseHeight, hrp.Position.Z) * hrp.CFrame.Rotation
	})
	riseTween:Play()

	-- Step 2: Slow 3.0s Celestial Sine Floating Loop (0.5 studs up & down)
	riseTween.Completed:Connect(function()
		local pData = playerData[player]
		if pData and pData.IsMeditating and hrp and hrp.Parent then
			local slowFloatInfo = TweenInfo.new(3.0, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
			local slowFloatTween = TweenService:Create(hrp, slowFloatInfo, {
				CFrame = CFrame.new(hrp.Position.X, startY + levitateBaseHeight + 0.5, hrp.Position.Z) * hrp.CFrame.Rotation
			})
			levitationTweens[player] = slowFloatTween
			slowFloatTween:Play()
		end
	end)
end

function CultivationManager.StopCelestialLevitation(player: Player, character: Model)
	if levitationTweens[player] then
		levitationTweens[player]:Cancel()
		levitationTweens[player] = nil
	end

	local aura = character:FindFirstChild("QiMeditationAura")
	if aura then aura:Destroy() end

	local highlight = character:FindFirstChild("QiMeditationHighlight")
	if highlight then highlight:Destroy() end

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if hrp then
		hrp.Anchored = false
	end
	if humanoid then
		humanoid.Sit = false
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
	end
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = playerData[player]
	if not pData or pData.IsTribulationActive then return false end

	local maxQi = CultivationConfig.GetOrderMaxQi(pData.Realm, pData.Order)
	if pData.CurrentQi < maxQi then return false end

	-- Minor Breakthrough (Order 1-8)
	if pData.Order < 9 then
		pData.Order += 1
		CultivationManager.ApplyRealmStats(player)
		CultivationManager.SyncClient(player)
		print(string.format("[CultivationManager] ✨ %s achieved Minor Breakthrough to %s — Order %d!", player.Name, CultivationConfig[pData.Realm].Name, pData.Order))
		return true
	end

	-- Major Breakthrough (Order 9 -> Next Realm Order 1)
	local nextRealm: CultivationConfig.RealmTier? = nil
	if pData.Realm == "QiCondensation" then
		nextRealm = "FoundationEstablishment"
	elseif pData.Realm == "FoundationEstablishment" then
		nextRealm = "GoldenCore"
	elseif pData.Realm == "GoldenCore" then
		nextRealm = "NascentSoul"
	elseif pData.Realm == "NascentSoul" then
		nextRealm = "HeavenlyTribulation"
	end

	if not nextRealm then return false end

	-- Start Heavenly Tribulation Sequence
	pData.IsTribulationActive = true
	local tribulationSpec = CultivationConfig[pData.Realm].Tribulation
	pData.TotalWaves = tribulationSpec.StrikeCount
	pData.TribulationWave = 0

	local character = player.Character
	if not character then
		pData.IsTribulationActive = false
		return false
	end

	CultivationManager.StartCelestialLevitation(player, character, pData.Realm, true)
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
				CultivationManager.StopCelestialLevitation(player, character)
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

			CultivationManager.StopCelestialLevitation(player, character)
			CultivationManager.ApplyRealmStats(player)

			combatActionRemote:FireAllClients(player, "AscensionBurst", {
				AuraColor = CultivationConfig[nextRealm].AuraColor,
			})
		else
			pData.IsTribulationActive = false
			pData.TribulationWave = 0
			CultivationManager.StopCelestialLevitation(player, character)
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

	local maxQi = CultivationConfig.GetOrderMaxQi(pData.Realm, pData.Order)

	local character = player.Character
	if character then
		character:SetAttribute("Qi", pData.CurrentQi)
		character:SetAttribute("MaxQi", maxQi)
		character:SetAttribute("Realm", string.format("%s — Order %d", realmInfo.Name, pData.Order))
	end

	updateCultivationRemote:FireClient(player, {
		RealmName = realmInfo.Name,
		Order = pData.Order,
		CurrentQi = pData.CurrentQi,
		MaxQi = maxQi,
		IsMeditating = pData.IsMeditating,
		IsTribulationActive = pData.IsTribulationActive,
		TribulationWave = pData.TribulationWave,
		TotalWaves = pData.TotalWaves,
		HealthMultiplier = realmInfo.HealthMultiplier,
	})
end

return CultivationManager