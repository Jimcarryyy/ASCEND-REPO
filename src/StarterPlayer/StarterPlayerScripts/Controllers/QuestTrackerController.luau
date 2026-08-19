--!strict
--[[
    QuestTrackerController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
    Client UI controller for the Persistent On-Screen Sect Quest & Duties Tracker.
    Theme: Dark Obsidian (#111827), Antique Gold (#8B6B32), Ivory Text (#F1E8D2), and Jade Highlights.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local QuestTrackerController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UI_FONT = Enum.Font.FredokaOne
local T = UIAssets.Theme

local sectRemote: RemoteEvent

local screenGui: ScreenGui
local trackerFrame: Frame
local questListContainer: Frame
local toggleBtn: TextButton

local isCollapsed = false
local activeQuests: { [string]: any } = {}

function QuestTrackerController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	QuestTrackerController.BuildUI()

	-- Network Listeners
	sectRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "SyncSectData" then
			activeQuests = payload.Quests or activeQuests
			QuestTrackerController.RenderQuests()
		elseif action == "QuestCompleted" then
			QuestTrackerController.RenderQuests()
		end
	end)

	-- Request initial quest data
	task.defer(function()
		task.wait(1)
		sectRemote:FireServer({ Action = "RequestSectData" })
	end)

	print("[ASCEND] QuestTrackerController Initialized (Persistent On-Screen Tracker Active).")
end

function QuestTrackerController.BuildUI()
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "QuestTrackerGui"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 10
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	trackerFrame = Instance.new("Frame")
	trackerFrame.Name = "TrackerWidget"
	trackerFrame.Size = UDim2.new(0, 220, 0, 190)
	trackerFrame.Position = UDim2.new(1, -230, 0.32, 0) -- Mid-Right Screen
	trackerFrame.BackgroundColor3 = T.DeepBackground
	trackerFrame.BackgroundTransparency = 0.15
	trackerFrame.BorderSizePixel = 0
	trackerFrame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = trackerFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = T.MainBorder
	stroke.Thickness = 1.5
	stroke.Parent = trackerFrame

	-- Header Bar
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundColor3 = T.SecondarySurface
	header.BorderSizePixel = 0
	header.Parent = trackerFrame

	local hCorner = Instance.new("UICorner")
	hCorner.CornerRadius = UDim.new(0, 8)
	hCorner.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -40, 1, 0)
	title.Position = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Text = "📜 SECT DUTIES"
	title.TextColor3 = T.HighlightBorder
	title.Font = UI_FONT
	title.TextSize = 13
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = header

	toggleBtn = Instance.new("TextButton")
	toggleBtn.Size = UDim2.new(0, 24, 0, 24)
	toggleBtn.Position = UDim2.new(1, -28, 0.5, -12)
	toggleBtn.BackgroundColor3 = T.RaisedSurface
	toggleBtn.Text = "−"
	toggleBtn.TextColor3 = T.PrimaryText
	toggleBtn.Font = UI_FONT
	toggleBtn.TextSize = 14
	toggleBtn.Parent = header

	local tbCorner = Instance.new("UICorner")
	tbCorner.CornerRadius = UDim.new(0, 4)
	tbCorner.Parent = toggleBtn

	toggleBtn.MouseButton1Click:Connect(function()
		isCollapsed = not isCollapsed
		toggleBtn.Text = if isCollapsed then "+" else "−"
		local targetSize = if isCollapsed then UDim2.new(0, 220, 0, 32) else UDim2.new(0, 220, 0, 190)
		TweenService:Create(trackerFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = targetSize }):Play()
		questListContainer.Visible = not isCollapsed
	end)

	-- Quests List Container
	questListContainer = Instance.new("Frame")
	questListContainer.Name = "QuestList"
	questListContainer.Size = UDim2.new(1, -16, 1, -40)
	questListContainer.Position = UDim2.new(0, 8, 0, 36)
	questListContainer.BackgroundTransparency = 1
	questListContainer.Parent = trackerFrame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = questListContainer
end

function QuestTrackerController.RenderQuests()
	questListContainer:ClearAllChildren()

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = questListContainer

	for questId, questDef in pairs(SectConfig.GetAllQuests()) do
		local progress = activeQuests[questId] or { CurrentAmount = 0, TargetAmount = questDef.TargetAmount, Completed = false }

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 42)
		row.BackgroundColor3 = T.SecondarySurface
		row.BorderSizePixel = 0
		row.Parent = questListContainer

		local rCorner = Instance.new("UICorner")
		rCorner.CornerRadius = UDim.new(0, 4)
		rCorner.Parent = row

		local rStroke = Instance.new("UIStroke")
		rStroke.Color = if progress.Completed then T.JadeAccent else T.RaisedSurface
		rStroke.Thickness = 1
		rStroke.Parent = row

		local qTitle = Instance.new("TextLabel")
		qTitle.Size = UDim2.new(1, -8, 0, 18)
		qTitle.Position = UDim2.new(0, 6, 0, 3)
		qTitle.BackgroundTransparency = 1
		qTitle.Text = questDef.Title
		qTitle.TextColor3 = if progress.Completed then T.JadeAccent else T.PrimaryText
		qTitle.Font = UI_FONT
		qTitle.TextSize = 11
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Parent = row

		local qStatus = Instance.new("TextLabel")
		qStatus.Size = UDim2.new(1, -8, 0, 16)
		qStatus.Position = UDim2.new(0, 6, 0, 22)
		qStatus.BackgroundTransparency = 1
		qStatus.Text = if progress.Completed then "✓ Ready to submit at Elder" else string.format("Progress: %d / %d", progress.CurrentAmount, questDef.TargetAmount)
		qStatus.TextColor3 = if progress.Completed then T.JadeAccent else T.SpiritBlue
		qStatus.Font = UI_FONT
		qStatus.TextSize = 10
		qStatus.TextXAlignment = Enum.TextXAlignment.Left
		qStatus.Parent = row
	end
end

return QuestTrackerController