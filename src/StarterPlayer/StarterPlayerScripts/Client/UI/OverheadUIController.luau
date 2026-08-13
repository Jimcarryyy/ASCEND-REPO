--!strict
--[[
    OverheadUIController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Client/UI/OverheadUIController.luau
    Purpose: Manages 3D Overhead Display for ALL players and world NPCs/Dummies.
    Strictly displays Realm Name & Rank (Line 1) and Alchemy Name & Rank (Line 2).
    Uses LuckiestGuy font with thick black text outlines for maximum readability.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local OverheadUIController = {}
local isInitialized = false

local function attachOverheadToCharacter(character: Model)
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not head or not humanoid then return end

	-- Destroy old billboard if re-attaching
	local existing = head:FindFirstChild("OverheadBillboardGui")
	if existing then
		existing:Destroy()
	end

	-- Programmatic Billboard Creation (Fixed Pixel Dimensions to prevent collapse)
	local overheadGui = Instance.new("BillboardGui")
	overheadGui.Name = "OverheadBillboardGui"
	overheadGui.Size = UDim2.new(0, 260, 0, 52)
	overheadGui.StudsOffset = Vector3.new(0, 3.5, 0)
	overheadGui.MaxDistance = 150
	overheadGui.AlwaysOnTop = true
	overheadGui.Enabled = true
	overheadGui.Adornee = head

	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.Padding = UDim.new(0, 2)
	listLayout.Parent = overheadGui

	-- Line 1: Realm Name and Rank (Gold Accent)
	local realmLabel = Instance.new("TextLabel")
	realmLabel.Name = "RealmBadgeLabel"
	realmLabel.Size = UDim2.new(1, 0, 0, 26)
	realmLabel.BackgroundTransparency = 1
	realmLabel.TextColor3 = Color3.fromRGB(255, 215, 0) -- Gold Accent
	realmLabel.TextStrokeTransparency = 0 -- Thick black outline
	realmLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	realmLabel.Font = Enum.Font.LuckiestGuy
	realmLabel.TextSize = 18
	realmLabel.LayoutOrder = 1
	realmLabel.Text = character:GetAttribute("Realm") or "Qi Condensation — Order 1"
	realmLabel.Parent = overheadGui

	-- Line 2: Alchemy Name and Rank (Jade Green Accent)
	local alchemyLabel = Instance.new("TextLabel")
	alchemyLabel.Name = "AlchemyBadgeLabel"
	alchemyLabel.Size = UDim2.new(1, 0, 0, 22)
	alchemyLabel.BackgroundTransparency = 1
	alchemyLabel.TextColor3 = Color3.fromRGB(80, 220, 120) -- Jade Green Accent
	alchemyLabel.TextStrokeTransparency = 0 -- Thick black outline
	alchemyLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	alchemyLabel.Font = Enum.Font.LuckiestGuy
	alchemyLabel.TextSize = 15
	alchemyLabel.LayoutOrder = 2
	alchemyLabel.Text = character:GetAttribute("AlchemyRank") or "Mortal Alchemist — Rank 1"
	alchemyLabel.Parent = overheadGui

	overheadGui.Parent = head

	local function updateOverheadTexts()
		local realmVal = character:GetAttribute("Realm") or "Qi Condensation — Order 1"
		local alchemyVal = character:GetAttribute("AlchemyRank") or "Mortal Alchemist — Rank 1"

		if realmLabel then
			realmLabel.Text = tostring(realmVal)
		end
		if alchemyLabel then
			alchemyLabel.Text = tostring(alchemyVal)
		end
	end

	updateOverheadTexts()

	character:GetAttributeChangedSignal("Realm"):Connect(updateOverheadTexts)
	character:GetAttributeChangedSignal("AlchemyRank"):Connect(updateOverheadTexts)
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

	print("[ASCEND] OverheadUIController Initialized (LuckiestGuy Badges Enabled).")
end

return OverheadUIController