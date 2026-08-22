--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Client controller for Combat Action Bars:
    - Manages Desktop SkillsGUI (M1, Q, E, F, SHIFT).
    - Builds and drives the Native Transparent Mobile Touch Action Cluster on Phone/Tablet.
    - Synchronizes real-time cooldown masks and timer overlays across both platforms.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local SkillBarController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

type SkillSlotUI = {
	Container: GuiObject,
	CooldownOverlay: Frame,
	CooldownLabel: TextLabel,
	CooldownDuration: number,
	CooldownEndTime: number,
	IsOnCooldown: boolean,
}

local desktopSlots: { [string]: SkillSlotUI } = {}
local mobileSlots: { [string]: SkillSlotUI } = {}
local mobileTouchGui: ScreenGui? = nil

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

function SkillBarController.Init()
	local isTouch = IsTouchDevice()

	local desktopGui = playerGui:WaitForChild("SkillsGUI", 8) :: ScreenGui?
	if desktopGui then
		desktopGui.Enabled = not isTouch
		SkillBarController.HookDesktopUI(desktopGui)
	end

	if isTouch then
		SkillBarController.CreateNativeMobileTouchCluster()
	end

	RunService.RenderStepped:Connect(SkillBarController.UpdateCooldowns)
	print("[ASCEND] SkillBarController Initialized with Native Mobile Touch Controls.")
end

-- =============================================================================
-- 1. DESKTOP SKILLS GUI
-- =============================================================================
function SkillBarController.HookDesktopUI(skillsGui: ScreenGui)
	local skillFrame = skillsGui:WaitForChild("SkillFrame", 5) :: Frame?
	if not skillFrame then return end

	local skillConfig = {
		["M1"]   = { FrameName = "M1_SKILL",   TextName = "M1_TEXT",   Cooldown = 0.38 },
		["Q"]    = { FrameName = "Q_SKILL",    TextName = "Q_TEXT",    Cooldown = 3.0 },
		["E"]    = { FrameName = "E_SKILL",    TextName = "E_TEXT",    Cooldown = 5.0 },
		["F"]    = { FrameName = "F_SKILL",    TextName = "F_TEXT",    Cooldown = 0.5 },
		["Dash"] = { FrameName = "DASH_SKILL", TextName = "DASH_TEXT", Cooldown = 3.0 },
	}

	for skillKey, data in pairs(skillConfig) do
		local container = skillFrame:FindFirstChild(data.FrameName) :: Frame?
		if container then
			local overlay = container:FindFirstChild("CooldownOverlay") :: Frame?
			if not overlay then
				overlay = Instance.new("Frame")
				overlay.Name = "CooldownOverlay"
				overlay.Size = UDim2.new(1, 0, 0, 0)
				overlay.Position = UDim2.new(0, 0, 1, 0)
				overlay.AnchorPoint = Vector2.new(0, 1)
				overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				overlay.BackgroundTransparency = 0.55
				overlay.BorderSizePixel = 0
				overlay.ZIndex = 5
				overlay.Visible = false
				overlay.Parent = container

				local corner = Instance.new("UICorner")
				corner.CornerRadius = UDim.new(0, 4)
				corner.Parent = overlay
			end

			local timerLbl = container:FindFirstChild("CooldownLabel") :: TextLabel?
			if not timerLbl then
				timerLbl = Instance.new("TextLabel")
				timerLbl.Name = "CooldownLabel"
				timerLbl.Size = UDim2.new(1, 0, 1, 0)
				timerLbl.Position = UDim2.new(0, 0, 0, 0)
				timerLbl.BackgroundTransparency = 1
				timerLbl.Text = ""
				timerLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				timerLbl.Font = Enum.Font.FredokaOne
				timerLbl.TextSize = 16
				timerLbl.ZIndex = 6
				timerLbl.Visible = false
				timerLbl.Parent = container
			end

			desktopSlots[skillKey] = {
				Container = container,
				CooldownOverlay = overlay,
				CooldownLabel = timerLbl,
				CooldownDuration = data.Cooldown,
				CooldownEndTime = 0,
				IsOnCooldown = false,
			}
		end
	end
