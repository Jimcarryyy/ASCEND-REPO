--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Directly bound to StarterGui.MasterHUDGui:
    - BottomCenterItemHotbar (Slots 1-5): Clean Steel-Grey Palette
    - BottomCenterCooldownRow: Dynamic status popups above 1-5 hotbar with seconds countdown
    - BottomRightActionGuide:
        * Collapsible RowsContainer via ToggleGuideButton or Keybind H
        * Interactive Combat Action Rows
    - Bottom-Left Vitals Container (HP, Qi, Sword Intent)
    - TopRight Currency (Live CP & Spirit Stones)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local SkillBarController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local INTENT_BAR_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INTENT_DECAY_DELAY = 2.5
local INTENT_DECAY_RATE = 8.0

-- MasterHUDGui References
local masterGui: ScreenGui?
local vitalsContainer: Frame?
local hpFill: Frame?
local hpTextLabel: TextLabel?
local qiFill: Frame?
local qiTextLabel: TextLabel?
local intentFill: Frame?
local intentTextLabel: TextLabel?

local currencyFrame: Frame?
local cpLabel: TextLabel?
local spiritStoneLabel: TextLabel?

local itemHotbar: Frame?
local actionGuide: Frame?
local guideRowsContainer: Frame?
local guideToggleButton: TextButton?
local guideToggleLabel: TextLabel?
local isGuideCollapsed: boolean = false

-- Cooldown Status Popups
local cooldownRow: Frame?
local cooldownTemplate: Frame?
local activeCooldownBoxes: { [string]: Frame } = {}
local activeCooldownThreads: { [string]: thread } = {}

local combatActionRemote: RemoteEvent
local inventoryActionRemote: RemoteEvent
local sectRemote: RemoteEvent? = nil

local currentSwordIntent = 0
local lastHitLandedTime = os.clock()

local hotbarSlotButtons: { [number]: ImageButton } = {}
local hotbarCountLabels: { [number]: TextLabel } = {}

local characterConnections: { RBXScriptConnection } = {}

local SKILL_META = {
	["Shift"] = { Key = "Shift", Symbol = "⚡", Order = 1 },
	["Dash"]  = { Key = "Shift", Symbol = "⚡", Order = 1 },
	["T"]     = { Key = "T",     Symbol = "🛡", Order = 2 },
	["Block"] = { Key = "T",     Symbol = "🛡", Order = 2 },
	["Q"]     = { Key = "Q",     Symbol = "🌀", Order = 3 },
	["E"]     = { Key = "E",     Symbol = "➔", Order = 4 },
	["F"]     = { Key = "F",     Symbol = "▼", Order = 5 },
	["B"]     = { Key = "B",     Symbol = "✦", Order = 6 },
	["Breakthrough"] = { Key = "B", Symbol = "✦", Order = 6 },
	["M1"]    = { Key = "M1",    Symbol = "⚔", Order = 7 },
}

local function GetInputController(): any
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			return require(inputCtrl)
		end
	end
	return nil
end

