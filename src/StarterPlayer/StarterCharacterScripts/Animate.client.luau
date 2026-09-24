--!strict
--[[
    Animate.client.luau
    Location: src/StarterPlayer/StarterCharacterScripts/Animate.client.luau
    Master R6 Movement Animation & Audio Sync Engine for ASCEND.
    Features:
      - Dual-State Running Engine: Normal running (without sword) vs SwordRun (holding sword, ID: 99873197987148).
      - Synced Locomotion Pacing: Both normal run and sword run play at 0.70x playback speed for weighted wuxia strides.
      - Upper-Body Idle Layering: Torso, arms, and blade maintain steady posture while moving unarmed.
      - Synced 0.70x footstep audio cadence.
      - 76 JumpPower with instant takeoff.
]]

local Character = script.Parent :: Model
local Humanoid = Character:WaitForChild("Humanoid", 5) :: Humanoid?
local RootPart = Character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
local Torso = Character:WaitForChild("Torso", 5) :: BasePart?
local Animator = if Humanoid then Humanoid:WaitForChild("Animator", 5) :: Animator? else nil

if not Humanoid or not RootPart or not Torso or not Animator then
	warn("[Animate] Required character instances missing!")
	return
end

Humanoid.JumpPower = 76
Humanoid.JumpHeight = 8.5
Humanoid.MaxSlopeAngle = 89

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local moveCfg = AnimationConfig.Movement

Humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
Humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

local WALK_SOUND_ID       = "rbxassetid://4416041299"
local RUN_STONE_SOUND_ID  = "rbxassetid://79250663775359"
local RUN_GRASS_SOUND_ID  = "rbxassetid://92240090015142"

local currentLocomotionState = "None"
local activeLocomotionTrack: AnimationTrack? = nil
local loadedLocomotionTracks: { [string]: AnimationTrack } = {}

local isDeliberateJump = false
local freefallStartTime = 0
local canJump = true
local targetIdleYaw: number? = nil

local rightShoulder = Torso:WaitForChild("Right Shoulder", 5) :: Motor6D?
local leftShoulder  = Torso:WaitForChild("Left Shoulder", 5) :: Motor6D?
local neck          = Torso:WaitForChild("Neck", 5) :: Motor6D?

local cachedIdleRShoulder = CFrame.identity
local cachedIdleLShoulder = CFrame.identity
local cachedIdleNeck      = CFrame.identity

local customWalkSound = Instance.new("Sound")
customWalkSound.Name = "CustomWalkAudio"
customWalkSound.SoundId = WALK_SOUND_ID
customWalkSound.Looped = true
customWalkSound.Volume = 0.65
customWalkSound.Parent = RootPart

local customRunStoneSound = Instance.new("Sound")
customRunStoneSound.Name = "CustomRunStoneAudio"
customRunStoneSound.SoundId = RUN_STONE_SOUND_ID
customRunStoneSound.Looped = true
customRunStoneSound.Volume = 0.75
customRunStoneSound.PlaybackSpeed = 0.70
customRunStoneSound.Parent = RootPart

local customRunGrassSound = Instance.new("Sound")
customRunGrassSound.Name = "CustomRunGrassAudio"
customRunGrassSound.SoundId = RUN_GRASS_SOUND_ID
customRunGrassSound.Looped = true
customRunGrassSound.Volume = 0.75
customRunGrassSound.PlaybackSpeed = 0.70
customRunGrassSound.Parent = RootPart

task.spawn(function()
	local defaultRunning = RootPart:WaitForChild("Running", 3) :: Sound?
	if defaultRunning then
		defaultRunning.Volume = 0
		defaultRunning:GetPropertyChangedSignal("Volume"):Connect(function()
			defaultRunning.Volume = 0
		end)
	end
end)

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

local function SanitizeAssetId(id: string): string
	if not id or id == "" then return "" end
	local clean = id:match("rbxassetid://%d+") or id:match("%d+")
	return if clean then "rbxassetid://" .. clean:gsub("%D", "") else ""
end

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

