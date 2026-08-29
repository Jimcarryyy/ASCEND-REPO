--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
    Real-time Dynamic Overhead HUD Engine for ASCEND:
    - Font: Bangers across all 4 tiers (Realm, Sect Rank, HP, Qi)
    - Sizing: Realm (17pt), Sect Rank (14pt), Thicker HP/Qi Bars & Numbers
    - Live synced Realm & Order directly from Character attributes
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)

local OverheadUIController = {}

local OVERHEAD_FONT = Enum.Font.Bangers
local BAR_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MAX_VIEW_DISTANCE = 85

local function FormatRealmString(rawRealm: any): string
	if type(rawRealm) == "string" and rawRealm ~= "" then
		local clean = rawRealm:gsub("·", ""):gsub("—", "-"):gsub("%s*-%s*", " - ")
		clean = clean:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		return clean
	end
	return "Qi Condensation - Order 1"
end

local function FormatSectRankString(rawRank: any): string
	if type(rawRank) == "string" and rawRank ~= "" then
		local rankMap: { [string]: string } = {
			["OuterDisciple"] = "Outer Disciple",
			["InnerDisciple"] = "Inner Disciple",
			["CoreDisciple"] = "Core Disciple",
			["Elder"] = "Sect Elder",
			["GrandElder"] = "Grand Elder",
			["Patriarch"] = "Sect Patriarch",
		}
		return rankMap[rawRank] or rawRank
	end
	return "Outer Disciple"
end

