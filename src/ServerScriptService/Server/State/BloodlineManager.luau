--!strict
--[[
    BloodlineManager.luau
    Location: src/ServerScriptService/Server/State/BloodlineManager.luau
    Server-authoritative Bloodline manager for ASCEND:
      - Validates and consumes Bloodline spins
      - Executes weighted RNG rolls via BloodlineConfig
      - Attaches physical 3D bloodline artifacts to character UpperTorso
      - Exchanges Spirit Stones for extra bloodline spins
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)

local BloodlineManager = {}
local bloodlineRemote: RemoteEvent

local SPIN_STONE_COST = 500 -- 500 Spirit Stones per Bloodline Spin

local function AttachVisualArtifact(character: Model, artifactMeshName: string)
	local oldArtifact = character:FindFirstChild("BloodlineArtifact")
	if oldArtifact then
		oldArtifact:Destroy()
	end

	local upperTorso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") :: BasePart?
	if not upperTorso then return end

	-- Check ReplicatedStorage.Assets.Bloodlines for the 3D Meshy Model
	local assetsFolder = ReplicatedStorage:FindFirstChild("Assets")
	local bloodlineFolder = assetsFolder and assetsFolder:FindFirstChild("Bloodlines")
	local modelPrefab = bloodlineFolder and bloodlineFolder:FindFirstChild(artifactMeshName) :: Model?

	if modelPrefab then
		local artifactClone = modelPrefab:Clone()
		artifactClone.Name = "BloodlineArtifact"

		local primary = artifactClone.PrimaryPart or artifactClone:FindFirstChildWhichIsA("BasePart")
		if primary then
			local weld = Instance.new("WeldConstraint")
			primary.CFrame = upperTorso.CFrame * CFrame.new(0, 0.5, 0.8)
			weld.Part0 = upperTorso
			weld.Part1 = primary
			weld.Parent = primary
		end

		artifactClone.Parent = character
	end
end

function BloodlineManager.ProcessSpin(player: Player)
	local spins = PlayerDataManager.GetBloodlineSpins(player)
	if spins <= 0 then
		bloodlineRemote:FireClient(player, {
			Action = "SpinFailed",
			Message = "No Bloodline Spins remaining! Earn them via Bosses or exchange Spirit Stones.",
		})
		return
	end

	local success = PlayerDataManager.UseBloodlineSpin(player)
	if not success then return end

	local rolledBloodline = BloodlineConfig.RollRandomBloodline()
	PlayerDataManager.SetBloodline(player, rolledBloodline.Id)

	if player.Character then
		AttachVisualArtifact(player.Character, rolledBloodline.ArtifactMeshName)
	end

	bloodlineRemote:FireClient(player, {
		Action = "SpinResult",
		BloodlineId = rolledBloodline.Id,
		DisplayName = rolledBloodline.DisplayName,
		Rarity = rolledBloodline.Rarity,
		Description = rolledBloodline.Description,
		RemainingSpins = PlayerDataManager.GetBloodlineSpins(player),
	})

	print(string.format("[BloodlineManager] 🧬 %s awakened Bloodline: %s (%s)!",
		player.Name, rolledBloodline.DisplayName, rolledBloodline.Rarity))
end

function BloodlineManager.BuySpinWithStones(player: Player)
	local currentStones = PlayerDataManager.GetSpiritStones(player)
	if currentStones < SPIN_STONE_COST then
		bloodlineRemote:FireClient(player, {
			Action = "BuyFailed",
			Message = string.format("Insufficient Spirit Stones! Requires %d stones.", SPIN_STONE_COST),
		})
		return
	end

	local deducted = PlayerDataManager.RemoveSpiritStones(player, SPIN_STONE_COST)
	if deducted then
		local newSpins = PlayerDataManager.AddBloodlineSpins(player, 1)
		bloodlineRemote:FireClient(player, {
			Action = "BuySuccess",
			NewSpins = newSpins,
			RemainingStones = PlayerDataManager.GetSpiritStones(player),
		})
	end
end

function BloodlineManager.Init()
	bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction")

	bloodlineRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		if payload.Action == "Spin" then
			BloodlineManager.ProcessSpin(player)
		elseif payload.Action == "BuySpin" then
			BloodlineManager.BuySpinWithStones(player)
		end
	end)

	-- Attach artifact on character spawn
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			task.wait(1.0)
			local bloodlineId = PlayerDataManager.GetBloodline(player)
			local def = BloodlineConfig.GetBloodline(bloodlineId)
			AttachVisualArtifact(char, def.ArtifactMeshName)
		end)
	end)

	print("[ASCEND] BloodlineManager Initialized (Gacha Spins & 3D Artifact Attachments Active).")
end

return BloodlineManager