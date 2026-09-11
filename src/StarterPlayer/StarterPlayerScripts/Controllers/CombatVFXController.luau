--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Handles:
      1. Xianxia Floating Damage Numbers (Pure text, no icons)
      2. Floating Sword Intent Combo & Unleashed Text Popups (Pure text, no icons)
      3. Slash VFX, Camera Shake, Hitstop, Parry Clashes & Block Sparks
      4. Triple-Wave Purple Sawblade Vortex (Q Skill) at Calibrated Torso Height
      5. Massive 36-Stud Purple 100-Slash Sphere Domain (F Skill)
      6. Victim & Caster POV Camera Impact Shudder
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CombatVFXController = {}
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local combatVFXRemote: RemoteEvent
local combatActionRemote: RemoteEvent

local vfxFolder = ReplicatedStorage:WaitForChild("VFX", 5) :: Folder?

local SWING_AIR_SOUND_ID = "rbxassetid://79218449800283"
local HIT_IMPACT_SOUND_ID = "rbxassetid://135448977656112"
local PARRY_CLASH_SOUND_ID = "rbxassetid://9114223175"
local SLASH_RELEASE_SFX = "rbxassetid://109735549169421"

local PURPLE_GRADIENT = ColorSequence.new({
	ColorSequenceKeypoint.new(0.0, Color3.fromRGB(245, 200, 255)),
	ColorSequenceKeypoint.new(0.35, Color3.fromRGB(180, 50, 255)),
	ColorSequenceKeypoint.new(1.0, Color3.fromRGB(90, 10, 160)),
})

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

	Debris:AddItem(soundPart, 2.5)
end

local function ScaleParticleSize(pe: ParticleEmitter, factor: number)
	local oldSeq = pe.Size
	local newKps = {}
	for _, kp in ipairs(oldSeq.Keypoints) do
		table.insert(newKps, NumberSequenceKeypoint.new(kp.Time, kp.Value * factor, kp.Envelope * factor))
	end
	pe.Size = NumberSequence.new(newKps)
end

function CombatVFXController.AddCameraShake(intensity: number)
	shakeIntensity = math.clamp(shakeIntensity + intensity, 0, 1.8)
end

function CombatVFXController.OnLocalPlayerDamaged(damage: number, isCrit: boolean)
	CombatVFXController.AddCameraShake(if isCrit then 0.95 else 0.75)

	if camera then
		task.spawn(function()
			local origFOV = camera.FieldOfView
			camera.FieldOfView = origFOV + (if isCrit then 4.0 else 2.5)
			TweenService:Create(camera, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = origFOV }):Play()
		end)
	end
end

function CombatVFXController.SpawnSlashHitVFX(position: Vector3, orientationCFrame: CFrame?)
	local attTemplate = (vfxFolder and vfxFolder:FindFirstChild("SlashHitAnimation"))
		or (ReplicatedStorage:FindFirstChild("SlashHitAnimation", true) :: Attachment?)

	if not attTemplate then return end

	local hitHolder = Instance.new("Part")
	hitHolder.Name = "ActiveSlashHit"
	hitHolder.Size = Vector3.new(1, 1, 1)
	hitHolder.Transparency = 1
	hitHolder.Position = position
	if orientationCFrame then
		hitHolder.CFrame = CFrame.new(position) * orientationCFrame.Rotation
	end
	hitHolder.Anchored = true
	hitHolder.CanCollide = false
	hitHolder.CanTouch = false
	hitHolder.CanQuery = false
	hitHolder.Parent = workspace

	local attClone = attTemplate:Clone()
	attClone.Parent = hitHolder

	for _, pe in ipairs(attClone:GetDescendants()) do
		if pe:IsA("ParticleEmitter") then
			pe:Emit(pe:GetAttribute("EmitCount") or 1)
		end
	end

	Debris:AddItem(hitHolder, 0.6)
end

