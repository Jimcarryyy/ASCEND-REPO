--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Master Combat VFX, Audio & Impact Engine for ASCEND:
      1. Dynamic Weapon-Attuned Colors: Q Sawblades & F 100-Slash Domain match the equipped sword.
      2. Pure Damage Numbers: Retro Press Start 2P / Arcade font (Pure White for normal, Vivid Gold for crit).
         Zero words ("CRIT!", "PARRY!", "GUARD BROKEN!", "INTENT"), zero icons.
      3. Slash VFX with Procedural Slashmark Fallback.
      4. Camera Impact Shudder & Screen Hit Flash on Damage Received (Full Player & Mob Support).
         Animation-induced flinches removed to prevent character collapse/ragdoll.
      5. Parry Clashes, Block Sparks & Blade Impact Audio (Full Mob & Player Support).
      6. Heavenly Tribulation Lightning Bolts, Ground Telegraphs & Ascension Light Pillars.
      7. Interactive Martial Trees: Pure High-Frequency Shudder & Fluttering Leaves.
      8. D1 Proximity Scoping: Distant fights never shake your camera or freeze your tracks.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

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
local THUNDER_STRIKE_SFX = "rbxassetid://138090596"
local ASCENSION_GONG_SFX = "rbxassetid://131237241"
local TREE_RUSTLE_SFX = "rbxassetid://566593606"

local shakeIntensity = 0
local shakeDecay = 8

local treeOriginalPivots: { [Model]: CFrame } = {}
local treeIsVibrating: { [Model]: boolean } = {}

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
	sound.Volume = volume or 1.15
	sound.RollOffMaxDistance = 75
	sound.RollOffMinDistance = 5
	sound.Parent = soundPart

	sound.Ended:Connect(function()
		soundPart:Destroy()
	end)

	pcall(function()
		sound:Play()
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
	if player:GetAttribute("CombatCameraShake") == false then return end
	shakeIntensity = math.clamp(shakeIntensity + intensity, 0, 1.8)
end

-- =============================================================================
-- INTERACTIVE TREE VIBRATION & FALLING LEAVES (ZERO TIPPING)
-- =============================================================================
function CombatVFXController.TriggerTreeReaction(tree: Model, strikeOrigin: Vector3)
	if treeIsVibrating[tree] then return end
	treeIsVibrating[tree] = true

	local origPivot = treeOriginalPivots[tree]
	if not origPivot then
		origPivot = tree:GetPivot()
		treeOriginalPivots[tree] = origPivot
	end

	local primary = tree.PrimaryPart or tree:FindFirstChildWhichIsA("BasePart")
	if not primary then
		treeIsVibrating[tree] = nil
		return
	end

	local bbCFrame, bbSize = tree:GetBoundingBox()
	local canopyTop = bbCFrame.Position + Vector3.new(0, bbSize.Y * 0.35, 0)

	local leafColor = Color3.fromRGB(52, 211, 153)
	for _, child in ipairs(tree:GetChildren()) do
		if child:IsA("BasePart") and not string.find(child.Name:lower(), "trunk") then
			leafColor = child.Color
			break
		end
	end

	local leafEmitterPart = Instance.new("Part")
	leafEmitterPart.Name = "TreeLeafEmitter"
	leafEmitterPart.Position = canopyTop
	leafEmitterPart.Size = Vector3.new(bbSize.X * 0.7, 1, bbSize.Z * 0.7)
	leafEmitterPart.Transparency = 1
	leafEmitterPart.Anchored = true
	leafEmitterPart.CanCollide = false
	leafEmitterPart.CanTouch = false
	leafEmitterPart.CanQuery = false
	leafEmitterPart.Parent = workspace

	local leaves = Instance.new("ParticleEmitter")
	leaves.Texture = "rbxassetid://258127045"
	leaves.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, leafColor),
		ColorSequenceKeypoint.new(1.0, leafColor:Lerp(Color3.fromRGB(255, 255, 255), 0.2)),
	})
	leaves.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.75),
		NumberSequenceKeypoint.new(0.8, 0.65),
		NumberSequenceKeypoint.new(1.0, 0.0),
	})
	leaves.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.2),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	leaves.Lifetime = NumberRange.new(1.8, 2.6)
	leaves.Rate = 0
	leaves.Speed = NumberRange.new(2, 6)
	leaves.Acceleration = Vector3.new(math.random(-3, 3), -12, math.random(-3, 3))
	leaves.Rotation = NumberRange.new(0, 360)
	leaves.RotSpeed = NumberRange.new(-75, 75)
	leaves.SpreadAngle = Vector2.new(180, 180)
	leaves.Parent = leafEmitterPart

	leaves:Emit(math.random(14, 22))
	Debris:AddItem(leafEmitterPart, 3.0)

	Play3DSound(TREE_RUSTLE_SFX, canopyTop, 0.85)

	task.spawn(function()
		local duration = 0.20
		local elapsed = 0
		local maxJitter = 0.22

		while elapsed < duration do
			local dt = RunService.RenderStepped:Wait()
			elapsed += dt
			local damp = 1 - (elapsed / duration)
			local jitterOffset = Vector3.new(
				(math.random() * 2 - 1) * maxJitter * damp,
				0,
				(math.random() * 2 - 1) * maxJitter * damp
			)
			if tree.Parent then
				tree:PivotTo(origPivot + jitterOffset)
			end
		end

		if tree.Parent then
			tree:PivotTo(origPivot)
		end
		task.wait(0.15)
		treeIsVibrating[tree] = nil
	end)
