-- [FLOATING +QI MEDITATION NUMBER EFFECT]
local function StartContinuousZoneMonitor()
	task.spawn(function()
		local realmColors = {
			[1] = Color3.fromRGB(180, 240, 255),
			[2] = Color3.fromRGB(120, 220, 255),
			[3] = Color3.fromRGB(255, 215, 0),
			[4] = Color3.fromRGB(200, 130, 255),
			[5] = Color3.fromRGB(255, 100, 100),
			[6] = Color3.fromRGB(110, 255, 190),
			[7] = Color3.fromRGB(255, 160, 60),
			[8] = Color3.fromRGB(255, 240, 140),
			[9] = Color3.fromRGB(220, 110, 255),
			[10] = Color3.fromRGB(255, 255, 255),
		}

		while true do
			task.wait(0.3)
			local p = game:GetService("Players").LocalPlayer
			local char = p and p.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local qiNodes = Workspace:FindFirstChild("QiNodes")

			local cultConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
			local currentRealm = char and char:GetAttribute("Realm") or player:GetAttribute("Realm")
			local playerTier = 1
			if currentRealm and cultConfig and cultConfig[currentRealm] then
				playerTier = cultConfig[currentRealm].Tier or 1
			elseif player:GetAttribute("Tier") then
				playerTier = player:GetAttribute("Tier")
			end

			local currentZone: BasePart? = nil
			local closestDist = math.huge

			if hrp and qiNodes then
				for _, node in ipairs(qiNodes:GetChildren()) do
					if node:IsA("BasePart") then
						local dist = (hrp.Position - node.Position).Magnitude
						local radius = math.max(node.Size.X, node.Size.Z) / 2 + 3
						if dist <= radius and dist < closestDist then
							currentZone = node
							closestDist = dist
						end
					end
				end
			end

			if masterGui then
				zoneFrame = masterGui:FindFirstChild("ZoneFrame") :: Frame?
				zoneTextLabel = zoneFrame and zoneFrame:FindFirstChildOfClass("TextLabel")
			end

			if zoneFrame and zoneTextLabel then
				if currentZone then
					local reqTier = (currentZone:GetAttribute("RequiredTier") or currentZone:GetAttribute("MinTier") or 1) :: number
					local reqRealm = tostring(currentZone:GetAttribute("RequiredRealm") or "Spiritual Realm")
					local nodeName = tostring(currentZone:GetAttribute("NodeName") or currentZone.Name)
					local mult = (currentZone:GetAttribute("QiMultiplier") or 1.0) :: number

					zoneFrame.Visible = true
					zoneTextLabel.FontFace = Font.fromName("Fondamento", Enum.FontWeight.Bold)
					zoneTextLabel.Font = Enum.Font.Fondamento

					if playerTier < reqTier then
						zoneTextLabel.Text = string.format("⚠️ %s [Requires Tier %d (%s) — Qi Ineffective (1.0x)]", nodeName, reqTier, reqRealm)
						zoneTextLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
					else
						zoneTextLabel.Text = string.format("✦ %s — %.1fx Qi SPEED ✦", nodeName, mult)
						zoneTextLabel.TextColor3 = realmColors[reqTier] or Color3.fromRGB(255, 255, 255)
					end
				else
					zoneFrame.Visible = false
				end
			end
		end
	end)
end

