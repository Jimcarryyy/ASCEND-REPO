--!strict
--[[
    InputController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
    Unified Input Controller with High-Impact Locomotion:
    - Sprint Speed Boosted to 44 studs/s (Arena: 34 studs/s)
    - Harmonic Running Camera Shake (stride-synced vertical bounce, lateral sway & roll)
    - Dynamic Speed-Tunnel FOV (70° -> 76° on sprint)
    - 3D Flight & Proximity Obstacle Cushion preserved
    - Permanent Anti-Trip Ground Physics Lock (FallingDown & Ragdoll permanently disabled)
    - Instant Velocity Arrest on Charge (Zero sliding/tripping when pressing F mid-sprint)
    - Natural Humanoid Locomotion Handoff (0.2s pause -> seamless sprint resumption)
    - 28-Stud Balanced Flash-Step Range
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local AnimationConfig = require(ReplicatedStorage.Shared.Configs.AnimationConfig)
local FlyingSwordConfig = require(ReplicatedStorage.Shared.Configs.Weapons.FlyingSwordConfig)

export type ActionPayload = {
	SkillKey: string,
	ComboIndex: number?,
	DashIndex: number?,
	AimDirection: Vector3,
	Origin: Vector3?,
	Timestamp: number,
}

local InputController = {}
InputController.__index = InputController

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = Workspace.CurrentCamera

local combatActionRemote: RemoteEvent
local updateCultivationRemote: RemoteEvent

local enabled = true
local isMeditating = false
local isSprinting = false
local isBlocking = false

local lastCPress = 0
local lastRPress = 0
local lastVPress = 0
local lastM1Press = 0
local lastDashPress = 0
local dashStep = 1
local DASH_COOLDOWN = 3.0

local currentAttackLockout = 0
local m1ComboIndex = 1
local COMBO_TIMEOUT = 1.3

local lastSkillQTime = 0
local isCastingSkillQ = false
local SWORD_RELEASE_SFX = "rbxassetid://109735549169421"

-- Ultimate F State
local isHoldingF = false
local isExecutingSkillF = false
local lastSkillFTime = 0
local chargeStartTimeF = 0
local wasSprintingBeforeF = false
local chargeTrackF: AnimationTrack? = nil
local slashTrackF: AnimationTrack? = nil

local FLIGHT_SPEED = 75.0
local VERTICAL_FLIGHT_SPEED = 42.0
local IDLE_DRIFT_DESCENT = -2.5
local FLIGHT_YAW_OFFSET = 90
local MIN_HOVER_ALTITUDE = 6.5
local HOVER_SPRING_STRENGTH = 18.0
local MIN_OBSTACLE_BUFFER = 8.5
local OBSTACLE_SPRING_STRENGTH = 15.0

local isAscending = false
local isDescending = false

local currentFovTarget = 70.0
local currentHeadBobWeight = 0.0

local flightLinearVel: LinearVelocity? = nil
local flightOrientation: AlignOrientation? = nil
local flightAttachment: Attachment? = nil

local function IsTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function EmitToast(message: string)
	local controllers = player.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local hudCtrl = controllers:FindFirstChild("HUDController")
		if hudCtrl then
			local req = require(hudCtrl) :: any
			if req and req.ShowToast then
				req.ShowToast(message)
			end
		end
	end
end

function InputController.GetLocomotionSpeeds(): (number, number)
	local character = player.Character
	local inArena = character and (character:GetAttribute("InArena") == true)
	if inArena then
		return 16, 34
	else
		return 18, 44
	end
end

function InputController.IsSprinting(): boolean
	return isSprinting
end

local function IsAnyMenuOpen(): boolean
	if UserInputService:GetFocusedTextBox() ~= nil then return true end
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return false end

	local uiNames = { "SpiritPouchInventoryGui", "AlchemyFurnaceGui", "SectMarketGui", "DialogueGui", "ArenaRegistrationGui", "SpiritCauldronAlchemyGui" }
	for _, name in ipairs(uiNames) do
		local gui = playerGui:FindFirstChild(name)
		if gui and gui:IsA("ScreenGui") and gui.Enabled then
			local backdrop = gui:FindFirstChild("OverlayBackdrop") or gui:FindFirstChild("MainFrame") or gui:FindFirstChild("MainModal")
			if backdrop and (backdrop :: Frame).Visible then
				return true
			end
		end
	end
	return false
end

local function StartFlightLocomotion(character: Model)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid then return end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoRotate = false

	if not flightAttachment or flightAttachment.Parent ~= hrp then
		flightAttachment = Instance.new("Attachment")
		flightAttachment.Name = "FlightAttachment"
		flightAttachment.Parent = hrp
	end

	if not flightOrientation or flightOrientation.Parent ~= hrp then
		flightOrientation = Instance.new("AlignOrientation")
		flightOrientation.Name = "FlightOrientationLock"
		flightOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		flightOrientation.Attachment0 = flightAttachment
		flightOrientation.Responsiveness = 35
		flightOrientation.MaxTorque = 10000000
		flightOrientation.Parent = hrp
	end

	if not flightLinearVel or flightLinearVel.Parent ~= hrp then
		flightLinearVel = Instance.new("LinearVelocity")
		flightLinearVel.Name = "FlightPhysicsEngine"
		flightLinearVel.Attachment0 = flightAttachment
		flightLinearVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
		flightLinearVel.MaxAxesForce = Vector3.new(300000, 300000, 300000)
		flightLinearVel.VectorVelocity = Vector3.zero
		flightLinearVel.RelativeTo = Enum.ActuatorRelativeTo.World
		flightLinearVel.Parent = hrp
	end

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = { character }
	local groundCheck = Workspace:Raycast(hrp.Position, Vector3.new(0, -10, 0), rayParams)
	if groundCheck and groundCheck.Distance < MIN_HOVER_ALTITUDE then
		local liftTargetY = (MIN_HOVER_ALTITUDE - groundCheck.Distance) + 1.2
		hrp.CFrame = hrp.CFrame + Vector3.new(0, liftTargetY, 0)
	end
end

local function StopFlightLocomotion(character: Model)
	if flightLinearVel then
		flightLinearVel:Destroy()
		flightLinearVel = nil
	end
	if flightOrientation then
		flightOrientation:Destroy()
		flightOrientation = nil
	end
	if flightAttachment then
		flightAttachment:Destroy()
		flightAttachment = nil
	end

	isAscending = false
	isDescending = false

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.AutoRotate = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid.JumpPower = 50
		humanoid.JumpHeight = 7.2
		local walkSpeed, _ = InputController.GetLocomotionSpeeds()
		humanoid.WalkSpeed = walkSpeed

		if humanoid.FloorMaterial == Enum.Material.Air then
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
	end
end

local function SpawnGhostAfterimage(character: Model)
	local fxContainer = workspace:FindFirstChild("ActiveUltimateVFX") or Instance.new("Folder", workspace)
	fxContainer.Name = "ActiveUltimateVFX"

	local ghost = Instance.new("Model")
	ghost.Name = "ShunpoGhost"

	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local ghostPart = Instance.new("Part")
			ghostPart.Size = part.Size
			ghostPart.CFrame = part.CFrame
			ghostPart.Color = Color3.fromRGB(190, 60, 255)
			ghostPart.Material = Enum.Material.Neon
			ghostPart.Transparency = 0.45
			ghostPart.CanCollide = false
			ghostPart.CanTouch = false
			ghostPart.CanQuery = false
			ghostPart.Anchored = true
			ghostPart.Parent = ghost

			TweenService:Create(ghostPart, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = ghostPart.Size * 1.05
			}):Play()
		end
	end

	ghost.Parent = fxContainer
	Debris:AddItem(ghost, 0.28)
end

function InputController.Init()
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	updateCultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")

	player.CharacterAdded:Connect(function(character)
		isMeditating = false
		isSprinting = false
		isBlocking = false
		isAscending = false
		isDescending = false
		m1ComboIndex = 1
		currentAttackLockout = 0
		currentHeadBobWeight = 0.0
		isCastingSkillQ = false
		isHoldingF = false
		isExecutingSkillF = false
		wasSprintingBeforeF = false
		chargeTrackF = nil
		slashTrackF = nil

		-- PERMANENT ANTI-TRIP LOCK
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

		StopFlightLocomotion(character)
	end)

	if player.Character then
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end
	end

	updateCultivationRemote.OnClientEvent:Connect(function(data: any)
		if type(data) == "table" and data.IsMeditating ~= nil then
			isMeditating = (data.IsMeditating == true)
			if isMeditating and isSprinting then InputController.StopSprint() end
			if isMeditating and isBlocking then InputController.StopBlock() end
		end
	end)

	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	UserInputService.InputEnded:Connect(InputController.OnInputEnded)

	-- =========================================================================
	-- MASTER RENDERSTEPPED: FLIGHT HOVER, DRIFT & RUNNING CAMERA SHAKE
	-- =========================================================================
	RunService.RenderStepped:Connect(function(dt: number)
		local character = player.Character
		if not character or not enabled then return end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not humanoid or not hrp or humanoid.Health <= 0 then return end

		local isFlying = (character:GetAttribute("IsFlying") == true)
		local isDashing = (character:GetAttribute("IsDashing") == true)

		-- 1. FLIGHT LOCOMOTION & HOVER
		if isFlying then
			if not flightLinearVel or not flightOrientation then
				StartFlightLocomotion(character)
			end

			local camCFrame = camera.CFrame
			local camLook = camCFrame.LookVector
			local flatForward = Vector3.new(camLook.X, 0, camLook.Z)
			if flatForward.Magnitude > 0.01 and flightOrientation then
				local yawOffset = character:GetAttribute("FlightYawOffset") or FLIGHT_YAW_OFFSET
				flightOrientation.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + flatForward.Unit) * CFrame.Angles(0, math.rad(yawOffset), 0)
			end

			local moveDir = humanoid.MoveDirection
			local isMoving = moveDir.Magnitude > 0.05
			local horizontalVel = Vector3.zero
			if isMoving then
				local horizontalUnit = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
				horizontalVel = horizontalUnit * FLIGHT_SPEED
			end

			local vy = 0.0
			if isAscending then
				vy = vy + VERTICAL_FLIGHT_SPEED
			elseif isDescending then
				vy = vy - VERTICAL_FLIGHT_SPEED
			elseif isMoving then
				local pitchContribution = camLook.Y * (FLIGHT_SPEED * 0.75)
				vy = vy + pitchContribution
			else
				vy = IDLE_DRIFT_DESCENT
			end

			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			rayParams.FilterDescendantsInstances = { character }

			local groundRay = Workspace:Raycast(hrp.Position, Vector3.new(0, -25, 0), rayParams)
			if groundRay and groundRay.Distance < MIN_HOVER_ALTITUDE then
				local penetration = MIN_HOVER_ALTITUDE - groundRay.Distance
				local springUp = penetration * HOVER_SPRING_STRENGTH
				vy = math.max(vy, springUp)
			end

			if isMoving and horizontalVel.Magnitude > 1 then
				local checkDir = horizontalVel.Unit
				local bladeOrigin = hrp.Position - Vector3.new(0, 1.4, 0)
				local obstacleRay = Workspace:Raycast(bladeOrigin, checkDir * (MIN_OBSTACLE_BUFFER + 1.5), rayParams)

				if obstacleRay and obstacleRay.Distance < MIN_OBSTACLE_BUFFER then
					local normal = obstacleRay.Normal
					local dot = horizontalVel:Dot(normal)

					if dot < 0 then
						horizontalVel = horizontalVel - (normal * dot)
					end

					local penetration = MIN_OBSTACLE_BUFFER - obstacleRay.Distance
					horizontalVel = horizontalVel + (normal * (penetration * OBSTACLE_SPRING_STRENGTH))
				end
			end

			if flightLinearVel then
				flightLinearVel.VectorVelocity = Vector3.new(horizontalVel.X, vy, horizontalVel.Z)
			end
			return
		else
			if flightLinearVel or flightOrientation then
				StopFlightLocomotion(character)
			end
		end

		-- 2. GROUND FOOTWORK & SPRINT SPEED-TUNNEL CAMERA
		local isAttacking = character:GetAttribute("IsAttacking") == true
		local isStunned = character:GetAttribute("IsStunned") == true 
			or character:GetAttribute("CCState") == "Stunned" 
			or character:GetAttribute("CCState") == "GuardBroken"

		if isAttacking or isBlocking or isMeditating or isStunned or isDashing or isCastingSkillQ or isExecutingSkillF or isHoldingF then
			return
		end

		local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
		local isMoving = humanoid.MoveDirection.Magnitude > 0.1
		local onGround = humanoid.FloorMaterial ~= Enum.Material.Air

		if IsTouchDevice() then
			local moveMag = humanoid.MoveDirection.Magnitude
			if moveMag > 0.85 and not isSprinting then
				isSprinting = true
				humanoid.WalkSpeed = sprintSpeed
			elseif moveMag < 0.20 and isSprinting then
				isSprinting = false
				humanoid.WalkSpeed = walkSpeed
			end
		else
			if isSprinting then
				if humanoid.WalkSpeed ~= sprintSpeed then humanoid.WalkSpeed = sprintSpeed end
			else
				if humanoid.WalkSpeed ~= walkSpeed then humanoid.WalkSpeed = walkSpeed end
			end
		end

		local targetFov = (isSprinting and isMoving and onGround) and 76.0 or 70.0
		currentFovTarget = currentFovTarget + (targetFov - currentFovTarget) * math.clamp(dt * 8, 0, 1)
		camera.FieldOfView = currentFovTarget

		local targetBobWeight = (isSprinting and isMoving and onGround) and 1.0 or 0.0
		currentHeadBobWeight = currentHeadBobWeight + (targetBobWeight - currentHeadBobWeight) * math.clamp(dt * 10, 0, 1)

		if currentHeadBobWeight > 0.02 then
			local stepTime = os.clock() * 13.5
			local yBob = math.sin(stepTime * 2) * (0.07 * currentHeadBobWeight)
			local xBob = math.cos(stepTime) * (0.04 * currentHeadBobWeight)
			local rollBob = math.cos(stepTime) * math.rad(0.75 * currentHeadBobWeight)

			camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, rollBob) * CFrame.new(xBob, yBob, 0)
		end
	end)

	print("[ASCEND] InputController Initialized (High-Impact 44 studs/s Running & Head-Bob Active).")
