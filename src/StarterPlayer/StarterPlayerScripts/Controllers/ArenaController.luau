--!strict
--[[
    ArenaController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/ArenaController.luau
    Client UI controller for the 1v1 Balanced Sparring Arena.
    Features: Sparring Registration Modal, queue status banner, 90s duel countdown HUD, and victory fanfare.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local ArenaController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UI_FONT = Enum.Font.FredokaOne
local T = UIAssets.Theme

local CLICK_SOUND_ID = "rbxassetid://6895079853"
local arenaRemote: RemoteEvent

-- UI Instances
local screenGui: ScreenGui
local registrationModal: Frame
local regTitleLabel: TextLabel
local regDescLabel: TextLabel
local queueToggleBtn: TextButton

local queueBanner: Frame
local queueStatusText: TextLabel
local matchHUD: Frame
local timerLabel: TextLabel
local opponentNameLabel: TextLabel
local opponentHpFill: Frame
local resultModal: Frame
local resultTitle: TextLabel
local resultRewardText: TextLabel

-- State
local isQueued = false
local isDuelActive = false
local currentDuelTime = 90
local duelTimerThread: thread? = nil
local opponentPlayer: Player? = nil
local opponentHpConn: RBXScriptConnection? = nil
local playerRealmName = "Qi Condensation"

local function PlayClickAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)
end

function ArenaController.OpenRegistrationModal()
	if isDuelActive then return end
	registrationModal.Visible = true
	ArenaController.UpdateRegistrationUI()
end

function ArenaController.CloseRegistrationModal()
	registrationModal.Visible = false
end

function ArenaController.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	ArenaController.BuildUI()

	-- Network Listeners
	arenaRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "OpenArenaMenu" then
			ArenaController.OpenRegistrationModal()
		elseif action == "QueueJoined" then
			isQueued = true
			playerRealmName = payload.Realm or playerRealmName
			ArenaController.ShowQueueBanner(playerRealmName)
			ArenaController.UpdateRegistrationUI()
		elseif action == "QueueLeft" then
			isQueued = false
			ArenaController.HideQueueBanner()
			ArenaController.UpdateRegistrationUI()
		elseif action == "DuelStarting" then
			isQueued = false
			ArenaController.HideQueueBanner()
			ArenaController.CloseRegistrationModal()
			ArenaController.StartDuelHUD(payload.OpponentName, payload.Realm, payload.Duration or 90)
		elseif action == "DuelEnded" then
			ArenaController.EndDuelHUD(payload.IsWinner, payload.IsDraw, payload.Reason, payload.RewardContribution, payload.RewardStones)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.P then
			if registrationModal.Visible then
				ArenaController.CloseRegistrationModal()
			else
				ArenaController.OpenRegistrationModal()
			end
		elseif input.KeyCode == Enum.KeyCode.Escape and registrationModal.Visible then
			ArenaController.CloseRegistrationModal()
		end
	end)

	print("[ASCEND] ArenaController Initialized (Registration Modal & 1v1 Sparring Active).")
end

