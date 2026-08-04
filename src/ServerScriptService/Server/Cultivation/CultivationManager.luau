--!strict
--[[
    CultivationManager.luau
    Server-authoritative cultivation state engine for ASCEND.
    Manages player Qi levels, realm progression, meditation state (Hotkey G),
    Qi absorption loop, character health stat scaling, and Heavenly Tribulation events (Hotkey B).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type PlayerCultivationData = {
	Realm: CultivationConfig.RealmTier,
	CurrentQi: number,
	IsMeditating: boolean,
	IsTribulationActive: boolean,
	TribulationWave: number,
	TotalWaves: number,
}

local CultivationManager = {}

local playerData: { [Player]: PlayerCultivationData } = {}
local meditationThreads: { [Player]: thread } = {}
local tribulationThreads: { [Player]: thread } = {}

local updateCultivationRemote: RemoteEvent
local combatActionRemote: RemoteEvent

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

	print("[ASCEND] CultivationManager Engine Initialized.")
end

function CultivationManager.OnPlayerAdded(player: Player)
	if not playerData[player] then
		playerData[player] = {
			Realm = "QiCondensation",
			CurrentQi = 0,
			IsMeditating = false,
			IsTribulationActive = false,
			TribulationWave = 0,
			TotalWaves = 0,
		}
	end

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
	if tribulationThreads[player] then
		task.cancel(tribulationThreads[player])
		tribulationThreads[player] = nil
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

	CultivationManager.SyncClient(player)
end

function CultivationManager.ToggleMeditation(player: Player)
	local pData = playerData[player]
	if not pData or pData.IsTribulationActive then return end

	pData.IsMeditating = not pData.IsMeditating
	local character = player.Character
	if not character then return end

	if pData.IsMeditating then
		print(string.format("[CultivationManager] %s entered Qi Meditation stance.", player.Name))
		CultivationManager.SpawnMeditationAura(character, pData.Realm, false)

		meditationThreads[player] = task.spawn(function()
			while pData.IsMeditating and player.Parent and character.Parent do
				local realmInfo = CultivationConfig[pData.Realm]
				if not realmInfo then break end

				-- If recovering depleted Qi, apply Fast Regen Multiplier!
				local isRecovering = pData.CurrentQi < realmInfo.MaxQi
				local rate = realmInfo.GatherRate * (if isRecovering then realmInfo.RegenMultiplier else 1.0)

				pData.CurrentQi = math.min(realmInfo.MaxQi, pData.CurrentQi + (rate * 0.5))
				CultivationManager.SyncClient(player)

				if pData.CurrentQi >= realmInfo.MaxQi then
					print(string.format("[CultivationManager] %s at Max Qi capacity (%d/%d)! Ready for Breakthrough ('B')!", player.Name, math.round(pData.CurrentQi), realmInfo.MaxQi))
				end

				task.wait(0.5)
			end
		end)
	else
		if meditationThreads[player] then
			task.cancel(meditationThreads[player])
			meditationThreads[player] = nil
		end
		CultivationManager.RemoveMeditationAura(character)
		print(string.format("[CultivationManager] %s exited Qi Meditation.", player.Name))
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

function CultivationManager.GetDamageMultiplier(player: Player): number
	local pData = playerData[player]
	if not pData then return 1.0 end

	local realmInfo = CultivationConfig[pData.Realm]
	return if realmInfo then realmInfo.DamageMultiplier else 1.0
end

function CultivationManager.AttemptBreakthrough(player: Player): boolean
	local pData = playerData[player]
	if not pData or pData.IsTribulationActive then return false end

	local currentRealmInfo = CultivationConfig[pData.Realm]
	if not currentRealmInfo then return false end

	if pData.CurrentQi < currentRealmInfo.MaxQi then
		warn(string.format("[CultivationManager] %s insufficient Qi for breakthrough! (%d/%d)", player.Name, math.round(pData.CurrentQi), currentRealmInfo.MaxQi))
		return false
	end

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

	-- Cancel normal meditation if running
	if pData.IsMeditating then
		pData.IsMeditating = false
		if meditationThreads[player] then
			task.cancel(meditationThreads[player])
			meditationThreads[player] = nil
		end
	end

	-- Start Heavenly Tribulation Sequence
	pData.IsTribulationActive = true
	local tribulationSpec = currentRealmInfo.Tribulation
	pData.TotalWaves = tribulationSpec.StrikeCount
	pData.TribulationWave = 0

	local character = player.Character
	if not character then
		pData.IsTribulationActive = false
		return false
	end

	CultivationManager.SpawnMeditationAura(character, pData.Realm, true)
	CultivationManager.SyncClient(player)

    tribulationThreads[player] = task.spawn(function()
            print(string.format("[CultivationManager] ⚡ HEAVENLY TRIBULATION STARTED for %s!", player.Name))

            -- Spawn Overhead Storm Cloud
            local stormCloud = CultivationManager.SpawnStormCloud(character, tribulationSpec.AuraColor)

            for wave = 1, tribulationSpec.StrikeCount do
                if not player.Parent or not character.Parent then break end

                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
                if not humanoid or humanoid.Health <= 0 or not hrp then break end

                pData.TribulationWave = wave
                CultivationManager.SyncClient(player)

                local targetPos = hrp.Position + Vector3.new(
                    math.random(-2, 2),
                    0,
                    math.random(-2, 2)
                )

                -- 1. Broadcast warning telegraph to clients
                combatActionRemote:FireAllClients(player, "TribulationTelegraph", {
                    TargetPosition = targetPos,
                    TelegraphTime = tribulationSpec.TelegraphTime,
                    AuraColor = tribulationSpec.AuraColor,
                })

                task.wait(tribulationSpec.TelegraphTime)

                -- Re-check health after windup
                if not humanoid or humanoid.Health <= 0 then break end

                -- 2. Execute Lightning Strike & Damage
                combatActionRemote:FireAllClients(player, "TribulationStrike", {
                    TargetPosition = targetPos,
                    Damage = tribulationSpec.DamagePerStrike,
                    AuraColor = tribulationSpec.AuraColor,
                })

                humanoid:TakeDamage(tribulationSpec.DamagePerStrike)

                if humanoid.Health <= 0 then
                    print(string.format("[CultivationManager] ❌ %s perished during Heavenly Tribulation wave %d!", player.Name, wave))
                    pData.IsTribulationActive = false
                    pData.TribulationWave = 0
                    if stormCloud then stormCloud:Destroy() end
                    CultivationManager.RemoveMeditationAura(character)
                    CultivationManager.SyncClient(player)
                    return
                end

                task.wait(tribulationSpec.StrikeInterval)
            end

            -- Clean up storm cloud
            if stormCloud then stormCloud:Destroy() end

            -- Breakthrough Success Check
            local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				pData.Realm = nextRealm
				-- pData.CurrentQi is PRESERVED naturally (e.g. 100/250 Qi)!
				pData.IsTribulationActive = false
				pData.TribulationWave = 0

				CultivationManager.RemoveMeditationAura(character)
				CultivationManager.ApplyRealmStats(player)

				combatActionRemote:FireAllClients(player, "AscensionBurst", {
					AuraColor = CultivationConfig[nextRealm].AuraColor,
				})

				print(string.format("[CultivationManager] 🔥 HEAVENLY TRIBULATION CONQUERED! %s advanced to %s (Qi Preserved: %d/%d)!", player.Name, CultivationConfig[nextRealm].Name, math.round(pData.CurrentQi), CultivationConfig[nextRealm].MaxQi))
            else
                pData.IsTribulationActive = false
                pData.TribulationWave = 0
                CultivationManager.RemoveMeditationAura(character)
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
	if hrp then
		cloud.Position = hrp.Position + Vector3.new(0, 22, 0)
	end
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

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://24366107" -- Smoke / Dark cloud particle texture
	particles.Rate = 25
	particles.Lifetime = NumberRange.new(1.5, 3.0)
	particles.Speed = NumberRange.new(2, 6)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 8),
		NumberSequenceKeypoint.new(1, 14)
	})
	particles.Color = ColorSequence.new(Color3.fromRGB(30, 30, 40), auraColor)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	particles.Parent = cloud

	return cloud
