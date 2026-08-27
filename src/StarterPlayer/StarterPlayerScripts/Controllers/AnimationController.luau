--!strict
--[[
    AnimationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau
    Handles animations, combat footwork dampening, and seamless sprint resumption.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}
local activeAttackTrack: AnimationTrack? = nil
local blockTrack: AnimationTrack? = nil

local SWORD_SLASH_SOUND_ID = "rbxassetid://79218449800283"
local DASH_SOUND_ID = "rbxassetid://93272068959626"
local PARRY_CLASH_SOUND_ID = "rbxassetid://9114223175"

local MEDITATION_ANIM_ID = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Meditation) or "rbxassetid://129333803961409"
local meditationTrack: AnimationTrack? = nil
local isCurrentlyMeditating = false
local meditationRequestId = 0 -- Guards against a stale (superseded) meditation toggle resolving late

-- Dash tuning. DASH_BURST_DURATION and DASH_SPEED are tunable to taste —
-- these are a first-pass fix, not final balance numbers.
local DASH_BURST_DURATION = 0.22 -- seconds of full-speed dash before decay (was ~0.15s effective)
local DASH_SPEED = 78
local DASH_WALL_SLOW_SPEED = 12
local DASH_WALL_CHECK_DISTANCE = 4

local function PlayLocalSFX(soundId: string, volume: number?)
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then return end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.95
	sound.PlaybackSpeed = math.random(96, 104) / 100
	sound.Parent = hrp
	sound:Play()

	sound.Ended:Connect(function() sound:Destroy() end)
	task.delay(1.5, function()
		if sound and sound.Parent then sound:Destroy() end
	end)
end

-- Waits (bounded) for both Humanoid and its Animator child to exist. Fixes the
-- race where a cultivation/meditation update arrives before Animator has
-- finished loading on a freshly spawned character, which previously caused
-- the first meditation toggle after joining to silently do nothing.
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
		character:SetAttribute("IsAttacking", false)
	end)

	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		local character = player.Character
		if not character then return end

		local newMeditatingState = (data.IsMeditating == true)
		character:SetAttribute("IsMeditating", newMeditatingState)

		if newMeditatingState == isCurrentlyMeditating then
			return -- No actual change; avoid replaying/re-stopping the same track
		end

		meditationRequestId += 1
		local thisRequestId = meditationRequestId

		task.spawn(function()
			local humanoid, animator = WaitForAnimator(character, 3)
			if not humanoid or not animator then
				warn("[AnimationController] Meditation animation skipped — Animator not ready within timeout.")
				return
			end

			-- If the state changed again while we were waiting, this request is stale — drop it.
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
		end
	end)

	print("[ASCEND] AnimationController Initialized (Footwork & Anti-Sky Launch Active).")
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

function AnimationController.PerformDash(dashStep: number)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not hrp or not animator or humanoid.Health <= 0 then return end

	if character:GetAttribute("IsMeditating") == true then return end

	character:SetAttribute("IsDashing", true)
	PlayLocalSFX(DASH_SOUND_ID, 1.0)

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
	track:Play(0.02, 1, 1.35)

	local dashDir = humanoid.MoveDirection
	if dashDir.Magnitude < 0.1 then
		dashDir = hrp.CFrame.LookVector
	end
	dashDir = Vector3.new(dashDir.X, 0, dashDir.Z).Unit

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local hitWall = Workspace:Raycast(hrp.Position, dashDir * DASH_WALL_CHECK_DISTANCE, rayParams)

	local dashVelocity = if hitWall then dashDir * DASH_WALL_SLOW_SPEED else dashDir * DASH_SPEED

	local attach = hrp:FindFirstChild("DashAttachment") :: Attachment?
	if not attach then
		attach = Instance.new("Attachment")
		attach.Name = "DashAttachment"
		attach.Parent = hrp
	end

	local linearVel = Instance.new("LinearVelocity")
	linearVel.Name = "DashForce"
	linearVel.Attachment0 = attach
	linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	linearVel.MaxAxesForce = Vector3.new(200000, 30000, 200000)
	linearVel.VectorVelocity = Vector3.new(dashVelocity.X, 0, dashVelocity.Z)
	linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
	linearVel.Parent = hrp

	hrp.AssemblyLinearVelocity = Vector3.new(hrp.AssemblyLinearVelocity.X, math.clamp(hrp.AssemblyLinearVelocity.Y, -20, 2), hrp.AssemblyLinearVelocity.Z)

	-- CRITICAL FIX: Humanoid's own movement force was fighting the dash impulse the
	-- entire time (WalkSpeed kept trying to push the character at run/sprint speed
	-- simultaneously), which is why the dash previously looked like "still running
	-- with a dash animation layered on top" instead of an actual burst. Silencing
	-- WalkSpeed and AutoRotate for the duration of the burst lets the LinearVelocity
	-- actually control the character.
	local previousAutoRotate = humanoid.AutoRotate
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = false

	-- CRITICAL FIX: the original wall check only raycast once, at the very start of
	-- the dash. At 78 studs/sec the character could still reach a wall mid-burst with
	-- full force. This loop re-checks every frame for the burst's duration and softens
	-- velocity if a wall is imminent, instead of slamming into it uncontrolled.
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
			linearVel.VectorVelocity = dashDir * DASH_WALL_SLOW_SPEED
		end
	end)

	task.delay(DASH_BURST_DURATION, function()
		if dashHeartbeatConn then dashHeartbeatConn:Disconnect() end

		if linearVel and linearVel.Parent then
			local decayTween = TweenService:Create(linearVel, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				VectorVelocity = dashDir * 10,
			})
			decayTween:Play()
			decayTween.Completed:Connect(function()
				if linearVel and linearVel.Parent then linearVel:Destroy() end
				character:SetAttribute("IsDashing", false)
				if track and track.IsPlaying then track:Stop(0.08) end

				if humanoid and humanoid.Parent then
					humanoid.AutoRotate = previousAutoRotate
					local InputController = require(player.PlayerScripts.Controllers.InputController)
					local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
					local isSprinting = InputController.IsSprinting()
					humanoid.WalkSpeed = isSprinting and sprintSpeed or walkSpeed
				end
			end)
		else
			-- Safety: if linearVel was already destroyed some other way, still restore movement
			if humanoid and humanoid.Parent then
				humanoid.AutoRotate = previousAutoRotate
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

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not animator then return end

	local weaponConfig = AnimationConfig[currentWeapon]
	if not weaponConfig then return end

	local animKey = skillKey
	if skillKey == "M1" then
		animKey = "M1_" .. tostring(comboIndex or 1)
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

	local equippedSword = character:FindFirstChild("EquippedSword")
	local trail = if equippedSword then equippedSword:FindFirstChildOfClass("Trail") else nil
	if trail then trail.Enabled = true end

	-- Lock combat footwork attribute
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

		-- Restore sprint speed if sprint is toggled on, otherwise walk speed
		if humanoid and humanoid.Parent and activeAttackTrack == track then
			local InputController = require(player.PlayerScripts.Controllers.InputController)
			local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
			local isSprinting = InputController.IsSprinting()
			humanoid.WalkSpeed = isSprinting and sprintSpeed or walkSpeed
		end
	end)
end

return AnimationController