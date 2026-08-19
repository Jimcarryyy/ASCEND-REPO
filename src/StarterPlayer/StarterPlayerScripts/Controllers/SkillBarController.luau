--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Client UI controller for the Skill Action Bar (M1, Q, E, F).
    Hooks directly into StarterGui.SkillsGUI to drive real-time cooldown masks and countdown timers.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local SkillBarController = {}

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui") :: PlayerGui

local combatActionRemote: RemoteEvent

type SkillSlotUI = {
	Container: Frame,
	Icon: ImageLabel,
	KeyText: TextLabel,
	CooldownOverlay: Frame,
	CooldownLabel: TextLabel,
	CooldownDuration: number,
	CooldownEndTime: number,
	IsOnCooldown: boolean,
}

local skillSlots: { [string]: SkillSlotUI } = {}

function SkillBarController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	SkillBarController.HookStudioUI()

	-- Listen for Skill Key Activations to trigger local cooldowns
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			SkillBarController.TriggerCooldown("M1")
		elseif input.KeyCode == Enum.KeyCode.Q then
			SkillBarController.TriggerCooldown("Q")
		elseif input.KeyCode == Enum.KeyCode.E then
			SkillBarController.TriggerCooldown("E")
		elseif input.KeyCode == Enum.KeyCode.F then
			SkillBarController.TriggerCooldown("F")
		end
	end)

	-- Frame-by-frame cooldown wipe and countdown loop
	RunService.RenderStepped:Connect(SkillBarController.UpdateCooldowns)

	print("[ASCEND] SkillBarController Initialized (Hooked to Studio SkillsGUI).")
end

function SkillBarController.HookStudioUI()
	local skillsGui = playerGui:WaitForChild("SkillsGUI", 10) :: ScreenGui?
	if not skillsGui then
		warn("[SkillBarController] SkillsGUI not found in PlayerGui!")
		return
	end

	local skillFrame = skillsGui:WaitForChild("SkillFrame", 5) :: Frame?
	if not skillFrame then return end

	local skillKeyMap = {
		["M1"] = { FrameName = "M1_SKILL", TextName = "M1_TEXT", Cooldown = 0.4 },
		["Q"]  = { FrameName = "Q_SKILL",  TextName = "Q_TEXT",  Cooldown = 3.0 },
		["E"]  = { FrameName = "E_SKILL",  TextName = "E_TEXT",  Cooldown = 5.0 },
		["F"]  = { FrameName = "F_SKILL",  TextName = "F_TEXT",  Cooldown = 1.5 },
	}

	for skillKey, data in pairs(skillKeyMap) do
		local container = skillFrame:FindFirstChild(data.FrameName) :: Frame?
		if container then
			local icon = container:FindFirstChildOfClass("ImageLabel") :: ImageLabel?
			local keyText = container:FindFirstChild(data.TextName) :: TextLabel?

			if icon and keyText then
				-- 1. Create or Find Cooldown Overlay Mask
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

				-- 2. Create or Find Cooldown Timer Text
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

				skillSlots[skillKey] = {
					Container = container,
					Icon = icon,
					KeyText = keyText,
					CooldownOverlay = overlay,
					CooldownLabel = timerLbl,
					CooldownDuration = data.Cooldown,
					CooldownEndTime = 0,
					IsOnCooldown = false,
				}

				-- Click support for mobile users tapping the skill box
				if container:IsA("GuiButton") then
					container.MouseButton1Click:Connect(function()
						SkillBarController.OnSkillButtonClicked(skillKey)
					end)
				else
					container.InputBegan:Connect(function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							SkillBarController.OnSkillButtonClicked(skillKey)
						end
					end)
				end
			end
		end
	end
end

function SkillBarController.OnSkillButtonClicked(skillKey: string)
	local controllers = localPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			local req = require(inputCtrl) :: any
			if req.GetTargetPayload then
				local payload = req.GetTargetPayload(skillKey)
				combatActionRemote:FireServer(payload)
			end
		end
	end
	SkillBarController.TriggerCooldown(skillKey)
end

function SkillBarController.TriggerCooldown(skillKey: string)
	local slot = skillSlots[skillKey]
	if not slot or slot.IsOnCooldown then return end

	local now = os.clock()
	slot.IsOnCooldown = true
	slot.CooldownEndTime = now + slot.CooldownDuration
	slot.CooldownOverlay.Visible = true
	slot.CooldownOverlay.Size = UDim2.new(1, 0, 1, 0) -- Full mask
	slot.CooldownLabel.Visible = (slot.CooldownDuration >= 1.0) -- Only show text for skills >= 1s
end

function SkillBarController.UpdateCooldowns()
	local now = os.clock()

	for skillKey, slot in pairs(skillSlots) do
		if slot.IsOnCooldown then
			local remaining = slot.CooldownEndTime - now

			if remaining <= 0 then
				slot.IsOnCooldown = false
				slot.CooldownOverlay.Visible = false
				slot.CooldownLabel.Visible = false
			else
				-- Update Vertical Wipe Ratio
				local ratio = math.clamp(remaining / slot.CooldownDuration, 0, 1)
				slot.CooldownOverlay.Size = UDim2.new(1, 0, ratio, 0)

				if slot.CooldownDuration >= 1.0 then
					slot.CooldownLabel.Text = string.format("%.1fs", remaining)
				end
			end
		end
	end
end

return SkillBarController