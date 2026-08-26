--!strict
--[[
    SectController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SectController.luau
    Client UI controller for the Sect Elder Pavilion (青云宗务堂):
    - Directly bound to StarterGui.SectPavilionGui without hardcoded UI creation
    - Syncs live disciple profile, rank, realm, contribution points, and spirit stones
    - Manages Daily Sect Stipends, Rank Promotions, and Daily Duty Mission Claims

    CHANGES IN THIS VERSION:
    1. Removed the CP progress bar entirely (cpBarFill / cpCount). The
       Promotion Evaluation button already displays "LOCKED (current/target CP)",
       so the bar was redundant. If you haven't deleted the CPBarTrack UI
       instance in Studio yet, it's fine to leave it there unreferenced —
       this script simply no longer looks for or updates it.

    2. Quest cards are now TIERED (Easy -> Medium -> Hard) instead of
       resetting back to "IN PROGRESS" forever after a claim. Each of the
       3 quest slots (Gather / Refine / Sparring) independently progresses
       through 3 tiers with increasing target counts and rewards. Once a
       quest's Hard tier is claimed, that card locks into a permanent
       "COMPLETE" state instead of looping.

       IMPORTANT: this requires your server payload (SyncSectData) to now
       include, per quest entry in `Quests`:
         {
             Tier = 1 | 2 | 3,        -- which tier is currently active
             CurrentAmount = number,   -- progress within the CURRENT tier
             ReadyToClaim = boolean,   -- server-computed: true when this
                                        -- tier's target is met and not yet claimed
             AllTiersCompleted = boolean, -- true once Hard tier has been claimed
         }
       And your SectConfig module needs a tier-aware quest lookup:
         SectConfig.GetQuest(questId: string, tier: number) -> QuestDef?
       returning tier-specific Title/Description/TargetAmount/Rewards.
       The client trusts ReadyToClaim / AllTiersCompleted from the server
       rather than recomputing amount-vs-target itself, so a stale client
       can't be tricked into re-claiming.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local SectController = {}
SectController.__index = SectController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local sectRemote: RemoteEvent

-- Audio
local CLICK_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.PanelClick) or "rbxassetid://138567614125924"

local function PlayPanelClickSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = 0.55
	sound.PlaybackSpeed = math.random(98, 102) / 100
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

-- UI References
local screenGui: ScreenGui?
local overlayBackdrop: Frame?
local mainFrame: ImageLabel?
local headerFrame: Frame?
local closeButton: GuiButton?

-- Left Column References (FirstFrame)
local firstFrame: ImageLabel?
local discipleUserName: TextLabel?
local discipleRankName: TextLabel?
local discipleBadgeName: TextLabel?
local discipleBadge: ImageLabel?

local stipendDescription: TextLabel?
local stipendButton: ImageButton?
local stipendButtonText: TextLabel?

local promotionButton: ImageButton?
local promotionButtonText: TextLabel?

-- Right Column References (SecondFrame - 3 Quest Cards)
local secondFrame: ImageLabel?
type QuestCardUI = {
	Container: ImageLabel,
	Icon: ImageLabel?,
	Title: TextLabel?,
	Description: TextLabel?,
	Reward1Text: TextLabel?,
	Reward2Text: TextLabel?,
	Reward3Text: TextLabel?,
	ActionButton: ImageButton?,
	ActionButtonText: TextLabel?,
	GlowOverlay: ImageLabel?,
	QuestId: string,
}

local questCards: { QuestCardUI } = {}

-- State Cache
local currentRankId: string = "OuterDisciple"
local currentContribution: number = 0
local currentStones: number = 0
local liveQuestsData: { [string]: any } = {}
local isOpen: boolean = false
local isInitialized: boolean = false

-- Ordered Quest List Key Mapping
local QUEST_INDEX_ORDER = {
	[1] = "Quest_GatherSpiritGrass",
	[2] = "Quest_RefineDan",
	[3] = "Quest_SparringTrial",
}

local TIER_LABELS = { [1] = "EASY", [2] = "MEDIUM", [3] = "HARD" }

local PROMOTION_ORDER = {
	"OuterDisciple",
	"InnerDisciple",
	"CoreDisciple",
	"DirectDisciple",
	"SectElder",
	"GrandElder",
}

local function IsPositionInsideGui(guiObject: GuiObject, x: number, y: number): boolean
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return x >= pos.X and x <= (pos.X + size.X) and y >= pos.Y and y <= (pos.Y + size.Y)
end

local function EnsureUI(): boolean
	if isInitialized and screenGui and mainFrame then return true end

	sectRemote = RemoteEvents.GetRemote("SectAction")

	screenGui = (playerGui:FindFirstChild("SectPavilionGui") or playerGui:WaitForChild("SectPavilionGui", 8)) :: ScreenGui?
	if not screenGui then return false end

	screenGui.DisplayOrder = 10
	screenGui.Enabled = false

	overlayBackdrop = screenGui:FindFirstChild("OverlayBackdrop") :: Frame?
	mainFrame = screenGui:FindFirstChild("MainFrame") :: ImageLabel?
	if not mainFrame then return false end
	mainFrame.Active = true

	-- Header
	headerFrame = mainFrame:FindFirstChild("HeaderFrame") :: Frame?
	if headerFrame then
		closeButton = (headerFrame:FindFirstChild("CloseImageButton") or headerFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
	end

	-- =========================================================================
	-- LEFT COLUMN (FirstFrame)
	-- =========================================================================
	firstFrame = mainFrame:FindFirstChild("FirstFrame") :: ImageLabel?
	if firstFrame then
		-- SubFrame1: Profile Card
		local sub1 = firstFrame:FindFirstChild("SubFrame1") :: ImageLabel?
		if sub1 then
			local discipleFrame = sub1:FindFirstChild("DiscipleFrame") :: Frame?
			if discipleFrame then
				discipleBadge = discipleFrame:FindFirstChild("DiscipleBadge") :: ImageLabel?
				discipleUserName = discipleFrame:FindFirstChild("DiscipleUserName") :: TextLabel?
				discipleRankName = discipleFrame:FindFirstChild("DiscipleRankName") :: TextLabel?
				discipleBadgeName = discipleFrame:FindFirstChild("DiscipleBadgeName") :: TextLabel?
			end
			-- NOTE: CPFrame (bar + count) intentionally no longer referenced.
			-- Promotion Evaluation's button text now carries the current/target
			-- CP display instead, so that redundant bar has been removed.
		end

		-- SubFrame2: Daily Stipend
		local sub2 = firstFrame:FindFirstChild("SubFrame2") :: ImageLabel?
		if sub2 then
			stipendDescription = sub2:FindFirstChild("RewardDescription") :: TextLabel?
			stipendButton = sub2:FindFirstChild("ImageButton") :: ImageButton?
			if stipendButton then
				stipendButtonText = stipendButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end

		-- SubFrame3: Promotion
		local sub3 = firstFrame:FindFirstChild("SubFrame3") :: ImageLabel?
		if sub3 then
			promotionButton = sub3:FindFirstChild("ImageButton") :: ImageButton?
			if promotionButton then
				promotionButtonText = promotionButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end
	end

	-- =========================================================================
	-- RIGHT COLUMN (SecondFrame - 3 Quest Cards)
	-- =========================================================================
	secondFrame = mainFrame:FindFirstChild("SecondFrame") :: ImageLabel?
	table.clear(questCards)

	if secondFrame then
		for idx = 1, 3 do
			local sub = secondFrame:FindFirstChild("SubFrame" .. tostring(idx)) :: ImageLabel?
			if sub then
				local iconContainer = sub:FindFirstChild("IconContainer") :: ImageLabel?
				local iconImg = if iconContainer then iconContainer:FindFirstChild("IconImage") :: ImageLabel? else nil
				local title = sub:FindFirstChild("MissionTitle") :: TextLabel?
				local desc = sub:FindFirstChild("MissionDescription") :: TextLabel?

				local r1 = sub:FindFirstChild("Reward1") :: ImageLabel?
				local r1Text = if r1 then r1:FindFirstChild("TextLabel") :: TextLabel? else nil
				local r2 = sub:FindFirstChild("Reward2") :: ImageLabel?
				local r2Text = if r2 then r2:FindFirstChild("TextLabel") :: TextLabel? else nil
				local r3 = sub:FindFirstChild("Reward3") :: ImageLabel?
				local r3Text = if r3 then r3:FindFirstChild("TextLabel") :: TextLabel? else nil

				local btn = sub:FindFirstChild("ImageButton") :: ImageButton?
				local btnText = if btn then btn:FindFirstChild("TextLabel") :: TextLabel? else nil
				local glow = if btn then btn:FindFirstChild("GlowOverlayImage") :: ImageLabel? else nil

				local qId = QUEST_INDEX_ORDER[idx] or "Quest_GatherSpiritGrass"

				table.insert(questCards, {
					Container = sub,
					Icon = iconImg,
					Title = title,
					Description = desc,
					Reward1Text = r1Text,
					Reward2Text = r2Text,
					Reward3Text = r3Text,
					ActionButton = btn,
					ActionButtonText = btnText,
					GlowOverlay = glow,
					QuestId = qId,
				})

				if btn then
					btn.MouseButton1Click:Connect(function()
						PlayPanelClickSFX()
						SectController.OnQuestButtonClicked(qId)
					end)
				end
			end
		end
	end

	-- =========================================================================
	-- BIND BUTTON INTERACTIONS
	-- =========================================================================
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			SectController.Close()
		end)
	end

	if overlayBackdrop then
		overlayBackdrop.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local clickPos = input.Position
				if mainFrame and not IsPositionInsideGui(mainFrame, clickPos.X, clickPos.Y) then
					PlayPanelClickSFX()
					SectController.Close()
				end
			end
		end)
	end

	if stipendButton then
		stipendButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			sectRemote:FireServer({ Action = "ClaimDailyStipend" })
		end)
	end

	if promotionButton then
		promotionButton.MouseButton1Click:Connect(function()
			PlayPanelClickSFX()
			sectRemote:FireServer({ Action = "RequestPromotion" })
		end)
	end

	isInitialized = true
	return true
