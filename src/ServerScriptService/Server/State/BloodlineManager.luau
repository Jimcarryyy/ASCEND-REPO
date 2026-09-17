--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)

local BloodlineManager = {}
local bloodlineRemote: RemoteEvent

local TIER_RANK = {
	Common = 1,
	Rare = 2,
	Legendary = 3,
	Mythic = 4,
}

-- All relics float around the cultivator. No relics are directly embedded into the skin.
local ARTIFACT_OFFSETS: { [string]: CFrame } = {
	-- Floating Top-Left Shoulder Orbs (Pushed out and lifted for true floating clearance)
	JadeLotusOrb = CFrame.new(-1.65, 2.25, 0.10),
	CosmicVoidSphere = CFrame.new(-1.65, 2.25, 0.10),

	-- Floating Back Halos & Wings (Clean air gap behind UpperTorso)
	AsuraBloodWheelHalo = CFrame.new(0, 0.45, 1.25),
	EightBladeCelestialHalo = CFrame.new(0, 0.50, 1.20),
	GlacialPhoenixCrest = CFrame.new(0, 0.45, 1.15),
	NineNetherSoulHalo = CFrame.new(0, 0.45, 1.25),
	PrimordialDragonWings = CFrame.new(0, 0.38, 0.95),
	ThunderSpineNeedles = CFrame.new(0, 0.30, 0.85),

	-- Placeholders (Kept for future floating redesign)
	IronRootCore = CFrame.new(0, 0.20, -0.75),
	SteelMeridianGlow = CFrame.new(0.85, 0.30, 0.20),
	WindGaleAnklets = CFrame.new(0, -0.40, 0.30),
	AzureDragonBracer = CFrame.new(1.65, 2.25, 0.10),
}

local function deductSpins(player: Player, count: number): boolean
	local current = PlayerDataManager.GetBloodlineSpins(player)
	if current < count then
		return false
	end

	local pdm = PlayerDataManager :: any
	if type(pdm.UseBloodlineSpin) == "function" then
		for _ = 1, count do
			pdm.UseBloodlineSpin(player)
		end
		return true
	elseif type(pdm.RemoveBloodlineSpins) == "function" then
		pdm.RemoveBloodlineSpins(player, count)
		return true
	elseif type(pdm.AddBloodlineSpins) == "function" then
		pdm.AddBloodlineSpins(player, -count)
		return true
	end

	return false
end

local function attachVisualArtifact(character: Model, artifactMeshName: string?, targetPartName: string?, auraColor: Color3?)
	local oldArtifact = character:FindFirstChild("BloodlineArtifact")
	if oldArtifact then
		oldArtifact:Destroy()
	end

	if not artifactMeshName or artifactMeshName == "" then return end

	-- All floating relics anchor relative to UpperTorso for stable, non-flailing orbit
	local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") :: BasePart?
	if not upperTorso then return end

	local RS = ReplicatedStorage
	local bloodlineFolder = RS:FindFirstChild("Bloodlines")
		or (RS:FindFirstChild("Assets") and RS.Assets:FindFirstChild("Bloodlines"))
	local modelPrefab = bloodlineFolder and bloodlineFolder:FindFirstChild(artifactMeshName) :: Model?

	if modelPrefab then
		local clone = modelPrefab:Clone()
		clone.Name = "BloodlineArtifact"
		local primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart")
		if primary then
			for _, desc in ipairs(clone:GetDescendants()) do
				if desc:IsA("BasePart") then
					desc.Anchored = false
					desc.CanCollide = false
					desc.Massless = true
				end
			end

			local offset = ARTIFACT_OFFSETS[artifactMeshName] or CFrame.new(0, 0.45, 1.20)
			primary.CFrame = upperTorso.CFrame * offset

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = upperTorso
			weld.Part1 = primary
			weld.Parent = primary

			if auraColor then
				local light = Instance.new("PointLight")
				light.Name = "AuraLight"
				light.Color = auraColor
				light.Range = 8
				light.Brightness = 2.0
				light.Parent = primary

				local particles = Instance.new("ParticleEmitter")
				particles.Name = "AuraParticles"
				particles.LightEmission = 1
				particles.Color = ColorSequence.new(auraColor)
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.15),
					NumberSequenceKeypoint.new(0.5, 0.35),
					NumberSequenceKeypoint.new(1, 0),
				})
				particles.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.8),
					NumberSequenceKeypoint.new(0.5, 0.3),
					NumberSequenceKeypoint.new(1, 1),
				})
				particles.Rate = 12
				particles.Lifetime = NumberRange.new(1.2, 2.0)
				particles.Speed = NumberRange.new(1, 2)
				particles.SpreadAngle = Vector2.new(30, 30)
				particles.Acceleration = Vector3.new(0, 1.5, 0)
				particles.Parent = primary
			end
		end
		clone.Parent = character
	end
end