end

-- =============================================================================
-- 2. NATIVE ROBLOX-STYLED TRANSPARENT MOBILE TOUCH CLUSTER
-- =============================================================================
function SkillBarController.CreateNativeMobileTouchCluster()
	if mobileTouchGui then mobileTouchGui:Destroy() end

	mobileTouchGui = Instance.new("ScreenGui")
	mobileTouchGui.Name = "NativeMobileCombatGui"
	mobileTouchGui.ResetOnSpawn = false
	mobileTouchGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	mobileTouchGui.Parent = playerGui

	local buttonCluster = Instance.new("Frame")
	buttonCluster.Name = "ActionCluster"
	buttonCluster.Size = UDim2.new(0, 260, 0, 260)
	buttonCluster.Position = UDim2.new(1, -20, 1, -20)
	buttonCluster.AnchorPoint = Vector2.new(1, 1)
	buttonCluster.BackgroundTransparency = 1
	buttonCluster.Parent = mobileTouchGui

	local buttonLayouts = {
		["M1"]   = { Name = "M1_BTN",   Label = "⚔️\nM1",   Size = 72, Pos = UDim2.new(1, -75, 1, -165), Cooldown = 0.38, IsMain = true },
		["Dash"] = { Name = "DASH_BTN", Label = "💨\nDASH", Size = 54, Pos = UDim2.new(1, -155, 1, -85),  Cooldown = 3.0, IsMain = false },
		["F"]    = { Name = "F_BTN",    Label = "🛡️\nPARRY",Size = 54, Pos = UDim2.new(1, -155, 1, -160), Cooldown = 0.5, IsMain = false },
		["Q"]    = { Name = "Q_BTN",    Label = "🌪️\nQ",    Size = 50, Pos = UDim2.new(1, -75, 1, -245),  Cooldown = 3.0, IsMain = false },
		["E"]    = { Name = "E_BTN",    Label = "🗡️\nE",    Size = 50, Pos = UDim2.new(1, -155, 1, -235), Cooldown = 5.0, IsMain = false },
	}

	for skillKey, cfg in pairs(buttonLayouts) do
		local btn = Instance.new("TextButton")
		btn.Name = cfg.Name
		btn.Size = UDim2.new(0, cfg.Size, 0, cfg.Size)
		btn.Position = cfg.Pos
		btn.AnchorPoint = Vector2.new(0.5, 0.5)
		btn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
		btn.BackgroundTransparency = 0.45 -- Native Roblox frosted look
		btn.Text = cfg.Label
		btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		btn.Font = Enum.Font.FredokaOne
		btn.TextSize = if cfg.IsMain then 16 else 12
		btn.TextStrokeTransparency = 0.5
		btn.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		btn.AutoButtonColor = false
		btn.ZIndex = 10
		btn.Parent = buttonCluster

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0) -- Perfect Circle
		corner.Parent = btn

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Transparency = 0.65
		stroke.Thickness = 1.5
		stroke.Parent = btn

		-- Circular Cooldown Mask
		local overlay = Instance.new("Frame")
		overlay.Name = "CooldownOverlay"
		overlay.Size = UDim2.new(1, 0, 0, 0)
		overlay.Position = UDim2.new(0, 0, 1, 0)
		overlay.AnchorPoint = Vector2.new(0, 1)
		overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		overlay.BackgroundTransparency = 0.60
		overlay.BorderSizePixel = 0
		overlay.ZIndex = 11
		overlay.Visible = false
		overlay.Parent = btn

		local overlayCorner = Instance.new("UICorner")
		overlayCorner.CornerRadius = UDim.new(1, 0)
		overlayCorner.Parent = overlay

		local timerLbl = Instance.new("TextLabel")
		timerLbl.Name = "CooldownLabel"
		timerLbl.Size = UDim2.new(1, 0, 1, 0)
		timerLbl.Position = UDim2.new(0, 0, 0, 0)
		timerLbl.BackgroundTransparency = 1
		timerLbl.Text = ""
		timerLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
		timerLbl.Font = Enum.Font.FredokaOne
		timerLbl.TextSize = 16
		timerLbl.ZIndex = 12
		timerLbl.Visible = false
		timerLbl.Parent = btn

		mobileSlots[skillKey] = {
			Container = btn,
			CooldownOverlay = overlay,
			CooldownLabel = timerLbl,
			CooldownDuration = cfg.Cooldown,
			CooldownEndTime = 0,
			IsOnCooldown = false,
		}

		-- Touch Events with Push Feedback
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundTransparency = 0.2, Size = UDim2.new(0, cfg.Size * 0.92, 0, cfg.Size * 0.92) }):Play()
				SkillBarController.OnActionTriggered(skillKey, true)
			end
		end)

		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				TweenService:Create(btn, TweenInfo.new(0.08), { BackgroundTransparency = 0.45, Size = UDim2.new(0, cfg.Size, 0, cfg.Size) }):Play()
				SkillBarController.OnActionTriggered(skillKey, false)
			end
		end)
	end
