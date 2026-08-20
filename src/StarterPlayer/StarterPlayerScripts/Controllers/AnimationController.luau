--!strict
--[[
    AnimationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau
    Client controller for ASCEND animation state, Q-Key Instant Long Dash (`132236998171530`),
    combat skills, weapon skill animations, and custom meditation pose.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}

-- Custom R6 Meditation Pose Asset ID
local MEDITATION_ANIM_ID = (AnimationConfig.Movement and AnimationConfig.Movement.Meditation) or "rbxassetid://129333803961409"
local meditationTrack: AnimationTrack? = nil
local isCurrentlyMeditating = false

function AnimationController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")
	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	-- Preload Meditation Animation Asset into Client Memory
	task.spawn(function()
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = MEDITATION_ANIM_ID
		pcall(function()
			ContentProvider:PreloadAsync({ animInstance })
		end)
	end)

	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
		if not humanoid or not animator then return end

		local newMeditatingState = (data.IsMeditating == true)
		character:SetAttribute("IsMeditating", newMeditatingState)

		-- Execute Animation ONLY when meditation state actually changes
		if newMeditatingState ~= isCurrentlyMeditating then
			isCurrentlyMeditating = newMeditatingState

			if isCurrentlyMeditating then
				-- Start Meditation Animation Track
				if not meditationTrack then
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
					if not meditationTrack.IsPlaying then
						meditationTrack:Play(0.2)
					end

					local currentTrack = meditationTrack
					task.spawn(function()
						local trackLength = currentTrack.Length
						if trackLength == 0 then
							trackLength = 1.0
						end

						local holdTime = math.max(0.1, trackLength - 0.08)
						task.wait(holdTime)

						if meditationTrack == currentTrack and currentTrack.IsPlaying and isCurrentlyMeditating then
							currentTrack:AdjustSpeed(0)
						end
					end)
				end

			else
				-- Stop Meditation Animation Track
				if meditationTrack then
					if meditationTrack.IsPlaying then
						meditationTrack:AdjustSpeed(1)
						meditationTrack:Stop(0.2)
					end
					meditationTrack = nil
				end
			end
		end
	end)

	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string)
		currentWeapon = weaponType
		AnimationController.ClearLoadedTracks()
	end)

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		if attacker == player then
			AnimationController.PlayAttackAnimation(skillKey)
		end
	end)

	print("[ASCEND] AnimationController Initialized with Q-Key Instant Long Dash Support.")
end

function AnimationController.ClearLoadedTracks()
	for _, track in pairs(loadedTracks) do
		track:Stop(0.05)
		track:Destroy()
	end
	table.clear(loadedTracks)
end

function AnimationController.PlayAttackAnimation(skillKey: string)
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not humanoid or not hrp then return end

	-- Q-KEY INSTANT LONG DASH (`132236998171530`)
	if skillKey == "Q" then
		local moveDir = humanoid.MoveDirection
		local dashDir = if moveDir.Magnitude > 0 then moveDir.Unit else hrp.CFrame.LookVector

		-- Exaggerated high-velocity forward impulse (120 speed)
		local dashImpulse = dashDir * 120 + Vector3.new(0, 10, 0)
		hrp.AssemblyLinearVelocity = dashImpulse

		local animator = humanoid:FindFirstChildOfClass("Animator")
		local track = nil
		if animator then
			local animObj = Instance.new("Animation")
			animObj.AnimationId = "rbxassetid://132236998171530"
			pcall(function()
				track = animator:LoadAnimation(animObj)
			end)
		end

		if track then
			track.Priority = Enum.AnimationPriority.Action4
			track.Looped = false
			track:Play(0.02, 5, 1.0)
		end

		humanoid.WalkSpeed = 36

		-- Exactly 0.43s duration recovery
		task.delay(0.43, function()
			if track and track.IsPlaying then
				track:Stop(0.1)
			end
			if humanoid and humanoid.Parent then
				local InputController = require(script.Parent:WaitForChild("InputController") :: ModuleScript)
				local isSprinting = if InputController and InputController.IsSprinting then InputController.IsSprinting() else false
				humanoid.WalkSpeed = if isSprinting then 32 else 14
			end
		end)
		return
	end

	-- Shift Dash
	if skillKey == "Shift" then
		local moveDir = humanoid.MoveDirection
		local dashDir = if moveDir.Magnitude > 0 then moveDir.Unit else hrp.CFrame.LookVector
		
		local dashImpulse = dashDir * 75 + Vector3.new(0, 8, 0)
		hrp.AssemblyLinearVelocity = dashImpulse

		humanoid.WalkSpeed = 32
		task.delay(0.22, function()
			if humanoid and humanoid.Parent then
				humanoid.WalkSpeed = 14
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

	local trackKey = currentWeapon .. "_" .. skillKey
	local track = loadedTracks[trackKey]
	if not track then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	track.Priority = Enum.AnimationPriority.Action
	track.Looped = false
	track:Play(animDef.FadeTime, 1, animDef.Speed)

	humanoid.WalkSpeed = animDef.WalkSpeedDampen

	task.delay(animDef.CastDuration, function()
		if track and track.IsPlaying then
			track:Stop(0.15)
		end
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = 14
		end
	end)
end

return AnimationController