local function FormatNum(num: number): string
	if num >= 1000000 then
		return string.format("%.2fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function FormatCurrency(num: number): string
	local formatted = tostring(math.floor(num))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

local function GetCurrentCP(): number
	local char = LocalPlayer.Character
	local val = (char and (char:GetAttribute("ContributionPoints") or char:GetAttribute("SectContribution") or char:GetAttribute("CP")))
		or LocalPlayer:GetAttribute("ContributionPoints")
		or LocalPlayer:GetAttribute("SectContribution")
		or LocalPlayer:GetAttribute("CP")
	return tonumber(val) or 0
end

local function GetCurrentStones(): number
	local char = LocalPlayer.Character
	local val = (char and (char:GetAttribute("SpiritStones") or char:GetAttribute("Stones") or char:GetAttribute("Money")))
		or LocalPlayer:GetAttribute("SpiritStones")
		or LocalPlayer:GetAttribute("Stones")
		or LocalPlayer:GetAttribute("Money")
	return tonumber(val) or 0
end

function SkillBarController.ToggleActionGuide()
	if not guideRowsContainer then return end
	isGuideCollapsed = not isGuideCollapsed

	guideRowsContainer.Visible = not isGuideCollapsed
	local text = isGuideCollapsed and "⌨ [SHOW]" or "⌨ [KEYS]"

	if guideToggleLabel then
		guideToggleLabel.Text = text
	elseif guideToggleButton then
		guideToggleButton.Text = text
	end
end

function SkillBarController.UseHotbarSlotByType(slotType: string)
	local ic = GetInputController()
	if slotType == "Sword" or slotType == "1" then
		if ic and ic.ToggleWeaponSheath then ic.ToggleWeaponSheath() end
	elseif slotType == "Flight" or slotType == "2" then
		if ic and ic.ToggleFlight then ic.ToggleFlight() end
	elseif slotType == "Heal" or slotType == "3" then
		inventoryActionRemote:FireServer({ Action = "UseItem", SlotIndex = 2 })
	elseif slotType == "Qi" or slotType == "4" then
		inventoryActionRemote:FireServer({ Action = "UseItem", SlotIndex = 3 })
	elseif slotType == "Custom" or slotType == "5" then
		inventoryActionRemote:FireServer({ Action = "UseItem", SlotIndex = 4 })
	end
end

local function BindSkillButton(btn: GuiButton, rawName: string)
	local cleanKey = rawName:gsub("_SKILL$", ""):gsub("^Row_", "")

	if cleanKey == "M1" or cleanKey == "Attack" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerM1 then ic.TriggerM1() end
		end)
	elseif cleanKey == "Shift" or cleanKey == "Dash" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerDash then ic.TriggerDash() end
		end)
	elseif cleanKey == "T" or cleanKey == "Shield" or cleanKey == "Block" then
		btn.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				local ic = GetInputController()
				if ic and ic.StartBlock then ic.StartBlock() end
			end
		end)
		btn.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				local ic = GetInputController()
				if ic and ic.StopBlock then ic.StopBlock() end
			end
		end)
	elseif cleanKey == "Q" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("Q") end
		end)
	elseif cleanKey == "E" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("E") end
		end)
	elseif cleanKey == "F" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("F") end
		end)
	elseif cleanKey == "C" or cleanKey == "Meditate" then
		btn.Activated:Connect(function()
			combatActionRemote:FireServer({ ToggleMeditation = true })
		end)
	elseif cleanKey == "B" or cleanKey == "Breakthrough" then
		btn.Activated:Connect(function()
			combatActionRemote:FireServer({ RequestBreakthrough = true })
		end)
	end
end