end

function CultivationManager.SpawnMeditationAura(character: Model, realm: CultivationConfig.RealmTier, isBreakthrough: boolean)
	CultivationManager.RemoveMeditationAura(character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	local realmInfo = CultivationConfig[realm]
	local auraColor = if realmInfo then (if isBreakthrough then realmInfo.Tribulation.AuraColor else realmInfo.AuraColor) else Color3.fromRGB(0, 220, 255)

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
	auraPart.Massless = true
	auraPart.Transparency = 1
	auraPart.Anchored = true

	local light = Instance.new("PointLight")
	light.Range = if isBreakthrough then 24 else 16
	light.Brightness = if isBreakthrough then 6.0 else 4.0
	light.Color = auraColor
	light.Parent = auraPart

	auraPart.Parent = character

	hrp.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y + (if isBreakthrough then 3.5 else 2.2), hrp.Position.Z) * hrp.CFrame.Rotation
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


function CultivationManager.SetPlayerData(player: Player, realm: CultivationConfig.RealmTier, currentQi: number)
	playerData[player] = {
		Realm = realm or "QiCondensation",
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

-- REPLACE function CultivationManager.SyncClient in src/ServerScriptService/Server/Cultivation/CultivationManager.luau with:
function CultivationManager.SyncClient(player: Player)
	local pData = playerData[player]
	if not pData then return end

	local realmInfo = CultivationConfig[pData.Realm]
	if not realmInfo then return end

	-- Update character attributes so OverheadUIController reads real-time stats across all players
	local character = player.Character
	if character then
		character:SetAttribute("Qi", pData.CurrentQi)
		character:SetAttribute("MaxQi", realmInfo.MaxQi)
		character:SetAttribute("Realm", realmInfo.Name)
		character:SetAttribute("Sect", "Azure Cloud Sect")
	end

	updateCultivationRemote:FireClient(player, {
		RealmName = realmInfo.Name,
		CurrentQi = pData.CurrentQi,
		MaxQi = realmInfo.MaxQi,
		IsMeditating = pData.IsMeditating,
		IsTribulationActive = pData.IsTribulationActive,
		TribulationWave = pData.TribulationWave,
		TotalWaves = pData.TotalWaves,
		HealthMultiplier = realmInfo.HealthMultiplier,
	})
end

return CultivationManager