local trackIdle     = GetLocomotionTrack("Idle", moveCfg.Idle, Enum.AnimationPriority.Idle, true)
local trackWalk     = GetLocomotionTrack("Walk", moveCfg.Walk, Enum.AnimationPriority.Movement, true)
local trackRun      = GetLocomotionTrack("Run", moveCfg.Run, Enum.AnimationPriority.Movement, true)
local trackSwordRun = GetLocomotionTrack("SwordRun", (moveCfg :: any).SwordRun or "rbxassetid://99873197987148", Enum.AnimationPriority.Movement, true)
local trackJump     = GetLocomotionTrack("Jump", moveCfg.Jump, Enum.AnimationPriority.Action2, false)
local trackFall     = GetLocomotionTrack("Fall", moveCfg.Fall, Enum.AnimationPriority.Action2, true)
local trackLand     = GetLocomotionTrack("Land", moveCfg.Land, Enum.AnimationPriority.Action2, false)
local trackClimb    = GetLocomotionTrack("Climb", moveCfg.Climb, Enum.AnimationPriority.Movement, true)
local trackSwim     = GetLocomotionTrack("Swim", moveCfg.Swim, Enum.AnimationPriority.Movement, true)

-- Helper to determine if the player is actively holding their sword in hand
local function IsHoldingSword(): boolean
	local hasSword = Character:FindFirstChild("EquippedSword") ~= nil
	local isDrawn = Character:GetAttribute("IsWeaponDrawn")
	return hasSword and (isDrawn == true or (isDrawn == nil and Character:GetAttribute("EquippedWeapon") ~= nil))
end

local function SetLocomotionState(newState: string)
	if currentLocomotionState == newState then return end
	currentLocomotionState = newState

	local targetTrack: AnimationTrack? = nil

	if newState == "Walk" then targetTrack = trackWalk
	elseif newState == "Run" then targetTrack = trackRun
	elseif newState == "SwordRun" then targetTrack = trackSwordRun
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
			targetTrack:Play(0.04, 1, 1.25)
		elseif newState == "Land" then
			targetTrack:Play(0.05, 1, 1.30)
		elseif newState == "Run" then
			-- Sluggish, weighted wuxia stride pacing (0.70x)
			targetTrack:Play(0.12, 1, 0.70)
		elseif newState == "SwordRun" then
			-- Matched to normal running pacing (0.70x) for smooth, weighted strides
			targetTrack:Play(0.12, 1, 0.70)
		else
			targetTrack:Play(0.1)
		end
	end
end

SetLocomotionState("Idle")

local function StopMovementAudio()
	if customWalkSound.IsPlaying then customWalkSound:Stop() end
	if customRunStoneSound.IsPlaying then customRunStoneSound:Stop() end
	if customRunGrassSound.IsPlaying then customRunGrassSound:Stop() end
end

local function IsGrassSurface(mat: Enum.Material): boolean
	return mat == Enum.Material.Grass
		or mat == Enum.Material.LeafyGrass
		or mat == Enum.Material.Ground
		or mat == Enum.Material.Mud
end

local function PlayActiveRunAudio()
	local onGrass = IsGrassSurface(Humanoid.FloorMaterial)

	if onGrass then
		if customRunStoneSound.IsPlaying then customRunStoneSound:Stop() end
		customRunGrassSound.PlaybackSpeed = 0.70
		if not customRunGrassSound.IsPlaying then customRunGrassSound:Play() end
	else
		if customRunGrassSound.IsPlaying then customRunGrassSound:Stop() end
		customRunStoneSound.PlaybackSpeed = 0.70
		if not customRunStoneSound.IsPlaying then customRunStoneSound:Play() end
	end
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

Character:GetAttributeChangedSignal("IsFlying"):Connect(function()
	local isFlying = Character:GetAttribute("IsFlying") == true
	if isFlying then
		StopAllLocomotionTracks()
	else
		if Humanoid.FloorMaterial == Enum.Material.Air or Humanoid:GetState() == Enum.HumanoidStateType.Freefall then
			SetLocomotionState("Fall")
		else
			SetLocomotionState("Idle")
		end
	end
end)

Character:GetAttributeChangedSignal("IsMeditating"):Connect(function()
	local isMed = Character:GetAttribute("IsMeditating") == true
	if isMed then
		StopAllLocomotionTracks()
	else
		SetLocomotionState("Idle")
	end
end)

