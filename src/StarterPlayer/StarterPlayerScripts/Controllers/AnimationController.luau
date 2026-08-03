--!strict
--[[
    AnimationController.luau
    Client controller for playing character attack animations,
    instant mouse rotation, smooth walkspeed action layering, and floating meditation camera framing.
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

        -- Smooth Camera Transition Logic
        local camTween: Tween? = nil

        if data.IsMeditating or data.IsTribulationActive then
            InputController.SetEnabled(false)

            camera.CameraType = Enum.CameraType.Scriptable
            local baseCFrame = hrp.CFrame
            local camDistance = if data.IsTribulationActive then -18.5 else -13.5
            local camHeight = if data.IsTribulationActive then 3.2 else 1.8
            local targetCFrame = (baseCFrame * CFrame.new(0, camHeight, camDistance)) * CFrame.Angles(0, math.rad(180), 0)

            if camTween then camTween:Cancel() end
            camTween = TweenService:Create(camera, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                CFrame = targetCFrame
            })
            camTween:Play()
        else
            InputController.SetEnabled(true)
            if camera.CameraType == Enum.CameraType.Scriptable then
                if camTween then camTween:Cancel() end
                camTween = TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    CFrame = hrp.CFrame * CFrame.new(0, 2, 12)
                })
                camTween:Play()
                camTween.Completed:Connect(function()
                    if not (data.IsMeditating or data.IsTribulationActive) then
                        camera.CameraType = Enum.CameraType.Custom
                    end
                end)
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

	if skillKey == "Shift" then
		local moveDir = humanoid.MoveDirection
		local dashDir = if moveDir.Magnitude > 0 then moveDir.Unit else hrp.CFrame.LookVector
		
		local dashImpulse = dashDir * 75 + Vector3.new(0, 8, 0)
		hrp.AssemblyLinearVelocity = dashImpulse

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
			humanoid.WalkSpeed = 16
		end
	end)
end

return AnimationController