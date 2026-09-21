--!strict
--[[
    SectManager.luau
    Location: src/ServerScriptService/Server/Cultivation/SectManager.luau
    Server-authoritative disciple progression and sect administration engine.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local SectManager = {}

type PlayerSectProfile = {
	SectId: string,
	SectName: string,
	Rank: SectConfig.DiscipleRank,
	Contribution: number,
	Quests: { [string]: { QuestId: string, Tier: number, CurrentAmount: number, AllTiersCompleted: boolean } },
	LastStipendClaim: number,
}

local playerSects: { [Player]: PlayerSectProfile } = {}

local updateSectRemoteRef: RemoteEvent? = nil
local sectActionRemoteRef: RemoteEvent? = nil
local playerDataManagerRef: any = nil

local function getUpdateSectRemote(): RemoteEvent?
	if not updateSectRemoteRef then
		updateSectRemoteRef = RemoteEvents.GetRemote("UpdateSect")
	end
	return updateSectRemoteRef
end

local function getSectActionRemote(): RemoteEvent?
	if not sectActionRemoteRef then
		sectActionRemoteRef = RemoteEvents.GetRemote("SectAction")
	end
	return sectActionRemoteRef
end

local function getPlayerDataManager(): any
	if not playerDataManagerRef then
		playerDataManagerRef = require(ServerScriptService.Server.State.PlayerDataManager)
	end
	return playerDataManagerRef
end

function SectManager.Init()
	local sectActionRemote = getSectActionRemote()

	Players.PlayerAdded:Connect(SectManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(SectManager.OnPlayerRemoving)

	if sectActionRemote then
		sectActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
			SectManager.OnSectAction(player, payload)
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			SectManager.OnPlayerAdded(player)
		end)
	end

	print("[ASCEND] SectManager Initialized (24h Daily Cycle & Persistent Quest Sync Active).")
end

function SectManager.OnPlayerAdded(player: Player)
	local pdm = getPlayerDataManager()
	local rank = if pdm then pdm.GetSectRank(player) else "OuterDisciple"
	local cp = if pdm then pdm.GetContributionPoints(player) else 0

	local sectProfile: PlayerSectProfile = {
		SectId = "AzureCloud",
		SectName = "Azure Cloud Sect",
		Rank = rank,
		Contribution = cp,
		Quests = {},
		LastStipendClaim = 0,
	}

	-- Line 88 Fix: Uses SectConfig.GetAllQuests()
	local allQuests = SectConfig.GetAllQuests()
	for qId, _ in pairs(allQuests) do
		sectProfile.Quests[qId] = {
			QuestId = qId,
			Tier = 1,
			CurrentAmount = 0,
			AllTiersCompleted = false,
		}
	end

	playerSects[player] = sectProfile
	task.delay(1.5, function()
		if player.Parent then
			SectManager.SyncSectData(player)
		end
	end)
end

function SectManager.OnPlayerRemoving(player: Player)
	playerSects[player] = nil
end

function SectManager.GetSectData(player: Player): PlayerSectProfile?
	return playerSects[player]
end

function SectManager.GetQuestState(player: Player): any
	local data = playerSects[player]
	return data and data.Quests or nil
end

function SectManager.SetQuestState(player: Player, questData: any)
	local data = playerSects[player]
	if data and questData and type(questData) == "table" then
		for qId, qState in pairs(questData) do
			if data.Quests[qId] then
				data.Quests[qId].Tier = qState.Tier or 1
				data.Quests[qId].CurrentAmount = qState.CurrentAmount or 0
				data.Quests[qId].AllTiersCompleted = qState.AllTiersCompleted or false
			end
		end
	end
end

function SectManager.GetLastStipendClaim(player: Player): number
	local data = playerSects[player]
	return data and data.LastStipendClaim or 0
end

function SectManager.SetLastStipendClaim(player: Player, claimTime: number?)
	local data = playerSects[player]
	if data then
		data.LastStipendClaim = claimTime or 0
	end
end

function SectManager.GetContributionMultiplier(player: Player): number
	local sectData = playerSects[player]
	if not sectData then return 1.0 end
	local rankInfo = SectConfig.GetRank(sectData.Rank)
	return if rankInfo and (rankInfo :: any).ContributionMultiplier then (rankInfo :: any).ContributionMultiplier else 1.0
end

function SectManager.GetSectQiBuff(player: Player): number
	local sectData = playerSects[player]
	if not sectData then return 1.0 end
	local rankInfo = SectConfig.GetRank(sectData.Rank)
	return if rankInfo and rankInfo.QiBuffMultiplier then rankInfo.QiBuffMultiplier else 1.0
end

function SectManager.SyncSectData(player: Player)
	local sectData = playerSects[player]
	if not sectData then return end

	local pdm = getPlayerDataManager()
	local pData = pdm and pdm.GetPlayerData and pdm.GetPlayerData(player)
	local realmName = if pData and pData.Cultivation then pData.Cultivation.Realm else (player:GetAttribute("Realm") or "QiCondensation")
	local rankMultiplier = SectManager.GetContributionMultiplier(player)
	local rankDef = SectConfig.GetRank(sectData.Rank)

	local updateRemote = getUpdateSectRemote()
	if updateRemote then
		updateRemote:FireClient(player, {
			Action = "SyncSectData",
			SectId = sectData.SectId,
			SectName = sectData.SectName,
			Rank = sectData.Rank,
			RankName = if rankDef then rankDef.DisplayName else tostring(sectData.Rank),
			Contribution = sectData.Contribution,
			Quests = sectData.Quests,
			LastStipendClaim = sectData.LastStipendClaim,
			PlayerRealm = realmName,
			RankMultiplier = rankMultiplier,
		})
	end
end

function SectManager.AddContribution(player: Player, amount: number)
	local sectData = playerSects[player]
	if not sectData then return end

	local rankMultiplier = SectManager.GetContributionMultiplier(player)
	local finalAmount = math.floor(amount * rankMultiplier)

	sectData.Contribution += finalAmount
	local pdm = getPlayerDataManager()
	if pdm then
		pdm.AddContributionPoints(player, finalAmount)
	end

	SectManager.SyncSectData(player)
end

function SectManager.AddQuestProgress(player: Player, actionType: string, targetIdentifier: string, amount: number)
	local sectData = playerSects[player]
	if not sectData then return end

	local quest = sectData.Quests[actionType]
	if not quest or quest.AllTiersCompleted then return end

	local questDef = SectConfig.GetQuest(actionType, quest.Tier)
	if not questDef then return end

	quest.CurrentAmount += amount

	if quest.CurrentAmount >= questDef.TargetAmount then
		quest.CurrentAmount = questDef.TargetAmount
		SectManager.AddContribution(player, questDef.RewardContribution)

		local pdm = getPlayerDataManager()
		if pdm and questDef.RewardSpiritStones then
			pdm.AddSpiritStones(player, questDef.RewardSpiritStones)
		end

		local nextTierDef = SectConfig.GetQuest(actionType, quest.Tier + 1)
		if nextTierDef then
			quest.Tier += 1
			quest.CurrentAmount = 0
		else
			quest.AllTiersCompleted = true
		end
	end

	SectManager.SyncSectData(player)
end

function SectManager.PromoteRank(player: Player): boolean
	local sectData = playerSects[player]
	if not sectData then return false end

	local currentRank = sectData.Rank
	local rankOrder: { SectConfig.DiscipleRank } = {
		"OuterDisciple",
		"InnerDisciple",
		"CoreDisciple",
		"DirectDisciple",
		"SectElder",
		"GrandElder",
	}

	local currentIndex = 1
	for idx, rk in ipairs(rankOrder) do
		if rk == currentRank then
			currentIndex = idx
			break
		end
	end

	if currentIndex >= #rankOrder then return false end
	local nextRank = rankOrder[currentIndex + 1]
	local rankDef = SectConfig.GetRank(nextRank)
	if not rankDef then return false end

	local pdm = getPlayerDataManager()
	local pData = pdm and pdm.GetPlayerData and pdm.GetPlayerData(player)
	local currentRealm = if pData and pData.Cultivation then pData.Cultivation.Realm else (player:GetAttribute("Realm") or "QiCondensation")

	local realmMeets = CultivationConfig.IsRealmTierAtLeast(currentRealm, rankDef.RequiredRealm)
	local contribMeets = sectData.Contribution >= rankDef.RequiredContribution

	if not (realmMeets and contribMeets) then return false end

	sectData.Contribution -= rankDef.RequiredContribution
	sectData.Rank = nextRank

	if pdm then
		pdm.SetSectRank(player, nextRank)
		pdm.AddContributionPoints(player, -rankDef.RequiredContribution)
	end

	player:SetAttribute("SectRank", nextRank)
	if player.Character then
		player.Character:SetAttribute("SectRank", nextRank)
	end

	SectManager.SyncSectData(player)
	return true
end

function SectManager.ClaimDailyStipend(player: Player): (boolean, string)
	local sectData = playerSects[player]
	if not sectData then return false, "No sect data" end

	local now = Workspace:GetServerTimeNow()
	local cooldown = 86400
	if now - sectData.LastStipendClaim < cooldown then
		local timeLeft = cooldown - (now - sectData.LastStipendClaim)
		local hours = math.floor(timeLeft / 3600)
		local mins = math.floor((timeLeft % 3600) / 60)
		return false, string.format("Stipend claimed. Cooldown: %dh %dm", hours, mins)
	end

	local rankInfo = SectConfig.GetRank(sectData.Rank)
	local stipend = if rankInfo and rankInfo.DailyStipendStones then rankInfo.DailyStipendStones else 100

	sectData.LastStipendClaim = now
	local pdm = getPlayerDataManager()
	if pdm then
		pdm.AddSpiritStones(player, stipend)
		pdm.SetLastStipendClaim(player, now)
	end

	SectManager.SyncSectData(player)
	return true, string.format("Claimed %d Spirit Stones daily stipend!", stipend)
end

function SectManager.OnSectAction(player: Player, payload: any)
	if type(payload) ~= "table" then return end
	if payload.Action == "RequestSync" then
		SectManager.SyncSectData(player)
	elseif payload.Action == "PromoteRank" then
		SectManager.PromoteRank(player)
	elseif payload.Action == "ClaimDailyStipend" then
		local success, msg = SectManager.ClaimDailyStipend(player)
		local updateRemote = getUpdateSectRemote()
		if updateRemote then
			updateRemote:FireClient(player, {
				Action = "StipendResult",
				Success = success,
				Message = msg,
			})
		end
	end
end

return SectManager