--!strict
--[[
    CultivationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
    Directly bound to MasterHUDGui.ZoneFrame and CultivationFeedbackGui.
    Manages client cultivation feedback, ascension modals, and the
    Inner Demon Tribulation screen-vignette / camera-shake / focus pulse QTE engine.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CultivationController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local camera = Workspace.CurrentCamera

local MEDITATION_SOUND_ID = "rbxassetid://124551555247426"
local ASCENSION_CHIME_SFX = "rbxassetid://131237241"
local REJECT_BUZZ_SFX = ""

local meditationSound: Sound? = nil
local isMeditating = false

-- HUD References
local masterGui: ScreenGui?
local zoneFrame: Frame?
local zoneTextLabel: TextLabel?
local zoneMonitorThread: thread? = nil

-- CultivationFeedbackGui References
local feedbackGui: ScreenGui?
local ascensionModal: Frame?
local modalMainFrame: Frame?
local modalScale: UIScale?
local headerTitle: TextLabel?
local realmTitle: TextLabel?
local hpPillText: TextLabel?
local qiPillText: TextLabel?
local multPillText: TextLabel?
local confirmBtn: TextButton?
local closeBtn: ImageButton?

local readyPrompt: Frame?
local readyScale: UIScale?
local isReadyPromptActive = false

local rejectToast: Frame?
local rejectScale: UIScale?
local rejectDesc: TextLabel?
local rejectToastThread: thread? = nil

-- Inner Demon Tribulation UI References
local innerDemonGui: ScreenGui?
local vignetteFrame: ImageLabel?
local qteContainer: Frame?
local pulseRing: Frame?
local qtePromptText: TextLabel?
local cameraShakeConnection: RBXScriptConnection?
local currentQteWave: number? = nil
local isQteActive = false

local function FormatNumber(num: number): string
	local formatted = tostring(math.floor(math.abs(num)))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

local function PlayUISound(soundId: string, volume: number?)
	if soundId == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1.0
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function SetupInnerDemonUI()
	if innerDemonGui then return end

	innerDemonGui = Instance.new("ScreenGui")
	innerDemonGui.Name = "InnerDemonTribulationGui"
	innerDemonGui.ResetOnSpawn = false
	innerDemonGui.DisplayOrder = 100
	innerDemonGui.Parent = playerGui

	vignetteFrame = Instance.new("ImageLabel")
	vignetteFrame.Name = "TribulationVignette"
	vignetteFrame.Size = UDim2.new(1, 0, 1, 0)
	vignetteFrame.BackgroundTransparency = 1
	vignetteFrame.Image = "rbxassetid://6015897843"
	vignetteFrame.ImageColor3 = Color3.fromRGB(90, 0, 40)
	vignetteFrame.ImageTransparency = 1
	vignetteFrame.Parent = innerDemonGui

	qteContainer = Instance.new("Frame")
	qteContainer.Name = "QTEContainer"
	qteContainer.Size = UDim2.new(0, 160, 0, 160)
	qteContainer.AnchorPoint = Vector2.new(0.5, 0.5)
	qteContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
	qteContainer.BackgroundTransparency = 1
	qteContainer.Visible = false
	qteContainer.Parent = innerDemonGui

	local targetRing = Instance.new("UIStroke")
	targetRing.Color = Color3.fromRGB(255, 215, 0)
	targetRing.Thickness = 3
	targetRing.Parent = qteContainer

	pulseRing = Instance.new("Frame")
	pulseRing.Name = "PulseRing"
	pulseRing.AnchorPoint = Vector2.new(0.5, 0.5)
	pulseRing.Position = UDim2.new(0.5, 0, 0.5, 0)
	pulseRing.Size = UDim2.new(1.8, 0, 1.8, 0)
	pulseRing.BackgroundTransparency = 1
	pulseRing.Parent = qteContainer

	local pulseStroke = Instance.new("UIStroke")
	pulseStroke.Color = Color3.fromRGB(255, 100, 100)
	pulseStroke.Thickness = 4
	pulseStroke.Parent = pulseRing

	qtePromptText = Instance.new("TextLabel")
	qtePromptText.Size = UDim2.new(1, 0, 0, 30)
	qtePromptText.Position = UDim2.new(0, 0, 1, 15)
	qtePromptText.BackgroundTransparency = 1
	qtePromptText.Font = Enum.Font.GothamBold
	qtePromptText.TextSize = 16
	qtePromptText.TextColor3 = Color3.fromRGB(255, 255, 255)
	qtePromptText.Text = "FOCUS MIND [SPACE / TAP]"
	qtePromptText.Parent = qteContainer
end

local function StartCameraShake()
	if cameraShakeConnection then return end
	cameraShakeConnection = RunService.RenderStepped:Connect(function()
		local dx = (math.random() - 0.5) * 0.12
		local dy = (math.random() - 0.5) * 0.12
		if camera then
			camera.CFrame = camera.CFrame * CFrame.Angles(math.rad(dx), math.rad(dy), 0)
		end
	end)
end

local function StopCameraShake()
	if cameraShakeConnection then
		cameraShakeConnection:Disconnect()
		cameraShakeConnection = nil
	end
end

local function HookStudioUI()

	StartContinuousZoneMonitor()	masterGui = (playerGui:FindFirstChild("MasterHUDGui") or playerGui:WaitForChild("MasterHUDGui", 6)) :: ScreenGui?
	if masterGui then
		zoneFrame = masterGui:FindFirstChild("ZoneFrame") :: Frame?
		if zoneFrame then
			zoneTextLabel = zoneFrame:FindFirstChildOfClass("TextLabel")
			zoneFrame.Visible = false
		end
	end

	feedbackGui = (playerGui:FindFirstChild("CultivationFeedbackGui") or playerGui:WaitForChild("CultivationFeedbackGui", 6)) :: ScreenGui?
	if feedbackGui then
		ascensionModal = feedbackGui:FindFirstChild("AscensionModal") :: Frame?
		if ascensionModal then
			modalMainFrame = ascensionModal:FindFirstChild("MainFrame") :: Frame?
			if modalMainFrame then
				modalScale = modalMainFrame:FindFirstChild("UIScale") :: UIScale?
				local header = modalMainFrame:FindFirstChild("HeaderFrame") :: Frame?
				if header then
					headerTitle = header:FindFirstChild("HeaderTitle") :: TextLabel?
					closeBtn = header:FindFirstChild("CloseButton") :: ImageButton?
				end

				local content = modalMainFrame:FindFirstChild("ContentCard") :: Frame?
				if content then
					realmTitle = content:FindFirstChild("RealmTitle") :: TextLabel?
					confirmBtn = content:FindFirstChild("ConfirmButton") :: TextButton?

					local pills = content:FindFirstChild("StatPillContainer") :: Frame?
					if pills then
						local hpPill = pills:FindFirstChild("HP_Pill") :: Frame?
						local qiPill = pills:FindFirstChild("QI_Pill") :: Frame?
						local multPill = pills:FindFirstChild("MULT_Pill") :: Frame?
						if hpPill then hpPillText = hpPill:FindFirstChild("PillText") :: TextLabel? end
						if qiPill then qiPillText = qiPill:FindFirstChild("PillText") :: TextLabel? end
						if multPill then multPillText = multPill:FindFirstChild("PillText") :: TextLabel? end
					end
				end
			end
			ascensionModal.Visible = false
		end

		readyPrompt = feedbackGui:FindFirstChild("ReadyPrompt") :: Frame?
		if readyPrompt then
			readyScale = readyPrompt:FindFirstChild("UIScale") :: UIScale?
			readyPrompt.Visible = false
		end

		rejectToast = feedbackGui:FindFirstChild("RejectionToast") :: Frame?
		if rejectToast then
			rejectScale = rejectToast:FindFirstChild("UIScale") :: UIScale?
			rejectDesc = rejectToast:FindFirstChild("RejectDesc") :: TextLabel?
			rejectToast.Visible = false
		end

		local function DismissModal()
			if not ascensionModal or not modalScale then return end
			local tInfo = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.In)
			local scaleTween = TweenService:Create(modalScale, tInfo, { Scale = 0.7 })
			local fadeTween = TweenService:Create(ascensionModal, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })
			scaleTween:Play()
			fadeTween:Play()
			scaleTween.Completed:Connect(function()
				ascensionModal.Visible = false
				modalScale.Scale = 1.0
			end)
		end

		if confirmBtn then confirmBtn.MouseButton1Click:Connect(DismissModal) end
		if closeBtn then closeBtn.MouseButton1Click:Connect(DismissModal) end
	end
