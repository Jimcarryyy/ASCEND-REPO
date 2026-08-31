--!strict
--[[
    QuestTrackerController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
    Client controller for the Quest Tracker HUD.
    Self-contained: Constructs UI at Top-Left (UDim2.new(0, 16, 0, 52)) and hooks SectAction remotes.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local QuestTrackerController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local UI_FONT = Enum.Font.Bangers
local CLICK_SOUND_ID = "rbxassetid://6895079853"
local sectRemote: RemoteEvent

local questTrackerGui: ScreenGui?
local questFrame: Frame?
local questScrollingFrame: ScrollingFrame?

local isCollapsed = false
local activeQuests: { [string]: any } = {}

local function PlayClickAudio()
	local sound = Instance.new("Sound")
	sound.SoundId = CLICK_SOUND_ID
	sound.Volume = 0.5
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1)
end

function QuestTrackerController.BuildUI()
	local existing = playerGui:FindFirstChild("QuestTrackerGUI")
	if existing then existing:Destroy() end

	questTrackerGui = Instance.new("ScreenGui")
	questTrackerGui.Name = "QuestTrackerGUI"
	questTrackerGui.ResetOnSpawn = false
	questTrackerGui.DisplayOrder = 8
	questTrackerGui.IgnoreGuiInset = false
	questTrackerGui.Parent = playerGui

	-- Upper-left position directly below Roblox settings
	questFrame = Instance.new("Frame")
	questFrame.Name = "QuestFrame"
	questFrame.Size = UDim2.new(0, 230, 0, 150)
	questFrame.Position = UDim2.new(0, 16, 0, 52)
	questFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	questFrame.BackgroundTransparency = 0.25
	questFrame.BorderSizePixel = 0
	questFrame.Parent = questTrackerGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = questFrame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(212, 175, 55)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.4
	stroke.Parent = questFrame

	-- Title Bar
	local titleFrame = Instance.new("Frame")
	titleFrame.Name = "TitleFrame"
	titleFrame.Size = UDim2.new(1, 0, 0, 28)
	titleFrame.BackgroundTransparency = 1
	titleFrame.Parent = questFrame

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, -36, 1, 0)
	titleLabel.Position = UDim2.new(0, 10, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Font = UI_FONT
	titleLabel.TextSize = 14
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.Text = "◈ SECT ASSIGNMENTS"
	titleLabel.Parent = titleFrame

	local titleStroke = Instance.new("UIStroke", titleLabel)
	titleStroke.Color = Color3.fromRGB(10, 10, 15)
	titleStroke.Thickness = 1

	local dropDownBtn = Instance.new("TextButton")
	dropDownBtn.Name = "DropDownIcon"
	dropDownBtn.Size = UDim2.new(0, 24, 0, 24)
	dropDownBtn.Position = UDim2.new(1, -26, 0, 2)
	dropDownBtn.BackgroundTransparency = 1
	dropDownBtn.Font = UI_FONT
	dropDownBtn.TextSize = 13
	dropDownBtn.TextColor3 = Color3.fromRGB(215, 185, 90)
	dropDownBtn.Text = "▼"
	dropDownBtn.Parent = titleFrame

	dropDownBtn.MouseButton1Click:Connect(function()
		PlayClickAudio()
		isCollapsed = not isCollapsed
		dropDownBtn.Text = if isCollapsed then "▲" else "▼"
		if questScrollingFrame then
			questScrollingFrame.Visible = not isCollapsed
		end
		if questFrame then
			questFrame.Size = if isCollapsed then UDim2.new(0, 230, 0, 30) else UDim2.new(0, 230, 0, 150)
		end
	end)

	-- Scrolling Frame for Quests
	questScrollingFrame = Instance.new("ScrollingFrame")
	questScrollingFrame.Name = "QuestScrollingFrame"
	questScrollingFrame.Size = UDim2.new(1, -12, 1, -34)
	questScrollingFrame.Position = UDim2.new(0, 6, 0, 30)
	questScrollingFrame.BackgroundTransparency = 1
	questScrollingFrame.BorderSizePixel = 0
	questScrollingFrame.ScrollBarThickness = 3
	questScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(212, 175, 55)
	questScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	questScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	questScrollingFrame.Parent = questFrame

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 6)
	listLayout.Parent = questScrollingFrame
