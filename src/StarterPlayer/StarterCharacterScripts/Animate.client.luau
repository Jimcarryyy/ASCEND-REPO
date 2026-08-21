--!strict
--[[
    Animate.client.luau
    Location: src/StarterPlayer/StarterCharacterScripts/Animate.client.luau
    Master R6 Movement Animation & Audio Sync Engine for ASCEND.
    Features: Rock-solid Idle Yaw Pinning (0% rotation drift), Anti-ragdoll protection, and clean locomotion audio.
]]

local Character = script.Parent :: Model
local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid?
local RootPart = Character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
local Animator = if Humanoid then Humanoid:WaitForChild("Animator", 5) :: Animator? else nil

if not Humanoid or not RootPart or not Animator then
	warn("[Animate] Required character instances missing!")
	return
end

-- Snappy Jump Power & Slope Climb Support
Humanoid.JumpPower = 65
Humanoid.MaxSlopeAngle = 89

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local moveCfg = AnimationConfig.Movement

-- Permanently disable tripping, ragdoll, and getting-up physics bugs
Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

-- Custom Looped Movement Audio IDs
local WALK_SOUND_ID = "rbxassetid://4416041299"       -- 5.851s Looped Walk Audio
local RUN_SOUND_ID  = "rbxassetid://79250663775359" -- 4.284s Looped Run Audio

local currentLocomotionState = "None"
local activeLocomotionTrack: AnimationTrack? = nil
local loadedLocomotionTracks: { [string]: AnimationTrack } = {}

local isDeliberateJump = false
local freefallStartTime = 0
local canJump = true
local targetIdleYaw: number? = nil

-- Create Custom Audio Instances on HumanoidRootPart
local customWalkSound = Instance.new("Sound")
customWalkSound.Name = "CustomWalkAudio"
customWalkSound.SoundId = WALK_SOUND_ID
customWalkSound.Looped = true
customWalkSound.Volume = 0.65
customWalkSound.Parent = RootPart

local customRunSound = Instance.new("Sound")
customRunSound.Name = "CustomRunAudio"
customRunSound.SoundId = RUN_SOUND_ID
customRunSound.Looped = true
customRunSound.Volume = 0.75
customRunSound.Parent = RootPart

-- Mute Roblox's Default Running Sound
task.spawn(function()
	local defaultRunning = RootPart:WaitForChild("Running", 3) :: Sound?
	if defaultRunning then
		defaultRunning.Volume = 0
		defaultRunning:GetPropertyChangedSignal("Volume"):Connect(function()
			defaultRunning.Volume = 0
		end)
	end
end)

-- Safely locate Jump/Land Audio from SoundService
local function GetMovementAudioInstance(soundName: string): Instance?
	local movementFolder = SoundService:FindFirstChild("Movement sounds") or SoundService:FindFirstChild("MovementSounds")
	if not movementFolder then return nil end
	local main = movementFolder:FindFirstChild("Main") or movementFolder
	local charFolder = main:FindFirstChild("Character") or main
	return charFolder:FindFirstChild(soundName)
end

local soundJumping = GetMovementAudioInstance("Jumping")
local soundLanding = GetMovementAudioInstance("Landing")

