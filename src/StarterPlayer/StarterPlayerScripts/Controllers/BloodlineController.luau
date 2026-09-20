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
		for idx = 1, 3 do
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
				bloodlineRemote:FireServer({ Action = "BuySpins", Amount = 1 })
			end)
			table.insert(buttonConnections, conn)
		end

		local buy10 = pityCard:FindFirstChild("Buy10Btn") :: TextButton?
		if buy10 then
			local conn = buy10.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "BuySpins", Amount = 10 })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	if altarCard then
		local spin1 = altarCard:FindFirstChild("Spin1xBtn") :: TextButton?
		if spin1 then
			local conn = spin1.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "Roll", Count = 1 })
			end)
			table.insert(buttonConnections, conn)
		end

		local spin10 = altarCard:FindFirstChild("Spin10xBtn") :: TextButton?
		if spin10 then
			local conn = spin10.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "Roll", Count = 10 })
			end)
			table.insert(buttonConnections, conn)
		end
	end

	for idx, sData in pairs(slotRows) do
		if sData.Btn then
			local conn = sData.Btn.Activated:Connect(function()
				PlayPanelClickSFX()
				bloodlineRemote:FireServer({ Action = "EquipSlot", SlotIndex = idx })
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
				bloodlineRemote:FireServer({ Action = "ClaimActive" })
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
				bloodlineRemote:FireServer({ Action = "SaveToSlot", SlotIndex = targetSlot })
			end)
			table.insert(buttonConnections, conn)
		end

		if discardBtn then
			local conn = discardBtn.Activated:Connect(function()
				PlayPanelClickSFX()
				decisionModal.Visible = false
				bloodlineRemote:FireServer({ Action = "Discard" })
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
	local activeId = (lastSyncData and lastSyncData.Bloodline) or player:GetAttribute("Bloodline") or "MortalSwordBone"
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

	for idx = 1, 3 do
		local sData = slotRows[idx]
		if sData and sData.Label and sData.Btn then
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

function BloodlineController.ShowDecisionModal(bloodlineId: string)
	if not EnsureUI() or not decisionModal then return end

	local def = BloodlineConfig.GetBloodline(bloodlineId)
	if not def then return end

	local card = decisionModal:FindFirstChild("ModalCard") or decisionModal
	local plate = card:FindFirstChild("DecPlate", true)

	local lName = plate and (plate:FindFirstChild("LineageName") or plate:FindFirstChildWhichIsA("TextLabel")) :: TextLabel?
	if lName then
		lName.Text = string.upper(def.Name)
		local TIER_COLORS = {
			Mortal = Color3.fromRGB(140, 140, 150),
			Earth = Color3.fromRGB(40, 140, 220),
			Heaven = Color3.fromRGB(160, 60, 220),
			Legendary = Color3.fromRGB(240, 160, 20),
			Mythic = Color3.fromRGB(230, 30, 70),
		}
		lName.TextColor3 = TIER_COLORS[def.Tier] or Color3.fromRGB(240, 210, 120)
	end

	local sLbl = plate and plate:FindFirstChild("StatModifiers", true) :: TextLabel?
	if sLbl then
		local mods = {}
		if def.StatMultipliers then
			if def.StatMultipliers.Damage then table.insert(mods, string.format("+%d%% Damage", math.round((def.StatMultipliers.Damage - 1) * 100))) end
			if def.StatMultipliers.QiMax then table.insert(mods, string.format("+%d%% Max Qi", math.round((def.StatMultipliers.QiMax - 1) * 100))) end
		end
		sLbl.Text = table.concat(mods, " • ") .. "\n" .. (def.Description or "")
	end

	decisionModal.Visible = true

	local mCard = decisionModal:FindFirstChild("ModalCard") :: Frame?
	if mCard then
		mCard.Size = UDim2.new(0, 480, 0, 280)
		TweenService:Create(mCard, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 520, 0, 310)
		}):Play()
	end
end

function BloodlineController.Open()
	if not EnsureUI() or not page then return end
	page.Visible = true
	if bloodlineRemote then
		bloodlineRemote:FireServer({ Action = "RequestSync" })
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

		if (action == "BloodlineAwakened" or action == "RollResult") and payload.BloodlineId then
			BloodlineController.ShowDecisionModal(payload.BloodlineId)
		elseif action == "SyncBloodlineData" or action == "TributeSuccess" or action == "SlotUpdated" then
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