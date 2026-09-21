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
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

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
	if soundId == "" then return end
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.6
	sound.Parent = SoundService
	sound:Play()
	Debris:AddItem(sound, 3)
end

-- Cylindrical Zone Detector
local function GetCurrentQiZoneMultiplier(character: Model): (number, string?, boolean, string?, number?)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return 1.0, nil, false, nil, nil end

	local qiNodesFolder = Workspace:FindFirstChild("QiNodes")
	if not qiNodesFolder then return 1.0, nil, false, nil, nil end

	local curRealm = character:GetAttribute("Realm") or player:GetAttribute("Realm") or "QiCondensation"
	local realmInfo = CultivationConfig[curRealm]
	local pTier = if realmInfo and realmInfo.Tier then realmInfo.Tier else 1

	for _, nodePart in ipairs(qiNodesFolder:GetChildren()) do
		if nodePart:IsA("BasePart") then
			local flatDist = Vector3.new(hrp.Position.X - nodePart.Position.X, 0, hrp.Position.Z - nodePart.Position.Z).Magnitude
			local flatRadius = math.max(nodePart.Size.X, nodePart.Size.Z) / 2 + 8
			local vertDist = math.abs(hrp.Position.Y - nodePart.Position.Y)
			local vertMax = (nodePart.Size.Y / 2) + 35

			if flatDist <= flatRadius and vertDist <= vertMax then
				local reqTier = tonumber(nodePart:GetAttribute("RequiredTier") or nodePart:GetAttribute("MinTier")) or 1
				local reqRealm = tostring(nodePart:GetAttribute("RequiredRealm") or "Higher Realm")
				local mult = tonumber(nodePart:GetAttribute("QiMultiplier")) or 2.0
				local name = tostring(nodePart:GetAttribute("NodeName")) or nodePart.Name

				if pTier < reqTier then
					return 0, name, true, reqRealm, reqTier
				end
				return mult, name, false, reqRealm, reqTier
			end
		end
	end

	return 1.0, nil, false, nil, nil
end

local function UpdateZoneBanner(character: Model)
	if not zoneFrame or not zoneTextLabel then return end

	local multiplier, nodeName, isRestricted, reqRealm, reqTier = GetCurrentQiZoneMultiplier(character)

	zoneTextLabel.FontFace = Font.fromName("Fondamento", Enum.FontWeight.Bold)
	zoneTextLabel.Font = Enum.Font.Fondamento

	if isRestricted then
		zoneFrame.Visible = true
		zoneTextLabel.Text = string.format("⚠️ %s [REQUIRES TIER %d (%s) — QI BLOCKED (0.0x)]", (nodeName or "QI NODE"):upper(), reqTier or 1, (reqRealm or ""):upper())
		zoneTextLabel.TextColor3 = Color3.fromRGB(255, 65, 65)
	elseif isMeditating then
		zoneFrame.Visible = true
		if multiplier > 1.0 then
			zoneTextLabel.Text = string.format("✦ %s - %.1fX SPEED (MEDITATING) ✦", (nodeName or "QI NODE"):upper(), multiplier)
			zoneTextLabel.TextColor3 = Color3.fromRGB(255, 220, 80)
		else
			zoneTextLabel.Text = "MEDITATING - 1.0X SPEED"
			zoneTextLabel.TextColor3 = Color3.fromRGB(200, 240, 255)
		end
	elseif multiplier > 1.0 then
		zoneFrame.Visible = true
		zoneTextLabel.Text = string.format("✦ %s - %.1fX SPEED ✦", (nodeName or "QI NODE"):upper(), multiplier)
		zoneTextLabel.TextColor3 = Color3.fromRGB(150, 230, 255)
	else
		zoneFrame.Visible = false
	end
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
				local header = modalMainFrame:FindFirstChild("HeaderFrame")
				if header then
					headerTitle = header:FindFirstChild("TitleText") :: TextLabel?
					closeBtn = header:FindFirstChild("CloseButton") :: ImageButton?
				end

				local content = modalMainFrame:FindFirstChild("ContentCard")
				if content then
					realmTitle = content:FindFirstChild("AscensionTitle") :: TextLabel?
					local statList = content:FindFirstChild("StatList")
					if statList then
						local hpCard = statList:FindFirstChild("HpCard")
						if hpCard then hpPillText = hpCard:FindFirstChild("StatValue") :: TextLabel? end

						local qiCard = statList:FindFirstChild("QiCard")
						if qiCard then qiPillText = qiCard:FindFirstChild("StatValue") :: TextLabel? end

						local multCard = statList:FindFirstChild("MultCard")
						if multCard then multPillText = multCard:FindFirstChild("StatValue") :: TextLabel? end
					end
					confirmBtn = content:FindFirstChild("ConfirmButton") :: TextButton?
				end
			end
		end

		readyPrompt = feedbackGui:FindFirstChild("ReadyPrompt") :: Frame?
		if readyPrompt then
			readyScale = readyPrompt:FindFirstChild("UIScale") :: UIScale?
			readyPrompt.Visible = false
		end

		rejectToast = feedbackGui:FindFirstChild("RejectionToast") :: Frame?
		if rejectToast then
			rejectScale = rejectToast:FindFirstChild("UIScale") :: UIScale?
			local toastMain = rejectToast:FindFirstChild("MainFrame")
			if toastMain then
				rejectDesc = toastMain:FindFirstChild("ToastDesc") :: TextLabel?
			end
			rejectToast.Visible = false
		end

		if confirmBtn then confirmBtn.MouseButton1Click:Connect(CultivationController.HideAscensionModal) end
		if closeBtn then closeBtn.MouseButton1Click:Connect(CultivationController.HideAscensionModal) end
	end