function CombatVFXController.SpawnIntentComboPopup(position: Vector3, comboCount: number, currentIntent: number, isEmpowered: boolean)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "IntentComboGui"
	billboard.Size = UDim2.new(0, 220, 0, 45)
	billboard.StudsOffsetWorldSpace = position + Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.Adornee = workspace.Terrain
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.Bangers

	local stroke = Instance.new("UIStroke", label)

	if isEmpowered then
		label.Text = "SWORD INTENT UNLEASHED (1.75X)"
		label.TextSize = 24
		label.TextColor3 = Color3.fromRGB(255, 235, 120)
		stroke.Color = Color3.fromRGB(200, 50, 0)
		stroke.Thickness = 2.0
	elseif currentIntent >= 100 then
		label.Text = "INTENT 100% - FULL CHARGE!"
		label.TextSize = 22
		label.TextColor3 = Color3.fromRGB(255, 215, 0)
		stroke.Color = Color3.fromRGB(15, 15, 20)
		stroke.Thickness = 1.6
	else
		label.Text = string.format("INTENT +25%% [COMBO x%d]", math.max(1, comboCount))
		label.TextSize = 18
		label.TextColor3 = Color3.fromRGB(0, 215, 255)
		stroke.Color = Color3.fromRGB(10, 20, 35)
		stroke.Thickness = 1.4
	end

	label.Parent = billboard

	local floatTween = TweenService:Create(billboard, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = billboard.StudsOffsetWorldSpace + Vector3.new(0, 2.2, 0),
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
	})

	floatTween:Play()
	fadeTween:Play()

	floatTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

function CombatVFXController.SpawnTriplePurpleTwirl(originPos: Vector3, direction: Vector3, isLocalCaster: boolean)
	local twirlPrefab = vfxFolder and vfxFolder:FindFirstChild("SwordTwirl")
	if not twirlPrefab then return end

	local projContainer = workspace:FindFirstChild("ActiveTwirlProjectiles")
	if not projContainer then
		projContainer = Instance.new("Folder")
		projContainer.Name = "ActiveTwirlProjectiles"
		projContainer.Parent = workspace
	end

	if isLocalCaster then
		CombatVFXController.AddCameraShake(0.65)
		if camera then
			task.spawn(function()
				local origFOV = camera.FieldOfView
				camera.FieldOfView = origFOV - 2.5
				TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = origFOV }):Play()
			end)
		end
	end

	local torsoHeightOrigin = originPos + Vector3.new(0, -0.40, 0)

	for waveIndex = 1, 3 do
		task.delay((waveIndex - 1) * 0.08, function()
			local tiltAngle = (waveIndex == 2 and 7) or (waveIndex == 3 and -7) or 0
			local spawnPos = torsoHeightOrigin + direction * (1.8 + waveIndex * 0.4) + Vector3.new(0, (waveIndex - 2) * 0.12, 0)
			local spawnCF = CFrame.lookAt(spawnPos, spawnPos + direction) * CFrame.Angles(0, 0, math.rad(tiltAngle))

			local proj = Instance.new("Part")
			proj.Name = "TwirlWave_" .. waveIndex
			proj.Size = Vector3.new(9, 1.2, 9)
			proj.Transparency = 1
			proj.CanCollide = false
			proj.CanTouch = false
			proj.CanQuery = false
			proj.Anchored = true
			proj.CFrame = spawnCF
			proj.Parent = projContainer

			local twirl = twirlPrefab:Clone()
			twirl.Parent = proj

			for _, pe in ipairs(twirl:GetDescendants()) do
				if pe:IsA("ParticleEmitter") then
					pe.LockedToPart = true
					pe.Enabled = true
					pe.Color = PURPLE_GRADIENT
					ScaleParticleSize(pe, 2.8)
					if pe.Rate == 0 then pe.Rate = 24 end
					pe:Emit(2)
				end
			end

			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(190, 60, 255)
			glow.Brightness = 3.8
			glow.Range = 20
			glow.Parent = proj

			local elapsed = 0
			local lifetime = 36 / 70
			local currentCF = spawnCF

			local conn: RBXScriptConnection?
			conn = RunService.Heartbeat:Connect(function(dt)
				elapsed += dt
				local nextPos = currentCF.Position + direction * (70 * dt)
				currentCF = CFrame.new(nextPos) * (currentCF - currentCF.Position)
				proj.CFrame = currentCF

				if elapsed >= lifetime then
					if conn then conn:Disconnect() end
					for _, pe in ipairs(twirl:GetDescendants()) do
						if pe:IsA("ParticleEmitter") then pe.Enabled = false end
					end
					Debris:AddItem(proj, 0.3)
				end
			end)
		end)
	end