local function sendState(player: Player)
	local bloodlineId = PlayerDataManager.GetBloodline(player) or "MortalSwordBone"
	local def = BloodlineConfig.GetBloodline(bloodlineId)
	bloodlineRemote:FireClient(player, {
		Action = "StateUpdate",
		BloodlineId = bloodlineId,
		DisplayName = def and def.Name or "Mortal Sword Meridians",
		Rarity = def and def.Tier or "Common",
		Description = def and def.Description or "Base physical meridians. Awaken at the altar to inherit ancestral arts.",
		Passives = def and def.Passives or {},
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
	})
end

function BloodlineManager.ProcessSpin(player: Player)
	local success = deductSpins(player, 1)
	if not success then
		bloodlineRemote:FireClient(player, {
			Action = "SpinFailed",
			Message = "No Awakening Beads remaining! Offer Spirit Stones (500) to condense beads.",
		})
		return
	end

	local bloodlineId = BloodlineConfig.RollBloodline()
	local rolledDef = BloodlineConfig.GetBloodline(bloodlineId)
	if not rolledDef then return end

	PlayerDataManager.SetBloodline(player, rolledDef.Id)

	if player.Character and rolledDef.VisualArtifact then
		attachVisualArtifact(
			player.Character,
			rolledDef.VisualArtifact.ArtifactName,
			rolledDef.VisualArtifact.AttachmentPoint,
			rolledDef.VisualArtifact.AuraColor
		)
	end

	bloodlineRemote:FireClient(player, {
		Action = "SpinResult",
		BloodlineId = rolledDef.Id,
		DisplayName = rolledDef.Name,
		Rarity = rolledDef.Tier,
		Description = rolledDef.Description,
		Passives = rolledDef.Passives,
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
	})
end

function BloodlineManager.Process10xSpin(player: Player)
	local success = deductSpins(player, 10)
	if not success then
		local currentSpins = PlayerDataManager.GetBloodlineSpins(player)
		bloodlineRemote:FireClient(player, {
			Action = "SpinFailed",
			Message = string.format("Insufficient Beads for 10x Ritual! Need 10 (Have %d).", currentSpins),
		})
		return
	end

	local bestDef: any = nil
	local bestRank = 0

	for _ = 1, 10 do
		local rollId = BloodlineConfig.RollBloodline()
		local def = BloodlineConfig.GetBloodline(rollId)
		if def then
			local rank = TIER_RANK[def.Tier] or 1
			if rank > bestRank then
				bestRank = rank
				bestDef = def
			end
		end
	end

	if bestDef then
		PlayerDataManager.SetBloodline(player, bestDef.Id)

		if player.Character and bestDef.VisualArtifact then
			attachVisualArtifact(
				player.Character,
				bestDef.VisualArtifact.ArtifactName,
				bestDef.VisualArtifact.AttachmentPoint,
				bestDef.VisualArtifact.AuraColor
			)
		end

		bloodlineRemote:FireClient(player, {
			Action = "SpinResult",
			BloodlineId = bestDef.Id,
			DisplayName = bestDef.Name,
			Rarity = bestDef.Tier,
			Description = bestDef.Description,
			Passives = bestDef.Passives,
			RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
			RemainingStones = PlayerDataManager.GetSpiritStones(player),
		})
	end
end

function BloodlineManager.ExchangeSpins(player: Player, amount: number?)
	local count = math.clamp(math.floor(tonumber(amount) or 1), 1, 10)
	local cost = count * 500

	local currentStones = PlayerDataManager.GetSpiritStones(player)
	if currentStones < cost then
		bloodlineRemote:FireClient(player, {
			Action = "ExchangeFailed",
			Message = string.format("Insufficient Spirit Stones! Need %d (Have %d).", cost, currentStones),
		})
		return
	end

	local success = PlayerDataManager.RemoveSpiritStones(player, cost)
	if not success then return end

	PlayerDataManager.AddBloodlineSpins(player, count)
	sendState(player)
end

function BloodlineManager.Init()
	bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction")

	bloodlineRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "GetState" then
			sendState(player)
		elseif payload.Action == "Spin" then
			BloodlineManager.ProcessSpin(player)
		elseif payload.Action == "Spin10x" then
			BloodlineManager.Process10xSpin(player)
		elseif payload.Action == "ExchangeSpins" then
			BloodlineManager.ExchangeSpins(player, payload.Amount)
		end
	end)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(1.0)
			local bloodlineId = PlayerDataManager.GetBloodline(player)
			if bloodlineId then
				local def = BloodlineConfig.GetBloodline(bloodlineId)
				if def and def.VisualArtifact then
					attachVisualArtifact(
						char,
						def.VisualArtifact.ArtifactName,
						def.VisualArtifact.AttachmentPoint,
						def.VisualArtifact.AuraColor
					)
				end
			end
		end)
	end)

	print("[BloodlineManager] Initialized successfully.")
end

return BloodlineManager