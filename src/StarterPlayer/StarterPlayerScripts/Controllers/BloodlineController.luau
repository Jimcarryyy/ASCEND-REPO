--!strict
--[[
    BloodlineController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/BloodlineController.luau
    Client UI controller bound to MainHubGui.MenuBackdrop.PageContainer.Page_Bloodline:
    - Auto-syncs live slot data upon opening (Slot 2 shows real Nine Nether Sovereign)
    - DecisionModal integration (Equip Active, Save to Vault, Discard +100)
    - 1X and 10X Awakening Rituals with server roll response
    - Real-time Pity meters (Legendary 0/30 & Mythic 0/100) and Spirit Stones tribute
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local BloodlineConfig = require(ReplicatedStorage.Shared.Configs.BloodlineConfig)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

local BloodlineController = {}
BloodlineController.__index = BloodlineController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local bloodlineRemote: RemoteEvent

local page: Frame? = nil
local activeCard: Frame? = nil
local vaultCard: Frame? = nil
local pityCard: Frame? = nil
local altarCard: Frame? = nil
local decisionModal: Frame? = nil

local lineageNameLabel: TextLabel? = nil
local tierBadgeLabel: TextLabel? = nil
local statModifiersLabel: TextLabel? = nil
local passiveSummaryLabel: TextLabel? = nil
local descriptionLabel: TextLabel? = nil

local legendFill: Frame? = nil
local legendCountLabel: TextLabel? = nil
local mythicFill: Frame? = nil
local mythicCountLabel: TextLabel? = nil

local stonesLabel: TextLabel? = nil
local beadsLabel: TextLabel? = nil

local slotRows: { [number]: { Row: Frame, Label: TextLabel?, Btn: TextButton? } } = {}
local buttonConnections: { RBXScriptConnection } = {}
local lastSyncData: any = nil
local isInitialized = false

local PANEL_CLICK_SOUND_ID = (UIAssets.Audio and UIAssets.Audio.PanelClick) or "rbxassetid://138567614125924"
local function PlayPanelClickSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = PANEL_CLICK_SOUND_ID
	sound.Volume = 0.55
	sound.PlaybackSpeed = math.random(98, 102) / 100
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 1.2)
end

local function ClearButtonConnections()
	for _, conn in ipairs(buttonConnections) do
		conn:Disconnect()
	end
	table.clear(buttonConnections)
end

local function EnsureUI(): boolean
	if isInitialized and page and page.Parent then return true end

	bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction")

	local hub = playerGui:WaitForChild("MainHubGui", 10) :: ScreenGui?
	if not hub then return false end

	local backdrop = hub:WaitForChild("MenuBackdrop", 5) :: Frame?
	local pageContainer = backdrop and backdrop:WaitForChild("PageContainer", 5) :: Frame?
	page = pageContainer and (pageContainer:WaitForChild("Page_Bloodline", 5) :: Frame?)

	if not page then return false end

	local body = page:FindFirstChild("BodyContainer") :: Frame?
	if not body then return false end

	local leftCol = body:FindFirstChild("LeftColumn") :: Frame?
	local rightCol = body:FindFirstChild("RightColumn") :: Frame?
	decisionModal = page:FindFirstChild("DecisionModal", true) :: Frame?

	if not leftCol or not rightCol then return false end

	activeCard = leftCol:FindFirstChild("ActiveCard") :: Frame?
	vaultCard = leftCol:FindFirstChild("VaultCard") :: Frame?
	pityCard = rightCol:FindFirstChild("PityCard") :: Frame?
	altarCard = rightCol:FindFirstChild("AltarCard") :: Frame?

	if activeCard then
		tierBadgeLabel = activeCard:FindFirstChild("TierBadge", true) :: TextLabel?
		local plate = activeCard:FindFirstChild("ShowcasePlate") :: Frame?
		if plate then
			lineageNameLabel = plate:FindFirstChild("LineageName") :: TextLabel?
			statModifiersLabel = plate:FindFirstChild("StatModifiers") :: TextLabel?
			passiveSummaryLabel = plate:FindFirstChild("PassiveSummary") :: TextLabel?
		end
		descriptionLabel = activeCard:FindFirstChild("DescriptionLabel") :: TextLabel?
	end

	if pityCard then
		legendFill = pityCard:FindFirstChild("Fill", true) :: Frame?
		local legRow = pityCard:FindFirstChild("LegendaryRow")
		legendCountLabel = legRow and legRow:FindFirstChild("CountLabel", true) :: TextLabel?

		local mytRow = pityCard:FindFirstChild("MythicRow")
		mythicFill = mytRow and mytRow:FindFirstChild("Fill", true) :: Frame?
		mythicCountLabel = mytRow and mytRow:FindFirstChild("CountLabel", true) :: TextLabel?

		stonesLabel = pityCard:FindFirstChild("StonesLabel", true) :: TextLabel?
	end

	if altarCard then
		beadsLabel = altarCard:FindFirstChild("BeadsLabel", true) :: TextLabel?
	end

	-- Map Meridian Vault Slots
	table.clear(slotRows)
	if vaultCard then
		for idx = 1, 5 do
			local row = vaultCard:FindFirstChild("SlotRow_" .. idx) :: Frame?
			if row then
				local sLbl = row:FindFirstChild("SlotLabel") :: TextLabel?
				local sBtn = row:FindFirstChild("SlotActionBtn") :: TextButton?
				slotRows[idx] = { Row = row, Label = sLbl, Btn = sBtn }
			end
		end
	end

	-- Connect Actions (Strictly Once)
	ClearButtonConnections()

	if pityCard then
		local buy1 = pityCard:FindFirstChild("Buy1Btn") :: TextButton?
		if buy1 then
			local conn = buy1.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "ExchangeSpins", Amount = 1 })
			end)
			table.insert(buttonConnections, conn)
		end

		local buy10 = pityCard:FindFirstChild("Buy10Btn") :: TextButton?
		if buy10 then
			local conn = buy10.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "ExchangeSpins", Amount = 10 })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	if altarCard then
		local spin1 = altarCard:FindFirstChild("Spin1xBtn") :: TextButton?
		if spin1 then
			local conn = spin1.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "Spin" })
			end)
			table.insert(buttonConnections, conn)
		end

		local spin10 = altarCard:FindFirstChild("Spin10xBtn") :: TextButton?
		if spin10 then
			local conn = spin10.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "Spin10x" })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	for idx, sData in pairs(slotRows) do
		if sData.Btn then
			local conn = sData.Btn.Activated:Connect(function()
				PlayPanelClickSFX()
				local maxSlots = (lastSyncData and (lastSyncData.MaxSlots or (lastSyncData.Data and lastSyncData.Data.MaxSlots))) or player:GetAttribute("MaxBloodlineSlots") or 2
				if idx > maxSlots then
					bloodlineRemote:FireServer({ Action = "UnlockSlot", SlotIndex = idx })
				else
					bloodlineRemote:FireServer({ Action = "EquipSlot", SlotIndex = idx })
				end
			end)
			table.insert(buttonConnections, conn)
		end
	end

	-- Wire DecisionModal Action Buttons
	if decisionModal then
		local card = decisionModal:FindFirstChild("ModalCard") or decisionModal
		local claimActiveBtn = card:FindFirstChild("ClaimActiveBtn", true) :: TextButton?
		local saveSlotBtn = card:FindFirstChild("SaveSlotBtn", true) :: TextButton?
		local discardBtn = card:FindFirstChild("DiscardBtn", true) :: TextButton?

		if claimActiveBtn then
			local conn = claimActiveBtn.Activated:Connect(function()
				PlayPanelClickSFX()
				decisionModal.Visible = false
				bloodlineRemote:FireServer({ Action = "ClaimRoll", TargetSlot = 1 })
			end)
			table.insert(buttonConnections, conn)
		end

		if saveSlotBtn then
			local conn = saveSlotBtn.Activated:Connect(function()
				PlayPanelClickSFX()
				decisionModal.Visible = false
				local slots = (lastSyncData and lastSyncData.Slots) or {}
				local targetSlot = 2
				for i = 1, 3 do
					if not slots[i] and not slots[tostring(i)] then
						targetSlot = i
						break
					end
				end
				bloodlineRemote:FireServer({ Action = "ClaimRoll", TargetSlot = targetSlot })
			end)
			table.insert(buttonConnections, conn)
		end

		if discardBtn then
			local conn = discardBtn.Activated:Connect(function()
				PlayPanelClickSFX()
				decisionModal.Visible = false
				bloodlineRemote:FireServer({ Action = "DiscardRoll" })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	isInitialized = true
	return true
end

function BloodlineController.Render()
	if not EnsureUI() or not page then return end

	-- 1. Active Lineage Card
	local activeId = (lastSyncData and (lastSyncData.BloodlineId or lastSyncData.Bloodline)) or player:GetAttribute("Bloodline") or "MortalSwordBone"
	local def = BloodlineConfig.GetBloodline(activeId) or {
		Name = "Mortal Sword Bone",
		Tier = "Mortal",
		Description = "Standard mortal meridian alignment. No elemental Dao affinities active.",
	}

	local TIER_COLORS = {
		Mortal = Color3.fromRGB(140, 140, 150),
		Earth = Color3.fromRGB(40, 140, 220),
		Heaven = Color3.fromRGB(160, 60, 220),
		Legendary = Color3.fromRGB(240, 160, 20),
		Mythic = Color3.fromRGB(230, 30, 70),
	}

	local tierColor = TIER_COLORS[def.Tier] or TIER_COLORS.Mortal

	if tierBadgeLabel then
		tierBadgeLabel.Text = string.upper(def.Tier)
		tierBadgeLabel.TextColor3 = tierColor
	end

	if lineageNameLabel then
		lineageNameLabel.Text = string.upper(def.Name)
		lineageNameLabel.TextColor3 = tierColor
	end

	if statModifiersLabel then
		local mods = {}
		if def.StatMultipliers then
			if def.StatMultipliers.Damage and def.StatMultipliers.Damage > 1 then
				table.insert(mods, string.format("+%d%% Damage", math.round((def.StatMultipliers.Damage - 1) * 100)))
			end
			if def.StatMultipliers.QiMax and def.StatMultipliers.QiMax > 1 then
				table.insert(mods, string.format("+%d%% Max Qi", math.round((def.StatMultipliers.QiMax - 1) * 100)))
			end
			if def.StatMultipliers.Speed and def.StatMultipliers.Speed > 1 then
				table.insert(mods, string.format("+%d%% Speed", math.round((def.StatMultipliers.Speed - 1) * 100)))
			end
		end
		statModifiersLabel.Text = if #mods > 0 then table.concat(mods, " • ") else "Base Attributes • Standard Dao Flow"
	end

	if passiveSummaryLabel then
		local pList = def.PassiveEffects or {}
		passiveSummaryLabel.Text = if #pList > 0 then "Passive: " .. table.concat(pList, ", ") else "No Passive Resonances"
	end

	if descriptionLabel then
		descriptionLabel.Text = def.Description or "Channel celestial intent through the altar to awaken sovereign bloodlines."
	end

	-- 2. Pity Meters
	local pity = (lastSyncData and lastSyncData.Pity) or {}
	local legPity = pity.SpinsSinceLegendary or player:GetAttribute("LegendaryPity") or 0
	local mytPity = pity.SpinsSinceMythic or player:GetAttribute("MythicPity") or 0

	if legendFill and legendCountLabel then
		local pct = math.clamp(legPity / 30, 0, 1)
		legendFill.Size = UDim2.new(pct, 0, 1, 0)
		legendCountLabel.Text = string.format("%d/30", legPity)
	end

	if mythicFill and mythicCountLabel then
		local pct = math.clamp(mytPity / 100, 0, 1)
		mythicFill.Size = UDim2.new(pct, 0, 1, 0)
		mythicCountLabel.Text = string.format("%d/100", mytPity)
	end

	-- 3. Live Currencies
	local stones = (lastSyncData and lastSyncData.SpiritStones) or player:GetAttribute("SpiritStones") or 0
	local spins = (lastSyncData and lastSyncData.Spins) or player:GetAttribute("BloodlineSpins") or 0

	if stonesLabel then stonesLabel.Text = string.format("Spirit Stones: %d", stones) end
	if beadsLabel then beadsLabel.Text = string.format("BEADS: %d", spins) end

	-- 4. Meridian Vault Slots (Renders Real Stored Bloodlines)
	local slots = (lastSyncData and lastSyncData.Slots) or {}

	local maxSlots = (lastSyncData and (lastSyncData.MaxSlots or (lastSyncData.Data and lastSyncData.Data.MaxSlots))) or player:GetAttribute("MaxBloodlineSlots") or 2

	for idx = 1, 5 do
		local sData = slotRows[idx]
		if sData and sData.Label and sData.Btn then
			if idx > maxSlots then
				-- Locked Slot: Requires Robux Unlock
				sData.Label.Text = string.format("SLOT %d: [LOCKED] Ancestral Meridian", idx)
				sData.Label.TextColor3 = Color3.fromRGB(150, 70, 70)

				sData.Btn.Text = "UNLOCK (ROBUX)"
				sData.Btn.BackgroundColor3 = Color3.fromRGB(55, 25, 25)
				sData.Btn.TextColor3 = Color3.fromRGB(240, 180, 180)
				sData.Btn.AutoButtonColor = true
			else
				-- Unlocked Slot (Slots 1 & 2 or purchased)
				local storedId = slots[idx] or slots[tostring(idx)]

				if idx == 1 and (not storedId or storedId == "") then
					storedId = activeId
				end

				if storedId and storedId ~= "" then
					local sDef = BloodlineConfig.GetBloodline(storedId)
					local name = sDef and sDef.Name or storedId
					local sTier = sDef and sDef.Tier or "Common"
					local isEquipped = (storedId == activeId)

					sData.Label.Text = string.format("SLOT %d: [%s] %s", idx, string.upper(sTier), name)
					sData.Label.TextColor3 = isEquipped and Color3.fromRGB(240, 210, 120) or Color3.fromRGB(200, 195, 185)

					if isEquipped then
						sData.Btn.Text = "EQUIPPED"
						sData.Btn.BackgroundColor3 = Color3.fromRGB(35, 60, 35)
						sData.Btn.TextColor3 = Color3.fromRGB(140, 230, 140)
						sData.Btn.AutoButtonColor = false
					else
						sData.Btn.Text = "EQUIP"
						sData.Btn.BackgroundColor3 = Color3.fromRGB(30, 45, 65)
						sData.Btn.TextColor3 = Color3.fromRGB(240, 210, 120)
						sData.Btn.AutoButtonColor = true
					end
				else
					sData.Label.Text = string.format("SLOT %d: [Empty Meridian]", idx)
					sData.Label.TextColor3 = Color3.fromRGB(130, 125, 120)

					sData.Btn.Text = "STORE ACTIVE"
					sData.Btn.BackgroundColor3 = Color3.fromRGB(45, 38, 20)
					sData.Btn.TextColor3 = Color3.fromRGB(240, 210, 120)
					sData.Btn.AutoButtonColor = true
				end
			end
		end
	end
end

function BloodlineController.ShowDecisionModal(bloodlineId: string)
	if not EnsureUI() or not decisionModal then return end

	local def = BloodlineConfig.GetBloodline(bloodlineId)
	if not def then return end

	local card = decisionModal:FindFirstChild("ModalCard") or decisionModal
	local viewport = card:FindFirstChild("RouletteViewport") :: Frame?
	local track = viewport and viewport:FindFirstChild("CardsTrack") :: Frame?
	local decTitle = card:FindFirstChild("DecTitle") :: TextLabel?
	local plate = card:FindFirstChild("DecPlate", true) :: Frame?
	local claimBtn = card:FindFirstChild("ClaimActiveBtn", true) :: TextButton?
	local saveBtn = card:FindFirstChild("SaveSlotBtn", true) :: TextButton?
	local discardBtn = card:FindFirstChild("DiscardBtn", true) :: TextButton?

	local TIER_COLORS = {
		Mortal = Color3.fromRGB(150, 150, 160),
		Common = Color3.fromRGB(150, 150, 160),
		Earth = Color3.fromRGB(45, 145, 230),
		Rare = Color3.fromRGB(45, 145, 230),
		Heaven = Color3.fromRGB(165, 75, 235),
		Legendary = Color3.fromRGB(245, 175, 30),
		Legend = Color3.fromRGB(245, 175, 30),
		Mythic = Color3.fromRGB(235, 40, 80),
	}

	local TIER_BG_COLORS = {
		Common = Color3.fromRGB(22, 22, 28),
		Mortal = Color3.fromRGB(22, 22, 28),
		Rare = Color3.fromRGB(16, 26, 42),
		Earth = Color3.fromRGB(16, 26, 42),
		Legendary = Color3.fromRGB(36, 28, 14),
		Legend = Color3.fromRGB(36, 28, 14),
		Mythic = Color3.fromRGB(38, 14, 20),
	}

	-- Initial Spin State Setup
	decisionModal.Visible = true
	if decTitle then decTitle.Text = "COMMUNING WITH ANCESTRAL MERIDIANS..." end
	if plate then plate.Visible = false end
	if claimBtn then claimBtn.Visible = false end
	if saveBtn then saveBtn.Visible = false end
	if discardBtn then discardBtn.Visible = false end

	-- Animate Modal Entrance
	card.Size = UDim2.new(0, 520, 0, 390)
	TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 560, 0, 430)
	}):Play()

	if not track or not viewport then
		if plate then plate.Visible = true end
		if claimBtn then claimBtn.Visible = true end
		if saveBtn then saveBtn.Visible = true end
		if discardBtn then discardBtn.Visible = true end
		return
	end

	-- Clear Previous Reel Cards
	for _, child in ipairs(track:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end

	-- Flatten the BloodlineConfig dictionary into an indexed array
	local allRaw = BloodlineConfig.GetAllBloodlines and BloodlineConfig.GetAllBloodlines() or {}
	local bloodlinePool = {}
	local highTierPool = {}

	for _, bDef in pairs(allRaw) do
		if typeof(bDef) == "table" and bDef.Name then
			table.insert(bloodlinePool, bDef)
			if bDef.Tier == "Mythic" or bDef.Tier == "Legendary" or bDef.Tier == "Legend" then
				table.insert(highTierPool, bDef)
			end
		end
	end

	if #bloodlinePool == 0 then
		table.insert(bloodlinePool, def)
	end
	if #highTierPool == 0 then
		table.insert(highTierPool, def)
	end

	-- Build 35 Reel Cards with Winner at Index 28
	local totalCards = 35
	local targetIndex = 28
	local cardWidth = 88
	local cardSpacing = 8
	local step = cardWidth + cardSpacing
	local winnerCard: Frame? = nil

	for i = 1, totalCards do
		local cDef = nil
		if i == targetIndex then
			-- The True Server Outcome
			cDef = def
		elseif i == (targetIndex - 1) and math.random() < 0.65 then
			-- 65% Near-Miss Teaser: High-Tier Mythic/Legend right before the winner!
			cDef = highTierPool[math.random(1, #highTierPool)]
		else
			-- Weighted organic random pull from all 12 bloodlines
			cDef = bloodlinePool[math.random(1, #bloodlinePool)]
		end

		if not cDef then cDef = def end

		local tierName = cDef.Tier or "Common"
		local tColor = TIER_COLORS[tierName] or TIER_COLORS.Common
		local bgColor = TIER_BG_COLORS[tierName] or TIER_BG_COLORS.Common

		local cFrame = Instance.new("Frame")
		cFrame.Name = "Card_" .. i
		cFrame.Position = UDim2.new(0, (i - 1) * step, 0, 5)
		cFrame.Size = UDim2.new(0, cardWidth, 0, 96)
		cFrame.BackgroundColor3 = bgColor
		cFrame.BorderSizePixel = 0
		cFrame.ZIndex = 35
		cFrame.Parent = track

		local cStroke = Instance.new("UIStroke")
		cStroke.Name = "Stroke"
		cStroke.Color = tColor
		cStroke.Thickness = (i == targetIndex) and 2.2 or 1.2
		cStroke.Parent = cFrame

		local tBadge = Instance.new("TextLabel")
		tBadge.Size = UDim2.new(1, 0, 0, 16)
		tBadge.Position = UDim2.new(0, 0, 0, 4)
		tBadge.BackgroundTransparency = 1
		tBadge.Text = string.upper(tierName)
		tBadge.TextColor3 = tColor
		tBadge.Font = Enum.Font.GothamBold
		tBadge.TextSize = 10
		tBadge.ZIndex = 36
		tBadge.Parent = cFrame

		local nLabel = Instance.new("TextLabel")
		nLabel.Size = UDim2.new(1, -8, 0, 68)
		nLabel.Position = UDim2.new(0, 4, 0, 22)
		nLabel.BackgroundTransparency = 1
		nLabel.Text = string.upper(cDef.Name or "UNKNOWN")
		nLabel.TextColor3 = (i == targetIndex) and Color3.fromRGB(255, 245, 195) or Color3.fromRGB(225, 220, 210)
		nLabel.Font = Enum.Font.GothamSemibold
		nLabel.TextScaled = true
		nLabel.ZIndex = 36
		nLabel.Parent = cFrame

		if i == targetIndex then
			winnerCard = cFrame
		end
	end

	-- Center Math & Exponential Deceleration Tween
	local centerViewportX = viewport.AbsoluteSize.X > 0 and (viewport.AbsoluteSize.X / 2) or ((560 - 32) / 2)
	local winnerCardCenterX = (targetIndex - 1) * step + (cardWidth / 2)
	local targetTrackX = centerViewportX - winnerCardCenterX + math.random(-6, 6)

	track.Position = UDim2.new(0, 0, 0, 0)

	-- Rapid sound ticks that decelerate alongside the wheel
	local spinDuration = 3.2
	task.spawn(function()
		local elapsed = 0
		while elapsed < (spinDuration - 0.25) do
			PlayPanelClickSFX()
			local progress = elapsed / spinDuration
			local interval = 0.035 + (progress ^ 2.2) * 0.35
			task.wait(interval)
			elapsed += interval
		end
	end)

	local spinTween = TweenService:Create(
		track,
		TweenInfo.new(spinDuration, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0, targetTrackX, 0, 0) }
	)

	spinTween.Completed:Connect(function()
		PlayPanelClickSFX()

		-- Winner Impact Flash
		if winnerCard then
			local wStroke = winnerCard:FindFirstChild("Stroke") :: UIStroke?
			if wStroke then
				wStroke.Color = Color3.fromRGB(255, 235, 120)
				wStroke.Thickness = 3.5
			end
			TweenService:Create(winnerCard, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 1, true), {
				Size = UDim2.new(0, cardWidth + 4, 0, 100),
				Position = winnerCard.Position - UDim2.new(0, 2, 0, 2)
			}):Play()
		end

		if decTitle then
			decTitle.Text = "ANCESTRAL LINEAGE AWAKENED!"
		end

		-- Populate DecPlate Text
		if plate then
			local lName = plate:FindFirstChild("LineageName") or plate:FindFirstChildWhichIsA("TextLabel") :: TextLabel?
			if lName then
				lName.Text = string.upper(def.Name)
				lName.TextColor3 = TIER_COLORS[def.Tier] or Color3.fromRGB(240, 210, 120)
			end

			local sLbl = (plate:FindFirstChild("DecSummary", true) or plate:FindFirstChild("StatModifiers", true)) :: TextLabel?
			if sLbl then
				local mods = {}
				if def.StatMultipliers then
					if def.StatMultipliers.Damage then table.insert(mods, string.format("+%d%% Damage", math.round((def.StatMultipliers.Damage - 1) * 100))) end
					if def.StatMultipliers.QiMax then table.insert(mods, string.format("+%d%% Max Qi", math.round((def.StatMultipliers.QiMax - 1) * 100))) end
				end
				sLbl.Text = table.concat(mods, " • ") .. "\n" .. (def.Description or "")
			end

			plate.Visible = true
		end

		-- Reveal Buttons with punchy Back-out scale tween
		for _, b in ipairs({claimBtn, saveBtn, discardBtn}) do
			if b then
				b.Visible = true
				b.Size = UDim2.new(0.3, 0, 0, 0)
				TweenService:Create(b, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(0.3, 0, 0, 42)
				}):Play()
			end
		end
	end)

	spinTween:Play()
end

function BloodlineController.Open()
	if not EnsureUI() or not page then return end
	page.Visible = true
	if bloodlineRemote then
		bloodlineRemote:FireServer({ Action = "GetState" })
	end
	BloodlineController.Render()
end

function BloodlineController.Close()
	if not page then return end
	page.Visible = false
	if decisionModal then decisionModal.Visible = false end
end

function BloodlineController.Init()
	bloodlineRemote = RemoteEvents.GetRemote("BloodlineAction")

	bloodlineRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		local action = payload.Action

		if (action == "RollDecide" or action == "BloodlineAwakened" or action == "RollResult") and payload.BloodlineId then
			BloodlineController.ShowDecisionModal(payload.BloodlineId)
		elseif action == "StateUpdate" or action == "SyncBloodlineData" or action == "TributeSuccess" or action == "SlotUpdated" or action == "RollDiscarded" then
			lastSyncData = payload
			BloodlineController.Render()
		end
	end)

	player:GetAttributeChangedSignal("Bloodline"):Connect(BloodlineController.Render)
	player:GetAttributeChangedSignal("BloodlineSpins"):Connect(BloodlineController.Render)
	player:GetAttributeChangedSignal("LegendaryPity"):Connect(BloodlineController.Render)
	player:GetAttributeChangedSignal("MythicPity"):Connect(BloodlineController.Render)
	player:GetAttributeChangedSignal("SpiritStones"):Connect(BloodlineController.Render)

	print("[ASCEND] BloodlineController Initialized & Connected to MainHub.")
end

return BloodlineController