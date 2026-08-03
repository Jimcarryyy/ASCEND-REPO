--!strict
-- OverheadUIController.luau
-- Dynamic overhead HP bars, Cultivation Realm Titles, and Name tags for Players and NPCs.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local OverheadUIController = {}
local localPlayer = Players.LocalPlayer

local function CreateOverheadGui(character: Model): BillboardGui?
	local head = character:WaitForChild("Head", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not head or not humanoid then return nil end

	-- Remove existing overhead UI if any
	local existing = head:FindFirstChild("OverheadUI")
	if existing then existing:Destroy() end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "OverheadUI"
	billboard.Size = UDim2.new(4, 0, 1.2, 0)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 80
	billboard.Parent = head

	-- Container Frame
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 1, 0)
	container.BackgroundTransparency = 1
	container.Parent = billboard

	-- Title / Name Label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.Size = UDim2.new(1, 0, 0.45, 0)
	nameLabel.Position = UDim2.new(0, 0, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 13
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.3
	nameLabel.Text = character.Name
	nameLabel.Parent = container

	-- Health Bar Background
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HpBackground"
	hpBg.Size = UDim2.new(0.9, 0, 0.25, 0)
	hpBg.Position = UDim2.new(0.05, 0, 0.55, 0)
	hpBg.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
	hpBg.BorderSizePixel = 0
	hpBg.Parent = container

	local hpBgCorner = Instance.new("UICorner")
	hpBgCorner.CornerRadius = UDim.new(0, 4)
	hpBgCorner.Parent = hpBg

	-- Health Bar Fill
	local hpFill = Instance.new("Frame")
	hpFill.Name = "HpFill"
	hpFill.Size = UDim2.new(humanoid.Health / humanoid.MaxHealth, 0, 1, 0)
	hpFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
	hpFill.BorderSizePixel = 0
	hpFill.Parent = hpBg

	local hpFillCorner = Instance.new("UICorner")
	hpFillCorner.CornerRadius = UDim.new(0, 4)
	hpFillCorner.Parent = hpFill

	-- Listen for Health Changes
	humanoid.HealthChanged:Connect(function(newHp)
		local ratio = math.clamp(newHp / humanoid.MaxHealth, 0, 1)
		TweenService:Create(hpFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(ratio, 0, 1, 0)
		}):Play()

		-- Dynamic color based on health remaining
		if ratio > 0.5 then
			hpFill.BackgroundColor3 = Color3.fromRGB(46, 204, 113) -- Green
		elseif ratio > 0.25 then
			hpFill.BackgroundColor3 = Color3.fromRGB(241, 196, 15) -- Yellow
		else
			hpFill.BackgroundColor3 = Color3.fromRGB(231, 76, 60) -- Red
		end
	end)

	return billboard
end

function OverheadUIController.Init()
	-- Process workspace characters
	local function TrackCharacter(model: Instance)
		if model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") then
			CreateOverheadGui(model)
		end
	end

	Workspace.ChildAdded:Connect(TrackCharacter)
	for _, child in ipairs(Workspace:GetChildren()) do
		TrackCharacter(child)
	end
end

OverheadUIController.Init()
return OverheadUIController