local function CreateOverheadGui(character: Model, player: Player): BillboardGui?
	local head = character:WaitForChild("Head", 5) :: BasePart?
	if not head then return nil end

	local existing = head:FindFirstChild("PlayerOverheadUI")
	if existing then existing:Destroy() end

	-- Master Billboard (Upscaled for larger Bangers text)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "PlayerOverheadUI"
	billboard.Size = UDim2.new(0, 205, 0, 74)
	billboard.StudsOffset = Vector3.new(0, 3.6, 0)
	billboard.MaxDistance = MAX_VIEW_DISTANCE
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false
	billboard.LightInfluence = 0
	billboard.Parent = head

	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	local listLayout = Instance.new("UIListLayout")
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayout.Padding = UDim.new(0, 2)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = container

	-- 1. Tier 1: Realm & Order (Font: Bangers, Size: 17)
	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmLabel"
	realmLabel.LayoutOrder = 1
	realmLabel.Size = UDim2.new(1, 0, 0, 20)
	realmLabel.BackgroundTransparency = 1
	realmLabel.Font = OVERHEAD_FONT
	realmLabel.TextSize = 17
	realmLabel.TextColor3 = Color3.fromRGB(255, 220, 115)
	realmLabel.Text = FormatRealmString(character:GetAttribute("Realm") or player:GetAttribute("Realm"))
	realmLabel.Parent = container

	local realmStroke = Instance.new("UIStroke")
	realmStroke.Color = Color3.fromRGB(20, 15, 10)
	realmStroke.Thickness = 1.4
	realmStroke.Transparency = 0.1
	realmStroke.Parent = realmLabel

	-- 2. Tier 2: Sect Rank (Font: Bangers, Size: 14)
	local sectLabel = Instance.new("TextLabel")
	sectLabel.Name = "SectLabel"
	sectLabel.LayoutOrder = 2
	sectLabel.Size = UDim2.new(1, 0, 0, 16)
	sectLabel.BackgroundTransparency = 1
	sectLabel.Font = OVERHEAD_FONT
	sectLabel.TextSize = 14
	sectLabel.TextColor3 = Color3.fromRGB(215, 225, 235)
	sectLabel.Text = FormatSectRankString(character:GetAttribute("SectRank") or player:GetAttribute("SectRank"))
	sectLabel.Parent = container

	local sectStroke = Instance.new("UIStroke")
	sectStroke.Color = Color3.fromRGB(15, 18, 25)
	sectStroke.Thickness = 1.2
	sectStroke.Transparency = 0.2
	sectStroke.Parent = sectLabel

	-- 3. Tier 3: Enlarged Health Bar (12px Height)
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HPBackground"
	hpBg.LayoutOrder = 3
	hpBg.Size = UDim2.new(1, 0, 0, 12)
	hpBg.BackgroundColor3 = Color3.fromRGB(25, 8, 10)
	hpBg.BorderSizePixel = 0
	hpBg.ClipsDescendants = true
	hpBg.Parent = container

	local hpCorner = Instance.new("UICorner")
	hpCorner.CornerRadius = UDim.new(0, 4)
	hpCorner.Parent = hpBg

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = Color3.fromRGB(12, 12, 14)
	hpStroke.Thickness = 1.2
	hpStroke.Parent = hpBg

	local hpFill = Instance.new("Frame")
	hpFill.Name = "Fill"
	hpFill.Size = UDim2.new(1, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	local hpFillCorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0, 4)
	hpFillCorner.Parent = hpFill

	local hpGradient = Instance.new("UIGradient")
	hpGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(215, 35, 45)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(140, 15, 25)),
	})
	hpGradient.Parent = hpFill

	local hpNumberLabel = Instance.new("TextLabel")
	hpNumberLabel.Name = "HPNumberLabel"
	hpNumberLabel.Size = UDim2.new(1, 0, 1, 0)
	hpNumberLabel.BackgroundTransparency = 1
	hpNumberLabel.Font = OVERHEAD_FONT
	hpNumberLabel.TextSize = 10.5
	hpNumberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	hpNumberLabel.Text = "100 / 100"
	hpNumberLabel.ZIndex = 5
	hpNumberLabel.Parent = hpBg

	local hpNumStroke = Instance.new("UIStroke")
	hpNumStroke.Color = Color3.fromRGB(15, 10, 10)
	hpNumStroke.Thickness = 1.1
	hpNumStroke.Parent = hpNumberLabel

	-- 4. Tier 4: Enlarged Qi Bar (10px Height)
	local qiBg = Instance.new("Frame")
	qiBg.Name = "QiBackground"
	qiBg.LayoutOrder = 4
	qiBg.Size = UDim2.new(1, 0, 0, 10)
	qiBg.BackgroundColor3 = Color3.fromRGB(8, 16, 25)
	qiBg.BorderSizePixel = 0
	qiBg.ClipsDescendants = true
	qiBg.Parent = container

	local qiCorner = Instance.new("UICorner")
	qiCorner.CornerRadius = UDim.new(0, 4)
	qiCorner.Parent = qiBg

	local qiStroke = Instance.new("UIStroke")
	qiStroke.Color = Color3.fromRGB(10, 12, 16)
	qiStroke.Thickness = 1.2
	qiStroke.Parent = qiBg

	local qiFill = Instance.new("Frame")
	qiFill.Name = "Fill"
	qiFill.Size = UDim2.new(1, 0, 1, 0)
	qiFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	qiFill.BorderSizePixel = 0
	qiFill.Parent = qiBg

	local qiFillCorner = Instance.new("UICorner")
	qiFillCorner.CornerRadius = UDim.new(0, 4)
	qiFillCorner.Parent = qiFill

	local qiGradient = Instance.new("UIGradient")
	qiGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 235, 255)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(40, 160, 240)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 90, 195)),
	})
	qiGradient.Parent = qiFill

	local qiNumberLabel = Instance.new("TextLabel")
	qiNumberLabel.Name = "QINumberLabel"
	qiNumberLabel.Size = UDim2.new(1, 0, 1, 0)
	qiNumberLabel.BackgroundTransparency = 1
	qiNumberLabel.Font = OVERHEAD_FONT
	qiNumberLabel.TextSize = 9.5
	qiNumberLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	qiNumberLabel.Text = "100 / 100"
	qiNumberLabel.ZIndex = 5
	qiNumberLabel.Parent = qiBg

	local qiNumStroke = Instance.new("UIStroke")
	qiNumStroke.Color = Color3.fromRGB(10, 15, 20)
	qiNumStroke.Thickness = 1.1
	qiNumStroke.Parent = qiNumberLabel

	return billboard
end