end

function CombatVFXController.CheckAndTriggerNearbyTrees(strikePos: Vector3, radius: number)
	local taggedTrees = CollectionService:GetTagged("InteractiveTree")
	for _, inst in ipairs(taggedTrees) do
		if inst:IsA("Model") then
			local primary = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
			if primary then
				local dist = (primary.Position - strikePos).Magnitude
				if dist <= radius then
					CombatVFXController.TriggerTreeReaction(inst, strikePos)
				end
			end
		end
	end
end

-- =============================================================================
-- DAMAGE FEEDBACK: CAMERA SHAKE & RED FLASH (ANIMATION COLLAPSE REMOVED)
-- =============================================================================
function CombatVFXController.OnLocalPlayerDamaged(damage: number, isCrit: boolean)
	CombatVFXController.AddCameraShake(if isCrit then 1.1 else 0.85)

	-- Hit reaction animation disabled to eliminate animation-induced ragdoll/falldown
	if camera then
		task.spawn(function()
			local origFOV = camera.FieldOfView
			camera.FieldOfView = origFOV + (if isCrit then 4.5 else 3.0)
			TweenService:Create(camera, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { FieldOfView = origFOV }):Play()
		end)
	end

	task.spawn(function()
		local playerGui = player:FindFirstChildOfClass("PlayerGui")
		if not playerGui then return end

		local hitScreen = playerGui:FindFirstChild("HitFeedbackGui")
		if not hitScreen then
			hitScreen = Instance.new("ScreenGui")
			hitScreen.Name = "HitFeedbackGui"
			hitScreen.DisplayOrder = 99
			hitScreen.ResetOnSpawn = false
			hitScreen.Parent = playerGui
		end

		local flashFrame = hitScreen:FindFirstChild("RedFlash") :: Frame?
		if not flashFrame then
			flashFrame = Instance.new("Frame")
			flashFrame.Name = "RedFlash"
			flashFrame.Size = UDim2.new(1, 0, 1, 0)
			flashFrame.BackgroundColor3 = Color3.fromRGB(220, 20, 20)
			flashFrame.BackgroundTransparency = 1
			flashFrame.BorderSizePixel = 0
			flashFrame.Parent = hitScreen
		end

		flashFrame.BackgroundTransparency = if isCrit then 0.65 else 0.78
		TweenService:Create(flashFrame, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		}):Play()
	end)
end

-- =============================================================================
-- HEAVENLY TRIBULATION & ASCENSION VFX SUITE
-- =============================================================================
function CombatVFXController.SpawnTribulationTelegraph(pos: Vector3, duration: number, auraColor: Color3)
	local ring = Instance.new("Part")
	ring.Name = "TribulationTelegraphRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 2.0, 2.0)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = auraColor
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.4
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanTouch = false
	ring.Parent = workspace

	local tween = TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.2, 10.0, 10.0),
		Transparency = 0.1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		ring:Destroy()
	end)

	Debris:AddItem(ring, duration + 0.2)
end

