--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Client VFX and Audio controller with Scaled Floating Damage Numbers and de-duplicated 3D sound routing.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CombatVFXController = {}
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local combatVFXRemote: RemoteEvent
local combatActionRemote: RemoteEvent

-- Audio IDs
local SWING_AIR_SOUND_ID = "rbxassetid://79218449800283"
local HIT_IMPACT_SOUND_ID = "rbxassetid://140462043853173"
local PARRY_CLASH_SOUND_ID = "rbxassetid://9114223175"

-- Camera Shake Variables
local shakeIntensity = 0
local shakeDecay = 8

local function Play3DSound(soundId: string, position: Vector3, volume: number?)
	local soundPart = Instance.new("Part")
	soundPart.Name = "CombatSFXPart"
	soundPart.Position = position
	soundPart.Transparency = 1
	soundPart.CanCollide = false
	soundPart.CanTouch = false
	soundPart.CanQuery = false
	soundPart.Anchored = true
	soundPart.Parent = workspace

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.85
	sound.RollOffMaxDistance = 80
	sound.RollOffMinDistance = 5
	sound.Parent = soundPart

	sound:Play()
	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)

	task.delay(2.5, function()
		if soundPart and soundPart.Parent then
			soundPart:Destroy()
		end
	end)
end

function CombatVFXController.Init()
	combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		local attackerChar = attacker.Character
		local hrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local origin = if hrp then hrp.Position else Vector3.zero

		-- 1. Swing Audio: ONLY played for OTHER observers (Attacker already played it locally with 0ms lag)
		if skillKey == "M1" and attacker ~= player then
			Play3DSound(SWING_AIR_SOUND_ID, origin, 0.7)
		end

		-- 2. Hit Feedback on Target
		if type(payload) == "table" and payload.HasHit == true and payload.TargetPosition ~= nil then
			if payload.WasParried then
				-- Handled by ParryClash event
			elseif payload.WasBlocked then
				Play3DSound(PARRY_CLASH_SOUND_ID, payload.TargetPosition, 0.7)
				if attacker == player then
					CombatVFXController.AddCameraShake(0.15)
				end
				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.Damage, false, Color3.fromRGB(175, 195, 220), "🛡️")
				end
			else
				Play3DSound(HIT_IMPACT_SOUND_ID, payload.TargetPosition, 0.95)
				if attacker == player then
					CombatVFXController.AddCameraShake(payload.IsCrit and 0.45 or 0.25)
				end
				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.Damage, payload.IsCrit == true)
				end
			end
		end
	end)

	combatVFXRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.EffectType then return end

		if payload.EffectType == "ParryClash" then
			CombatVFXController.SpawnParryClash(payload.Position)
		elseif payload.EffectType == "BlockSparks" then
			CombatVFXController.SpawnBlockSparks(payload.Position)
		elseif payload.EffectType == "MagmaCrescentCleave" then
			CombatVFXController.SpawnMagmaCrescentCleave(payload.Origin, payload.Direction)
		elseif payload.EffectType == "CelestialSunfall" then
			CombatVFXController.SpawnCelestialSunfall(payload.Position)
		elseif payload.EffectType == "CameraShake" then
			CombatVFXController.AddCameraShake(payload.Intensity or 0.5)
		elseif payload.EffectType == "DamageNumber" then
			CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.DamageAmount, payload.IsCrit)
		end
	end)

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

	print("[ASCEND] CombatVFXController Initialized (Zero-Echo Audio & Scaled Damage Numbers).")
end

function CombatVFXController.SpawnParryClash(position: Vector3)
	Play3DSound(PARRY_CLASH_SOUND_ID, position, 1.0)
	CombatVFXController.AddCameraShake(0.4)

	local flashPart = Instance.new("Part")
	flashPart.Name = "ParryFlash"
	flashPart.Shape = Enum.PartType.Ball
	flashPart.Size = Vector3.new(2, 2, 2)
	flashPart.Position = position
	flashPart.Color = Color3.fromRGB(255, 240, 150)
	flashPart.Material = Enum.Material.Neon
	flashPart.Anchored = true
	flashPart.CanCollide = false
	flashPart.Parent = workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxassetid://242200234"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 0)),
	})
	pe.Size = NumberSequence.new(0.6, 0)
	pe.Lifetime = NumberRange.new(0.15, 0.3)
	pe.Rate = 120
	pe.Speed = NumberRange.new(25, 45)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Parent = flashPart
	pe:Emit(40)

	local tween = TweenService:Create(flashPart, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(6, 6, 6),
		Transparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		flashPart:Destroy()
	end)
end

function CombatVFXController.SpawnBlockSparks(position: Vector3)
	local sparkPart = Instance.new("Part")
	sparkPart.Position = position
	sparkPart.Transparency = 1
	sparkPart.Anchored = true
	sparkPart.CanCollide = false
	sparkPart.Parent = workspace

	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxassetid://242200234"
	pe.Color = ColorSequence.new(Color3.fromRGB(200, 220, 255))
	pe.Size = NumberSequence.new(0.4, 0)
	pe.Lifetime = NumberRange.new(0.1, 0.2)
	pe.Rate = 60
	pe.Speed = NumberRange.new(15, 25)
	pe.Parent = sparkPart
	pe:Emit(15)

	task.delay(0.5, function()
		sparkPart:Destroy()
	end)
end

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
			mesh.MeshId = "rbxassetid://431221415"
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

function CombatVFXController.SpawnCelestialSunfall(position: Vector3)
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

function CombatVFXController.AddCameraShake(intensity: number)
	shakeIntensity = math.clamp(shakeIntensity + intensity, 0, 1.5)
end

-- =============================================================================
-- DYNAMIC SCALED FLOATING DAMAGE NUMBERS & CRITICAL STRIKES
-- =============================================================================
function CombatVFXController.SpawnDamageNumber(position: Vector3, damage: number, isCrit: boolean?, customColor: Color3?, prefixText: string?)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumberGui"
	billboard.Size = if isCrit then UDim2.new(0, 180, 0, 50) else UDim2.new(0, 140, 0, 40)
	billboard.StudsOffsetWorldSpace = position + Vector3.new(math.random(-10, 10) / 10, 2, math.random(-10, 10) / 10)
	billboard.AlwaysOnTop = true
	billboard.Adornee = workspace.Terrain
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1

	local formattedNum = tostring(math.floor(damage))
	if prefixText then
		label.Text = string.format("%s %s", prefixText, formattedNum)
	elseif isCrit then
		label.Text = string.format("CRIT! %s", formattedNum)
	else
		label.Text = formattedNum
	end

	label.Font = Enum.Font.LuckiestGuy

	-- Dynamic Font Size Scaling
	if isCrit then
		label.TextSize = 34
		label.TextColor3 = customColor or Color3.fromRGB(255, 215, 0) -- Radiant Gold
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(130, 25, 0) -- Fiery Crimson Outline
	else
		local baseSize = math.clamp(20 + math.floor(damage / 15), 20, 26)
		label.TextSize = baseSize
		label.TextColor3 = customColor or Color3.fromRGB(255, 255, 255)
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
	end

	label.Parent = billboard

	local targetOffset = billboard.StudsOffsetWorldSpace + Vector3.new(0, isCrit and 4.2 or 3.0, 0)

	local floatTween = TweenService:Create(billboard, TweenInfo.new(isCrit and 0.95 or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = targetOffset,
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(isCrit and 0.95 or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
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