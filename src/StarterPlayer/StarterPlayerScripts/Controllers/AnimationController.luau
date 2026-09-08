--!strict
--[[
    AnimationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau
    Handles:
      - Lightning Flash-Step Dash with Elevation Hover & Anti-Trip Orientation Lock.
      - Sword slash particle emissions directly from equipped blade tip.
      - Movement Sound Governor (zero stuck footsteps on flight/jump spam).
      - Flight mode animation & suppression of ground animations.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}
local activeAttackTrack: AnimationTrack? = nil
local blockTrack: AnimationTrack? = nil
local flightTrack: AnimationTrack? = nil
local animPlayedConn: RBXScriptConnection? = nil

-- Audio Assets
local SWORD_SLASH_SOUND_ID = "rbxassetid://79218449800283"
local DASH_SOUND_ID = "rbxassetid://93272068959626"
local MEDITATION_ANIM_ID = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Meditation) or "rbxassetid://129333803961409"
local FLIGHT_ANIM_ID = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Flight) or "rbxassetid://81098622855235"

local meditationTrack: AnimationTrack? = nil
local isCurrentlyMeditating = false
local meditationRequestId = 0

--------------------------------------------------------------------------------
-- LIGHTNING DASH CONSTANTS (Explosive Impulse & Anti-Trip Protection)
--------------------------------------------------------------------------------
local DASH_BURST_DURATION = 0.16        -- Snappy 0.16s burst
local DASH_PEAK_SPEED = 150.0           -- Instant explosive velocity
local DASH_WALL_SLOW_SPEED = 14.0
local DASH_WALL_CHECK_DISTANCE = 5.0
local DASH_FLOAT_LIFT = 1.2             -- Elevates character 1.2 studs to clear ground friction

local function PlayLocalSFX(soundId: string, volume: number?, speed: number?)
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.95
	sound.PlaybackSpeed = speed or (math.random(96, 104) / 100)
	sound.Parent = hrp
	sound:Play()

	sound.Ended:Connect(function() sound:Destroy() end)
	Debris:AddItem(sound, 1.5)
end

local function WaitForAnimator(character: Model, timeout: number): (Humanoid?, Animator?)
	local startTime = os.clock()
	repeat
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
		if humanoid and animator then
			return humanoid, animator
		end
		task.wait(0.05)
	until os.clock() - startTime >= timeout or not character.Parent
	return nil, nil
end

function AnimationController.EmitSwordSlash(character: Model)
	local equippedSword = character:FindFirstChild("EquippedSword")
	if not equippedSword then return end

	local slashAtt = equippedSword:FindFirstChild("NormalSlashAnimation", true)
	if slashAtt then
		for _, pe in ipairs(slashAtt:GetDescendants()) do
			if pe:IsA("ParticleEmitter") then
				pe:Emit(pe:GetAttribute("EmitCount") or 2)
			end
		end
	end
end

-- =============================================================================
-- LIGHTNING DASH VISUAL POLISH: AFTERIMAGES & CAMERA IMPACT
-- =============================================================================
local function SpawnDashAfterimage(character: Model)
	local afterimageModel = Instance.new("Model")
	afterimageModel.Name = "DashGhostSilhouette"

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local ghost = Instance.new("Part")
			ghost.Size = part.Size
			ghost.CFrame = part.CFrame
			ghost.Color = Color3.fromRGB(56, 189, 248) -- Celestial Electric Cyan (#38BDF8)
			ghost.Material = Enum.Material.Neon
			ghost.Transparency = 0.42
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.CanTouch = false
			ghost.CanQuery = false
			ghost.Parent = afterimageModel

			TweenService:Create(ghost, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
			}):Play()
		end
	end

	afterimageModel.Parent = Workspace
	Debris:AddItem(afterimageModel, 0.28)
end