end

function CombatVFXController.SpawnUltimateSlashSphere(spherePos: Vector3, isLocalCaster: boolean)
	local ultPrefab = (vfxFolder and vfxFolder:FindFirstChild("UltimateSkill"))
		or (ReplicatedStorage:FindFirstChild("UltimateSkill", true) :: Instance?)

	if not ultPrefab then return end

	local fxContainer = workspace:FindFirstChild("ActiveUltimateVFX") or Instance.new("Folder", workspace)
	fxContainer.Name = "ActiveUltimateVFX"

	local vfxHolder = Instance.new("Part")
	vfxHolder.Name = "UltimateSlashSphere"
	vfxHolder.Size = Vector3.new(2, 2, 2)
	vfxHolder.Transparency = 1
	vfxHolder.Anchored = true
	vfxHolder.CanCollide = false
	vfxHolder.CanTouch = false
	vfxHolder.CanQuery = false
	vfxHolder.CFrame = CFrame.new(spherePos)
	vfxHolder.Parent = fxContainer

	local clonedVFX = ultPrefab:Clone()
	clonedVFX.Parent = vfxHolder

	if clonedVFX:IsA("Attachment") or clonedVFX:IsA("Bone") then
		clonedVFX.CFrame = CFrame.identity
	end

	local activeEmitters = {}
	for _, desc in ipairs(clonedVFX:GetDescendants()) do
		if desc:IsA("Attachment") then
			if desc.Name == "Bottom" then
				desc.Position = Vector3.new(0, -2.0, 0)
			else
				desc.Position = Vector3.zero
			end
		elseif desc:IsA("ParticleEmitter") then
			desc.Enabled = true
			desc.LockedToPart = false
			desc.Color = PURPLE_GRADIENT
			ScaleParticleSize(desc, 2.2)
			table.insert(activeEmitters, desc)

			if desc.Rate == 0 then desc.Rate = 40 end
			desc:Emit(6)
		end
	end

	if isLocalCaster then
		CombatVFXController.AddCameraShake(1.4)
		if camera then
			task.spawn(function()
				local origFOV = camera.FieldOfView
				camera.FieldOfView = origFOV - 4.5
				TweenService:Create(camera, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = origFOV }):Play()
			end)
		end
	end

	Play3DSound(SLASH_RELEASE_SFX, spherePos, 2.8)

	task.delay(0.70, function()
		for _, pe in ipairs(activeEmitters) do pe.Enabled = false end
		Debris:AddItem(vfxHolder, 0.8)
	end)
end

