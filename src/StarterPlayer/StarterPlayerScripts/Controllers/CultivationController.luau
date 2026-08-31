--!strict
--[[
    CultivationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
    Client controller for meditation camera adjustments, audio, and QiNode Zone Visuals:
    - Real-time Top-Left Meditation Status Banner (Underneath default Roblox top-bar buttons)
    - Validates whether disciple is currently meditating inside a Qi Multiplier zone
    - Automatically attaches floating Bangers Billboard above QiNode zones
    - Dynamically colors dome mesh & light based on QiMultiplier tier
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
local playerGui = player:WaitForChild("PlayerGui")
local camera = Workspace.CurrentCamera

local isMeditating = false
local MEDITATION_SOUND_ID = "rbxassetid://124551555247426"
local meditationSound: Sound? = nil

local FONT_TITLE = Enum.Font.Bangers
local TWEEN_FAST = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Top-Left HUD References
local meditationStatusGui: ScreenGui?
local statusBannerFrame: Frame?
local statusTextLabel: TextLabel?
local statusStroke: UIStroke?
local zoneMonitorThread: thread? = nil

local function GetZoneColor(multiplier: number): Color3
	if multiplier <= 2 then
		return Color3.fromRGB(115, 235, 255) -- Celestial Cyan (Starter)
	elseif multiplier <= 5 then
		return Color3.fromRGB(120, 245, 175) -- Emerald Jade (Intermediate)
	elseif multiplier <= 9 then
		return Color3.fromRGB(255, 175, 50)  -- Amber Flame (Advanced)
	else
		return Color3.fromRGB(255, 220, 90)  -- Radiant Solar Gold (Master/Sovereign)
	end
end

-- Checks if player's character is inside any QiNode zone
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
				local name = tostring(nodePart:GetAttribute("NodeName") or "Qi Node")
				return mult, name
			end
		end
	end

	return 1.0, nil
end

-- =============================================================================
-- TOP-LEFT MEDITATION STATUS BANNER (Underneath Roblox Top-Bar)
-- =============================================================================
local function EnsureStatusBanner()
	if meditationStatusGui and meditationStatusGui.Parent then return end

	meditationStatusGui = Instance.new("ScreenGui")
	meditationStatusGui.Name = "MeditationStatusGui"
	meditationStatusGui.ResetOnSpawn = false
	meditationStatusGui.DisplayOrder = 15
	meditationStatusGui.IgnoreGuiInset = false
	meditationStatusGui.Parent = playerGui

	statusBannerFrame = Instance.new("Frame")
	statusBannerFrame.Name = "StatusBanner"
	statusBannerFrame.Size = UDim2.new(0, 230, 0, 30)
	statusBannerFrame.Position = UDim2.new(0, 16, 0, 52) -- Positioned directly below Roblox top-bar buttons
	statusBannerFrame.BackgroundColor3 = Color3.fromRGB(12, 16, 24)
	statusBannerFrame.BackgroundTransparency = 1
	statusBannerFrame.BorderSizePixel = 0
	statusBannerFrame.Visible = false
	statusBannerFrame.Parent = meditationStatusGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = statusBannerFrame

	statusStroke = Instance.new("UIStroke")
	statusStroke.Color = Color3.fromRGB(115, 235, 255)
	statusStroke.Thickness = 1.3
	statusStroke.Transparency = 1
	statusStroke.Parent = statusBannerFrame

	statusTextLabel = Instance.new("TextLabel")
	statusTextLabel.Name = "StatusText"
	statusTextLabel.Size = UDim2.new(1, -10, 1, 0)
	statusTextLabel.Position = UDim2.new(0, 5, 0, 0)
	statusTextLabel.BackgroundTransparency = 1
	statusTextLabel.Font = FONT_TITLE
	statusTextLabel.TextSize = 14
	statusTextLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusTextLabel.TextTransparency = 1
	statusTextLabel.Text = "🧘 MEDITATING · 1.0X SPEED"
	statusTextLabel.TextXAlignment = Enum.TextXAlignment.Center
	statusTextLabel.TextYAlignment = Enum.TextYAlignment.Center
	statusTextLabel.Parent = statusBannerFrame

	local textStroke = Instance.new("UIStroke")
	textStroke.Color = Color3.fromRGB(10, 10, 15)
	textStroke.Thickness = 1.2
	textStroke.Parent = statusTextLabel
end

local function UpdateMeditationBanner(character: Model)
	if not statusBannerFrame or not statusTextLabel or not statusStroke then return end

	local multiplier, nodeName = GetCurrentQiZoneMultiplier(character)
	if multiplier > 1.0 then
		local zoneColor = GetZoneColor(multiplier)
		local displayName = if nodeName and nodeName ~= "" then nodeName:upper() else "QI ZONE"
		statusTextLabel.Text = string.format("⚡ %s · %.1fX SPEED", displayName, multiplier)
		statusTextLabel.TextColor3 = zoneColor
		statusStroke.Color = zoneColor
	else
		statusTextLabel.Text = "🧘 MEDITATING · 1.0X SPEED"
		statusTextLabel.TextColor3 = Color3.fromRGB(220, 230, 240)
		statusStroke.Color = Color3.fromRGB(120, 140, 165)
	end
end

-- =============================================================================
-- QI NODE DOME & FLOATING BILLBOARD INITIALIZER
-- =============================================================================
local function SetupQiNodeVisual(nodePart: BasePart)
	if nodePart:FindFirstChild("QiZoneBillboard") then return end

	local nodeName = tostring(nodePart:GetAttribute("NodeName") or "Qi Condensation - 2x")
	local multiplier = tonumber(nodePart:GetAttribute("QiMultiplier")) or 2.0
	local zoneColor = GetZoneColor(multiplier)

	nodePart.Color = zoneColor
	local innerLight = nodePart:FindFirstChildOfClass("PointLight")
	if innerLight then
		innerLight.Color = zoneColor
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QiZoneBillboard"
	billboard.Size = UDim2.new(0, 280, 0, 56)
	billboard.StudsOffset = Vector3.new(0, (nodePart.Size.Y / 2) + 3.5, 0)
	billboard.MaxDistance = 150
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.Parent = nodePart

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = container

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 26)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = FONT_TITLE
	titleLabel.TextSize = 24
	titleLabel.TextColor3 = zoneColor
	titleLabel.Text = nodeName:upper()
	titleLabel.Parent = container

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(15, 15, 20)
	titleStroke.Thickness = 2
	titleStroke.Parent = titleLabel

	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubtitleLabel"
	subLabel.Size = UDim2.new(1, 0, 0, 18)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = FONT_TITLE
	subLabel.TextSize = 14
	subLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
	subLabel.Text = string.format("[ %.1fX QI CULTIVATION SPEED ]", multiplier)
	subLabel.Parent = container

	local subStroke = Instance.new("UIStroke")
	subStroke.Color = Color3.fromRGB(10, 10, 15)
	subStroke.Thickness = 1.3
	subStroke.Parent = subLabel

	nodePart:GetAttributeChangedSignal("QiMultiplier"):Connect(function()
		local newMult = tonumber(nodePart:GetAttribute("QiMultiplier")) or 2.0
		local newColor = GetZoneColor(newMult)
		nodePart.Color = newColor
		if innerLight then innerLight.Color = newColor end
		titleLabel.TextColor3 = newColor
		subLabel.Text = string.format("[ %.1fX QI CULTIVATION SPEED ]", newMult)
	end)

	nodePart:GetAttributeChangedSignal("NodeName"):Connect(function()
		local newName = tostring(nodePart:GetAttribute("NodeName") or "Qi Condensation - 2x")
		titleLabel.Text = newName:upper()
	end)
end

local function InitAllQiNodes()
	local qiNodesFolder = Workspace:WaitForChild("QiNodes", 8)
	if not qiNodesFolder then return end

	for _, child in ipairs(qiNodesFolder:GetChildren()) do
		if child:IsA("BasePart") then
			SetupQiNodeVisual(child)
		end
	end

	qiNodesFolder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			SetupQiNodeVisual(child)
		end
	end)
