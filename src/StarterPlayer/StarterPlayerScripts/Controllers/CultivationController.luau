--!strict
-- CultivationController.luau
-- Client controller for meditation floating motion and camera offset adjustments.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CultivationController = {}
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local isMeditating = false
local meditationHeartbeat: RBXScriptConnection? = nil
local floatHeight = 0.5   -- Low float gap (0.5 studs)
local floatSpeed = 1.6    -- Slow, calm oscillation period

-- Starts calm floating and backs up camera distance
function CultivationController.StartMeditation(character: Model)
	if isMeditating then return end
	isMeditating = true

	local hrp = character:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	local humanoid = character:WaitForChild("Humanoid", 5) :: Humanoid?
	if not hrp or not humanoid then return end

	-- 1. Wide Cinematic Camera Offset (Backs up camera so player is comfortably framed)
	humanoid.CameraOffset = Vector3.new(0, 1.8, 8.5) -- Shift camera back by 8.5 studs

	TweenService:Create(camera, TweenInfo.new(1.0, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
		FieldOfView = 65 -- Calming, slightly wider field of view
	}):Play()

	-- 2. Smooth Calm Floating Sine-Wave Motion
	local startY = hrp.Position.Y
	local startTime = os.clock()

	meditationHeartbeat = RunService.Heartbeat:Connect(function()
		if not isMeditating or not hrp or not hrp.Parent then return end
		local elapsed = os.clock() - startTime
		local sineOffset = math.sin(elapsed * floatSpeed) * floatHeight
		
		-- Gentle vertical velocity smoothing (eliminates rapid bobbing)
		hrp.AssemblyLinearVelocity = Vector3.new(
			hrp.AssemblyLinearVelocity.X,
			math.cos(elapsed * floatSpeed) * 0.6,
			hrp.AssemblyLinearVelocity.Z
		)
	end)
end

-- Stops meditation, resets camera and floating motion
function CultivationController.StopMeditation(character: Model)
	if not isMeditating then return end
	isMeditating = false

	if meditationHeartbeat then
		meditationHeartbeat:Disconnect()
		meditationHeartbeat = nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.CameraOffset = Vector3.new(0, 0, 0)
	end

	TweenService:Create(camera, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FieldOfView = 70 -- Return to default FOV
	}):Play()
end

function CultivationController.Init()
	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	cultivationRemote.OnClientEvent:Connect(function(actionType: string, data: any)
		local character = player.Character
		if not character then return end

		if actionType == "StartMeditation" then
			CultivationController.StartMeditation(character)
		elseif actionType == "StopMeditation" then
			CultivationController.StopMeditation(character)
		end
	end)
end

CultivationController.Init()
return CultivationController