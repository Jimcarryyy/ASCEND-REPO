--!strict
--[[
    FocusTargetController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau
    Azure Center Reticle and Upper-Body Focus Targeting Controller.
    Bound to MouseButton3 (Middle Click) and Z key.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local FocusTargetController = {}
FocusTargetController.__index = FocusTargetController

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isFocusActive = false
local focusReticleGui: ScreenGui? = nil
local reticleImage: ImageLabel? = nil

local function CreateReticleGui()
	if focusReticleGui then return end

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
	focusReticleGui = Instance.new("ScreenGui")
	focusReticleGui.Name = "FocusTargetReticleGui"
	focusReticleGui.ResetOnSpawn = false
	focusReticleGui.Enabled = false
	focusReticleGui.Parent = playerGui

	reticleImage = Instance.new("ImageLabel")
	reticleImage.Name = "AzureReticle"
	reticleImage.Size = UDim2.new(0, 36, 0, 36)
	reticleImage.Position = UDim2.new(0.5, 0, 0.5, 0)
	reticleImage.AnchorPoint = Vector2.new(0.5, 0.5)
	reticleImage.BackgroundTransparency = 1
	reticleImage.Image = "rbxassetid://13165215707"
	reticleImage.ImageColor3 = Color3.fromRGB(100, 220, 255)
	reticleImage.Parent = focusReticleGui
end

function FocusTargetController.Init()
	CreateReticleGui()

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		-- Bound to Middle Click (MouseButton3) and Z key
		if input.UserInputType == Enum.UserInputType.MouseButton3 or input.KeyCode == Enum.KeyCode.Z then
			FocusTargetController.ToggleFocus()
		end
	end)

	RunService.RenderStepped:Connect(function()
		if not isFocusActive then return end

		local character = player.Character
		if not character or character:GetAttribute("IsMeditating") == true then
			if isFocusActive then FocusTargetController.SetFocus(false) end
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		if camera then
			local lookVec = camera.CFrame.LookVector
			local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z).Unit
			if flatLook.Magnitude > 0.1 then
				hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
			end
		end
	end)

	print("[ASCEND] FocusTargetController Initialized (MMB / Z Focus Aiming).")
end

function FocusTargetController.ToggleFocus()
	FocusTargetController.SetFocus(not isFocusActive)
end

function FocusTargetController.SetFocus(active: boolean)
	isFocusActive = active
	if focusReticleGui then
		focusReticleGui.Enabled = isFocusActive
	end
	UserInputService.MouseBehavior = if isFocusActive then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
end

return FocusTargetController