function CombatVFXController.SpawnTribulationStrike(targetPos: Vector3, auraColor: Color3)
	local cloudHeight = 24
	local bolt = Instance.new("Part")
	bolt.Name = "TribulationLightningBolt"
	bolt.Size = Vector3.new(1.2, cloudHeight, 1.2)
	bolt.CFrame = CFrame.new(targetPos + Vector3.new(0, cloudHeight / 2, 0))
	bolt.Color = auraColor
	bolt.Material = Enum.Material.Neon
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanTouch = false
	bolt.Parent = workspace

	Play3DSound(THUNDER_STRIKE_SFX, targetPos, 2.5)
	CombatVFXController.AddCameraShake(1.2)

	local sparks = Instance.new("ParticleEmitter")
	sparks.Texture = "rbxassetid://242200234"
	sparks.Color = ColorSequence.new(auraColor)
	sparks.Size = NumberSequence.new(0.8, 0)
	sparks.Lifetime = NumberRange.new(0.2, 0.4)
	sparks.Rate = 0
	sparks.Speed = NumberRange.new(20, 45)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Parent = bolt
	sparks:Emit(35)

	local fadeTween = TweenService:Create(bolt, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(2.4, cloudHeight, 2.4),
		Transparency = 1,
	})
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		bolt:Destroy()
	end)

	Debris:AddItem(bolt, 0.5)
end

function CombatVFXController.SpawnAscensionPillar(pos: Vector3, auraColor: Color3)
	local pillar = Instance.new("Part")
	pillar.Name = "AscensionLightPillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(80, 4, 4)
	pillar.CFrame = CFrame.new(pos + Vector3.new(0, 38, 0)) * CFrame.Angles(0, 0, math.rad(90))
	pillar.Color = auraColor
	pillar.Material = Enum.Material.Neon
	pillar.Transparency = 0.2
	pillar.Anchored = true
	pillar.CanCollide = false
	pillar.CanTouch = false
	pillar.Parent = workspace

	Play3DSound(ASCENSION_GONG_SFX, pos, 3.0)
	CombatVFXController.AddCameraShake(1.5)

	local shockwave = Instance.new("Part")
	shockwave.Name = "AscensionShockwave"
	shockwave.Shape = Enum.PartType.Cylinder
	shockwave.Size = Vector3.new(0.3, 3, 3)
	shockwave.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	shockwave.Color = auraColor
	shockwave.Material = Enum.Material.Neon
	shockwave.Anchored = true
	shockwave.CanCollide = false
	shockwave.Parent = workspace

	TweenService:Create(shockwave, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.3, 36, 36),
		Transparency = 1,
	}):Play()

	local pillarTween = TweenService:Create(pillar, TweenInfo.new(2.0, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = Vector3.new(80, 16, 16),
		Transparency = 1,
	})
	pillarTween:Play()
	pillarTween.Completed:Connect(function()
		pillar:Destroy()
		shockwave:Destroy()
	end)

	Debris:AddItem(pillar, 2.5)
	Debris:AddItem(shockwave, 1.0)
end

-- =============================================================================
-- WEAPON-ATTUNED SLASHMARKS & COMBAT PARTICLES
-- =============================================================================
function CombatVFXController.SpawnSlashHitVFX(position: Vector3, orientationCFrame: CFrame?, weaponId: string?)
	local palette = ItemConfig.GetWeaponPalette(weaponId)

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

	local attTemplate = (vfxFolder and vfxFolder:FindFirstChild("SlashHitAnimation"))
		or (ReplicatedStorage:FindFirstChild("SlashHitAnimation", true) :: Attachment?)

	if attTemplate then
		local attClone = attTemplate:Clone()
		attClone.Parent = hitHolder
		for _, pe in ipairs(attClone:GetDescendants()) do
			if pe:IsA("ParticleEmitter") then
				pe.Color = palette.Gradient
				pe:Emit(pe:GetAttribute("EmitCount") or 4)
			end
		end
	else
		local slashMesh = Instance.new("Part")
		slashMesh.Name = "ProceduralSlashSlice"
		slashMesh.Size = Vector3.new(4.2, 0.15, 0.15)
		slashMesh.CFrame = hitHolder.CFrame * CFrame.Angles(math.rad(math.random(-25, 25)), 0, math.rad(math.random(35, 65)))
		slashMesh.Color = palette.PrimaryColor
		slashMesh.Material = Enum.Material.Neon
		slashMesh.Transparency = 0.05
		slashMesh.Anchored = true
		slashMesh.CanCollide = false
		slashMesh.Parent = hitHolder

		TweenService:Create(slashMesh, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Transparency = 1,
			Size = Vector3.new(5.2, 0.02, 0.02),
		}):Play()

		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxassetid://242200234"
		pe.Color = palette.Gradient
		pe.Size = NumberSequence.new(0.45, 0)
		pe.Lifetime = NumberRange.new(0.12, 0.22)
		pe.Rate = 0
		pe.Speed = NumberRange.new(18, 32)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.Parent = hitHolder
		pe:Emit(12)
	end

	Debris:AddItem(hitHolder, 0.4)
end

