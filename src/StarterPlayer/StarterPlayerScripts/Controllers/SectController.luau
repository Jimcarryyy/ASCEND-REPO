--!strict
--[[
    SectController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SectController.luau
    Client UI controller for the Sect Elder Pavilion (青云宗务堂):
    - Instant ProximityPrompt trigger for Deacon Zhao & Notice Board
    - Robust hierarchy finding for MainFrame inside OverlayBackdrop
    - DisplayOrder = 50 modal layering
    - Full sync for Disciple profile, Daily Stipends, Promotions, and 3-Tier Duties
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
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
local mainFrame: Frame?
local headerFrame: Frame?
local closeButton: GuiButton?

-- Left Column References (FirstFrame)
local firstFrame: Frame?
local discipleUserName: TextLabel?
local discipleRankName: TextLabel?
local discipleBadgeName: TextLabel?

local stipendDescription: TextLabel?
local stipendButton: GuiButton?
local stipendButtonText: TextLabel?

local promotionButton: GuiButton?
local promotionButtonText: TextLabel?

-- Right Column References (SecondFrame - 3 Quest Cards)
local secondFrame: Frame?
type QuestCardUI = {
	Container: Frame,
	Title: TextLabel?,
	Description: TextLabel?,
	Reward1Text: TextLabel?,
	Reward2Text: TextLabel?,
	Reward3Text: TextLabel?,
	ActionButton: GuiButton?,
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

	screenGui = (playerGui:FindFirstChild("SectPavilionGui") or playerGui:WaitForChild("SectPavilionGui", 6)) :: ScreenGui?
	if not screenGui then return false end

	screenGui.DisplayOrder = 50
	screenGui.IgnoreGuiInset = true

	overlayBackdrop = screenGui:FindFirstChild("OverlayBackdrop") :: Frame?
	
	-- Robust MainFrame Resolution (Handles both direct child and nested in OverlayBackdrop)
	mainFrame = (screenGui:FindFirstChild("MainFrame") or (overlayBackdrop and overlayBackdrop:FindFirstChild("MainFrame")) or screenGui:FindFirstChildWhichIsA("Frame", true)) :: Frame?
	if not mainFrame then return false end
	mainFrame.Active = true

	-- Header Frame & Close Button
	headerFrame = mainFrame:FindFirstChild("HeaderFrame") :: Frame?
	if headerFrame then
		closeButton = (headerFrame:FindFirstChild("CloseImageButton") or headerFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
	end

	-- =========================================================================
	-- LEFT COLUMN (FirstFrame)
	-- =========================================================================
	firstFrame = mainFrame:FindFirstChild("FirstFrame") :: Frame?
	if firstFrame then
		-- SubFrame1: Profile Card
		local sub1 = firstFrame:FindFirstChild("SubFrame1") :: Frame?
		if sub1 then
			local discipleFrame = sub1:FindFirstChild("DiscipleFrame") :: Frame?
			if discipleFrame then
				discipleUserName = discipleFrame:FindFirstChild("DiscipleUserName") :: TextLabel?
				discipleRankName = discipleFrame:FindFirstChild("DiscipleRankName") :: TextLabel?
				discipleBadgeName = discipleFrame:FindFirstChild("DiscipleBadgeName") :: TextLabel?
			end
		end

		-- SubFrame2: Daily Stipend
		local sub2 = firstFrame:FindFirstChild("SubFrame2") :: Frame?
		if sub2 then
			stipendDescription = sub2:FindFirstChild("RewardDescription") :: TextLabel?
			stipendButton = (sub2:FindFirstChild("ImageButton") or sub2:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
			if stipendButton then
				stipendButtonText = stipendButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end

		-- SubFrame3: Promotion
		local sub3 = firstFrame:FindFirstChild("SubFrame3") :: Frame?
		if sub3 then
			promotionButton = (sub3:FindFirstChild("ImageButton") or sub3:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
			if promotionButton then
				promotionButtonText = promotionButton:FindFirstChild("TextLabel") :: TextLabel?
			end
		end
	end

	-- =========================================================================
	-- RIGHT COLUMN (SecondFrame - 3 Quest Cards)
	-- =========================================================================
	secondFrame = mainFrame:FindFirstChild("SecondFrame") :: Frame?
	table.clear(questCards)

	if secondFrame then
		for idx = 1, 3 do
			local sub = secondFrame:FindFirstChild("SubFrame" .. tostring(idx)) :: Frame?
			if sub then
				local title = sub:FindFirstChild("MissionTitle") :: TextLabel?
				local desc = sub:FindFirstChild("MissionDescription") :: TextLabel?

				local r1 = sub:FindFirstChild("Reward1") :: Frame?
				local r1Text = if r1 then r1:FindFirstChild("TextLabel") :: TextLabel? else nil
				local r2 = sub:FindFirstChild("Reward2") :: Frame?
				local r2Text = if r2 then r2:FindFirstChild("TextLabel") :: TextLabel? else nil
				local r3 = sub:FindFirstChild("Reward3") :: Frame?
				local r3Text = if r3 then r3:FindFirstChild("TextLabel") :: TextLabel? else nil

				local btn = (sub:FindFirstChild("ImageButton") or sub:FindFirstChildWhichIsA("GuiButton")) :: GuiButton?
				local btnText = if btn then btn:FindFirstChild("TextLabel") :: TextLabel? else nil
				local glow = if btn then btn:FindFirstChild("GlowOverlayImage") :: ImageLabel? else nil

				local qId = QUEST_INDEX_ORDER[idx] or "Quest_GatherSpiritGrass"

				table.insert(questCards, {
					Container = sub,
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
					btn.Activated:Connect(function()
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
		closeButton.Activated:Connect(function()
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
		stipendButton.Activated:Connect(function()
			PlayPanelClickSFX()
			sectRemote:FireServer({ Action = "ClaimDailyStipend" })
		end)
	end

	if promotionButton then
		promotionButton.Activated:Connect(function()
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

	-- 1. Client Proximity Prompt Listener for Deacon Zhao
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
		if triggeringPlayer == player then
			local action = prompt.ActionText:lower()
			local obj = prompt.ObjectText:lower()
			if string.find(action, "sect") or string.find(action, "duties") or string.find(action, "missions") or string.find(obj, "deacon") or string.find(obj, "zhao") then
				PlayPanelClickSFX()
				SectController.Open()
			end
		end
	end)

	-- 2. Server Event Listener
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
				stipendButton.BackgroundColor3 = Color3.fromRGB(75, 85, 99)
				if stipendButton:IsA("ImageButton") then
					(stipendButton :: ImageButton).ImageColor3 = Color3.fromRGB(120, 120, 130)
				end
			end
		elseif payload.Action == "PromotionSuccess" then
			currentRankId = payload.NewRank or currentRankId
			sectRemote:FireServer({ Action = "RequestSectData" })
		end
	end)

	task.defer(function()
		task.wait(1.0)
		sectRemote:FireServer({ Action = "RequestSectData" })
	end)

	print("[ASCEND] SectController Initialized (Client ProximityPrompt & Server Sync Active).")
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

function SectController.Toggle()
	if isOpen then
		SectController.Close()
	else
		SectController.Open()
	end
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
		local realm = (char and char:GetAttribute("Realm")) or "Qi Condensation - Order 1"
		local order = (char and char:GetAttribute("Order")) or 1
		local realmStr = tostring(realm):upper()
		if string.find(realmStr, "ORDER") then
			discipleBadgeName.Text = realmStr
		else
			discipleBadgeName.Text = string.format("%s - ORDER %d", realmStr, order)
		end
	end

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
		stipendDescription.Text = string.format("%d Spirit Stones + Daily Dan", rankDef.DailyStipendStones or 100)
	end

	-- 3. Promotion Button State
	local isHighestRank = (currentRankId == PROMOTION_ORDER[#PROMOTION_ORDER])
	local meetsCP = currentContribution >= targetCP
	local isEligible = not isHighestRank and meetsCP

	if promotionButton then
		local stroke = promotionButton:FindFirstChildOfClass("UIStroke")
		if isHighestRank then
			promotionButton.BackgroundColor3 = Color3.fromRGB(75, 85, 99)
			if stroke then stroke.Color = Color3.fromRGB(50, 65, 85) end
			if promotionButtonText then promotionButtonText.Text = "HIGHEST RANK ACHIEVED" end
		elseif isEligible then
			promotionButton.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
			if stroke then stroke.Color = Color3.fromRGB(253, 224, 71) end
			if promotionButtonText then promotionButtonText.Text = "REQUEST PROMOTION" end
		else
			promotionButton.BackgroundColor3 = Color3.fromRGB(75, 85, 99)
			if stroke then stroke.Color = Color3.fromRGB(50, 65, 85) end
			if promotionButtonText then promotionButtonText.Text = string.format("LOCKED (%d/%d CP)", currentContribution, targetCP) end
		end
	end

	-- 4. Update 3 Quest Cards
	for _, card in ipairs(questCards) do
		local qLive = liveQuestsData[card.QuestId]

		if not qLive then
			if card.ActionButtonText then card.ActionButtonText.Text = "..." end
			if card.GlowOverlay then card.GlowOverlay.Visible = false end
			continue
		end

		if qLive.AllTiersCompleted then
			if card.Title then
				card.Title.Text = string.format("%s — COMPLETED", (SectConfig.GetQuest(card.QuestId, 3) or {}).Title or "Duty")
			end
			if card.Description then
				card.Description.Text = "You have completed all difficulty tiers for this duty."
			end
			if card.ActionButton and card.ActionButtonText then
				card.ActionButton.BackgroundColor3 = Color3.fromRGB(50, 55, 65)
				card.ActionButtonText.Text = "COMPLETED"
				local str = card.ActionButton:FindFirstChildOfClass("UIStroke")
				if str then str.Color = Color3.fromRGB(40, 48, 60) end
			end
			if card.GlowOverlay then card.GlowOverlay.Visible = false end
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
			local str = card.ActionButton:FindFirstChildOfClass("UIStroke")
			if readyToClaim then
				card.ActionButton.BackgroundColor3 = Color3.fromRGB(16, 185, 129)
				card.ActionButtonText.Text = "CLAIM"
				if str then str.Color = Color3.fromRGB(52, 211, 153) end
				if card.GlowOverlay then card.GlowOverlay.Visible = true end
			else
				card.ActionButton.BackgroundColor3 = Color3.fromRGB(75, 85, 99)
				card.ActionButtonText.Text = "IN PROGRESS"
				if str then str.Color = Color3.fromRGB(50, 65, 85) end
				if card.GlowOverlay then card.GlowOverlay.Visible = false end
			end
		end
	end
end

function SectController.OnQuestButtonClicked(questId: string)
	local qLive = liveQuestsData[questId]
	if qLive and qLive.ReadyToClaim and not qLive.AllTiersCompleted then
		sectRemote:FireServer({ Action = "SubmitQuest", QuestId = questId })
	end
end

return SectController