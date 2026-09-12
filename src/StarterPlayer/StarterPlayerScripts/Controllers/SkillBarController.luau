--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Directly bound to StarterGui.MasterHUDGui:
    - 10-Slot Desktop Hotbar & Mobile Touch Cluster
    - Dual Cooldown Sweeper
    - Bottom-Left Vitals Container (HP, Qi, Sword Intent with Bangers font)
    - Anti-Death Bug: Strict Connection Garbage Collector purges zombie listeners on respawn
    - Always binds to active live Humanoid (Permanently eliminates the 0 HP bug)
    - TopRight Currency (Live CP & Spirit Stones)
    - BottomNavTray Modal Openers (Arena, Pouch, Guide, Mission)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

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

local hotbarContainer: Frame?
local mobileScatterCluster: Frame?
local bottomNavTray: Frame?

local combatActionRemote: RemoteEvent
local sectRemote: RemoteEvent? = nil

local currentSwordIntent = 0
local lastHitLandedTime = os.clock()

local cooldownSweeps: { [string]: { Frame } } = {}
local cooldownTexts: { [string]: { TextLabel } } = {}

-- Connection Garbage Collector (Kills all zombie listeners on death)
local characterConnections: { RBXScriptConnection } = {}

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

local function CleanSlotKey(rawName: string): string
	local clean = rawName:gsub("_SKILL$", "")
	return clean
end

local function BindSkillButton(btn: GuiButton, rawName: string)
	local cleanKey = CleanSlotKey(rawName)

	local sweep = btn:FindFirstChild("CooldownSweep") :: Frame?
	local cdText = btn:FindFirstChild("CooldownText") :: TextLabel?

	if sweep then
		if not cooldownSweeps[cleanKey] then cooldownSweeps[cleanKey] = {} end
		table.insert(cooldownSweeps[cleanKey], sweep)
	end
	if cdText then
		if not cooldownTexts[cleanKey] then cooldownTexts[cleanKey] = {} end
		table.insert(cooldownTexts[cleanKey], cdText)
	end

	if cleanKey == "M1" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerM1 then
				ic.TriggerM1()
			else
				combatActionRemote:FireServer({ SkillKey = "M1", AimDirection = Vector3.new(0, 0, -1), Timestamp = os.clock() })
			end
		end)

	elseif cleanKey == "Shift" or cleanKey == "Dash" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerDash then
				ic.TriggerDash()
			end
		end)

	elseif cleanKey == "T" or cleanKey == "Shield" then
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

	elseif cleanKey == "Q" or cleanKey == "Whirl" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("Q") end
		end)

	elseif cleanKey == "E" or cleanKey == "Thrust" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("E") end
		end)

	elseif cleanKey == "F" or cleanKey == "Slam" then
		btn.Activated:Connect(function()
			local ic = GetInputController()
			if ic and ic.TriggerSkill then ic.TriggerSkill("F") end
		end)

	elseif cleanKey == "R" or cleanKey == "Sheath" then
		btn.Activated:Connect(function()
			combatActionRemote:FireServer({ ToggleSheath = true })
		end)

	elseif cleanKey == "V" or cleanKey == "Flight" then
		btn.Activated:Connect(function()
			combatActionRemote:FireServer({ ToggleFlight = true })
		end)

	elseif cleanKey == "C" or cleanKey == "Meditate" then
		btn.Activated:Connect(function()
			combatActionRemote:FireServer({ ToggleMeditation = true })
		end)

	elseif cleanKey == "B" or cleanKey == "Break" then
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

	table.clear(cooldownSweeps)
	table.clear(cooldownTexts)

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

	currencyFrame = masterGui:FindFirstChild("TopRightCurrencyFrame") :: Frame?
	if currencyFrame then
		local cpFrame = currencyFrame:FindFirstChild("CPFrame")
		if cpFrame then cpLabel = cpFrame:FindFirstChildOfClass("TextLabel") end

		local stoneFrame = currencyFrame:FindFirstChild("SpiritStoneFrame")
		if stoneFrame then spiritStoneLabel = stoneFrame:FindFirstChildOfClass("TextLabel") end
	end

	local skillSlotNames = {
		"B_SKILL", "C_SKILL", "E_SKILL", "F_SKILL", "M1_SKILL",
		"Q_SKILL", "R_SKILL", "Shift_SKILL", "T_SKILL", "V_SKILL"
	}

	local bottomCenter = masterGui:FindFirstChild("BottomCenterFrame") :: Frame?
	if bottomCenter then
		hotbarContainer = bottomCenter:FindFirstChild("HotbarContainer") :: Frame?
		if hotbarContainer then
			for _, sName in ipairs(skillSlotNames) do
				local btn = hotbarContainer:FindFirstChild(sName) :: GuiButton?
				if btn then
					BindSkillButton(btn, sName)
				end
			end
		end
	end

	mobileScatterCluster = masterGui:FindFirstChild("MobileScatterCluster") :: Frame?
	if mobileScatterCluster then
		for _, sName in ipairs(skillSlotNames) do
			local btn = mobileScatterCluster:FindFirstChild(sName) :: GuiButton?
			if btn then
				BindSkillButton(btn, sName)
			end
		end
	end

	bottomNavTray = masterGui:FindFirstChild("BottomNavTray") :: Frame?
	if bottomNavTray then
		local function bindNav(btnName: string, callback: () -> ())
			local btn = bottomNavTray:FindFirstChild(btnName) :: TextButton?
			if btn then
				btn.Activated:Connect(callback)
			end
		end

		bindNav("ArenaImageButton", function()
			local c = LocalPlayer.PlayerScripts.Controllers:FindFirstChild("ArenaController")
			if c then require(c).ToggleModal() end
		end)

		bindNav("BagImageButton", function()
			local c = LocalPlayer.PlayerScripts.Controllers:FindFirstChild("InventoryController")
			if c then require(c).Toggle() end
		end)

		bindNav("GuideImageButton", function()
			local g = PlayerGui:FindFirstChild("StarterGuideGui")
			if g then g.Enabled = not g.Enabled end
		end)

		bindNav("SectImageButton", function()
			local c = LocalPlayer.PlayerScripts.Controllers:FindFirstChild("SectController")
			if c then require(c).Open() end
		end)
	end
