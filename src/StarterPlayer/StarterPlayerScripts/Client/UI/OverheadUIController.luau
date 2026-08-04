--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Client/UI/OverheadUIController.luau
    Purpose: Manages 3D Overhead Display for OTHER players and world NPCs/Dummies.
    Skips local player to prevent screen clutter.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local OverheadUIController = {}
local isInitialized = false
local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Color Palette for ASCEND Theme
local COLOR_HEALTH_FILL = Color3.fromRGB(46, 204, 113)  -- Emerald Health Green
local COLOR_QI_FILL = Color3.fromRGB(0, 180, 255)       -- Azure Spirit Qi
local COLOR_BAR_BG = Color3.fromRGB(20, 20, 28)        -- Dark Obsidian Background

local overheadTemplate: BillboardGui?

--------------------------------------------------------------------------------
-- PRIVATE HELPER FUNCTIONS
--------------------------------------------------------------------------------

local function getOverheadTemplate(): BillboardGui?
	if overheadTemplate then
		return overheadTemplate
	end

	local foundDirect = ReplicatedStorage:FindFirstChild("OverheadBillboardGui") :: BillboardGui?
	if foundDirect then
		overheadTemplate = foundDirect
		return overheadTemplate
	end

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if sharedFolder then
		local foundShared = sharedFolder:FindFirstChild("OverheadBillboardGui") :: BillboardGui?
		if foundShared then
			overheadTemplate = foundShared
			return overheadTemplate
		end
	end

	return nil
end

