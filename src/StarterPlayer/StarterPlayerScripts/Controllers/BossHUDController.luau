--!strict
--[[
    BossHUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/BossHUDController.luau
    Wires StarterGui.BossHealthHUD to active World Boss encounters:
      - Proximity engagement (< 65 studs to Boss_FallenSwordGenius)
      - Dynamic health tracking with smooth Quad-out bar tweening
      - Damage lag bar effect and percentage readout
      - Automatic disengage when out of range (> 95 studs) or upon boss defeat
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MobConfig = require(ReplicatedStorage.Shared.Configs.MobConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local localPlayer = Players.LocalPlayer

local BossHUDController = {}

-- UI References
local bossGui: ScreenGui? = nil
local mainContainer: GuiObject? = nil
local nameLabel: TextLabel? = nil
local titleLabel: TextLabel? = nil
local healthFill: Frame? = nil
local lagFill: Frame? = nil
local healthText: TextLabel? = nil

-- State
local currentBossModel: Model? = nil
local currentBossHumanoid: Humanoid? = nil
local currentBossConfig: any = nil
local isHudVisible = false
local healthConn: RBXScriptConnection? = nil
local diedConn: RBXScriptConnection? = nil

local ENGAGE_DISTANCE = 65    -- AggroRadius from MobConfig
local DISENGAGE_DISTANCE = 95 -- Leash boundary buffer

-- Helper to safely find GUI elements with fallback names
local function ResolveUIElements()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	bossGui = playerGui:WaitForChild("BossHealthHUD", 10) :: ScreenGui?

	if not bossGui then
		warn("[BossHUDController] BossHealthHUD not found in PlayerGui!")
		return
	end

	bossGui.Enabled = true

	-- Find root container (CanvasGroup or Frame)
	mainContainer = (bossGui:FindFirstChild("Container", true)
		or bossGui:FindFirstChild("MainFrame", true)
		or bossGui:FindFirstChild("BossFrame", true)
		or bossGui:FindFirstChildOfClass("CanvasGroup")
		or bossGui:FindFirstChildOfClass("Frame")) :: GuiObject?

	if not mainContainer then
		warn("[BossHUDController] No root container frame found in BossHealthHUD!")
		return
	end

	-- Initially hide HUD
	if mainContainer:IsA("CanvasGroup") then
		mainContainer.GroupTransparency = 1
	else
		mainContainer.Visible = false
	end

	-- Resolve Labels
	nameLabel = (mainContainer:FindFirstChild("NameLabel", true)
		or mainContainer:FindFirstChild("BossName", true)
		or mainContainer:FindFirstChild("Title", true)) :: TextLabel?

	titleLabel = (mainContainer:FindFirstChild("TitleLabel", true)
		or mainContainer:FindFirstChild("Subtitle", true)
		or mainContainer:FindFirstChild("RankLabel", true)) :: TextLabel?

	healthText = (mainContainer:FindFirstChild("HealthText", true)
		or mainContainer:FindFirstChild("HPLabel", true)
		or mainContainer:FindFirstChild("PercentText", true)) :: TextLabel?

	-- Resolve Health Bars
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
		local targetTransparency = visible and 0 or 1
		TweenService:Create(mainContainer, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			GroupTransparency = targetTransparency
		}):Play()
	else
		if visible then
			mainContainer.Visible = true
			mainContainer.BackgroundTransparency = 1
			TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				BackgroundTransparency = 0.15
			}):Play()
		else
			local tw = TweenService:Create(mainContainer, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				BackgroundTransparency = 1
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
			Size = UDim2.new(pct, 0, 1, 0)
		}):Play()
	end

	if lagFill then
		task.delay(0.25, function()
			if lagFill and isHudVisible then
				TweenService:Create(lagFill, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.new(pct, 0, 1, 0)
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
	if healthConn then
		healthConn:Disconnect()
		healthConn = nil
	end
	if diedConn then
		diedConn:Disconnect()
		diedConn = nil
	end
	currentBossModel = nil
	currentBossHumanoid = nil
	currentBossConfig = nil
	SetHUDVisible(false)
end

local function AttachBoss(model: Model, humanoid: Humanoid, config: any)
	if currentBossModel == model then return end
	DetachBoss()

	currentBossModel = model
	currentBossHumanoid = humanoid
	currentBossConfig = config

	-- Set Boss Identity
	if nameLabel then
		nameLabel.Text = config.DisplayName or "Fallen Sword Genius - Mo Chen"
	end
	if titleLabel then
		titleLabel.Text = "WORLD DECREE • TIER 5 DEMONIC SWORD MASTER"
	end

	UpdateHealthBar(humanoid.Health, humanoid.MaxHealth)
	SetHUDVisible(true)

	healthConn = humanoid.HealthChanged:Connect(function(newHp)
		UpdateHealthBar(newHp, humanoid.MaxHealth)
	end)

	diedConn = humanoid.Died:Connect(function()
		if healthText then
			healthText.Text = "VANQUISHED"
		end
		if healthFill then
			healthFill.Size = UDim2.new(0, 0, 1, 0)
		end
		task.delay(2.5, function()
			if currentBossModel == model then
				DetachBoss()
			end
		end)
	end)
end

local function FindNearbyBoss(): (Model?, Humanoid?, any)
	local char = localPlayer.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return nil, nil, nil end

	-- Scan MobSpawns and Workspace for Boss models
	local mobContainer = Workspace:FindFirstChild("MobSpawns") or Workspace
	for _, child in ipairs(mobContainer:GetChildren()) do
		if child:IsA("Model") and (child.Name == "Boss_FallenSwordGenius" or child:GetAttribute("IsBoss") == true) then
			local hum = child:FindFirstChildOfClass("Humanoid")
			local bossHrp = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart
			if hum and bossHrp and hum.Health > 0 then
				local dist = (bossHrp.Position - hrp.Position).Magnitude
				if dist <= ENGAGE_DISTANCE then
					local cfg = MobConfig.GetMobConfig(child.Name) or MobConfig.GetMobConfig("Boss_FallenSwordGenius")
					return child, hum, cfg
				end
			end
		end
	end

	return nil, nil, nil
end

function BossHUDController.Init()
	ResolveUIElements()

	-- Proximity & State tracking loop (every 0.5s)
	task.spawn(function()
		while true do
			task.wait(0.5)

			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?

			if currentBossModel and currentBossModel.Parent and currentBossHumanoid and currentBossHumanoid.Health > 0 and hrp then
				local bossHrp = currentBossModel:FindFirstChild("HumanoidRootPart") or currentBossModel.PrimaryPart
				if bossHrp then
					local dist = (bossHrp.Position - hrp.Position).Magnitude
					if dist > DISENGAGE_DISTANCE then
						DetachBoss()
					end
				else
					DetachBoss()
				end
			else
				if currentBossModel then
					DetachBoss()
				end

				-- Check if we are near any world boss
				local bossModel, bossHum, bossCfg = FindNearbyBoss()
				if bossModel and bossHum and bossCfg then
					AttachBoss(bossModel, bossHum, bossCfg)
				end
			end
		end
	end)

	print("[BossHUDController] Initialized with Proximity & Health Tracking.")
end

return BossHUDController