--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
    Handles:
      - Clean Xianxia ARPG Overhead Billboard GUIs exclusively for PLAYERS (NPCs/mobs ignored)
      - HP bars completely removed (tracked in Bottom-Left Vitals HUD)
      - Cultivation Realm & Order + Sect Rank display only (deduplicated order suffix)
      - Phase 5: Dynamic [SAMSARA I], [SAMSARA II] prefix title rendering with Radiant Sun Gold styling
      - Bangers font style with vibrant vertical text gradients and sharp black strokes
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)


local function FormatNum(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	else
		return tostring(math.floor(num))
	end
end

local function SpawnQiPopup(character: Model, delta: number)
	local head = character:FindFirstChild("Head") :: BasePart?
	if not head then return end

	local rawRealm = character:GetAttribute("Realm") or "QiCondensation"
	local info = CultivationConfig and (CultivationConfig :: any)[rawRealm]
	local realmColor = if info and info.AuraColor then info.AuraColor else Color3.fromRGB(150, 240, 255)

	-- Offset high above head so it clears the 2.8 stud Overhead titles completely
	local randX = (math.random() - 0.5) * 2.2
	local randZ = (math.random() - 0.5) * 2.2
	local startOffset = Vector3.new(randX, 4.6, randZ)

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "QiPopupBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(0, 240, 0, 48)
	billboard.StudsOffset = startOffset
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 110
	billboard.Parent = head

	-- PURE TEXTLABEL (Bigger & Bolder Fondamento)
	local label = Instance.new("TextLabel")
	label.Name = "QiGainLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("+%s Qi", FormatNum(delta))
	label.FontFace = Font.fromName("Bangers", Enum.FontWeight.Bold)
	label.Font = Enum.Font.BangersBangers
	label.TextSize = 28
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = billboard

	local grad = Instance.new("UIGradient")
	grad.Rotation = -35
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.45, realmColor),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 255, 255)),
	})
	grad.Parent = label

	-- Thick, heavy outline for high visibility
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1.0
	stroke.Color = Color3.fromRGB(10, 15, 25)
	stroke.Transparency = 0.05
	stroke.Parent = label

	local duration = 0.85
	local riseTween = TweenService:Create(billboard, TweenInfo.new(duration, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		StudsOffset = startOffset + Vector3.new(0, 2.4, 0)
	})
	local fadeTween = TweenService:Create(label, TweenInfo.new(duration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1
	})
	local strokeFade = TweenService:Create(stroke, TweenInfo.new(duration * 0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Transparency = 1
	})

	riseTween:Play()
	task.delay(duration * 0.45, function()
		if label.Parent then
			fadeTween:Play()
			strokeFade:Play()
		end
	end)

	Debris:AddItem(billboard, duration + 0.1)
end

local OverheadUIController = {}

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
local CFG = {
	BillboardSize = UDim2.new(0, 240, 0, 38),
	StudsOffset = Vector3.new(0, 2.8, 0),
	MaxDistance = 85,
}

local function ToRoman(num: number): string
	local romanNumerals = {
		{ 10, "X" }, { 9, "IX" }, { 5, "V" }, { 4, "IV" }, { 1, "I" }
	}
	local result = ""
	local remaining = num
	for _, pair in ipairs(romanNumerals) do
		local val, sym = pair[1], pair[2]
		while remaining >= val do
			result ..= sym
			remaining -= val
		end
	end
	return if result ~= "" then result else "I"
end

--------------------------------------------------------------------------------
-- FORMATTERS
--------------------------------------------------------------------------------
local function GetFormattedRealm(character: Model, player: Player?): string
	local rawRealm = character:GetAttribute("Realm") or (player and player:GetAttribute("Realm"))
	local rawOrder = character:GetAttribute("Order") or (player and player:GetAttribute("Order"))
	local samsaraCycle = character:GetAttribute("SamsaraCycle") or (player and player:GetAttribute("SamsaraCycle")) or 0

	local realmName = "QI CONDENSATION"
	if rawRealm and type(rawRealm) == "string" then
		local info = CultivationConfig and (CultivationConfig :: any)[rawRealm]
		if info and info.DisplayName then
			realmName = string.upper(info.DisplayName)
		else
			realmName = string.upper(rawRealm)
		end
	end

	-- Deduplication: Strip any existing order tags (e.g. "- ORDER 2" or "ORDER 2") before appending
	realmName = realmName:gsub("%s*[-–]?%s*ORDER%s*%d+", ""):gsub("%s*[-–]%s*$", "")

	local formatted = if rawOrder then string.format("%s - ORDER %s", realmName, tostring(rawOrder)) else realmName
	local cycleNum = tonumber(samsaraCycle) or 0
	if cycleNum > 0 then
		formatted = string.format("[SAMSARA %s] %s", ToRoman(cycleNum), formatted)
	end
	return formatted
end

local function GetFormattedSectRank(character: Model, player: Player?): string
	local rawRank = character:GetAttribute("SectRank") or (player and player:GetAttribute("SectRank"))
	if rawRank and type(rawRank) == "string" then
		if SectConfig and SectConfig.GetRank then
			local def = SectConfig.GetRank(rawRank :: any)
			if def and def.DisplayName then
				return string.upper(def.DisplayName)
			end
		end
		return string.upper(rawRank)
	end
	return "INNER DISCIPLE"
