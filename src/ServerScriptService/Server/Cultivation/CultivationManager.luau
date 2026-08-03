--!strict
--[[
    CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND.
    Manages player Qi levels, realm progression, meditation state (Hotkey G),
    Qi absorption loop, and character health stat scaling.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerCultivationData = {
	Realm: CultivationConfig.RealmTier,
	CurrentQi: number,
	IsMeditating: boolean,
}

local CultivationManager = {}

-- Player Cultivation Data Storage: [Player] -> PlayerCultivationData
local playerData: { [Player]: PlayerCultivationData } = {}
local meditationThreads: { [Player]: thread } = {}

local updateCultivationRemote: RemoteEvent

function CultivationManager.Init()
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	Players.PlayerAdded:Connect(CultivationManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CultivationManager.OnPlayerRemoving)

	for _, player in ipairs(Players:GetPlayers()) do
		CultivationManager.OnPlayerAdded(player)
	end

	-- Handle client network requests
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "table" then
			if payload.ToggleMeditation then
				CultivationManager.ToggleMeditation(player)
			elseif payload.RequestBreakthrough then
				CultivationManager.AttemptBreakthrough(player)
			end
		end
	end)

	print("[ASCEND] CultivationManager Engine Initialized.")
end

function CultivationManager.OnPlayerAdded(player: Player)
	playerData[player] = {
		Realm = "QiCondensation",
		CurrentQi = 0,
		IsMeditating = false,
	}

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5)
		CultivationManager.ApplyRealmStats(player)
	end)
end

function CultivationManager.OnPlayerRemoving(player: Player)
	if meditationThreads[player] then
		task.cancel(meditationThreads[player])
		meditationThreads[player] = nil
	end
	playerData[player] = nil
end

function CultivationManager.GetPlayerData(player: Player): PlayerCultivationData?
	return playerData[player]
end

function CultivationManager.ApplyRealmStats(player: Player)
	local pData = playerData[player]
	if not pData then return end

	local realmInfo = CultivationConfig[pData.Realm]
	if not realmInfo then return end

	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local baseHealth = 100
		humanoid.MaxHealth = baseHealth * realmInfo.HealthMultiplier
		humanoid.Health = humanoid.MaxHealth
	end

	-- Sync cultivation data to client
	CultivationManager.SyncClient(player)
end

function CultivationManager.ToggleMeditation(player: Player)
	local pData = playerData[player]
	if not pData then return end

	pData.IsMeditating = not pData.IsMeditating

	local character = player.Character
	if not character then return end

	if pData.IsMeditating then
		-- Start Qi Gathering Meditation Loop
		print(string.format("[CultivationManager] %s entered Qi Meditation stance.", player.Name))
		CultivationManager.SpawnMeditationAura(character, pData.Realm)

		meditationThreads[player] = task.spawn(function()
			while pData.IsMeditating and player.Parent and character.Parent do
				local realmInfo = CultivationConfig[pData.Realm]
				if not realmInfo then break end

				-- Absorb Qi from atmosphere
				pData.CurrentQi = math.min(realmInfo.MaxQi, pData.CurrentQi + (realmInfo.GatherRate * 0.5))
				CultivationManager.SyncClient(player)

				print(string.format("[CultivationManager] %s Gathering Qi... (%d/%d)", player.Name, math.round(pData.CurrentQi), realmInfo.MaxQi))

				if pData.CurrentQi >= realmInfo.MaxQi then
					print(string.format("[CultivationManager] %s reached Max Qi for %s! Press 'B' for Breakthrough!", player.Name, realmInfo.Name))
				end

				task.wait(0.5)
			end
		end)
	else
		-- Stop Meditation
		if meditationThreads[player] then
			task.cancel(meditationThreads[player])
			meditationThreads[player] = nil
		end

		CultivationManager.RemoveMeditationAura(character)
		print(string.format("[CultivationManager] %s exited Qi Meditation.", player.Name))
	end

	CultivationManager.SyncClient(player)
end

function CultivationManager.SpawnMeditationAura(character: Model, realm: CultivationConfig.RealmTier)
	CultivationManager.RemoveMeditationAura(character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local realmInfo = CultivationConfig[realm]
	local auraColor = if realmInfo then realmInfo.AuraColor else Color3.fromRGB(0, 220, 255)

	-- Lock server character movement
	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	-- 1. Lightweight Body Glow Wrap (Face & clothes stay visible, delicate glowing border)
	local highlight = Instance.new("Highlight")
	highlight.Name = "QiMeditationHighlight"
	highlight.Adornee = character
	highlight.FillColor = auraColor
	highlight.FillTransparency = 0.95 -- 95% transparent fill so clothing & face stay crisp
	highlight.OutlineColor = auraColor
	highlight.OutlineTransparency = 0.25 -- Delicate glowing outline
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = character

	-- 2. Clean Floor Light Ring
	local auraPart = Instance.new("Part")
	auraPart.Name = "QiMeditationAura"
	auraPart.Size = Vector3.new(8, 0.2, 8)
	auraPart.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y - 2.8, hrp.Position.Z)
	auraPart.CanCollide = false
	auraPart.Massless = true
	auraPart.Transparency = 1
	auraPart.Anchored = true

	local light = Instance.new("PointLight")
	light.Range = 16
	light.Brightness = 4.0
	light.Color = auraColor
	light.Parent = auraPart

	auraPart.Parent = character

	-- 3. Anchor HRP at fixed steady hover height (No bobbing/jitter)
	hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + 2.2, hrp.Position.Z) * hrp.CFrame.Rotation
	hrp.Anchored = true
end

function CultivationManager.RemoveMeditationAura(character: Model)
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
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
	end
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = playerData[player]
	if not pData then return false end

	local currentRealmInfo = CultivationConfig[pData.Realm]
	if not currentRealmInfo then return false end

	if pData.CurrentQi < currentRealmInfo.MaxQi then
		warn(string.format("[CultivationManager] %s insufficient Qi for breakthrough! (%d/%d)", player.Name, math.round(pData.CurrentQi), currentRealmInfo.MaxQi))
		return false
	end

	-- Advance Realm
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

	if not nextRealm then
		warn(string.format("[CultivationManager] %s is already at max realm!", player.Name))
		return false
	end

	pData.Realm = nextRealm
	pData.CurrentQi = 0
	pData.IsMeditating = false

	if player.Character then
		CultivationManager.RemoveMeditationAura(player.Character)
	end

	CultivationManager.ApplyRealmStats(player)
	print(string.format("[CultivationManager] 🔥 BREAKTHROUGH SUCCESS! %s advanced to %s! (Health Multiplier: %.1fx)", player.Name, CultivationConfig[nextRealm].Name, CultivationConfig[nextRealm].HealthMultiplier))
	return true
end

function CultivationManager.SyncClient(player: Player)
	local pData = playerData[player]
	if not pData then return end

	local realmInfo = CultivationConfig[pData.Realm]
	if not realmInfo then return end

	updateCultivationRemote:FireClient(player, {
		RealmName = realmInfo.Name,
		CurrentQi = pData.CurrentQi,
		MaxQi = realmInfo.MaxQi,
		IsMeditating = pData.IsMeditating,
		HealthMultiplier = realmInfo.HealthMultiplier,
	})
end

return CultivationManager