end

function InputController.SetEnabled(state: boolean)
	enabled = state
	if not enabled then
		InputController.StopSprint()
		InputController.StopBlock()
	end
end

function InputController.ToggleSprint()
	if isMeditating or not enabled or isBlocking or isCastingSkillQ or isExecutingSkillF then return end
	local character = player.Character
	if character and (character:GetAttribute("IsDashing") == true or character:GetAttribute("IsFlying") == true) then return end

	if isSprinting then
		InputController.StopSprint()
	else
		InputController.StartSprint()
	end
end

function InputController.StartSprint()
	if isMeditating or not enabled or isBlocking or isCastingSkillQ or isExecutingSkillF then return end
	local character = player.Character
	if character and character:GetAttribute("IsFlying") == true then return end

	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		local _, sprintSpeed = InputController.GetLocomotionSpeeds()
		isSprinting = true
		humanoid.WalkSpeed = sprintSpeed
	end
end

function InputController.StopSprint()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		local walkSpeed, _ = InputController.GetLocomotionSpeeds()
		isSprinting = false
		humanoid.WalkSpeed = walkSpeed
	end
end

function InputController.StartBlock()
	local character = player.Character
	if isMeditating or not enabled or isBlocking or isCastingSkillQ or isExecutingSkillF then return end
	if character and (character:GetAttribute("IsFlying") == true or character:GetAttribute("IsDashing") == true or character:GetAttribute("IsAttacking") == true) then return end

	isBlocking = true
	if isSprinting then isSprinting = false end

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.StartBlock()
	combatActionRemote:FireServer({ Action = "BlockStart", Timestamp = os.clock() })

	local SkillBarController = require(script.Parent.SkillBarController)
	if SkillBarController.TriggerCooldown then
		SkillBarController.TriggerCooldown("T", 1.2)
	end