local function TriggerDashCameraFX()
	local camera = Workspace.CurrentCamera
	if not camera then return end

	-- 1. FOV Speed-Warp
	local baseFov = 70
	local warpFov = 79
	local fovTweenIn = TweenService:Create(camera, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = warpFov,
	})
	fovTweenIn:Play()
	fovTweenIn.Completed:Connect(function()
		TweenService:Create(camera, TweenInfo.new(0.20, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			FieldOfView = baseFov,
		}):Play()
	end)

	-- 2. Micro-Trauma Camera Shake
	local shakeStartTime = os.clock()
	local shakeDuration = 0.14
	local shakeConn: RBXScriptConnection? = nil

	shakeConn = RunService.RenderStepped:Connect(function()
		local elapsed = os.clock() - shakeStartTime
		if elapsed >= shakeDuration then
			if shakeConn then shakeConn:Disconnect() end
			return
		end

		local decay = 1 - (elapsed / shakeDuration)
		local rollJitter = (math.random() - 0.5) * math.rad(1.4) * decay
		local pitchJitter = (math.random() - 0.5) * math.rad(1.0) * decay
		local yDip = (math.random() - 0.5) * 0.1 * decay

		camera.CFrame = camera.CFrame * CFrame.Angles(pitchJitter, 0, rollJitter) * CFrame.new(0, yDip, 0)
	end)
end

-- =============================================================================
-- MOVEMENT SOUND GOVERNOR
-- =============================================================================
local function BindSoundGovernor(character: Model)
	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not humanoid then return end

	local runningSound: Sound? = nil

	local function hookSound()
		runningSound = hrp:WaitForChild("Running", 3) :: Sound?
		if runningSound then
			runningSound:GetPropertyChangedSignal("Playing"):Connect(function()
				local isFlying = character:GetAttribute("IsFlying") == true
				local inAir = (humanoid.FloorMaterial == Enum.Material.Air)
					or (humanoid:GetState() == Enum.HumanoidStateType.Jumping)
					or (humanoid:GetState() == Enum.HumanoidStateType.Freefall)

				if isFlying or inAir then
					runningSound:Stop()
					runningSound.Volume = 0
				end
			end)
		end
	end
	task.spawn(hookSound)

	local heartbeatConn: RBXScriptConnection? = nil
	heartbeatConn = RunService.Heartbeat:Connect(function()
		if not character.Parent or not hrp.Parent then
			if heartbeatConn then heartbeatConn:Disconnect() end
			return
		end

		if not runningSound or runningSound.Parent ~= hrp then
			runningSound = hrp:FindFirstChild("Running") :: Sound?
			return
		end

		local isFlying = character:GetAttribute("IsFlying") == true
		local inAir = (humanoid.FloorMaterial == Enum.Material.Air)
			or (humanoid:GetState() == Enum.HumanoidStateType.Jumping)
			or (humanoid:GetState() == Enum.HumanoidStateType.Freefall)
		local isMoving = humanoid.MoveDirection.Magnitude > 0.1

		if isFlying or inAir or not isMoving then
			if runningSound.Playing then runningSound:Stop() end
			runningSound.Volume = 0
		else
			runningSound.Volume = 0.65
		end
	end)
end

local function BindFlightListener(character: Model)
	local function syncFlight()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
		if not humanoid or not animator then return end

		local isFlying = character:GetAttribute("IsFlying") == true

		if isFlying then
			if activeAttackTrack and activeAttackTrack.IsPlaying then
				activeAttackTrack:Stop(0.05)
				activeAttackTrack = nil
			end
			if blockTrack and blockTrack.IsPlaying then
				blockTrack:Stop(0.05)
				blockTrack = nil
			end

			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				if track ~= flightTrack and track.Animation and track.Animation.AnimationId ~= FLIGHT_ANIM_ID then
					track:Stop(0.05)
				end
			end

			if not animPlayedConn then
				animPlayedConn = animator.AnimationPlayed:Connect(function(track)
					if character:GetAttribute("IsFlying") == true then
						if track ~= flightTrack and track.Animation and track.Animation.AnimationId ~= FLIGHT_ANIM_ID then
							track:Stop(0)
						end
					end
				end)
			end

			if not flightTrack or flightTrack.Parent == nil then
				local animInstance = Instance.new("Animation")
				animInstance.AnimationId = FLIGHT_ANIM_ID
				flightTrack = animator:LoadAnimation(animInstance)
				if flightTrack then
					flightTrack.Priority = Enum.AnimationPriority.Action4
					flightTrack.Looped = true
				end
			end

			if flightTrack and not flightTrack.IsPlaying then
				flightTrack:Play(0.15)
			end
		else
			if animPlayedConn then
				animPlayedConn:Disconnect()
				animPlayedConn = nil
			end

			if flightTrack and flightTrack.IsPlaying then
				flightTrack:Stop(0.2)
			end
			flightTrack = nil
		end
	end

	character:GetAttributeChangedSignal("IsFlying"):Connect(syncFlight)
	task.spawn(syncFlight)
