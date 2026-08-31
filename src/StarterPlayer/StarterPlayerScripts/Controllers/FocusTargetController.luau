--!strict
--[[
    FocusTargetController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau
    Handles:
      - Azure Reticle & Upper-Body Focus Targeting (Bound to MMB / Z)
      - Top-Center Target Lock-On / Boss Frame (HP, Posture / Guard Break Gauge, Distance)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local FocusTargetController = {}
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isFocusActive = false
local currentTarget: Model? = nil

local focusReticleGui: ScreenGui?
local reticleImage: ImageLabel?

local targetHudGui: ScreenGui?
local targetCard: Frame?
local targetNameLabel: TextLabel?
local targetRealmLabel: TextLabel?
local targetDistanceLabel: TextLabel?
local targetHpFill: Frame?
local targetHpText: TextLabel?
local targetPostureFill: Frame?

local UI_FONT = Enum.Font.Bangers
local TWEEN_FAST = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function CreateReticleAndHUD()
	if focusReticleGui then return end

	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	-- 1. Center Reticle GUI
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

	-- 2. Top-Center Target Lock-On Frame
	targetHudGui = Instance.new("ScreenGui")
	targetHudGui.Name = "TargetLockHUD"
	targetHudGui.ResetOnSpawn = false
	targetHudGui.DisplayOrder = 12
	targetHudGui.Parent = playerGui

	targetCard = Instance.new("Frame")
	targetCard.Name = "TargetCard"
	targetCard.Size = UDim2.new(0, 320, 0, 56)
	targetCard.Position = UDim2.new(0.5, 0, 0, 16)
	targetCard.AnchorPoint = Vector2.new(0.5, 0)
	targetCard.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	targetCard.BackgroundTransparency = 0.25
	targetCard.BorderSizePixel = 0
	targetCard.Visible = false
	targetCard.Parent = targetHudGui

	local corner = Instance.new("UICorner", targetCard)
	corner.CornerRadius = UDim.new(0, 6)

	local stroke = Instance.new("UIStroke", targetCard)
	stroke.Color = Color3.fromRGB(212, 175, 55)
	stroke.Thickness = 1.2
	stroke.Transparency = 0.4

	-- Target Name
	targetNameLabel = Instance.new("TextLabel")
	targetNameLabel.Name = "TargetName"
	targetNameLabel.Size = UDim2.new(0.65, 0, 0, 18)
	targetNameLabel.Position = UDim2.new(0, 10, 0, 4)
	targetNameLabel.BackgroundTransparency = 1
	targetNameLabel.Font = UI_FONT
	targetNameLabel.TextSize = 13
	targetNameLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	targetNameLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetNameLabel.Text = "DEMONIC BEAST"
	targetNameLabel.Parent = targetCard

	-- Realm / Tier
	targetRealmLabel = Instance.new("TextLabel")
	targetRealmLabel.Name = "TargetRealm"
	targetRealmLabel.Size = UDim2.new(0.35, -10, 0, 18)
	targetRealmLabel.Position = UDim2.new(0.65, 0, 0, 4)
	targetRealmLabel.BackgroundTransparency = 1
	targetRealmLabel.Font = Enum.Font.GothamBold
	targetRealmLabel.TextSize = 10
	targetRealmLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
	targetRealmLabel.TextXAlignment = Enum.TextXAlignment.Right
	targetRealmLabel.Text = "ORDER 3"
	targetRealmLabel.Parent = targetCard

	-- HP Gauge (Green/Jade)
	local hpTrack = Instance.new("Frame")
	hpTrack.Name = "HPTrack"
	hpTrack.Size = UDim2.new(1, -20, 0, 14)
	hpTrack.Position = UDim2.new(0, 10, 0, 24)
	hpTrack.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	hpTrack.BorderSizePixel = 0
	hpTrack.ClipsDescendants = true
	hpTrack.Parent = targetCard
	Instance.new("UICorner", hpTrack).CornerRadius = UDim.new(0, 3)

	targetHpFill = Instance.new("Frame")
	targetHpFill.Name = "Fill"
	targetHpFill.Size = UDim2.new(1, 0, 1, 0)
	targetHpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	targetHpFill.BorderSizePixel = 0
	targetHpFill.Parent = hpTrack
	Instance.new("UICorner", targetHpFill).CornerRadius = UDim.new(0, 3)

	local hpGrad = Instance.new("UIGradient")
	hpGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(46, 204, 113)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(26, 120, 66)),
	})
	hpGrad.Parent = targetHpFill

	targetHpText = Instance.new("TextLabel")
	targetHpText.Size = UDim2.new(1, 0, 1, 0)
	targetHpText.BackgroundTransparency = 1
	targetHpText.Font = UI_FONT
	targetHpText.TextSize = 9.5
	targetHpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	targetHpText.Text = "100%"
	targetHpText.Parent = hpTrack

	-- Posture Gauge (Orange Guard-Break Meter)
	local postureTrack = Instance.new("Frame")
	postureTrack.Name = "PostureTrack"
	postureTrack.Size = UDim2.new(1, -20, 0, 6)
	postureTrack.Position = UDim2.new(0, 10, 0, 42)
	postureTrack.BackgroundColor3 = Color3.fromRGB(24, 30, 40)
	postureTrack.BorderSizePixel = 0
	postureTrack.ClipsDescendants = true
	postureTrack.Parent = targetCard
	Instance.new("UICorner", postureTrack).CornerRadius = UDim.new(0, 2)

	targetPostureFill = Instance.new("Frame")
	targetPostureFill.Name = "Fill"
	targetPostureFill.Size = UDim2.new(1, 0, 1, 0)
	targetPostureFill.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
	targetPostureFill.BorderSizePixel = 0
	targetPostureFill.Parent = postureTrack
	Instance.new("UICorner", targetPostureFill).CornerRadius = UDim.new(0, 2)
