--!strict
--[[
    GatheringController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/GatheringController.luau
    Handles:
      - Reliable automatic ProximityPrompt popup for both BasePart & Model nodes
      - Strict suppression: Prompt immediately disappears on interaction and stays hidden while harvesting or depleted
      - Sharp rectangular Xianxia aesthetic (No UICorner, vibrant Amber-Gold gradient, thin black borders)
      - Bangers font for [ E ] keycap and node titles
      - Elastic spring pop-in & fade-out transitions for prompts
      - Compact 210px GatheringHUD progress bar displaying clean "HARVESTING..." text
      - Movement cancellation and server loot sync
]]

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
local isHarvesting = false

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

--------------------------------------------------------------------------------
-- VIBRANT SHARP PROXIMITY PROMPT BUILDER
--------------------------------------------------------------------------------
local function CreateCustomPromptGui(prompt: ProximityPrompt): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CustomGatherPrompt"
	billboard.Size = UDim2.new(0, 190, 0, 48)
	billboard.StudsOffset = Vector3.new(0, 1.4, 0)
	billboard.AlwaysOnTop = true
	billboard.ResetOnSpawn = false

	-- Card Container (Sharp Rectangular, Vibrant Amber-Gold Gradient)
	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.new(0, 140, 0, 36)
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.new(0.5, 0, 0.5, 0)
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0
	card.BorderSizePixel = 0
	card.ClipsDescendants = false
	card.Parent = billboard

	-- Normal Thin Black Border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = card

	-- Vibrant Amber-Gold Gradient
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 0
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(180, 83, 9)),   -- Deep Radiant Amber
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(245, 158, 11)),  -- Vibrant Sun Gold
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 65, 5)),   -- Warm Bronze Gold
	})
	gradient.Parent = card

	-- [E] Keycap Badge
	local keyBadge = Instance.new("Frame")
	keyBadge.Name = "KeyBadge"
	keyBadge.Size = UDim2.new(0, 26, 0, 26)
	keyBadge.Position = UDim2.new(0, 8, 0.5, 0)
	keyBadge.AnchorPoint = Vector2.new(0, 0.5)
	keyBadge.BackgroundColor3 = Color3.fromRGB(12, 14, 18)
	keyBadge.BorderSizePixel = 0
	keyBadge.Parent = card

	local keyStroke = Instance.new("UIStroke")
	keyStroke.Color = Color3.fromRGB(0, 0, 0)
	keyStroke.Thickness = 1.0
	keyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	keyStroke.Parent = keyBadge

	local keyText = Instance.new("TextLabel")
	keyText.Size = UDim2.new(1, 0, 1, 0)
	keyText.BackgroundTransparency = 1
	keyText.Text = "E"
	keyText.TextColor3 = Color3.fromRGB(255, 240, 160)
	keyText.Font = Enum.Font.Bangers
	keyText.TextSize = 18
	keyText.Parent = keyBadge

	local keyTextStroke = Instance.new("UIStroke")
	keyTextStroke.Color = Color3.fromRGB(0, 0, 0)
	keyTextStroke.Thickness = 1.2
	keyTextStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	keyTextStroke.Parent = keyText

	-- Node Object Text
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -44, 0, 18)
	title.Position = UDim2.new(0, 40, 0, 6)
	title.BackgroundTransparency = 1
	title.Text = string.upper(prompt.ObjectText ~= "" and prompt.ObjectText or "SPIRIT NODE")
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.Bangers
	title.TextSize = 15
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = card

	local titleStroke = Instance.new("UIStroke")
	titleStroke.Color = Color3.fromRGB(0, 0, 0)
	titleStroke.Thickness = 1.4
	titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	titleStroke.Parent = title

	-- Action Text
	local action = Instance.new("TextLabel")
	action.Name = "Action"
	action.Size = UDim2.new(1, -44, 0, 14)
	action.Position = UDim2.new(0, 40, 0, 24)
	action.BackgroundTransparency = 1
	action.Text = string.upper(prompt.ActionText ~= "" and prompt.ActionText or "HARVEST")
	action.TextColor3 = Color3.fromRGB(254, 243, 199)
	action.Font = Enum.Font.Bangers
	action.TextSize = 12
	action.TextXAlignment = Enum.TextXAlignment.Left
	action.Parent = card

	local actionStroke = Instance.new("UIStroke")
	actionStroke.Color = Color3.fromRGB(0, 0, 0)
	actionStroke.Thickness = 1.0
	actionStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	actionStroke.Parent = action

	return billboard
end

--------------------------------------------------------------------------------
-- ANIMATED PROMPT LIFECYCLE
--------------------------------------------------------------------------------
local function HidePrompt()
	if activeBillboard then
		local b = activeBillboard
		activeBillboard = nil
		local card = b:FindFirstChild("Card") :: Frame?
		if card then
			local t = TweenService:Create(card, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = UDim2.new(0, 120, 0, 30),
				BackgroundTransparency = 1,
			})
			t:Play()
			t.Completed:Connect(function()
				b:Destroy()
			end)
		else
			b:Destroy()
		end
	end
	activePrompt = nil
