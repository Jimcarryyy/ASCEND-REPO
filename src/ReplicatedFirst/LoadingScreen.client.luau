--!strict
--[[
    LoadingScreen.client.luau
    Location: src/ReplicatedFirst/LoadingScreen.client.luau

    Optimization pass over the previous version:

    1. PARALLEL GATES — Preload, Character Mount, and Inventory Sync have no
       dependency on each other (only on Gate 1 / engine load). They now run
       concurrently via task.spawn instead of one-after-another, so total wait
       time is roughly max(gate2, gate3, gate4) instead of sum(gate2, gate3, gate4).

    2. SCOPED PRELOAD — no more Workspace:GetDescendants() walking the entire
       map. Uses CollectionService:GetTagged("Preload") so cost scales with
       what you actually tag, not map size. Tag any MeshPart/Decal/Texture/
       SpecialMesh you want guaranteed-loaded with the "Preload" tag in Studio.

    3. EVENT-DRIVEN WAITS — EquippedSword check now listens for ChildAdded
       instead of polling every 0.1s.

    4. WEIGHTED PROGRESS — each gate has a weight; progress bar reflects real
       proportional completion instead of arbitrary fixed jumps, and updates
       live as each parallel gate finishes (not just at group boundaries).

    5. MIN/MAX display time preserved from previous version.
]]

local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local StarterGui = game:GetService("StarterGui")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local BGM_ASSET_ID = "rbxassetid://137280276426447"
local MIN_DISPLAY_TIME = 2.5
local MAX_DISPLAY_TIME = 12.0
local PRELOAD_TAG = "Preload" -- tag instances in Studio with this to guarantee preload

local startClock = os.clock()

-- =============================================================================
-- BACKGROUND MUSIC
-- =============================================================================
local function StartBackgroundMusic()
	local existingBgm = SoundService:FindFirstChild("AscendExplorationBGM") :: Sound?
	if not existingBgm then
		local bgm = Instance.new("Sound")
		bgm.Name = "AscendExplorationBGM"
		bgm.SoundId = BGM_ASSET_ID
		bgm.Volume = 0.35
		bgm.Looped = true
		bgm.Parent = SoundService
		bgm:Play()
	elseif not existingBgm.IsPlaying then
		existingBgm:Play()
	end
end
StartBackgroundMusic()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local loadingGui: ScreenGui?
local background: ImageLabel?
local progressFill: GuiObject?
local percentageLabel: TextLabel?
local statusLabel: TextLabel?
local tipLabel: TextLabel?

local LORE_TIPS = {
	"Tips: Breakthrough at the right time to increase your cultivation efficiency.",
	"Tips: Tapping Block within 0.22s of an incoming strike triggers a Perfect Parry, staggering your foe.",
	"Tips: Sitting in meditation replenishes Dantian Qi and radiates your Realm Aura.",
	"Tips: Older spiritual herbs yield superior alchemical pills with higher stat multipliers.",
	"Tips: In the 1v1 Sparring Arena, stats are normalized to 1,000 HP for balanced martial dueling.",
}

