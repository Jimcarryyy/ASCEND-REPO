--!strict
--[[
    GatheringController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/GatheringController.luau
    Client UI and interaction controller for harvesting world resource nodes.
    Plays GatherHerbsSound from SoundService and triggers HUD Toast notifications on harvest completion.
    Harvest completion itself is server-authoritative (ProximityPrompt.Triggered handled
    server-side in GatheringManager) — this controller only reacts to server broadcasts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local HUDController = require(script.Parent.HUDController)

local GatheringController = {}
local player = Players.LocalPlayer

local gatheringActionRemote: RemoteEvent

function GatheringController.Init()
	gatheringActionRemote = RemoteEvents.GetRemote("GatheringAction")

	-- Listen for Harvest Signals from Server
	gatheringActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		-- Handle harvest events safely
		local isHarvestEvent = (payload.Action == "HarvestSuccess")
			or (payload.Action == "HarvestSuccessSound")
			or (payload.ItemId ~= nil)

		if isHarvestEvent then
			local sound = SoundService:FindFirstChild("GatherHerbsSound") :: Sound?
			if sound then
				sound:Play()
			end

			-- Trigger On-Screen Toast Notification Safely with Sanitized String Quality Metadata
			if payload.ItemId and HUDController and HUDController.ShowItemToast then
				local qualityStr = if payload.Quality ~= nil then tostring(payload.Quality) else nil
				HUDController.ShowItemToast(payload.ItemId, payload.Count or 1, qualityStr)
			end
		end
	end)

	print("[ASCEND] GatheringController Initialized (Audio & Toast Notifications Connected).")
end

return GatheringController