end

function InputController.StopBlock()
	if not isBlocking then return end
	isBlocking = false

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.StopBlock()
	combatActionRemote:FireServer({ Action = "BlockEnd", Timestamp = os.clock() })
end

function InputController.GetTargetPayload(skillKey: string, comboIndex: number?, dashIndex: number?): ActionPayload
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil

	local origin = if hrp then hrp.Position else Vector3.zero
	local aimDir = Vector3.new(0, 0, -1)

	if not IsTouchDevice() and mouse then
		local targetPos = mouse.Hit.Position
		if (targetPos - origin).Magnitude > 0 then
			aimDir = (targetPos - origin).Unit
		end
	elseif hrp then
		aimDir = hrp.CFrame.LookVector
	end

	return {
		SkillKey = skillKey,
		ComboIndex = comboIndex,
		DashIndex = dashIndex,
		AimDirection = aimDir,
		Origin = origin,
		Timestamp = os.clock(),
	}
end

function InputController.TriggerDash()
	local character = player.Character
	if isMeditating or not enabled or isBlocking or isCastingSkillQ or isExecutingSkillF then return end
	if character and character:GetAttribute("IsFlying") == true then return end

	local now = os.clock()
	if (now - lastDashPress) < DASH_COOLDOWN then return end
	lastDashPress = now

	local currentDashStep = dashStep
	dashStep = if dashStep == 1 then 2 else 1

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.PerformDash(currentDashStep)

	local payload = InputController.GetTargetPayload("Shift", nil, currentDashStep)
	combatActionRemote:FireServer(payload)

	local SkillBarController = require(script.Parent.SkillBarController)
	if SkillBarController.TriggerCooldown then
		SkillBarController.TriggerCooldown("Dash", DASH_COOLDOWN)
	end