function ArenaController.BuildUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ArenaHUDGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 18
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	-- 1. Registration Modal (Center Screen)
	registrationModal = Instance.new("Frame")
	registrationModal.Name = "RegistrationModal"
	registrationModal.Size = UDim2.new(0, 480, 0, 260)
	registrationModal.Position = UDim2.new(0.5, 0, 0.5, 0)
	registrationModal.AnchorPoint = Vector2.new(0.5, 0.5)
	registrationModal.BackgroundColor3 = T.DeepBackground
	registrationModal.BorderSizePixel = 0
	registrationModal.Visible = false
	registrationModal.Parent = screenGui

	local rmCorner = Instance.new("UICorner")
	rmCorner.CornerRadius = UDim.new(0, 10)
	rmCorner.Parent = registrationModal

	local rmStroke = Instance.new("UIStroke")
	rmStroke.Color = T.HighlightBorder
	rmStroke.Thickness = 2
	rmStroke.Parent = registrationModal

	local headerBar = Instance.new("Frame")
	headerBar.Size = UDim2.new(1, 0, 0, 44)
	headerBar.BackgroundColor3 = T.SecondarySurface
	headerBar.BorderSizePixel = 0
	headerBar.Parent = registrationModal

	local hbCorner = Instance.new("UICorner")
	hbCorner.CornerRadius = UDim.new(0, 10)
	hbCorner.Parent = headerBar

	regTitleLabel = Instance.new("TextLabel")
	regTitleLabel.Size = UDim2.new(1, -50, 1, 0)
	regTitleLabel.Position = UDim2.new(0, 14, 0, 0)
	regTitleLabel.BackgroundTransparency = 1
	regTitleLabel.Text = "⚔️ SECT SPARRING ARENA"
	regTitleLabel.TextColor3 = T.HighlightBorder
	regTitleLabel.Font = UI_FONT
	regTitleLabel.TextSize = 16
	regTitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	regTitleLabel.Parent = headerBar

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 32, 0, 32)
	closeBtn.Position = UDim2.new(1, -38, 0.5, -16)
	closeBtn.BackgroundColor3 = T.Vermilion
	closeBtn.Text = "X"
	closeBtn.TextColor3 = T.PrimaryText
	closeBtn.Font = UI_FONT
	closeBtn.TextSize = 16
	closeBtn.Parent = headerBar

	local cbCorner = Instance.new("UICorner")
	cbCorner.CornerRadius = UDim.new(0, 6)
	cbCorner.Parent = closeBtn

	closeBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		ArenaController.CloseRegistrationModal()
	end)

	regDescLabel = Instance.new("TextLabel")
	regDescLabel.Size = UDim2.new(1, -32, 0, 90)
	regDescLabel.Position = UDim2.new(0, 16, 0, 56)
	regDescLabel.BackgroundTransparency = 1
	regDescLabel.Text = "Engage in 1v1 balanced martial sparring against disciples in your exact Cultivation Realm bracket.\n\n• Match Duration: 90 Seconds\n• Victory: +100 Contribution | +150 Stones\n• Non-Lethal Resolution"
	regDescLabel.TextColor3 = T.SecondaryText
	regDescLabel.Font = UI_FONT
	regDescLabel.TextSize = 12
	regDescLabel.TextWrapped = true
	regDescLabel.TextXAlignment = Enum.TextXAlignment.Left
	regDescLabel.TextYAlignment = Enum.TextYAlignment.Top
	regDescLabel.Parent = registrationModal

	queueToggleBtn = Instance.new("TextButton")
	queueToggleBtn.Size = UDim2.new(1, -32, 0, 46)
	queueToggleBtn.Position = UDim2.new(0, 16, 1, -60)
	queueToggleBtn.BackgroundColor3 = T.JadeAccent
	queueToggleBtn.Text = "ENTER SPARRING QUEUE"
	queueToggleBtn.TextColor3 = T.PrimaryText
	queueToggleBtn.Font = UI_FONT
	queueToggleBtn.TextSize = 15
	queueToggleBtn.Parent = registrationModal

	local qbCorner = Instance.new("UICorner")
	qbCorner.CornerRadius = UDim.new(0, 6)
	qbCorner.Parent = queueToggleBtn

	queueToggleBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		if isQueued then
			arenaRemote:FireServer({ Action = "LeaveQueue" })
		else
			arenaRemote:FireServer({ Action = "JoinQueue" })
		end
	end)

	-- 2. Queue Status Banner (Top Center)
	queueBanner = Instance.new("Frame")
	queueBanner.Name = "QueueBanner"
	queueBanner.Size = UDim2.new(0, 320, 0, 40)
	queueBanner.Position = UDim2.new(0.5, 0, 0, 15)
	queueBanner.AnchorPoint = Vector2.new(0.5, 0)
	queueBanner.BackgroundColor3 = T.DeepBackground
	queueBanner.BorderSizePixel = 0
	queueBanner.Visible = false
	queueBanner.Parent = screenGui

	local qbCorner2 = Instance.new("UICorner")
	qbCorner2.CornerRadius = UDim.new(0, 6)
	qbCorner2.Parent = queueBanner

	local qbStroke = Instance.new("UIStroke")
	qbStroke.Color = T.MainBorder
	qbStroke.Thickness = 1.5
	qbStroke.Parent = queueBanner

	queueStatusText = Instance.new("TextLabel")
	queueStatusText.Size = UDim2.new(1, -70, 1, 0)
	queueStatusText.Position = UDim2.new(0, 10, 0, 0)
	queueStatusText.BackgroundTransparency = 1
	queueStatusText.Text = "⚔️ SEARCHING FOR OPPONENT..."
	queueStatusText.TextColor3 = T.HighlightBorder
	queueStatusText.Font = UI_FONT
	queueStatusText.TextSize = 12
	queueStatusText.TextXAlignment = Enum.TextXAlignment.Left
	queueStatusText.Parent = queueBanner

	local leaveBtn = Instance.new("TextButton")
	leaveBtn.Size = UDim2.new(0, 54, 0, 26)
	leaveBtn.Position = UDim2.new(1, -60, 0.5, -13)
	leaveBtn.BackgroundColor3 = T.Vermilion
	leaveBtn.Text = "LEAVE"
	leaveBtn.TextColor3 = T.PrimaryText
	leaveBtn.Font = UI_FONT
	leaveBtn.TextSize = 11
	leaveBtn.Parent = queueBanner

	local lbCorner = Instance.new("UICorner")
	lbCorner.CornerRadius = UDim.new(0, 4)
	lbCorner.Parent = leaveBtn

	leaveBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		arenaRemote:FireServer({ Action = "LeaveQueue" })
	end)

	-- 3. In-Match Top Duel Bar
	matchHUD = Instance.new("Frame")
	matchHUD.Name = "MatchHUD"
	matchHUD.Size = UDim2.new(0, 440, 0, 64)
	matchHUD.Position = UDim2.new(0.5, 0, 0, 15)
	matchHUD.AnchorPoint = Vector2.new(0.5, 0)
	matchHUD.BackgroundColor3 = T.DeepBackground
	matchHUD.BorderSizePixel = 0
	matchHUD.Visible = false
	matchHUD.Parent = screenGui

	local mhCorner = Instance.new("UICorner")
	mhCorner.CornerRadius = UDim.new(0, 8)
	mhCorner.Parent = matchHUD

	local mhStroke = Instance.new("UIStroke")
	mhStroke.Color = T.HighlightBorder
	mhStroke.Thickness = 2
	mhStroke.Parent = matchHUD

	timerLabel = Instance.new("TextLabel")
	timerLabel.Size = UDim2.new(0, 60, 0, 26)
	timerLabel.Position = UDim2.new(0.5, -30, 0, 6)
	timerLabel.BackgroundColor3 = T.SecondarySurface
	timerLabel.Text = "90s"
	timerLabel.TextColor3 = T.PrimaryText
	timerLabel.Font = UI_FONT
	timerLabel.TextSize = 14
	timerLabel.Parent = matchHUD

	local tlCorner = Instance.new("UICorner")
	tlCorner.CornerRadius = UDim.new(0, 4)
	tlCorner.Parent = timerLabel

	opponentNameLabel = Instance.new("TextLabel")
	opponentNameLabel.Size = UDim2.new(1, -20, 0, 20)
	opponentNameLabel.Position = UDim2.new(0, 10, 0, 8)
	opponentNameLabel.BackgroundTransparency = 1
	opponentNameLabel.Text = "OPPONENT: PLAYER"
	opponentNameLabel.TextColor3 = T.HighlightBorder
	opponentNameLabel.Font = UI_FONT
	opponentNameLabel.TextSize = 13
	opponentNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	opponentNameLabel.Parent = matchHUD

	local oppHpBg = Instance.new("Frame")
	oppHpBg.Size = UDim2.new(1, -20, 0, 16)
	oppHpBg.Position = UDim2.new(0, 10, 0, 38)
	oppHpBg.BackgroundColor3 = T.SecondarySurface
	oppHpBg.BorderSizePixel = 0
	oppHpBg.Parent = matchHUD

	local hpbCorner = Instance.new("UICorner")
	hpbCorner.CornerRadius = UDim.new(0, 4)
	hpbCorner.Parent = oppHpBg

	opponentHpFill = Instance.new("Frame")
	opponentHpFill.Size = UDim2.new(1, 0, 1, 0)
	opponentHpFill.BackgroundColor3 = T.Vermilion
	opponentHpFill.BorderSizePixel = 0
	opponentHpFill.Parent = oppHpBg

	local hpfCorner = Instance.new("UICorner")
	hpfCorner.CornerRadius = UDim.new(0, 4)
	hpfCorner.Parent = opponentHpFill

	-- 4. Match Result Modal
	resultModal = Instance.new("Frame")
	resultModal.Name = "ResultModal"
	resultModal.Size = UDim2.new(0, 360, 0, 140)
	resultModal.Position = UDim2.new(0.5, 0, 0.4, 0)
	resultModal.AnchorPoint = Vector2.new(0.5, 0.5)
	resultModal.BackgroundColor3 = T.DeepBackground
	resultModal.BorderSizePixel = 0
	resultModal.Visible = false
	resultModal.Parent = screenGui

	local rmodalCorner = Instance.new("UICorner")
	rmodalCorner.CornerRadius = UDim.new(0, 10)
	rmodalCorner.Parent = resultModal

	local rmodalStroke = Instance.new("UIStroke")
	rmodalStroke.Color = T.HighlightBorder
	rmodalStroke.Thickness = 2
	rmodalStroke.Parent = resultModal

	resultTitle = Instance.new("TextLabel")
	resultTitle.Size = UDim2.new(1, 0, 0, 48)
	resultTitle.Position = UDim2.new(0, 0, 0, 10)
	resultTitle.BackgroundTransparency = 1
	resultTitle.Text = "🏆 VICTORY!"
	resultTitle.TextColor3 = T.JadeAccent
	resultTitle.Font = UI_FONT
	resultTitle.TextSize = 28
	resultTitle.Parent = resultModal

	resultRewardText = Instance.new("TextLabel")
	resultRewardText.Size = UDim2.new(1, -20, 0, 40)
	resultRewardText.Position = UDim2.new(0, 10, 0, 65)
	resultRewardText.BackgroundTransparency = 1
	resultRewardText.Text = "+100 Contribution Points | +150 Spirit Stones"
	resultRewardText.TextColor3 = T.PrimaryText
	resultRewardText.Font = UI_FONT
	resultRewardText.TextSize = 14
	resultRewardText.Parent = resultModal