end

function SkillBarController.OnActionTriggered(skillKey: string, isPress: boolean)
	local controllers = localPlayer.PlayerScripts:FindFirstChild("Controllers")
	if not controllers then return end
	local inputCtrl = controllers:FindFirstChild("InputController")
	if not inputCtrl then return end

	local req = require(inputCtrl) :: any

	if skillKey == "M1" and isPress then
		if req.TriggerM1 then req.TriggerM1() end
	elseif skillKey == "Dash" and isPress then
		if req.TriggerDash then req.TriggerDash() end
	elseif skillKey == "F" then
		if isPress then
			if req.StartBlock then req.StartBlock() end
		else
			if req.StopBlock then req.StopBlock() end
		end
	elseif (skillKey == "Q" or skillKey == "E") and isPress then
		if req.TriggerSkill then req.TriggerSkill(skillKey) end
	end
end

-- =============================================================================
-- 3. COOLDOWN PROPAGATION ENGINE
-- =============================================================================
function SkillBarController.TriggerCooldown(skillKey: string)
	local now = os.clock()

	local dSlot = desktopSlots[skillKey]
	if dSlot and not dSlot.IsOnCooldown then
		dSlot.IsOnCooldown = true
		dSlot.CooldownEndTime = now + dSlot.CooldownDuration
		dSlot.CooldownOverlay.Visible = true
		dSlot.CooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
		dSlot.CooldownLabel.Visible = (dSlot.CooldownDuration >= 1.0)
	end

	local mSlot = mobileSlots[skillKey]
	if mSlot and not mSlot.IsOnCooldown then
		mSlot.IsOnCooldown = true
		mSlot.CooldownEndTime = now + mSlot.CooldownDuration
		mSlot.CooldownOverlay.Visible = true
		mSlot.CooldownOverlay.Size = UDim2.new(1, 0, 1, 0)
		mSlot.CooldownLabel.Visible = (mSlot.CooldownDuration >= 1.0)
	end
end

function SkillBarController.UpdateCooldowns()
	local now = os.clock()

	local function processSlots(slots: { [string]: SkillSlotUI })
		for _, slot in pairs(slots) do
			if slot.IsOnCooldown then
				local remaining = slot.CooldownEndTime - now

				if remaining <= 0 then
					slot.IsOnCooldown = false
					slot.CooldownOverlay.Visible = false
					slot.CooldownLabel.Visible = false
				else
					local ratio = math.clamp(remaining / slot.CooldownDuration, 0, 1)
					slot.CooldownOverlay.Size = UDim2.new(1, 0, ratio, 0)

					if slot.CooldownDuration >= 1.0 then
						slot.CooldownLabel.Text = string.format("%.1fs", remaining)
					end
				end
			end
		end
	end

	processSlots(desktopSlots)
	processSlots(mobileSlots)
end

return SkillBarController