--!strict
--[[
    DeathReincarnationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/DeathReincarnationController.luau
    Master death and reincarnation controller for ASCEND.
    Wires StarterGui.DeathReincarnationGui to Character death lifecycle:
      - Intercepts Humanoid.Died
      - Cinematic screen darkening & Xianxia Samsara overlay
      - Synchronized rebirth countdown (5s)
      - Smooth fade-in on death, graceful fade-out upon reincarnation at Murim_SpawnDais
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

local DeathReincarnationController = {}

-- UI References
local deathGui: ScreenGui? = nil
local mainContainer: GuiObject? = nil
local titleLabel: TextLabel? = nil
local subLabel: TextLabel? = nil
local timerLabel: TextLabel? = nil
local respawnButton: TextButton? = nil

-- State
local isDying = false
local diedConnection: RBXScriptConnection? = nil
local REINCARNATION_SECONDS = 5

local function ResolveUIElements()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	deathGui = playerGui:WaitForChild("DeathReincarnationGui", 10) :: ScreenGui?

	if not deathGui then
		warn("[DeathReincarnationController] DeathReincarnationGui not found in PlayerGui!")
		return
	end

	deathGui.Enabled = true
	deathGui.DisplayOrder = 100 -- Ensure it renders above HUD

	-- Find root container (CanvasGroup or Frame)
	mainContainer = (deathGui:FindFirstChild("Container", true)
		or deathGui:FindFirstChild("MainFrame", true)
		or deathGui:FindFirstChild("DeathFrame", true)
		or deathGui:FindFirstChild("Background", true)
		or deathGui:FindFirstChildOfClass("CanvasGroup")
		or deathGui:FindFirstChildOfClass("Frame")) :: GuiObject?

	if not mainContainer then
		warn("[DeathReincarnationController] No container found in DeathReincarnationGui!")
		return
	end

	-- Initially hide the overlay
	if mainContainer:IsA("CanvasGroup") then
		mainContainer.GroupTransparency = 1
		mainContainer.Visible = true
	else
		mainContainer.Visible = false
		mainContainer.BackgroundTransparency = 1
	end

	-- Resolve Labels
	titleLabel = (mainContainer:FindFirstChild("TitleLabel", true)
		or mainContainer:FindFirstChild("DeathTitle", true)
		or mainContainer:FindFirstChild("Title", true)) :: TextLabel?

	subLabel = (mainContainer:FindFirstChild("SubLabel", true)
		or mainContainer:FindFirstChild("ReasonLabel", true)
		or mainContainer:FindFirstChild("Subtitle", true)) :: TextLabel?

	timerLabel = (mainContainer:FindFirstChild("TimerLabel", true)
		or mainContainer:FindFirstChild("CountdownLabel", true)
		or mainContainer:FindFirstChild("TimeText", true)) :: TextLabel?

	respawnButton = (mainContainer:FindFirstChild("RespawnButton", true)
		or mainContainer:FindFirstChild("ReincarnateButton", true)
		or mainContainer:FindFirstChildOfClass("TextButton")) :: TextButton?
end

local function FadeScreen(fadeIn: boolean, duration: number)
	if not mainContainer then return end

	local targetTrans = fadeIn and 0 or 1
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	if mainContainer:IsA("CanvasGroup") then
		mainContainer.Visible = true
		TweenService:Create(mainContainer, tweenInfo, { GroupTransparency = targetTrans }):Play()
		if not fadeIn then
			task.delay(duration, function()
				if not isDying and mainContainer then
					mainContainer.Visible = false
				end
			end)
		end
	else
		if fadeIn then
			mainContainer.Visible = true
		end
		TweenService:Create(mainContainer, tweenInfo, { BackgroundTransparency = targetTrans }):Play()
		if not fadeIn then
			task.delay(duration, function()
				if not isDying and mainContainer then
					mainContainer.Visible = false
				end
			end)
		end
	end
end

local function StartReincarnationSequence()
	if isDying then return end
	isDying = true

	-- Set Lore Text
	if titleLabel then
		titleLabel.Text = "PHYSICAL VESSEL SHATTERED"
	end
	if subLabel then
		subLabel.Text = "Qi Dissipated into Heaven and Earth • Recondensing Soul..."
	end

	FadeScreen(true, 0.8)

	-- 5-second countdown loop
	task.spawn(function()
		for sec = REINCARNATION_SECONDS, 1, -1 do
			if not isDying then break end
			if timerLabel then
				timerLabel.Text = string.format("Reincarnating in %d...", sec)
			end
			task.wait(1)
		end

		if isDying and timerLabel then
			timerLabel.Text = "Returning to Murim Spawn..."
		end
	end)
end

local function OnCharacterSpawned(character: Model)
	-- Reset state and fade out overlay
	isDying = false
	FadeScreen(false, 0.6)

	if diedConnection then
		diedConnection:Disconnect()
		diedConnection = nil
	end

	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		diedConnection = humanoid.Died:Connect(function()
			StartReincarnationSequence()
		end)
	end
end

function DeathReincarnationController.Init()
	ResolveUIElements()

	-- Connect current character and future respawns
	if localPlayer.Character then
		task.spawn(function()
			OnCharacterSpawned(localPlayer.Character :: Model)
		end)
	end

	localPlayer.CharacterAdded:Connect(function(newChar)
		OnCharacterSpawned(newChar)
	end)

	print("[DeathReincarnationController] Initialized with Samsara Rebirth Lifecycle.")
end

return DeathReincarnationController