--!strict
-- CultivationController.luau
-- Client controller for grounded meditation camera adjustments and background audio.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CultivationController = {}
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isMeditating = false

-- Meditation Background Sound Asset ID
local MEDITATION_SOUND_ID = "rbxassetid://124551555247426"
local meditationSound: Sound? = nil

-- Starts meditation camera FOV shift and background audio
function CultivationController.StartMeditation(character: Model)
	if isMeditating then return end
	isMeditating = true

	TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		FieldOfView = 65 -- Calming, slightly wider field of view
	}):Play()

	-- Create & Play Meditation Sound
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

-- Stops meditation, restores FOV, and stops background audio
function CultivationController.StopMeditation(character: Model)
	if not isMeditating then return end
	isMeditating = false

	-- Stop Meditation Sound
	if meditationSound and meditationSound.IsPlaying then
		meditationSound:Stop()
	end

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 70 -- Return to default FOV
	}):Play()
end

function CultivationController.Init()
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
end

return CultivationController