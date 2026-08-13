--!strict
--[[
    LoadingScreen.client.luau
    Location: src/ReplicatedFirst/LoadingScreen.client.luau
    Custom Xianxia Loading Screen for ASCEND.
    Disables default Roblox loading screen, dynamically scans and preloads all game assets,
    tracks server data initialization, and provides an optional Skip button.
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Immediately remove default Roblox loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

-- Customizable Configuration Constants
local BACKGROUND_IMAGE_ID = "rbxassetid://70461133318970" -- Replace with your custom artwork Asset ID
local FONT_TITLE = Enum.Font.FredokaOne
local FONT_SUBTITLE = Enum.Font.LuckiestGuy

-- Light-Mode Xianxia Palette
local COLOR_BG_PANEL = Color3.fromRGB(247, 234, 224)    -- #F7EAE0 Warm Cream
local COLOR_JADE_DARK = Color3.fromRGB(29, 69, 51)      -- #1D4533 Dark Jade Green
local COLOR_GOLD_ACCENT = Color3.fromRGB(255, 215, 0)   -- #FFD700 Gold Accent

local isLoadingComplete = false
local isServerDataLoaded = false

-- Create Loading ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AscendLoadingScreen"
screenGui.DisplayOrder = 1000
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Background Fullscreen Image
local bgImage = Instance.new("ImageLabel")
bgImage.Name = "BackgroundImage"
bgImage.Size = UDim2.new(1, 0, 1, 0)
bgImage.Position = UDim2.new(0, 0, 0, 0)
bgImage.BackgroundColor3 = Color3.fromRGB(15, 23, 42)
bgImage.Image = BACKGROUND_IMAGE_ID
bgImage.ScaleType = Enum.ScaleType.Crop
bgImage.Parent = screenGui

-- Dark Gradient Overlay for Readability
local darkOverlay = Instance.new("Frame")
darkOverlay.Name = "DarkOverlay"
darkOverlay.Size = UDim2.new(1, 0, 1, 0)
darkOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
darkOverlay.BackgroundTransparency = 0.45
darkOverlay.Parent = bgImage

-- Center Title & Subtitle Container
local titleContainer = Instance.new("Frame")
titleContainer.Name = "TitleContainer"
titleContainer.Size = UDim2.new(0, 500, 0, 120)
titleContainer.Position = UDim2.new(0.5, -250, 0.35, 0)
titleContainer.BackgroundTransparency = 1
titleContainer.Parent = bgImage

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.Size = UDim2.new(1, 0, 0, 60)
titleLabel.Position = UDim2.new(0, 0, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ASCEND"
titleLabel.Font = FONT_TITLE
titleLabel.TextSize = 52
titleLabel.TextColor3 = COLOR_GOLD_ACCENT
titleLabel.TextStrokeColor3 = COLOR_JADE_DARK
titleLabel.TextStrokeTransparency = 0
titleLabel.Parent = titleContainer

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.Size = UDim2.new(1, 0, 0, 30)
subtitleLabel.Position = UDim2.new(0, 0, 0, 65)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Text = "— Seeking The Dao —"
subtitleLabel.Font = FONT_SUBTITLE
subtitleLabel.TextSize = 22
subtitleLabel.TextColor3 = COLOR_BG_PANEL
subtitleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
subtitleLabel.TextStrokeTransparency = 0
subtitleLabel.Parent = titleContainer

-- Bottom Loading Bar Container
local barContainer = Instance.new("Frame")
barContainer.Name = "BarContainer"
barContainer.Size = UDim2.new(0, 480, 0, 50)
barContainer.Position = UDim2.new(0.5, -240, 0.78, 0)
barContainer.BackgroundTransparency = 1
barContainer.Parent = bgImage

-- Progress Bar Background Frame
local barFrame = Instance.new("Frame")
barFrame.Name = "ProgressBarFrame"
barFrame.Size = UDim2.new(1, 0, 0, 18)
barFrame.Position = UDim2.new(0, 0, 0, 0)
barFrame.BackgroundColor3 = COLOR_BG_PANEL
barFrame.BorderSizePixel = 0
barFrame.Parent = barContainer

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(0, 9)
barCorner.Parent = barFrame

local barStroke = Instance.new("UIStroke")
barStroke.Color = COLOR_GOLD_ACCENT
barStroke.Thickness = 2
barStroke.Parent = barFrame

-- Progress Bar Fill
local barFill = Instance.new("Frame")
barFill.Name = "ProgressBarFill"
barFill.Size = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = COLOR_JADE_DARK
barFill.BorderSizePixel = 0
barFill.Parent = barFrame

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 9)
fillCorner.Parent = barFill

-- Progress Text
local progressText = Instance.new("TextLabel")
progressText.Name = "ProgressText"
progressText.Size = UDim2.new(1, 0, 0, 24)
progressText.Position = UDim2.new(0, 0, 0, 24)
progressText.BackgroundTransparency = 1
progressText.Text = "Scanning World Assets... 0%"
progressText.Font = FONT_SUBTITLE
progressText.TextSize = 15
progressText.TextColor3 = COLOR_BG_PANEL
progressText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
progressText.TextStrokeTransparency = 0
progressText.Parent = barContainer

-- Skip Button
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(0, 180, 0, 36)
skipButton.Position = UDim2.new(0.5, -90, 0.88, 0)
skipButton.BackgroundColor3 = COLOR_JADE_DARK
skipButton.BorderSizePixel = 0
skipButton.Text = "SKIP [SPACE / CLICK]"
skipButton.Font = FONT_SUBTITLE
skipButton.TextSize = 14
skipButton.TextColor3 = COLOR_GOLD_ACCENT
skipButton.AutoButtonColor = true
skipButton.Visible = false -- Appears after 1.5 seconds
skipButton.Parent = bgImage

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = skipButton

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = COLOR_GOLD_ACCENT
skipStroke.Thickness = 1.5
skipStroke.Parent = skipButton

-- Finish & Fade Out Function
local function DismissLoadingScreen()
	if isLoadingComplete then return end
	isLoadingComplete = true

	local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	
	-- Fade out UI elements
	TweenService:Create(darkOverlay, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(subtitleLabel, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(barFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(barFill, tweenInfo, { BackgroundTransparency = 1 }):Play()
	TweenService:Create(barStroke, tweenInfo, { Transparency = 1 }):Play()
	TweenService:Create(progressText, tweenInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	TweenService:Create(skipButton, tweenInfo, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
	TweenService:Create(skipStroke, tweenInfo, { Transparency = 1 }):Play()

	local fadeBg = TweenService:Create(bgImage, tweenInfo, { ImageTransparency = 1, BackgroundTransparency = 1 })
	fadeBg:Play()

	fadeBg.Completed:Connect(function()
		screenGui:Destroy()
		print("[ASCEND] Custom Xianxia Loading Screen Completed.")
	end)
end

-- Skip Button Handlers
skipButton.MouseButton1Click:Connect(function()
	DismissLoadingScreen()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.Space and skipButton.Visible then
		DismissLoadingScreen()
	end
end)

-- Make Skip Button visible after 1.5 seconds
task.delay(1.5, function()
	if not isLoadingComplete then
		skipButton.Visible = true
	end
end)

-- Listen for Server Data Sync Remote Event to verify player profile is ready
task.spawn(function()
	local sharedFolder = ReplicatedStorage:WaitForChild("Shared", 10)
	local networkFolder = sharedFolder and sharedFolder:WaitForChild("Network", 10)
	local remoteEventsMod = networkFolder and networkFolder:WaitForChild("RemoteEvents", 10)

	if remoteEventsMod then
		local RemoteEvents = require(remoteEventsMod :: ModuleScript)
		local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
		if updateCultivationRemote then
			local conn
			conn = updateCultivationRemote.OnClientEvent:Connect(function()
				isServerDataLoaded = true
				if conn then conn:Disconnect() end
			end)
		end
	end
end)

-- Dynamic Asset Discovery & Preload Thread
task.spawn(function()
	local assetsToPreload: { Instance } = {}

	-- Helper function to gather heavy renderable assets recursively
	local function gatherAssets(container: Instance)
		for _, descendant in ipairs(container:GetDescendants()) do
			if descendant:IsA("MeshPart") 
				or descendant:IsA("SpecialMesh") 
				or descendant:IsA("Decal") 
				or descendant:IsA("Texture") 
				or descendant:IsA("ImageLabel") 
				or descendant:IsA("Sound") 
				or descendant:IsA("Animation") then
				table.insert(assetsToPreload, descendant)
			end
		end
	end

	-- Scan ReplicatedStorage, SoundService, and PlayerGui for renderable instances
	gatherAssets(ReplicatedStorage)
	gatherAssets(SoundService)

	local totalAssets = #assetsToPreload
	if totalAssets == 0 then
		totalAssets = 1
	end

	local loadedCount = 0

	-- Iterate through assets in dynamic batches
	for i, asset in ipairs(assetsToPreload) do
		if isLoadingComplete then break end

		pcall(function()
			ContentProvider:PreloadAsync({ asset })
		end)

		loadedCount += 1
		local percent = math.clamp(math.floor((loadedCount / totalAssets) * 90), 0, 90)

		if barFill then
			TweenService:Create(barFill, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(percent / 100, 0, 1, 0)
			}):Play()
		end

		if progressText then
			local assetName = asset.Name
			progressText.Text = string.format("Harmonizing Assets... %d%% (%s)", percent, assetName)
		end

		task.wait(0.02)
	end

	-- Final Stage: Waiting for Server Profile & Character Data Sync
	if not isLoadingComplete then
		if progressText then
			progressText.Text = "Synchronizing Cultivator Profile... 95%"
		end
		if barFill then
			TweenService:Create(barFill, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(0.95, 0, 1, 0)
			}):Play()
		end

		local timeout = 0
		while not isServerDataLoaded and timeout < 3.0 do
			if isLoadingComplete then break end
			task.wait(0.1)
			timeout += 0.1
		end

		if barFill then
			TweenService:Create(barFill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = UDim2.new(1.0, 0, 1, 0)
			}):Play()
		end

		if progressText then
			progressText.Text = "Ascension Prepared... 100%"
		end

		task.wait(0.3)
		DismissLoadingScreen()
	end
end)