end

function ArenaController.UpdateRegistrationUI()
	if queueToggleBtn then
		if isQueued then
			queueToggleBtn.Text = "LEAVE SPARRING QUEUE"
			queueToggleBtn.BackgroundColor3 = T.Vermilion
		else
			queueToggleBtn.Text = "ENTER SPARRING QUEUE"
			queueToggleBtn.BackgroundColor3 = T.JadeAccent
		end
	end
end

function ArenaController.ShowQueueBanner(realm: string)
	queueStatusText.Text = string.format("⚔️ QUEUED: %s BRACKET", realm:upper())
	queueBanner.Visible = true
end

function ArenaController.HideQueueBanner()
	queueBanner.Visible = false
end

function ArenaController.StartDuelHUD(opponentName: string, realm: string, duration: number)
	isDuelActive = true
	currentDuelTime = duration
	matchHUD.Visible = true
	opponentNameLabel.Text = string.format("OPPONENT: %s (%s)", opponentName:upper(), realm:upper())
	opponentHpFill.Size = UDim2.new(1, 0, 1, 0)
	timerLabel.Text = duration .. "s"

	opponentPlayer = Players:FindFirstChild(opponentName) :: Player?
	if opponentHpConn then opponentHpConn:Disconnect() end

	if opponentPlayer and opponentPlayer.Character then
		local hum = opponentPlayer.Character:FindFirstChild("Humanoid") :: Humanoid?
		if hum then
			opponentHpConn = hum.HealthChanged:Connect(function(health)
				local ratio = math.clamp(health / math.max(1, hum.MaxHealth), 0, 1)
				opponentHpFill.Size = UDim2.new(ratio, 0, 1, 0)
			end)
		end
	end

	if duelTimerThread then task.cancel(duelTimerThread) end
	duelTimerThread = task.spawn(function()
		while isDuelActive and currentDuelTime > 0 do
			task.wait(1)
			currentDuelTime -= 1
			timerLabel.Text = currentDuelTime .. "s"
		end
	end)
end

function ArenaController.EndDuelHUD(isWinner: boolean, isDraw: boolean, reason: string, rewardContrib: number, rewardStones: number)
	isDuelActive = false
	if duelTimerThread then task.cancel(duelTimerThread) end
	if opponentHpConn then opponentHpConn:Disconnect() end

	matchHUD.Visible = false

	if isWinner then
		resultTitle.Text = "🏆 VICTORY!"
		resultTitle.TextColor3 = T.JadeAccent
	elseif isDraw then
		resultTitle.Text = "🤝 DRAW MATCH"
		resultTitle.TextColor3 = T.SpiritBlue
	else
		resultTitle.Text = "💀 DUEL FINISHED"
		resultTitle.TextColor3 = T.Vermilion
	end

	resultRewardText.Text = string.format("+%d Contribution  |  +%d Spirit Stones\n(%s)", rewardContrib, rewardStones, reason)
	resultModal.Visible = true

	task.delay(4.5, function()
		resultModal.Visible = false
	end)
end

return ArenaController