end

function CultivationController.ShowRejectionToast(currentQi: number, targetQi: number, pct: number, customMessage: string?)
	if not rejectToast or not rejectDesc then return end

	if rejectToastThread then
		task.cancel(rejectToastThread)
		rejectToastThread = nil
	end

	if customMessage then
		rejectDesc.Text = customMessage
	else
		rejectDesc.Text = string.format("Current Qi: %s / %s (%d%%) • Meditate to absorb more Qi!", FormatNumber(currentQi), FormatNumber(targetQi), pct)
	end
	rejectToast.Position = UDim2.new(0.5, 0, -0.12, 0)
	rejectToast.Visible = true

	PlayUISound(REJECT_BUZZ_SFX, 0.7)

	local dropTween = TweenService:Create(rejectToast, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0.12, 0),
	})
	dropTween:Play()

	rejectToastThread = task.spawn(function()
		task.wait(3.5)
		local riseTween = TweenService:Create(rejectToast, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.12, 0),
		})
		riseTween:Play()
		riseTween.Completed:Wait()
		rejectToast.Visible = false
	end)
end

function CultivationController.ShowAscensionModal(data: { [string]: any })
	if not ascensionModal or not modalMainFrame or not modalScale then return end

	local isMajor = (data.IsMajor == true)
	if headerTitle then
		headerTitle.Text = if isMajor then "HEAVENLY ASCENSION" else "ORDER ADVANCEMENT"
	end

	if realmTitle then
		local rName = tostring(data.RealmName or data.Realm or "UNKNOWN"):upper()
		realmTitle.Text = string.format("REACHED: %s — ORDER %d", rName, tonumber(data.Order) or 1)
	end

	if hpPillText then hpPillText.Text = string.format("+%s MAX HP", FormatNumber(data.HpGain or 0)) end
	if qiPillText then qiPillText.Text = string.format("+%s MAX QI", FormatNumber(data.QiGain or 0)) end
	if multPillText then multPillText.Text = string.format("%.1fX POWER", data.PowerMultiplier or 1.0) end

	ascensionModal.BackgroundTransparency = 1
	modalScale.Scale = 0.65
	ascensionModal.Visible = true

	PlayUISound(ASCENSION_CHIME_SFX, 1.2)

	TweenService:Create(ascensionModal, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.40,
	}):Play()

	TweenService:Create(modalScale, TweenInfo.new(0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = 1.0,
	}):Play()