end

function SectController.Init()
	EnsureUI()

	sectRemote = RemoteEvents.GetRemote("SectAction")

	-- Listen for Server Sect Synchronization
	sectRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "OpenSectMenu" then
			SectController.Open()
		elseif payload.Action == "SyncSectData" then
			currentRankId = payload.Rank or "OuterDisciple"
			currentContribution = payload.ContributionPoints or 0
			currentStones = payload.SpiritStones or 0
			liveQuestsData = payload.Quests or {}
			SectController.UpdateUI()
		elseif payload.Action == "StipendClaimed" then
			if stipendButtonText then
				stipendButtonText.Text = "CLAIMED TODAY"
			end
			if stipendButton then
				stipendButton.ImageColor3 = Color3.fromRGB(120, 120, 130)
			end
		elseif payload.Action == "PromotionSuccess" then
			currentRankId = payload.NewRank or currentRankId
			sectRemote:FireServer({ Action = "RequestSectData" })
		end
	end)

	-- Request initial data
	task.defer(function()
		task.wait(1.0)
		sectRemote:FireServer({ Action = "RequestSectData" })
	end)

	print("[ASCEND] SectController Initialized (Studio SectPavilionGui Connected).")
end

function SectController.Open()
	if not EnsureUI() then return end
	if not screenGui or not mainFrame then return end

	isOpen = true
	screenGui.Enabled = true
	mainFrame.Visible = true
	if overlayBackdrop then overlayBackdrop.Visible = true end

	sectRemote:FireServer({ Action = "RequestSectData" })
	SectController.UpdateUI()