local function PlayImpactAudio(audioObj: Instance?)
	if not audioObj then return end
	if audioObj:IsA("Sound") then
		audioObj.PlaybackSpeed = 1.0
		audioObj:Play()
	elseif audioObj:IsA("SoundGroup") or audioObj:IsA("Folder") then
		local sounds = {}
		for _, child in ipairs(audioObj:GetChildren()) do
			if child:IsA("Sound") then table.insert(sounds, child) end
		end
		if #sounds > 0 then
			local s = sounds[math.random(1, #sounds)]
			s.PlaybackSpeed = 1.0
			s:Play()
		end
	end
end

-- Helper function to sanitize Asset ID strings
local function SanitizeAssetId(id: string): string
	if not id or id == "" then return "" end
	local clean = id:match("rbxassetid://%d+") or id:match("%d+")
	return if clean then "rbxassetid://" .. clean:gsub("%D", "") else ""
end

-- Pre-Warming Dynamic Track Binder
local function GetLocomotionTrack(animName: string, animId: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
	if loadedLocomotionTracks[animName] then
		return loadedLocomotionTracks[animName]
	end

	local cleanId = SanitizeAssetId(animId)
	if cleanId == "" or cleanId == "rbxassetid://" then
		warn(string.format("[Animate] Missing or invalid Animation ID for '%s'.", animName))
		return nil
	end

	local animObj = Instance.new("Animation")
	animObj.AnimationId = cleanId

	local success, trk = pcall(function()
		return (Animator :: Animator):LoadAnimation(animObj)
	end)

	if success and trk then
		trk.Priority = priority
		trk.Looped = looped
		loadedLocomotionTracks[animName] = trk
		return trk
	else
		warn(string.format("[Animate] Failed to load track '%s' (%s): %s", animName, cleanId, tostring(trk)))
	end
	return nil
end

-- Locomotion tracks with standard Movement priority
local trackIdle  = GetLocomotionTrack("Idle", moveCfg.Idle, Enum.AnimationPriority.Idle, true)
local trackWalk  = GetLocomotionTrack("Walk", moveCfg.Walk, Enum.AnimationPriority.Movement, true)
local trackRun   = GetLocomotionTrack("Run", moveCfg.Run, Enum.AnimationPriority.Movement, true)
local trackJump  = GetLocomotionTrack("Jump", moveCfg.Jump, Enum.AnimationPriority.Action2, false)
local trackFall  = GetLocomotionTrack("Fall", moveCfg.Fall, Enum.AnimationPriority.Action2, true)
local trackLand  = GetLocomotionTrack("Land", moveCfg.Land, Enum.AnimationPriority.Action2, false)
local trackClimb = GetLocomotionTrack("Climb", moveCfg.Climb, Enum.AnimationPriority.Movement, true)
local trackSwim  = GetLocomotionTrack("Swim", moveCfg.Swim, Enum.AnimationPriority.Movement, true)

local function SetLocomotionState(newState: string)
	if currentLocomotionState == newState then return end
	currentLocomotionState = newState

	local targetTrack: AnimationTrack? = nil

	if newState == "Walk" then targetTrack = trackWalk
	elseif newState == "Run" then targetTrack = trackRun
	elseif newState == "Jump" then targetTrack = trackJump
	elseif newState == "Fall" then targetTrack = trackFall
	elseif newState == "Land" then targetTrack = trackLand
	elseif newState == "Climb" then targetTrack = trackClimb
	elseif newState == "Swim" then targetTrack = trackSwim
	elseif newState == "Idle" then targetTrack = trackIdle
	end

	if activeLocomotionTrack and activeLocomotionTrack ~= targetTrack then
		activeLocomotionTrack:Stop(0.1)
	end

	activeLocomotionTrack = targetTrack
	if targetTrack and not targetTrack.IsPlaying then
		if newState == "Jump" then
			targetTrack:Play(0.04, 1, 1.2)
		elseif newState == "Land" then
			targetTrack:Play(0.05, 1, 1.3)
		else
			targetTrack:Play(0.1)
		end
	end
end

SetLocomotionState("Idle")

local function StopMovementAudio()
	if customWalkSound.IsPlaying then customWalkSound:Stop() end
	if customRunSound.IsPlaying then customRunSound:Stop() end
end

local function StopAllLocomotionTracks()
	StopMovementAudio()
	if activeLocomotionTrack and activeLocomotionTrack.IsPlaying then
		activeLocomotionTrack:Stop(0.05)
		activeLocomotionTrack = nil
	end
	for _, track in pairs(loadedLocomotionTracks) do
		if track and track.IsPlaying then
			track:Stop(0.05)
		end
	end
	currentLocomotionState = "None"
	targetIdleYaw = nil
end

Character:GetAttributeChangedSignal("IsMeditating"):Connect(function()
	local isMed = Character:GetAttribute("IsMeditating") == true
	if isMed then
		StopAllLocomotionTracks()
	else
		SetLocomotionState("Idle")
	end
end)

-- State Change Listener
Humanoid.StateChanged:Connect(function(_, newState)
	if Character:GetAttribute("IsMeditating") == true then
		StopAllLocomotionTracks()
		return
	end

	if newState == Enum.HumanoidStateType.Jumping then
		if not canJump then
			Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			return
		end

		isDeliberateJump = true
		freefallStartTime = os.clock()
		SetLocomotionState("Jump")
		PlayImpactAudio(soundJumping)
		StopMovementAudio()
		targetIdleYaw = nil

	elseif newState == Enum.HumanoidStateType.Freefall then
		targetIdleYaw = nil
		if not isDeliberateJump then
			freefallStartTime = os.clock()
			task.delay(0.25, function()
				if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not isDeliberateJump then
					SetLocomotionState("Fall")
				end
			end)
		else
			task.delay(1.2, function()
				if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and (os.clock() - freefallStartTime) >= 1.2 then
					SetLocomotionState("Fall")
				end
			end)
		end

	elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp then
		isDeliberateJump = false
		SetLocomotionState("Land")
		PlayImpactAudio(soundLanding)

		canJump = false
		task.delay(0.2, function()
			canJump = true
		end)

		task.delay(0.16, function()
			if Humanoid.MoveDirection.Magnitude > 0.05 then
				local isSprinting = Humanoid.WalkSpeed > 20
				SetLocomotionState(if isSprinting then "Run" else "Walk")
			else
				SetLocomotionState("Idle")
			end
		end)

	elseif newState == Enum.HumanoidStateType.Swimming then
		isDeliberateJump = false
		SetLocomotionState("Swim")
		StopMovementAudio()
		targetIdleYaw = nil

	elseif newState == Enum.HumanoidStateType.Climbing then
		isDeliberateJump = false
		SetLocomotionState("Climb")
		StopMovementAudio()
		targetIdleYaw = nil
	end
end)

-- Continuous Locomotion Loop with Zero Idle Drift Pinning
RunService.RenderStepped:Connect(function()
	if not Character.Parent or not Humanoid.Parent or not RootPart then return end

	if Character:GetAttribute("IsMeditating") == true then
		StopMovementAudio()
		if activeLocomotionTrack and activeLocomotionTrack.IsPlaying then
			activeLocomotionTrack:Stop(0.05)
			activeLocomotionTrack = nil
		end
		return
	end

	local state = Humanoid:GetState()
	if state == Enum.HumanoidStateType.Jumping 
		or state == Enum.HumanoidStateType.Freefall 
		or state == Enum.HumanoidStateType.Climbing 
		or state == Enum.HumanoidStateType.Swimming then
		targetIdleYaw = nil
		return
	end

	if Humanoid.MoveDirection.Magnitude > 0.05 then
		-- Actively moving: clear idle pin and steer freely
		targetIdleYaw = nil
		local isSprinting = Humanoid.WalkSpeed > 20

		if isSprinting then
			SetLocomotionState("Run")
			if customWalkSound.IsPlaying then customWalkSound:Stop() end
			customRunSound.PlaybackSpeed = 1.0
			if not customRunSound.IsPlaying then customRunSound:Play() end
		else
			SetLocomotionState("Walk")
			if customRunSound.IsPlaying then customRunSound:Stop() end
			customWalkSound.PlaybackSpeed = math.clamp(Humanoid.WalkSpeed / 18.0, 0.8, 1.4)
			if not customWalkSound.IsPlaying then customWalkSound:Play() end
		end
	else
		-- STANDING IDLE: Capture exact facing angle and pin it firmly
		SetLocomotionState("Idle")
		StopMovementAudio()

		if not targetIdleYaw then
			local _, y, _ = RootPart.CFrame:ToOrientation()
			targetIdleYaw = y
		end

		-- Lock rotation firmly to targetIdleYaw (only when not in focus target mode)
		if Character:GetAttribute("IsFocusMode") ~= true and targetIdleYaw then
			RootPart.AssemblyAngularVelocity = Vector3.zero
			RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, targetIdleYaw, 0)
		end
	end
end)