end

local function GetCurrentQiZoneMultiplier(character: Model): (number, string?)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 1.0, nil end

	local qiNodesFolder = Workspace:FindFirstChild("QiNodes")
	if not qiNodesFolder then return 1.0, nil end

	for _, nodePart in ipairs(qiNodesFolder:GetChildren()) do
		if nodePart:IsA("BasePart") then
			local distance = (hrp.Position - nodePart.Position).Magnitude
			local maxRadius = math.max(nodePart.Size.X, nodePart.Size.Z) / 2 + 3
			if distance <= maxRadius then
				local mult = tonumber(nodePart:GetAttribute("QiMultiplier")) or 2.0
				local name = tostring(nodePart:GetAttribute("NodeName")) or "Qi Condensation"
				return mult, name
			end
		end
	end

	return 1.0, nil
end

local function UpdateZoneBanner(character: Model)
	if not zoneFrame or not zoneTextLabel then return end

	local multiplier, nodeName = GetCurrentQiZoneMultiplier(character)

	if isMeditating then
		zoneFrame.Visible = true
		if multiplier > 1.0 then
			zoneTextLabel.Text = string.format("%s - %.1fX SPEED (MEDITATING)", (nodeName or "QI NODE"):upper(), multiplier)
		else
			zoneTextLabel.Text = "MEDITATING - 1.0X SPEED"
		end
	elseif multiplier > 1.0 then
		zoneFrame.Visible = true
		zoneTextLabel.Text = string.format("%s - %.1fX SPEED", (nodeName or "QI NODE"):upper(), multiplier)
	else
		zoneFrame.Visible = false
	end
end

function CultivationController.StartMeditation(character: Model)
	if isMeditating then return end
	isMeditating = true
	UpdateZoneBanner(character)

	if zoneMonitorThread then task.cancel(zoneMonitorThread) end
	zoneMonitorThread = task.spawn(function()
		while character.Parent do
			UpdateZoneBanner(character)
			task.wait(0.35)
		end
	end)

	TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { FieldOfView = 65 }):Play()

	if not meditationSound or meditationSound.Parent == nil then
		meditationSound = Instance.new("Sound")
		meditationSound.Name = "MeditationBGSound"
		meditationSound.SoundId = MEDITATION_SOUND_ID
		meditationSound.Looped = true
		meditationSound.Volume = 0.5
		meditationSound.Parent = SoundService
	end
	if meditationSound and not meditationSound.IsPlaying then meditationSound:Play() end
end

function CultivationController.StopMeditation(character: Model)
	if not isMeditating then return end
	isMeditating = false

	if zoneMonitorThread then
		task.cancel(zoneMonitorThread)
		zoneMonitorThread = nil
	end

	UpdateZoneBanner(character)
	if meditationSound and meditationSound.IsPlaying then meditationSound:Stop() end
	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 70 }):Play()
