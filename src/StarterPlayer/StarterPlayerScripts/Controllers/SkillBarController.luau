--!strict
--[[
    SkillBarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
    Handles:
      - Desktop (SkillsGUI: M1, R, B, V, C) vs Mobile (LowViewPortSkillsGUI + Touch Combat Cluster)
      - Exclusive 'C' Keybind for Meditation (M key completely removed)
      - Dynamic Vitals & Looping Sword Intent updates
      - BottomMenuGui & CurrencyGUI Bindings
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

local SkillBarController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
local Camera = Workspace.CurrentCamera

local INTENT_BAR_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BUTTON_PRESS_TWEEN = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local INTENT_DECAY_DELAY = 2.5
local INTENT_DECAY_RATE = 8.0

-- Desktop SkillsGUI
local desktopSkillsGui: ScreenGui?
local desktopMainFrame: Frame?
local desktopIntentFill: Frame?
local desktopIntentLabel: TextLabel?
local desktopHpFill: Frame?
local desktopHpLabel: TextLabel?
local desktopQiFill: Frame?
local desktopQiLabel: TextLabel?

-- Low Viewport SkillsGUI (Studio: LowViewPortSkillsGUI)
local lowViewportGui: ScreenGui?
local lowMainFrame: Frame?
local lowIntentFill: Frame?
local lowIntentLabel: TextLabel?
local lowHpFill: Frame?
local lowHpLabel: TextLabel?
local lowQiFill: Frame?
local lowQiLabel: TextLabel?

-- Dynamic Mobile Right-Side Combat Cluster (M1, R, V)
local mobileCombatGui: ScreenGui?
local mobileCombatCluster: Frame?

-- BottomMenuGui
local bottomMenuGui: ScreenGui?
local bagButton: ImageButton?
local arenaButton: ImageButton?

-- CurrencyGUI
local currencyGui: ScreenGui?
local cpLabel: TextLabel?
local spiritStoneLabel: TextLabel?

local combatActionRemote: RemoteEvent
local currentSwordIntent = 0
local lastHitLandedTime = os.clock()

local lastKnownQi = 0
local lastKnownMaxQi = 100

-- =============================================================================
-- DEVICE DETECTION (Touch / Mobile Viewport)
-- =============================================================================
local function IsMobileOrTouch(): boolean
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return true
	end
	local vp = Camera.ViewportSize
	if vp.X > 0 and (vp.X < 950 or vp.Y < 560) then
		return true
	end
	return false
end

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

local function EmitToast(message: string)
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local hudCtrl = controllers:FindFirstChild("HUDController")
		if hudCtrl then
			local req = require(hudCtrl) :: any
			if req and req.ShowToast then
				req.ShowToast(message)
			end
		end
	end
end

local function TriggerM1()
	local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local inputCtrl = controllers:FindFirstChild("InputController")
		if inputCtrl then
			local req = require(inputCtrl) :: any
			if req.TriggerM1 then
				req.TriggerM1()
				return
			end
		end
	end
	combatActionRemote:FireServer({ SkillKey = "M1", AimDirection = Vector3.new(0, 0, -1), Timestamp = os.clock() })
end

local function TriggerBreakthrough()
	if lastKnownQi >= lastKnownMaxQi then
		EmitToast("Initiating Cultivation Breakthrough...")
	else
		EmitToast(string.format("Breakthrough Failed: Qi not condensed (%s/%s)", FormatNum(lastKnownQi), FormatNum(lastKnownMaxQi)))
	end
	combatActionRemote:FireServer({ RequestBreakthrough = true })
end

local function TriggerMeditation()
	local char = LocalPlayer.Character
	local isCurrentlyMeditating = char and char:GetAttribute("IsMeditating") == true
	if isCurrentlyMeditating then
		EmitToast("Exited Meditation")
	else
		EmitToast("Entered Meditation (Cultivating Qi)")
	end
	combatActionRemote:FireServer({ ToggleMeditation = true })
end

-- =============================================================================
-- BAR FILL HELPER
-- =============================================================================
local function SetupBarFill(barFrame: Frame, defaultColor: Color3): (Frame, TextLabel?)
	barFrame.ClipsDescendants = true

	local fill = barFrame:FindFirstChild("BarFill") :: Frame?
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "BarFill"
		fill.Size = UDim2.new(1, 0, 1, 0)
		fill.Position = UDim2.new(0, 0, 0, 0)
		fill.BackgroundColor3 = defaultColor
		fill.BorderSizePixel = 0
		fill.ZIndex = 1
		fill.Parent = barFrame

		local parentCorner = barFrame:FindFirstChildOfClass("UICorner")
		if parentCorner then
			local c = parentCorner:Clone()
			c.Parent = fill
		else
			local c = Instance.new("UICorner", fill)
			c.CornerRadius = UDim.new(0, 30)
		end

		local existingGrad = barFrame:FindFirstChildOfClass("UIGradient")
		if existingGrad then
			existingGrad.Parent = fill
		end
	end

	local textLabel = barFrame:FindFirstChildOfClass("TextLabel")
	if textLabel then
		textLabel.ZIndex = 3
	end

	return fill, textLabel
end

local function BindTouchOrClick(inst: Instance, callback: () -> ())
	if inst:IsA("GuiButton") then
		inst.MouseButton1Click:Connect(callback)
	elseif inst:IsA("GuiObject") then
		inst.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
				callback()
			end
		end)
	end
	for _, child in ipairs(inst:GetChildren()) do
		if child:IsA("GuiButton") then
			child.MouseButton1Click:Connect(callback)
		end
	end
end

-- =============================================================================
-- MOBILE RIGHT-SIDE TOUCH COMBAT CLUSTER
-- =============================================================================
local function CreateRobloxStyleTouchButton(name: string, size: number, position: UDim2, labelText: string, callback: () -> ()): ImageButton
	local btn = Instance.new("ImageButton")
	btn.Name = name
	btn.Size = UDim2.new(0, size, 0, size)
	btn.Position = position
	btn.AnchorPoint = Vector2.new(0.5, 0.5)
	btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	btn.BackgroundTransparency = 0.5
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = btn

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(180, 180, 180)
	stroke.Thickness = 2.0
	stroke.Transparency = 0.45
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = btn

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = if size >= 60 then 11.5 else 10.5
	lbl.TextColor3 = Color3.fromRGB(220, 220, 220)
	lbl.Text = labelText
	lbl.Parent = btn

	local scale = Instance.new("UIScale", btn)

	btn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(scale, BUTTON_PRESS_TWEEN, { Scale = 0.9 }):Play()
			callback()
		end
	end)

	btn.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			TweenService:Create(scale, BUTTON_PRESS_TWEEN, { Scale = 1.0 }):Play()
		end
	end)

	return btn
