--!strict
--[[
    CharacterStatsController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CharacterStatsController.luau
    Authoritative client controller for StarterGui.CharacterStatsGui:
    - 100% Dynamic data-binding to pre-built StarterGuide-style template (ADR-041).
    - 4-Tab navigation (Dao Realm, Combat Stats, Spirit Weapon, 3D Avatar Manifest).
    - Live 3D turntable ViewportFrame of character & equipped weapon.
    - Toggled via "P" key or public API.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

local CharacterStatsController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- UI References
local gui: ScreenGui?
local backdrop: Frame?
local window: Frame?
local closeBtn: TextButton?
local tabBar: Frame?
local confirmBtn: TextButton?

-- Tab Buttons
local tabs: { TextButton } = {}
local panels: { Frame } = {}
local activeTabIdx = 1

-- Panel 1 Elements (Dao Realm)
local p1Header: TextLabel?
local p1DescLabels: { [string]: TextLabel } = {}
local qiTitle: TextLabel?
local qiFill: Frame?

-- Panel 2 Elements (Combat Stats)
local p2Header: TextLabel?
local p2DescLabels: { [string]: TextLabel } = {}

-- Panel 3 Elements (Spirit Weapon & Forge)
local p3Header: TextLabel?
local p3DescLabels: { [string]: TextLabel } = {}

-- Panel 4 Elements (3D Avatar)
local p4Header: TextLabel?
local viewportFrame: ViewportFrame?
local vpCamera: Camera?
local vpModel: Model?
local turntableConn: RBXScriptConnection?

-- Tab Colors (Matching StarterGuideGui)
local C_ACT_BG  = Color3.fromRGB(0, 150, 190)   -- #0096be
local C_ACT_STR = Color3.fromRGB(0, 220, 255)   -- #00dcff
local C_INA_BG  = Color3.fromRGB(25, 32, 44)    -- #19202c
local C_INA_STR = Color3.fromRGB(50, 65, 85)    -- #324155
local C_INA_TXT = Color3.fromRGB(180, 200, 220) -- #b4c8dc

local isInitialized = false

--------------------------------------------------------------------------------
-- FORMATTERS
--------------------------------------------------------------------------------
local function FormatNum(num: number): string
	if CultivationConfig and CultivationConfig.FormatNumber then
		return CultivationConfig.FormatNumber(num)
	end
	if num >= 1000000 then
		return string.format("%.2fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function FormatComma(n: number): string
	local formatted = tostring(math.floor(n))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

--------------------------------------------------------------------------------
-- ENSURE UI HOOKS
--------------------------------------------------------------------------------
local function EnsureUI(): boolean
	if isInitialized and gui and window then return true end

	gui = (playerGui:FindFirstChild("CharacterStatsGui") or playerGui:WaitForChild("CharacterStatsGui", 6)) :: ScreenGui?
	if not gui then return false end
	gui.DisplayOrder = 50

	backdrop = gui:FindFirstChild("ModalBackdrop") :: Frame?
	if not backdrop then return false end

	window = backdrop:FindFirstChild("GuideWindow") :: Frame?
	if not window then return false end

	closeBtn = window:FindFirstChild("CloseButton") :: TextButton?
	tabBar = window:FindFirstChild("TabBar") :: Frame?
	confirmBtn = window:FindFirstChild("ConfirmButton") :: TextButton?

	-- Hook Tabs
	if tabBar then
		tabs = {
			tabBar:FindFirstChild("Tab_1") :: TextButton,
			tabBar:FindFirstChild("Tab_2") :: TextButton,
			tabBar:FindFirstChild("Tab_3") :: TextButton,
			tabBar:FindFirstChild("Tab_4") :: TextButton,
		}
	end

	-- Hook Panels
	panels = {
		window:FindFirstChild("Panel_1_DaoRealm") :: Frame,
		window:FindFirstChild("Panel_2_CombatStats") :: Frame,
		window:FindFirstChild("Panel_3_SpiritWeapon") :: Frame,
		window:FindFirstChild("Panel_4_AvatarManifest") :: Frame,
	}

	-- Hook Panel 1 Rows
	local panel1 = panels[1]
	if panel1 then
		p1Header = panel1:FindFirstChild("TabHeader") :: TextLabel?
		for i = 1, 6 do
			local row = panel1:FindFirstChild("Row_" .. tostring(i))
			if row then
				p1DescLabels["Row_" .. tostring(i)] = row:FindFirstChild("KeyDesc") :: TextLabel
			end
		end
		local qc = panel1:FindFirstChild("QiContainer")
		if qc then
			qiTitle = qc:FindFirstChild("QiLabel") :: TextLabel?
			local track = qc:FindFirstChild("QiBarTrack")
			if track then
				qiFill = track:FindFirstChild("QiFill") :: Frame?
			end
		end
	end

	-- Hook Panel 2 Rows
	local panel2 = panels[2]
	if panel2 then
		p2Header = panel2:FindFirstChild("TabHeader") :: TextLabel?
		for i = 1, 6 do
			local row = panel2:FindFirstChild("Row_" .. tostring(i))
			if row then
				p2DescLabels["Row_" .. tostring(i)] = row:FindFirstChild("KeyDesc") :: TextLabel
			end
		end
	end

	-- Hook Panel 3 Rows
	local panel3 = panels[3]
	if panel3 then
		p3Header = panel3:FindFirstChild("TabHeader") :: TextLabel?
		for i = 1, 6 do
			local row = panel3:FindFirstChild("Row_" .. tostring(i))
			if row then
				p3DescLabels["Row_" .. tostring(i)] = row:FindFirstChild("KeyDesc") :: TextLabel
			end
		end
	end

	-- Hook Panel 4 (3D Viewport)
	local panel4 = panels[4]
	if panel4 then
		p4Header = panel4:FindFirstChild("TabHeader") :: TextLabel?
		viewportFrame = panel4:FindFirstChild("CharacterViewport") :: ViewportFrame?
	end

	-- Bind Tab Clicking
	for idx, btn in ipairs(tabs) do
		if btn then
			btn.Activated:Connect(function()
				CharacterStatsController.SwitchTab(idx)
			end)
		end
	end

	-- Bind Close Button
	if closeBtn then
		closeBtn.Activated:Connect(function()
			CharacterStatsController.Close()
		end)
	end

	-- Bind Backdrop Dismiss
	backdrop.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local mousePos = UserInputService:GetMouseLocation()
			if window then
				local minX = window.AbsolutePosition.X
				local maxX = minX + window.AbsoluteSize.X
				local minY = window.AbsolutePosition.Y
				local maxY = minY + window.AbsoluteSize.Y

				if mousePos.X < minX or mousePos.X > maxX or mousePos.Y < minY or mousePos.Y > maxY then
					CharacterStatsController.Close()
				end
			end
		end
	end)

	isInitialized = true
	return true
end

--------------------------------------------------------------------------------
-- TAB SWITCHING ENGINE
--------------------------------------------------------------------------------
function CharacterStatsController.SwitchTab(idx: number)
	if not EnsureUI() then return end
	activeTabIdx = idx

	for i, tab in ipairs(tabs) do
		local p = panels[i]
		if i == idx then
			tab.BackgroundColor3 = C_ACT_BG
			tab.TextColor3 = Color3.fromRGB(255, 255, 255)
			local s = tab:FindFirstChildOfClass("UIStroke")
			if s then s.Color = C_ACT_STR end
			if p then p.Visible = true end
		else
			tab.BackgroundColor3 = C_INA_BG
			tab.TextColor3 = C_INA_TXT
			local s = tab:FindFirstChildOfClass("UIStroke")
			if s then s.Color = C_INA_STR end
			if p then p.Visible = false end
		end
	end

	if idx == 4 then
		CharacterStatsController.Setup3DViewport()
	else
		CharacterStatsController.Teardown3DViewport()
	end
end

--------------------------------------------------------------------------------
-- 3D VIEWPORT TURNTABLE RIG SETUP (Panel 4)
--------------------------------------------------------------------------------
function CharacterStatsController.Setup3DViewport()
	if not viewportFrame then return end

	CharacterStatsController.Teardown3DViewport()

	local char = player.Character
	if not char then return end

	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = false
	clone.Name = "ViewportCharacter"

	for _, desc in ipairs(clone:GetDescendants()) do
		if desc:IsA("Script") or desc:IsA("LocalScript") or desc:IsA("Sound") or desc:IsA("BillboardGui") then
			desc:Destroy()
		elseif desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
		end
	end

	local hrp = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then clone:Destroy(); return end

	clone:PivotTo(CFrame.new(0, 0, 0))
	clone.Parent = viewportFrame
	vpModel = clone

	vpCamera = Instance.new("Camera")
	vpCamera.FieldOfView = 36
	vpCamera.CFrame = CFrame.lookAt(Vector3.new(0, 0.4, 8.5), Vector3.new(0, -0.1, 0))
	vpCamera.Parent = viewportFrame
	viewportFrame.CurrentCamera = vpCamera

	local angle = 0
	turntableConn = RunService.RenderStepped:Connect(function(dt: number)
		if not gui or not gui.Enabled or not vpModel or activeTabIdx ~= 4 then return end
		angle = (angle + (dt * 0.45)) % (math.pi * 2)
		vpModel:PivotTo(CFrame.Angles(0, angle, 0))
	end)
end

function CharacterStatsController.Teardown3DViewport()
	if turntableConn then
		turntableConn:Disconnect()
		turntableConn = nil
	end
	if vpModel then
		vpModel:Destroy()
		vpModel = nil
	end
	if vpCamera then
		vpCamera:Destroy()
		vpCamera = nil
	end
end

--------------------------------------------------------------------------------
-- DYNAMIC REAL-TIME STATS SYNCHRONIZATION
--------------------------------------------------------------------------------
function CharacterStatsController.Refresh()
	if not EnsureUI() then return end

	local char = player.Character
	if not char then return end
	local humanoid = char:FindFirstChildOfClass("Humanoid")

	-- 1. Identity & Cultivation Attributes
	local realmRaw = tostring(char:GetAttribute("Realm") or player:GetAttribute("Realm") or "Qi Condensation - Order 1")
	local sectRank = tostring(char:GetAttribute("SectRank") or player:GetAttribute("SectRank") or "Inner Disciple")
	local sect = tostring(char:GetAttribute("Sect") or player:GetAttribute("Sect") or "Azure Cloud Sect")
	local stones = tonumber(char:GetAttribute("SpiritStones") or player:GetAttribute("SpiritStones") or 250) or 0
	local cp = tonumber(char:GetAttribute("ContributionPoints") or player:GetAttribute("ContributionPoints") or 0) or 0
	local alchemyRank = tostring(char:GetAttribute("AlchemyRank") or "Mortal Alchemist - Rank 1")

	local curQi = tonumber(char:GetAttribute("Qi") or player:GetAttribute("Qi") or 100) or 100
	local targetQi = tonumber(char:GetAttribute("TargetQi") or 1000) or 1000

	-- Calculate Realm Multiplier
	local order = tonumber(player:GetAttribute("Order") or char:GetAttribute("Order") or 1) or 1
	local matchOrder = realmRaw:match("Order%s+(%d+)")
	if matchOrder then order = tonumber(matchOrder) or order end

	local realmTierEnum: any = "QiCondensation"
	if string.find(realmRaw:lower(), "nascent") then realmTierEnum = "NascentSoul"
	elseif string.find(realmRaw:lower(), "golden") then realmTierEnum = "GoldenCore"
	elseif string.find(realmRaw:lower(), "foundation") then realmTierEnum = "FoundationEstablishment"
	elseif string.find(realmRaw:lower(), "spirit") then realmTierEnum = "SpiritSevering"
	elseif string.find(realmRaw:lower(), "void") then realmTierEnum = "VoidRefining"
	elseif string.find(realmRaw:lower(), "body") then realmTierEnum = "BodyIntegration"
	elseif string.find(realmRaw:lower(), "mahayana") then realmTierEnum = "Mahayana"
	elseif string.find(realmRaw:lower(), "tribulation") then realmTierEnum = "TribulationTranscending"
	elseif string.find(realmRaw:lower(), "immortal") then realmTierEnum = "ImmortalAscension"
	end

	local powerMultiplier = 1.0
	if CultivationConfig and CultivationConfig.GetPowerMultiplier then
		powerMultiplier = CultivationConfig.GetPowerMultiplier(realmTierEnum, order)
	end

	-- 2. Combat Physique Attributes
	local maxHp = humanoid and humanoid.MaxHealth or 100
	local poise = tonumber(char:GetAttribute("MaxPosture") or 100) or 100
	local intent = tonumber(char:GetAttribute("SwordIntent") or 100) or 100

	-- 3. Weapon & Forge Attributes
	local wepId = tostring(char:GetAttribute("EquippedWeapon") or "VoidStarCleaverDao")
	local wepDef = ItemConfig.GetItem(wepId)
	local wepDisplayName = wepDef and wepDef.Name or "Void Star Cleaver Dao"
	local baseDmg = wepDef and wepDef.Damage or 220
	local wepSpeed = wepDef and wepDef.Speed or 1.25
	local rarity = wepDef and wepDef.Rarity or "Mythic"

	-- Blacksmith Refinement
	local refineLevel = tonumber(char:GetAttribute("WeaponRefinement") or player:GetAttribute("WeaponRefinement") or 3) or 3
	local refineMult = 1.0 + (refineLevel * 0.05)
	local effectiveBaseDmg = math.floor(baseDmg * refineMult)
	local empoweredDmg = math.floor(effectiveBaseDmg * powerMultiplier)

	-- Whetstone Sharpening Status
	local sharpenedUntil = tonumber(char:GetAttribute("BladeSharpenedUntil") or 0) or 0
	local now = os.clock()
	local isSharpened = (sharpenedUntil > now)
	local remSec = math.max(0, math.floor(sharpenedUntil - now))
	local minLeft = math.floor(remSec / 60)
	local secLeft = remSec % 60
	local critChance = 5 + (if isSharpened then 10 else 0)

	----------------------------------------------------------------------------
	-- APPLY TO PANEL 1 (DAO REALM)
	----------------------------------------------------------------------------
	if p1DescLabels["Row_1"] then p1DescLabels["Row_1"].Text = string.format("%s (%s)", player.Name, sect) end
	if p1DescLabels["Row_2"] then p1DescLabels["Row_2"].Text = string.format("%s (Tier 1 Grounds)", sectRank) end
	if p1DescLabels["Row_3"] then p1DescLabels["Row_3"].Text = realmRaw end
	if p1DescLabels["Row_4"] then p1DescLabels["Row_4"].Text = string.format("%sx Total Output Multiplier", FormatComma(powerMultiplier)) end
	if p1DescLabels["Row_5"] then p1DescLabels["Row_5"].Text = string.format("%s (Cauldron Master)", alchemyRank) end
	if p1DescLabels["Row_6"] then p1DescLabels["Row_6"].Text = string.format("%s Stones • %s Sect CP", FormatComma(stones), FormatComma(cp)) end

	if qiTitle then
		qiTitle.Text = string.format("DANTIAN QI CAPACITY: %s / %s (GOAL FOR ORDER %d)", FormatNum(curQi), FormatNum(targetQi), math.clamp(order + 1, 1, 9))
	end
	if qiFill then
		local qRatio = math.clamp(curQi / math.max(1, targetQi), 0, 1)
		TweenService:Create(qiFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(qRatio, 0, 1, 0)
		}):Play()
	end

	----------------------------------------------------------------------------
	-- APPLY TO PANEL 2 (COMBAT STATS)
	----------------------------------------------------------------------------
	if p2DescLabels["Row_1"] then p2DescLabels["Row_1"].Text = string.format("%s Total Life Force (HP)", FormatComma(maxHp)) end
	if p2DescLabels["Row_2"] then p2DescLabels["Row_2"].Text = string.format("%d Max Posture (0.25s Perfect Parry Window)", poise) end
	if p2DescLabels["Row_3"] then p2DescLabels["Row_3"].Text = "18 Base Walk  •  44 studs/s High-Impact Sprint" end
	if p2DescLabels["Row_4"] then p2DescLabels["Row_4"].Text = "75 studs/s Omnidirectional 3D Hover & Glide" end
	if p2DescLabels["Row_5"] then p2DescLabels["Row_5"].Text = string.format("%d%% Maximum Intent Gauge (1.75x Damage Surge)", intent) end
	if p2DescLabels["Row_6"] then p2DescLabels["Row_6"].Text = string.format("%d%% Strike (5%% Base Trait%s)", critChance, if isSharpened then " + 10% Whetstone Buff" else "") end

	----------------------------------------------------------------------------
	-- APPLY TO PANEL 3 (SPIRIT WEAPON)
	----------------------------------------------------------------------------
	if p3DescLabels["Row_1"] then p3DescLabels["Row_1"].Text = string.format("%s (%s Grade)", wepDisplayName, rarity) end
	if p3DescLabels["Row_2"] then p3DescLabels["Row_2"].Text = string.format("%d Physical Strike Damage per Hit", baseDmg) end
	if p3DescLabels["Row_3"] then p3DescLabels["Row_3"].Text = string.format("%.2fx Fluid Swing Cadence", wepSpeed) end
	if p3DescLabels["Row_4"] then p3DescLabels["Row_4"].Text = string.format("+%d Refinement Grade (+%d%% Damage Multiplier)", refineLevel, refineLevel * 5) end
	if p3DescLabels["Row_5"] then p3DescLabels["Row_5"].Text = "+10 Maximum Refinement (+50% Output Cap)" end
	if p3DescLabels["Row_6"] then
		p3DescLabels["Row_6"].Text = if isSharpened
			then string.format("Active (+10%% Crit • %dm %02ds Remaining)", minLeft, secLeft)
			else "Inactive (Sharpen at Madame Tie's Anvil)"
	end

	----------------------------------------------------------------------------
	-- APPLY TO BOTTOM ACTION BANNER
	----------------------------------------------------------------------------
	if confirmBtn then
		confirmBtn.Text = string.format("TOTAL STRIKE OUTPUT: %s BASE • %s REALM EMPOWERED OUTPUT", FormatComma(effectiveBaseDmg), FormatComma(empoweredDmg))
	end
end

--------------------------------------------------------------------------------
-- OPEN / CLOSE MODAL
--------------------------------------------------------------------------------
function CharacterStatsController.Open()
	if not EnsureUI() then return end
	if gui then gui.Enabled = true end
	if backdrop then backdrop.Visible = true end

	CharacterStatsController.Refresh()
	CharacterStatsController.SwitchTab(activeTabIdx)
end

function CharacterStatsController.Close()
	if not EnsureUI() then return end
	if gui then gui.Enabled = false end
	if backdrop then backdrop.Visible = false end

	CharacterStatsController.Teardown3DViewport()
end

function CharacterStatsController.Toggle()
	if not EnsureUI() then return end
	if gui and gui.Enabled then
		CharacterStatsController.Close()
	else
		CharacterStatsController.Open()
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function CharacterStatsController.Init()
	EnsureUI()
	if gui then gui.Enabled = false end
	if backdrop then backdrop.Visible = false end

	-- "P" Key Toggle Listener
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if UserInputService:GetFocusedTextBox() ~= nil then return end

		if input.KeyCode == Enum.KeyCode.P then
			CharacterStatsController.Toggle()
		end
	end)

	-- Auto-refresh stats when character attributes update
	player.CharacterAdded:Connect(function(character)
		character:GetAttributeChangedSignal("Realm"):Connect(function()
			if gui and gui.Enabled then CharacterStatsController.Refresh() end
		end)
		character:GetAttributeChangedSignal("Qi"):Connect(function()
			if gui and gui.Enabled then CharacterStatsController.Refresh() end
		end)
		character:GetAttributeChangedSignal("WeaponRefinement"):Connect(function()
			if gui and gui.Enabled then CharacterStatsController.Refresh() end
		end)
		character:GetAttributeChangedSignal("BladeSharpenedUntil"):Connect(function()
			if gui and gui.Enabled then CharacterStatsController.Refresh() end
		end)
	end)

	print("[ASCEND] CharacterStatsController Initialized (Dynamic Data Binding Active on 'P').")
end

return CharacterStatsController