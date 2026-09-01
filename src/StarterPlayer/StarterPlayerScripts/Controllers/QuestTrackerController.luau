--!strict
--[[
    QuestTrackerController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
    Directly binds to Studio SectMissionGui.MissionFrame (Frame1, Frame2, Frame3)
    Populates active Sect Missions into each frame cleanly.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local QuestTrackerController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local sectRemote: RemoteEvent

-- Studio UI Reference: SectMissionGui
local sectMissionGui: ScreenGui?
local missionFrame: Frame?
local missionFrames: { Frame } = {}

local activeQuests: { [string]: any } = {}

function QuestTrackerController.HookStudioUI()
	sectMissionGui = playerGui:WaitForChild("SectMissionGui", 10) :: ScreenGui?
	if sectMissionGui then
		missionFrame = sectMissionGui:WaitForChild("MissionFrame", 5) :: Frame?
		if missionFrame then
			missionFrames = {}
			for i = 1, 3 do
				local f = missionFrame:FindFirstChild("Frame" .. tostring(i)) :: Frame?
				if f then
					table.insert(missionFrames, f)
				end
			end
		end
	end
end

function QuestTrackerController.RenderQuests()
	if #missionFrames == 0 then return end

	local allQuests = if SectConfig and SectConfig.GetAllQuests then SectConfig.GetAllQuests() else {}
	local questList: { { Id: string, Title: string, Target: number } } = {}

	for qId, qDef in pairs(allQuests) do
		table.insert(questList, { Id = qId, Title = qDef.Title, Target = qDef.TargetAmount or 1 })
	end

	-- Fallback default quests if none registered in config
	if #questList == 0 then
		questList = {
			{ Id = "HerbalForaging", Title = "Herbal Foraging Duty", Target = 5 },
			{ Id = "AlchemyRefine",  Title = "Alchemy Cauldron Refinement", Target = 1 },
			{ Id = "SparringGround", Title = "Sparring Ground Discipline", Target = 3 },
		}
	end

	for idx, frame in ipairs(missionFrames) do
		local qData = questList[idx]
		local textLabel = frame:FindFirstChildOfClass("TextLabel")

		if qData and textLabel then
			frame.Visible = true
			local progress = activeQuests[qData.Id] or { CurrentAmount = 0, Completed = false }
			local current = progress.CurrentAmount or 0
			local target = qData.Target

			textLabel.Text = string.format("%s : %d/%d", qData.Title, current, target)
			if progress.Completed or current >= target then
				textLabel.TextColor3 = Color3.fromRGB(115, 235, 195)
			else
				textLabel.TextColor3 = Color3.fromRGB(240, 248, 252)
			end
		else
			frame.Visible = false
		end
	end
end

function QuestTrackerController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	QuestTrackerController.HookStudioUI()
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

	print("[ASCEND] QuestTrackerController Initialized (Studio SectMissionGui Bound).")
end

return QuestTrackerController