end

function SectController.Close()
	isOpen = false
	if screenGui then screenGui.Enabled = false end
	if mainFrame then mainFrame.Visible = false end
	if overlayBackdrop then overlayBackdrop.Visible = false end
end

-- =============================================================================
-- UPDATE LIVE UI WITH REAL DATASTORE & SECT VALUES
-- =============================================================================
function SectController.UpdateUI()
	if not isInitialized then EnsureUI() end

	local rankDef = SectConfig.GetRank(currentRankId :: any)

	-- 1. Profile Card
	if discipleUserName then
		discipleUserName.Text = player.DisplayName:upper()
	end
	if discipleRankName then
		discipleRankName.Text = (rankDef.DisplayName or "Outer Disciple"):upper()
		discipleRankName.TextColor3 = rankDef.TitleColor or Color3.fromRGB(240, 200, 100)
	end
	if discipleBadgeName then
		local char = player.Character
		local realm = (char and char:GetAttribute("Realm")) or "QiCondensation"
		local order = (char and char:GetAttribute("Order")) or 1
		discipleBadgeName.Text = string.format("%s %d", tostring(realm):upper(), order)
	end

	-- Next Rank Contribution Target (still needed for the Promotion button's
	-- "LOCKED (current/target CP)" text -- the bar itself has been removed)
	local nextRankIndex = 1
	for i, r in ipairs(PROMOTION_ORDER) do
		if r == currentRankId then
			nextRankIndex = math.min(#PROMOTION_ORDER, i + 1)
			break
		end
	end
	local nextRankId = PROMOTION_ORDER[nextRankIndex]
	local nextRankDef = SectConfig.GetRank(nextRankId :: any)
	local targetCP = math.max(1, nextRankDef.RequiredContribution or 500)

	-- 2. Daily Stipend Info
	if stipendDescription then
		stipendDescription.Text = string.format("%d Stones + Daily Dan", rankDef.DailyStipendStones or 100)
	end

	-- 3. Promotion Button State
	local isHighestRank = (currentRankId == PROMOTION_ORDER[#PROMOTION_ORDER])
	local meetsCP = currentContribution >= targetCP
	local isEligible = not isHighestRank and meetsCP

	if promotionButton then
		if isHighestRank then
			promotionButton.ImageColor3 = Color3.fromRGB(100, 100, 110)
			if promotionButtonText then promotionButtonText.Text = "HIGHEST RANK ACHIEVED" end
		elseif isEligible then
			promotionButton.ImageColor3 = Color3.fromRGB(245, 158, 11) -- Radiant Gold
			if promotionButtonText then promotionButtonText.Text = "REQUEST PROMOTION" end
		else
			promotionButton.ImageColor3 = Color3.fromRGB(100, 100, 110)
			if promotionButtonText then promotionButtonText.Text = string.format("LOCKED (%d/%d CP)", currentContribution, targetCP) end
		end
	end

	-- 4. Update 3 Quest Cards — now tiered (Easy -> Medium -> Hard) instead
	-- of looping back to "IN PROGRESS" forever.
	for _, card in ipairs(questCards) do
		local qLive = liveQuestsData[card.QuestId]

		if not qLive then
			-- No data yet (still loading) -- leave card in a neutral state.
			if card.ActionButtonText then card.ActionButtonText.Text = "..." end
			if card.GlowOverlay then card.GlowOverlay.Visible = false end
			continue
		end

		if qLive.AllTiersCompleted then
			-- Player has cleared Easy, Medium, and Hard for this duty.
			-- Lock the card instead of resetting it back to tier 1.
			if card.Title then
				card.Title.Text = string.format("%s — SECT DUTY COMPLETE", (SectConfig.GetQuest(card.QuestId, 3) or {}).Title or "Duty")
			end
			if card.Description then
				card.Description.Text = "You have completed all difficulty tiers for this duty."
			end
			if card.ActionButton and card.ActionButtonText then
				card.ActionButton.ImageColor3 = Color3.fromRGB(90, 90, 100) -- muted, permanently inactive
				card.ActionButtonText.Text = "COMPLETED"
			end
			if card.GlowOverlay then
				card.GlowOverlay.Visible = false
			end
			continue
		end

		local tier = math.clamp(qLive.Tier or 1, 1, 3)
		local qDef = SectConfig.GetQuest(card.QuestId, tier)
		if not qDef then continue end

		local curAmt = qLive.CurrentAmount or 0
		local readyToClaim = qLive.ReadyToClaim == true

		if card.Title then
			local tierLabel = TIER_LABELS[tier] or "EASY"
			card.Title.Text = string.format("%s — %s (%d/%d)", qDef.Title, tierLabel, curAmt, qDef.TargetAmount)
		end
		if card.Description then
			card.Description.Text = qDef.Description
		end
		if card.Reward1Text then
			card.Reward1Text.Text = string.format("+%d CP", qDef.RewardContribution)
		end
		if card.Reward2Text then
			card.Reward2Text.Text = string.format("+%d STONES", qDef.RewardSpiritStones)
		end
		if card.Reward3Text then
			card.Reward3Text.Text = string.format("+%d QI", qDef.RewardQi)
		end

		if card.ActionButton and card.ActionButtonText then
			if readyToClaim then
				card.ActionButton.ImageColor3 = Color3.fromRGB(16, 185, 129) -- Radiant Green
				card.ActionButtonText.Text = "CLAIM"
				if card.GlowOverlay then card.GlowOverlay.Visible = true end
			else
				card.ActionButton.ImageColor3 = Color3.fromRGB(75, 85, 99) -- Slate Gray
				card.ActionButtonText.Text = "IN PROGRESS"
				if card.GlowOverlay then card.GlowOverlay.Visible = false end
			end
		end
	end
end

function SectController.OnQuestButtonClicked(questId: string)
	local qLive = liveQuestsData[questId]

	-- Trust the server-computed flags rather than re-deriving amount-vs-target
	-- on the client -- this is what prevents a stale/tampered client from
	-- re-firing a claim after a tier (or all tiers) is already done.
	if qLive and qLive.ReadyToClaim and not qLive.AllTiersCompleted then
		sectRemote:FireServer({ Action = "SubmitQuest", QuestId = questId })
	end
end

return SectController
