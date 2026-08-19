--!strict
--[[
    QuestTrackerController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
    Client controller for the Quest Tracker HUD.
    Hooks directly into StarterGui.QuestTrackerGUI with automatic UIListLayout spacing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local QuestTrackerController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local CLICK_SOUND_ID = "rbxassetid://6895079853"
local sectRemote: RemoteEvent

-- Studio GUI References
local questTrackerGui: ScreenGui?
local questFrame: Frame?
local titleFrame: Frame?
local dropDownBtn: Instance?
local questScrollingFrame: ScrollingFrame?
local dutyCardTemplate: Frame?

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

function QuestTrackerController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	QuestTrackerController.HookStudioUI()

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

	print("[ASCEND] QuestTrackerController Initialized (With Vertical Spacing Enforcement).")
end

function QuestTrackerController.HookStudioUI()
	questTrackerGui = playerGui:WaitForChild("QuestTrackerGUI", 10) :: ScreenGui?
	if not questTrackerGui then return end

	questFrame = questTrackerGui:WaitForChild("QuestFrame", 5) :: Frame?
	if not questFrame then return end

	titleFrame = questFrame:WaitForChild("TitleFrame", 5) :: Frame?
	questScrollingFrame = questFrame:WaitForChild("QuestScrollingFrame", 5) :: ScrollingFrame?

	if questScrollingFrame then
		-- Ensure UIListLayout exists so cards never stack
		local listLayout = questScrollingFrame:FindFirstChildOfClass("UIListLayout")
		if not listLayout then
			listLayout = Instance.new("UIListLayout")
			listLayout.FillDirection = Enum.FillDirection.Vertical
			listLayout.SortOrder = Enum.SortOrder.LayoutOrder
			listLayout.Padding = UDim.new(0, 6)
			listLayout.Parent = questScrollingFrame
		end

		questScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

		dutyCardTemplate = questScrollingFrame:WaitForChild("DutyCard", 5) :: Frame?
		if dutyCardTemplate then
			dutyCardTemplate.Visible = false
		end
	end

	-- Bind DropDown / Collapse Button
	if titleFrame then
		dropDownBtn = titleFrame:FindFirstChild("DropDownIcon")
		if dropDownBtn then
			local function toggleCollapse()
				PlayClickAudio()
				isCollapsed = not isCollapsed
				if questScrollingFrame then
					questScrollingFrame.Visible = not isCollapsed
				end
			end

			if dropDownBtn:IsA("GuiButton") then
				dropDownBtn.MouseButton1Click:Connect(toggleCollapse)
			elseif dropDownBtn:IsA("GuiObject") then
				dropDownBtn.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						toggleCollapse()
					end
				end)
			end
		end
	end
end

function QuestTrackerController.RenderQuests()
	if not questScrollingFrame or not dutyCardTemplate then return end

	-- Clean up previous clones
	for _, child in ipairs(questScrollingFrame:GetChildren()) do
		if child ~= dutyCardTemplate and child:IsA("GuiObject") and child.Name == "ClonedDutyCard" then
			child:Destroy()
		end
	end

	local order = 1
	for questId, questDef in pairs(SectConfig.GetAllQuests()) do
		local progress = activeQuests[questId] or { CurrentAmount = 0, TargetAmount = questDef.TargetAmount, Completed = false }

		local cardClone = dutyCardTemplate:Clone()
		cardClone.Name = "ClonedDutyCard"
		cardClone.LayoutOrder = order
		cardClone.Size = UDim2.new(1, -8, 0, 42) -- Explicit height per card
		cardClone.Visible = true
		cardClone.Parent = questScrollingFrame
		order += 1

		local textFrame = cardClone:FindFirstChild("QuestTextFrame") :: Frame?
		local checkPending = cardClone:FindFirstChild("CheckIconPending") :: ImageLabel?
		local checkDone = cardClone:FindFirstChild("CheckIconDone") :: ImageLabel?

		if textFrame then
			local qTitle = textFrame:FindFirstChild("QuestTitle") :: TextLabel?
			local qDisc = textFrame:FindFirstChild("QuestDisc") :: TextLabel?

			if qTitle then
				qTitle.Text = questDef.Title
			end
			if qDisc then
				if progress.Completed then
					qDisc.Text = string.format("Completed (%d/%d) - Ready to Submit", progress.CurrentAmount, questDef.TargetAmount)
					qDisc.TextColor3 = Color3.fromRGB(16, 185, 129)
				else
					qDisc.Text = string.format("%s (%d/%d)", questDef.Description, progress.CurrentAmount, questDef.TargetAmount)
					qDisc.TextColor3 = Color3.fromRGB(169, 169, 159)
				end
			end
		end

		if checkPending then
			checkPending.Visible = not progress.Completed
		end
		if checkDone then
			checkDone.Visible = progress.Completed
		end
	end
end

return QuestTrackerController