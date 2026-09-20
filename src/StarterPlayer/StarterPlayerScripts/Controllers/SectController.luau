--!strict
--[[
    SectController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SectController.luau
    Client UI controller bound to MainHubGui.MenuBackdrop.PageContainer.Page_Faction:
    - Guaranteed single-listener binding (permanently purges spammed click SFX)
    - 24-Hour live ticking countdown clock on Daily Stipend
    - Instant quest submission and live progress display
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local SectController = {}
SectController.__index = SectController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local sectRemote: RemoteEvent

local mainFrame: Frame? = nil
local discipleUserName: TextLabel? = nil
local discipleRankName: TextLabel? = nil
local discipleBadgeName: TextLabel? = nil
local stipendDescription: TextLabel? = nil
local stipendButton: GuiButton? = nil
local stipendButtonText: TextLabel? = nil
local promotionButton: GuiButton? = nil
local promotionButtonText: TextLabel? = nil

type QuestCardUI = {
	Frame: Frame,
	Title: TextLabel?,
	Description: TextLabel?,
	Button: GuiButton?,
	ButtonText: TextLabel?,
	Glow: ImageLabel?,
}

local questCards: { QuestCardUI } = {}
local lastSectData: any = nil
local isOpen = false
local isInitialized = false
local countdownThread: thread? = nil
local buttonConnections: { RBXScriptConnection } = {}

local QUEST_IDS = {
	"Quest_GatherSpiritGrass",
	"Quest_RefineDan",
	"Quest_SparringTrial",
}

local PANEL_CLICK_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.PanelClick) or "rbxassetid://138567614125924"
local function PlayPanelClickSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = PANEL_CLICK_SOUND_ID
	sound.Volume = 0.55
	sound.PlaybackSpeed = math.random(98, 102) / 100
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

local function FormatTime(seconds: number): string
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	local s = math.floor(seconds % 60)
	return string.format("%02dh %02dm %02ds", h, m, s)
end

local function ClearButtonConnections()
	for _, conn in ipairs(buttonConnections) do
		conn:Disconnect()
	end
	table.clear(buttonConnections)
end

local function EnsureUI(): boolean
	if isInitialized and mainFrame then return true end

	sectRemote = RemoteEvents.GetRemote("SectAction")

	local hub = playerGui:WaitForChild("MainHubGui", 10) :: ScreenGui?
	if hub then
		local backdrop = hub:WaitForChild("MenuBackdrop", 5) :: Frame?
		local pageContainer = backdrop and backdrop:WaitForChild("PageContainer", 5) :: Frame?
		mainFrame = pageContainer and (pageContainer:WaitForChild("Page_Faction", 5) :: Frame?)
	end

	if not mainFrame then
		local legacy = playerGui:FindFirstChild("SectPavilionGui")
		mainFrame = legacy and legacy:FindFirstChild("Page_Faction", true) or (legacy and legacy:FindFirstChild("MainFrame", true))
	end

	if not mainFrame then return false end
	mainFrame.Active = true

	local firstFrame = mainFrame:FindFirstChild("FirstFrame") :: Frame?
	if firstFrame then
		local sub1 = firstFrame:FindFirstChild("SubFrame1") :: Frame?
		if sub1 then
			local discipleFrame = sub1:FindFirstChild("DiscipleFrame") :: Frame?
			if discipleFrame then
				discipleUserName = discipleFrame:FindFirstChild("DiscipleUserName") :: TextLabel?
				discipleRankName = discipleFrame:FindFirstChild("DiscipleRankName") :: TextLabel?
				discipleBadgeName = discipleFrame:FindFirstChild("DiscipleBadgeName") :: TextLabel?
			end
		end

		local sub2 = firstFrame:FindFirstChild("SubFrame2") :: Frame?
		if sub2 then
			stipendDescription = sub2:FindFirstChild("RewardDescription") :: TextLabel?
			stipendButton = (sub2:FindFirstChild("ImageButton") or sub2:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
			if stipendButton then
				stipendButtonText = stipendButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end

		local sub3 = firstFrame:FindFirstChild("SubFrame3") :: Frame?
		if sub3 then
			promotionButton = (sub3:FindFirstChild("ImageButton") or sub3:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
			if promotionButton then
				promotionButtonText = promotionButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end
	end

	local secondFrame = mainFrame:FindFirstChild("SecondFrame") :: Frame?
	table.clear(questCards)

	if secondFrame then
		for idx = 1, 3 do
			local sub = secondFrame:FindFirstChild("SubFrame" .. tostring(idx)) :: Frame?
			if sub then
				local title = sub:FindFirstChild("MissionTitle") :: TextLabel?
				local desc = sub:FindFirstChild("MissionDescription") :: TextLabel?
				local btn = (sub:FindFirstChild("ImageButton") or sub:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
				local btnText = btn and (btn:FindFirstChild("TextLabel") or btn:FindFirstChildWhichIsA("TextLabel")) :: TextLabel?
				local glow = btn and btn:FindFirstChild("GlowOverlayImage") :: ImageLabel?

				table.insert(questCards, {
					Frame = sub,
					Title = title,
					Description = desc,
					Button = btn,
					ButtonText = btnText,
					Glow = glow,
				})
			end
		end
	end

	-- Connect buttons exactly ONCE (purges duplicate listener machine-gun audio)
	ClearButtonConnections()

	for idx = 1, 3 do
		local card = questCards[idx]
		local questId = QUEST_IDS[idx]
		if card and card.Button then
			local conn = card.Button.Activated:Connect(function()
				PlayPanelClickSFX()
				sectRemote:FireServer({ Action = "SubmitQuest", QuestId = questId })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	if stipendButton then
		local conn = stipendButton.Activated:Connect(function()
			PlayPanelClickSFX()
			sectRemote:FireServer({ Action = "ClaimDailyStipend" })
		end)
		table.insert(buttonConnections, conn)
	end

	if promotionButton then
		local conn = promotionButton.Activated:Connect(function()
			PlayPanelClickSFX()
			sectRemote:FireServer({ Action = "RequestPromotion" })
		end)
		table.insert(buttonConnections, conn)
	end

	isInitialized = true
	return true
end

function SectController.Render(data: any?)
	if not EnsureUI() or not mainFrame then return end
	if data then lastSectData = data end

	-- 1. Disciple Identification
	local currentRank = (lastSectData and lastSectData.Rank) or player:GetAttribute("SectRank") or "OuterDisciple"
	local rankTitle = (lastSectData and lastSectData.RankTitle) or tostring(currentRank)
	local cp = (lastSectData and lastSectData.ContributionPoints) or player:GetAttribute("ContributionPoints") or 0
	local realm = (lastSectData and lastSectData.Realm) or player:GetAttribute("Realm") or "QiCondensation"
	local order = (lastSectData and lastSectData.Order) or player:GetAttribute("Order") or 1

	if discipleUserName then discipleUserName.Text = (player.DisplayName or player.Name):upper() end
	if discipleRankName then discipleRankName.Text = string.gsub(tostring(rankTitle), "(%l)(%u)", "%1 %2"):upper() end
	if discipleBadgeName then discipleBadgeName.Text = string.format("%s - ORDER %s", tostring(realm):upper(), tostring(order)) end

	-- 2. Daily Sect Stipend (24h Live Countdown)
	local rankDef = SectConfig.GetRank(currentRank)
	if stipendDescription and rankDef then
		stipendDescription.Text = string.format("%d Spirit Stones + Daily Dan", rankDef.DailyStipendStones)
	end

	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end

	if stipendButton and stipendButtonText then
		local isClaimed = lastSectData and lastSectData.StipendClaimed
		local nextTimestamp = (lastSectData and lastSectData.NextStipendTimestamp) or 0
		local now = os.time()

		if isClaimed and nextTimestamp > now then
			countdownThread = task.spawn(function()
				while true do
					local remaining = nextTimestamp - os.time()
					if remaining <= 0 then
						if stipendButtonText then stipendButtonText.Text = "CLAIM DAILY STIPEND" end
						if stipendButton then stipendButton.BackgroundColor3 = Color3.fromRGB(200, 150, 40) end
						if lastSectData then lastSectData.StipendClaimed = false end
						break
					end
					if stipendButtonText then
						stipendButtonText.Text = "CLAIM IN " .. FormatTime(remaining)
					end
					if stipendButton then
						stipendButton.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
					end
					task.wait(1)
				end
			end)
		else
			stipendButtonText.Text = "CLAIM DAILY STIPEND"
			stipendButton.BackgroundColor3 = Color3.fromRGB(200, 150, 40)
		end
	end

	-- 3. Promotion Evaluation
	if promotionButton and promotionButtonText then
		local PROMOTION_CHAIN = { "OuterDisciple", "InnerDisciple", "CoreDisciple", "DirectDisciple", "SectElder", "GrandElder" }
		local nextRank: string? = nil
		for i, r in ipairs(PROMOTION_CHAIN) do
			if r == currentRank and i < #PROMOTION_CHAIN then
				nextRank = PROMOTION_CHAIN[i + 1]
				break
			end
		end

		if nextRank then
			local nextDef = SectConfig.GetRank(nextRank)
			local reqCp = nextDef and nextDef.RequiredContribution or 2500
			if cp >= reqCp then
				promotionButtonText.Text = "REQUEST PROMOTION"
				promotionButton.BackgroundColor3 = Color3.fromRGB(80, 40, 140)
			else
				promotionButtonText.Text = string.format("LOCKED (%d/%d CP)", cp, reqCp)
				promotionButton.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
			end
		else
			promotionButtonText.Text = "MAX RANK REACHED"
			promotionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		end
	end

	-- 4. 3-Tier Duties
	local quests = (lastSectData and lastSectData.Quests) or {}
	local TIER_NAMES = { [1] = "EASY", [2] = "MEDIUM", [3] = "HARD" }

	for idx = 1, 3 do
		local card = questCards[idx]
		local questId = QUEST_IDS[idx]
		local qData = quests[questId]

		if card and card.Frame then
			local tier = qData and qData.Tier or 1
			local qDef = SectConfig.GetQuest(questId, tier)
			local target = qDef and qDef.TargetAmount or 1
			local cur = qData and qData.CurrentAmount or 0
			local tierLabel = TIER_NAMES[tier] or "EASY"

			if card.Title and qDef then
				card.Title.Text = string.format("%s — %s (%d/%d)", qDef.Title, tierLabel, math.min(cur, target), target)
			end

			if card.Description and qDef then
				card.Description.Text = qDef.Description
			end

			if card.Button and card.ButtonText then
				if qData and qData.AllTiersCompleted then
					card.ButtonText.Text = "COMPLETED"
					card.Button.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
					if card.Glow then card.Glow.Visible = false end
				elseif qData and qData.ReadyToClaim then
					card.ButtonText.Text = "CLAIM REWARD"
					card.Button.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
					if card.Glow then card.Glow.Visible = true end
				else
					card.ButtonText.Text = "IN PROGRESS"
					card.Button.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
					if card.Glow then card.Glow.Visible = false end
				end
			end
		end
	end
end

function SectController.Open()
	if not EnsureUI() or not mainFrame then return end
	isOpen = true
	mainFrame.Visible = true

	if sectRemote then
		sectRemote:FireServer({ Action = "RequestSectData" })
	end

	SectController.Render()
end

function SectController.Close()
	if not isOpen then return end
	isOpen = false
	PlayPanelClickSFX()
	if countdownThread then
		task.cancel(countdownThread)
		countdownThread = nil
	end
	if mainFrame then mainFrame.Visible = false end
end

function SectController.Toggle()
	if isOpen then SectController.Close() else SectController.Open() end
end

function SectController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	sectRemote.OnClientEvent:Connect(function(payloadOrAction: any, maybePayload: any)
		local payload = if type(payloadOrAction) == "table" then payloadOrAction else maybePayload
		if type(payload) == "table" and (payload.Action == "SyncSectData" or payload.Action == "SectData") then
			lastSectData = payload
			SectController.Render(payload)
		elseif type(payload) == "table" and payload.Action == "StipendClaimed" then
			PlayPanelClickSFX()
			if lastSectData then
				lastSectData.StipendClaimed = true
				lastSectData.NextStipendTimestamp = os.time() + 86400
				SectController.Render(lastSectData)
			end
		elseif type(payload) == "table" and payload.Action == "QuestCompleted" then
			PlayPanelClickSFX()
		end
	end)

	player:GetAttributeChangedSignal("SectRank"):Connect(function() SectController.Render() end)
	player:GetAttributeChangedSignal("Realm"):Connect(function() SectController.Render() end)
	player:GetAttributeChangedSignal("ContributionPoints"):Connect(function() SectController.Render() end)

	print("[ASCEND] SectController Initialized & Live Dynamic Sync Active.")
end

return SectController