--!strict
--[[
    CultivationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
    Handles:
      1. 3D Floating Qi Node Billboards (Bangers Font + UIStroke)
      2. 2D Screen QIZoneNotifGui Binding (Accurate, non-doubled zone rates)
      3. Meditation FOV adjustments, sound loop, and real-time multiplier detection
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

local FONT_QI_NODE = Enum.Font.Bangers
local MEDITATION_SOUND_ID = "rbxassetid://124551555247426"
local meditationSound: Sound? = nil

local isMeditating = false

-- Studio UI Reference: QIZoneNotifGui (2D Screen Banner)
local qiZoneGui: ScreenGui?
local zoneFrame: Frame?
local zoneTextLabel: TextLabel?
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

-- =============================================================================
-- 3D FLOATING QI NODE BILLBOARD SETUP (Bangers + Bold UIStroke)
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
	billboard.Size = UDim2.new(0, 320, 0, 65)
	billboard.StudsOffset = Vector3.new(0, (nodePart.Size.Y / 2) + 3.5, 0)
	billboard.MaxDistance = 160
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

	-- Node Title (Bangers Font)
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 32)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = FONT_QI_NODE
	titleLabel.TextSize = 28
	titleLabel.TextColor3 = zoneColor
	titleLabel.Text = nodeName:upper()
	titleLabel.Parent = container

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(10, 10, 15)
	titleStroke.Thickness = 2.0
	titleStroke.Parent = titleLabel

	-- Node Subtitle / Multiplier (Bangers Font)
	local subLabel = Instance.new("TextLabel")
	subLabel.Name = "SubtitleLabel"
	subLabel.Size = UDim2.new(1, 0, 0, 22)
	subLabel.BackgroundTransparency = 1
	subLabel.Font = FONT_QI_NODE
	subLabel.TextSize = 18
	subLabel.TextColor3 = Color3.fromRGB(245, 245, 255)
	subLabel.Text = string.format("[ %.1fX QI CULTIVATION SPEED ]", multiplier)
	subLabel.Parent = container

	local subStroke = Instance.new("UIStroke")
	subStroke.Color = Color3.fromRGB(10, 10, 15)
	subStroke.Thickness = 1.6
	subStroke.Parent = subLabel

	-- Live attribute update listeners
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
-- 2D SCREEN QIZONENOTIFGUI BINDING
-- =============================================================================
local function HookStudioUI()
	qiZoneGui = playerGui:WaitForChild("QIZoneNotifGui", 10) :: ScreenGui?
	if qiZoneGui then
		zoneFrame = qiZoneGui:WaitForChild("ZoneFrame", 5) :: Frame?
		if zoneFrame then
			zoneTextLabel = zoneFrame:FindFirstChildOfClass("TextLabel")
			zoneFrame.Visible = false
		end
	end
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
				local name = tostring(nodePart:GetAttribute("NodeName") or "Qi Condensation")
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

-- =============================================================================
-- MEDITATION STATE HANDLERS
-- =============================================================================
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

	UpdateZoneBanner(character)

	if meditationSound and meditationSound.IsPlaying then
		meditationSound:Stop()
	end

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 70
	}):Play()
end

function CultivationController.Init()
	InitAllQiNodes()
	HookStudioUI()

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

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if char and not isMeditating then
			UpdateZoneBanner(char)
		end
	end)

	print("[ASCEND] CultivationController Initialized (Bangers QiNode Billboards Active).")
end

return CultivationController