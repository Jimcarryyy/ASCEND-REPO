--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Directly binds to MasterHUDGui.ToastContainer.ToastLabel with Generation-ID anti-race protection.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

local HUDController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local TWEEN_FADE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FADE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local masterGui: ScreenGui?
local toastContainer: Frame?
local toastLabel: TextLabel?

local currentToastId: number = 0
local currentTween: Tween? = nil

function HUDController.HookStudioUI()
	masterGui = (PlayerGui:FindFirstChild("MasterHUDGui") or PlayerGui:WaitForChild("MasterHUDGui", 8)) :: ScreenGui?
	if masterGui then
		toastContainer = masterGui:FindFirstChild("ToastContainer") :: Frame?
		if toastContainer then
			toastLabel = toastContainer:FindFirstChild("ToastLabel") :: TextLabel?
			toastContainer.Visible = false
			if toastLabel then
				toastLabel.TextTransparency = 1
			end
		end
	end
end

function HUDController.ShowToast(message: string, duration: number?)
	if not toastContainer or not toastLabel then return end

	currentToastId += 1
	local thisToastId = currentToastId
	local holdDuration = duration or 2.8

	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	toastLabel.Text = message
	toastLabel.TextTransparency = 0
	toastContainer.Visible = true

	currentTween = TweenService:Create(toastLabel, TWEEN_FADE_IN, { TextTransparency = 0 })
	currentTween:Play()

	task.spawn(function()
		task.wait(holdDuration)
		if currentToastId == thisToastId and toastLabel and toastContainer then
			currentTween = TweenService:Create(toastLabel, TWEEN_FADE_OUT, { TextTransparency = 1 })
			currentTween:Play()

			task.wait(0.36)
			if currentToastId == thisToastId and toastContainer and toastLabel then
				if toastLabel.TextTransparency >= 0.9 then
					toastContainer.Visible = false
				end
			end
		end
	end)
end

function HUDController.ShowItemToast(itemId: string, count: number?, qualityText: string?)
	local itemDef = nil
	pcall(function() itemDef = ItemConfig.GetItem(itemId) end)

	local itemName = if itemDef and itemDef.Name then itemDef.Name else tostring(itemId):gsub("_", " ")
	local qStr = if qualityText and qualityText ~= "" then string.format(" (%s)", qualityText) else ""
	local cStr = if count and count > 1 then string.format(" x%d", count) else ""

	HUDController.ShowToast(string.format("Obtained: %s%s%s", itemName, qStr, cStr), 2.8)
end

function HUDController.Init()
	HUDController.HookStudioUI()

	local gatherRemote = RemoteEvents.GetRemote("GatheringAction") :: RemoteEvent?
	if gatherRemote then
		gatherRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local targetItem = payload.ItemId or payload.HerbId or payload.HerbName
			if targetItem and (payload.Success == nil or payload.Success == true) then
				HUDController.ShowItemToast(tostring(targetItem), payload.Amount or 1, payload.Quality)
			end
		end)
	end

	local alchemyRemote = RemoteEvents.GetRemote("AlchemyAction") :: RemoteEvent?
	if alchemyRemote then
		alchemyRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			if payload.Action == "RefineResult" and payload.Success then
				HUDController.ShowToast(payload.Message or "Refined Spirit Dan Successfully!", 3.0)
			end
		end)
	end

	local sectRemote = RemoteEvents.GetRemote("SectAction") :: RemoteEvent?
	if sectRemote then
		sectRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) == "table" and payload.Action == "QuestCompleted" then
				HUDController.ShowToast("Sect Duty Completed! Rewards Claimed.", 3.0)
			end
		end)
	end

	print("[ASCEND] HUDController Initialized (MasterHUDGui ToastContainer Bound).")
end

return HUDController