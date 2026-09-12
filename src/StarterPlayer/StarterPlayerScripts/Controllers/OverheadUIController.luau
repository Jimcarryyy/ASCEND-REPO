--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
    Handles:
      - Clean Xianxia ARPG Overhead Billboard GUIs exclusively for PLAYERS (NPCs/mobs ignored)
      - HP bars completely removed (tracked in Bottom-Left Vitals HUD)
      - Cultivation Realm & Order + Sect Rank display only (deduplicated order suffix)
      - Bangers font style with vibrant vertical text gradients and sharp black strokes
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)

local OverheadUIController = {}

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
local CFG = {
	BillboardSize = UDim2.new(0, 220, 0, 36),
	StudsOffset = Vector3.new(0, 2.8, 0),
	MaxDistance = 85,
}

--------------------------------------------------------------------------------
-- FORMATTERS
--------------------------------------------------------------------------------
local function GetFormattedRealm(character: Model, player: Player?): string
	local rawRealm = character:GetAttribute("Realm") or (player and player:GetAttribute("Realm"))
	local rawOrder = character:GetAttribute("Order") or (player and player:GetAttribute("Order"))

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

	if rawOrder then
		return string.format("%s - ORDER %s", realmName, tostring(rawOrder))
	end
	return realmName
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

	targetPlayer:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
	targetPlayer:GetAttributeChangedSignal("Order"):Connect(syncTitles)
	targetPlayer:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)

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
	print("[ASCEND] OverheadUIController Initialized (Bangers Font, Single-Order Title, Clean No-Bar Aesthetic).")
end

return OverheadUIController