end

function InputController.TriggerM1()
	local character = player.Character
	if not enabled or isMeditating or isBlocking or IsAnyMenuOpen() or isCastingSkillQ or isExecutingSkillF then return end
	if character and character:GetAttribute("IsFlying") == true then return end

	local now = os.clock()
	if (now - lastM1Press) < currentAttackLockout then return end
	if (now - lastM1Press) > COMBO_TIMEOUT then m1ComboIndex = 1 end

	local currentStep = m1ComboIndex
	local animKey = "M1_" .. tostring(currentStep)
	local swordCfg = AnimationConfig.FlyingSword :: any
	local animDef = if swordCfg then swordCfg[animKey] else nil

	currentAttackLockout = if animDef then (animDef.CastDuration * 0.88) else 0.38
	m1ComboIndex = if m1ComboIndex >= 5 then 1 else m1ComboIndex + 1
	lastM1Press = now

	local AnimationController = require(script.Parent.AnimationController)
	AnimationController.PlayAttackAnimation("M1", currentStep)

	local payload = InputController.GetTargetPayload("M1", currentStep)
	combatActionRemote:FireServer(payload)

	local SkillBarController = require(script.Parent.SkillBarController)
	if SkillBarController.TriggerCooldown then
		SkillBarController.TriggerCooldown("M1", currentAttackLockout)
	end