end

function AnimationController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")
	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	player.CharacterAdded:Connect(function(character)
		AnimationController.ClearLoadedTracks()
		isCurrentlyMeditating = false
		meditationTrack = nil
		activeAttackTrack = nil
		blockTrack = nil
		flightTrack = nil
		character:SetAttribute("IsAttacking", false)
		character:SetAttribute("IsFlying", false)
		BindFlightListener(character)
		BindSoundGovernor(character)
	end)

	if player.Character then
		BindFlightListener(player.Character)
		BindSoundGovernor(player.Character)
	end

	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		local character = player.Character
		if not character then return end

		local newMeditatingState = (data.IsMeditating == true)
		character:SetAttribute("IsMeditating", newMeditatingState)

		if newMeditatingState == isCurrentlyMeditating then return end

		meditationRequestId += 1
		local thisRequestId = meditationRequestId

		task.spawn(function()
			local humanoid, animator = WaitForAnimator(character, 3)
			if not humanoid or not animator then return end
			if thisRequestId ~= meditationRequestId then return end

			isCurrentlyMeditating = newMeditatingState

			if isCurrentlyMeditating then
				if activeAttackTrack and activeAttackTrack.IsPlaying then
					activeAttackTrack:Stop(0.05)
					activeAttackTrack = nil
				end

				if not meditationTrack or meditationTrack.Parent == nil then
					local animInstance = Instance.new("Animation")
					animInstance.AnimationId = MEDITATION_ANIM_ID
					meditationTrack = animator:LoadAnimation(animInstance)
					if meditationTrack then
						meditationTrack.Priority = Enum.AnimationPriority.Action4
						meditationTrack.Looped = false
					end
				end

				if meditationTrack then
					meditationTrack:AdjustSpeed(1)
					meditationTrack.TimePosition = 0
					if not meditationTrack.IsPlaying then meditationTrack:Play(0.2) end

					local currentTrack = meditationTrack
					task.spawn(function()
						local trackLength = currentTrack.Length
						if trackLength == 0 then trackLength = 1.0 end
						task.wait(math.max(0.1, trackLength - 0.08))
						if meditationTrack == currentTrack and currentTrack.IsPlaying and isCurrentlyMeditating then
							currentTrack:AdjustSpeed(0)
						end
					end)
				end
			else
				if meditationTrack then
					if meditationTrack.IsPlaying then
						meditationTrack:AdjustSpeed(1)
						meditationTrack:Stop(0.2)
					end
					meditationTrack = nil
				end
			end
		end)
	end)

	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string)
		currentWeapon = weaponType
		AnimationController.ClearLoadedTracks()
	end)

	combatActionRemote.OnClientEvent:Connect(function(target: Player, skillKey: string, payload: any?)
		if target == player and skillKey == "StatusEffect" then
			local effectType = payload and payload.Effect
			local duration = payload and payload.Duration or 0.5
			if effectType == "Stunned" or effectType == "GuardBroken" then
				AnimationController.PlayStunAnimation(duration)
			end
		elseif target ~= player and skillKey == "Shift" then
			local otherChar = target.Character
			if otherChar then
				SpawnDashAfterimage(otherChar)
				task.delay(0.06, function()
					if otherChar.Parent then SpawnDashAfterimage(otherChar) end
				end)
			end
		end
	end)

	print("[ASCEND] AnimationController Initialized (Lightning Flash-Step Dash & Anti-Trip Active).")
end

function AnimationController.ClearLoadedTracks()
	for _, track in pairs(loadedTracks) do
		pcall(function()
			track:Stop(0.05)
			track:Destroy()
		end)
	end
	table.clear(loadedTracks)
	activeAttackTrack = nil
	blockTrack = nil
	meditationTrack = nil
	if animPlayedConn then
		animPlayedConn:Disconnect()
		animPlayedConn = nil
	end
	if flightTrack then
		pcall(function()
			flightTrack:Stop(0.05)
			flightTrack:Destroy()
		end)
		flightTrack = nil
	end
end

function AnimationController.StartBlock()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local swordCfg = AnimationConfig.FlyingSword :: any
	local blockDef = if swordCfg then swordCfg.Block else nil
	if not blockDef then return end

	local trackKey = "FlyingSword_Block"
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = blockDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		track.Priority = Enum.AnimationPriority.Action3
		loadedTracks[trackKey] = track
	end

	if humanoid and blockDef.WalkSpeedDampen then
		humanoid.WalkSpeed = blockDef.WalkSpeedDampen
	end

	track:Play(0.05, 1, 1.0)
	blockTrack = track
