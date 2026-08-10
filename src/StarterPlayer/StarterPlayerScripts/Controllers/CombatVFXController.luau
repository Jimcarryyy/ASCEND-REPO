--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Client VFX and visual feedback controller for ASCEND combat.
    Renders 3-Wave Magma Crescent Cleaves, Celestial Sunfalls, Camera Shake,
    and Dynamic Floating Damage Numbers.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CombatVFXController = {}
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local combatVFXRemote: RemoteEvent

-- Camera Shake Variables
local shakeIntensity = 0
local shakeDecay = 8

function CombatVFXController.Init()
	combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")

	combatVFXRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.EffectType then return end

		if payload.EffectType == "MagmaCrescentCleave" then
			CombatVFXController.SpawnMagmaCrescentCleave(payload.Origin, payload.Direction)
		elseif payload.EffectType == "CelestialSunfall" then
			CombatVFXController.SpawnCelestialSunfall(payload.Position)
		elseif payload.EffectType == "CameraShake" then
			CombatVFXController.AddCameraShake(payload.Intensity or 0.5)
		elseif payload.EffectType == "DamageNumber" then
			CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.DamageAmount, payload.IsCrit)
		end
	end)

	-- Procedural Camera Shake Update Loop
	RunService.RenderStepped:Connect(function(dt)
		if shakeIntensity > 0.01 then
			local offsetX = (math.random() * 2 - 1) * shakeIntensity
			local offsetY = (math.random() * 2 - 1) * shakeIntensity
			local offsetZ = (math.random() * 2 - 1) * shakeIntensity

			if camera then
				camera.CFrame = camera.CFrame * CFrame.new(offsetX, offsetY, offsetZ)
			end

			shakeIntensity = math.max(0, shakeIntensity - (shakeDecay * dt))
		end
	end)

	print("[ASCEND] CombatVFXController Initialized (Magma Cleaves, Sunfalls, Camera Shake, Damage Numbers).")
end

-- =============================================================================
-- 1. 3-WAVE MAGMA CRESCENT CLEAVES
-- =============================================================================
function CombatVFXController.SpawnMagmaCrescentCleave(origin: Vector3, direction: Vector3)
	local normDir = direction.Magnitude > 0 and direction.Unit or Vector3.new(0, 0, -1)

	for waveIndex = 1, 3 do
		task.delay((waveIndex - 1) * 0.12, function()
			local wavePart = Instance.new("Part")
			wavePart.Name = "MagmaCrescentWave_" .. waveIndex
			wavePart.Size = Vector3.new(6 + (waveIndex * 2), 0.5, 2)
			wavePart.CFrame = CFrame.lookAt(origin + (normDir * (waveIndex * 4)), origin + (normDir * (waveIndex * 4 + 10)))
			wavePart.Color = Color3.fromRGB(255, 70, 30)
			wavePart.Material = Enum.Material.Neon
			wavePart.Anchored = true
			wavePart.CanCollide = false
			wavePart.Parent = workspace

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.FileMesh
			mesh.MeshId = "rbxassetid://431221415" -- Arc Crescent Mesh
			mesh.Scale = Vector3.new(1 + (waveIndex * 0.3), 0.5, 1 + (waveIndex * 0.3))
			mesh.Parent = wavePart

			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxassetid://242200234"
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 20)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 0)),
			})
			pe.Size = NumberSequence.new(1.5, 0)
			pe.Lifetime = NumberRange.new(0.3, 0.6)
			pe.Rate = 40
			pe.Speed = NumberRange.new(10, 20)
			pe.Parent = wavePart

			-- Animate Forward Slash Sweep & Fade
			local targetCFrame = wavePart.CFrame + (normDir * 25)
			local tweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local tween = TweenService:Create(wavePart, tweenInfo, {
				CFrame = targetCFrame,
				Transparency = 1,
			})

			tween:Play()
			CombatVFXController.AddCameraShake(0.35)

			tween.Completed:Connect(function()
				wavePart:Destroy()
			end)
		end)
	end
end

-- =============================================================================
-- 2. CELESTIAL SUNFALL IMPACTS
-- =============================================================================
function CombatVFXController.SpawnCelestialSunfall(position: Vector3)
	-- Vertical Sun Shaft Beam
	local beamPart = Instance.new("Part")
	beamPart.Name = "CelestialSunfallShaft"
	beamPart.Size = Vector3.new(8, 120, 8)
	beamPart.Position = position + Vector3.new(0, 60, 0)
	beamPart.Color = Color3.fromRGB(255, 220, 100)
	beamPart.Material = Enum.Material.Neon
	beamPart.Anchored = true
	beamPart.CanCollide = false
	beamPart.Transparency = 0.2
	beamPart.Parent = workspace

	-- Expanding Solar Shockwave Ring on Ground
	local ringPart = Instance.new("Part")
	ringPart.Name = "SunfallGroundRing"
	ringPart.Shape = Enum.PartType.Cylinder
	ringPart.Size = Vector3.new(0.5, 4, 4)
	ringPart.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	ringPart.Color = Color3.fromRGB(255, 200, 60)
	ringPart.Material = Enum.Material.Neon
	ringPart.Anchored = true
	ringPart.CanCollide = false
	ringPart.Parent = workspace

	CombatVFXController.AddCameraShake(0.7)

	-- Tween Sunbeam Dissolve & Shockwave Expansion
	local shaftTween = TweenService:Create(beamPart, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = Vector3.new(1, 120, 1),
	})

	local ringTween = TweenService:Create(ringPart, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, 32, 32),
		Transparency = 1,
	})

	shaftTween:Play()
	ringTween:Play()

	shaftTween.Completed:Connect(function()
		beamPart:Destroy()
		ringPart:Destroy()
	end)
end

-- =============================================================================
-- 3. CAMERA SHAKE ENGINE
-- =============================================================================
function CombatVFXController.AddCameraShake(intensity: number)
	shakeIntensity = math.clamp(shakeIntensity + intensity, 0, 1.5)
end

-- =============================================================================
-- 4. FLOATING ANIMATED DAMAGE NUMBERS
-- =============================================================================
function CombatVFXController.SpawnDamageNumber(position: Vector3, damage: number, isCrit: boolean?)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumberGui"
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffsetWorldSpace = position + Vector3.new(math.random(-1, 1), 2, math.random(-1, 1))
	billboard.AlwaysOnTop = true
	billboard.Adornee = workspace.Terrain
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = tostring(math.floor(damage))
	label.Font = UIAssets.Fonts.Header or Enum.Font.Fondamento
	label.TextSize = if isCrit then 28 else 20
	label.TextColor3 = if isCrit then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	label.Parent = billboard

	-- Animate Float Upward & Scale Pop
	local targetOffset = billboard.StudsOffsetWorldSpace + Vector3.new(0, 3, 0)

	local floatTween = TweenService:Create(billboard, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = targetOffset,
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})

	floatTween:Play()
	fadeTween:Play()

	floatTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

return CombatVFXController