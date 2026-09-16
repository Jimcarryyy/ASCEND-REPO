--!strict
--[[
    ArenaController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/ArenaController.luau
    Authoritative client controller for On-Demand Duels and Sparring HUD:
    - Interactive Sparring Challenge invitations
    - Dynamic Qi Ring duel countdown and timer HUD
    - Match victory / concession notifications
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local ArenaController = {}

local arenaRemote: RemoteEvent? = nil

-- UI References
local sparringHud: ScreenGui?
local challengeModal: Frame?
local challengerNameText: TextLabel?
local acceptBtn: TextButton?
local declineBtn: TextButton?

local matchTimerFrame: Frame?
local timerText: TextLabel?
local timerThread: thread? = nil

local resultBanner: Frame?
local resultTitle: TextLabel?
local resultDesc: TextLabel?

local currentChallenger: Player? = nil

local function PlayUISound(soundId: string, volume: number?)
	if soundId == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1.0
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function() sound:Destroy() end)
end

local function SetupSparringUI()
	if sparringHud then return end

	sparringHud = Instance.new("ScreenGui")
	sparringHud.Name = "SparringDuelHUD"
	sparringHud.ResetOnSpawn = false
	sparringHud.DisplayOrder = 90
	sparringHud.Parent = playerGui

	-- 1. Duel Challenge Modal
	challengeModal = Instance.new("Frame")
	challengeModal.Name = "ChallengeModal"
	challengeModal.Size = UDim2.new(0, 320, 0, 150)
	challengeModal.AnchorPoint = Vector2.new(0.5, 0)
	challengeModal.Position = UDim2.new(0.5, 0, -0.2, 0)
	challengeModal.BackgroundColor3 = Color3.fromRGB(15, 20, 30)
	challengeModal.BorderSizePixel = 0
	challengeModal.Visible = false
	challengeModal.Parent = sparringHud

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 220, 255)
	stroke.Thickness = 2
	stroke.Parent = challengeModal

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = challengeModal

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 30)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16
	title.TextColor3 = Color3.fromRGB(255, 215, 0)
	title.Text = "SPARRING CHALLENGE"
	title.Parent = challengeModal

	challengerNameText = Instance.new("TextLabel")
	challengerNameText.Size = UDim2.new(1, -20, 0, 40)
	challengerNameText.Position = UDim2.new(0, 10, 0, 35)
	challengerNameText.BackgroundTransparency = 1
	challengerNameText.Font = Enum.Font.Gotham
	challengerNameText.TextSize = 14
	challengerNameText.TextColor3 = Color3.fromRGB(230, 240, 255)
	challengerNameText.Text = "Cultivator challenges you to a duel!"
	challengerNameText.TextWrapped = true
	challengerNameText.Parent = challengeModal

	acceptBtn = Instance.new("TextButton")
	acceptBtn.Size = UDim2.new(0, 120, 0, 36)
	acceptBtn.Position = UDim2.new(0, 25, 0, 95)
	acceptBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 100)
	acceptBtn.Font = Enum.Font.GothamBold
	acceptBtn.TextSize = 14
	acceptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	acceptBtn.Text = "ACCEPT"
	acceptBtn.Parent = challengeModal
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = acceptBtn

	declineBtn = Instance.new("TextButton")
	declineBtn.Size = UDim2.new(0, 120, 0, 36)
	declineBtn.Position = UDim2.new(1, -145, 0, 95)
	declineBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
	declineBtn.Font = Enum.Font.GothamBold
	declineBtn.TextSize = 14
	declineBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	declineBtn.Text = "DECLINE"
	declineBtn.Parent = challengeModal
	local btnCorner2 = Instance.new("UICorner")
	btnCorner2.CornerRadius = UDim.new(0, 6)
	btnCorner2.Parent = declineBtn

	-- 2. Duel Timer Display
	matchTimerFrame = Instance.new("Frame")
	matchTimerFrame.Name = "MatchTimerFrame"
	matchTimerFrame.Size = UDim2.new(0, 200, 0, 50)
	matchTimerFrame.AnchorPoint = Vector2.new(0.5, 0)
	matchTimerFrame.Position = UDim2.new(0.5, 0, 0.05, 0)
	matchTimerFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	matchTimerFrame.BackgroundTransparency = 0.3
	matchTimerFrame.BorderSizePixel = 0
	matchTimerFrame.Visible = false
	matchTimerFrame.Parent = sparringHud

	local tCorner = Instance.new("UICorner")
	tCorner.CornerRadius = UDim.new(0, 8)
	tCorner.Parent = matchTimerFrame

	local tStroke = Instance.new("UIStroke")
	tStroke.Color = Color3.fromRGB(0, 220, 255)
	tStroke.Thickness = 2
	tStroke.Parent = matchTimerFrame

	timerText = Instance.new("TextLabel")
	timerText.Size = UDim2.new(1, 0, 1, 0)
	timerText.BackgroundTransparency = 1
	timerText.Font = Enum.Font.GothamBold
	timerText.TextSize = 20
	timerText.TextColor3 = Color3.fromRGB(255, 255, 255)
	timerText.Text = "SPARRING: 90s"
	timerText.Parent = matchTimerFrame

	-- 3. Match Result Banner
	resultBanner = Instance.new("Frame")
	resultBanner.Name = "ResultBanner"
	resultBanner.Size = UDim2.new(0, 400, 0, 100)
	resultBanner.AnchorPoint = Vector2.new(0.5, 0.5)
	resultBanner.Position = UDim2.new(0.5, 0, 0.35, 0)
	resultBanner.BackgroundColor3 = Color3.fromRGB(10, 15, 25)
	resultBanner.BackgroundTransparency = 0.2
	resultBanner.BorderSizePixel = 0
	resultBanner.Visible = false
	resultBanner.Parent = sparringHud

	local rCorner = Instance.new("UICorner")
	rCorner.CornerRadius = UDim.new(0, 10)
	rCorner.Parent = resultBanner

	resultTitle = Instance.new("TextLabel")
	resultTitle.Size = UDim2.new(1, 0, 0, 45)
	resultTitle.Position = UDim2.new(0, 0, 0, 10)
	resultTitle.BackgroundTransparency = 1
	resultTitle.Font = Enum.Font.GothamBold
	resultTitle.TextSize = 26
	resultTitle.Text = "VICTORY"
	resultTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
	resultTitle.Parent = resultBanner

	resultDesc = Instance.new("TextLabel")
	resultDesc.Size = UDim2.new(1, 0, 0, 30)
	resultDesc.Position = UDim2.new(0, 0, 0, 55)
	resultDesc.BackgroundTransparency = 1
	resultDesc.Font = Enum.Font.Gotham
	resultDesc.TextSize = 14
	resultDesc.TextColor3 = Color3.fromRGB(200, 220, 240)
	resultDesc.Text = "Concession acknowledged. Realm stats restored."
	resultDesc.Parent = resultBanner

	-- Button Interactions
	if acceptBtn then
		acceptBtn.MouseButton1Click:Connect(function()
			if challengeModal then challengeModal.Visible = false end
			if arenaRemote and currentChallenger then
				arenaRemote:FireServer({ Action = "AcceptChallenge", Challenger = currentChallenger })
			end
			currentChallenger = nil
		end)
	end

	if declineBtn then
		declineBtn.MouseButton1Click:Connect(function()
			if challengeModal then challengeModal.Visible = false end
			if arenaRemote then
				arenaRemote:FireServer({ Action = "DeclineChallenge" })
			end
			currentChallenger = nil
		end)
	end
