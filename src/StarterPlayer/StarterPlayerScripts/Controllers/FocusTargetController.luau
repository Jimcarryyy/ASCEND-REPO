--!strict
--[[
    FocusTargetController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau
    Handles Focus Target Combat Mode: Center crosshair UI, Humanoid strafe locking,
    and Upper Body / RootJoint orientation tracking towards mouse/aim point.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local FocusTargetController = {}

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local isFocusMode = false
local reticleGui: ScreenGui?
local reticleFrame: Frame?

function FocusTargetController.Init()
	FocusTargetController.CreateReticleUI()

	-- Toggle Focus Mode with LeftControl or Middle Click
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.LeftControl or input.UserInputType == Enum.UserInputType.MouseButton3 then
			FocusTargetController.ToggleFocusMode()
		end
	end)

	-- Upper body & RootPart tracking loop
	RunService.RenderStepped:Connect(function(dt)
		if not isFocusMode then return end

		local character = player.Character
		if not character then return end

		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not hrp or not humanoid or humanoid.Health <= 0 then return end

		-- Check if player is meditating
		if character:GetAttribute("IsMeditating") == true then return end

		humanoid.AutoRotate = false

		-- Calculate mouse aim direction in 3D world space
		local mousePos = mouse.Hit.Position
		local lookVector = (mousePos - hrp.Position)
		local horizontalDir = Vector3.new(lookVector.X, 0, lookVector.Z).Unit

		if horizontalDir.Magnitude > 0.1 then
			-- Smoothly twist RootPart to match horizontal mouse aim
			local targetCFrame = CFrame.lookAt(hrp.Position, hrp.Position + horizontalDir)
			hrp.CFrame = hrp.CFrame:Lerp(targetCFrame, math.clamp(dt * 20, 0, 1))
		end

		-- Upper body / RootJoint Pitch adjustment
		local rootJoint = hrp:FindFirstChild("RootJoint") :: Motor6D?
		if rootJoint then
			local pitchAngle = math.clamp(math.asin(lookVector.Unit.Y), math.rad(-35), math.rad(35))
			local targetC0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90) + pitchAngle * 0.4, 0, math.rad(180))
			rootJoint.C0 = rootJoint.C0:Lerp(targetC0, math.clamp(dt * 15, 0, 1))
		end
	end)

	print("[ASCEND] FocusTargetController Initialized with Upper-Body Aim Lock.")
end

function FocusTargetController.CreateReticleUI()
	local playerGui = player:WaitForChild("PlayerGui")
	reticleGui = Instance.new("ScreenGui")
	reticleGui.Name = "FocusReticleGUI"
	reticleGui.ResetOnSpawn = false
	reticleGui.Enabled = false

	reticleFrame = Instance.new("Frame")
	reticleFrame.Name = "Reticle"
	reticleFrame.Size = UDim2.new(0, 16, 0, 16)
	reticleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	reticleFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	reticleFrame.BackgroundTransparency = 1

	local circle = Instance.new("Frame")
	circle.Size = UDim2.new(0, 8, 0, 8)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.BackgroundColor3 = Color3.fromRGB(0, 220, 255)
	circle.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(15, 23, 42)
	stroke.Thickness = 1.5
	stroke.Parent = circle

	circle.Parent = reticleFrame
	reticleFrame.Parent = reticleGui
	reticleGui.Parent = playerGui
end

function FocusTargetController.ToggleFocusMode()
	isFocusMode = not isFocusMode
	if reticleGui then
		reticleGui.Enabled = isFocusMode
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid and not isFocusMode then
		humanoid.AutoRotate = true

		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local rootJoint = if hrp then hrp:FindFirstChild("RootJoint") :: Motor6D? else nil
		if rootJoint then
			rootJoint.C0 = CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-90), 0, math.rad(180))
		end
	end
end

function FocusTargetController.IsFocusMode(): boolean
	return isFocusMode
end

return FocusTargetController