end

function SkillBarController.TriggerCooldown(slotName: string, duration: number?)
	local cd = if duration and type(duration) == "number" and duration > 0 then duration else 1.5
	local cleanKey = CleanSlotKey(slotName)

	local sweepList = cooldownSweeps[cleanKey]
	local textList = cooldownTexts[cleanKey]

	if not sweepList or #sweepList == 0 then return end

	for _, s in ipairs(sweepList) do s.Visible = true end
	if textList then
		for _, t in ipairs(textList) do t.Visible = true end
	end

	local startTime = os.clock()
	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local remaining = math.max(0, cd - elapsed)
		local progress = math.clamp(remaining / cd, 0, 1)

		for _, s in ipairs(sweepList) do
			s.Size = UDim2.new(1, 0, progress, 0)
		end

		if textList then
			local formatted = string.format("%.1f", remaining)
			for _, t in ipairs(textList) do
				t.Text = formatted
			end
		end

		if remaining <= 0 then
			for _, s in ipairs(sweepList) do s.Visible = false end
			if textList then
				for _, t in ipairs(textList) do
					t.Visible = false
					t.Text = ""
				end
			end
			if conn then conn:Disconnect() end
		end
	end)
end

function SkillBarController.UpdateVitals(curHp: number, maxHp: number, curQi: number, maxQi: number)
	local hMax = math.max(1, maxHp or 100)
	local hCur = math.clamp(curHp or 0, 0, hMax)
	local hRatio = math.clamp(hCur / hMax, 0, 1)

	local qMax = math.max(1, maxQi or 100)
	local qCur = math.clamp(curQi or 0, 0, qMax)
	local qRatio = math.clamp(qCur / qMax, 0, 1)

	if hpFill then TweenService:Create(hpFill, INTENT_BAR_TWEEN, { Size = UDim2.new(hRatio, 0, 1, 0) }):Play() end
	if hpTextLabel then hpTextLabel.Text = string.format("%s / %s", FormatNum(hCur), FormatNum(hMax)) end

	if qiFill then TweenService:Create(qiFill, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play() end
	if qiTextLabel then qiTextLabel.Text = string.format("%s / %s", FormatNum(qCur), FormatNum(qMax)) end
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

-- =============================================================================
-- BULLETPROOF ACTIVE-CHARACTER BINDER (Zero Stale Closures)
-- =============================================================================
local function BindCharacter(newCharacter: Model)
	-- 1. PURGE ALL ZOMBIE LISTENERS FROM PREVIOUS LIVES IMMEDIATELY
	for _, conn in ipairs(characterConnections) do
		conn:Disconnect()
	end
	table.clear(characterConnections)

	SkillBarController.HookStudioUI()

	local humanoid = newCharacter:WaitForChild("Humanoid", 8) :: Humanoid?

	-- Dynamic Active Evaluator: Always reads from the live character instance
	local function checkVitals()
		local char = LocalPlayer.Character
		if not char or char ~= newCharacter then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		local liveMaxHp = math.max(hum.MaxHealth, char:GetAttribute("MaxHealth") or 0)
		local liveHp = if hum.Health > 0 then hum.Health else (char:GetAttribute("Health") or hum.Health)

		local curQi = char:GetAttribute("Qi") or char:GetAttribute("CurrentQi") or LocalPlayer:GetAttribute("Qi") or 100
		local maxQi = char:GetAttribute("MaxQi") or char:GetAttribute("MaxGoalQi") or LocalPlayer:GetAttribute("MaxQi") or 1000

		SkillBarController.UpdateVitals(
			tonumber(liveHp) or 100,
			tonumber(liveMaxHp) or 100,
			tonumber(curQi) or 100,
			tonumber(maxQi) or 100
		)
	end

	local function checkIntent()
		local char = LocalPlayer.Character
		if not char or char ~= newCharacter then return end

		local intent = char:GetAttribute("SwordIntent") or LocalPlayer:GetAttribute("SwordIntent") or currentSwordIntent
		local maxIntent = char:GetAttribute("MaxSwordIntent") or LocalPlayer:GetAttribute("MaxSwordIntent") or 100
		SkillBarController.UpdateSwordIntent(tonumber(intent) or 0, tonumber(maxIntent) or 100)
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
	table.insert(characterConnections, newCharacter:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent))

	-- Rapid Sync Loop: Guarantees millions of HP are rendered within frames of revival
	task.spawn(function()
		local syncIntervals = { 0.05, 0.15, 0.30, 0.60, 1.0 }
		for _, delaySec in ipairs(syncIntervals) do
			task.wait(delaySec)
			if LocalPlayer.Character == newCharacter and humanoid and humanoid.Parent and humanoid.Health > 0 then
				checkVitals()
				if humanoid.MaxHealth > 1000 then break end
			end
		end
	end)

	checkVitals()
	SkillBarController.UpdateCurrencies()
	checkIntent()
end

function SkillBarController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

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

	-- Dedicated Global Currency Listeners (Bound once to LocalPlayer)
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

	print("[ASCEND] SkillBarController Initialized (Zombie Listeners Purged, Bulletproof HP Revival Active).")
end

return SkillBarController