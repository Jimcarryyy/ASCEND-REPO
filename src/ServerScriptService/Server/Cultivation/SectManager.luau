--!strict
--[[
    SectManager.luau
    Location: src/ServerScriptService/Server/Cultivation/SectManager.luau
    Server-authoritative Sect Management Engine for the Azure Cloud Sect.
    Handles: Daily Quests, Contribution Points, Disciple Rank Promotions, Daily Stipends, and Quest Elder NPC.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

export type PlayerQuestProgress = {
	QuestId: string,
	CurrentAmount: number,
	TargetAmount: number,
	Completed: boolean,
}

local SectManager = {}

local sectRemote: RemoteEvent
local playerQuests: { [Player]: { [string]: PlayerQuestProgress } } = {}
local lastStipendClaim: { [Player]: number } = {}

-- Disciple Promotion Progression Order
local PROMOTION_CHAIN: { SectConfig.DiscipleRank } = {
	"OuterDisciple",
	"InnerDisciple",
	"CoreDisciple",
	"DirectDisciple",
	"SectElder",
	"GrandElder",
}

local function GetRealmTier(realmTier: CultivationConfig.RealmTier): number
	local info = CultivationConfig[realmTier]
	return if info then info.Tier else 1
end

local function GetRealmDisplayName(realmTier: CultivationConfig.RealmTier): string
	local info = CultivationConfig[realmTier]
	return if info then info.Name else tostring(realmTier)
end

function SectManager.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	-- Handle Client Sect Requests
	sectRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "RequestSectData" then
			SectManager.SyncSectData(player)
		elseif action == "SubmitQuest" then
			SectManager.ProcessSubmitQuest(player, payload.QuestId)
		elseif action == "RequestPromotion" then
			SectManager.ProcessPromotion(player)
		elseif action == "ClaimDailyStipend" then
			SectManager.ProcessClaimStipend(player)
		end
	end)

	Players.PlayerAdded:Connect(SectManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		playerQuests[player] = nil
		lastStipendClaim[player] = nil
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			SectManager.OnPlayerAdded(player)
		end)
	end

	task.spawn(SectManager.SetupQuestElderPrompt)

	print("[ASCEND] SectManager Initialized (Quests, Promotions & Quest Elder Active).")
end

function SectManager.OnPlayerAdded(player: Player)
	playerQuests[player] = {}

	for questId, questDef in pairs(SectConfig.GetAllQuests()) do
		playerQuests[player][questId] = {
			QuestId = questId,
			CurrentAmount = 0,
			TargetAmount = questDef.TargetAmount,
			Completed = false,
		}
	end
end

function SectManager.SetupQuestElderPrompt()
	local elderFolder = Workspace:FindFirstChild("QuestNPCs") or Workspace:FindFirstChild("SectElders")
	if not elderFolder then
		elderFolder = Instance.new("Folder")
		elderFolder.Name = "QuestNPCs"
		elderFolder.Parent = Workspace
	end

	local function BindPrompt(elderPart: Instance)
		if not (elderPart:IsA("BasePart") or elderPart:IsA("Model")) then return end

		local targetPart = elderPart:IsA("Model") and (elderPart.PrimaryPart or elderPart:FindFirstChildWhichIsA("BasePart")) or elderPart :: BasePart
		if not targetPart or targetPart:FindFirstChild("QuestElderPrompt") then return end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "QuestElderPrompt"
		prompt.ObjectText = "Elder Xuan — Sect Master"
		prompt.ActionText = "Sect Affairs"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = targetPart

		prompt.Triggered:Connect(function(player: Player)
			SectManager.OpenSectMenuForPlayer(player)
		end)
	end

	for _, child in ipairs(elderFolder:GetChildren()) do
		BindPrompt(child)
	end

	elderFolder.ChildAdded:Connect(BindPrompt)
end

function SectManager.OpenSectMenuForPlayer(player: Player)
	SectManager.SyncSectData(player)
	sectRemote:FireClient(player, { Action = "OpenSectMenu" })
end

function SectManager.SyncSectData(player: Player)
	local rank = PlayerDataManager.GetSectRank(player)
	local rankDef = SectConfig.GetRank(rank)
	local contribution = PlayerDataManager.GetContributionPoints(player)
	local stones = PlayerDataManager.GetSpiritStones(player)
	local quests = playerQuests[player] or {}

	sectRemote:FireClient(player, {
		Action = "SyncSectData",
		Rank = rank,
		RankTitle = rankDef.DisplayName,
		ContributionPoints = contribution,
		SpiritStones = stones,
		Quests = quests,
		AllRanks = SectConfig.GetAllRanks(),
		AllQuests = SectConfig.GetAllQuests(),
	})
end

function SectManager.AddQuestProgress(player: Player, questType: "Gather" | "Cultivate" | "DefeatMob" | "CraftDan", targetId: string, amount: number)
	local quests = playerQuests[player]
	if not quests then return end

	for _, quest in pairs(quests) do
		if not quest.Completed then
			local questDef = SectConfig.GetQuest(quest.QuestId)
			if questDef and questDef.QuestType == questType then
				if questDef.TargetId == targetId or questDef.TargetId == "AnyDan" then
					quest.CurrentAmount = math.min(quest.TargetAmount, quest.CurrentAmount + amount)
					if quest.CurrentAmount >= quest.TargetAmount then
						quest.Completed = true
					end
					SectManager.SyncSectData(player)
				end
			end
		end
	end
end

function SectManager.ProcessSubmitQuest(player: Player, questId: any)
	if type(questId) ~= "string" then return end

	local quests = playerQuests[player]
	local quest = quests and quests[questId]
	local questDef = SectConfig.GetQuest(questId)

	if not quest or not questDef or not quest.Completed then
		sectRemote:FireClient(player, { Action = "QuestError", Message = "Quest requirements not yet completed." })
		return
	end

	-- If it was an herb delivery quest, verify and remove required herbs
	if questDef.QuestType == "Gather" then
		if not InventoryManager.HasItem(player, questDef.TargetId, questDef.TargetAmount) then
			local variantId = questDef.TargetId .. "_1Yr"
			if not InventoryManager.HasItem(player, variantId, questDef.TargetAmount) then
				sectRemote:FireClient(player, { Action = "QuestError", Message = "Missing required herbs in Spirit Pouch!" })
				return
			else
				InventoryManager.RemoveItem(player, variantId, questDef.TargetAmount)
			end
		else
			InventoryManager.RemoveItem(player, questDef.TargetId, questDef.TargetAmount)
		end
	end

	-- Award Rewards Safely
	PlayerDataManager.AddContributionPoints(player, questDef.RewardContribution)
	PlayerDataManager.AddSpiritStones(player, questDef.RewardSpiritStones)

	-- Add Qi directly via PlayerCultivationData
	local pData = CultivationManager.GetPlayerData(player)
	if pData then
		local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
		pData.CultivatedQi = math.clamp(pData.CultivatedQi + questDef.RewardQi, 0, maxQiGoal)
		pData.CurrentQi = math.clamp(pData.CurrentQi + questDef.RewardQi, 0, pData.CultivatedQi)
		CultivationManager.SyncClient(player)
	end

	-- Reset Quest for repeat
	quest.CurrentAmount = 0
	quest.Completed = false

	sectRemote:FireClient(player, {
		Action = "QuestCompleted",
		QuestId = questId,
		RewardContribution = questDef.RewardContribution,
		RewardSpiritStones = questDef.RewardSpiritStones,
		RewardQi = questDef.RewardQi,
	})

	SectManager.SyncSectData(player)
	print(string.format("[SectManager] %s completed Sect Quest '%s' (+%d Contribution, +%d Stones).", 
		player.Name, questDef.Title, questDef.RewardContribution, questDef.RewardSpiritStones))
end

function SectManager.ProcessPromotion(player: Player)
	local currentRank = PlayerDataManager.GetSectRank(player)
	local currentContribution = PlayerDataManager.GetContributionPoints(player)
	local cultivation = CultivationManager.GetPlayerData(player)
	if not cultivation then return end

	local nextRank: SectConfig.DiscipleRank? = nil
	for i, rank in ipairs(PROMOTION_CHAIN) do
		if rank == currentRank and i < #PROMOTION_CHAIN then
			nextRank = PROMOTION_CHAIN[i + 1]
			break
		end
	end

	if not nextRank then
		sectRemote:FireClient(player, { Action = "PromotionFailed", Message = "You have already achieved the highest Sect rank!" })
		return
	end

	local nextRankDef = SectConfig.GetRank(nextRank)

	if currentContribution < nextRankDef.RequiredContribution then
		sectRemote:FireClient(player, { 
			Action = "PromotionFailed", 
			Message = string.format("Insufficient Contribution Points! (%d / %d required)", currentContribution, nextRankDef.RequiredContribution) 
		})
		return
	end

	local playerRealmTier = GetRealmTier(cultivation.Realm)
	local reqRealmTier = GetRealmTier(nextRankDef.RequiredRealm)

	if playerRealmTier < reqRealmTier then
		local reqName = GetRealmDisplayName(nextRankDef.RequiredRealm)
		sectRemote:FireClient(player, { 
			Action = "PromotionFailed", 
			Message = string.format("Cultivation realm too low! Must reach %s.", reqName) 
		})
		return
	end

	PlayerDataManager.SetSectRank(player, nextRank)

	sectRemote:FireClient(player, {
		Action = "PromotionSuccess",
		NewRank = nextRank,
		DisplayName = nextRankDef.DisplayName,
	})

	SectManager.SyncSectData(player)
	print(string.format("[SectManager] ✨ %s was promoted to %s in the Azure Cloud Sect!", player.Name, nextRankDef.DisplayName))
end

function SectManager.ProcessClaimStipend(player: Player)
	local lastClaim = lastStipendClaim[player] or 0
	local now = os.time()
	local COOLDOWN = 72000 -- 20 hours (Daily reset)

	if now - lastClaim < COOLDOWN then
		local remainingSecs = COOLDOWN - (now - lastClaim)
		local hours = math.floor(remainingSecs / 3600)
		local mins = math.floor((remainingSecs % 3600) / 60)
		sectRemote:FireClient(player, { 
			Action = "StipendFailed", 
			Message = string.format("Daily stipend already claimed! Available in %dh %dm.", hours, mins) 
		})
		return
	end

	local currentRank = PlayerDataManager.GetSectRank(player)
	local rankDef = SectConfig.GetRank(currentRank)
	local stipend = rankDef.DailyStipendStones

	lastStipendClaim[player] = now
	PlayerDataManager.AddSpiritStones(player, stipend)

	sectRemote:FireClient(player, {
		Action = "StipendClaimed",
		Amount = stipend,
		NewBalance = PlayerDataManager.GetSpiritStones(player),
	})

	print(string.format("[SectManager] %s claimed daily stipend of %d Spirit Stones.", player.Name, stipend))
end

return SectManager