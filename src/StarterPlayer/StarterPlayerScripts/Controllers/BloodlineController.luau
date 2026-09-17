--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local BloodlineController = {}
local isInitialized = false

local CLICK_SFX_ID = "rbxassetid://138567614125924"

local TIER_GRADIENTS = {
	Common = { Color3.fromRGB(14, 116, 144), Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161) },
	Rare = { Color3.fromRGB(5, 150, 105), Color3.fromRGB(16, 185, 129), Color3.fromRGB(4, 120, 87) },
	Legendary = { Color3.fromRGB(159, 18, 57), Color3.fromRGB(244, 63, 94), Color3.fromRGB(136, 19, 55) },
	Mythic = { Color3.fromRGB(76, 29, 149), Color3.fromRGB(167, 139, 250), Color3.fromRGB(67, 20, 120) },
}

local clickSound: Sound?

local function playClick()
	if not clickSound then
		clickSound = Instance.new("Sound")
		clickSound.Name = "BloodlineClickSFX"
		clickSound.SoundId = CLICK_SFX_ID
		clickSound.Volume = 0.65
		clickSound.Parent = SoundService
	end
	clickSound:Play()
end

function BloodlineController.Init()
	if isInitialized then return end
	isInitialized = true

	local lp = Players.LocalPlayer
	local pGui = lp:WaitForChild("PlayerGui") :: PlayerGui
	local screenGui = pGui:WaitForChild("BloodlineGui", 10) :: ScreenGui?
	if not screenGui then
		warn("[BloodlineController] BloodlineGui not found in PlayerGui.")
		return
	end

	local overlayBackdrop = screenGui:WaitForChild("OverlayBackdrop") :: Frame
	local mainFrame = overlayBackdrop:WaitForChild("MainFrame") :: Frame
	local uiScale = mainFrame:WaitForChild("UIScale") :: UIScale

	local headerFrame = mainFrame:WaitForChild("HeaderFrame") :: Frame
	local closeBtn = headerFrame:WaitForChild("CloseImageButton") :: TextButton

	local firstFrame = mainFrame:WaitForChild("FirstFrame") :: Frame
	local leftSub1 = firstFrame:WaitForChild("SubFrame1") :: Frame
	local tierPill = leftSub1:WaitForChild("TierPill") :: Frame
	local showcasePlate = leftSub1:WaitForChild("ShowcasePlate") :: Frame
	local lineageName = showcasePlate:WaitForChild("LineageName") :: TextLabel
	local passiveSummary = showcasePlate:WaitForChild("PassiveSummary") :: TextLabel
	local lineageDesc = leftSub1:WaitForChild("LineageDescription") :: TextLabel

	local leftSub2 = firstFrame:WaitForChild("SubFrame2") :: Frame
	local spinsPill = leftSub2:WaitForChild("SpinsPill") :: Frame
	local spin1xBtn = leftSub2:WaitForChild("Spin1xBtn") :: TextButton
	local spin10xBtn = leftSub2:WaitForChild("Spin10xBtn") :: TextButton

	local secondFrame = mainFrame:WaitForChild("SecondFrame") :: Frame
	local rightSub1 = secondFrame:WaitForChild("SubFrame1") :: Frame
	local stonesPill = rightSub1:WaitForChild("StonesPill") :: Frame
	local buy1Btn = rightSub1:WaitForChild("Buy1Btn") :: TextButton
	local buy10Btn = rightSub1:WaitForChild("Buy10Btn") :: TextButton

	local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteEvents") :: any)
	local bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction") :: RemoteEvent

	local isOpen = false

	-- Universal Pop-Up Open Animation
	local function openModal()
		if isOpen then return end
		isOpen = true
		playClick()

		screenGui.Enabled = true
		overlayBackdrop.BackgroundTransparency = 1
		overlayBackdrop.Visible = true
		uiScale.Scale = 0.75

		TweenService:Create(overlayBackdrop, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.45,
		}):Play()

		TweenService:Create(uiScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Scale = 1.0,
		}):Play()

		bloodlineRemote:FireServer({ Action = "GetState" })
	end

	-- Universal Pop-Up Close Animation
	local function closeModal()
		if not isOpen then return end
		isOpen = false
		playClick()

		local tInfo = TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		local scaleTween = TweenService:Create(uiScale, tInfo, { Scale = 0.75 })
		local fadeTween = TweenService:Create(overlayBackdrop, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})

		scaleTween:Play()
		fadeTween:Play()
		scaleTween.Completed:Connect(function()
			if not isOpen then
				overlayBackdrop.Visible = false
				screenGui.Enabled = false
				uiScale.Scale = 1.0
			end
		end)
	end

	closeBtn.Activated:Connect(closeModal)

	-- Button Micro-Interactions
	local function wireButton(btn: TextButton)
		local bScale = btn:FindFirstChild("UIScale") :: UIScale?
		local glow = btn:FindFirstChild("GlowOverlayImage") :: ImageLabel?
		if not bScale then return end

		btn.MouseEnter:Connect(function()
			if glow then glow.Visible = true end
			TweenService:Create(bScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.03 }):Play()
		end)
		btn.MouseLeave:Connect(function()
			if glow then glow.Visible = false end
			TweenService:Create(bScale, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.0 }):Play()
		end)
		btn.MouseButton1Down:Connect(function()
			TweenService:Create(bScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 0.97 }):Play()
		end)
		btn.MouseButton1Up:Connect(function()
			TweenService:Create(bScale, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Scale = 1.03 }):Play()
		end)
	end

	wireButton(closeBtn)
	wireButton(spin1xBtn)
	wireButton(spin10xBtn)
	wireButton(buy1Btn)
	wireButton(buy10Btn)

	-- Proximity Prompt Hook (Strictly world-based, no keybinds)
	local function bindAltarPrompt(prompt: ProximityPrompt)
		prompt.RequiresLineOfSight = false
		prompt.MaxActivationDistance = 25
		prompt.HoldDuration = 0.3
		prompt.Triggered:Connect(function()
			openModal()
		end)
	end

	local altar = workspace:FindFirstChild("BloodlineAltar")
	local dais = altar and altar:FindFirstChild("AttunementDais")
	local existingPrompt = dais and dais:FindFirstChild("BloodlineAltarPrompt") :: ProximityPrompt?
	if existingPrompt then
		bindAltarPrompt(existingPrompt)
	else
		workspace.DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") and desc.Name == "BloodlineAltarPrompt" then
				bindAltarPrompt(desc)
			end
		end)
	end

	-- Helpers
	local function updatePillCaption(pill: Frame, text: string)
		local cap = pill:FindFirstChild("PillCaption") :: TextLabel?
		if cap then cap.Text = string.upper(text) end
	end

	local function applyTierPillStyle(tierName: string)
		updatePillCaption(tierPill, tierName)
		local grad = tierPill:FindFirstChildWhichIsA("UIGradient")
		local colors = TIER_GRADIENTS[tierName] or TIER_GRADIENTS.Common
		if grad then
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, colors[1]),
				ColorSequenceKeypoint.new(0.5, colors[2]),
				ColorSequenceKeypoint.new(1, colors[3]),
			})
		end
	end

	local function formatPassivesText(passives: { [string]: number }?): string
		if not passives or next(passives) == nil then
			return "Base Attributes • No Ancestral Amplifications Active"
		end

		local parts = {}
		if passives.DamageMultiplier then
			table.insert(parts, string.format("+%d%% SWORD DMG", math.round((passives.DamageMultiplier - 1) * 100)))
		end
		if passives.HealthMultiplier then
			table.insert(parts, string.format("+%d%% MAX HP", math.round((passives.HealthMultiplier - 1) * 100)))
		end
		if passives.QiGatherMultiplier then
			table.insert(parts, string.format("+%d%% QI FLOW", math.round((passives.QiGatherMultiplier - 1) * 100)))
		end
		if passives.SpeedMultiplier then
			table.insert(parts, string.format("+%d%% FOOTWORK", math.round((passives.SpeedMultiplier - 1) * 100)))
		end
		if passives.CritChance then
			table.insert(parts, string.format("+%d%% CRIT", math.round(passives.CritChance * 100)))
		end

		if #parts == 0 then
			return "Ancestral Resonance Active"
		end
		return table.concat(parts, " • ")
	end

	-- Button Actions with Click SFX
	spin1xBtn.Activated:Connect(function()
		playClick()
		bloodlineRemote:FireServer({ Action = "Spin" })
	end)

	spin10xBtn.Activated:Connect(function()
		playClick()
		bloodlineRemote:FireServer({ Action = "Spin10x" })
	end)

	buy1Btn.Activated:Connect(function()
		playClick()
		bloodlineRemote:FireServer({ Action = "ExchangeSpins", Amount = 1 })
	end)

	buy10Btn.Activated:Connect(function()
		playClick()
		bloodlineRemote:FireServer({ Action = "ExchangeSpins", Amount = 10 })
	end)

	-- Network Sync
	bloodlineRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then return end

		if payload.Action == "StateUpdate" or payload.Action == "SpinResult" then
			lineageName.Text = string.upper(payload.DisplayName or payload.BloodlineId or "MORTAL MERIDIANS")
			applyTierPillStyle(payload.Rarity or "Common")
			passiveSummary.Text = formatPassivesText(payload.Passives)
			lineageDesc.Text = payload.Description or ""

			updatePillCaption(spinsPill, string.format("+%d AWAKEN BEADS", payload.RemainingSpins or 0))
			if payload.RemainingStones then
				updatePillCaption(stonesPill, string.format("+%d STONES", payload.RemainingStones))
			end

			if payload.Action == "SpinResult" then
				local pop = TweenService:Create(showcasePlate, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0.94, 0, 0.46, 0),
				})
				pop:Play()
				pop.Completed:Connect(function()
					TweenService:Create(showcasePlate, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						Size = UDim2.new(0.92, 0, 0.44, 0),
					}):Play()
				end)
			end

		elseif payload.Action == "SpinFailed" or payload.Action == "ExchangeFailed" then
			warn("[BloodlineController] " .. tostring(payload.Message))
		end
	end)

	-- Hide by default
	overlayBackdrop.Visible = false
	screenGui.Enabled = false

	print("[BloodlineController] Initialized.")
end

function BloodlineController.Start()
	BloodlineController.Init()
end

-- Self-bootstrap fallback if ClientMain doesn't auto-require every controller
task.defer(function()
	BloodlineController.Init()
end)

return BloodlineController