end

local function BuildMobileCombatCluster(parentGui: ScreenGui)
	mobileCombatCluster = Instance.new("Frame")
	mobileCombatCluster.Name = "MobileCombatCluster"
	mobileCombatCluster.Size = UDim2.new(0, 240, 0, 240)
	mobileCombatCluster.Position = UDim2.new(1, 0, 1, 0)
	mobileCombatCluster.AnchorPoint = Vector2.new(1, 1)
	mobileCombatCluster.BackgroundTransparency = 1
	mobileCombatCluster.Visible = false
	mobileCombatCluster.Parent = parentGui

	local m1Btn = CreateRobloxStyleTouchButton("MobileM1Button", 64, UDim2.new(1, -160, 1, -50), "M1\nSTRIKE", TriggerM1)
	m1Btn.Parent = mobileCombatCluster

	local rBtn = CreateRobloxStyleTouchButton("MobileRButton", 48, UDim2.new(1, -160, 1, -125), "R\nDRAW", function()
		combatActionRemote:FireServer({ ToggleSheath = true })
	end)
	rBtn.Parent = mobileCombatCluster

	local vBtn = CreateRobloxStyleTouchButton("MobileVButton", 48, UDim2.new(1, -70, 1, -160), "V\nFLIGHT", function()
		combatActionRemote:FireServer({ ToggleFlight = true })
	end)
	vBtn.Parent = mobileCombatCluster
end