end

function AnimationController.StopBlock()
	local trackKey = "FlyingSword_Block"
	local track = loadedTracks[trackKey]
	if track and track.IsPlaying then track:Stop(0.08) end
	blockTrack = nil

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		local inArena = character:GetAttribute("InArena") == true
		humanoid.WalkSpeed = inArena and 16 or 18
	end
end

function AnimationController.PlayStunAnimation(duration: number)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local swordCfg = AnimationConfig.FlyingSword :: any
	local stunDef = if swordCfg then swordCfg.Stun else nil
	if not stunDef then return end

	local trackKey = "FlyingSword_Stun"
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = stunDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		track.Priority = Enum.AnimationPriority.Action4
		loadedTracks[trackKey] = track
	end

	track:Play(0.05, 1, 1.0)
	task.delay(duration, function()
		if track and track.IsPlaying then track:Stop(0.1) end
	end)
end

-- =============================================================================
-- LIGHTNING FLASH-STEP DASH (ANTI-TRIP ELEVATION & UPRIGHT LOCK)
-- =============================================================================
function AnimationController.PerformDash(dashStep: number)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not hrp or not animator or humanoid.Health <= 0 then return end

	if character:GetAttribute("IsMeditating") == true or character:GetAttribute("IsFlying") == true then return end

	character:SetAttribute("IsDashing", true)

	PlayLocalSFX(DASH_SOUND_ID, 1.0, 1.18)
	SpawnDashAfterimage(character)
	TriggerDashCameraFX()

	local animId = if dashStep == 1
		then ((AnimationConfig.Movement :: any).Dash_1 or "rbxassetid://118004062849712")
		else ((AnimationConfig.Movement :: any).Dash_2 or "rbxassetid://87494050060721")

	local trackKey = "Dash_" .. tostring(dashStep)
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(0.01, 1, 1.55)

	-- 1. Determine Dash Direction
	local dashDir = humanoid.MoveDirection
	if dashDir.Magnitude < 0.1 then
		dashDir = hrp.CFrame.LookVector
	end
	dashDir = Vector3.new(dashDir.X, 0, dashDir.Z).Unit

	-- 2. Anti-Trip Elevation Lift (Raises character +1.2 studs so feet don't drag on ground)
	hrp.CFrame = hrp.CFrame + Vector3.new(0, DASH_FLOAT_LIFT, 0)

	-- 3. Temporarily disable ground-friction solver to prevent tripping
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local hitWall = Workspace:Raycast(hrp.Position, dashDir * DASH_WALL_CHECK_DISTANCE, rayParams)

	local dashVelocity = if hitWall then dashDir * DASH_WALL_SLOW_SPEED else dashDir * DASH_PEAK_SPEED

	local attach = hrp:FindFirstChild("DashAttachment") :: Attachment?
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "DashAttachment"
		attach.Parent = hrp
	end

	-- 4. High-Torque Upright Lock (Makes it physically impossible to tumble or flip)
	local dashOrientation = Instance.new("AlignOrientation")
	dashOrientation.Name = "DashOrientationLock"
	dashOrientation.Attachment0 = attach
	dashOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	dashOrientation.Responsiveness = 40
	dashOrientation.MaxTorque = 10000000
	dashOrientation.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + dashDir)
	dashOrientation.Parent = hrp

	-- 5. Linear Impulse with gentle vertical float (+2.5 studs/s) to maintain elevation
	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "DashForce"
	linearVel.Attachment0 = attach
	linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVel.MaxAxesForce = Vector3.new(350000, 50000, 350000)
	linearVel.VectorVelocity = Vector3.new(dashVelocity.X, 2.5, dashVelocity.Z)
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.Parent = hrp

	hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, 3.0, hrp.AssemblyLinearVelocity.Z)

	local previousAutoRotate = humanoid.AutoRotate
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false

	-- Midpoint second ghost silhouette
	task.delay(0.06, function()
		if character.Parent and character:GetAttribute("IsDashing") == true then
			SpawnDashAfterimage(character)
		end
	end)

	local startTime = os.clock()
	local dashHeartbeatConn: RBXScriptConnection? = nil
	dashHeartbeatConn = RunService.Heartbeat:Connect(function()
		if not hrp.Parent or not linearVel.Parent then
			if dashHeartbeatConn then dashHeartbeatConn:Disconnect() end
			return
		end

		if os.clock() - startTime >= DASH_BURST_DURATION then
			if dashHeartbeatConn then dashHeartbeatConn:Disconnect() end
			return
		end

		local wallAhead = Workspace:Raycast(hrp.Position, dashDir * DASH_WALL_CHECK_DISTANCE, rayParams)
		if wallAhead then
			linearVel.VectorVelocity = Vector3.new(dashDir.X * DASH_WALL_SLOW_SPEED, 2.0, dashDir.Z * DASH_WALL_SLOW_SPEED)
		end
	end)

	-- Snappy brake & clean ground landing
	task.delay(DASH_BURST_DURATION, function()
		if dashHeartbeatConn then dashHeartbeatConn:Disconnect() end

		if linearVel and linearVel.Parent then
			local decayTween = TweenService:Create(linearVel, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				VectorVelocity = Vector3.new(dashDir.X * 15, 0, dashDir.Z * 15),
			})
			decayTween:Play()
			decayTween.Completed:Connect(function()
				if linearVel and linearVel.Parent then linearVel:Destroy() end
				if dashOrientation and dashOrientation.Parent then dashOrientation:Destroy() end
				character:SetAttribute("IsDashing", false)
				if track and track.IsPlaying then track:Stop(0.06) end

				if humanoid and humanoid.Parent then
					humanoid.AutoRotate = previousAutoRotate
					humanoid:ChangeState(Enum.HumanoidStateType.Running)
					local InputController = require(player.PlayerScripts.Controllers.InputController)
					local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
					local isSprinting = InputController.IsSprinting()
					humanoid.WalkSpeed = isSprinting and sprintSpeed or walkSpeed
				end
			end)
		else
			if dashOrientation and dashOrientation.Parent then dashOrientation:Destroy() end
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = previousAutoRotate
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
				local InputController = require(player.PlayerScripts.Controllers.InputController)
				local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
				local isSprinting = InputController.IsSprinting()
				humanoid.WalkSpeed = isSprinting and sprintSpeed or walkSpeed
			end
			character:SetAttribute("IsDashing", false)
		end
	end)
