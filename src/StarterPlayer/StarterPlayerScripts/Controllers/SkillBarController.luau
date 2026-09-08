--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Directly bound to StarterGui.MasterHUDGui:
    - 10-Slot Skill Hotbar (B, C, E, F, M1, Q, R, Shift, T, V) with Cooldown Sweeps
    - Vitals Container (HP, Qi, Sword Intent Gauge)
    - TopRight Currency (Live Contribution Points CP & Spirit Stones)
    - BottomNavTray Modal Buttons (Arena, Bag, Guide, Meditate, Sect)
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
local bottomNavTray: Frame?

local combatActionRemote: RemoteEvent
local sectRemote: RemoteEvent? = nil

local currentSwordIntent = 0
local lastHitLandedTime = os.clock()
local lastKnownQi = 0
local lastKnownMaxQi = 100

local skillButtons: { [string]: ImageButton } = {}
local cooldownSweeps: { [string]: Frame } = {}
local cooldownTexts: { [string]: TextLabel } = {}

local function FormatNum(num: number): string
	if CultivationConfig and CultivationConfig.FormatNumber then
		return CultivationConfig.FormatNumber(num)
	end
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
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

local function TriggerM1()
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			local req = require(inputCtrl) :: any
			if req.TriggerM1 then req.TriggerM1(); return end
		end
	end
	combatActionRemote:FireServer({ SkillKey = "M1", AimDirection = Vector3.new(0, 0, -1), Timestamp = os.clock() })
end

function SkillBarController.HookStudioUI()
	masterGui = (PlayerGui:FindFirstChild("MasterHUDGui") or PlayerGui:WaitForChild("MasterHUDGui", 8)) :: ScreenGui?
	if not masterGui then return end
	masterGui.DisplayOrder = 10

	-- 1. Vitals Container (HP, Qi, Intent)
	vitalsContainer = masterGui:FindFirstChild("VitalsContainer") :: Frame?
	if vitalsContainer then
		local hpFrame = vitalsContainer:FindFirstChild("HPBarFrame")
		if hpFrame then
			hpFill = hpFrame:FindFirstChild("BarFill") :: Frame?
			hpTextLabel = hpFrame:FindFirstChildOfClass("TextLabel")
		end

		local qiFrame = vitalsContainer:FindFirstChild("QIBarFrame")
		if qiFrame then
			qiFill = qiFrame:FindFirstChild("BarFill") :: Frame?
			qiTextLabel = qiFrame:FindFirstChildOfClass("TextLabel")
		end

		local intentFrame = vitalsContainer:FindFirstChild("IntentBarFrame")
		if intentFrame then
			intentFill = intentFrame:FindFirstChild("BarFill") :: Frame?
			intentTextLabel = intentFrame:FindFirstChildOfClass("TextLabel")
		end
	end

	-- 2. Top-Right Currency Frame
	currencyFrame = masterGui:FindFirstChild("TopRightCurrencyFrame") :: Frame?
	if currencyFrame then
		local cpFrame = currencyFrame:FindFirstChild("CPFrame")
		if cpFrame then cpLabel = cpFrame:FindFirstChildOfClass("TextLabel") end

		local stoneFrame = currencyFrame:FindFirstChild("SpiritStoneFrame")
		if stoneFrame then spiritStoneLabel = stoneFrame:FindFirstChildOfClass("TextLabel") end
	end

	-- 3. Bottom Center Hotbar Container (10 Skills)
	local bottomCenter = masterGui:FindFirstChild("BottomCenterFrame")
	if bottomCenter then
		hotbarContainer = bottomCenter:FindFirstChild("HotbarContainer") :: Frame?
		if hotbarContainer then
			local skillSlotNames = { "B_SKILL", "C_SKILL", "E_SKILL", "F_SKILL", "M1_SKILL", "Q_SKILL", "R_SKILL", "Shift_SKILL", "T_SKILL", "V_SKILL" }
			for _, sName in ipairs(skillSlotNames) do
				local btn = hotbarContainer:FindFirstChild(sName) :: ImageButton?
				if btn then
					skillButtons[sName] = btn
					cooldownSweeps[sName] = btn:FindFirstChild("CooldownSweep") :: Frame?
					cooldownTexts[sName] = btn:FindFirstChild("CooldownText") :: TextLabel?

					btn.Activated:Connect(function()
						if sName == "M1_SKILL" then
							TriggerM1()
						elseif sName == "R_SKILL" then
							combatActionRemote:FireServer({ ToggleSheath = true })
						elseif sName == "V_SKILL" then
							combatActionRemote:FireServer({ ToggleFlight = true })
						elseif sName == "B_SKILL" then
							combatActionRemote:FireServer({ RequestBreakthrough = true })
						elseif sName == "C_SKILL" then
							combatActionRemote:FireServer({ ToggleMeditation = true })
						end
					end)
				end
			end
		end
	end

	-- 4. Bottom Nav Tray (Modal Openers)
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
			if g then g.Enabled = not g.Enabled; g.ModalBackdrop.Visible = g.Enabled end
		end)

		bindNav("MeditateButton", function()
			combatActionRemote:FireServer({ ToggleMeditation = true })
		end)

		bindNav("SectImageButton", function()
			local c = LocalPlayer.PlayerScripts.Controllers:FindFirstChild("SectController")
			if c then require(c).Open() end
		end)
	end
