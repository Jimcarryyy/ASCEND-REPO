--!strict
--[[
    HUDController.luau
    Manages client HUD state, skill bar cooldown masks, active slot highlights,
    and boss/tribulation health displays.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local HUDController = {}
HUDController.__index = HUDController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local hudGui: ScreenGui?
local actionSkillBar: Frame?
local bossHealthBar: Frame?
local bossFill: Frame?
local bossTitle: TextLabel?

local activeSlots: { [string]: GuiObject } = {}
local activeCooldowns: { [string]: thread } = {}

function HUDController.Init()
	hudGui = playerGui:WaitForChild("HUDGui", 10) :: ScreenGui?
	if not hudGui then
		warn("[HUDController] 'HUDGui' ScreenGui not found in PlayerGui!")
		return
	end

	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if data.IsTribulationActive and data.TribulationWave then
			local waveTitle = string.format("⚡ HEAVENLY TRIBULATION — Strike %d / %d ⚡", data.TribulationWave, data.TotalWaves or 0)
			HUDController.SetBossHealthVisible(true, waveTitle)
			HUDController.UpdateBossHealth(data.TribulationWave, data.TotalWaves or 1)
		else
			HUDController.SetBossHealthVisible(false)
		end
	end)

	actionSkillBar = hudGui:FindFirstChild("ActionSkillBar") :: Frame?
	bossHealthBar = hudGui:FindFirstChild("BossHealthBar") :: Frame?
	if bossHealthBar then
		bossFill = bossHealthBar:FindFirstChild("Fill") :: Frame? or bossHealthBar:FindFirstChild("Bar") :: Frame?
		bossTitle = bossHealthBar:FindFirstChild("Title") :: TextLabel? or bossHealthBar:FindFirstChild("NameLabel") :: TextLabel?
	end

	if actionSkillBar then
		HUDController.SetupSkillSlots()
	end

	HUDController.SetBossHealthVisible(false)

	local syncCooldownRemote = RemoteEvents.GetRemote("SyncCooldown")
	syncCooldownRemote.OnClientEvent:Connect(function(skillKey: string, cooldownDuration: number)
		HUDController.TriggerCooldown(skillKey, cooldownDuration)
	end)

	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")
	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string, skillIcons: { [string]: string })
		for key, iconAsset in pairs(skillIcons) do
			local slot = actionSkillBar:FindFirstChild("Slot_" .. key)
			if slot then
				local iconLabel = slot:FindFirstChild("Icon")
				if iconLabel and (iconLabel:IsA("ImageLabel") or iconLabel:IsA("ImageButton")) then
					iconLabel.Image = iconAsset
				end
			end
		end
		print("[HUDController] HUD skill icons updated for weapon:", weaponType)
	end)

	print("[ASCEND] HUDController UI Renderer Initialized.")
end

