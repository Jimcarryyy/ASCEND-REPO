--!strict
--[[
    SparringGuidanceController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SparringGuidanceController.luau
    Client UI controller for StarterGui.SparringGuidanceGui.
]]

local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local SparringGuidanceController = {}
local sectRemote: RemoteEvent

local gui: ScreenGui?
local backdrop: Frame?
local window: Frame?
local closeBtn: TextButton?
local startTrialBtn: TextButton?
local resetDPSBtn: TextButton?
local isInitialized = false

local function EnsureUI(): boolean
	if isInitialized and gui and backdrop then return true end

	gui = (playerGui:FindFirstChild("SparringGuidanceGui") or playerGui:WaitForChild("SparringGuidanceGui", 8)) :: ScreenGui?
	if not gui then return false end
	gui.DisplayOrder = 50

	backdrop = (gui:FindFirstChild("ModalBackdrop") or gui:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not backdrop then return false end

	window = (backdrop:FindFirstChild("SparringWindow") or backdrop:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not window then return false end

	closeBtn = window:FindFirstChild("CloseButton") :: TextButton?
	startTrialBtn = window:FindFirstChild("StartTrialButton") :: TextButton?
	resetDPSBtn = window:FindFirstChild("ResetDPSButton") :: TextButton?

	if closeBtn then
		closeBtn.Activated:Connect(function()
			if backdrop then backdrop.Visible = false end
		end)
	end

	if startTrialBtn then
		startTrialBtn.Activated:Connect(function()
			if backdrop then backdrop.Visible = false end
			print("[Sparring] Sparring Trial Activated! Strike 3 Ironwood Dummies with full M1 combos.")
		end)
	end

	if resetDPSBtn then
		resetDPSBtn.Activated:Connect(function()
			print("[Sparring] Resetting Training Dummy DPS trackers.")
		end)
	end

	isInitialized = true
	return true
end

function SparringGuidanceController.Init()
	sectRemote = RemoteEvents.GetRemote("SectAction")

	EnsureUI()
	if backdrop then backdrop.Visible = false end

	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= localPlayer then return end
		local act = prompt.ActionText:lower()
		if act == "sparring guidance" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_InstructorWu") then
			if EnsureUI() and backdrop then
				backdrop.Visible = true
			end
		end
	end)

	print("[ASCEND] SparringGuidanceController Initialized.")
end

return SparringGuidanceController