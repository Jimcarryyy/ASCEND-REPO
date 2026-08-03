--!strict
--[[
    AnimationController.luau
    Client controller for playing character attack animations,
    instant mouse rotation, and smooth walkspeed action layering.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}

function AnimationController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")

	-- Custom Floating Meditation Track & Steady Front View Camera
	local MEDITATION_ANIM_ID = "rbxassetid://116333173300889"
	local meditationTrack: AnimationTrack? = nil
	local camera = Workspace.CurrentCamera

	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
		if not animator or not hrp then return end

		local InputController = require(script.Parent:WaitForChild("InputController") :: ModuleScript)

		if data.IsMeditating then
			-- Lock client movement keys
			InputController.SetEnabled(false)

			-- Start custom floating animation loop
			if not meditationTrack then
				local anim = Instance.new("Animation")
				anim.AnimationId = MEDITATION_ANIM_ID
				meditationTrack = animator:LoadAnimation(anim)
			end

			if meditationTrack and not meditationTrack.IsPlaying then
				meditationTrack.Priority = Enum.AnimationPriority.Action4
				meditationTrack.Looped = true
				-- Play at 0.65 speed for slow, serene floating motion
				meditationTrack:Play(0.6, 1, 0.65)
			end

			-- Calibrated Camera View (Backed up to 13.5 studs for comfortable framing)
			camera.CameraType = Enum.CameraType.Scriptable
			local baseCFrame = hrp.CFrame
			camera.CFrame = (baseCFrame * CFrame.new(0, 1.8, -13.5)) * CFrame.Angles(0, math.rad(180), 0)
		else
			-- Exit Meditation: Restore Camera & Unlock Controls
			camera.CameraType = Enum.CameraType.Custom
			InputController.SetEnabled(true)

			if meditationTrack and meditationTrack.IsPlaying then
				meditationTrack:Stop(0.4)
			end
		end
	end)

	-- Track weapon type changes
	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string)
		currentWeapon = weaponType
		AnimationController.ClearLoadedTracks()
	end)

	-- Listen for combat actions to play animation & smooth rotation locally
	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		if attacker == player then
			AnimationController.PlayAttackAnimation(skillKey)
		end
	end)

	print("[ASCEND] AnimationController Initialized.")
end

function AnimationController.ClearLoadedTracks()
	for _, track in pairs(loadedTracks) do
		track:Stop(0.05)
		track:Destroy()
	end
	table.clear(loadedTracks)
end

function AnimationController.SmoothRotateCharacter(aimDirection: Vector3)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local flatDir = Vector3.new(aimDirection.X, 0, aimDirection.Z)
	if flatDir.Magnitude > 0 then
		local targetCFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatDir.Unit)
		TweenService:Create(hrp, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCFrame
		}):Play()
	end
end

function AnimationController.PlayAttackAnimation(skillKey: string)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then return end

	-- Handle Shift Windstep Dash with directional dodge impulse
	if skillKey == "Shift" then
		local moveDir = humanoid.MoveDirection
		local dashDir = if moveDir.Magnitude > 0 then moveDir.Unit else hrp.CFrame.LookVector
		
		-- Physical lunge burst in WASD or facing direction
		local dashImpulse = dashDir * 75 + Vector3.new(0, 8, 0)
		hrp.AssemblyLinearVelocity = dashImpulse

		-- Speed boost
		humanoid.WalkSpeed = 32
		task.delay(0.22, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = 16
			end
		end)
		return
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end

	local weaponConfig = AnimationConfig[currentWeapon]
	if not weaponConfig then return end

	local animDef = weaponConfig[skillKey]
	if not animDef or animDef.AnimationId == "" then return end

	-- Load track or fetch cached
	local trackKey = currentWeapon .. "_" .. skillKey
	local track = loadedTracks[trackKey]
	if not track then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	-- Force Action priority & disable looping so pose doesn't freeze
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false

	-- Play animation with snappy blend
	track:Play(animDef.FadeTime, 1, animDef.Speed)

	-- Apply WalkSpeed dampening
	humanoid.WalkSpeed = animDef.WalkSpeedDampen

	-- Auto-stop animation and restore normal WalkSpeed
	task.delay(animDef.CastDuration, function()
		if track and track.IsPlaying then
			track:Stop(0.15)
		end
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = 16
		end
	end)
end

return AnimationController