-- =============================================================================
-- HOOK STUDIO GUIS & RESPONSIVE VIEWPORT TOGGLING
-- =============================================================================
function SkillBarController.HookStudioUI()
	-- 1. Desktop SkillsGUI (M1, R, B, V, C)
	desktopSkillsGui = PlayerGui:WaitForChild("SkillsGUI", 5) :: ScreenGui?
	if desktopSkillsGui then
		desktopMainFrame = desktopSkillsGui:FindFirstChild("BottomCenterFrame", true) :: Frame?
		if desktopMainFrame then
			local iFrame = desktopMainFrame:FindFirstChild("IntentBarFrame") :: Frame?
			if iFrame then desktopIntentFill, desktopIntentLabel = SetupBarFill(iFrame, Color3.fromRGB(245, 140, 0)) end

			local hFrame = desktopMainFrame:FindFirstChild("HPBarFrame") :: Frame?
			if hFrame then desktopHpFill, desktopHpLabel = SetupBarFill(hFrame, Color3.fromRGB(0, 200, 50)) end

			local qFrame = desktopMainFrame:FindFirstChild("QIBarFrame") :: Frame?
			if qFrame then desktopQiFill, desktopQiLabel = SetupBarFill(qFrame, Color3.fromRGB(0, 100, 255)) end

			local desktopSlots = {
				{ Name = "M1_SKILL", Callback = TriggerM1 },
				{ Name = "R_SKILL",  Callback = function() combatActionRemote:FireServer({ ToggleSheath = true }) end },
				{ Name = "B_SKILL",  Callback = TriggerBreakthrough },
				{ Name = "V_SKILL",  Callback = function() combatActionRemote:FireServer({ ToggleFlight = true }) end },
				{ Name = "C_SKILL",  Callback = TriggerMeditation },
			}
			for _, s in ipairs(desktopSlots) do
				local slotObj = desktopMainFrame:FindFirstChild(s.Name)
				if slotObj then BindTouchOrClick(slotObj, s.Callback) end
			end
		end
	end

	-- 2. Low Viewport Mobile SkillsGUI (Intent/HP/QI + B & C/M Skills)
	lowViewportGui = (PlayerGui:WaitForChild("LowViewPortSkillsGUI", 5) or PlayerGui:WaitForChild("LowViewPortSkillGUI", 5)) :: ScreenGui?
	if lowViewportGui then
		lowMainFrame = lowViewportGui:FindFirstChild("BottomCenterFrame", true) :: Frame?
		if lowMainFrame then
			local iFrame = lowMainFrame:FindFirstChild("IntentBarFrame") :: Frame?
			if iFrame then lowIntentFill, lowIntentLabel = SetupBarFill(iFrame, Color3.fromRGB(245, 140, 0)) end

			local hFrame = lowMainFrame:FindFirstChild("HPBarFrame") :: Frame?
			if hFrame then lowHpFill, lowHpLabel = SetupBarFill(hFrame, Color3.fromRGB(0, 200, 50)) end

			local qFrame = lowMainFrame:FindFirstChild("QIBarFrame") :: Frame?
			if qFrame then lowQiFill, lowQiLabel = SetupBarFill(qFrame, Color3.fromRGB(0, 100, 255)) end

			local bSlot = lowMainFrame:FindFirstChild("B_SKILL")
			if bSlot then BindTouchOrClick(bSlot, TriggerBreakthrough) end

			local cSlot = lowMainFrame:FindFirstChild("C_SKILL") or lowMainFrame:FindFirstChild("M_SKILL")
			if cSlot then BindTouchOrClick(cSlot, TriggerMeditation) end
		end
	end

	-- 3. Dynamic Mobile Right-Side Combat Cluster
	mobileCombatGui = Instance.new("ScreenGui")
	mobileCombatGui.Name = "MobileCombatHUD"
	mobileCombatGui.ResetOnSpawn = false
	mobileCombatGui.DisplayOrder = 11
	mobileCombatGui.IgnoreGuiInset = false
	mobileCombatGui.Parent = PlayerGui
	BuildMobileCombatCluster(mobileCombatGui)

	-- 4. BottomMenuGui
	bottomMenuGui = PlayerGui:WaitForChild("BottomMenuGui", 5) :: ScreenGui?
	if bottomMenuGui then
		bagButton = bottomMenuGui:FindFirstChild("BagImageButton", true) :: ImageButton?
		arenaButton = bottomMenuGui:FindFirstChild("ArenaImageButton", true) :: ImageButton?

		if bagButton then
			bagButton.MouseButton1Click:Connect(function()
				local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
				if controllers then
					local inv = controllers:FindFirstChild("InventoryController")
					if inv then
						local req = require(inv) :: any
						if req.Toggle then req.Toggle() end
					end
				end
			end)
		end

		if arenaButton then
			arenaButton.MouseButton1Click:Connect(function()
				local controllers = LocalPlayer.PlayerScripts:FindFirstChild("Controllers")
				if controllers then
					local arena = controllers:FindFirstChild("ArenaController")
					if arena then
						local req = require(arena) :: any
						if req.ToggleModal then req.ToggleModal() end
					end
				end
			end)
		end
	end

	-- 5. CurrencyGUI
	currencyGui = PlayerGui:WaitForChild("CurrencyGUI", 5) :: ScreenGui?
	if currencyGui then
		local cpFrame = currencyGui:FindFirstChild("CPFrame", true)
		if cpFrame then cpLabel = cpFrame:FindFirstChildOfClass("TextLabel") end

		local spiritFrame = currencyGui:FindFirstChild("SpiritStoneFrame", true)
		if spiritFrame then spiritStoneLabel = spiritFrame:FindFirstChildOfClass("TextLabel") end
	end

	SkillBarController.UpdateViewportMode()
