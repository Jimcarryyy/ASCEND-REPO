--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
    Handles:
      - High-visibility Player & Mob Overhead Billboard GUIs
      - FredokaOne typography for Realm, Sect Rank, and HP numbers
      - 3-Stop 90° Emerald/Jade Gradient HP Bar with UICorner (30) and 2px White UIStroke
      - Dynamic Realm & Sect Rank Live Synchronization
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)

local OverheadUIController = {}
local LocalPlayer = Players.LocalPlayer

local UI_FONT = Enum.Font.Bangers
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

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

local function GetFormattedRealm(character: Model, player: Player?): string
	local raw = character:GetAttribute("Realm") or (player and player:GetAttribute("Realm"))
	if raw and type(raw) == "string" and raw ~= "" then
		return string.upper(raw)
	end
	return "QI CONDENSATION - ORDER 1"
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

local function AttachOverhead(character: Model, player: Player?)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not head or not humanoid then return end

	local existing = head:FindFirstChild("OverheadBillboard")
	if existing then existing:Destroy() end

	-- Enlarged billboard container for enhanced distance readability
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadBillboard"
	billboard.Size = UDim2.new(0, 210, 0, 58)
	billboard.StudsOffset = Vector3.new(0, 2.8, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 90
	billboard.Parent = head

	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1
	mainFrame.Parent = billboard

	-- 1. Realm / Order Title
	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmLabel"
	realmLabel.Size = UDim2.new(1, 0, 0, 18)
	realmLabel.Position = UDim2.new(0, 0, 0, 0)
	realmLabel.BackgroundTransparency = 1
	realmLabel.Font = UI_FONT
	realmLabel.TextSize = 16
	realmLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	realmLabel.Text = GetFormattedRealm(character, player)
	realmLabel.Parent = mainFrame

	local rStroke = Instance.new("UIStroke", realmLabel)
	rStroke.Color = Color3.fromRGB(15, 15, 20)
	rStroke.Thickness = 1.5

	-- 2. Sect Rank Title
	local rankLabel = Instance.new("TextLabel")
	rankLabel.Name = "RankLabel"
	rankLabel.Size = UDim2.new(1, 0, 0, 14)
	rankLabel.Position = UDim2.new(0, 0, 0, 18)
	rankLabel.BackgroundTransparency = 1
	rankLabel.Font = UI_FONT
	rankLabel.TextSize = 12
	rankLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
	rankLabel.Text = GetFormattedSectRank(character, player)
	rankLabel.Parent = mainFrame

	local sStroke = Instance.new("UIStroke", rankLabel)
	sStroke.Color = Color3.fromRGB(15, 15, 20)
	sStroke.Thickness = 1.2

	-- 3. Emerald Jade HP Bar Frame
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HPBackground"
	hpBg.Size = UDim2.new(1, 0, 0, 16)
	hpBg.Position = UDim2.new(0, 0, 0, 36)
	hpBg.BackgroundColor3 = Color3.fromRGB(16, 24, 20)
	hpBg.BorderSizePixel = 0
	hpBg.ClipsDescendants = true
	hpBg.Parent = mainFrame

	-- UICorner set to 30
	local bgCorner = Instance.new("UICorner", hpBg)
	bgCorner.CornerRadius = UDim.new(0, 30)

	-- 2px Solid White UIStroke Border
	local hpStroke = Instance.new("UIStroke", hpBg)
	hpStroke.Name = "HPStroke"
	hpStroke.Color = Color3.fromRGB(255, 255, 255)
	hpStroke.Thickness = 2.0
	hpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

	-- HP Fill Frame
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HPFill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	local fillCorner = Instance.new("UICorner", hpFill)
	fillCorner.CornerRadius = UDim.new(0, 30)

	-- 3-Stop 90° Gradient: Bright Emerald (0) -> Vibrant Jade (0.5) -> Deep Jade (1.0)
	local greenGrad = Instance.new("UIGradient")
	greenGrad.Rotation = 90
	greenGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(74, 222, 128)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(34, 197, 94)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(21, 128, 61)),
	})
	greenGrad.Parent = hpFill

	-- HP Text Label
	local hpText = Instance.new("TextLabel")
	hpText.Name = "HPText"
	hpText.Size = UDim2.new(1, 0, 1, 0)
	hpText.BackgroundTransparency = 1
	hpText.Font = UI_FONT
	hpText.TextSize = 11.5
	hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpText.Text = "100 / 100"
	hpText.ZIndex = 3
	hpText.Parent = hpBg

	local textStroke = Instance.new("UIStroke", hpText)
	textStroke.Color = Color3.fromRGB(10, 10, 15)
	textStroke.Thickness = 1.2

	local function syncHP()
		local cur = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
		local max = math.max(1, humanoid.MaxHealth)
		local ratio = cur / max
		TweenService:Create(hpFill, TWEEN_INFO, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		hpText.Text = string.format("%s / %s", FormatNum(cur), FormatNum(max))
	end

	local function syncTitles()
		realmLabel.Text = GetFormattedRealm(character, player)
		rankLabel.Text = GetFormattedSectRank(character, player)
	end

	humanoid:GetPropertyChangedSignal("Health"):Connect(syncHP)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(syncHP)
	syncHP()

	character:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
	character:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)
	if player then
		player:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
		player:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)
	end
	syncTitles()
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
	for _, player in ipairs(Players:GetPlayers()) do
		OnPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(OnPlayerAdded)
	print("[ASCEND] OverheadUIController Initialized (FredokaOne & 3-Stop 90° Gradient HP Active).")
end

return OverheadUIController