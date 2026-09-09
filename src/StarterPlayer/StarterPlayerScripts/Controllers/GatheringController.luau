local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local HUDController = require(script.Parent.HUDController)

local GatheringController = {}

local localPlayer = Players.LocalPlayer
local activeTween: Tween? = nil
local activeBillboard: BillboardGui? = nil
local activePrompt: ProximityPrompt? = nil
local cancelConn: RBXScriptConnection? = nil

local NODE_DURATIONS = {
	SpiritGrass = 1.8,
	DragonBloodVine = 2.2,
	GaleWindLotus = 2.0,
	CelestialSpring = 2.2,
	JadeOre = 2.5,
}

local function GetHUD()
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then return nil end

	local gui = playerGui:FindFirstChild("GatheringHUD")
	if not gui then return nil end

	local container = gui:FindFirstChild("HarvestProgressContainer") :: Frame?
	if not container then return nil end

	local bg = container:FindFirstChild("ProgressBarBg") :: Frame?
	local fill = bg and bg:FindFirstChild("ProgressBarFill") :: Frame?
	local label = container:FindFirstChild("HerbNameLabel") :: TextLabel?

	if fill and label then
		return {
			Container = container,
			Fill = fill,
			Label = label,
		}
	end
	return nil
end

local function CreateCustomPromptGui(prompt: ProximityPrompt): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CustomGatherPrompt"
	billboard.Size = UDim2.new(0, 180, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 1.8, 0)
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.new(1, 0, 1, 0)
	card.BackgroundColor3 = Color3.fromRGB(15, 20, 22)
	card.BackgroundTransparency = 0.15
	card.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(212, 175, 55)
	stroke.Thickness = 1.2
	stroke.Parent = card

	-- [E] Keycap Badge
	local keyBadge = Instance.new("Frame")
	keyBadge.Size = UDim2.new(0, 30, 0, 30)
	keyBadge.Position = UDim2.new(0, 10, 0.5, -15)
	keyBadge.BackgroundColor3 = Color3.fromRGB(26, 32, 36)
	keyBadge.Parent = card

	local keyCorner = Instance.new("UICorner")
	keyCorner.CornerRadius = UDim.new(0, 6)
	keyCorner.Parent = keyBadge

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Color3.fromRGB(240, 200, 80)
	keyStroke.Thickness = 1
	keyStroke.Parent = keyBadge

	local keyText = Instance.new("TextLabel")
	keyText.Size = UDim2.new(1, 0, 1, 0)
	keyText.BackgroundTransparency = 1
	keyText.Text = "E"
	keyText.TextColor3 = Color3.fromRGB(255, 240, 180)
	keyText.Font = Enum.Font.SourceSansBold
	keyText.TextSize = 18
	keyText.Parent = keyBadge

	-- Text labels
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -55, 0, 18)
	title.Position = UDim2.new(0, 48, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = prompt.ObjectText ~= "" and prompt.ObjectText or "Spirit Herb"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local action = Instance.new("TextLabel")
	action.Size = UDim2.new(1, -55, 0, 16)
	action.Position = UDim2.new(0, 48, 0, 25)
	action.BackgroundTransparency = 1
	action.Text = prompt.ActionText ~= "" and prompt.ActionText or "Harvest"
	action.TextColor3 = Color3.fromRGB(150, 220, 180)
	action.Font = Enum.Font.SourceSans
	action.TextSize = 12
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Parent = card

	return billboard
end

local function HidePrompt()
	if activeBillboard then
		activeBillboard:Destroy()
		activeBillboard = nil
	end
	activePrompt = nil
end

local function ShowPrompt(prompt: ProximityPrompt)
	if activePrompt == prompt then return end
	HidePrompt()

	local adornee = prompt.Parent
	if adornee and adornee:IsA("BasePart") then
		activePrompt = prompt
		activeBillboard = CreateCustomPromptGui(prompt)
		activeBillboard.Adornee = adornee
		activeBillboard.Parent = localPlayer:WaitForChild("PlayerGui")
	end
end

local function CancelChannel()
	if cancelConn then
		cancelConn:Disconnect()
		cancelConn = nil
	end
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	local ui = GetHUD()
	if ui then
		ui.Container.Visible = false
		ui.Fill.Size = UDim2.new(0, 0, 1, 0)
	end
end

function GatheringController.Init()
	local hud = GetHUD()
	if hud then
		hud.Container.Visible = false
		hud.Fill.Size = UDim2.new(0, 0, 1, 0)
	end

	-- Suppress default Roblox UI on all gathering prompts
	local function SetupPrompt(prompt: ProximityPrompt)
		if prompt.Name == "GatherPrompt" then
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.HoldDuration = 0
		end
	end

	local gatheringFolder = workspace:WaitForChild("GatheringNodes", 10)
	if gatheringFolder then
		for _, desc in ipairs(gatheringFolder:GetDescendants()) do
			if desc:IsA("ProximityPrompt") then
				SetupPrompt(desc)
			end
		end
		gatheringFolder.DescendantAdded:Connect(function(desc)
			if desc:IsA("ProximityPrompt") then
				SetupPrompt(desc)
			end
		end)
	end

	-- In-World Custom Prompt Listeners
	ProximityPromptService.PromptShown:Connect(function(prompt: ProximityPrompt)
		if prompt.Name == "GatherPrompt" then
			ShowPrompt(prompt)
		end
	end)

	ProximityPromptService.PromptHidden:Connect(function(prompt: ProximityPrompt)
		if prompt == activePrompt then
			HidePrompt()
		end
	end)

	-- 1-Click Trigger: Start the bottom progress bar fill
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt.Name ~= "GatherPrompt" then return end

		HidePrompt()
		CancelChannel()

		local ui = GetHUD()
		if not ui then return end

		local model = prompt:FindFirstAncestorWhichIsA("Model")
		local nodeType = model and (model:GetAttribute("NodeType") or model.Name) or "SpiritGrass"
		local duration = NODE_DURATIONS[nodeType] or 1.8
		local herbName = prompt.ObjectText ~= "" and prompt.ObjectText or nodeType

		ui.Label.Text = "HARVESTING: " .. string.upper(herbName)
		ui.Fill.Size = UDim2.new(0, 0, 1, 0)
		ui.Container.Visible = true

		activeTween = TweenService:Create(ui.Fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0)
		})
		activeTween:Play()

		-- Cancel if player moves away during harvest
		local char = localPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local startPos = hrp and hrp.Position

		if startPos then
			cancelConn = RunService.Heartbeat:Connect(function()
				if not hrp or (hrp.Position - startPos).Magnitude > 8 then
					CancelChannel()
				end
			end)
		end
	end)

	-- Server Success Listener
	local gatheringRemote = RemoteEvents.GetRemote("GatheringAction")
	gatheringRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then return end

		if payload.Action == "HarvestSuccess" then
			if cancelConn then
				cancelConn:Disconnect()
				cancelConn = nil
			end

			local sound = SoundService:FindFirstChild("GatherHerbsSound")
			if sound and sound:IsA("Sound") then
				sound:Play()
			end

			local ui = GetHUD()
			if ui and ui.Container.Visible then
				ui.Fill.Size = UDim2.new(1, 0, 1, 0)
				task.delay(0.2, function()
					ui.Container.Visible = false
					ui.Fill.Size = UDim2.new(0, 0, 1, 0)
				end)
			end

			local itemId = payload.ItemId
			local count = payload.Count or 1
			if itemId then
				HUDController.ShowItemToast(itemId, count)
			end
		end
	end)
end

return GatheringController