end

-- =============================================================================
-- EXPLICIT VIEWPORT VISIBILITY SWITCHER
-- =============================================================================
function SkillBarController.UpdateViewportMode()
	local isMobile = IsMobileOrTouch()

	-- Desktop GUI Toggle
	if desktopSkillsGui then
		desktopSkillsGui.Enabled = not isMobile
	end
	if desktopMainFrame then
		desktopMainFrame.Visible = not isMobile
	end

	-- Low Viewport Mobile GUI Toggle
	if lowViewportGui then
		lowViewportGui.Enabled = isMobile
	end
	if lowMainFrame then
		lowMainFrame.Visible = isMobile
	end

	-- Mobile Right-Side Combat Cluster
	if mobileCombatGui then
		mobileCombatGui.Enabled = isMobile
	end
	if mobileCombatCluster then
		mobileCombatCluster.Visible = isMobile
	end
end

-- =============================================================================
-- DUAL-VIEWPORT VITALS & INTENT UPDATES
-- =============================================================================
function SkillBarController.UpdateVitals(curHp: number, maxHp: number, curQi: number, maxQi: number)
	lastKnownQi = curQi or 0
	lastKnownMaxQi = maxQi or 100

	local hMax = math.max(1, maxHp or 100)
	local hCur = math.clamp(curHp or 0, 0, hMax)
	local hRatio = math.clamp(hCur / hMax, 0, 1)

	local qMax = math.max(1, maxQi or 100)
	local qCur = math.clamp(curQi or 0, 0, qMax)
	local qRatio = math.clamp(qCur / qMax, 0, 1)

	local hpStr = string.format("HP %s/%s", FormatNum(hCur), FormatNum(hMax))
	local qiStr = string.format("QI %s/%s", FormatNum(qCur), FormatNum(qMax))

	-- Desktop Update
	if desktopHpFill then TweenService:Create(desktopHpFill, INTENT_BAR_TWEEN, { Size = UDim2.new(hRatio, 0, 1, 0) }):Play() end
	if desktopHpLabel then desktopHpLabel.Text = hpStr end
	if desktopQiFill then TweenService:Create(desktopQiFill, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play() end
	if desktopQiLabel then desktopQiLabel.Text = qiStr end

	-- Low Viewport Mobile Update
	if lowHpFill then TweenService:Create(lowHpFill, INTENT_BAR_TWEEN, { Size = UDim2.new(hRatio, 0, 1, 0) }):Play() end
	if lowHpLabel then lowHpLabel.Text = hpStr end
	if lowQiFill then TweenService:Create(lowQiFill, INTENT_BAR_TWEEN, { Size = UDim2.new(qRatio, 0, 1, 0) }):Play() end
	if lowQiLabel then lowQiLabel.Text = qiStr end
end

function SkillBarController.UpdateCurrencies(cp: number, stones: number)
	if cpLabel then cpLabel.Text = FormatCurrency(cp) end
	if spiritStoneLabel then spiritStoneLabel.Text = FormatCurrency(stones) end
end

function SkillBarController.UpdateSwordIntent(current: number, max: number)
	currentSwordIntent = math.clamp(current or 0, 0, max or 100)
	local maxVal = math.max(1, max or 100)
	local ratio = math.clamp(currentSwordIntent / maxVal, 0, 1)
	local percent = math.floor(ratio * 100)
	local intentStr = if percent >= 100 then "SWORD INTENT 100%" else string.format("SWORD INTENT %d%%", percent)

	-- Desktop Intent
	if desktopIntentFill then TweenService:Create(desktopIntentFill, INTENT_BAR_TWEEN, { Size = UDim2.new(ratio, 0, 1, 0) }):Play() end
	if desktopIntentLabel then desktopIntentLabel.Text = intentStr end

	-- Low Viewport Mobile Intent
	if lowIntentFill then TweenService:Create(lowIntentFill, INTENT_BAR_TWEEN, { Size = UDim2.new(ratio, 0, 1, 0) }):Play() end
	if lowIntentLabel then lowIntentLabel.Text = intentStr end
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

	local function checkCurrencies()
		local stones = character:GetAttribute("SpiritStones") or LocalPlayer:GetAttribute("SpiritStones") or LocalPlayer:GetAttribute("Stones") or 46600
		local cp = character:GetAttribute("SectContribution") or LocalPlayer:GetAttribute("SectContribution") or LocalPlayer:GetAttribute("CP") or 350

		SkillBarController.UpdateCurrencies(tonumber(cp) or 0, tonumber(stones) or 0)
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

	LocalPlayer:GetAttributeChangedSignal("SpiritStones"):Connect(checkCurrencies)
	LocalPlayer:GetAttributeChangedSignal("Stones"):Connect(checkCurrencies)
	LocalPlayer:GetAttributeChangedSignal("SectContribution"):Connect(checkCurrencies)
	LocalPlayer:GetAttributeChangedSignal("CP"):Connect(checkCurrencies)
	character:GetAttributeChangedSignal("SpiritStones"):Connect(checkCurrencies)

	character:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)
	LocalPlayer:GetAttributeChangedSignal("SwordIntent"):Connect(checkIntent)

	checkVitals()
	checkCurrencies()
	checkIntent()
