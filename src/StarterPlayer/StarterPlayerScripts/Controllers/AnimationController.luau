--!strict
--[[
    AnimationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau
    Updates:
      - Hit Reaction Animation Completely Removed: Eliminates animation-induced ground collapse/ragdoll.
        Damage feedback is delivered purely through camera shake, red flash, and audio.
      - Phase 5.1: M1 Forward Step & Anticipation Lunge.
      - Phase 3: Two-Phase Slash Speed Curve (slow windup 0.55x -> fast strike commit 1.65x).
      - 4-Way Dash with Shunpo Vanish/Reappear Effect.
      - M1 Body Twist Fix: Locks AutoRotate during attack so avatar never spins mid-slash.
      - A6 Attribute Governance for WalkSpeed.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}
local activeAttackTrack: AnimationTrack? = nil
local blockTrack: AnimationTrack? = nil
local flightTrack: AnimationTrack? = nil
local animPlayedConn: RBXScriptConnection? = nil

local SWORD_SLASH_SOUND_ID = "rbxassetid://79218449800283"
local DASH_SOUND_ID        = "rbxasset://sounds/swordlunge.wav"
local MEDITATION_ANIM_ID   = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Meditation) or "rbxassetid://129333803961409"
local FLIGHT_ANIM_ID       = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Flight) or "rbxassetid://81098622855235"

local meditationTrack: AnimationTrack? = nil
local isCurrentlyMeditating = false
local meditationRequestId = 0

local DASH_BURST_SPEED = 125.0
local DASH_DURATION    = 0.28
local DASH_FLOAT_LIFT  = 0.35
local DASH_WALL_SLOW_SPEED = 14.0
local DASH_WALL_CHECK_DISTANCE = 5.0

local function PlayLocalSFX(soundId: string, volume: number?, speed: number?)
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.95
	sound.PlaybackSpeed = speed or (math.random(98, 102) / 100)
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

-- Shunpo Disappear/Reappear Helper
local function SetCharacterVanish(character: Model, vanish: boolean)
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = if vanish then 0.92 else 0
		elseif part:IsA("Decal") then
			part.Transparency = if vanish then 0.92 else 0
		end
	end
end

local function SpawnDashAfterimage(character: Model)
	local afterimageModel = Instance.new("Model")
	afterimageModel.Name = "DashGhostSilhouette"

	local weaponId = character:GetAttribute("EquippedWeapon") :: string?
	local palette = ItemConfig.GetWeaponPalette(weaponId)

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local ghost = Instance.new("Part")
			ghost.Size = part.Size
			ghost.CFrame = part.CFrame
			ghost.Color = palette.PrimaryColor
			ghost.Material = Enum.Material.Neon
			ghost.Transparency = 0.45
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

	local baseFov = camera.FieldOfView
	local warpFov = baseFov + 6.5
	local fovTweenIn = TweenService:Create(camera, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = warpFov,
	})
	fovTweenIn:Play()
	fovTweenIn.Completed:Connect(function()
		TweenService:Create(camera, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			FieldOfView = baseFov,
		}):Play()
	end)
end

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
		character:SetAttribute("IsDashing", false)
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
			if activeAttackTrack and activeAttackTrack.IsPlaying then
				activeAttackTrack:Stop(0.04)
				activeAttackTrack = nil
			end
			if player.Character then
				player.Character:SetAttribute("IsAttacking", false)
				player.Character:SetAttribute("AttackSpeedDampen", nil)
				local hum = player.Character:FindFirstChildOfClass("Humanoid")
				if hum then hum.AutoRotate = true end
			end

			local effectType = payload and payload.Effect
			local duration = payload and payload.Duration or 0.5
			if effectType == "Stunned" or effectType == "GuardBroken" or effectType == "Staggered" then
				AnimationController.PlayStunAnimation(duration)
			end
		elseif target ~= player and skillKey == "Shift" then
			local otherChar = target.Character
			if otherChar then
				SpawnDashAfterimage(otherChar)
				task.delay(0.08, function()
					if otherChar.Parent then SpawnDashAfterimage(otherChar) end
				end)
			end
		end
	end)

	print("[ASCEND] AnimationController Initialized (Shunpo Vanish Dash & M1 AutoRotate Fix Active).")
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

	character:SetAttribute("IsBlocking", true)
	track:Play(0.05, 1, 1.0)
	blockTrack = track
