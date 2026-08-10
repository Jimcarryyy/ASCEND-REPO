--!strict
--[[
    GatheringController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/GatheringController.luau
    Client UI and interaction controller for harvesting world resource nodes.
    Plays GatherHerbsSound from SoundService on harvest completion.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local GatheringController = {}
local player = Players.LocalPlayer

local gatheringActionRemote: RemoteEvent

function GatheringController.Init()
	gatheringActionRemote = RemoteEvents.GetRemote("GatheringAction")

	ProximityPromptService.PromptTriggered:Connect(function(prompt, playerWhoTriggered)
		if playerWhoTriggered ~= player then return end

		local nodeInstance = prompt.Parent
		if not nodeInstance then return end

		gatheringActionRemote:FireServer({
			Action = "CompleteHarvest",
			NodeInstance = nodeInstance,
		})
	end)

	-- Listen for Sound Play Signal from Server
	gatheringActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "HarvestSuccessSound" then
			local sound = SoundService:FindFirstChild("GatherHerbsSound") :: Sound?
			if sound then
				sound:Play()
			else
				warn("[GatheringController] Could not find 'GatherHerbsSound' in SoundService!")
			end
		end
	end)

	print("[ASCEND] GatheringController Initialized (Audio Playback Connected).")
end

return GatheringController