local function BindCharacter(character: Model)
	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	local humanoid = character:WaitForChild("Humanoid", 6) :: Humanoid?
	if not humanoid then return end

	local billboard = CreateOverheadGui(character, player)
	if not billboard then return end

	local container = billboard:WaitForChild("Container") :: Frame
	local realmLabel = container:WaitForChild("RealmLabel") :: TextLabel
	local sectLabel = container:WaitForChild("SectLabel") :: TextLabel
	local hpBg = container:WaitForChild("HPBackground") :: Frame
	local hpFill = hpBg:WaitForChild("Fill") :: Frame
	local hpNumberLabel = hpBg:WaitForChild("HPNumberLabel") :: TextLabel

	local qiBg = container:WaitForChild("QiBackground") :: Frame
	local qiFill = qiBg:WaitForChild("Fill") :: Frame
	local qiNumberLabel = qiBg:WaitForChild("QINumberLabel") :: TextLabel

	local function UpdateHealth()
		local hp = humanoid.Health
		local maxHp = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(hp / maxHp, 0, 1)

		TweenService:Create(hpFill, BAR_TWEEN_INFO, {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()

		hpNumberLabel.Text = string.format("%s / %s", CultivationConfig.FormatNumber(hp), CultivationConfig.FormatNumber(maxHp))
	end
	UpdateHealth()
	local hpConn = humanoid.HealthChanged:Connect(UpdateHealth)
	local maxHpConn = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(UpdateHealth)

	local function UpdateQi()
		local currentQi = tonumber(character:GetAttribute("Qi") or player:GetAttribute("CultivatedQi") or player:GetAttribute("Qi") or 100) or 100
		local maxQi = tonumber(character:GetAttribute("MaxQi") or player:GetAttribute("MaxQi") or 100) or 100
		local ratio = math.clamp(currentQi / math.max(maxQi, 1), 0, 1)

		TweenService:Create(qiFill, BAR_TWEEN_INFO, {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()

		qiNumberLabel.Text = string.format("%s / %s", CultivationConfig.FormatNumber(currentQi), CultivationConfig.FormatNumber(maxQi))
	end
	UpdateQi()

	local qiCharConn = character:GetAttributeChangedSignal("Qi"):Connect(UpdateQi)
	local qiMaxConn = character:GetAttributeChangedSignal("MaxQi"):Connect(UpdateQi)
	local qiPlrConn = player:GetAttributeChangedSignal("CultivatedQi"):Connect(UpdateQi)

	local function UpdateRealm()
		local rawRealm = character:GetAttribute("Realm") or player:GetAttribute("Realm")
		realmLabel.Text = FormatRealmString(rawRealm)
	end
	UpdateRealm()
	local realmConn = character:GetAttributeChangedSignal("Realm"):Connect(UpdateRealm)
	local playerRealmConn = player:GetAttributeChangedSignal("Realm"):Connect(UpdateRealm)

	local function UpdateSectRank()
		local rawRank = character:GetAttribute("SectRank") or player:GetAttribute("SectRank") or player:GetAttribute("Rank")
		sectLabel.Text = FormatSectRankString(rawRank)
	end
	UpdateSectRank()
	local sectConn = character:GetAttributeChangedSignal("SectRank"):Connect(UpdateSectRank)
	local playerSectConn = player:GetAttributeChangedSignal("SectRank"):Connect(UpdateSectRank)

	humanoid.Died:Once(function()
		hpConn:Disconnect()
		maxHpConn:Disconnect()
		qiCharConn:Disconnect()
		qiMaxConn:Disconnect()
		qiPlrConn:Disconnect()
		realmConn:Disconnect()
		playerRealmConn:Disconnect()
		sectConn:Disconnect()
		playerSectConn:Disconnect()
	end)
end

function OverheadUIController.Init()
	local function HookPlayer(player: Player)
		if player.Character then
			task.spawn(BindCharacter, player.Character)
		end
		player.CharacterAdded:Connect(function(char)
			task.spawn(BindCharacter, char)
		end)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		HookPlayer(player)
	end
	Players.PlayerAdded:Connect(HookPlayer)

	print("[ASCEND] OverheadUIController Initialized (All Bangers Typography Active).")
end

return OverheadUIController