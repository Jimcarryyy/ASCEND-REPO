--!strict
--[[
    Animate.client.luau
    Location: src/StarterPlayer/StarterCharacterScripts/Animate.client.luau
    Master R6 Movement Animation & Audio Sync Engine for ASCEND.
    Features: Normal 1.0x Run Audio Beat Matching, Fast 32-Speed Sprinting, Snappy Jump Power 65, and 100% Idle Spin Lock.
]]

local Character = script.Parent :: Model
local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid?
local RootPart = Character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
local Animator = if Humanoid then Humanoid:WaitForChild("Animator", 5) :: Animator? else nil

if not Humanoid or not RootPart or not Animator then
	warn("[Animate] Required character instances missing!")
	return
end

-- Apply Snappy Jump Power
Humanoid.JumpPower = 65

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local moveCfg = AnimationConfig.Movement

-- Disable Tripping / Ragdoll Physics States
Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

-- Custom Looped Movement Audio IDs
local WALK_SOUND_ID = "rbxassetid://4416041299"       -- 5.851s Looped Walk Audio
local RUN_SOUND_ID  = "rbxassetid://79250663775359" -- 4.284s Looped Run Audio

local currentLocomotionState = "None"
local activeLocomotionTrack: AnimationTrack? = nil
local loadedLocomotionTracks: { [string]: AnimationTrack } = {}

local freefallStartTime = 0
local canJump = true
local idleLockCFrame: CFrame? = nil

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
		print(string.format("[Animate] Dynamically bound track '%s' (%s).", animName, cleanId))
		return trk
	else
		warn(string.format("[Animate] Failed to load track '%s' (%s): %s", animName, cleanId, tostring(trk)))
	end
	return nil
end

-- Pre-Warm all locomotion tracks
local trackIdle  = GetLocomotionTrack("Idle", moveCfg.Idle, Enum.AnimationPriority.Idle, true)
local trackWalk  = GetLocomotionTrack("Walk", moveCfg.Walk, Enum.AnimationPriority.Action2, true)
local trackRun   = GetLocomotionTrack("Run", moveCfg.Run, Enum.AnimationPriority.Action3, true)
local trackJump  = GetLocomotionTrack("Jump", moveCfg.Jump, Enum.AnimationPriority.Action4, false)
local trackFall  = GetLocomotionTrack("Fall", moveCfg.Fall, Enum.AnimationPriority.Action4, true)
local trackLand  = GetLocomotionTrack("Land", moveCfg.Land, Enum.AnimationPriority.Action4, false)
local trackClimb = GetLocomotionTrack("Climb", moveCfg.Climb, Enum.AnimationPriority.Action2, true)
local trackSwim  = GetLocomotionTrack("Swim", moveCfg.Swim, Enum.AnimationPriority.Action2, true)

local function SetLocomotionState(newState: string)
	if currentLocomotionState == newState then return end
	currentLocomotionState = newState

	local targetTrack: AnimationTrack? = nil

	if newState == "Idle" then
		targetTrack = trackIdle
		if RootPart then
			idleLockCFrame = CFrame.new(RootPart.Position) * RootPart.CFrame.Rotation
		end
	else
		idleLockCFrame = nil
	end

	if newState == "Walk" then targetTrack = trackWalk
	elseif newState == "Run" then targetTrack = trackRun
	elseif newState == "Jump" then targetTrack = trackJump
	elseif newState == "Fall" then targetTrack = trackFall
	elseif newState == "Land" then targetTrack = trackLand
	elseif newState == "Climb" then targetTrack = trackClimb
	elseif newState == "Swim" then targetTrack = trackSwim
	end

	if activeLocomotionTrack and activeLocomotionTrack ~= targetTrack then
		activeLocomotionTrack:Stop(0.12)
	end

	activeLocomotionTrack = targetTrack
	if targetTrack and not targetTrack.IsPlaying then
		if newState == "Jump" then
			targetTrack:Play(0.05, 1, 1.4) -- 1.4x Accelerated Jump Takeoff
		else
			targetTrack:Play(0.12)
		end
		print(string.format("[Animate] Playing locomotion state '%s'.", newState))
	end
end

-- Start default Idle track
SetLocomotionState("Idle")

-- Stop all custom locomotion audio
local function StopMovementAudio()
	if customWalkSound.IsPlaying then customWalkSound:Stop() end
	if customRunSound.IsPlaying then customRunSound:Stop() end
end

-- Humanoid State Change Listener
Humanoid.StateChanged:Connect(function(_, newState)
	if Character:GetAttribute("IsMeditating") == true then
		StopMovementAudio()
		return
	end

	if newState == Enum.HumanoidStateType.Jumping then
		if not canJump then
			Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			return
		end

		freefallStartTime = os.clock()
		SetLocomotionState("Jump")
		PlayImpactAudio(soundJumping)
		StopMovementAudio()

	elseif newState == Enum.HumanoidStateType.Freefall then
		freefallStartTime = os.clock()
		task.delay(0.35, function()
			if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and (os.clock() - freefallStartTime) >= 0.35 then
				SetLocomotionState("Fall")
			end
		end)

	elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp then
		SetLocomotionState("Land")
		PlayImpactAudio(soundLanding)

		-- 0.3s Jump Recovery Debounce
		canJump = false
		task.delay(0.3, function()
			canJump = true
		end)

		task.delay(0.18, function()
			if Humanoid.MoveDirection.Magnitude > 0.05 then
				local isSprinting = Humanoid.WalkSpeed > 20
				SetLocomotionState(if isSprinting then "Run" else "Walk")
			else
				SetLocomotionState("Idle")
			end
		end)

	elseif newState == Enum.HumanoidStateType.Swimming then
		SetLocomotionState("Swim")
		StopMovementAudio()

	elseif newState == Enum.HumanoidStateType.Climbing then
		SetLocomotionState("Climb")
		StopMovementAudio()
	end
end)

-- Continuous Locomotion & Audio Loop
RunService.RenderStepped:Connect(function()
	if not Character.Parent or not Humanoid.Parent then return end

	-- 100% IDLE ROTATION LOCK
	if currentLocomotionState == "Idle" and RootPart and idleLockCFrame then
		RootPart.AssemblyAngularVelocity = Vector3.zero
		RootPart.CFrame = CFrame.new(RootPart.Position) * idleLockCFrame.Rotation
	end

	if Character:GetAttribute("IsMeditating") == true then
		StopMovementAudio()
		return
	end

	local state = Humanoid:GetState()
	if state == Enum.HumanoidStateType.Jumping 
		or state == Enum.HumanoidStateType.Freefall 
		or state == Enum.HumanoidStateType.Climbing 
		or state == Enum.HumanoidStateType.Swimming then
		return
	end

	if Humanoid.MoveDirection.Magnitude > 0.05 then
		local isSprinting = Humanoid.WalkSpeed > 20

		if isSprinting then
			SetLocomotionState("Run")
			if customWalkSound.IsPlaying then customWalkSound:Stop() end
			customRunSound.PlaybackSpeed = 1.0 -- Normal speed matches running footstep beat 1:1
			if not customRunSound.IsPlaying then customRunSound:Play() end
		else
			SetLocomotionState("Walk")
			if customRunSound.IsPlaying then customRunSound:Stop() end
			customWalkSound.PlaybackSpeed = math.clamp(Humanoid.WalkSpeed / 14.0, 0.8, 1.5)
			if not customWalkSound.IsPlaying then customWalkSound:Play() end
		end
	else
		SetLocomotionState("Idle")
		StopMovementAudio()
	end
end)