end

function AnimationController.StopBlock()
	local trackKey = "FlyingSword_Block"
	local track = loadedTracks[trackKey]
	if track and track.IsPlaying then track:Stop(0.08) end
	blockTrack = nil

	local character = player.Character
	if character then
		character:SetAttribute("IsBlocking", false)
	end
end

function AnimationController.PlayStunAnimation(duration: number)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local moveCfg = AnimationConfig.Movement :: any
	local stunId = moveCfg.Parryed or (AnimationConfig.FlyingSword and AnimationConfig.FlyingSword.Stun.AnimationId)
	if not stunId or stunId == "" then return end

	local trackKey = "Combat_Stun"
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = stunId
		track = animator:LoadAnimation(animInstance)
		track.Priority = Enum.AnimationPriority.Action4
		loadedTracks[trackKey] = track
	end

	track:Play(0.05, 1, 1.0)
	task.delay(duration, function()
		if track and track.IsPlaying then track:Stop(0.1) end
	end)
end

function AnimationController.PlayEquipAnimation(isEquipping: boolean)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local moveCfg = AnimationConfig.Movement :: any
	local animId = if isEquipping then moveCfg.Equip else moveCfg.Unequip
	if not animId or animId == "" then return end

	local trackKey = if isEquipping then "Weapon_Equip" else "Weapon_Unequip"
	local track = loadedTracks[trackKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animId
		track = animator:LoadAnimation(animInstance)
		track.Priority = Enum.AnimationPriority.Action3
		track.Looped = false
		loadedTracks[trackKey] = track
	end

	local oppositeKey = if isEquipping then "Weapon_Unequip" else "Weapon_Equip"
	local oppositeTrack = loadedTracks[oppositeKey]
	if oppositeTrack and oppositeTrack.IsPlaying then
		oppositeTrack:Stop(0.12)
	end

	track:Play(0.15, 1, 1.0)
end

-- =============================================================================
-- HIT REACTION: REMOVED TO PREVENT ANIMATION-INDUCED RAGDOLL / FALLDOWN
-- =============================================================================
function AnimationController.PlayHitReaction(_reactionType: string?)
	-- Intentionally disabled: visual damage feedback is delivered cleanly via
	-- screen flash, camera impact shake, and floating damage numbers.
end

-- =============================================================================
-- 4-WAY DASH WITH SHUNPO VANISH & REAPPEAR REFINEMENT
-- =============================================================================
function AnimationController.PerformDash(_dashStep: number?, overrideDir: Vector3?, overrideDirCode: string?)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not hrp or not animator or humanoid.Health <= 0 then return end

	if character:GetAttribute("IsMeditating") == true or character:GetAttribute("IsFlying") == true then return end
	if character:GetAttribute("IsDashing") == true then return end

	character:SetAttribute("IsDashing", true)

	local cam = Workspace.CurrentCamera
	local dashDir: Vector3
	local dirCode: string = overrideDirCode or "W"

	if overrideDir and overrideDir.Magnitude > 0.1 then
		dashDir = overrideDir
	else
		local camLook = if cam then cam.CFrame.LookVector else hrp.CFrame.LookVector
		local camFlatCF = CFrame.lookAt(Vector3.zero, Vector3.new(camLook.X, 0, camLook.Z).Unit)

		local isW = UserInputService:IsKeyDown(Enum.KeyCode.W)
		local isS = UserInputService:IsKeyDown(Enum.KeyCode.S)
		local isA = UserInputService:IsKeyDown(Enum.KeyCode.A)
		local isD = UserInputService:IsKeyDown(Enum.KeyCode.D)

		local inputVec = Vector3.zero
		if isW then inputVec += Vector3.new(0, 0, -1) end
		if isS then inputVec += Vector3.new(0, 0, 1) end
		if isA then inputVec += Vector3.new(-1, 0, 0) end
		if isD then inputVec += Vector3.new(1, 0, 0) end

		if inputVec.Magnitude < 0.1 then
			if humanoid.MoveDirection.Magnitude > 0.1 then
				inputVec = camFlatCF:VectorToObjectSpace(humanoid.MoveDirection)
			else
				inputVec = Vector3.new(0, 0, -1)
			end
		end

		inputVec = inputVec.Unit

		if math.abs(inputVec.X) > math.abs(inputVec.Z) then
			dirCode = if inputVec.X > 0 then "D" else "A"
		else
			dirCode = if inputVec.Z > 0 then "S" else "W"
		end

		dashDir = camFlatCF:VectorToWorldSpace(inputVec)
	end

	local moveCfg = AnimationConfig.Movement :: any
	local animKey = "Dash_" .. dirCode
	local animId = moveCfg[animKey] or moveCfg.Dash_W or "rbxassetid://137006811308011"

	local track = loadedTracks[animKey]
	if not track or track.Parent == nil then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animId
		track = animator:LoadAnimation(animInstance)
		track.Priority = Enum.AnimationPriority.Action4
		track.Looped = false
		loadedTracks[animKey] = track
	end

	PlayLocalSFX(DASH_SOUND_ID, 1.0, 1.0)
	SpawnDashAfterimage(character)
	TriggerDashCameraFX()

	-- SHUNPO VANISH: Character dissolves into spectral blur
	SetCharacterVanish(character, true)
	track:Play(0.02, 1, 1.30)

	hrp.CFrame = hrp.CFrame + Vector3.new(0, DASH_FLOAT_LIFT, 0)
	humanoid:ChangeState(Enum.HumanoidStateType.Freefall)

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local hitWall = Workspace:Raycast(hrp.Position, dashDir * DASH_WALL_CHECK_DISTANCE, rayParams)

	local initialDashSpeed = if hitWall then DASH_WALL_SLOW_SPEED else DASH_BURST_SPEED

	local attach = hrp:FindFirstChild("DashAttachment") :: Attachment?
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "DashAttachment"
		attach.Parent = hrp
	end

	local camFlatLook = if cam then Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z).Unit else hrp.CFrame.LookVector
	local dashOrientation = Instance.new("AlignOrientation")
	dashOrientation.Name = "DashOrientationLock"
	dashOrientation.Attachment0 = attach
	dashOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	dashOrientation.Responsiveness = 45
	dashOrientation.MaxTorque = 9000000
	dashOrientation.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + camFlatLook)
	dashOrientation.Parent = hrp

	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "DashForce"
	linearVel.Attachment0 = attach
	linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVel.MaxAxesForce = Vector3.new(450000, 35000, 450000)
	linearVel.VectorVelocity = Vector3.new(dashDir.X * initialDashSpeed, 0.35, dashDir.Z * initialDashSpeed)
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.Parent = hrp

	local previousAutoRotate = humanoid.AutoRotate
	humanoid.AutoRotate = false

	task.delay(0.08, function()
		if character.Parent and character:GetAttribute("IsDashing") == true then
			SpawnDashAfterimage(character)
		end
	end)

	-- SHUNPO REAPPEAR & SNAP BRAKE
	task.delay(DASH_DURATION * 0.40, function()
		if linearVel and linearVel.Parent then
			local snapDecay = TweenService:Create(
				linearVel,
				TweenInfo.new(DASH_DURATION * 0.60, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{ VectorVelocity = Vector3.new(dashDir.X * 10, 0, dashDir.Z * 10) }
			)
			snapDecay:Play()
			snapDecay.Completed:Connect(function()
				if linearVel and linearVel.Parent then linearVel:Destroy() end
				if dashOrientation and dashOrientation.Parent then dashOrientation:Destroy() end
				if track and track.IsPlaying then track:Stop(0.08) end

				-- Instant snap back to full visibility at destination
				SetCharacterVanish(character, false)
				SpawnDashAfterimage(character)

				if humanoid and humanoid.Parent then
					humanoid.AutoRotate = previousAutoRotate
					humanoid:ChangeState(Enum.HumanoidStateType.Running)
				end
				character:SetAttribute("IsDashing", false)
			end)
		else
			SetCharacterVanish(character, false)
			if dashOrientation and dashOrientation.Parent then dashOrientation:Destroy() end
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = previousAutoRotate
				humanoid:ChangeState(Enum.HumanoidStateType.Running)
			end
			character:SetAttribute("IsDashing", false)
		end
	end)
end

-- =============================================================================
-- HEAVY M1 SWING EXECUTION WITH FORWARD LUNGE & TWO-PHASE SPEED CURVE
-- =============================================================================
function AnimationController.PlayAttackAnimation(skillKey: string, comboIndex: number?)
	local character = player.Character
	if not character then return end
	if character:GetAttribute("IsFlying") == true then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not hrp or not animator then return end

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

	-- AUTOROTATE LOCK: Prevents character from spinning its body mid-slash
	humanoid.AutoRotate = false

	character:SetAttribute("AttackSpeedDampen", animDef.WalkSpeedDampen or 6.0)
	character:SetAttribute("IsAttacking", true)

	local windupSpeed = animDef.WindupMultiplier or 0.55
	local strikeSpeed = animDef.StrikeMultiplier or 1.65
	local windupRatio = animDef.WindupRatio or 0.45
	local duration = animDef.CastDuration or 0.58
	local windupDuration = duration * windupRatio

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(animDef.FadeTime or 0.08, 1, windupSpeed)
	track:AdjustSpeed(windupSpeed)
	activeAttackTrack = track

	-- Windup-then-Snap Transition: Accelerates and steps forward at the exact instant the strike commits
	task.delay(windupDuration, function()
		if activeAttackTrack == track and track.IsPlaying and hrp.Parent then
			track:AdjustSpeed(strikeSpeed)

			-- FORWARD LUNGE: Steps forward in the attack direction with anticipation
			local stepDir = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z).Unit
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = { character }
			local hitWall = Workspace:Raycast(hrp.Position, stepDir * 2.5, rayParams)

			if not hitWall then
				local rootAtt = hrp:FindFirstChild("RootAttachment") :: Attachment?
				if not rootAtt then
					rootAtt = Instance.new("Attachment")
					rootAtt.Name = "RootAttachment"
					rootAtt.Parent = hrp
				end

				local existingStep = hrp:FindFirstChild("M1StepVelocity")
				if existingStep then existingStep:Destroy() end

				local isFinisher = (stepNum >= 5)
				local stepSpeed = if isFinisher then 36.0 else 24.0
				local stepDuration = if isFinisher then 0.14 else 0.11

				local stepVel = Instance.new("LinearVelocity")
				stepVel.Name = "M1StepVelocity"
				stepVel.Attachment0 = rootAtt
				stepVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
				stepVel.MaxAxesForce = Vector3.new(350000, 5000, 350000)
				stepVel.VectorVelocity = stepDir * stepSpeed
				stepVel.RelativeTo = Enum.ActuatorRelativeTo.World
				stepVel.Parent = hrp

				local stepTween = TweenService:Create(
					stepVel,
					TweenInfo.new(stepDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ VectorVelocity = Vector3.zero }
				)
				stepTween:Play()
				stepTween.Completed:Connect(function()
					if stepVel and stepVel.Parent then stepVel:Destroy() end
				end)
				Debris:AddItem(stepVel, stepDuration + 0.05)
			end
		end
	end)

	task.delay(duration, function()
		if trail and activeAttackTrack == track then trail.Enabled = false end
		if track and track.IsPlaying and activeAttackTrack == track then track:Stop(0.08) end
		if activeAttackTrack == track then
			character:SetAttribute("IsAttacking", false)
			character:SetAttribute("AttackSpeedDampen", nil)
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = true
			end
		end
	end)
end

return AnimationController