--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Client/UI/OverheadUIController.luau
    Purpose: Manages 3D Overhead Display for ALL players and world NPCs/Dummies.
    Displays: Sect Disciple Rank & Title (Line 1) and Cultivation Realm (Line 2).
    Optimized: StudsOffset and MaxDistance distance fading to prevent close-range overlap.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local SectConfig = require(ReplicatedStorage.Shared.Configs.SectConfig)

local OverheadUIController = {}
local isInitialized = false

local function attachOverheadToCharacter(character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not head or not humanoid then return end

	local existing = head:FindFirstChild("OverheadBillboardGui")
	if existing then
		existing:Destroy()
	end

	local overheadGui = Instance.new("BillboardGui")
	overheadGui.Name = "OverheadBillboardGui"
	overheadGui.Size = UDim2.new(0, 260, 0, 52)
	overheadGui.StudsOffset = Vector3.new(0, 4.2, 0) -- Adjusted height to eliminate overlap
	overheadGui.MaxDistance = 55 -- Distance cull to keep screen clean
	overheadGui.AlwaysOnTop = true
	overheadGui.Enabled = true
	overheadGui.Adornee = head

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = overheadGui

	-- Line 1: Sect Disciple Rank Title (Dynamic Color based on Rank)
	local sectLabel = Instance.new("TextLabel")
	sectLabel.Name = "SectBadgeLabel"
	sectLabel.Size = UDim2.new(1, 0, 0, 24)
	sectLabel.BackgroundTransparency = 1
	sectLabel.TextColor3 = Color3.fromRGB(180, 220, 255)
	sectLabel.TextStrokeTransparency = 0
	sectLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	sectLabel.Font = Enum.Font.LuckiestGuy
	sectLabel.TextSize = 16
	sectLabel.LayoutOrder = 1
	sectLabel.Text = "[Azure Cloud Sect — Outer Disciple]"
	sectLabel.Parent = overheadGui

	-- Line 2: Cultivation Realm (Gold Accent)
	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmBadgeLabel"
	realmLabel.Size = UDim2.new(1, 0, 0, 22)
	realmLabel.BackgroundTransparency = 1
	realmLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	realmLabel.TextStrokeTransparency = 0
	realmLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	realmLabel.Font = Enum.Font.LuckiestGuy
	realmLabel.TextSize = 14
	realmLabel.LayoutOrder = 2
	realmLabel.Text = character:GetAttribute("Realm") or "Qi Condensation — Order 1"
	realmLabel.Parent = overheadGui

	overheadGui.Parent = head

	local function updateOverheadTexts()
		local realmVal = character:GetAttribute("Realm") or "Qi Condensation — Order 1"
		local sectRankVal = character:GetAttribute("SectRank") or "OuterDisciple"
		local sectName = character:GetAttribute("Sect") or "Azure Cloud Sect"

		local rankDef = SectConfig.GetRank(sectRankVal :: SectConfig.DiscipleRank)

		if sectLabel then
			sectLabel.Text = string.format("[%s — %s]", sectName, rankDef.DisplayName)
			sectLabel.TextColor3 = rankDef.TitleColor
		end

		if realmLabel then
			realmLabel.Text = tostring(realmVal)
		end
	end

	updateOverheadTexts()

	character:GetAttributeChangedSignal("Realm"):Connect(updateOverheadTexts)
	character:GetAttributeChangedSignal("SectRank"):Connect(updateOverheadTexts)
	character:GetAttributeChangedSignal("Sect"):Connect(updateOverheadTexts)
end

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

	print("[ASCEND] OverheadUIController Initialized (Dynamic Sect & Realm Badges Enabled).")
end

return OverheadUIController