function SkillBarController.HookStudioUI()
	masterGui = (PlayerGui:FindFirstChild("MasterHUDGui") or PlayerGui:WaitForChild("MasterHUDGui", 8)) :: ScreenGui?
	if not masterGui then return end
	masterGui.DisplayOrder = 10
	masterGui.ResetOnSpawn = false

	table.clear(hotbarSlotButtons)
	table.clear(hotbarCountLabels)

	-- 1. Hook Cooldown Row & Template
	cooldownRow = masterGui:FindFirstChild("BottomCenterCooldownRow") :: Frame?
	if cooldownRow then
		cooldownTemplate = cooldownRow:FindFirstChild("CooldownTemplate") :: Frame?
		if cooldownTemplate then
			cooldownTemplate.Visible = false
		end
	end

	-- 2. Hook Item Hotbar (Slots 1-5)
	itemHotbar = masterGui:FindFirstChild("BottomCenterItemHotbar") :: Frame?
	if itemHotbar then
		for slotIdx = 1, 5 do
			local slotBtn = itemHotbar:FindFirstChild("Slot_" .. slotIdx, true) :: ImageButton?
			if not slotBtn then
				for _, child in ipairs(itemHotbar:GetChildren()) do
					if child:IsA("ImageButton") and child.Name:match("^Slot_" .. slotIdx) then
						slotBtn = child
						break
					end
				end
			end

			if slotBtn then
				hotbarSlotButtons[slotIdx] = slotBtn
				local countLbl = slotBtn:FindFirstChild("CountLabel") :: TextLabel?
				if countLbl then hotbarCountLabels[slotIdx] = countLbl end

				slotBtn.Activated:Connect(function()
					SkillBarController.UseHotbarSlotByType(tostring(slotIdx))
				end)
			end
		end
	end

	-- 3. Hook Action Guide & Toggle Button
	actionGuide = masterGui:FindFirstChild("BottomRightActionGuide") :: Frame?
	if actionGuide then
		guideRowsContainer = actionGuide:FindFirstChild("RowsContainer") :: Frame?
		guideToggleButton = actionGuide:FindFirstChild("ToggleGuideButton") :: TextButton?
		guideToggleLabel = guideToggleButton and guideToggleButton:FindFirstChild("BtnLabel") :: TextLabel?

		if guideToggleButton then
			guideToggleButton.Activated:Connect(SkillBarController.ToggleActionGuide)
			guideToggleButton.MouseButton1Click:Connect(SkillBarController.ToggleActionGuide)
		end

		local container = guideRowsContainer or actionGuide
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Frame") and child.Name:match("^Row_") then
				local cleanKey = child.Name:gsub("^Row_", "")
				local clickTrigger = child:FindFirstChildWhichIsA("GuiButton")
				if not clickTrigger then
					local btn = Instance.new("TextButton")
					btn.Name = "RowTriggerBtn"
					btn.Size = UDim2.new(1, 0, 1, 0)
					btn.BackgroundTransparency = 1
					btn.Text = ""
					btn.ZIndex = 15
					btn.Parent = child
					clickTrigger = btn
				end
				if clickTrigger then
					BindSkillButton(clickTrigger, cleanKey)
				end
			end
		end
	end

	-- 4. Hook Vitals
	vitalsContainer = masterGui:FindFirstChild("VitalsContainer") :: Frame?
	if vitalsContainer then
		local hpFrame = vitalsContainer:FindFirstChild("HPBarFrame")
		if hpFrame then
			hpFill = hpFrame:FindFirstChild("BarFill", true) :: Frame?
			hpTextLabel = (hpFrame:FindFirstChild("ValueLabel", true) or hpFrame:FindFirstChild("TextLabel", true)) :: TextLabel?
		end

		local qiFrame = vitalsContainer:FindFirstChild("QIBarFrame")
		if qiFrame then
			qiFill = qiFrame:FindFirstChild("BarFill", true) :: Frame?
			qiTextLabel = (qiFrame:FindFirstChild("ValueLabel", true) or qiFrame:FindFirstChild("TextLabel", true)) :: TextLabel?
		end

		local intentFrame = vitalsContainer:FindFirstChild("IntentBarFrame")
		if intentFrame then
			intentFill = intentFrame:FindFirstChild("BarFill", true) :: Frame?
			intentTextLabel = (intentFrame:FindFirstChild("ValueLabel", true) or intentFrame:FindFirstChild("TextLabel", true)) :: TextLabel?
		end
	end

	-- 5. Hook Currencies
	currencyFrame = masterGui:FindFirstChild("TopRightCurrencyFrame") :: Frame?
	if currencyFrame then
		local cpFrame = currencyFrame:FindFirstChild("CPFrame")
		if cpFrame then cpLabel = cpFrame:FindFirstChildOfClass("TextLabel") end

		local stoneFrame = currencyFrame:FindFirstChild("SpiritStoneFrame")
		if stoneFrame then spiritStoneLabel = stoneFrame:FindFirstChildOfClass("TextLabel") end
	end
end