end

function ArenaController.ShowChallengePrompt(challenger: Player, challengerName: string)
	if not challengeModal or not challengerNameText then return end

	currentChallenger = challenger
	challengerNameText.Text = string.format("Cultivator %s (@%s) challenges you to a sparring duel!", challengerName, challenger.Name)
	challengeModal.Visible = true
	challengeModal.Position = UDim2.new(0.5, 0, -0.15, 0)

	PlayUISound("rbxassetid://9114223170", 1.0)

	TweenService:Create(challengeModal, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.10, 0),
	}):Play()
end

function ArenaController.StartDuelHUD(duration: number)
	if not matchTimerFrame or not timerText then return end

	matchTimerFrame.Visible = true
	PlayUISound("rbxassetid://131237241", 1.2)

	if timerThread then task.cancel(timerThread) end
	timerThread = task.spawn(function()
		local remaining = duration
		while remaining > 0 do
			timerText.Text = string.format("SPARRING: %ds", remaining)
			task.wait(1.0)
			remaining -= 1
		end
		timerText.Text = "TIME'S UP"
	end)
end

function ArenaController.ShowMatchResult(isWinner: boolean, reason: string?)
	if not resultBanner or not resultTitle or not resultDesc then return end

	if timerThread then task.cancel(timerThread) end
	if matchTimerFrame then matchTimerFrame.Visible = false end

	resultTitle.Text = if isWinner then "SPARRING VICTORY" else "SPARRING CONCESSION"
	resultTitle.TextColor3 = if isWinner then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(200, 100, 100)
	resultDesc.Text = reason or "Non-lethal match concluded. Realm stats restored."

	resultBanner.Visible = true
	resultBanner.BackgroundTransparency = 1
	resultBanner.Position = UDim2.new(0.5, 0, 0.30, 0)

	TweenService:Create(resultBanner, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.35, 0),
		BackgroundTransparency = 0.2,
	}):Play()

	task.delay(4.0, function()
		if resultBanner and resultBanner.Visible then
			local fade = TweenService:Create(resultBanner, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			fade:Play()
			fade.Completed:Connect(function()
				resultBanner.Visible = false
			end)
		end
	end)
end

function ArenaController.Init()
	SetupSparringUI()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	if arenaRemote then
		arenaRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end

			if payload.Action == "DuelChallenged" and payload.Challenger then
				ArenaController.ShowChallengePrompt(payload.Challenger, payload.ChallengerName or payload.Challenger.DisplayName)

			elseif payload.Action == "DuelStarting" then
				ArenaController.StartDuelHUD(payload.Duration or 90)

			elseif payload.Action == "DuelEnded" then
				ArenaController.ShowMatchResult(payload.IsWinner == true, payload.Reason)
			end
		end)
	end

	print("[ASCEND] ArenaController Initialized (On-Demand Sparring & Qi Ring UI Active).")
end

return ArenaController