end

function AnimationController.PlayAttackAnimation(skillKey: string, comboIndex: number?)
	local character = player.Character
	if not character then return end
	if character:GetAttribute("IsFlying") == true then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local weaponConfig = AnimationConfig[currentWeapon]
	if not weaponConfig then return end

	local animKey = skillKey
	local stepNum = comboIndex or 1
	if skillKey == "M1" then
		animKey = "M1_" .. tostring(stepNum)
	end

	local animDef = weaponConfig[animKey] or weaponConfig[skillKey]
	if not animDef or animDef.AnimationId == "" then return end

	if activeAttackTrack and activeAttackTrack.IsPlaying then
		activeAttackTrack:Stop(0.04)
	end

	local trackKey = currentWeapon .. "_" .. animKey
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	PlayLocalSFX(SWORD_SLASH_SOUND_ID, 0.95)
	AnimationController.EmitSwordSlash(character)

	local equippedSword = character:FindFirstChild("EquippedSword")
	local trail = if equippedSword then equippedSword:FindFirstChildOfClass("Trail") else nil
	if trail then trail.Enabled = true end

	character:SetAttribute("IsAttacking", true)

	if animDef.WalkSpeedDampen and humanoid then
		humanoid.WalkSpeed = animDef.WalkSpeedDampen
	end

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(animDef.FadeTime or 0.08, 1, animDef.Speed or 0.85)
	activeAttackTrack = track

	local duration = animDef.CastDuration or 0.44
	task.delay(duration, function()
		if trail and activeAttackTrack == track then trail.Enabled = false end
		if track and track.IsPlaying and activeAttackTrack == track then track:Stop(0.08) end
		if activeAttackTrack == track then
			character:SetAttribute("IsAttacking", false)
		end

		if humanoid and humanoid.Parent and activeAttackTrack == track then
			local InputController = require(player.PlayerScripts.Controllers.InputController)
			local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
			local isSprinting = InputController.IsSprinting()
			humanoid.WalkSpeed = isSprinting and sprintSpeed or walkSpeed
		end
	end)
end

return AnimationController