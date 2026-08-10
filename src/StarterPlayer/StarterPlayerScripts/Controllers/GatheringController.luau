--!strict
--[[
    GatheringController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/GatheringController.luau
    Client UI and interaction controller for harvesting world resource nodes.
    Plays GatherHerbsSound from SoundService and triggers HUD Toast notifications on harvest completion.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local HUDController = require(script.Parent.HUDController)

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

	-- Listen for Harvest Signals from Server
	gatheringActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "HarvestSuccess" or payload.Action == "HarvestSuccessSound" then
			local sound = SoundService:FindFirstChild("GatherHerbsSound") :: Sound?
			if sound then
				sound:Play()
			else
				warn("[GatheringController] Could not find 'GatherHerbsSound' in SoundService!")
			end

			-- Trigger On-Screen Toast Notification
			if payload.ItemId then
				HUDController.ShowItemToast(payload.ItemId, payload.Count or 1)
			end
		end
	end)

	print("[ASCEND] GatheringController Initialized (Audio & Toast Notifications Connected).")
end

return GatheringController