end

function CultivationController.Init()
	HookStudioUI()
	SetupInnerDemonUI()

	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	local cultivationActionRemote = RemoteEvents.GetRemote("CultivationAction")

		-- Connect Qi Gain Particle Feedback
	local lastTrackedMaxQi = 0
	
	cultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) ~= "table" then return end
		local character = player.Character
		if not character then return end

		-- 1. Meditation Audio & FOV Toggle
		local newMeditatingState = (data.IsMeditating == true)
		if newMeditatingState ~= isMeditating then
			if newMeditatingState then
				CultivationController.StartMeditation(character)
			else
				CultivationController.StopMeditation(character)
			end
		end

		-- 2. Dantian Saturated [B] Keybind Prompt Toggle
		if type(data.MaxQi) == "number" and type(data.TargetQi) == "number" then
			local isSaturated = (data.MaxQi >= data.TargetQi)
			if readyPrompt then
				if isSaturated and not isReadyPromptActive then
					isReadyPromptActive = true
					readyPrompt.Position = UDim2.new(0.5, 0, 0.90, 0)
					readyPrompt.Visible = true
					TweenService:Create(readyPrompt, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Position = UDim2.new(0.5, 0, 0.82, 0),
					}):Play()
				elseif not isSaturated and isReadyPromptActive then
					isReadyPromptActive = false
					readyPrompt.Visible = false
				end
			end
		end

		-- 3. Breakthrough Rejection Event Handler
		if data.Action == "BreakthroughRejected" then
			local cur = tonumber(data.CurrentQi) or 0
			local tgt = tonumber(data.TargetQi) or 1
			local pct = tonumber(data.Percentage) or math.floor((cur / math.max(1, tgt)) * 100)
			CultivationController.ShowRejectionToast(cur, tgt, pct, data.Message)
		end

		-- 4. Breakthrough Success / Ascension Event Handler
		if data.Action == "BreakthroughSuccess" then
			CultivationController.ShowAscensionModal(data)
		end
	end)

	cultivationActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "InnerDemonStart" then
			StartCameraShake()
			if vignetteFrame then
				TweenService:Create(vignetteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 0.35,
					ImageColor3 = payload.AuraColor or Color3.fromRGB(90, 0, 40),
				}):Play()
			end

		elseif payload.Action == "FocusPulsePrompt" then
			currentQteWave = payload.Wave
			isQteActive = true
			if qteContainer and pulseRing then
				qteContainer.Visible = true
				pulseRing.Size = UDim2.new(2.0, 0, 2.0, 0)
				local win = payload.Window or 1.2
				local tween = TweenService:Create(pulseRing, TweenInfo.new(win, Enum.EasingStyle.Linear), {
					Size = UDim2.new(1.0, 0, 1.0, 0),
				})
				tween:Play()
			end

		elseif payload.Action == "InnerDemonBacklash" then
			isQteActive = false
			StopCameraShake()
			if qteContainer then qteContainer.Visible = false end
			if vignetteFrame then
				vignetteFrame.ImageColor3 = Color3.fromRGB(255, 0, 0)
				vignetteFrame.ImageTransparency = 0.1
				TweenService:Create(vignetteFrame, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 1.0,
				}):Play()
			end
			CultivationController.ShowRejectionToast(0, 0, 0, payload.Message or "TRIBULATION BACKLASH: Qi Deviation!")

		elseif payload.Action == "InnerDemonSuccess" then
			isQteActive = false
			StopCameraShake()
			if qteContainer then qteContainer.Visible = false end
			if vignetteFrame then
				TweenService:Create(vignetteFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 1.0,
				}):Play()
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if isQteActive and currentQteWave then
			if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isQteActive = false
				if qteContainer then qteContainer.Visible = false end
				cultivationActionRemote:FireServer({
					Action = "FocusPulse",
					Wave = currentQteWave,
				})
				return
			end
		end

		if processed then return end
	end)

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if char and not isMeditating then
			UpdateZoneBanner(char)
		end
	end)

	print("[ASCEND] CultivationController Initialized (Inner Demon QTE & Rejection Feedback Active).")
end

return CultivationController