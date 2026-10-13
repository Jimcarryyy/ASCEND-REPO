--!strict
--[[
    BossHUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/BossHUDController.luau
    Wires StarterGui.BossHealthHUD exclusively to active Humanoid World Boss encounters.
    Monster Sovereign Boss checks removed.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobConfig = require(ReplicatedStorage.Shared.Configs.MobConfig)

local localPlayer = Players.LocalPlayer

local BossHUDController = {}

local bossGui: ScreenGui? = nil
local mainContainer: GuiObject? = nil
local nameLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil
local healthFill: Frame? = nil
local lagFill: Frame? = nil
local healthText: TextLabel? = nil

local currentBossModel: Model? = nil
local isHudVisible = false
local healthConn: RBXScriptConnection? = nil
local stateConn: RBXScriptConnection? = nil

local ENGAGE_DISTANCE = 65
local DISENGAGE_DISTANCE = 95

local function ResolveUIElements()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	bossGui = playerGui:WaitForChild("BossHealthHUD", 10) :: ScreenGui?

	if not bossGui then return end
	bossGui.Enabled = true

	mainContainer = (bossGui:FindFirstChild("Container", true)
		or bossGui:FindFirstChild("MainFrame", true)
		or bossGui:FindFirstChild("BossFrame", true)
		or bossGui:FindFirstChildOfClass("CanvasGroup")
		or bossGui:FindFirstChildOfClass("Frame")) :: GuiObject?

	if not mainContainer then return end

	if mainContainer:IsA("CanvasGroup") then
		mainContainer.GroupTransparency = 1
	else
		mainContainer.Visible = false
	end

	nameLabel = (mainContainer:FindFirstChild("NameLabel", true)
		or mainContainer:FindFirstChild("BossName", true)
		or mainContainer:FindFirstChild("Title", true)) :: TextLabel?

	titleLabel = (mainContainer:FindFirstChild("TitleLabel", true)
		or mainContainer:FindFirstChild("Subtitle", true)
		or mainContainer:FindFirstChild("RankLabel", true)) :: TextLabel?

	healthText = (mainContainer:FindFirstChild("HealthText", true)
		or mainContainer:FindFirstChild("HPLabel", true)
		or mainContainer:FindFirstChild("PercentText", true)) :: TextLabel?

	healthFill = (mainContainer:FindFirstChild("Fill", true)
		or mainContainer:FindFirstChild("HealthFill", true)
		or mainContainer:FindFirstChild("ProgressBar", true)) :: Frame?

	lagFill = (mainContainer:FindFirstChild("LagBar", true)
		or mainContainer:FindFirstChild("DamageFill", true)) :: Frame?
end

local function SetHUDVisible(visible: boolean)
	if not mainContainer or isHudVisible == visible then return end
	isHudVisible = visible

	if mainContainer:IsA("CanvasGroup") then
		TweenService:Create(mainContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = visible and 0 or 1,
		}):Play()
	else
		if visible then
			mainContainer.Visible = true
			mainContainer.BackgroundTransparency = 1
			TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.15,
			}):Play()
		else
			local tw = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1,
			})
			tw:Play()
			tw.Completed:Connect(function()
				if not isHudVisible and mainContainer then
					mainContainer.Visible = false
				end
			end)
		end
	end
end

local function UpdateHealthBar(currentHp: number, maxHp: number)
	if maxHp <= 0 then return end
	local pct = math.clamp(currentHp / maxHp, 0, 1)

	if healthFill then
		TweenService:Create(healthFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(pct, 0, 1, 0),
		}):Play()
	end

	if lagFill then
		task.delay(0.25, function()
			if lagFill and isHudVisible then
				TweenService:Create(lagFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(pct, 0, 1, 0),
				}):Play()
			end
		end)
	end

	if healthText then
		healthText.Text = string.format("%s / %s (%.0f%%)",
			tostring(math.round(currentHp)),
			tostring(math.round(maxHp)),
			pct * 100
		)
	end
end

local function DetachBoss()
	if healthConn then healthConn:Disconnect(); healthConn = nil end
	if stateConn then stateConn:Disconnect(); stateConn = nil end
	currentBossModel = nil
	SetHUDVisible(false)
end

local function AttachBoss(model: Model, displayName: string, subtitle: string, curHp: number, maxHp: number)
	if currentBossModel == model then return end
	DetachBoss()

	currentBossModel = model

	if nameLabel then nameLabel.Text = displayName end
	if titleLabel then titleLabel.Text = subtitle end

	UpdateHealthBar(curHp, maxHp)
	SetHUDVisible(true)

	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum then
		healthConn = hum.HealthChanged:Connect(function(newHp)
			UpdateHealthBar(newHp, hum.MaxHealth)
		end)
		stateConn = hum.Died:Connect(function()
			if healthText then healthText.Text = "VANQUISHED" end
			if healthFill then healthFill.Size = UDim2.new(0, 0, 1, 0) end
			task.delay(2.5, function()
				if currentBossModel == model then DetachBoss() end
			end)
		end)
	end
end

local function FindNearbyHumanoidBoss(): (Model?, string?, string?, number?, number?)
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil end

	local mobSpawns = Workspace:FindFirstChild("MobSpawns") or Workspace
	for _, desc in ipairs(mobSpawns:GetDescendants()) do
		if desc:IsA("Model") and (desc.Name == "Boss_FallenSwordGenius" or desc:GetAttribute("IsBoss") == true) then
			local hum = desc:FindFirstChildOfClass("Humanoid")
			local bossHrp = desc:FindFirstChild("HumanoidRootPart") or desc.PrimaryPart
			if hum and bossHrp and hum.Health > 0 then
				local dist = (bossHrp.Position - hrp.Position).Magnitude
				if dist <= ENGAGE_DISTANCE then
					local cfg = MobConfig.GetMobConfig(desc.Name) or MobConfig.GetMobConfig("Boss_FallenSwordGenius")
					local dName = cfg and cfg.DisplayName or "Fallen Sword Genius - Mo Chen"
					local subtitle = "WORLD DECREE • TIER 5 DEMONIC SWORD MASTER"
					return desc, dName, subtitle, hum.Health, hum.MaxHealth
				end
			end
		end
	end

	return nil
end

function BossHUDController.Init()
	ResolveUIElements()

	task.spawn(function()
		while true do
			task.wait(0.5)

			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

			if currentBossModel and currentBossModel.Parent and hrp then
				local rootPart = currentBossModel:FindFirstChild("HumanoidRootPart") or currentBossModel.PrimaryPart
				if rootPart then
					local dist = (rootPart.Position - hrp.Position).Magnitude
					if dist > DISENGAGE_DISTANCE then
						DetachBoss()
					end
				else
					DetachBoss()
				end
			else
				if currentBossModel then DetachBoss() end

				local bModel, dName, sub, hp, maxHp = FindNearbyHumanoidBoss()
				if bModel and dName and sub and hp and maxHp then
					AttachBoss(bModel, dName, sub, hp, maxHp)
				end
			end
		end
	end)

	print("[BossHUDController] Initialized for Humanoid World Bosses.")
end

return BossHUDController