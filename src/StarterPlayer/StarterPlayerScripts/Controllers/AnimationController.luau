--!strict
--[[
    AnimationController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau
    Client controller for ASCEND animation state.
    Features:
    - Fixed 18-Stud Qi Flash-Step Dash (ForceLimitMode.PerAxis with Smooth Deceleration)
    - Dedicated Sound Spawner (Zero Slash SFX dropouts)
    - 5-Hit M1 Broadsword Combo & Custom Meditation Form
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)

local AnimationController = {}
AnimationController.__index = AnimationController

local player = Players.LocalPlayer
local currentWeapon = "FlyingSword"
local loadedTracks: { [string]: AnimationTrack } = {}
local activeAttackTrack: AnimationTrack? = nil

-- Audio IDs
local SWORD_SLASH_SOUND_ID = "rbxassetid://79218449800283"
local DASH_SOUND_ID = "rbxassetid://93272068959626"

-- Custom R6 Meditation Pose Asset ID
local MEDITATION_ANIM_ID = (AnimationConfig.Movement and (AnimationConfig.Movement :: any).Meditation) or "rbxassetid://129333803961409"
local meditationTrack: AnimationTrack? = nil
local isCurrentlyMeditating = false

-- Reliable Sound Spawner on Character Root
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

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	task.delay(1.5, function()
		if sound and sound.Parent then sound:Destroy() end
	end)
end

function AnimationController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	local updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")
	local updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	-- Preload All Animations & Audio
	task.spawn(function()
		local animsToPreload = {
			MEDITATION_ANIM_ID,
			SWORD_SLASH_SOUND_ID,
			DASH_SOUND_ID,
			"rbxassetid://118004062849712",
			"rbxassetid://87494050060721",
			"rbxassetid://129254042886405",
			"rbxassetid://78342794513338",
			"rbxassetid://133701354257850",
			"rbxassetid://140582503077234",
			"rbxassetid://111677132360566",
		}
		local instances = {}
		for _, id in ipairs(animsToPreload) do
			if id:find("rbxassetid://") then
				local a = Instance.new("Animation")
				a.AnimationId = id
				table.insert(instances, a)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(instances)
		end)
	end)

	-- Meditation State Handler
	updateCultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		local character = player.Character
		if not character then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
		if not humanoid or not animator then return end

		local newMeditatingState = (data.IsMeditating == true)
		character:SetAttribute("IsMeditating", newMeditatingState)

		if newMeditatingState ~= isCurrentlyMeditating then
			isCurrentlyMeditating = newMeditatingState

			if isCurrentlyMeditating then
				if activeAttackTrack and activeAttackTrack.IsPlaying then
					activeAttackTrack:Stop(0.05)
					activeAttackTrack = nil
				end

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
						if trackLength == 0 then trackLength = 1.0 end
						local holdTime = math.max(0.1, trackLength - 0.08)
						task.wait(holdTime)

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
		end
	end)

	updateSkillStateRemote.OnClientEvent:Connect(function(weaponType: string)
		currentWeapon = weaponType
		AnimationController.ClearLoadedTracks()
	end)

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		if attacker ~= player then
			if skillKey == "Shift" then
				local dashIdx = (type(payload) == "table" and payload.DashIndex) or 1
				AnimationController.PerformDash(attacker, dashIdx)
			else
				local comboIdx = (type(payload) == "table" and payload.ComboIndex) or 1
				AnimationController.PlayAttackAnimation(attacker, skillKey, comboIdx)
			end
		end
	end)

	print("[ASCEND] AnimationController Initialized (ForceLimitMode.PerAxis Dash Active).")
end

function AnimationController.ClearLoadedTracks()
	for _, track in pairs(loadedTracks) do
		track:Stop(0.05)
		track:Destroy()
	end
	table.clear(loadedTracks)
	activeAttackTrack = nil
end

