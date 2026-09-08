--!strict
--[[
    CultivationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
    Directly bound to MasterHUDGui.ZoneFrame.TextLabel.
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

local masterGui: ScreenGui?
local zoneFrame: Frame?
local zoneTextLabel: TextLabel?
local zoneMonitorThread: thread? = nil

local function GetZoneColor(multiplier: number): Color3
	if multiplier <= 2 then
		return Color3.fromRGB(115, 235, 255)
	elseif multiplier <= 5 then
		return Color3.fromRGB(120, 245, 175)
	elseif multiplier <= 9 then
		return Color3.fromRGB(255, 175, 50)
	else
		return Color3.fromRGB(255, 220, 90)
	end
end

local function HookStudioUI()
	masterGui = (playerGui:FindFirstChild("MasterHUDGui") or playerGui:WaitForChild("MasterHUDGui", 8)) :: ScreenGui?
	if masterGui then
		zoneFrame = masterGui:FindFirstChild("ZoneFrame") :: Frame?
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
	cultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })\
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

	print("[ASCEND] CultivationController Initialized (MasterHUDGui ZoneFrame Bound).")
end

return CultivationController