function SkillBarController.TriggerCooldown(skillKey: string, duration: number?)
	local cd = if duration and type(duration) == "number" and duration > 0 then duration else 1.5

	if not cooldownRow or not cooldownTemplate then return end

	local normKey = skillKey
	if normKey == "Dash" then normKey = "Shift"
	elseif normKey == "Block" then normKey = "T"
	elseif normKey == "Breakthrough" then normKey = "B"
	end

	if activeCooldownThreads[normKey] then
		task.cancel(activeCooldownThreads[normKey])
		activeCooldownThreads[normKey] = nil
	end

	local box = activeCooldownBoxes[normKey]
	if not box or not box.Parent then
		box = cooldownTemplate:Clone()
		box.Name = "CD_" .. normKey
		box.Visible = true

		local meta = SKILL_META[normKey] or { Key = normKey, Symbol = "⚔", Order = 10 }
		box.LayoutOrder = meta.Order

		local kb = box:FindFirstChild("KeyBadge") :: Frame?
		local kt = kb and kb:FindFirstChild("KeyText") :: TextLabel?
		if kt then kt.Text = meta.Key end

		local sym = box:FindFirstChild("SymbolLabel") :: TextLabel?
		if sym then sym.Text = meta.Symbol end

		box.Parent = cooldownRow
		activeCooldownBoxes[normKey] = box
	end

	local sweep = box:FindFirstChild("CooldownSweep") :: Frame?
	local secLabel = box:FindFirstChild("SecondsLabel") :: TextLabel?

	local startTime = os.clock()

	activeCooldownThreads[normKey] = task.spawn(function()
		while true do
			local elapsed = os.clock() - startTime
			local remaining = math.max(0, cd - elapsed)
			local progress = math.clamp(remaining / cd, 0, 1)

			if sweep then
				sweep.Size = UDim2.new(1, 0, progress, 0)
			end

			if secLabel then
				secLabel.Text = string.format("%.1fs", remaining)
			end

			if remaining <= 0 then
				if box and box.Parent then
					box:Destroy()
				end
				activeCooldownBoxes[normKey] = nil
				activeCooldownThreads[normKey] = nil
				break
			end

			RunService.Heartbeat:Wait()
		end
	end)
end