end

function SkillBarController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	SkillBarController.HookStudioUI()

	if LocalPlayer.Character then
		BindCharacter(LocalPlayer.Character)
	end
	LocalPlayer.CharacterAdded:Connect(BindCharacter)

	-- Direct CombatAction sync for instant Sword Intent charge
	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any)
		if attacker == LocalPlayer and type(payload) == "table" and payload.HasHit == true then
			lastHitLandedTime = os.clock()

			if payload.CurrentIntent ~= nil then
				currentSwordIntent = tonumber(payload.CurrentIntent) or 0
			else
				if currentSwordIntent >= 99.9 then
					currentSwordIntent = 0
				else
					currentSwordIntent = math.clamp(currentSwordIntent + 25, 0, 100)
				end
			end

			SkillBarController.UpdateSwordIntent(currentSwordIntent, 100)
		end
	end)

	-- Client-side smooth intent decay
	RunService.Heartbeat:Connect(function(dt: number)
		local now = os.clock()
		if (now - lastHitLandedTime > INTENT_DECAY_DELAY) and currentSwordIntent > 0 then
			currentSwordIntent = math.clamp(currentSwordIntent - (INTENT_DECAY_RATE * dt), 0, 100)
			SkillBarController.UpdateSwordIntent(currentSwordIntent, 100)
		end
	end)

	-- Viewport resize listener for Studio device emulation
	Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		SkillBarController.UpdateViewportMode()
	end)

	-- Desktop Keybind triggers (Exclusive 'C' keybind for Meditation)
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local key = input.KeyCode

		if key == Enum.KeyCode.R then
			combatActionRemote:FireServer({ ToggleSheath = true })
		elseif key == Enum.KeyCode.V then
			combatActionRemote:FireServer({ ToggleFlight = true })
		elseif key == Enum.KeyCode.B then
			TriggerBreakthrough()
		elseif key == Enum.KeyCode.C then
			TriggerMeditation()
		end
	end)

	print("[ASCEND] SkillBarController Initialized (C_SKILL & Exclusive 'C' Cultivation Active).")
end

return SkillBarController