end

function CultivationController.ShowAscensionModal(data: { [string]: any })
	if not ascensionModal or not modalMainFrame or not modalScale then return end
	local isMajor = (data.IsMajor == true)

	if headerTitle then
		headerTitle.Text = if isMajor then "HEAVENLY ASCENSION" else "ORDER ADVANCEMENT"
	end

	if realmTitle then
		local rName = tostring(data.RealmName or data.Realm or "UNKNOWN"):upper()
		realmTitle.Text = string.format("REACHED: %s — ORDER %d", rName, tonumber(data.Order or data.NewOrder) or 1)
	end

	if hpPillText then hpPillText.Text = string.format("+%s MAX HP", FormatNumber(data.HpGain or 0)) end
	if qiPillText then qiPillText.Text = string.format("+%s MAX QI", FormatNumber(data.QiGain or 0)) end
	if multPillText then multPillText.Text = string.format("%.2fX POWER", tonumber(data.PowerMultiplier) or 1.0) end

	modalScale.Scale = 0.8
	ascensionModal.Visible = true
	PlayUISound(ASCENSION_CHIME_SFX, 0.8)
	TweenService:Create(modalScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

function CultivationController.HideAscensionModal()
	if not ascensionModal or not modalScale then return end
	local tween = TweenService:Create(modalScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.8 })
	tween:Play()
	tween.Completed:Connect(function()
		ascensionModal.Visible = false
	end)
end

function CultivationController.ShowRejectionToast(curQi: number, tgtQi: number, pct: number, customMessage: string?)
	if not rejectToast or not rejectDesc or not rejectScale then return end
	if rejectToastThread then task.cancel(rejectToastThread) end

	rejectDesc.Text = customMessage or string.format("Current Qi: %s / %s (%d%%) • Meditate to absorb more Qi!", FormatNumber(curQi), FormatNumber(tgtQi), pct)
	rejectScale.Scale = 0.8
	rejectToast.Visible = true
	PlayUISound(REJECT_BUZZ_SFX, 0.4)

	TweenService:Create(rejectScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	rejectToastThread = task.spawn(function()
		task.wait(2.5)
		local fade = TweenService:Create(rejectScale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.8 })
		fade:Play()
		fade.Completed:Connect(function()
			rejectToast.Visible = false
		end)
	end)
end

function CultivationController.StartMeditation(character: Model)
	if isMeditating then return end
	isMeditating = true

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

	if meditationSound and meditationSound.IsPlaying then
		local fadeOut = TweenService:Create(meditationSound, TweenInfo.new(0.5), { Volume = 0 })
		fadeOut:Play()
		fadeOut.Completed:Connect(function()
			if not isMeditating and meditationSound then
				meditationSound:Stop()
				meditationSound.Volume = 0.5
			end
		end)
	end

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 70 }):Play()
end

function CultivationController.Init()
	HookStudioUI()

	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	cultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) ~= "table" then return end
		local character = player.Character
		if not character then return end

		-- 1. Meditation Toggle
		local newMeditating = (data.IsMeditating == true)
		if newMeditating ~= isMeditating then
			if newMeditating then
				CultivationController.StartMeditation(character)
			else
				CultivationController.StopMeditation(character)
			end
		end

		-- 2. Ready Prompt
		if type(data.MaxQi) == "number" and type(data.TargetQi) == "number" then
			local isSaturated = (data.MaxQi >= data.TargetQi)
			if readyPrompt then
				if isSaturated and not isReadyPromptActive then
					isReadyPromptActive = true
					readyPrompt.Visible = true
					if readyScale then
						readyScale.Scale = 0.8
						TweenService:Create(readyScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
					end
				elseif not isSaturated and isReadyPromptActive then
					isReadyPromptActive = false
					readyPrompt.Visible = false
				end
			end
		end

		-- 3. Breakthrough Rejected
		if data.Action == "BreakthroughRejected" then
			local cur = tonumber(data.CurrentQi) or 0
			local tgt = tonumber(data.TargetQi) or 1
			local pct = tonumber(data.Percentage) or math.floor((cur / math.max(1, tgt)) * 100)
			CultivationController.ShowRejectionToast(cur, tgt, pct, data.Message)
		end

		-- 4. Breakthrough Success
		if data.Action == "BreakthroughSuccess" then
			CultivationController.ShowAscensionModal(data)
		end
	end)

	-- Continuous Zone Monitor Loop
	task.spawn(function()
		while true do
			task.wait(0.3)
			local char = player.Character
			if char and char.Parent then
				UpdateZoneBanner(char)
			end
		end
	end)

	print("[ASCEND] CultivationController Initialized Successfully.")
end

return CultivationController