--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Directly binds to Studio GlobalToastNotifGui.ToastFrame.TextLabel.
    Handles:
      - Multi-harvest consecutive toasts with Generation ID anti-race engine
      - Gathering item harvest alerts (ItemId, HerbId, HerbName)
      - Alchemy refinement & Sect mission completion toasts
      - Leaves Studio background colors, fonts, and sizes completely untouched
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

local toastGui: ScreenGui?
local toastFrame: Frame?
local toastTextLabel: TextLabel?

local currentToastId: number = 0
local currentTween: Tween? = nil

function HUDController.HookStudioUI()
	toastGui = PlayerGui:WaitForChild("GlobalToastNotifGui", 10) :: ScreenGui?
	if toastGui then
		toastFrame = toastGui:WaitForChild("ToastFrame", 5) :: Frame?
		if toastFrame then
			toastTextLabel = toastFrame:FindFirstChildOfClass("TextLabel")
			toastFrame.Visible = false
			if toastTextLabel then
				toastTextLabel.TextTransparency = 1
			end
		end
	end
end

-- =============================================================================
-- GENERATION-ID PROTECTED TOAST ENGINE (Solves Consecutive Harvest Glitch)
-- =============================================================================
function HUDController.ShowToast(message: string, duration: number?)
	if not toastFrame or not toastTextLabel then return end

	currentToastId += 1
	local thisToastId = currentToastId
	local holdDuration = duration or 2.8

	-- 1. Cancel any active fade-out tween
	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	-- 2. Set text & force visible synchronously
	toastTextLabel.Text = message
	toastTextLabel.TextTransparency = 0
	toastFrame.Visible = true

	currentTween = TweenService:Create(toastTextLabel, TWEEN_FADE_IN, { TextTransparency = 0 })
	currentTween:Play()

	-- 3. Hold timer with Generation ID validation
	task.spawn(function()
		task.wait(holdDuration)

		-- Only proceed if no newer toast was triggered in the meantime
		if currentToastId == thisToastId and toastTextLabel and toastFrame then
			currentTween = TweenService:Create(toastTextLabel, TWEEN_FADE_OUT, { TextTransparency = 1 })
			currentTween:Play()

			task.wait(0.36)

			-- Only hide frame if this remains the active generation
			if currentToastId == thisToastId and toastFrame and toastTextLabel then
				if toastTextLabel.TextTransparency >= 0.9 then
					toastFrame.Visible = false
				end
			end
		end
	end)
end

function HUDController.ShowItemToast(itemId: string, count: number?, qualityText: string?)
	local itemDef = nil
	pcall(function()
		itemDef = ItemConfig.GetItem(itemId)
	end)

	local itemName = if itemDef and itemDef.Name then itemDef.Name else tostring(itemId):gsub("_", " ")
	local qStr = if qualityText and qualityText ~= "" then string.format(" (%s)", qualityText) else ""
	local cStr = if count and count > 1 then string.format(" x%d", count) else ""

	HUDController.ShowToast(string.format("Obtained: %s%s%s", itemName, qStr, cStr), 2.8)
end

function HUDController.Init()
	HUDController.HookStudioUI()

	-- Gathering Notifications
	local gatherRemote = RemoteEvents.GetRemote("GatheringAction") :: RemoteEvent?
	if gatherRemote then
		gatherRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end

			local targetItem = payload.ItemId or payload.HerbId or payload.HerbName or payload.HarvestedItem or payload.Item
			if targetItem and (payload.Success == nil or payload.Success == true) then
				HUDController.ShowItemToast(tostring(targetItem), payload.Amount or 1, payload.Quality)
			end
		end)
	end

	-- Alchemy Notifications
	local alchemyRemote = RemoteEvents.GetRemote("AlchemyAction") :: RemoteEvent?
	if alchemyRemote then
		alchemyRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end

			if payload.Action == "RefineResult" and payload.Success then
				local potionItem = payload.ResultItemId or payload.Potion or payload.Item or payload.Dan
				if potionItem then
					HUDController.ShowItemToast(tostring(potionItem), payload.Amount or 1, payload.QualityText or payload.Quality)
				else
					HUDController.ShowToast("Refined Spirit Dan Successfully!", 2.8)
				end
			end
		end)
	end

	-- Sect Duty Notifications
	local sectRemote = RemoteEvents.GetRemote("SectAction") :: RemoteEvent?
	if sectRemote then
		sectRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) == "table" and payload.Action == "QuestCompleted" then
				HUDController.ShowToast("Sect Duty Completed! Rewards Claimed.", 3.0)
			end
		end)
	end

	print("[ASCEND] HUDController Initialized (Consecutive Generation-Protected Toast Active).")
end

return HUDController