end

--------------------------------------------------------------------------------
-- ATTACH OVERHEAD (PLAYERS ONLY)
--------------------------------------------------------------------------------
local function AttachOverhead(character: Model, player: Player?)
	local targetPlayer = player or Players:GetPlayerFromCharacter(character)
	if not targetPlayer then return end

	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then return end

	local existing = head:FindFirstChild("OverheadBillboard")
	if existing then existing:Destroy() end

	-- 1. Billboard Setup
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadBillboard"
	billboard.Size = CFG.BillboardSize
	billboard.StudsOffset = CFG.StudsOffset
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = CFG.MaxDistance
	billboard.Parent = head

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = billboard

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 0)
	listLayout.Parent = mainFrame

	-- 2. Realm & Order Label (Bangers, Vibrant Radiant Sun Gold Gradient)
	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmLabel"
	realmLabel.Size = UDim2.new(1, 0, 0, 18)
	realmLabel.LayoutOrder = 1
	realmLabel.BackgroundTransparency = 1
	realmLabel.Font = Enum.Font.Bangers
	realmLabel.TextSize = 16
	realmLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	realmLabel.Text = GetFormattedRealm(character, targetPlayer)
	realmLabel.TextXAlignment = Enum.TextXAlignment.Center
	realmLabel.TextYAlignment = Enum.TextYAlignment.Center
	realmLabel.Parent = mainFrame

	local rStroke = Instance.new("UIStroke")
	rStroke.Color = Color3.fromRGB(0, 0, 0)
	rStroke.Thickness = 1.6
	rStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	rStroke.Parent = realmLabel

	local goldGrad = Instance.new("UIGradient")
	goldGrad.Name = "GoldGradient"
	goldGrad.Rotation = 90
	goldGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 245, 160)), -- Radiant Sun Gold
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 185, 20)),  -- Vibrant Amber Gold
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(245, 130, 10)),  -- Deep Golden Flame
	})
	goldGrad.Parent = realmLabel

	-- 3. Sect Rank Label (Bangers, Luminous Spirit Silver-Cyan Gradient)
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, 0, 0, 14)
	rankLabel.LayoutOrder = 2
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = Enum.Font.Bangers
	rankLabel.TextSize = 13
	rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rankLabel.Text = GetFormattedSectRank(character, targetPlayer)
	rankLabel.TextXAlignment = Enum.TextXAlignment.Center
	rankLabel.TextYAlignment = Enum.TextYAlignment.Center
	rankLabel.Parent = mainFrame

	local sStroke = Instance.new("UIStroke")
	sStroke.Color = Color3.fromRGB(0, 0, 0)
	sStroke.Thickness = 1.4
	sStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	sStroke.Parent = rankLabel

	local silverGrad = Instance.new("UIGradient")
	silverGrad.Name = "SilverGradient"
	silverGrad.Rotation = 90
	silverGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(245, 250, 255)), -- Pure Luminous White
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200, 230, 250)), -- Celestial Spirit Silver
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(140, 195, 235)), -- Soft Azure Glow
	})
	silverGrad.Parent = rankLabel

	----------------------------------------------------------------------------
	-- LIVE TITLE SYNCHRONIZATION
	----------------------------------------------------------------------------
	local function syncTitles()
		realmLabel.Text = GetFormattedRealm(character, targetPlayer)
		rankLabel.Text = GetFormattedSectRank(character, targetPlayer)
	end

	character:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
	character:GetAttributeChangedSignal("Order"):Connect(syncTitles)
	character:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)
	character:GetAttributeChangedSignal("SamsaraCycle"):Connect(syncTitles)

	targetPlayer:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
	targetPlayer:GetAttributeChangedSignal("Order"):Connect(syncTitles)
	targetPlayer:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)
	targetPlayer:GetAttributeChangedSignal("SamsaraCycle"):Connect(syncTitles)

		syncTitles()

	-- Live Meditation Qi Gain Listener
	local lastMaxQi = character:GetAttribute("MaxQi") or 0
	character:GetAttributeChangedSignal("MaxQi"):Connect(function()
		local cur = (character:GetAttribute("MaxQi") :: number?) or 0
		local delta = cur - lastMaxQi
		lastMaxQi = cur
		local isMeditating = (character:GetAttribute("IsMeditating") == true)
		if isMeditating and delta > 0 then
			SpawnQiPopup(character, delta)
		end
	end)
end

local function OnPlayerAdded(player: Player)
	if player.Character then
		AttachOverhead(player.Character, player)
	end
	player.CharacterAdded:Connect(function(char)
		AttachOverhead(char, player)
	end)
end

function OverheadUIController.Init()
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("BillboardGui") and desc.Name == "OverheadBillboard" then
			local char = desc.Parent and desc.Parent.Parent
			if not (char and char:IsA("Model") and Players:GetPlayerFromCharacter(char)) then
				desc:Destroy()
			end
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		OnPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(OnPlayerAdded)
	print("[ASCEND] OverheadUIController Initialized (Bangers Font, Samsara Titles & Clean No-Bar Aesthetic).")
end

return OverheadUIController