--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
    Handles:
      - Sleek ARPG Overhead Billboard GUIs exclusively for PLAYERS (NPCs/mobs ignored)
      - Fredoka One font across all labels (Realm, Rank, and HP numbers)
      - Numbers centered directly on top of the HP bar
      - Thin rectangular Jade Gradient Health Bar with 1px dark border
      - Qi/Mana bar removed (HP bar only)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)

local OverheadUIController = {}
local LocalPlayer = Players.LocalPlayer

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
-- CONFIGURATION
--------------------------------------------------------------------------------
local CFG = {
    BillboardSize = UDim2.new(0, 180, 0, 48),
    StudsOffset = Vector3.new(0, 3.2, 0),
    MaxDistance = 85,

    -- Bar geometry (sleek thin profile, rectangular with 1px micro-bevel)
    BarWidth = 140,
    BarHeight = 11,
    CornerRadius = 1,
    BorderThickness = 1,
    BorderColor = Color3.fromRGB(45, 52, 62),   -- Dark slate border
    TrackColor = Color3.fromRGB(18, 22, 28),     -- Dark translucent track
    TrackTransparency = 0.25,

    -- 3-stop Celestial Jade Green Gradient
    HealthGradient = {
        ColorSequenceKeypoint.new(0.0, Color3.fromRGB(74, 222, 128)), -- Luminous Jade (#4ADE80)
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(34, 197, 94)),  -- Vibrant Jade (#22C55E)
        ColorSequenceKeypoint.new(1.0, Color3.fromRGB(16, 128, 67)),  -- Deep Forest Jade (#108043)
    },

    -- Set to true to center numbers ON the bar; false to float them above
    TEXT_ON_BAR = true,
}

--------------------------------------------------------------------------------
-- FORMATTERS
--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
-- ATTACH OVERHEAD (PLAYERS ONLY)
--------------------------------------------------------------------------------
local function AttachOverhead(character: Model, player: Player?)
    -- 1. STRICT PLAYER FILTER: Discard NPCs, dummies, and mob models
    local targetPlayer = player or Players:GetPlayerFromCharacter(character)
    if not targetPlayer then
        return
    end

    local head = character:WaitForChild("Head", 5) :: BasePart?
    local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
    if not head or not humanoid then return end

    local existing = head:FindFirstChild("OverheadBillboard")
    if existing then existing:Destroy() end

    -- 2. Billboard Setup
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
    mainFrame.Parent = billboard

    -- 3. Realm / Order Label (Fredoka One, Amber Gold)
    local realmLabel = Instance.new("TextLabel")
    realmLabel.Name = "RealmLabel"
    realmLabel.Size = UDim2.new(1, 0, 0, 16)
    realmLabel.Position = UDim2.new(0, 0, 0, 0)
    realmLabel.BackgroundTransparency = 1
    realmLabel.Font = Enum.Font.FredokaOne
    realmLabel.TextSize = 15
    realmLabel.TextColor3 = Color3.fromRGB(255, 195, 0)
    realmLabel.Text = GetFormattedRealm(character, targetPlayer)
    realmLabel.Parent = mainFrame

    local rStroke = Instance.new("UIStroke", realmLabel)
    rStroke.Color = Color3.fromRGB(15, 15, 20)
    rStroke.Thickness = 1.2

    -- 4. Sect Rank Label (Fredoka One, Antique White)
    local rankLabel = Instance.new("TextLabel")
    rankLabel.Name = "RankLabel"
    rankLabel.Size = UDim2.new(1, 0, 0, 13)
    rankLabel.Position = UDim2.new(0, 0, 0, 16)
    rankLabel.BackgroundTransparency = 1
    rankLabel.Font = Enum.Font.FredokaOne
    rankLabel.TextSize = 11
    rankLabel.TextColor3 = Color3.fromRGB(225, 230, 235)
    rankLabel.Text = GetFormattedSectRank(character, targetPlayer)
    rankLabel.Parent = mainFrame

    local sStroke = Instance.new("UIStroke", rankLabel)
    sStroke.Color = Color3.fromRGB(15, 15, 20)
    sStroke.Thickness = 1.0

    -- 5. Main Health Bar Track (Thin & Rectangular, Centered)
    local barPosY = if CFG.TEXT_ON_BAR then 32 else 40
    local hpBg = Instance.new("Frame")
    hpBg.Name = "HPBackground"
    hpBg.Size = UDim2.new(0, CFG.BarWidth, 0, CFG.BarHeight)
    hpBg.Position = UDim2.new(0.5, -math.floor(CFG.BarWidth / 2), 0, barPosY)
    hpBg.BackgroundColor3 = CFG.TrackColor
    hpBg.BackgroundTransparency = CFG.TrackTransparency
    hpBg.BorderSizePixel = 0
    hpBg.ClipsDescendants = true
    hpBg.Parent = mainFrame

    local bgCorner = Instance.new("UICorner", hpBg)
    bgCorner.CornerRadius = UDim.new(0, CFG.CornerRadius)

    local hpStroke = Instance.new("UIStroke", hpBg)
    hpStroke.Name = "HPStroke"
    hpStroke.Color = CFG.BorderColor
    hpStroke.Thickness = CFG.BorderThickness
    hpStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

    -- Health Fill Frame
    local hpFill = Instance.new("Frame")
    hpFill.Name = "HPFill"
    hpFill.Size = UDim2.new(1, 0, 1, 0)
    hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    hpFill.BorderSizePixel = 0
    hpFill.Parent = hpBg

    local fillCorner = Instance.new("UICorner", hpFill)
    fillCorner.CornerRadius = UDim.new(0, CFG.CornerRadius)

    local greenGrad = Instance.new("UIGradient")
    greenGrad.Rotation = 0
    greenGrad.Color = ColorSequence.new(CFG.HealthGradient)
    greenGrad.Parent = hpFill

    -- 6. Numeric HP Readout (Fredoka One, Centered directly ON TOP of the HP Bar)
    local hpText = Instance.new("TextLabel")
    hpText.Name = "HPText"
    hpText.BackgroundTransparency = 1
    hpText.Font = Enum.Font.FredokaOne
    hpText.TextSize = 10
    hpText.TextColor3 = Color3.fromRGB(255, 255, 255)
    hpText.Text = "100 / 100"

    if CFG.TEXT_ON_BAR then
        hpText.Size = UDim2.new(1, 0, 1, 0)
        hpText.Position = UDim2.new(0, 0, 0, 0)
        hpText.ZIndex = 3
        hpText.Parent = hpBg
    else
        hpText.Size = UDim2.new(1, 0, 0, 11)
        hpText.Position = UDim2.new(0, 0, 0, 28)
        hpText.Parent = mainFrame
    end

    local hpTextStroke = Instance.new("UIStroke", hpText)
    hpTextStroke.Color = Color3.fromRGB(15, 15, 20)
    hpTextStroke.Thickness = 1.0

    ----------------------------------------------------------------------------
    -- LIVE HEALTH & TITLE SYNCHRONIZATION
    ----------------------------------------------------------------------------
    local function syncHP()
        local cur = math.clamp(humanoid.Health, 0, humanoid.MaxHealth)
        local max = math.max(1, humanoid.MaxHealth)
        local ratio = cur / max
        TweenService:Create(hpFill, TWEEN_INFO, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
        hpText.Text = string.format("%s / %s", FormatNum(cur), FormatNum(max))
    end

    local function syncTitles()
        realmLabel.Text = GetFormattedRealm(character, targetPlayer)
        rankLabel.Text = GetFormattedSectRank(character, targetPlayer)
    end

    humanoid:GetPropertyChangedSignal("Health"):Connect(syncHP)
    humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(syncHP)
    syncHP()

    character:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
    character:GetAttributeChangedSignal("SectRank"):Connect(syncTitles)
    targetPlayer:GetAttributeChangedSignal("Realm"):Connect(syncTitles)
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
    -- 1. Purge rogue billboards on non-player rigs
    for _, desc in ipairs(Workspace:GetDescendants()) do
        if desc:IsA("BillboardGui") and desc.Name == "OverheadBillboard" then
            local char = desc.Parent and desc.Parent.Parent
            if not (char and char:IsA("Model") and Players:GetPlayerFromCharacter(char)) then
                desc:Destroy()
            end
        end
    end

    -- 2. Bind exclusively to players
    for _, player in ipairs(Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
    Players.PlayerAdded:Connect(OnPlayerAdded)
    print("[ASCEND] OverheadUIController Initialized (Fredoka One, On-Bar HP, Qi Bar Removed).")
end

return OverheadUIController