end

function InputController.TriggerSkill(skillKey: string)
	local character = player.Character
	if not enabled or isMeditating or isBlocking or IsAnyMenuOpen() then return end
	if character and character:GetAttribute("IsFlying") == true then return end

	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local curQi = character:GetAttribute("Qi") or 0
	local maxQi = character:GetAttribute("MaxQi") or 100
	local skillData = FlyingSwordConfig.Skills[skillKey]
	local costPercent = if skillData then skillData.QiCostPercent else 0
	local requiredQi = math.ceil(maxQi * costPercent)

	if curQi < requiredQi then
		EmitToast(string.format("Insufficient Qi! (%d/%d required)", math.floor(curQi), requiredQi))
		return
	end

	local now = os.clock()
	local cd = if skillKey == "Q" then 3.5 else (if skillKey == "F" then 5.5 else (skillData and skillData.Cooldown or 2.0))

	if skillKey == "Q" then
		if isCastingSkillQ or (now - lastSkillQTime) < cd then return end
		isCastingSkillQ = true
		lastSkillQTime = now

		local wasSprintingBeforeCast = isSprinting
		hum.WalkSpeed = 3.5

		local AnimationController = require(script.Parent.AnimationController)
		AnimationController.PlayAttackAnimation(skillKey, nil)

		local SkillBarController = require(script.Parent.SkillBarController)
		if SkillBarController.TriggerCooldown then
			SkillBarController.TriggerCooldown(skillKey, cd)
		end

		local charForward = (hrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
		local payload = InputController.GetTargetPayload(skillKey)
		payload.AimDirection = charForward

		task.delay(0.30, function()
			if not hrp.Parent then return end
			hrp.AssemblyLinearVelocity = charForward * 20 + Vector3.new(0, 2, 0)

			local sound = Instance.new("Sound")
			sound.SoundId = SWORD_RELEASE_SFX
			sound.Volume = 1.3
			sound.Parent = hrp
			sound:Play()
			Debris:AddItem(sound, 2.5)

			combatActionRemote:FireServer(payload)

			task.delay(0.18, function()
				if hum and hum.Parent then
					local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
					if wasSprintingBeforeCast and hum.MoveDirection.Magnitude > 0.05 then
						isSprinting = true
						hum.WalkSpeed = sprintSpeed
					else
						isSprinting = false
						hum.WalkSpeed = walkSpeed
					end
				end
				isCastingSkillQ = false
			end)
		end)
	elseif skillKey == "F" then
		return
	else
		local AnimationController = require(script.Parent.AnimationController)
		AnimationController.PlayAttackAnimation(skillKey, nil)

		local payload = InputController.GetTargetPayload(skillKey)
		combatActionRemote:FireServer(payload)

		local SkillBarController = require(script.Parent.SkillBarController)
		if SkillBarController.TriggerCooldown then
			SkillBarController.TriggerCooldown(skillKey, cd)
		end
	end
end

-- =============================================================================
-- ULTIMATE SKILL F: CHARGE, SHUNPO BLINK & 100-SLASH SPHERE (ANTI-TRIP FIXED)
-- =============================================================================
local function StartChargingUltimateF()
	local character = player.Character
	if not enabled or isMeditating or isBlocking or IsAnyMenuOpen() or isExecutingSkillF then return end
	if character and character:GetAttribute("IsFlying") == true then return end

	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local now = os.clock()
	local cd = FlyingSwordConfig.Skills.F.Cooldown or 5.5
	if isHoldingF or (now - lastSkillFTime) < cd then return end

	local curQi = character:GetAttribute("Qi") or 0
	local maxQi = character:GetAttribute("MaxQi") or 100
	local requiredQi = math.ceil(maxQi * FlyingSwordConfig.Skills.F.QiCostPercent)

	if curQi < requiredQi then
		EmitToast(string.format("Insufficient Qi! (%d/%d required)", math.floor(curQi), requiredQi))
		return
	end

	isHoldingF = true
	chargeStartTimeF = now
	wasSprintingBeforeF = isSprinting

	-- INSTANT MOMENTUM ARREST: Prevents sliding/tripping forward when pressing F mid-sprint
	hrp.AssemblyLinearVelocity = Vector3.new(0, math.min(0, hrp.AssemblyLinearVelocity.Y), 0)
	hrp.AssemblyAngularVelocity = Vector3.zero
	hum.WalkSpeed = 0

	character:SetAttribute("IsAttacking", true)

	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	if not chargeTrackF then
		local animObj = Instance.new("Animation")
		animObj.AnimationId = AnimationConfig.FlyingSword.F.ChargeAnimationId or "rbxassetid://84905841522350"
		chargeTrackF = animator:LoadAnimation(animObj)
		chargeTrackF.Looped = true
		chargeTrackF.Priority = Enum.AnimationPriority.Action3
	end

	chargeTrackF:Play(0.06)
	chargeTrackF:AdjustSpeed(1.0)

	if camera then
		TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Sine), { FieldOfView = 65.0 }):Play()
	end

	-- Freeze pose indefinitely on final charge frame
	task.spawn(function()
		local freezeTarget = if chargeTrackF.Length > 0.3 then (chargeTrackF.Length * 0.85) else 0.24
		local elapsed = 0
		while isHoldingF and elapsed < freezeTarget do
			local dt = task.wait()
			elapsed += dt
		end
		if isHoldingF and chargeTrackF.IsPlaying then
			chargeTrackF:AdjustSpeed(0)
		end
	end)