end

-- =============================================================================
-- MEDITATION CAMERA, AUDIO & HUD STATE
-- =============================================================================
function CultivationController.StartMeditation(character: Model)
	if isMeditating then return end
	isMeditating = true

	EnsureStatusBanner()

	-- Slide down & Fade in Status Banner
	if statusBannerFrame and statusTextLabel and statusStroke then
		UpdateMeditationBanner(character)
		statusBannerFrame.Visible = true
		statusBannerFrame.Position = UDim2.new(0, 16, 0, 44)

		TweenService:Create(statusBannerFrame, TWEEN_FAST, {
			BackgroundTransparency = 0.25,
			Position = UDim2.new(0, 16, 0, 52)
		}):Play()
		TweenService:Create(statusStroke, TWEEN_FAST, { Transparency = 0.2 }):Play()
		TweenService:Create(statusTextLabel, TWEEN_FAST, { TextTransparency = 0 }):Play()
	end

	-- Live zone monitoring while meditating
	if zoneMonitorThread then task.cancel(zoneMonitorThread) end
	zoneMonitorThread = task.spawn(function()
		while isMeditating and character.Parent do
			UpdateMeditationBanner(character)
			task.wait(0.3)
		end
	end)

	TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		FieldOfView = 65
	}):Play()

	if not meditationSound or meditationSound.Parent == nil then
		meditationSound = Instance.new("Sound")
		meditationSound.Name = "MeditationBGSound"
		meditationSound.SoundId = MEDITATION_SOUND_ID
		meditationSound.Looped = true
		meditationSound.Volume = 0.5
		meditationSound.Parent = SoundService
	end

	if meditationSound and not meditationSound.IsPlaying then
		meditationSound:Play()
	end
end

function CultivationController.StopMeditation(character: Model)
	if not isMeditating then return end
	isMeditating = false

	if zoneMonitorThread then
		task.cancel(zoneMonitorThread)
		zoneMonitorThread = nil
	end

	-- Fade out & Slide up Status Banner
	if statusBannerFrame and statusTextLabel and statusStroke then
		local fadeTween = TweenService:Create(statusBannerFrame, TWEEN_FAST, {
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 16, 0, 44)
		})
		TweenService:Create(statusStroke, TWEEN_FAST, { Transparency = 1 }):Play()
		TweenService:Create(statusTextLabel, TWEEN_FAST, { TextTransparency = 1 }):Play()
		fadeTween:Play()

		fadeTween.Completed:Connect(function()
			if not isMeditating and statusBannerFrame then
				statusBannerFrame.Visible = false
			end
		end)
	end

	if meditationSound and meditationSound.IsPlaying then
		meditationSound:Stop()
	end

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 70
	}):Play()
end

function CultivationController.Init()
	InitAllQiNodes()
	EnsureStatusBanner()

	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	cultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) ~= "table" then return end
		local character = player.Character
		if not character then return end

		local newMeditatingState = (data.IsMeditating == true)

		if newMeditatingState ~= isMeditating then
			if newMeditatingState then
				CultivationController.StartMeditation(character)
			else
				CultivationController.StopMeditation(character)
			end
		end
	end)

	print("[ASCEND] CultivationController Initialized (Dynamic QiNode Visuals & Top-Left Status Active).")
end

return CultivationController