-- =============================================================================
-- FULLY POWERED QI FLASH-STEP DASH
-- =============================================================================
function AnimationController.PerformDash(targetPlayer: Player, dashStep: number)
	local character = targetPlayer.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not humanoid or not hrp or not animator or humanoid.Health <= 0 then return end

	if character:GetAttribute("IsMeditating") == true then return end

	character:SetAttribute("IsDashing", true)

	-- 1. Play Dash SFX
	if targetPlayer == player then
		PlayLocalSFX(DASH_SOUND_ID, 1.0)
	end

	-- 2. Determine Dash Track
	local animId = if dashStep == 1 
		then ((AnimationConfig.Movement :: any).Dash_1 or "rbxassetid://118004062849712") 
		else ((AnimationConfig.Movement :: any).Dash_2 or "rbxassetid://87494050060721")

	local trackKey = "Dash_" .. tostring(dashStep)
	local track = loadedTracks[trackKey]
	if not track then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(0.02, 1, 1.35)

	-- 3. Calculate Direction
	local dashDir = humanoid.MoveDirection
	if dashDir.Magnitude < 0.1 then
		dashDir = hrp.CFrame.LookVector
	end
	dashDir = Vector3.new(dashDir.X, 0, dashDir.Z).Unit

	-- 4. Apply Force with ForceLimitMode.PerAxis
	if targetPlayer == player then
		local attach = hrp:FindFirstChild("DashAttachment") :: Attachment?
		if not attach then
			attach = Instance.new("Attachment")
			attach.Name = "DashAttachment"
			attach.Parent = hrp
		end

		local linearVel = Instance.new("LinearVelocity")
		linearVel.Name = "DashForce"
		linearVel.Attachment0 = attach
		linearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis -- CRITICAL: Enables MaxAxesForce!
		linearVel.MaxAxesForce = Vector3.new(250000, 0, 250000) -- Full horizontal push, zero Y-clipping
		linearVel.VectorVelocity = dashDir * 88 -- Delivers crisp ~18-stud dash distance
		linearVel.RelativeTo = Enum.ActuatorRelativeTo.World
		linearVel.Parent = hrp

		-- Smooth deceleration decay at the end of the dash
		task.delay(0.16, function()
			if linearVel and linearVel.Parent then
				local decayTween = TweenService:Create(linearVel, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					VectorVelocity = dashDir * 15,
				})
				decayTween:Play()
				decayTween.Completed:Connect(function()
					if linearVel and linearVel.Parent then linearVel:Destroy() end
					character:SetAttribute("IsDashing", false)
					if track and track.IsPlaying then track:Stop(0.08) end
				end)
			end
		end)
	else
		task.delay(0.24, function()
			character:SetAttribute("IsDashing", false)
			if track and track.IsPlaying then track:Stop(0.08) end
		end)
	end
end

function AnimationController.PlayAttackAnimation(attacker: Player, skillKey: string, comboIndex: number?)
	local character = attacker.Character
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

	if attacker == player and activeAttackTrack and activeAttackTrack.IsPlaying then
		activeAttackTrack:Stop(0.04)
	end

	local trackKey = currentWeapon .. "_" .. animKey
	local track = loadedTracks[trackKey]
	if not track then
		local animInstance = Instance.new("Animation")
		animInstance.AnimationId = animDef.AnimationId
		track = animator:LoadAnimation(animInstance)
		loadedTracks[trackKey] = track
	end

	-- 1. Reliable Slash Audio Playback
	if attacker == player then
		PlayLocalSFX(SWORD_SLASH_SOUND_ID, 0.95)
	end

	-- 2. Enable Trail
	local equippedSword = character:FindFirstChild("EquippedSword")
	local trail = if equippedSword then equippedSword:FindFirstChildOfClass("Trail") else nil
	if trail then
		trail.Enabled = true
	end

	if animDef.WalkSpeedDampen and humanoid then
		humanoid.WalkSpeed = animDef.WalkSpeedDampen
	end

	track.Priority = Enum.AnimationPriority.Action4
	track.Looped = false
	track:Play(animDef.FadeTime or 0.08, 1, animDef.Speed or 0.85)

	if attacker == player then
		activeAttackTrack = track
	end

	local duration = animDef.CastDuration or 0.44
	task.delay(duration, function()
		if trail and (attacker ~= player or activeAttackTrack == track) then
			trail.Enabled = false
		end
		if track and track.IsPlaying and (attacker ~= player or activeAttackTrack == track) then
			track:Stop(0.08)
		end
		if humanoid and humanoid.Parent and attacker == player then
			humanoid.WalkSpeed = 18
		end
	end)
end

return AnimationController