--!strict
--[[
    SectManager.luau
    Location: src/ServerScriptService/Server/Cultivation/SectManager.luau
    Server-authoritative Sect Management Engine.
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

export type ServerQuestState = {
	QuestId: string,
	Tier: number,
	CurrentAmount: number,
	AllTiersCompleted: boolean,
}

local SectManager = {}
local sectRemote: RemoteEvent? = nil

local function GetSectRemote(): RemoteEvent
	if not sectRemote then
		sectRemote = RemoteEvents.GetRemote("SectAction")
	end
	return sectRemote
end

local function SafeGet(fnName: string, fn: any, ...: any): any
	if type(fn) ~= "function" then return nil end
	local ok, result = pcall(fn, ...)
	if not ok then return nil end
	return result
end

local playerQuests: { [Player]: { [string]: ServerQuestState } } = {}
local lastStipendClaim: { [Player]: number } = {}

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
	local remote = GetSectRemote()

	remote.OnServerEvent:Connect(function(player: Player, payload: any)
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
	print("[ASCEND] SectManager Initialized (3-Tier Quest Engine Active).")
end

function SectManager.OnPlayerAdded(player: Player)
	if not playerQuests[player] then
		playerQuests[player] = {
			["Quest_GatherSpiritGrass"] = { QuestId = "Quest_GatherSpiritGrass", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
			["Quest_RefineDan"]          = { QuestId = "Quest_RefineDan", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
			["Quest_SparringTrial"]       = { QuestId = "Quest_SparringTrial", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
		}
	end

	task.spawn(function()
		task.wait(1.5)
		SectManager.SyncSectData(player)
	end)
end

function SectManager.GetQuestState(player: Player): { [string]: ServerQuestState }?
	return playerQuests[player]
end

function SectManager.SetQuestState(player: Player, savedQuests: { [string]: ServerQuestState }?)
	if savedQuests then playerQuests[player] = savedQuests end
end

function SectManager.GetLastStipendClaim(player: Player): number?
	return lastStipendClaim[player]
end

function SectManager.SetLastStipendClaim(player: Player, timestamp: number?)
	lastStipendClaim[player] = timestamp
end

function SectManager.SetupQuestElderPrompt()
	local function BindPrompt(prompt: ProximityPrompt)
		local action = prompt.ActionText:lower()
		-- Strictly binds ONLY to Deacon Zhao / Notice Board!
		if action == "view missions" or action == "sect affairs" or action == "receive sect duties" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_DeaconZhao") then
			prompt.Triggered:Connect(function(player: Player)
				SectManager.OpenSectMenuForPlayer(player)
			end)
		end
	end

	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then BindPrompt(desc) end
	end

	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then BindPrompt(desc) end
	end)
end

function SectManager.OpenSectMenuForPlayer(player: Player)
	SectManager.SyncSectData(player)
	GetSectRemote():FireClient(player, { Action = "OpenSectMenu" })
end

function SectManager.SyncSectData(player: Player)
	local cultData = CultivationManager.GetPlayerData(player)
	if not cultData then return end

	local rank = SafeGet("GetSectRank", PlayerDataManager.GetSectRank, player) or "OuterDisciple"
	local rankDef = SectConfig.GetRank(rank)
	local contribution = SafeGet("GetContributionPoints", PlayerDataManager.GetContributionPoints, player) or 0
	local stones = SafeGet("GetSpiritStones", PlayerDataManager.GetSpiritStones, player) or 0
	local rawQuests = playerQuests[player] or {}

	local clientQuests: { [string]: { Tier: number, CurrentAmount: number, ReadyToClaim: boolean, AllTiersCompleted: boolean } } = {}

	for qId, qState in pairs(rawQuests) do
		local qDef = SectConfig.GetQuest(qId, qState.Tier)
		local target = if qDef then qDef.TargetAmount else 999999
		local isReady = (qState.CurrentAmount >= target) and not qState.AllTiersCompleted

		clientQuests[qId] = {
			Tier = qState.Tier,
			CurrentAmount = qState.CurrentAmount,
			ReadyToClaim = isReady,
			AllTiersCompleted = qState.AllTiersCompleted == true,
		}
	end

	GetSectRemote():FireClient(player, {
		Action = "SyncSectData",
		Rank = rank,
		RankTitle = rankDef.DisplayName,
		ContributionPoints = contribution,
		SpiritStones = stones,
		Quests = clientQuests,
		StipendClaimed = (lastStipendClaim[player] ~= nil and (os.time() - lastStipendClaim[player]) < 72000),
		Realm = cultData.Realm or "QiCondensation",
		Order = cultData.Order or 1,
	})
end

function SectManager.AddQuestProgress(player: Player, questType: "Gather" | "Cultivate" | "DefeatMob" | "CraftDan", targetId: string, amount: number)
	local quests = playerQuests[player]
	if not quests then return end

	for _, quest in pairs(quests) do
		if not quest.AllTiersCompleted then
			local questDef = SectConfig.GetQuest(quest.QuestId, quest.Tier)
			if questDef and questDef.QuestType == questType then
				if questDef.TargetId == targetId or questDef.TargetId == "AnyDan" then
					quest.CurrentAmount = math.min(questDef.TargetAmount, quest.CurrentAmount + amount)
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
	if not quest or quest.AllTiersCompleted then return end

	local questDef = SectConfig.GetQuest(questId, quest.Tier)
	if not questDef then return end

	if quest.CurrentAmount < questDef.TargetAmount then return end

	if questDef.QuestType == "Gather" then
		if not InventoryManager.HasItem(player, questDef.TargetId, questDef.TargetAmount) then
			local variantId = questDef.TargetId .. "_1Yr"
			if not InventoryManager.HasItem(player, variantId, questDef.TargetAmount) then return else
				InventoryManager.RemoveItem(player, variantId, questDef.TargetAmount)
			end
		else
			InventoryManager.RemoveItem(player, questDef.TargetId, questDef.TargetAmount)
		end
	end

	SafeGet("AddContributionPoints", PlayerDataManager.AddContributionPoints, player, questDef.RewardContribution)
	SafeGet("AddSpiritStones", PlayerDataManager.AddSpiritStones, player, questDef.RewardSpiritStones)

	local pData = CultivationManager.GetPlayerData(player)
	if pData then
		local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
		pData.CultivatedQi = math.clamp(pData.CultivatedQi + questDef.RewardQi, 0, maxQiGoal)
		pData.CurrentQi = math.clamp(pData.CurrentQi + questDef.RewardQi, 0, pData.CultivatedQi)
		CultivationManager.SyncClient(player)
	end

	if quest.Tier < 3 then
		quest.Tier += 1
		quest.CurrentAmount = 0
		quest.AllTiersCompleted = false
	else
		quest.AllTiersCompleted = true
		quest.CurrentAmount = questDef.TargetAmount
	end

	GetSectRemote():FireClient(player, {
		Action = "QuestCompleted",
		QuestId = questId,
		RewardContribution = questDef.RewardContribution,
		RewardSpiritStones = questDef.RewardSpiritStones,
		RewardQi = questDef.RewardQi,
	})

	SectManager.SyncSectData(player)
end

function SectManager.ProcessPromotion(player: Player)
	local currentRank = SafeGet("GetSectRank", PlayerDataManager.GetSectRank, player) or "OuterDisciple"
	local currentContribution = SafeGet("GetContributionPoints", PlayerDataManager.GetContributionPoints, player) or 0
	local cultivation = CultivationManager.GetPlayerData(player)
	if not cultivation then return end

	local nextRank: SectConfig.DiscipleRank? = nil
	for i, rank in ipairs(PROMOTION_CHAIN) do
		if rank == currentRank and i < #PROMOTION_CHAIN then
			nextRank = PROMOTION_CHAIN[i + 1]
			break
		end
	end

	if not nextRank then return end
	local nextRankDef = SectConfig.GetRank(nextRank)

	if currentContribution < nextRankDef.RequiredContribution then return end

	local playerRealmTier = GetRealmTier(cultivation.Realm)
	local reqRealmTier = GetRealmTier(nextRankDef.RequiredRealm)
	if playerRealmTier < reqRealmTier then return end

	SafeGet("SetSectRank", PlayerDataManager.SetSectRank, player, nextRank)

	GetSectRemote():FireClient(player, {
		Action = "PromotionSuccess",
		NewRank = nextRank,
		DisplayName = nextRankDef.DisplayName,
	})

	SectManager.SyncSectData(player)
end

function SectManager.ProcessClaimStipend(player: Player)
	local lastClaim = lastStipendClaim[player] or 0
	local now = os.time()
	local COOLDOWN = 72000

	if now - lastClaim < COOLDOWN then return end

	local currentRank = SafeGet("GetSectRank", PlayerDataManager.GetSectRank, player) or "OuterDisciple"
	local rankDef = SectConfig.GetRank(currentRank)
	local stipend = rankDef.DailyStipendStones

	lastStipendClaim[player] = now
	SafeGet("AddSpiritStones", PlayerDataManager.AddSpiritStones, player, stipend)

	GetSectRemote():FireClient(player, {
		Action = "StipendClaimed",
		Amount = stipend,
		NewBalance = SafeGet("GetSpiritStones", PlayerDataManager.GetSpiritStones, player) or 0,
	})

	SectManager.SyncSectData(player)
end

return SectManager