end

function QuestTrackerController.RenderQuests()
	if not questScrollingFrame then return end

	for _, child in ipairs(questScrollingFrame:GetChildren()) do
		if child:IsA("GuiObject") and child.Name:find("DutyCard") then
			child:Destroy()
		end
	end

	local allQuests = if SectConfig and SectConfig.GetAllQuests then SectConfig.GetAllQuests() else {}
	local order = 1

	-- If no quests exist in config yet, supply default assignment
	local questList = allQuests
	if next(questList) == nil then
		questList = {
			["DailyWolfHunt"] = {
				Title = "Corrupted Wolf Hunt",
				Description = "Purge 5 Corrupted Wolves in Sector 1",
				TargetAmount = 5,
			},
			["DailyMeditation"] = {
				Title = "Qi Condensation Duty",
				Description = "Absorb Qi in any 2x Qi Node",
				TargetAmount = 1,
			}
		}
	end

	for questId, questDef in pairs(questList) do
		local progress = activeQuests[questId] or { CurrentAmount = 0, TargetAmount = questDef.TargetAmount or 1, Completed = false }

		local card = Instance.new("Frame")
		card.Name = "DutyCard_" .. questId
		card.LayoutOrder = order
		card.Size = UDim2.new(1, -6, 0, 52)
		card.BackgroundColor3 = Color3.fromRGB(22, 28, 38)
		card.BackgroundTransparency = 0.3
		card.BorderSizePixel = 0
		card.Parent = questScrollingFrame

		local cCorner = Instance.new("UICorner", card)
		cCorner.CornerRadius = UDim.new(0, 4)

		local cStroke = Instance.new("UIStroke", card)
		cStroke.Color = if progress.Completed then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(160, 180, 205)
		cStroke.Thickness = 1
		cStroke.Transparency = 0.6

		local qTitle = Instance.new("TextLabel")
		qTitle.Name = "QuestTitle"
		qTitle.Size = UDim2.new(1, -12, 0, 16)
		qTitle.Position = UDim2.new(0, 6, 0, 4)
		qTitle.BackgroundTransparency = 1
		qTitle.Font = UI_FONT
		qTitle.TextSize = 12
		qTitle.TextColor3 = if progress.Completed then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(240, 245, 255)
		qTitle.TextXAlignment = Enum.TextXAlignment.Left
		qTitle.Text = (if progress.Completed then "✓ " else "◈ ") .. questDef.Title
		qTitle.Parent = card

		local qDisc = Instance.new("TextLabel")
		qDisc.Name = "QuestDisc"
		qDisc.Size = UDim2.new(1, -12, 0, 14)
		qDisc.Position = UDim2.new(0, 6, 0, 20)
		qDisc.BackgroundTransparency = 1
		qDisc.Font = Enum.Font.Gotham
		qDisc.TextSize = 10
		qDisc.TextColor3 = Color3.fromRGB(170, 180, 195)
		qDisc.TextXAlignment = Enum.TextXAlignment.Left
		qDisc.Text = questDef.Description
		qDisc.Parent = card

		local progressLbl = Instance.new("TextLabel")
		progressLbl.Name = "ProgressLabel"
		progressLbl.Size = UDim2.new(1, -12, 0, 14)
		progressLbl.Position = UDim2.new(0, 6, 0, 34)
		progressLbl.BackgroundTransparency = 1
		progressLbl.Font = UI_FONT
		progressLbl.TextSize = 10
		progressLbl.TextColor3 = if progress.Completed then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(0, 200, 255)
		progressLbl.TextXAlignment = Enum.TextXAlignment.Left
		progressLbl.Text = string.format("Progress: %d / %d", progress.CurrentAmount or 0, questDef.TargetAmount or 1)
		progressLbl.Parent = card

		order += 1
	end
end

function QuestTrackerController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	QuestTrackerController.BuildUI()
	QuestTrackerController.RenderQuests()

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

	task.defer(function()
		task.wait(1)
		sectRemote:FireServer({ Action = "RequestSectData" })
	end)

	print("[ASCEND] QuestTrackerController Initialized (Top-Left Self-Contained UI Active).")
end

return QuestTrackerController