-- Intent text popups suppressed: No words or icons displayed
function CombatVFXController.SpawnIntentComboPopup(_position: Vector3, _comboCount: number, _currentIntent: number, _isEmpowered: boolean)
	-- Pure numbers only: Intent word popups are intentionally silenced
end

function CombatVFXController.SpawnTriplePurpleTwirl(originPos: Vector3, direction: Vector3, isLocalCaster: boolean, weaponId: string?)
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

	local palette = ItemConfig.GetWeaponPalette(weaponId)
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
					pe.Color = palette.Gradient
					ScaleParticleSize(pe, 2.8)
					if pe.Rate == 0 then pe.Rate = 24 end
					pe:Emit(2)
				end
			end

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

function CombatVFXController.SpawnUltimateSlashSphere(spherePos: Vector3, isLocalCaster: boolean, weaponId: string?)
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

	local palette = ItemConfig.GetWeaponPalette(weaponId)
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
			desc.Color = palette.Gradient
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

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player?, skillKey: string, payload: any?)
		local attackerChar = attacker and attacker.Character
		local hrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local origin = if hrp then hrp.Position else Vector3.zero
		local isLocal = (attacker == player)
		local myChar = player.Character
		local myHrp = if myChar then myChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local weaponId = attackerChar and attackerChar:GetAttribute("EquippedWeapon") :: string?

		if skillKey == "TribulationTelegraph" and type(payload) == "table" and payload.TargetPosition then
			CombatVFXController.SpawnTribulationTelegraph(
				payload.TargetPosition,
				payload.TelegraphTime or 1.2,
				payload.AuraColor or Color3.fromRGB(0, 220, 255)
			)
			return
		end

		if skillKey == "TribulationStrike" and type(payload) == "table" and payload.TargetPosition then
			CombatVFXController.SpawnTribulationStrike(
				payload.TargetPosition,
				payload.AuraColor or Color3.fromRGB(0, 220, 255)
			)
			if payload.Damage and payload.Damage > 0 then
				CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.Damage, true)
			end
			return
		end

		if skillKey == "AscensionBurst" and type(payload) == "table" then
			local burstPos = if hrp then hrp.Position else (player.Character and player.Character:GetPivot().Position or Vector3.zero)
			CombatVFXController.SpawnAscensionPillar(burstPos, payload.AuraColor or Color3.fromRGB(255, 215, 0))
			return
		end

		if skillKey == "M1" then
			if attacker ~= player and attacker ~= nil then
				Play3DSound(SWING_AIR_SOUND_ID, origin, 0.7)
			end
			CombatVFXController.CheckAndTriggerNearbyTrees(origin, 14)
		end

		if skillKey == "Q" and hrp then
			local aimDir = (hrp.CFrame.LookVector * Vector3.new(1, 0, 1)).Unit
			if type(payload) == "table" and payload.AimDirection then
				aimDir = payload.AimDirection
			end
			CombatVFXController.SpawnTriplePurpleTwirl(hrp.Position, aimDir, isLocal, weaponId)
			CombatVFXController.CheckAndTriggerNearbyTrees(origin, 26)
		end

		if skillKey == "F" then
			local spherePos = if type(payload) == "table" and payload.Origin then payload.Origin else (origin + Vector3.new(0, -0.4, 0))
			CombatVFXController.SpawnUltimateSlashSphere(spherePos, isLocal, weaponId)
			CombatVFXController.CheckAndTriggerNearbyTrees(spherePos, 32)
		end

		-- Supports both player and mob hits (MobAttackHit)
		if (skillKey == "MobAttackHit" or (type(payload) == "table" and payload.HasHit == true and payload.TargetPosition ~= nil)) then
			local targetPos: Vector3 = payload.TargetPosition
			local hitOrientation = if hrp then hrp.CFrame else (payload.AttackerCFrame or nil)

			CombatVFXController.CheckAndTriggerNearbyTrees(targetPos, 12)

			local isVictim = false
			if payload.Hits then
				for _, hitData in ipairs(payload.Hits) do
					if hitData.Character == player.Character then
						isVictim = true
						CombatVFXController.OnLocalPlayerDamaged(payload.Damage or 20, payload.IsCrit == true)
					end
				end
			end

			local distToFight = if myHrp then (myHrp.Position - targetPos).Magnitude else 999
			local isNearby = distToFight <= 28.0

			if payload.WasParried then
				CombatVFXController.SpawnParryClash(targetPos)
				CombatVFXController.SpawnDamageNumber(targetPos, 0, false)
			elseif payload.WasGuardBroken then
				Play3DSound(PARRY_CLASH_SOUND_ID, targetPos, 1.0)
				if isVictim or isLocal or isNearby then
					CombatVFXController.AddCameraShake(if (isVictim or isLocal) then 0.65 else 0.25)
					if isVictim or isLocal then
						CombatVFXController.ApplyHitstop(0.06)
					end
				end
				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage, true)
				end
			elseif payload.WasBlocked then
				Play3DSound(PARRY_CLASH_SOUND_ID, targetPos, 0.8)
				if isVictim or isLocal then
					CombatVFXController.AddCameraShake(0.20)
				end
				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage, false)
				else
					CombatVFXController.SpawnDamageNumber(targetPos, 0, false)
				end
			else
				Play3DSound(HIT_IMPACT_SOUND_ID, targetPos, 1.3)
				CombatVFXController.SpawnSlashHitVFX(targetPos, hitOrientation, weaponId)

				if attacker == player then
					CombatVFXController.AddCameraShake(payload.IsCrit and 0.45 or 0.25)
					CombatVFXController.ApplyHitstop(payload.IsCrit and 0.06 or 0.04)
				end

				if payload.Damage and payload.Damage > 0 then
					CombatVFXController.SpawnDamageNumber(targetPos, payload.Damage, payload.IsCrit == true)
				end
			end
		end
	end)

	combatVFXRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.EffectType or not payload.Position then return end

		local myChar = player.Character
		local myHrp = if myChar then myChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local dist = if myHrp then (myHrp.Position - payload.Position).Magnitude else 999
		if dist > 85 then return end

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

	print("[ASCEND] CombatVFXController Initialized (Full VFX Suite & High-Visibility Numbers Active).")