local function attachOverheadToCharacter(character: Model)
	local targetPlayer = Players:GetPlayerFromCharacter(character)
	local localPlayer = Players.LocalPlayer

	-- 🚀 SKIP LOCAL PLAYER: Local player stats are handled by the Bottom HUD Panel!
	if targetPlayer and targetPlayer == localPlayer then
		return
	end

	local head = character:WaitForChild("Head", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not head or not humanoid then return end

	-- Destroy old billboard if re-attaching
	local existing = head:FindFirstChild("OverheadBillboardGui")
	if existing then
		existing:Destroy()
	end

	local template = getOverheadTemplate()
	local overheadGui: BillboardGui

	if template then
		overheadGui = template:Clone()
	else
		-- Programmatic Fallback Creation
		overheadGui = Instance.new("BillboardGui")
		overheadGui.Name = "OverheadBillboardGui"
		overheadGui.Size = UDim2.new(5, 0, 2.2, 0)

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "PlayerNameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
		nameLabel.Position = UDim2.new(0, 0, 0, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		nameLabel.TextStrokeTransparency = 0
		nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		nameLabel.TextScaled = true
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = character.Name
		nameLabel.Parent = overheadGui

		-- Health Bar Setup
		local healthBg = Instance.new("Frame")
		healthBg.Name = "HealthBarBackground"
		healthBg.Size = UDim2.new(1, 0, 0.28, 0)
		healthBg.Position = UDim2.new(0, 0, 0.38, 0)
		healthBg.BackgroundColor3 = COLOR_BAR_BG
		healthBg.BorderSizePixel = 0
		healthBg.Parent = overheadGui

		local healthFill = Instance.new("Frame")
		healthFill.Name = "HealthBarFill"
		healthFill.Size = UDim2.new(1, 0, 1, 0)
		healthFill.BackgroundColor3 = COLOR_HEALTH_FILL
		healthFill.BorderSizePixel = 0
		healthFill.ZIndex = 2
		healthFill.Parent = healthBg

		local healthText = Instance.new("TextLabel")
		healthText.Name = "HealthText"
		healthText.Size = UDim2.new(1, 0, 1, 0)
		healthText.BackgroundTransparency = 1
		healthText.TextColor3 = Color3.fromRGB(255, 255, 255)
		healthText.TextStrokeTransparency = 0.3
		healthText.TextScaled = true
		healthText.ZIndex = 3
		healthText.Font = Enum.Font.GothamMedium
		healthText.Text = "HP: 100 / 100"
		healthText.Parent = healthBg

		-- Qi Bar Setup
		local qiBg = Instance.new("Frame")
		qiBg.Name = "QiBarBackground"
		qiBg.Size = UDim2.new(1, 0, 0.24, 0)
		qiBg.Position = UDim2.new(0, 0, 0.70, 0)
		qiBg.BackgroundColor3 = COLOR_BAR_BG
		qiBg.BorderSizePixel = 0
		qiBg.Parent = overheadGui

		local qiFill = Instance.new("Frame")
		qiFill.Name = "QiBarFill"
		qiFill.Size = UDim2.new(1, 0, 1, 0)
		qiFill.BackgroundColor3 = COLOR_QI_FILL
		qiFill.BorderSizePixel = 0
		qiFill.ZIndex = 2
		qiFill.Parent = qiBg

		local qiText = Instance.new("TextLabel")
		qiText.Name = "QiText"
		qiText.Size = UDim2.new(1, 0, 1, 0)
		qiText.BackgroundTransparency = 1
		qiText.TextColor3 = Color3.fromRGB(255, 255, 255)
		qiText.TextStrokeTransparency = 0.3
		qiText.TextScaled = true
		qiText.ZIndex = 3
		qiText.Font = Enum.Font.GothamMedium
		qiText.Text = "Qi: 0 / 100"
		qiText.Parent = qiBg
	end

	overheadGui.Adornee = head
	overheadGui.StudsOffset = Vector3.new(0, 3.8, 0)
	overheadGui.Size = UDim2.new(5.5, 0, 2.2, 0)
	overheadGui.MaxDistance = 150
	overheadGui.AlwaysOnTop = true
	overheadGui.Enabled = true
	overheadGui.Parent = head

	local nameLabel = overheadGui:FindFirstChild("PlayerNameLabel") :: TextLabel?
	local healthBg = overheadGui:FindFirstChild("HealthBarBackground") :: Frame?
	local healthFill = healthBg and healthBg:FindFirstChild("HealthBarFill") :: Frame?
	local healthText = healthBg and healthBg:FindFirstChild("HealthText") :: TextLabel?
	
	local qiBg = overheadGui:FindFirstChild("QiBarBackground") :: Frame?
	local qiFill = qiBg and qiBg:FindFirstChild("QiBarFill") :: Frame?
	local qiText = qiBg and qiBg:FindFirstChild("QiText") :: TextLabel?

	if healthFill then healthFill.BackgroundColor3 = COLOR_HEALTH_FILL end
	if qiFill then qiFill.BackgroundColor3 = COLOR_QI_FILL end

	local function updateTitle()
		if not nameLabel then return end
		local sect = character:GetAttribute("Sect") or "Azure Cloud Sect"
		local realm = character:GetAttribute("Realm") or "Qi Condensation"
		local displayName = if targetPlayer then targetPlayer.DisplayName else character.Name
		
		nameLabel.Text = string.format("[%s] %s (%s)", tostring(sect), displayName, tostring(realm))
		nameLabel.TextStrokeTransparency = 0.2
	end

	local function updateHealth()
		if not humanoid then return end
		local currentHp = math.floor(humanoid.Health)
		local maxHp = math.floor(humanoid.MaxHealth)
		local ratio = math.clamp(humanoid.Health / math.max(1, humanoid.MaxHealth), 0, 1)

		if healthFill then
			TweenService:Create(healthFill, TWEEN_INFO, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		end
		if healthText then
			healthText.Text = string.format("HP: %d / %d", currentHp, maxHp)
		end
	end

	local function updateQi()
		local currentQi = math.floor(character:GetAttribute("Qi") or 0)
		local maxQi = math.floor(character:GetAttribute("MaxQi") or 100)
		local ratio = math.clamp(currentQi / math.max(1, maxQi), 0, 1)

		if qiFill then
			TweenService:Create(qiFill, TWEEN_INFO, { Size = UDim2.new(ratio, 0, 1, 0) }):Play()
		end
		if qiText then
			qiText.Text = string.format("Qi: %d / %d", currentQi, maxQi)
		end
	end

	updateTitle()
	updateHealth()
	updateQi()

	humanoid.HealthChanged:Connect(updateHealth)
	character:GetAttributeChangedSignal("Qi"):Connect(updateQi)
	character:GetAttributeChangedSignal("MaxQi"):Connect(updateQi)
	character:GetAttributeChangedSignal("Realm"):Connect(updateTitle)
	character:GetAttributeChangedSignal("Sect"):Connect(updateTitle)
end

--------------------------------------------------------------------------------
-- PUBLIC CONTROLLER API
--------------------------------------------------------------------------------

function OverheadUIController.Init()
	if isInitialized then return end
	isInitialized = true

	local localPlayer = Players.LocalPlayer

	local function onCharacterAdded(char: Model)
		task.spawn(attachOverheadToCharacter, char)
	end

	if localPlayer.Character then
		onCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(onCharacterAdded)

	for _, child in ipairs(Workspace:GetChildren()) do
		if child:IsA("Model") and child:FindFirstChildOfClass("Humanoid") then
			task.spawn(attachOverheadToCharacter, child)
		end
	end

	Workspace.ChildAdded:Connect(function(child: Instance)
		if child:IsA("Model") then
			task.spawn(function()
				local humanoid = child:WaitForChild("Humanoid", 5)
				if humanoid then
					attachOverheadToCharacter(child)
				end
			end)
		end
	end)

	print("[ASCEND] OverheadUIController Initialized (Local Overhead Hidden).")
end

return OverheadUIController