local function SetupLoadingUI(): boolean
	local customGui = ReplicatedFirst:FindFirstChild("CustomLoadingScreen")
		or playerGui:FindFirstChild("CustomLoadingScreen") :: ScreenGui?

	if not customGui then
		customGui = ReplicatedFirst:WaitForChild("CustomLoadingScreen", 5) :: ScreenGui?
	end

	if not customGui then
		warn("[LoadingScreen] CustomLoadingScreen not found in ReplicatedFirst!")
		return false
	end

	customGui.DisplayOrder = 999
	customGui.IgnoreGuiInset = true
	customGui.ResetOnSpawn = false

	if customGui.Parent == ReplicatedFirst then
		loadingGui = customGui:Clone()
		loadingGui.Parent = playerGui
	else
		loadingGui = customGui
	end

	if not loadingGui then return false end

	background = loadingGui:WaitForChild("Background", 5) :: ImageLabel?
	if not background then return false end

	local progressFrame = background:FindFirstChild("ProgressFrame") :: Frame?
	if progressFrame then
		progressFill = progressFrame:FindFirstChild("ProgressFill", true) :: GuiObject?
		percentageLabel = progressFrame:FindFirstChild("PercentageLabel", true) :: TextLabel?
	end

	local tipFrame = background:FindFirstChild("TipFrame") :: Frame?
	if tipFrame then
		statusLabel = tipFrame:FindFirstChild("StatusLabel") :: TextLabel?
		tipLabel = tipFrame:FindFirstChild("TipLabel") :: TextLabel?
	end

	if tipLabel then
		tipLabel.Text = LORE_TIPS[math.random(1, #LORE_TIPS)]
	end

	return true
end

local highestRatioShown = 0
local function UpdateProgress(targetRatio: number, statusText: string?)
	targetRatio = math.clamp(targetRatio, 0, 1)
	if targetRatio < highestRatioShown then
		targetRatio = highestRatioShown
	end
	highestRatioShown = targetRatio

	if statusText and statusLabel then
		statusLabel.Text = statusText
	end
	if percentageLabel then
		percentageLabel.Text = string.format("%d%%", math.floor(targetRatio * 100))
	end
	if progressFill then
		TweenService:Create(progressFill, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(targetRatio, 0, 1, 0),
		}):Play()
	end
end

-- Runs fn with a timeout; warns instead of hanging the caller if it overruns.
-- Returns true if fn completed within the timeout, false if it timed out.
local function withTimeout(seconds: number, label: string, fn: () -> ()): boolean
	local done = false
	task.spawn(function()
		fn()
		done = true
	end)

	local deadline = os.clock() + seconds
	while not done and os.clock() < deadline do
		task.wait(0.05)
	end

	if not done then
		warn(string.format("[LoadingScreen] Gate '%s' timed out after %.1fs — continuing anyway.", label, seconds))
	end
	return done
end

local function WaitForContentQueueEmpty(maxSeconds: number)
	local deadline = os.clock() + maxSeconds
	while ContentProvider.RequestQueueSize > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end

-- =============================================================================
-- PARALLEL GATE RUNNER
-- Runs several independent gates concurrently. Each contributes `weight` to
-- the progress bar, credited the moment that specific gate finishes — so the
-- bar advances continuously as things complete instead of jumping in blocks.
-- =============================================================================
type GateSpec = {
	name: string,
	weight: number,
	timeout: number,
	fn: () -> (),
	statusText: string,
}

local function runGatesInParallel(gates: { GateSpec }, baseProgress: number, groupSpan: number)
	local totalWeight = 0
	for _, g in ipairs(gates) do
		totalWeight += g.weight
	end

	local completedWeight = 0
	local remaining = #gates
	local doneSignal = Instance.new("BindableEvent")

	for _, g in ipairs(gates) do
		task.spawn(function()
			withTimeout(g.timeout, g.name, g.fn)
			completedWeight += g.weight
			local fraction = totalWeight > 0 and (completedWeight / totalWeight) or 1
			UpdateProgress(baseProgress + fraction * groupSpan, g.statusText)
			remaining -= 1
			if remaining <= 0 then
				doneSignal:Fire()
			end
		end)
	end

	if remaining > 0 then
		doneSignal.Event:Wait()
	end
	doneSignal:Destroy()
end

-- =============================================================================
-- MASTER INITIALIZATION SEQUENCE
-- =============================================================================
local function RunMasterInitSequence()
	if not SetupLoadingUI() then return end

	-- GATE 1 (must run alone/first — nothing else is guaranteed to exist yet)
	UpdateProgress(0.05, "Connecting to Azure Cloud Domain...")
	withTimeout(8, "EngineLoaded", function()
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
	end)
	UpdateProgress(0.15, "Connecting to Azure Cloud Domain...")

	-- GATES 2, 3, 4 — independent of each other, run concurrently.
	runGatesInParallel({
		{
			name = "PreloadAssets",
			weight = 30,
			timeout = 6,
			statusText = "Channeling Spiritual Artifacts & Herbs...",
			fn = function()
				local assetsToPreload: { Instance } = {}

				for _, folderName in ipairs({ "Weapons", "Herbs", "Remotes", "Cosmetics" }) do
					local folder = ReplicatedStorage:FindFirstChild(folderName)
						or ReplicatedStorage:WaitForChild(folderName, 4)
					if folder then
						table.insert(assetsToPreload, folder)
					end
				end

				-- Scoped instead of a full Workspace:GetDescendants() walk —
				-- tag anything you want guaranteed-preloaded with "Preload" in Studio.
				for _, inst in ipairs(CollectionService:GetTagged(PRELOAD_TAG)) do
					table.insert(assetsToPreload, inst)
				end

				-- StarterGui images/viewports — this is what fixes the
				-- "pixelated on first open, sharp on second open" symptom.
				-- PreloadAsync forces these to fully decode now instead of
				-- lazily decoding the first time the UI is shown.
				for _, inst in ipairs(StarterGui:GetDescendants()) do
					if inst:IsA("ImageLabel") or inst:IsA("ImageButton") or inst:IsA("ViewportFrame") then
						table.insert(assetsToPreload, inst)
					end
				end

				if #assetsToPreload > 0 then
					pcall(function()
						ContentProvider:PreloadAsync(assetsToPreload)
					end)
				end
			end,
		},
		{
			name = "CharacterMount",
			weight = 40,
			timeout = 10,
			statusText = "Materializing Cultivator Physical Form...",
			fn = function()
				local character = player.Character or player.CharacterAdded:Wait()
				character:WaitForChild("HumanoidRootPart", 10)
				character:WaitForChild("Humanoid", 10)

				if not player:HasAppearanceLoaded() then
					player.CharacterAppearanceLoaded:Wait()
				end

				-- Event-driven instead of polling: resolves the instant the
				-- sword is parented, or gives up after 4s either way.
				if not character:FindFirstChild("EquippedSword") then
					local swordAdded = false
					local conn: RBXScriptConnection
					conn = character.ChildAdded:Connect(function(child)
						if child.Name == "EquippedSword" then
							swordAdded = true
							conn:Disconnect()
						end
					end)

					local deadline = os.clock() + 4
					while not swordAdded and os.clock() < deadline do
						task.wait(0.05)
					end
					conn:Disconnect()
				end
			end,
		},
		{
			name = "InventorySync",
			weight = 30,
			timeout = 5,
			statusText = "Attuning Dantian Spiritual Reserves...",
			fn = function()
				local remotes = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
				local updateInvRemote = remotes and remotes:FindFirstChild("UpdateInventory") :: RemoteEvent?
				if not updateInvRemote then return end

				local inventorySynced = false
				local conn: RBXScriptConnection?
				conn = updateInvRemote.OnClientEvent:Connect(function()
					inventorySynced = true
					if conn then conn:Disconnect() end
				end)

				local invAction = remotes:FindFirstChild("InventoryAction") :: RemoteEvent?
				if invAction then
					invAction:FireServer({ Action = "RequestSync" })
				end

				local syncTimeout = os.clock() + 3.0
				while os.clock() < syncTimeout and not inventorySynced do
					task.wait(0.1)
				end
				if conn then conn:Disconnect() end
			end,
		},
	}, 0.15, 0.70) -- occupies progress range 15% -> 85%

	-- GATE 5 — final real completion check (after the parallel group, since
	-- it should reflect the total queue state once everything above kicked off).
	UpdateProgress(0.90, "Spiritual Foundation Solidifying...")
	WaitForContentQueueEmpty(4)
	UpdateProgress(1.0, "Spiritual Foundation Solidified.")

	-- Enforce minimum display time; never exceed the safety max.
	local elapsed = os.clock() - startClock
	local remaining = math.clamp(MIN_DISPLAY_TIME - elapsed, 0, MAX_DISPLAY_TIME)
	task.wait(remaining)

	-- GATE 6 — Fade out
	if loadingGui and background then
		local fadeInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(background, fadeInfo, {
			ImageTransparency = 1,
			BackgroundTransparency = 1,
		})

		for _, child in ipairs(background:GetDescendants()) do
			if child:IsA("TextLabel") then
				TweenService:Create(child, fadeInfo, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
				TweenService:Create(child, fadeInfo, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA("Frame") or child:IsA("ScrollingFrame") then
				TweenService:Create(child, fadeInfo, { BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, fadeInfo, { Transparency = 1 }):Play()
			end
		end

		tween:Play()
		tween.Completed:Connect(function()
			if loadingGui and loadingGui.Parent then
				loadingGui:Destroy()
			end
			print("[ASCEND] Custom Loading Screen Completed. Welcome, Disciple!")
		end)
	else
		if loadingGui then loadingGui:Destroy() end
	end
end

task.spawn(RunMasterInitSequence)