end

function CombatVFXController.ApplyHitstop(duration: number)
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local animator = if humanoid then humanoid:FindFirstChildOfClass("Animator") else nil
	if not animator then return end

	local savedSpeeds: { [AnimationTrack]: number } = {}
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		savedSpeeds[track] = track.Speed
		track:AdjustSpeed(0.05)
	end

	task.delay(duration, function()
		if animator and animator.Parent then
			for track, origSpeed in pairs(savedSpeeds) do
				if track and track.IsPlaying then
					track:AdjustSpeed(origSpeed)
				end
			end
		end
	end)
end

function CombatVFXController.SpawnParryClash(position: Vector3)
	Play3DSound(PARRY_CLASH_SOUND_ID, position, 1.0)
	local myChar = player.Character
	local myHrp = if myChar then myChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if myHrp and (myHrp.Position - position).Magnitude <= 24 then
		CombatVFXController.AddCameraShake(0.4)
	end

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
		ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 200)),
		ColorSequenceKeypoint.new(1.0, Color3.fromRGB(255, 140, 0)),
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

-- =============================================================================
-- PRESS START 2P / ARCADE: HIGH-VISIBILITY PURE NUMBERS
-- =============================================================================
function CombatVFXController.SpawnDamageNumber(position: Vector3, damage: number, isCrit: boolean?)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DamageNumberGui"
	billboard.Size = if isCrit then UDim2.new(0, 180, 0, 52) else UDim2.new(0, 140, 0, 42)
	billboard.StudsOffsetWorldSpace = position + Vector3.new(math.random(-8, 8) / 10, 2.2, math.random(-8, 8) / 10)
	billboard.AlwaysOnTop = true
	billboard.Adornee = workspace.Terrain
	billboard.Parent = workspace

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1

	local ok = pcall(function()
		label.FontFace = Font.fromName("Press Start 2P")
	end)
	if not ok then
		label.Font = Enum.Font.Arcade
	end

	label.Text = tostring(math.max(0, math.floor(damage)))

	local s = Instance.new("UIStroke", label)

	if isCrit then
		label.TextSize = 28
		label.TextColor3 = Color3.fromRGB(255, 205, 40)
		s.Color = Color3.fromRGB(160, 40, 0)
		s.Thickness = 2.4
	else
		label.TextSize = 20
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		s.Color = Color3.fromRGB(15, 15, 20)
		s.Thickness = 2.0
	end

	label.Parent = billboard

	local targetOffset = billboard.StudsOffsetWorldSpace + Vector3.new(0, isCrit and 3.6 or 2.8, 0)

	local floatTween = TweenService:Create(billboard, TweenInfo.new(isCrit and 0.85 or 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		StudsOffsetWorldSpace = targetOffset,
	})

	local fadeTween = TweenService:Create(label, TweenInfo.new(isCrit and 0.85 or 0.75, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
	})

	floatTween:Play()
	fadeTween:Play()

	floatTween.Completed:Connect(function()
		billboard:Destroy()
	end)
end

return CombatVFXController