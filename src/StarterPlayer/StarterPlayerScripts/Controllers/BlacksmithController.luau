--!strict
--[[
    BlacksmithController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/BlacksmithController.luau
    Client UI controller for StarterGui.BlacksmithGui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local BlacksmithController = {}
local blacksmithRemote: RemoteEvent

local gui: ScreenGui?
local backdrop: Frame?
local window: Frame?
local closeBtn: TextButton?
local refineBtn: TextButton?
local sharpenBtn: TextButton?

local costStonesLabel: TextLabel?
local costIngotsLabel: TextLabel?
local upgradeHeader: TextLabel?
local statPreviewLabel: TextLabel?
local rankBadge: TextLabel?

local isInitialized = false

local function EnsureUI(): boolean
	if isInitialized and gui and backdrop then return true end

	gui = (playerGui:FindFirstChild("BlacksmithGui") or playerGui:WaitForChild("BlacksmithGui", 8)) :: ScreenGui?
	if not gui then return false end
	gui.DisplayOrder = 50

	backdrop = (gui:FindFirstChild("ModalBackdrop") or gui:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not backdrop then return false end

	window = (backdrop:FindFirstChild("ForgeWindow") or backdrop:FindFirstChildWhichIsA("Frame")) :: Frame?
	if not window then return false end

	closeBtn = window:FindFirstChild("CloseButton") :: TextButton?
	refineBtn = window:FindFirstChild("RefineButton") :: TextButton?
	sharpenBtn = window:FindFirstChild("SharpenButton") :: TextButton?

	local rightPanel = window:FindFirstChild("RefinementStationPanel") :: Frame?
	if rightPanel then
		upgradeHeader = rightPanel:FindFirstChild("UpgradeHeader") :: TextLabel?
		statPreviewLabel = rightPanel:FindFirstChild("StatPreview") :: TextLabel?
		costStonesLabel = rightPanel:FindFirstChild("CostStones") :: TextLabel?
		costIngotsLabel = rightPanel:FindFirstChild("CostIngots") :: TextLabel?
	end

	local leftPanel = window:FindFirstChild("EquippedWeaponPanel") :: Frame?
	if leftPanel then
		rankBadge = leftPanel:FindFirstChild("RankBadge") :: TextLabel?
	end

	if closeBtn then
		closeBtn.Activated:Connect(function()
			if gui then gui.Enabled = false end
			if backdrop then backdrop.Visible = false end
		end)
	end

	if refineBtn then
		refineBtn.Activated:Connect(function()
			blacksmithRemote:FireServer({ Action = "RefineWeapon" })
		end)
	end

	if sharpenBtn then
		sharpenBtn.Activated:Connect(function()
			blacksmithRemote:FireServer({ Action = "SharpenBlade" })
		end)
	end

	isInitialized = true
	return true
end

function BlacksmithController.Init()
	blacksmithRemote = RemoteEvents.GetRemote("BlacksmithAction")
	EnsureUI()
	if gui then gui.Enabled = false end
	if backdrop then backdrop.Visible = false end

	-- Universal Prompt Trigger Listener
	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= localPlayer then return end
		local act = prompt.ActionText:lower()
		if act == "refine & sharpen weapons" or prompt.ObjectText == "Master Blacksmith Anvil" or (prompt.Parent and (prompt.Parent.Name == "Sect_NPC_MadameTie" or prompt.Parent.Name == "Anvil_Body")) then
			if EnsureUI() and backdrop and gui then
				gui.Enabled = true
				backdrop.Visible = true
				blacksmithRemote:FireServer({ Action = "RequestSync" })
			end
		end
	end)

	-- Server Events Listener
	blacksmithRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		if not EnsureUI() then return end

		if payload.Action == "OpenForge" or payload.Action == "SyncData" then
			if gui then gui.Enabled = true end
			if backdrop then backdrop.Visible = true end
			local stones = payload.SpiritStones or 0
			local refine = payload.RefinementLevel or 3
			local nextCost = 150 + (refine * 75)

			if upgradeHeader then upgradeHeader.Text = string.format("UPGRADE TO REFINEMENT +%d", refine + 1) end
			if rankBadge then rankBadge.Text = string.format("TIER 2 SPIRIT WEAPON  •  REFINEMENT +%d", refine) end
			if statPreviewLabel then statPreviewLabel.Text = string.format("Damage: %d ➔ %d (+%d DMG)", 30 + (refine * 5), 30 + ((refine + 1) * 5), 5) end
			if costStonesLabel then costStonesLabel.Text = string.format("• Spirit Stones: %d / %d Required", stones, nextCost) end
		elseif payload.Action == "Result" then
			blacksmithRemote:FireServer({ Action = "RequestSync" })
		end
	end)

	print("[ASCEND] BlacksmithController Initialized.")
end

return BlacksmithController