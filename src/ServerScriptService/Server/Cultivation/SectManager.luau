--!strict
--[[
    SectManager.luau
    Location: src/ServerScriptService/Server/Cultivation/SectManager.luau
    Server-authoritative Sect progression, 24-hour daily stipend, and 3-tier duty tracking:
    - 24-Hour (86,400s) persistent cooldown cycle keyed to player.UserId & PlayerDataManager
    - Strictly matches 'Spirit Grass' for Herbal Foraging duty (rejects other herbs)
    - Item-agnostic quest submission upon reaching target counts
    - Full countdown timestamps sent to client for live ticking clock
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

local SectManager = {}

local STIPEND_COOLDOWN_SECONDS = 86400 -- 24 Hours in Seconds

export type ServerQuestState = {
	QuestId: string,
	Tier: number,
	CurrentAmount: number,
	AllTiersCompleted: boolean,
}

local playerQuests: { [Player]: { [string]: ServerQuestState } } = {}
local stipendCacheByUserId: { [number]: number } = {} -- Keyed to UserId so it never wipes on player reload
local sectRemote: RemoteEvent? = nil

local function GetSectRemote(): RemoteEvent
	if not sectRemote then
		sectRemote = RemoteEvents.GetRemote("SectAction")
	end
	return sectRemote
end

local function SafeGet(funcName: string, func: any, ...)
	if type(func) == "function" then
		local success, result = pcall(func, ...)
		if success then return result end
	end
	return nil
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

	-- Delayed memory purge: PlayerDataManager.SaveData has plenty of time to save
	Players.PlayerRemoving:Connect(function(player: Player)
		task.delay(10, function()
			playerQuests[player] = nil
		end)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			SectManager.OnPlayerAdded(player)
		end)
	end

	SectManager.SetupQuestElderPrompt()
	print("[ASCEND] SectManager Initialized (24h Daily Cycle & Persistent Quest Sync Active).")
end

function SectManager.OnPlayerAdded(player: Player)
	if not playerQuests[player] then
		playerQuests[player] = {
			["Quest_GatherSpiritGrass"] = { QuestId = "Quest_GatherSpiritGrass", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
			["Quest_RefineDan"]          = { QuestId = "Quest_RefineDan", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
			["Quest_SparringTrial"]       = { QuestId = "Quest_SparringTrial", Tier = 1, CurrentAmount = 0, AllTiersCompleted = false },
		}
	end

	local savedTimestamp = player:GetAttribute("LastStipendClaim")
	if typeof(savedTimestamp) == "number" and savedTimestamp > 0 then
		stipendCacheByUserId[player.UserId] = savedTimestamp
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
	if savedQuests and type(savedQuests) == "table" then
		playerQuests[player] = savedQuests
	end
end

function SectManager.GetLastStipendClaim(player: Player): number?
	return stipendCacheByUserId[player.UserId] or player:GetAttribute("LastStipendClaim")
end

function SectManager.SetLastStipendClaim(player: Player, timestamp: number?)
	if timestamp and timestamp > 0 then
		stipendCacheByUserId[player.UserId] = timestamp
		player:SetAttribute("LastStipendClaim", timestamp)
	end
end

function SectManager.SetupQuestElderPrompt()
	local function BindPrompt(prompt: ProximityPrompt)
		local action = prompt.ActionText:lower()
		if action == "view missions" or action == "sect affairs" or action == "receive sect duties" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_DeaconZhao") then
			prompt.Triggered:Connect(function(player: Player)
				SectManager.OpenSectMenuForPlayer(player)
			end)
		end
	end

	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then BindPrompt(desc) end
	end

	workspace.DescendantAdded:Connect(function(desc)
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
	local rankDef = SectConfig.GetRank(rank) or { DisplayName = "Outer Disciple", DailyStipendStones = 100 }
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

	local now = os.time()
	local lastClaim = stipendCacheByUserId[player.UserId] or player:GetAttribute("LastStipendClaim") or 0
	local isClaimed = (lastClaim > 0) and ((now - lastClaim) < STIPEND_COOLDOWN_SECONDS)
	local remaining = if isClaimed then math.max(0, STIPEND_COOLDOWN_SECONDS - (now - lastClaim)) else 0

	GetSectRemote():FireClient(player, {
		Action = "SyncSectData",
		Rank = rank,
		RankTitle = rankDef.DisplayName,
		ContributionPoints = contribution,
		SpiritStones = stones,
		Quests = clientQuests,
		StipendClaimed = isClaimed,
		LastStipendClaim = lastClaim,
		NextStipendTimestamp = lastClaim + STIPEND_COOLDOWN_SECONDS,
		RemainingSeconds = remaining,
		Realm = cultData.Realm or "QiCondensation",
		Order = cultData.Order or 1,
	})
end

function SectManager.AddQuestProgress(player: Player, questType: "Gather" | "Cultivate" | "DefeatMob" | "CraftDan", targetId: string, amount: number)
	local quests = playerQuests[player]
	if not quests then return end

	local cleanTarget = targetId:gsub("_%d+Yr$", ""):gsub("%s+", ""):lower()

	for _, quest in pairs(quests) do
		if not quest.AllTiersCompleted then
			local questDef = SectConfig.GetQuest(quest.QuestId, quest.Tier)
			if questDef and questDef.QuestType == questType then
				local cleanDefTarget = (questDef.TargetId or ""):gsub("%s+", ""):lower()

				-- Strict Herbal Foraging: ONLY Spirit Grass advances this quest
				local isGatherMatch = (questType == "Gather") and (
					cleanDefTarget == "spiritgrass" and (cleanTarget == "spiritgrass" or cleanTarget == "spiritgrasscluster")
				)
				local isDanMatch = (questType == "CraftDan") and (cleanDefTarget == "anydan" or cleanTarget:find("dan") or cleanTarget:find("pill"))
				local isMobMatch = (questType == "DefeatMob") and (
					cleanDefTarget == "roguedisciple" and (cleanTarget == "roguedisciple" or cleanTarget:find("rogue") or cleanTarget:find("disciple"))
				)

				if isGatherMatch or isDanMatch or isMobMatch or (cleanDefTarget == cleanTarget) then
					quest.CurrentAmount = math.min(questDef.TargetAmount, quest.CurrentAmount + amount)
					SectManager.SyncSectData(player)
				end
			end
		end
	end
end

function SectManager.UpdateQuestProgress(player: Player, questType: "Gather" | "Cultivate" | "DefeatMob" | "CraftDan", targetId: string, amount: number)
	SectManager.AddQuestProgress(player, questType, targetId, amount)
end

function SectManager.ProcessSubmitQuest(player: Player, questId: any)
	if type(questId) ~= "string" then return end

	local quests = playerQuests[player]
	local quest = quests and quests[questId]
	if not quest or quest.AllTiersCompleted then return end

	local questDef = SectConfig.GetQuest(questId, quest.Tier)
	if not questDef then return end

	if quest.CurrentAmount < questDef.TargetAmount then return end

	-- Award Contribution Points, Spirit Stones, and Cultivated Qi
	SafeGet("AddContributionPoints", PlayerDataManager.AddContributionPoints, player, questDef.RewardContribution)
	SafeGet("AddSpiritStones", PlayerDataManager.AddSpiritStones, player, questDef.RewardSpiritStones)

	local pData = CultivationManager.GetPlayerData(player)
	if pData then
		local maxQiGoal = CultivationConfig.GetOrderTargetQi(pData.Realm, pData.Order)
		pData.CultivatedQi = math.clamp(pData.CultivatedQi + questDef.RewardQi, 0, maxQiGoal)
		pData.CurrentQi = math.clamp(pData.CurrentQi + questDef.RewardQi, 0, pData.CultivatedQi)
		CultivationManager.SyncClient(player)
	end

	-- Advance tier or mark completed
	if quest.Tier < 3 then
		quest.Tier += 1
		quest.CurrentAmount = 0
		quest.AllTiersCompleted = false
	else
		quest.AllTiersCompleted = true
		quest.CurrentAmount = questDef.TargetAmount
	end

	SectManager.SyncSectData(player)

	GetSectRemote():FireClient(player, {
		Action = "QuestCompleted",
		QuestId = questId,
		RewardContribution = questDef.RewardContribution,
		RewardSpiritStones = questDef.RewardSpiritStones,
	})
end

function SectManager.ProcessClaimStipend(player: Player)
	local now = os.time()
	local last = stipendCacheByUserId[player.UserId] or player:GetAttribute("LastStipendClaim") or 0

	-- Strict 24-Hour Enforcement
	if last > 0 and (now - last) < STIPEND_COOLDOWN_SECONDS then
		SectManager.SyncSectData(player)
		return
	end

	stipendCacheByUserId[player.UserId] = now
	player:SetAttribute("LastStipendClaim", now)

	local rank = SafeGet("GetSectRank", PlayerDataManager.GetSectRank, player) or "OuterDisciple"
	local rankDef = SectConfig.GetRank(rank)
	if not rankDef then return end

	SafeGet("AddSpiritStones", PlayerDataManager.AddSpiritStones, player, rankDef.DailyStipendStones)

	local danItemId = "CommonSpiritDan_1Yr"
	if rank == "InnerDisciple" then danItemId = "SpiritualSpiritDan_1Yr"
	elseif rank == "CoreDisciple" then danItemId = "EarthSpiritDan_1Yr"
	elseif rank == "DirectDisciple" or rank == "SectElder" or rank == "GrandElder" then danItemId = "HeavenSpiritDan_1Yr" end

	pcall(function()
		InventoryManager.AddItem(player, danItemId, 1)
	end)

	SectManager.SyncSectData(player)

	GetSectRemote():FireClient(player, {
		Action = "StipendClaimed",
		StonesGranted = rankDef.DailyStipendStones,
		DanGranted = danItemId,
	})
end

function SectManager.ProcessPromotion(player: Player)
	local currentRank = SafeGet("GetSectRank", PlayerDataManager.GetSectRank, player) or "OuterDisciple"
	local PROMOTION_ORDER = { "OuterDisciple", "InnerDisciple", "CoreDisciple", "DirectDisciple", "SectElder", "GrandElder" }

	local nextRank: string? = nil
	for i, r in ipairs(PROMOTION_ORDER) do
		if r == currentRank and i < #PROMOTION_ORDER then
			nextRank = PROMOTION_ORDER[i + 1]
			break
		end
	end

	if not nextRank then return end

	local nextDef = SectConfig.GetRank(nextRank)
	if not nextDef then return end

	local currentCp = SafeGet("GetContributionPoints", PlayerDataManager.GetContributionPoints, player) or 0
	if currentCp < nextDef.RequiredContribution then return end

	local cultData = CultivationManager.GetPlayerData(player)
	if cultData and nextDef.MinRealm then
		local curIdx = CultivationConfig.GetRealmIndex(cultData.Realm)
		local minIdx = CultivationConfig.GetRealmIndex(nextDef.MinRealm)
		if curIdx < minIdx then return end
	end

	SafeGet("SetSectRank", PlayerDataManager.SetSectRank, player, nextRank)
	SectManager.SyncSectData(player)

	GetSectRemote():FireClient(player, {
		Action = "Promoted",
		NewRank = nextRank,
		RankTitle = nextDef.DisplayName,
	})
end

return SectManager