function CombatVFXController.Init()
	combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		local attackerChar = attacker.Character
		local hrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local origin = if hrp then hrp.Position else Vector3.zero
		local isLocal = (attacker == player)

		if skillKey == "M1" and attacker ~= player then
			Play3DSound(SWING_AIR_SOUND_ID, origin, 0.7)
		end

		-- Q Skill: 3x Purple Sawblade Vortex
		if skillKey == "Q" and hrp then
			local aimDir = (hrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			if type(payload) == "table" and payload.AimDirection then
				aimDir = payload.AimDirection
			end
			CombatVFXController.SpawnTriplePurpleTwirl(hrp.Position, aimDir, isLocal)
		end

		-- F Skill: 36-Stud Purple 100-Slash Sphere Domain
		if skillKey == "F" then
			local spherePos = if type(payload) == "table" and payload.Origin then payload.Origin else (origin + Vector3.new(0, -0.4, 0))
			CombatVFXController.SpawnUltimateSlashSphere(spherePos, isLocal)
		end

		-- Hits & Damage Popups
		if type(payload) == "table" and payload.HasHit == true and payload.TargetPosition ~= nil then
			local targetPos: Vector3 = payload.TargetPosition

			if payload.Hits then
				for _, hitData in ipairs(payload.Hits) do
					if hitData.Character == player.Character then
						CombatVFXController.OnLocalPlayerDamaged(payload.Damage or 20, payload.IsCrit == true)
					end
				end
			end

			if payload.WasParried then
				CombatVFXController.SpawnParryClash(targetPos)
				CombatVFXController.SpawnDamageNumber(targetPos, 0, true, Color3.fromRGB(100, 220, 255), "PARRY!")
			elseif payload.WasGuardBroken then
				Play3DSound(PARRY_CLASH_SOUND_ID, targetPos, 1.0)
				CombatVFXController.AddCameraShake(0.55)
				CombatVFXController.ApplyHitstop(0.06)
				CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage or 0, true, Color3.fromRGB(255, 60, 60), "GUARD BROKEN!")
			elseif payload.WasBlocked then
				Play3DSound(PARRY_CLASH_SOUND_ID, targetPos, 0.7)
				if attacker == player then CombatVFXController.AddCameraShake(0.15) end
				CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage or 0, false, Color3.fromRGB(175, 195, 220), "BLOCKED")
			else
				Play3DSound(HIT_IMPACT_SOUND_ID, targetPos, 1.2)
				CombatVFXController.SpawnSlashHitVFX(targetPos, hrp and hrp.CFrame)

				if attacker == player then
					CombatVFXController.AddCameraShake(payload.IsCrit and 0.45 or 0.25)
					CombatVFXController.ApplyHitstop(payload.IsCrit and 0.06 or 0.04)

					CombatVFXController.SpawnIntentComboPopup(
						targetPos,
						payload.ComboCount or 1,
						payload.CurrentIntent or 0,
						payload.IsCrit == true
					)
				end

				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage, payload.IsCrit == true)
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

	print("[ASCEND] CombatVFXController Initialized (Clean Text Combat Popups & Ultimate Domain Active).")
end

function CombatVFXController.ApplyHitstop(duration: number)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not animator then return end

	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:AdjustSpeed(0.05)
	end

	task.delay(duration, function()
		if animator and animator.Parent then
			for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
				track:AdjustSpeed(1.0)
			end
		end
	end)
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

	Debris:AddItem(sparkPart, 0.5)
end

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
		label.Text = string.format("%s %s", prefixText, (if damage > 0 then formattedNum else ""))
	elseif isCrit then
		label.Text = string.format("CRIT! %s", formattedNum)
	else
		label.Text = formattedNum
	end

	label.Font = Enum.Font.Bangers

	if isCrit then
		label.TextSize = 34
		label.TextColor3 = customColor or Color3.fromRGB(255, 215, 0)
		local s = Instance.new("UIStroke", label)
		s.Color = Color3.fromRGB(130, 25, 0)
		s.Thickness = 1.8
	else
		local baseSize = math.clamp(20 + math.floor(damage / 15), 20, 26)
		label.TextSize = baseSize
		label.TextColor3 = customColor or Color3.fromRGB(255, 255, 255)
		local s = Instance.new("UIStroke", label)
		s.Color = Color3.fromRGB(15, 15, 20)
		s.Thickness = 1.2
	end

	label.Parent = billboard

	local targetOffset = billboard.StudsOffsetWorldSpace + Vector3.new(0, isCrit and 4.2 or 3.0, 0)

	local floatTween = TweenService:Create(billboard, TweenInfo.new(isCrit and 0.95 or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = targetOffset,
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(isCrit and 0.95 or 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
	})

	floatTween:Play()
	fadeTween:Play()

	floatTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

return CombatVFXController