Humanoid.StateChanged:Connect(function(_, newState)
	if Character:GetAttribute("IsFlying") == true or Character:GetAttribute("IsMeditating") == true then
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
			task.delay(0.15, function()
				if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and not isDeliberateJump then
					SetLocomotionState("Fall")
				end
			end)
		else
			task.delay(1.0, function()
				if Humanoid:GetState() == Enum.HumanoidStateType.Freefall and (os.clock() - freefallStartTime) >= 1.0 then
					SetLocomotionState("Fall")
				end
			end)
		end

	elseif newState == Enum.HumanoidStateType.Landed or newState == Enum.HumanoidStateType.GettingUp then
		isDeliberateJump = false
		SetLocomotionState("Land")
		PlayImpactAudio(soundLanding)

		canJump = false
		task.delay(0.18, function()
			canJump = true
		end)

		task.delay(0.16, function()
			if Character:GetAttribute("IsFlying") == true then return end
			if Humanoid.MoveDirection.Magnitude > 0.05 then
				local isSprinting = Humanoid.WalkSpeed > 18
				if isSprinting then
					SetLocomotionState(if IsHoldingSword() then "SwordRun" else "Run")
				else
					SetLocomotionState("Walk")
				end
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

-- Continuous Locomotion Loop
RunService.RenderStepped:Connect(function()
	if not Character.Parent or not Humanoid.Parent or not RootPart or not Torso then return end

	if Character:GetAttribute("IsFlying") == true or Character:GetAttribute("IsMeditating") == true then
		StopMovementAudio()
		if activeLocomotionTrack and activeLocomotionTrack.IsPlaying then
			activeLocomotionTrack:Stop(0.05)
			activeLocomotionTrack = nil
		end
		targetIdleYaw = nil
		return
	end

	local isAttacking  = Character:GetAttribute("IsAttacking") == true
	local isBlocking   = Character:GetAttribute("IsBlocking") == true
	local isStunned    = Character:GetAttribute("CCState") == "Stunned" or Character:GetAttribute("CCState") == "GuardBroken"
	local isDashing    = Character:GetAttribute("IsDashing") == true
	local isBlinking   = Character:GetAttribute("IsBlinking") == true
	local isFocusMode  = Character:GetAttribute("IsFocusMode") == true
	local isCombatMoving = isBlinking or Character:GetAttribute("IsChargingF") == true or isDashing

	if isCombatMoving then
		StopMovementAudio()
		targetIdleYaw = nil
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

	local isMoving = Humanoid.MoveDirection.Magnitude > 0.05

	if isMoving then
		targetIdleYaw = nil
		local isSprinting = Humanoid.WalkSpeed > 18

		if isSprinting then
			SetLocomotionState(if IsHoldingSword() then "SwordRun" else "Run")
			if customWalkSound.IsPlaying then customWalkSound:Stop() end
			PlayActiveRunAudio()
		else
			SetLocomotionState("Walk")
			if customRunStoneSound.IsPlaying then customRunStoneSound:Stop() end
			if customRunGrassSound.IsPlaying then customRunGrassSound:Stop() end
			customWalkSound.PlaybackSpeed = math.clamp(Humanoid.WalkSpeed / 16.0, 0.70, 1.2)
			if not customWalkSound.IsPlaying then customWalkSound:Play() end
		end

		-- UPPER-BODY IDLE PRESERVATION: Only apply for unarmed run / walk so custom SwordRun pose can animate freely
		if not isAttacking and currentLocomotionState ~= "SwordRun" and rightShoulder and leftShoulder and neck then
			rightShoulder.Transform = cachedIdleRShoulder
			leftShoulder.Transform = cachedIdleLShoulder
			neck.Transform = cachedIdleNeck
		end
	else
		SetLocomotionState("Idle")
		StopMovementAudio()

		if rightShoulder and leftShoulder and neck then
			cachedIdleRShoulder = rightShoulder.Transform
			cachedIdleLShoulder = leftShoulder.Transform
			cachedIdleNeck = neck.Transform
		end

		if not isFocusMode and not isAttacking and not isBlocking and not isStunned then
			if not targetIdleYaw then
				local _, y, _ = RootPart.CFrame:ToOrientation()
				targetIdleYaw = y
			end

			RootPart.AssemblyAngularVelocity = Vector3.zero
			RootPart.CFrame = CFrame.new(RootPart.Position) * CFrame.Angles(0, targetIdleYaw, 0)
		else
			targetIdleYaw = nil
		end
	end
end)