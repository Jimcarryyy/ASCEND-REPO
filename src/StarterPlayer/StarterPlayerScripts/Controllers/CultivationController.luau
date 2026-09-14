--!strict
--[[
    CultivationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
    Directly bound to MasterHUDGui.ZoneFrame and CultivationFeedbackGui.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

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
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1.0
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

local function HookStudioUI()
	masterGui = (playerGui:FindFirstChild("MasterHUDGui") or playerGui:WaitForChild("MasterHUDGui", 6)) :: ScreenGui?
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

function CultivationController.ShowRejectionToast(currentQi: number, targetQi: number, pct: number)
	if not rejectToast or not rejectDesc then return end

	if rejectToastThread then
		task.cancel(rejectToastThread)
		rejectToastThread = nil
	end

	rejectDesc.Text = string.format("Current Qi: %s / %s (%d%%) • Meditate to absorb more Qi!", FormatNumber(currentQi), FormatNumber(targetQi), pct)
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
		while isMeditating and character.Parent do
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

	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
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
			CultivationController.ShowRejectionToast(cur, tgt, pct)
		end

		-- 4. Breakthrough Success / Ascension Event Handler
		if data.Action == "BreakthroughSuccess" then
			CultivationController.ShowAscensionModal(data)
		end
	end)

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if char and not isMeditating then
			UpdateZoneBanner(char)
		end
	end)

	print("[ASCEND] CultivationController Initialized (Breakthrough & Rejection Feedback Active).")
end

return CultivationController