--!strict
--[[
    QuestTrackerController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
    Directly bound to MasterHUDGui.TopLeftDutyTracker.MissionFrame (Frame1, Frame2, Frame3).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local QuestTrackerController = {}
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local sectRemote: RemoteEvent
local masterGui: ScreenGui?
local dutyTracker: Frame?
local missionFrame: Frame?
local frames: { Frame } = {}

local activeQuests: { [string]: any } = {}

function QuestTrackerController.HookStudioUI()
	masterGui = (playerGui:FindFirstChild("MasterHUDGui") or playerGui:WaitForChild("MasterHUDGui", 8)) :: ScreenGui?
	if masterGui then
		dutyTracker = masterGui:FindFirstChild("TopLeftDutyTracker") :: Frame?
		if dutyTracker then
			missionFrame = dutyTracker:FindFirstChild("MissionFrame") :: Frame?
			if missionFrame then
				frames = {}
				for i = 1, 3 do
					local f = missionFrame:FindFirstChild("Frame" .. tostring(i)) :: Frame?
					if f then table.insert(frames, f) end
				end
			end
		end
	end
end

function QuestTrackerController.RenderQuests()
	if #frames == 0 then return end

	local questList = {
		{ Id = "Quest_GatherSpiritGrass", Title = "Herbal Foraging Duty", Target = 5 },
		{ Id = "Quest_RefineDan",          Title = "Alchemy Cauldron Refine", Target = 1 },
		{ Id = "Quest_SparringTrial",       Title = "Sparring Discipline", Target = 3 },
	}

	for idx, frame in ipairs(frames) do
		local qData = questList[idx]
		local textLabel = frame:FindFirstChildOfClass("TextLabel")
		local progLabel = frame:FindFirstChild("ProgressLabel") :: TextLabel?

		if qData then
			frame.Visible = true
			local progress = activeQuests[qData.Id] or { CurrentAmount = 0, Completed = false }
			local current = progress.CurrentAmount or 0
			local target = qData.Target

			if textLabel then textLabel.Text = qData.Title end
			if progLabel then
				progLabel.Text = string.format("%d / %d", current, target)
				progLabel.TextColor3 = (current >= target) and Color3.fromRGB(115, 235, 195) or Color3.fromRGB(240, 248, 252)
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
		if payload.Action == "SyncSectData" or payload.Action == "QuestCompleted" then
			activeQuests = payload.Quests or activeQuests
			QuestTrackerController.RenderQuests()
		end
	end)

	task.defer(function()
		task.wait(1)
		sectRemote:FireServer({ Action = "RequestSectData" })
	end)

	print("[ASCEND] QuestTrackerController Initialized (MasterHUDGui TopLeftDutyTracker Bound).")
end

return QuestTrackerController