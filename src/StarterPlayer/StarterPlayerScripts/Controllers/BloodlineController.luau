--!strict
--[[
    BloodlineController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/BloodlineController.luau
    Master Client Controller for Bloodline Awakening, Meridian Vault & Pity
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local BloodlineController = {}
local isInitialized = false

local CLICK_SFX_ID = "rbxassetid://138567614125924"
local clickSound: Sound?

local TIER_GRADIENTS = {
	Common = { Color3.fromRGB(14, 116, 144), Color3.fromRGB(56, 189, 248), Color3.fromRGB(3, 105, 161) },
	Rare = { Color3.fromRGB(5, 150, 105), Color3.fromRGB(16, 185, 129), Color3.fromRGB(4, 120, 87) },
	Legendary = { Color3.fromRGB(159, 18, 57), Color3.fromRGB(244, 63, 94), Color3.fromRGB(136, 19, 55) },
	Mythic = { Color3.fromRGB(76, 29, 149), Color3.fromRGB(167, 139, 250), Color3.fromRGB(67, 20, 120) },
}

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

	-- Left Column Elements
	local firstFrame = mainFrame:WaitForChild("FirstFrame") :: Frame
	local leftSub1 = firstFrame:WaitForChild("SubFrame1") :: Frame
	local tierPill = leftSub1:WaitForChild("TierPill") :: Frame
	local showcasePlate = leftSub1:WaitForChild("ShowcasePlate") :: Frame
	local lineageName = showcasePlate:WaitForChild("LineageName") :: TextLabel
	local passiveSummary = showcasePlate:WaitForChild("PassiveSummary") :: TextLabel
	local lineageDesc = leftSub1:WaitForChild("LineageDescription") :: TextLabel

	-- Meridian Vault Slot Rows
	local leftSub2 = firstFrame:WaitForChild("SubFrame2") :: Frame
	local slotRow1 = leftSub2:WaitForChild("SlotRow_1") :: Frame
	local slotLabel1 = slotRow1:WaitForChild("SlotLabel") :: TextLabel
	local slotBtn1 = slotRow1:WaitForChild("SlotActionBtn") :: TextButton

	local slotRow2 = leftSub2:WaitForChild("SlotRow_2") :: Frame
	local slotLabel2 = slotRow2:WaitForChild("SlotLabel") :: TextLabel
	local slotBtn2 = slotRow2:WaitForChild("SlotActionBtn") :: TextButton

	local slotRow3 = leftSub2:WaitForChild("SlotRow_3") :: Frame
	local slotLabel3 = slotRow3:WaitForChild("SlotLabel") :: TextLabel
	local slotBtn3 = slotRow3:WaitForChild("SlotActionBtn") :: TextButton

	-- Right Column Elements
	local secondFrame = mainFrame:WaitForChild("SecondFrame") :: Frame
	local rightSub1 = secondFrame:WaitForChild("SubFrame1") :: Frame
	local legPityPill = rightSub1:WaitForChild("LegendaryPityPill") :: Frame
	local mythPityPill = rightSub1:WaitForChild("MythicPityPill") :: Frame
	local stonesPill = rightSub1:WaitForChild("StonesPill") :: Frame
	local buy1Btn = rightSub1:WaitForChild("Buy1Btn") :: TextButton
	local buy10Btn = rightSub1:WaitForChild("Buy10Btn") :: TextButton

	local rightSub2 = secondFrame:WaitForChild("SubFrame2") :: Frame
	local spinsPill = rightSub2:WaitForChild("SpinsPill") :: Frame
	local spin1xBtn = rightSub2:WaitForChild("Spin1xBtn") :: TextButton
	local spin10xBtn = rightSub2:WaitForChild("Spin10xBtn") :: TextButton

	-- Decision Modal
	local decisionModal = overlayBackdrop:WaitForChild("DecisionModal") :: Frame
	local decPlate = decisionModal:WaitForChild("DecPlate") :: Frame
	local decLineageName = decPlate:WaitForChild("DecLineageName") :: TextLabel
	local decSummary = decPlate:WaitForChild("DecSummary") :: TextLabel
	local claimActiveBtn = decisionModal:WaitForChild("ClaimActiveBtn") :: TextButton
	local saveSlotBtn = decisionModal:WaitForChild("SaveSlotBtn") :: TextButton
	local discardBtn = decisionModal:WaitForChild("DiscardBtn") :: TextButton

	local RemoteEvents = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Network"):WaitForChild("RemoteEvents") :: any)
	local bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction") :: RemoteEvent

	local isOpen = false
	local cachedMaxSlots = 1
	local cachedSlots: { [number]: string } = {}

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
	wireButton(slotBtn1)
	wireButton(slotBtn2)
	wireButton(slotBtn3)
	wireButton(claimActiveBtn)
	wireButton(saveSlotBtn)
	wireButton(discardBtn)

	-- Open & Close Tweens
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

	local function closeModal()
		if not isOpen then return end
		isOpen = false
		playClick()

		decisionModal.Visible = false
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

	-- Proximity Prompt Hook
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

	-- Formatting Helpers
	local function updatePillCaption(pill: Frame, text: string)
		local cap = pill:FindFirstChild("PillCaption") :: TextLabel?
		if cap then cap.Text = string.upper(text) end
	end

	local function setButtonCaption(btn: TextButton, text: string)
		local cap = btn:FindFirstChild("CaptionLabel") :: TextLabel?
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
		if passives.GuardPierce then
			table.insert(parts, string.format("+%d%% PIERCE", math.round(passives.GuardPierce * 100)))
		end

		if #parts == 0 then return "Ancestral Resonance Active" end
		return table.concat(parts, " • ")
	end

	-- Slot Buttons Routing
	slotBtn1.Activated:Connect(function()
		playClick()
		bloodlineRemote:FireServer({ Action = "EquipSlot", SlotIndex = 1 })
	end)

	slotBtn2.Activated:Connect(function()
		playClick()
		if cachedMaxSlots >= 2 then
			bloodlineRemote:FireServer({ Action = "EquipSlot", SlotIndex = 2 })
		else
			bloodlineRemote:FireServer({ Action = "UnlockSlot", SlotIndex = 2 })
		end
	end)

	slotBtn3.Activated:Connect(function()
		playClick()
		if cachedMaxSlots >= 3 then
			bloodlineRemote:FireServer({ Action = "EquipSlot", SlotIndex = 3 })
		else
			bloodlineRemote:FireServer({ Action = "UnlockSlot", SlotIndex = 3 })
		end
	end)

	-- Decision Modal Actions
	claimActiveBtn.Activated:Connect(function()
		playClick()
		decisionModal.Visible = false
		bloodlineRemote:FireServer({ Action = "ClaimRoll", TargetSlot = 1 })
	end)

	saveSlotBtn.Activated:Connect(function()
		playClick()
		decisionModal.Visible = false
		local target = if cachedMaxSlots >= 2 then 2 else 1
		bloodlineRemote:FireServer({ Action = "ClaimRoll", TargetSlot = target })
	end)

	discardBtn.Activated:Connect(function()
		playClick()
		decisionModal.Visible = false
		bloodlineRemote:FireServer({ Action = "DiscardRoll" })
	end)

	-- Awakening & Exchange Buttons
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

	-- Server Network Listener
	bloodlineRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then return end

		if payload.Action == "StateUpdate" then
			lineageName.Text = string.upper(payload.DisplayName or payload.BloodlineId or "MORTAL MERIDIANS")
			applyTierPillStyle(payload.Rarity or "Common")
			passiveSummary.Text = formatPassivesText(payload.Passives)
			lineageDesc.Text = payload.Description or ""

			updatePillCaption(spinsPill, string.format("+%d AWAKEN BEADS", payload.RemainingSpins or 0))
			if payload.RemainingStones then
				updatePillCaption(stonesPill, string.format("+%d STONES", payload.RemainingStones))
			end

			-- Update Pity Trackers
			updatePillCaption(legPityPill, string.format("LEGEND: %d/30", payload.LegendaryPity or 0))
			updatePillCaption(mythPityPill, string.format("MYTHIC: %d/100", payload.MythicPity or 0))

			-- Update Meridian Slots Drawer
			cachedMaxSlots = payload.MaxSlots or 1
			cachedSlots = payload.Slots or {}

			slotLabel1.Text = string.format("SLOT 1 (ACTIVE): %s", string.upper(cachedSlots[1] or payload.DisplayName or "None"))
			setButtonCaption(slotBtn1, "ACTIVE")

			if cachedMaxSlots >= 2 then
				local s2Name = cachedSlots[2] or "Empty"
				slotLabel2.Text = string.format("SLOT 2: %s", string.upper(s2Name))
				setButtonCaption(slotBtn2, if s2Name ~= "Empty" then "EQUIP" else "UNLOCKED")
			else
				slotLabel2.Text = "SLOT 2: [LOCKED · REACH FOUNDATION]"
				setButtonCaption(slotBtn2, "UNLOCK")
			end

			if cachedMaxSlots >= 3 then
				local s3Name = cachedSlots[3] or "Empty"
				slotLabel3.Text = string.format("SLOT 3: %s", string.upper(s3Name))
				setButtonCaption(slotBtn3, if s3Name ~= "Empty" then "EQUIP" else "UNLOCKED")
			else
				slotLabel3.Text = "SLOT 3: [LOCKED · 25,000 STONES]"
				setButtonCaption(slotBtn3, "UNLOCK")
			end

		elseif payload.Action == "RollDecide" then
			-- Open Keep or Discard Modal
			playClick()
			decisionModal.Visible = true
			decLineageName.Text = string.upper(payload.DisplayName or payload.BloodlineId)
			decSummary.Text = formatPassivesText(payload.Passives)

			updatePillCaption(spinsPill, string.format("+%d AWAKEN BEADS", payload.RemainingSpins or 0))
			updatePillCaption(legPityPill, string.format("LEGEND: %d/30", payload.LegendaryPity or 0))
			updatePillCaption(mythPityPill, string.format("MYTHIC: %d/100", payload.MythicPity or 0))

		elseif payload.Action == "RollDiscarded" then
			decisionModal.Visible = false
			if payload.RemainingStones then
				updatePillCaption(stonesPill, string.format("+%d STONES", payload.RemainingStones))
			end

		elseif payload.Action == "ActionFailed" or payload.Action == "SpinFailed" or payload.Action == "ExchangeFailed" then
			warn("[BloodlineController] " .. tostring(payload.Message))
		end
	end)

	overlayBackdrop.Visible = false
	screenGui.Enabled = false
	print("[BloodlineController] Initialized with Meridian Vault Slots & Pity Engine.")
end

function BloodlineController.Start()
	BloodlineController.Init()
end

task.defer(function()
	BloodlineController.Init()
end)

return BloodlineController