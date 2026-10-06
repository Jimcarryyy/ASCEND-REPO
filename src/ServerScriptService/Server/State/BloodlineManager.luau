--!strict
--[[
    BloodlineManager.luau
    Location: src/ServerScriptService/Server/State/BloodlineManager.luau
    Server-authoritative Bloodline manager:
    - 5-Tier Lineage Gacha with Bad-Luck Pity (Guaranteed Legendary @ 30)
    - Top-Left Shoulder Spiritual Orb Welder (Matches Reference Rig)
    - Clean Aesthetic: PointLight Illumination with Zero Particle VFX
    - Meridian Vault Slots (Store, swap, and unlock multiple lineages)
    - Resilient 3D Relic Welder: Supports Models, single MeshParts, R6 & R15 rigs
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
	Common    = 1,
	Uncommon  = 2,
	Rare      = 3,
	Epic      = 4,
	Legendary = 5,
}

local LEGENDARY_PITY_THRESHOLD = 30
local DISCARD_REFUND_STONES = 100
local SLOT_3_STONE_COST = 25000

local pendingRolls: { [Player]: BloodlineConfig.BloodlineDefinition } = {}

-- Calibrated Top-Left Shoulder Hover CFrame (Matches Reference Rig)
local DEFAULT_ORB_OFFSET = CFrame.new(-1.65, 1.75, 0.1)

local ARTIFACT_OFFSETS: { [string]: CFrame } = {
	["Mortal Steel Vein"]             = DEFAULT_ORB_OFFSET,
	["Spirit Iron Sword-Bone"]       = DEFAULT_ORB_OFFSET,
	["Gale-Jade Sword-Vein"]         = DEFAULT_ORB_OFFSET,
	["JadeLotusOrb"]                 = DEFAULT_ORB_OFFSET,
	["Thunder-Severing Sword-Heart"] = DEFAULT_ORB_OFFSET,
	["Heavy-Crag Sword-Marrow"]      = DEFAULT_ORB_OFFSET,
	["CosmicVoidSphere"]             = DEFAULT_ORB_OFFSET,
	["Innate Sovereign Sword-Bone"]  = DEFAULT_ORB_OFFSET,
	["Ghost-Shadow Sword-Pulse"]     = DEFAULT_ORB_OFFSET,
	["Scarlet-Lotus Blade-Bone"]     = DEFAULT_ORB_OFFSET,
}

local function NormalizeKey(name: string): string
	return name:gsub("[%s%-_.]+", ""):lower()
end

local function FindBloodlinePrefab(artifactMeshName: string): Instance?
	local RS = ReplicatedStorage
	local bloodlineFolder = RS:FindFirstChild("Bloodlines")
		or RS:FindFirstChild("Bloodline")
		or (RS:FindFirstChild("Assets") and (RS.Assets:FindFirstChild("Bloodlines") or RS.Assets:FindFirstChild("Bloodline")))

	if not bloodlineFolder then return nil end

	local searchFolders: { Folder } = {}
	local newBloodlines = bloodlineFolder:FindFirstChild("NewBloodlines") :: Folder?
	if newBloodlines and newBloodlines:IsA("Folder") then
		table.insert(searchFolders, newBloodlines)
	end
	table.insert(searchFolders, bloodlineFolder)

	for _, folder in ipairs(searchFolders) do
		local exact = folder:FindFirstChild(artifactMeshName)
		if exact then return exact end
	end

	local targetNorm = NormalizeKey(artifactMeshName)
	for _, folder in ipairs(searchFolders) do
		for _, child in ipairs(folder:GetChildren()) do
			if NormalizeKey(child.Name) == targetNorm then
				return child
			end
		end
	end

	return nil
end

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

	local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso") :: BasePart?
	if not torso then return end

	local prefab = FindBloodlinePrefab(artifactMeshName)
	if not prefab then
		warn(string.format("[BloodlineManager] 3D Model '%s' missing from ReplicatedStorage.Bloodlines!", artifactMeshName))
		return
	end

	local clone = prefab:Clone()
	clone.Name = "BloodlineArtifact"

	local primary: BasePart? = nil
	if clone:IsA("Model") then
		primary = clone.PrimaryPart or clone:FindFirstChildWhichIsA("BasePart", true)
		if not clone.PrimaryPart and primary then
			clone.PrimaryPart = primary
		end
	elseif clone:IsA("BasePart") then
		primary = clone
	end

	if not primary then
		warn(string.format("[BloodlineManager] Artifact '%s' has no BasePart or MeshPart to weld!", artifactMeshName))
		clone:Destroy()
		return
	end

	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = false
			desc.CanCollide = false
			desc.Massless = true
		elseif desc:IsA("ParticleEmitter") or desc:IsA("Trail") then
			desc:Destroy() -- Clean: No VFX per design
		end
	end
	if clone:IsA("BasePart") then
		clone.Anchored = false
		clone.CanCollide = false
		clone.Massless = true
	end

	local offset = ARTIFACT_OFFSETS[artifactMeshName] or DEFAULT_ORB_OFFSET
	primary.CFrame = torso.CFrame * offset

	for _, child in ipairs(primary:GetChildren()) do
		if child:IsA("Weld") or child:IsA("WeldConstraint") or child:IsA("Motor6D") then
			child:Destroy()
		end
	end

	local weld = Instance.new("Weld")
	weld.Name = "OrbWeld"
	weld.Part0 = torso
	weld.Part1 = primary
	weld.C0 = offset
	weld.C1 = CFrame.identity
	weld.Parent = primary

	if auraColor then
		local light = primary:FindFirstChild("OrbLight") :: PointLight?
		if not light then
			light = Instance.new("PointLight")
			light.Name = "OrbLight"
			light.Parent = primary
		end
		light.Color = auraColor
		light.Range = 8
		light.Brightness = 1.6
		light.Shadows = false
	end

	clone.Parent = character
end

local function sendState(player: Player)
	local bloodlineId = PlayerDataManager.GetBloodline(player) or "MortalSteelVein"
	local def = BloodlineConfig.GetBloodline(bloodlineId)
	local slots = PlayerDataManager.GetBloodlineSlots(player)
	local maxSlots = PlayerDataManager.GetMaxBloodlineSlots(player)
	local pity = PlayerDataManager.GetBloodlinePity(player)
	local pending = pendingRolls[player]

	bloodlineRemote:FireClient(player, {
		Action = "StateUpdate",
		BloodlineId = bloodlineId,
		DisplayName = def and def.Name or "Mortal Steel Vein",
		Rarity = def and def.Tier or "Common",
		Description = def and def.Description or "Mundane physical meridians. Awaken at the altar to inherit ancestral arts.",
		Passives = def and def.Passives or {},
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
		RemainingStones = PlayerDataManager.GetSpiritStones(player),
		Slots = slots,
		MaxSlots = maxSlots,
		LegendaryPity = pity.SpinsSinceLegendary,
		PendingRoll = pending and {
			Id = pending.Id,
			DisplayName = pending.Name,
			Rarity = pending.Tier,
			Description = pending.Description,
			Passives = pending.Passives,
		} or nil,
	})
end

local function rollSingleWithPity(player: Player): (string, BloodlineConfig.BloodlineDefinition)
	local pity = PlayerDataManager.IncrementBloodlinePity(player)
	local forcedTier: BloodlineConfig.BloodlineTier? = nil

	if pity.SpinsSinceLegendary >= LEGENDARY_PITY_THRESHOLD then
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

	local rolledDef = BloodlineConfig.GetBloodline(rolledId) or BloodlineConfig.GetBloodline("MortalSteelVein") :: BloodlineConfig.BloodlineDefinition

	if rolledDef.Tier == "Legendary" then
		PlayerDataManager.ResetBloodlinePity(player, "Legendary")
	end

	return rolledId, rolledDef
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
		})
	end
end

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

function BloodlineManager.UnlockSlot(player: Player, slotIndex: number)
	local currentMax = PlayerDataManager.GetMaxBloodlineSlots(player)
	if slotIndex ~= currentMax + 1 or slotIndex > 5 then return end

	if slotIndex == 2 then
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

	print("[BloodlineManager] Master Gacha & Top-Left Shoulder Welder Initialized.")
end

return BloodlineManager