end

local function ShowPrompt(prompt: ProximityPrompt)
	-- NEVER show prompt while harvesting or if prompt is disabled
	if isHarvesting then return end
	if not prompt.Enabled then return end

	-- Check if node is marked depleted or inactive
	local parentInst = prompt.Parent
	local model = prompt:FindFirstAncestorWhichIsA("Model") or (parentInst and parentInst:IsA("Model") and parentInst)
	if model and (model:GetAttribute("Depleted") == true or model:GetAttribute("IsActive") == false) then
		return
	end

	if activePrompt == prompt then return end
	HidePrompt()

	local targetPart: BasePart? = nil
	if parentInst then
		if parentInst:IsA("BasePart") then
			targetPart = parentInst
		elseif parentInst:IsA("Model") then
			targetPart = parentInst.PrimaryPart or parentInst:FindFirstChildWhichIsA("BasePart")
		end

		if not targetPart and model then
			targetPart = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
		end
	end

	if targetPart then
		activePrompt = prompt
		local b = CreateCustomPromptGui(prompt)
		b.Adornee = targetPart
		b.Parent = localPlayer:WaitForChild("PlayerGui")
		activeBillboard = b

		local card = b:FindFirstChild("Card") :: Frame?
		if card then
			card.Size = UDim2.new(0, 130, 0, 32)
			card.BackgroundTransparency = 0.4
			TweenService:Create(card, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 0,
			}):Play()
			TweenService:Create(b, TweenInfo.new(0.24, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
				StudsOffset = Vector3.new(0, 2.2, 0),
			}):Play()
		end
	end
end

local function CancelChannel()
	isHarvesting = false
	if cancelConn then
		cancelConn:Disconnect()
		cancelConn = nil
	end
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	local ui = GetHUD()
	if ui and ui.Container.Visible then
		local hideTween = TweenService:Create(ui.Container, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 160, 0, 32),
		})
		hideTween:Play()
		hideTween.Completed:Connect(function()
			ui.Container.Visible = false
			ui.Fill.Size = UDim2.new(0, 0, 1, 0)
		end)
	end
end

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------
function GatheringController.Init()
	local hud = GetHUD()
	if hud then
		hud.Container.Visible = false
		hud.Fill.Size = UDim2.new(0, 0, 1, 0)
	end

	local function SetupPrompt(prompt: ProximityPrompt)
		if prompt.Name == "GatherPrompt" then
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.HoldDuration = 0
			prompt.RequiresLineOfSight = false
			prompt.MaxActivationDistance = math.max(prompt.MaxActivationDistance, 11)

			-- Auto-hide if prompt is disabled by server or client
			prompt:GetPropertyChangedSignal("Enabled"):Connect(function()
				if not prompt.Enabled and activePrompt == prompt then
					HidePrompt()
				end
			end)
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

	-- 1-Click Trigger: Suppress prompt instantly & start channeled progress bar
	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt)
		if prompt.Name ~= "GatherPrompt" then return end
		if isHarvesting then return end

		-- LOCK HARVEST STATE & HIDE PROMPT INSTANTLY
		isHarvesting = true
		prompt.Enabled = false
		HidePrompt()
		CancelChannel()
		isHarvesting = true -- retain active channel lock

		local ui = GetHUD()
		if not ui then
			isHarvesting = false
			return
		end

		local model = prompt:FindFirstAncestorWhichIsA("Model")
		local nodeType = model and (model:GetAttribute("NodeType") or model.Name) or "SpiritGrass"
		local duration = NODE_DURATIONS[nodeType] or 2.0

		ui.Label.Text = "HARVESTING..."
		ui.Fill.Size = UDim2.new(0, 0, 1, 0)

		ui.Container.Size = UDim2.new(0, 160, 0, 32)
		ui.Container.Visible = true
		TweenService:Create(ui.Container, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 210, 0, 40),
		}):Play()

		activeTween = TweenService:Create(ui.Fill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0),
		})
		activeTween:Play()

		-- Movement cancellation check
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
			isHarvesting = false

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
					local exitTween = TweenService:Create(ui.Container, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						Size = UDim2.new(0, 160, 0, 32),
					})
					exitTween:Play()
					exitTween.Completed:Connect(function()
						ui.Container.Visible = false
						ui.Fill.Size = UDim2.new(0, 0, 1, 0)
					end)
				end)
			end

			local itemId = payload.ItemId
			local count = payload.Count or 1
			if itemId then
				HUDController.ShowItemToast(itemId, count)
			end
		end
	end)

	print("[ASCEND] GatheringController Initialized (Instant Prompt Suppression & Active-Only Gating Active).")
end

return GatheringController