function SkillBarController.UpdateVitals(curHp: number, maxHp: number, curQi: number, maxQi: number, targetQi: number?, isReady: boolean?, isMeditating: boolean?)
	local hMax = math.max(1, maxHp or 100)
	local hCur = math.clamp(curHp or 0, 0, hMax)
	local hRatio = math.clamp(hCur / hMax, 0, 1)

	local qMax = math.max(1, maxQi or 100)
	local qCur = math.clamp(curQi or 0, 0, qMax)
	local qRatio = math.clamp(qCur / qMax, 0, 1)

	if hpFill then TweenService:Create(hpFill, INTENT_BAR_TWEEN, { Size = UDim2.new(hRatio, 0, 1, 0) }):Play() end
	if hpTextLabel then hpTextLabel.Text = string.format("%s / %s", FormatNum(hCur), FormatNum(hMax)) end

	if qiFill then TweenService:Create(qiFill, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play() end
	if qiTextLabel then
		if isReady then
			qiTextLabel.Text = string.format("%s / %s [READY - PRESS B]", FormatNum(qCur), FormatNum(qMax))
		elseif isMeditating and targetQi and targetQi > 0 then
			local dPct = math.floor(math.clamp(qMax / targetQi, 0, 1) * 100)
			qiTextLabel.Text = string.format("%s / %s (Dantian: %d%%)", FormatNum(qCur), FormatNum(qMax), dPct)
		else
			qiTextLabel.Text = string.format("%s / %s", FormatNum(qCur), FormatNum(qMax))
		end
	end
end

function SkillBarController.UpdateCurrencies()
	local cp = GetCurrentCP()
	local stones = GetCurrentStones()

	if cpLabel then cpLabel.Text = FormatCurrency(cp) .. " CP" end
	if spiritStoneLabel then spiritStoneLabel.Text = FormatCurrency(stones) end
end

function SkillBarController.UpdateSwordIntent(current: number, max: number)
	currentSwordIntent = math.clamp(current or 0, 0, max or 100)
	local maxVal = math.max(1, max or 100)
	local ratio = math.clamp(currentSwordIntent / maxVal, 0, 1)
	local val = math.floor(currentSwordIntent)

	if intentFill then TweenService:Create(intentFill, INTENT_BAR_TWEEN, { Size = UDim2.new(ratio, 0, 1, 0) }):Play() end
	if intentTextLabel then intentTextLabel.Text = string.format("%d / %d", val, math.floor(maxVal)) end
end

local function BindCharacter(newCharacter: Model)
	for _, conn in ipairs(characterConnections) do
		conn:Disconnect()
	end
	table.clear(characterConnections)

	SkillBarController.HookStudioUI()

	local humanoid = newCharacter:WaitForChild("Humanoid", 8) :: Humanoid?

	local function checkVitals()
		local char = LocalPlayer.Character
		if not char or char ~= newCharacter then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		local liveMaxHp = math.max(hum.MaxHealth, char:GetAttribute("MaxHealth") or 0)
		local liveHp = if hum.Health > 0 then hum.Health else (char:GetAttribute("Health") or hum.Health)

		local curQi = char:GetAttribute("Qi") or char:GetAttribute("CurrentQi") or LocalPlayer:GetAttribute("Qi") or 100
		local maxQi = char:GetAttribute("MaxQi") or char:GetAttribute("MaxGoalQi") or LocalPlayer:GetAttribute("MaxQi") or 1000
		local targetQi = char:GetAttribute("TargetQi") or 500
		local isReady = (char:GetAttribute("BreakthroughReady") == true) or (maxQi >= targetQi)
		local isMeditating = char:GetAttribute("IsMeditating") == true

		SkillBarController.UpdateVitals(
			tonumber(liveHp) or 100,
			tonumber(liveMaxHp) or 100,
			tonumber(curQi) or 100,
			tonumber(maxQi) or 100,
			tonumber(targetQi) or 500,
			isReady,
			isMeditating
		)
	end

	local function checkIntent()
		local char = LocalPlayer.Character
		if not char or char ~= newCharacter then return end

		local intent = char:GetAttribute("SwordIntent") or LocalPlayer:GetAttribute("SwordIntent") or currentSwordIntent
		local maxIntent = char:GetAttribute("MaxSwordIntent") or LocalPlayer:GetAttribute("MaxSwordIntent") or 100
		SkillBarController.UpdateSwordIntent(tonumber(intent) or 0, tonumber(maxIntent) or 100)
	end

	local function checkEquippedStates()
		local char = LocalPlayer.Character
		if not char or char ~= newCharacter then return end

		local isDrawn = char:GetAttribute("IsWeaponDrawn") == true
		local isFlying = char:GetAttribute("IsFlying") == true

		local slot1 = hotbarSlotButtons[1]
		if slot1 then
			local stroke = slot1:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = isDrawn and Color3.fromRGB(190, 215, 245) or Color3.fromRGB(60, 78, 105)
				stroke.Thickness = isDrawn and 1.8 or 1
			end
		end

		local slot2 = hotbarSlotButtons[2]
		if slot2 then
			local stroke = slot2:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = isFlying and Color3.fromRGB(120, 180, 235) or Color3.fromRGB(60, 78, 105)
				stroke.Thickness = isFlying and 1.8 or 1
			end
		end
	end

	if humanoid then
		table.insert(characterConnections, humanoid:GetPropertyChangedSignal("Health"):Connect(checkVitals))
		table.insert(characterConnections, humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(checkVitals))
		table.insert(characterConnections, humanoid.Died:Connect(function()
			local char = LocalPlayer.Character
			if char == newCharacter then
				local deathMaxHp = math.max(humanoid.MaxHealth, char:GetAttribute("MaxHealth") or 0)
				local deathMaxQi = char:GetAttribute("MaxQi") or LocalPlayer:GetAttribute("MaxQi") or 1000
				SkillBarController.UpdateVitals(0, deathMaxHp, 0, deathMaxQi)
			end
		end))
	end

	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("Health"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("MaxHealth"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("Qi"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("CurrentQi"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("MaxQi"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("TargetQi"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("BreakthroughReady"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("IsMeditating"):Connect(checkVitals))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("IsWeaponDrawn"):Connect(checkEquippedStates))
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("IsFlying"):Connect(checkEquippedStates))

	task.spawn(function()
		local syncIntervals = { 0.05, 0.15, 0.30, 0.60, 1.0 }
		for _, delaySec in ipairs(syncIntervals) do
			task.wait(delaySec)
			if LocalPlayer.Character == newCharacter and humanoid and humanoid.Parent and humanoid.Health > 0 then
				checkVitals()
				checkEquippedStates()
				if humanoid.MaxHealth > 1000 then break end
			end
		end
	end)

	checkVitals()
	SkillBarController.UpdateCurrencies()
	checkIntent()
	checkEquippedStates()
end

function SkillBarController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")

	local updateInvRemote = RemoteEvents.GetRemote("UpdateInventory")
	if updateInvRemote then
		updateInvRemote.OnClientEvent:Connect(function(inventoryData: any)
			if type(inventoryData) ~= "table" then return end
			local healCount = 0
			local qiCount = 0

			for _, slotData in pairs(inventoryData) do
				if type(slotData) == "table" and slotData.ItemId then
					if slotData.ItemId == "SpiritHealingDan" then
						healCount += (tonumber(slotData.Count) or 1)
					elseif slotData.ItemId == "QiGatheringDan" then
						qiCount += (tonumber(slotData.Count) or 1)
					end
				end
			end

			if hotbarCountLabels[3] then
				hotbarCountLabels[3].Text = if healCount > 0 then "x" .. tostring(healCount) else ""
			end
			if hotbarCountLabels[4] then
				hotbarCountLabels[4].Text = if qiCount > 0 then "x" .. tostring(qiCount) else ""
			end
		end)
	end

	pcall(function()
		sectRemote = RemoteEvents.GetRemote("SectAction")
		if sectRemote then
			sectRemote.OnClientEvent:Connect(function(payload: any)
				if type(payload) == "table" and (payload.Action == "SyncSectData" or payload.Action == "QuestCompleted") then
					task.defer(SkillBarController.UpdateCurrencies)
				end
			end)
		end
	end)

	SkillBarController.HookStudioUI()

	local currencyAttributes = { "ContributionPoints", "SectContribution", "CP", "SpiritStones", "Stones" }
	for _, attr in ipairs(currencyAttributes) do
		LocalPlayer:GetAttributeChangedSignal(attr):Connect(SkillBarController.UpdateCurrencies)
	end

	if LocalPlayer.Character then
		BindCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(BindCharacter)

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any)
		if attacker == LocalPlayer and type(payload) == "table" and payload.HasHit == true then
			lastHitLandedTime = os.clock()
			currentSwordIntent = if payload.CurrentIntent ~= nil then (tonumber(payload.CurrentIntent) or 0) else math.clamp(currentSwordIntent + 25, 0, 100)
			SkillBarController.UpdateSwordIntent(currentSwordIntent, 100)
		end
	end)

	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		if (now - lastHitLandedTime > INTENT_DECAY_DELAY) and currentSwordIntent > 0 then
			currentSwordIntent = math.clamp(currentSwordIntent - (INTENT_DECAY_RATE * dt), 0, 100)
			SkillBarController.UpdateSwordIntent(currentSwordIntent, 100)
		end
	end)

	print("[ASCEND] SkillBarController Initialized (Interactive Collapsible Guide Active).")
end

return SkillBarController