--!strict
--[[
    BloodlineManager.luau
    Location: src/ServerScriptService/Server/State/BloodlineManager.luau
    Server-authoritative Bloodline manager:
    - 12-Lineage Gacha with Bad-Luck Pity (Guaranteed Legendary @ 30, Mythic @ 100)
    - Keep or Discard Decision Pipeline (Refunds unrefined stones on discard)
    - Meridian Vault Slots (Store, swap, and unlock multiple lineages)
    - Dynamic Floating 3D Relic Welder with Sacred Aura Lighting & Particle Motes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

local BloodlineManager = {}
local bloodlineRemote: RemoteEvent

local TIER_RANK: { [BloodlineConfig.BloodlineTier]: number } = {
	Common = 1,
	Rare = 2,
	Legendary = 3,
	Mythic = 4,
}

local LEGENDARY_PITY_THRESHOLD = 30
local MYTHIC_PITY_THRESHOLD = 100
local DISCARD_REFUND_STONES = 100
local SLOT_3_STONE_COST = 25000

-- In-memory pending roll storage for the Keep/Discard decision
local pendingRolls: { [Player]: BloodlineConfig.BloodlineDefinition } = {}

-- All relics float around the cultivator with calibrated air gaps
local ARTIFACT_OFFSETS: { [string]: CFrame } = {
	-- Floating Top-Left Shoulder Orbs (Clean clearance, ear/shoulder level)
	JadeLotusOrb = CFrame.new(-1.65, 2.25, 0.10),
	CosmicVoidSphere = CFrame.new(-1.65, 2.25, 0.10),

	-- Floating Back Halos & Wings (Clean air gap behind UpperTorso)
	AsuraBloodWheelHalo = CFrame.new(0, 0.45, 1.25),
	EightBladeCelestialHalo = CFrame.new(0, 0.50, 1.20),
	GlacialPhoenixCrest = CFrame.new(0, 0.45, 1.15),
	NineNetherSoulHalo = CFrame.new(0, 0.45, 1.25),
	PrimordialDragonWings = CFrame.new(0, 0.38, 0.95),
	ThunderSpineNeedles = CFrame.new(0, 0.30, 0.85),

	-- Placeholders
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

-- Full State Sync: includes active bloodline, slots, pity counters, and pending rolls
local function sendState(player: Player)
	local bloodlineId = PlayerDataManager.GetBloodline(player) or "MortalSwordBone"
	local def = BloodlineConfig.GetBloodline(bloodlineId)
	local slots = PlayerDataManager.GetBloodlineSlots(player)
	local maxSlots = PlayerDataManager.GetMaxBloodlineSlots(player)
	local pity = PlayerDataManager.GetBloodlinePity(player)
	local pending = pendingRolls[player]

	bloodlineRemote:FireClient(player, {
		Action = "StateUpdate",
		BloodlineId = bloodlineId,
		DisplayName = def and def.Name or "Mortal Sword Meridians",
		Rarity = def and def.Tier or "Common",
		Description = def and def.Description or "Base physical meridians. Awaken at the altar to inherit ancestral arts.",
		Passives = def and def.Passives or {},
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
		Slots = slots,
		MaxSlots = maxSlots,
		LegendaryPity = pity.SpinsSinceLegendary,
		MythicPity = pity.SpinsSinceMythic,
		PendingRoll = pending and {
			Id = pending.Id,
			DisplayName = pending.Name,
			Rarity = pending.Tier,
			Description = pending.Description,
			Passives = pending.Passives,
		} or nil,
	})
end

-- Pity-Enforced Single Roll Resolution
local function rollSingleWithPity(player: Player): (string, BloodlineConfig.BloodlineDefinition)
	local pity = PlayerDataManager.IncrementBloodlinePity(player)
	local forcedTier: BloodlineConfig.BloodlineTier? = nil

	if pity.SpinsSinceMythic >= MYTHIC_PITY_THRESHOLD then
		forcedTier = "Mythic"
	elseif pity.SpinsSinceLegendary >= LEGENDARY_PITY_THRESHOLD then
		forcedTier = "Legendary"
	end

	local rolledId: string
	if forcedTier then
		local candidates = {}
		for id, def in pairs(BloodlineConfig.GetAllBloodlines()) do
			if def.Tier == forcedTier then
				table.insert(candidates, id)
			end
		end
		rolledId = candidates[math.random(1, #candidates)]
	else
		rolledId = BloodlineConfig.RollBloodline()
	end

	local rolledDef = BloodlineConfig.GetBloodline(rolledId) or BloodlineConfig.GetBloodline("MortalSwordBone") :: BloodlineConfig.BloodlineDefinition

	-- Reset pity when a tier is hit
	if rolledDef.Tier == "Mythic" then
		PlayerDataManager.ResetBloodlinePity(player, "Mythic")
	elseif rolledDef.Tier == "Legendary" then
		PlayerDataManager.ResetBloodlinePity(player, "Legendary")
	end

	return rolledId, rolledDef
end

-- Single Spin
function BloodlineManager.ProcessSpin(player: Player)
	local success = deductSpins(player, 1)
	if not success then
		bloodlineRemote:FireClient(player, {
			Action = "SpinFailed",
			Message = "No Awakening Beads remaining! Offer Spirit Stones (500) to condense beads.",
		})
		return
	end

	local rolledId, rolledDef = rollSingleWithPity(player)
	pendingRolls[player] = rolledDef

	local pity = PlayerDataManager.GetBloodlinePity(player)

	bloodlineRemote:FireClient(player, {
		Action = "RollDecide",
		BloodlineId = rolledId,
		DisplayName = rolledDef.Name,
		Rarity = rolledDef.Tier,
		Description = rolledDef.Description,
		Passives = rolledDef.Passives,
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
		LegendaryPity = pity.SpinsSinceLegendary,
		MythicPity = pity.SpinsSinceMythic,
	})
end

-- 10x Ritual Spin
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
		local _, def = rollSingleWithPity(player)
		local rank = TIER_RANK[def.Tier] or 1
		if rank > bestRank then
			bestRank = rank
			bestDef = def
		end
	end

	if bestDef then
		pendingRolls[player] = bestDef
		local pity = PlayerDataManager.GetBloodlinePity(player)

		bloodlineRemote:FireClient(player, {
			Action = "RollDecide",
			BloodlineId = bestDef.Id,
			DisplayName = bestDef.Name,
			Rarity = bestDef.Tier,
			Description = bestDef.Description,
			Passives = bestDef.Passives,
			RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
			RemainingStones = PlayerDataManager.GetSpiritStones(player),
			LegendaryPity = pity.SpinsSinceLegendary,
			MythicPity = pity.SpinsSinceMythic,
		})
	end
end

-- Decision: Claim / Equip Pending Roll
function BloodlineManager.ClaimRoll(player: Player, targetSlot: number?)
	local pending = pendingRolls[player]
	if not pending then
		bloodlineRemote:FireClient(player, { Action = "ActionFailed", Message = "No pending awakening roll to claim!" })
		return
	end

	local slotIdx = math.clamp(targetSlot or 1, 1, PlayerDataManager.GetMaxBloodlineSlots(player))
	PlayerDataManager.SaveBloodlineToSlot(player, slotIdx, pending.Id)

	if slotIdx == 1 then
		PlayerDataManager.SetBloodline(player, pending.Id)
		if player.Character and pending.VisualArtifact then
			attachVisualArtifact(
				player.Character,
				pending.VisualArtifact.ArtifactName,
				pending.VisualArtifact.AttachmentPoint,
				pending.VisualArtifact.AuraColor
			)
		end
	end

	pendingRolls[player] = nil
	sendState(player)
	print(string.format("[BloodlineManager] %s claimed %s into Meridian Slot %d.", player.Name, pending.Name, slotIdx))
end

-- Decision: Discard Pending Roll (Refunds unrefined stones)
function BloodlineManager.DiscardRoll(player: Player)
	local pending = pendingRolls[player]
	if not pending then return end

	pendingRolls[player] = nil
	PlayerDataManager.AddSpiritStones(player, DISCARD_REFUND_STONES)

	bloodlineRemote:FireClient(player, {
		Action = "RollDiscarded",
		RefundedStones = DISCARD_REFUND_STONES,
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
	})
	sendState(player)
	print(string.format("[BloodlineManager] %s discarded roll and reclaimed %d Spirit Stones.", player.Name, DISCARD_REFUND_STONES))
end

-- Meridian Slot Management: Equip From Slot
function BloodlineManager.EquipSlot(player: Player, slotIndex: number)
	local maxSlots = PlayerDataManager.GetMaxBloodlineSlots(player)
	if slotIndex < 1 or slotIndex > maxSlots then return end

	local success = PlayerDataManager.EquipBloodlineFromSlot(player, slotIndex)
	if not success then return end

	local activeId = PlayerDataManager.GetBloodline(player)
	local def = BloodlineConfig.GetBloodline(activeId)
	if player.Character and def and def.VisualArtifact then
		attachVisualArtifact(
			player.Character,
			def.VisualArtifact.ArtifactName,
			def.VisualArtifact.AttachmentPoint,
			def.VisualArtifact.AuraColor
		)
	end

	sendState(player)
	print(string.format("[BloodlineManager] %s switched active lineage to Slot %d (%s).", player.Name, slotIndex, activeId))
end

-- Meridian Slot Management: Unlock Higher Slots
function BloodlineManager.UnlockSlot(player: Player, slotIndex: number)
	local currentMax = PlayerDataManager.GetMaxBloodlineSlots(player)
	if slotIndex ~= currentMax + 1 or slotIndex > 3 then return end

	if slotIndex == 2 then
		-- Slot 2 Requirement: Reach Foundation Establishment
		local cultivation = CultivationManager.GetPlayerData(player)
		local realm = cultivation and cultivation.Realm or "QiCondensation"
		if realm == "QiCondensation" then
			bloodlineRemote:FireClient(player, {
				Action = "ActionFailed",
				Message = "Meridian Slot 2 unlocks upon reaching Foundation Establishment realm!",
			})
			return
		end
		PlayerDataManager.SetMaxBloodlineSlots(player, 2)

	elseif slotIndex == 3 then
		-- Slot 3 Requirement: 25,000 Spirit Stones
		local currentStones = PlayerDataManager.GetSpiritStones(player)
		if currentStones < SLOT_3_STONE_COST then
			bloodlineRemote:FireClient(player, {
				Action = "ActionFailed",
				Message = string.format("Insufficient Spirit Stones for Slot 3! Need %d (Have %d).", SLOT_3_STONE_COST, currentStones),
			})
			return
		end
		PlayerDataManager.RemoveSpiritStones(player, SLOT_3_STONE_COST)
		PlayerDataManager.SetMaxBloodlineSlots(player, 3)
	end

	sendState(player)
	print(string.format("[BloodlineManager] %s successfully unlocked Meridian Slot %d!", player.Name, slotIndex))
end

-- Currency Exchange
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
		elseif payload.Action == "ClaimRoll" then
			BloodlineManager.ClaimRoll(player, payload.TargetSlot)
		elseif payload.Action == "DiscardRoll" then
			BloodlineManager.DiscardRoll(player)
		elseif payload.Action == "EquipSlot" then
			BloodlineManager.EquipSlot(player, payload.SlotIndex)
		elseif payload.Action == "UnlockSlot" then
			BloodlineManager.UnlockSlot(player, payload.SlotIndex)
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

	Players.PlayerRemoving:Connect(function(player)
		pendingRolls[player] = nil
	end)

	print("[BloodlineManager] Master Gacha, Pity & Meridian Vault Server Engine Initialized.")
end

return BloodlineManager