end

local function ReleaseUltimateF()
	if not isHoldingF or isExecutingSkillF then return end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	local holdDuration = os.clock() - chargeStartTimeF
	local remainingWait = math.max(0, 0.20 - holdDuration)

	isHoldingF = false
	isExecutingSkillF = true
	lastSkillFTime = os.clock()

	local SkillBarController = require(script.Parent.SkillBarController)
	if SkillBarController.TriggerCooldown then
		SkillBarController.TriggerCooldown("F", FlyingSwordConfig.Skills.F.Cooldown or 5.5)
	end

	task.delay(remainingWait, function()
		if chargeTrackF then chargeTrackF:Stop(0.04) end

		local charForward = (hrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
		local targetTravelDist = FlyingSwordConfig.Skills.F.DashDistance or 28.0 -- Tuned to 28 studs
		local dashSpeed = FlyingSwordConfig.Skills.F.DashSpeed or 150.0

		-- OBSTACLE RAYCAST: Stops at Trees, Walls & Terrain, ignores all Humanoids/Enemies
		local rayParams = RaycastParams.new()
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.IgnoreWater = true

		local ignoreList: { Instance } = { character }
		for _, entity in ipairs(workspace:GetDescendants()) do
			if entity:IsA("Model") and entity:FindFirstChildOfClass("Humanoid") then
				table.insert(ignoreList, entity)
			end
		end
		rayParams.FilterDescendantsInstances = ignoreList

		local obstacleHit = workspace:Raycast(hrp.Position + Vector3.new(0, 1, 0), charForward * targetTravelDist, rayParams)
		local effectiveDist = targetTravelDist
		if obstacleHit and obstacleHit.Normal.Y < 0.65 then
			effectiveDist = math.max(4.0, obstacleHit.Distance - 2.0)
		end

		local actualDashDuration = effectiveDist / dashSpeed

		if camera then
			TweenService:Create(camera, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 76.0 }):Play()
		end

		-- Launch forward velocity
		hrp.AssemblyLinearVelocity = charForward * dashSpeed
		hrp.AssemblyAngularVelocity = Vector3.zero

		task.spawn(function()
			for _ = 1, 3 do
				task.wait(0.05)
				if hrp and hrp.Parent then
					SpawnGhostAfterimage(character)
				end
			end
		end)

		-- Mid-dash execution at ~45% of travel path
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
		if not slashTrackF then
			local animObj = Instance.new("Animation")
			animObj.AnimationId = AnimationConfig.FlyingSword.F.AnimationId
			slashTrackF = animator:LoadAnimation(animObj)
			slashTrackF.Priority = Enum.AnimationPriority.Action4
		end

		task.delay(actualDashDuration * 0.45, function()
			if not hrp.Parent then return end

			slashTrackF:Play(0.02)
			slashTrackF:AdjustSpeed(1.4)

			local midPointPos = hrp.Position + Vector3.new(0, -0.40, 0)

			combatActionRemote:FireServer({
				Action = "F",
				SkillKey = "F",
				AimDirection = charForward,
				Origin = midPointPos,
			})
		end)

		-- =====================================================================
		-- DASH FINISH: SEAMLESS RECOVERY (NO TRIPPING, NATURAL LOCOMOTION)
		-- =====================================================================
		task.delay(actualDashDuration, function()
			if not hrp.Parent then return end

			-- Clear rotational spin
			hrp.AssemblyAngularVelocity = Vector3.zero

			-- Clean upright orientation lock
			local _, currentYaw, _ = hrp.CFrame:ToOrientation()
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, currentYaw, 0)

			-- ZERO OUT VELOCITY (Lets Humanoid handle walking/running with no physics fights)
			hrp.AssemblyLinearVelocity = Vector3.zero

			-- Quick 0.20s slice recovery window (<0.40s total skill time)
			task.delay(0.20, function()
				if slashTrackF then slashTrackF:Stop(0.10) end

				character:SetAttribute("IsAttacking", false)

				-- AUTOMATIC SPRINT RESUMPTION (Pure Humanoid Locomotion)
				local walkSpeed, sprintSpeed = InputController.GetLocomotionSpeeds()
				if wasSprintingBeforeF and hum.MoveDirection.Magnitude > 0.05 then
					isSprinting = true
					hum.WalkSpeed = sprintSpeed
				else
					isSprinting = false
					hum.WalkSpeed = walkSpeed
				end

				isExecutingSkillF = false
			end)
		end)
	end)
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed or IsAnyMenuOpen() then return end

	local character = player.Character
	local isFlying = character and character:GetAttribute("IsFlying") == true

	if input.KeyCode == Enum.KeyCode.V then
		if isMeditating then return end
		local now = os.clock()
		if now - lastVPress < 0.5 then return end
		lastVPress = now
		combatActionRemote:FireServer({ ToggleFlight = true })
		return
	end

	if isFlying then
		if input.KeyCode == Enum.KeyCode.Space then
			isAscending = true
			return
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
			isDescending = true
			return
		end
		return
	end

	if character and character:GetAttribute("IsDashing") == true then return end

	if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		InputController.ToggleSprint()
		return
	end

	if input.KeyCode == Enum.KeyCode.T then
		InputController.StartBlock()
		return
	end

	if input.KeyCode == Enum.KeyCode.LeftShift then
		InputController.TriggerDash()
		return
	end

	if input.KeyCode == Enum.KeyCode.C then
		local now = os.clock()
		if now - lastCPress < 0.8 then return end
		lastCPress = now

		local isCurrentlyMeditating = character and character:GetAttribute("IsMeditating") == true
		if isCurrentlyMeditating then
			EmitToast("Exited Meditation")
		else
			EmitToast("Entered Meditation (Cultivating Qi)")
		end

		combatActionRemote:FireServer({ ToggleMeditation = true })
		return
	end

	if input.KeyCode == Enum.KeyCode.R then
		if isMeditating then return end
		local now = os.clock()
		if now - lastRPress < 0.5 then return end
		lastRPress = now
		combatActionRemote:FireServer({ ToggleSheath = true })
		return
	end

	if not enabled or isMeditating or isBlocking or isCastingSkillQ or isExecutingSkillF then return end

	if input.KeyCode == Enum.KeyCode.B then
		local curQi = character and character:GetAttribute("Qi") or 0
		local maxQi = character and character:GetAttribute("MaxQi") or 100
		if curQi >= maxQi then
			EmitToast("Initiating Cultivation Breakthrough...")
		else
			EmitToast(string.format("Breakthrough Failed: Qi not condensed (%s/%s)", tostring(math.floor(curQi)), tostring(math.floor(maxQi))))
		end
		combatActionRemote:FireServer({ RequestBreakthrough = true })
		return
	end

	-- Q: Purple Sword Tempest
	if input.KeyCode == Enum.KeyCode.Q then
		InputController.TriggerSkill("Q")
		return
	end

	-- E: Thrust
	if input.KeyCode == Enum.KeyCode.E then
		InputController.TriggerSkill("E")
		return
	end

	-- F: Ultimate Skill (Start Charging)
	if input.KeyCode == Enum.KeyCode.F then
		StartChargingUltimateF()
		return
	end

	-- M1 Combo
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		InputController.TriggerM1()
		return
	end
end

function InputController.OnInputEnded(input: InputObject, gameProcessed: boolean)
	local character = player.Character
	local isFlying = character and character:GetAttribute("IsFlying") == true

	if isFlying then
		if input.KeyCode == Enum.KeyCode.Space then
			isAscending = false
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.C then
			isDescending = false
		end
	end

	if input.KeyCode == Enum.KeyCode.T then
		InputController.StopBlock()
	end

	-- F: Release Charge & Unleash Ultimate
	if input.KeyCode == Enum.KeyCode.F then
		ReleaseUltimateF()
	end
end

return InputController