end

local function FindBestTarget(): Model?
	local myChar = player.Character
	local myHrp = if myChar then myChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not myHrp then return nil end

	local bestTarget: Model? = nil
	local bestDist = 60

	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and obj ~= myChar then
			local humanoid = obj:FindFirstChildOfClass("Humanoid")
			local targetHrp = obj:FindFirstChild("HumanoidRootPart") :: BasePart?

			if humanoid and humanoid.Health > 0 and targetHrp then
				local dist = (myHrp.Position - targetHrp.Position).Magnitude
				if dist <= bestDist then
					local toTarget = (targetHrp.Position - myHrp.Position).Unit
					local dot = camera.CFrame.LookVector:Dot(toTarget)
					if dot > 0.4 then
						bestTarget = obj
						bestDist = dist
					end
				end
			end
		end
	end

	return bestTarget
end

local function UpdateTargetHUD(dt: number)
	if not isFocusActive or not currentTarget or not currentTarget.Parent then
		if targetCard and targetCard.Visible then
			targetCard.Visible = false
		end
		return
	end

	local humanoid = currentTarget:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		FocusTargetController.SetFocus(false)
		return
	end

	if targetCard then targetCard.Visible = true end

	if targetNameLabel then
		targetNameLabel.Text = currentTarget.Name:upper()
	end

	if targetRealmLabel then
		local realm = currentTarget:GetAttribute("Realm") or currentTarget:GetAttribute("Tier") or "DISCIPLE"
		targetRealmLabel.Text = string.upper(tostring(realm))
	end

	if targetHpFill and targetHpText then
		local cur = humanoid.Health
		local max = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(cur / max, 0, 1)
		targetHpFill.Size = UDim2.new(ratio, 0, 1, 0)
		targetHpText.Text = string.format("%d%%", math.floor(ratio * 100))
	end

	if targetPostureFill then
		local posture = tonumber(currentTarget:GetAttribute("Posture")) or 100
		local maxPosture = tonumber(currentTarget:GetAttribute("MaxPosture")) or 100
		local ratio = math.clamp(posture / math.max(1, maxPosture), 0, 1)
		targetPostureFill.Size = UDim2.new(ratio, 0, 1, 0)
	end
end

function FocusTargetController.Init()
	CreateReticleAndHUD()

	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton3 or input.KeyCode == Enum.KeyCode.Z then
			FocusTargetController.ToggleFocus()
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		if not isFocusActive then return end

		local character = player.Character
		if not character or character:GetAttribute("IsMeditating") == true then
			if isFocusActive then FocusTargetController.SetFocus(false) end
			return
		end

		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end

		if currentTarget and currentTarget.Parent then
			local targetHrp = currentTarget:FindFirstChild("HumanoidRootPart") :: BasePart?
			if targetHrp then
				local dir = (targetHrp.Position - hrp.Position)
				local flatLook = Vector3.new(dir.X, 0, dir.Z).Unit
				if flatLook.Magnitude > 0.1 then
					hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
				end
			end
		else
			local lookVec = camera.CFrame.LookVector
			local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z).Unit
			if flatLook.Magnitude > 0.1 then
				hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatLook)
			end
		end

		UpdateTargetHUD(dt)
	end)

	print("[ASCEND] FocusTargetController Initialized (Target Lock & Top HUD Active).")
end

function FocusTargetController.ToggleFocus()
	FocusTargetController.SetFocus(not isFocusActive)
end

function FocusTargetController.SetFocus(active: boolean)
	isFocusActive = active
	currentTarget = if isFocusActive then FindBestTarget() else nil

	if focusReticleGui then
		focusReticleGui.Enabled = isFocusActive
	end

	if targetCard then
		targetCard.Visible = isFocusActive and (currentTarget ~= nil)
	end

	UserInputService.MouseBehavior = if isFocusActive then Enum.MouseBehavior.LockCenter else Enum.MouseBehavior.Default
end

return FocusTargetController