function HUDController.SetupSkillSlots()
	if not actionSkillBar then return end

	local slotsConfig = {
		{ Key = "M1", BindText = "LMB", Icon = UIAssets.Skills.M1_SwordArt },
		{ Key = "F", BindText = "F", Icon = UIAssets.Skills.M2_HeavySlam },
		{ Key = "Q", BindText = "Q", Icon = UIAssets.Skills.SwordTempest },
		{ Key = "E", BindText = "E", Icon = UIAssets.Skills.DragonRoar },
		{ Key = "R", BindText = "R", Icon = UIAssets.Skills.TribulationBolt },
		{ Key = "Shift", BindText = "SHIFT", Icon = UIAssets.Skills.DodgeWindstep },
	}

	for _, config in ipairs(slotsConfig) do
		local slot = actionSkillBar:FindFirstChild("Slot_" .. config.Key) :: GuiObject?
		if slot then
			activeSlots[config.Key] = slot
			
			if slot:IsA("ImageLabel") or slot:IsA("ImageButton") then
				slot.Image = UIAssets.HUD.SlotBase
				slot.BackgroundTransparency = 1
			else
				local bg = slot:FindFirstChild("Background")
				if bg and (bg:IsA("ImageLabel") or bg:IsA("ImageButton")) then
					bg.Image = UIAssets.HUD.SlotBase
					bg.BackgroundTransparency = 1
				end
			end
			
			local iconLabel = slot:FindFirstChild("Icon")
			if iconLabel and (iconLabel:IsA("ImageLabel") or iconLabel:IsA("ImageButton")) then
				iconLabel.Image = config.Icon
			end

			local badge = slot:FindFirstChild("KeyBadge")
			if badge and (badge:IsA("ImageLabel") or badge:IsA("ImageButton")) then
				badge.Image = UIAssets.HUD.KeyBadge
				local keyText = badge:FindFirstChild("KeyText")
				if keyText and (keyText:IsA("TextLabel") or keyText:IsA("TextButton")) then
					keyText.Text = config.BindText
				end
			end

			local highlight = slot:FindFirstChild("ActiveBorder")
			if highlight and (highlight:IsA("ImageLabel") or highlight:IsA("ImageButton")) then
				highlight.Image = UIAssets.HUD.SlotActive
				highlight.BackgroundTransparency = 1
				highlight.ZIndex = 2
				highlight.Visible = false
			end

			local mask = slot:FindFirstChild("CooldownMask") :: Frame?
			if mask then
				mask.ZIndex = 4
				mask.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
				mask.BackgroundTransparency = 0.45
				mask.Position = UDim2.new(0, 0, 0, 0)
				mask.Size = UDim2.new(1, 0, 0, 0)
				mask.Visible = false

				local corner = mask:FindFirstChildOfClass("UICorner")
				if not corner then
					corner = Instance.new("UICorner")
					corner.CornerRadius = UDim.new(0, 8)
					corner.Parent = mask
				end
			end

			local textLabel = slot:FindFirstChild("CooldownText") :: TextLabel?
			if textLabel then
				textLabel.ZIndex = 5
				textLabel.Text = ""
				textLabel.Visible = false
			end
		end
	end
end

function HUDController.SetSlotHighlight(slotKey: string, active: boolean)
	local slot = activeSlots[slotKey]
	if not slot then return end

	local highlight = slot:FindFirstChild("ActiveBorder") :: GuiObject?
	if highlight then
		highlight.Visible = active
	end
end

function HUDController.HighlightSlotPulse(slotKey: string, pulseDuration: number)
	HUDController.SetSlotHighlight(slotKey, true)
	task.delay(pulseDuration, function()
		HUDController.SetSlotHighlight(slotKey, false)
	end)
end

function HUDController.TriggerCooldown(slotKey: string, duration: number)
	local slot = activeSlots[slotKey]
	if not slot then return end

	local mask = slot:FindFirstChild("CooldownMask") :: Frame?
	local textLabel = slot:FindFirstChild("CooldownText") :: TextLabel?
	if not mask then return end

	if activeCooldowns[slotKey] then
		task.cancel(activeCooldowns[slotKey])
		activeCooldowns[slotKey] = nil
	end

	mask.Visible = true
	mask.ZIndex = 4
	mask.Position = UDim2.new(0, 0, 0, 0)
	mask.Size = UDim2.new(1, 0, 1, 0)

	if textLabel then
		textLabel.Visible = true
		textLabel.ZIndex = 5
		textLabel.Text = string.format("%.1f", duration)
	end

	local tween = TweenService:Create(mask, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(1, 0, 0, 0)
	})
	tween:Play()

	local startTime = os.clock()
	activeCooldowns[slotKey] = task.spawn(function()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, duration - elapsed)

			if textLabel then
				if remaining > 0 then
					textLabel.Text = string.format("%.1f", remaining)
				else
					textLabel.Text = ""
				end
			end

			if remaining <= 0 then
				break
			end

			task.wait(0.03)
		end

		mask.Visible = false
		if textLabel then
			textLabel.Visible = false
			textLabel.Text = ""
		end
		activeCooldowns[slotKey] = nil
	end)
end

function HUDController.SetBossHealthVisible(visible: boolean, title: string?)
	if not bossHealthBar then return end
	bossHealthBar.Visible = visible
	if visible and title and bossTitle then
		bossTitle.Text = title
	end
end

function HUDController.UpdateBossHealth(currentHealth: number, maxHealth: number)
	if not bossFill then return end
	local percentage = math.clamp(currentHealth / maxHealth, 0, 1)
	TweenService:Create(bossFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.new(percentage, 0, 1, 0)
	}):Play()
end

return HUDController