end

function SkillBarController.TriggerCooldown(slotName: string, duration: number)
	local sweep = cooldownSweeps[slotName] or cooldownSweeps[slotName .. "_SKILL"]
	local text = cooldownTexts[slotName] or cooldownTexts[slotName .. "_SKILL"]
	if not sweep then return end

	sweep.Visible = true
	if text then text.Visible = true end

	local startTime = os.clock()
	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		local elapsed = os.clock() - startTime
		local remaining = math.max(0, duration - elapsed)
		local progress = math.clamp(remaining / duration, 0, 1)

		sweep.Size = UDim2.new(1, 0, progress, 0)
		if text then text.Text = string.format("%.1f", remaining) end

		if remaining <= 0 then
			sweep.Visible = false
			if text then text.Visible = false; text.Text = "" end
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
	if hpTextLabel then hpTextLabel.Text = string.format("HP %s/%s", FormatNum(hCur), FormatNum(hMax)) end

	if qiFill then TweenService:Create(qiFill, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play() end
	if qiTextLabel then qiTextLabel.Text = string.format("QI %s/%s", FormatNum(qCur), FormatNum(qMax)) end
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
	local percent = math.floor(ratio * 100)

	if intentFill then TweenService:Create(intentFill, INTENT_BAR_TWEEN, { Size = UDim2.new(ratio, 0, 1, 0) }):Play() end
	if intentTextLabel then intentTextLabel.Text = string.format("SWORD INTENT %d%%", percent) end
end

local function BindCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?

	local function checkVitals()
		local curHp = if humanoid then humanoid.Health else (character:GetAttribute("Health") or 100)
		local maxHp = if humanoid then humanoid.MaxHealth else (character:GetAttribute("MaxHealth") or 100)
		local curQi = character:GetAttribute("Qi") or LocalPlayer:GetAttribute("Qi") or 100
		local maxQi = character:GetAttribute("MaxQi") or LocalPlayer:GetAttribute("MaxQi") or 100
		SkillBarController.UpdateVitals(tonumber(curHp) or 100, tonumber(maxHp) or 100, tonumber(curQi) or 100, tonumber(maxQi) or 100)
	end

	local function checkIntent()
		local intent = character:GetAttribute("SwordIntent") or LocalPlayer:GetAttribute("SwordIntent") or currentSwordIntent
		local maxIntent = character:GetAttribute("MaxSwordIntent") or LocalPlayer:GetAttribute("MaxSwordIntent") or 100
		SkillBarController.UpdateSwordIntent(tonumber(intent) or 0, tonumber(maxIntent) or 100)
	end

	if humanoid then
		humanoid:GetPropertyChangedSignal("Health"):Connect(checkVitals)
		humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(checkVitals)
	end

	character:GetAttributeChangedSignal("Qi"):Connect(checkVitals)
	character:GetAttributeChangedSignal("MaxQi"):Connect(checkVitals)
	LocalPlayer:GetAttributeChangedSignal("Qi"):Connect(checkVitals)
	LocalPlayer:GetAttributeChangedSignal("MaxQi"):Connect(checkVitals)

	local currencyAttributes = { "ContributionPoints", "SectContribution", "CP", "SpiritStones", "Stones" }
	for _, attr in ipairs(currencyAttributes) do
		LocalPlayer:GetAttributeChangedSignal(attr):Connect(SkillBarController.UpdateCurrencies)
		character:GetAttributeChangedSignal(attr):Connect(SkillBarController.UpdateCurrencies)
	end

	character:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)
	LocalPlayer:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)

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

	if LocalPlayer.Character then BindCharacter(LocalPlayer.Character) end
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

	print("[ASCEND] SkillBarController Initialized (MasterHUDGui Bound).")
end

return SkillBarController