--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Client-side visual and audio effects engine for ASCEND.
    Features Mythic Magma Quality & 3-Wave Sharp Crescent Moon Cleave Effects.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CombatVFXController = {}
CombatVFXController.__index = CombatVFXController

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Audio Asset Mappings
local SWING_SOUND_ID = "rbxassetid://134671877618939"
local THUNDER_SOUND_ID = "rbxassetid://9120021541"

local WEAPON_HIT_SOUNDS = {
	FlyingSword = "rbxassetid://140462043853173",
	Gauntlet    = "rbxassetid://138208560796742",
	Spear       = "rbxassetid://135278368445325",
}

local SKILL_SOUNDS: { [string]: any } = {
	Shift = "rbxassetid://74818885604525",

	FlyingSword = {
		F = "rbxassetid://80602493348966",
		Q = "rbxassetid://127120106558731",
		E = "rbxassetid://109735549169421",
		R = "rbxassetid://121761867811041",
	},
}

function CombatVFXController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		CombatVFXController.OnCombatAction(attacker, skillKey, payload)
	end)

	print("[ASCEND] CombatVFXController Initialized with 3-Wave Magma Crescent Moon VFX.")
end

function CombatVFXController.OnCombatAction(attacker: Player, skillKey: string, payload: any?)
	-- 1. Handle Heavenly Tribulation
	if skillKey == "TribulationTelegraph" and payload then
		CombatVFXController.CreateTelegraphRing(payload.TargetPosition, payload.TelegraphTime or 1.5, payload.AuraColor)
		return
	elseif skillKey == "TribulationStrike" and payload then
		CombatVFXController.CreateLightningStrike(payload.TargetPosition, payload.AuraColor)
		CombatVFXController.ShakeCamera(0.4, 1.4)
		return
	elseif skillKey == "AscensionBurst" and payload then
		local char = attacker and attacker.Character
		if char then
			CombatVFXController.CreateAscensionBurst(char, payload.AuraColor)
			CombatVFXController.ShakeCamera(0.5, 1.8)
		end
		return
	end

	local attackerChar = attacker and attacker.Character
	local weaponType = (payload and payload.WeaponType)
		or (attackerChar and attackerChar:GetAttribute("WeaponType"))
		or "FlyingSword"

	local equippedWeapon = (attackerChar and attackerChar:GetAttribute("EquippedWeaponId")) or "SunSlayerCrimsonSword"

	-- 2. Play Skill Audio, Trails & Particles
	if attackerChar then
		local hrp = attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			if skillKey == "Shift" then
				CombatVFXController.TriggerShiftDashTrail(attackerChar, 0.3)
				CombatVFXController.PlaySound(SKILL_SOUNDS.Shift, hrp, 0.7)
			elseif skillKey == "M1" then
				CombatVFXController.TriggerWeaponTrail(attackerChar, 0.25)
				CombatVFXController.PlaySound(SWING_SOUND_ID, hrp, 0.6)
				CombatVFXController.RenderSkillParticleEffect(attackerChar, weaponType, "M1", tostring(equippedWeapon))
			elseif skillKey == "F" or skillKey == "Q" or skillKey == "E" or skillKey == "R" then
				CombatVFXController.TriggerWeaponTrail(attackerChar, 0.35)
				
				local weaponSkillMap = SKILL_SOUNDS[weaponType] or SKILL_SOUNDS.FlyingSword
				local skillSoundId = weaponSkillMap[skillKey] or SWING_SOUND_ID
				CombatVFXController.PlaySound(skillSoundId, hrp, 0.85)

				CombatVFXController.RenderSkillParticleEffect(attackerChar, weaponType, skillKey, tostring(equippedWeapon))
			end
		end
	end

	-- 3. Camera Shake for Local Attacker
	if attacker == player then
		if skillKey == "R" then
			CombatVFXController.ShakeCamera(0.4, 1.5)
		elseif skillKey == "F" then
			CombatVFXController.ShakeCamera(0.25, 0.8)
		elseif skillKey == "E" or skillKey == "Q" then
			CombatVFXController.ShakeCamera(0.2, 0.6)
		elseif skillKey == "M1" then
			CombatVFXController.ShakeCamera(0.08, 0.2)
		end
	end

	-- 4. Damage Numbers & Hit Impacts
	if payload and type(payload) == "table" and payload.Damage and payload.Damage > 0 then
		if payload.TargetPosition then
			CombatVFXController.CreateDamageNumber(payload.TargetPosition, payload.Damage, payload.IsCrit)
			CombatVFXController.CreateHitImpactEffect(payload.TargetPosition)
			
			local hitSoundId = WEAPON_HIT_SOUNDS[weaponType] or WEAPON_HIT_SOUNDS.FlyingSword

			local hitPart = Instance.new("Part")
			hitPart.Position = payload.TargetPosition
			hitPart.Transparency = 1
			hitPart.Anchored = true
			hitPart.CanCollide = false
			hitPart.Parent = Workspace
			
			CombatVFXController.PlaySound(hitSoundId, hitPart, 0.8)
			Debris:AddItem(hitPart, 1.0)
		end
	end
end

--------------------------------------------------------------------------------
-- HELPER: CONSECUTIVE CRESCENT MOON MAGMA CLEAVE WAVE SPANWER
--------------------------------------------------------------------------------
local function SpawnCrescentMagmaWave(hrp: BasePart, offsetAngle: number, delayTime: number, scaleFactor: number)
	task.delay(delayTime, function()
		if not hrp or not hrp.Parent then return end

		-- Sharp Crescent Moon Wave Part
		local wave = Instance.new("Part")
		wave.Name = "MagmaCrescentWave"
		wave.Size = Vector3.new(0.3, 10 * scaleFactor, 3.5 * scaleFactor)
		wave.CFrame = hrp.CFrame * CFrame.new(0, 0, -2) * CFrame.Angles(0, math.rad(offsetAngle), math.rad(90 + offsetAngle * 0.5))
		wave.Color = Color3.fromRGB(255, 70, 0) -- Incandescent Magma Orange-Red
		wave.Material = Enum.Material.Neon
		wave.CanCollide = false
		wave.Anchored = true
		wave.Parent = Workspace

		-- Sphere mesh scaled to create a sharp crescent moon arc shape
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Sphere
		mesh.Scale = Vector3.new(0.08, 1.3, 0.4)
		mesh.Parent = wave

		-- Trailing Molten Lava Flames
		local flame = Instance.new("ParticleEmitter")
		flame.Name = "MagmaWaveTrail"
		flame.Texture = "rbxassetid://242203597" -- Flame / Ember texture
		flame.LightEmission = 0.8
		flame.LightInfluence = 0.1
		flame.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 60)), -- Gold-White Core
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 60, 0)),  -- Molten Lava Orange
			ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 10, 0))    -- Dark Crimson Ash
		})
		flame.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5 * scaleFactor),
			NumberSequenceKeypoint.new(1, 0)
		})
		flame.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(1, 1)
		})
		flame.Lifetime = NumberRange.new(0.2, 0.4)
		flame.Rate = 22
		flame.Speed = NumberRange.new(1.5, 3.5)
		flame.Parent = wave

		-- Forward Crescent Wave Motion
		local travelDistance = 34 * scaleFactor
		local targetCFrame = wave.CFrame * CFrame.new(0, travelDistance, 0)
		
		local tween = TweenService:Create(wave, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			CFrame = targetCFrame,
			Transparency = 1
		})
		
		local meshTween = TweenService:Create(mesh, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = Vector3.new(0.02, 2.4 * scaleFactor, 0.9 * scaleFactor) -- Crescent arc expands & sharpens as it slices forward
		})

		tween:Play()
		meshTween:Play()
		Debris:AddItem(wave, 0.38)
	end)
end

--------------------------------------------------------------------------------
-- PROCEDURAL SKILL VISUAL EFFECTS RENDERER (Magma Quality Engine)
--------------------------------------------------------------------------------

function CombatVFXController.RenderSkillParticleEffect(character: Model, weaponType: string, skillKey: string, equippedWeaponId: string?)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local isSunSlayer = (equippedWeaponId == "SunSlayerCrimsonSword" or equippedWeaponId == "Sun-Slayer Crimson Sword")
	
	-- Magma Quality Palette: Incandescent Orange-Red Core & Deep Crimson Lava
	local magmaCoreColor = Color3.fromRGB(255, 70, 0)
	local magmaDarkColor = Color3.fromRGB(180, 15, 0)

	if weaponType == "FlyingSword" then
		if skillKey == "M1" and isSunSlayer then
			-- M1 Single Sharp Crescent Magma Slash
			SpawnCrescentMagmaWave(hrp, math.random(-15, 15), 0, 0.8)

		elseif skillKey == "F" then
			if isSunSlayer then
				-- F SKILL: CONSECUTIVE 3-WAVE CRESCENT MOON MAGMA CLEAVE
				SpawnCrescentMagmaWave(hrp, 25, 0.00, 1.0)   -- Wave 1: Right Arc
				SpawnCrescentMagmaWave(hrp, -25, 0.08, 1.1)  -- Wave 2: Left Arc
				SpawnCrescentMagmaWave(hrp, 0, 0.16, 1.45)   -- Wave 3: Heavy Central Moon Cleave!
			else
				-- Standard Non-Mythic Thrust
				local beam = Instance.new("Part")
				beam.Size = Vector3.new(1.2, 1.2, 16)
				beam.CFrame = hrp.CFrame * CFrame.new(0, 0, -9)
				beam.Color = Color3.fromRGB(0, 220, 255)
				beam.Material = Enum.Material.Neon
				beam.CanCollide = false
				beam.Anchored = true
				beam.Parent = Workspace

				TweenService:Create(beam, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.1, 0.1, 18),
					Transparency = 1,
				}):Play()
				Debris:AddItem(beam, 0.35)
			end

		elseif skillKey == "Q" then
			-- Q SKILL: Volcanic Magma Eruption Tempest
			local ring = Instance.new("Part")
			ring.Shape = Enum.PartType.Cylinder
			ring.Size = Vector3.new(0.4, 4, 4)
			ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
			ring.Color = if isSunSlayer then magmaCoreColor else Color3.fromRGB(0, 220, 255)
			ring.Material = Enum.Material.Neon
			ring.Transparency = 0.2
			ring.CanCollide = false
			ring.Anchored = true
			ring.Parent = Workspace

			TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.4, 22, 22),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ring, 0.45)

		elseif skillKey == "E" then
			-- E SKILL: Obsidian Volcanic Vortex
			local vortex = Instance.new("Part")
			vortex.Shape = Enum.PartType.Cylinder
			vortex.Size = Vector3.new(6, 6, 6)
			vortex.CFrame = hrp.CFrame * CFrame.Angles(math.rad(90), 0, 0)
			vortex.Color = if isSunSlayer then magmaDarkColor else Color3.fromRGB(0, 140, 255)
			vortex.Material = Enum.Material.ForceField
			vortex.CanCollide = false
			vortex.Anchored = true
			vortex.Parent = Workspace

			TweenService:Create(vortex, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				Size = Vector3.new(15, 15, 15),
				Transparency = 1,
			}):Play()
			Debris:AddItem(vortex, 0.55)

		elseif skillKey == "R" then
			-- R SKILL: Volcanic Moon Sunfall (ULTIMATE)
			local moonBlade = Instance.new("Part")
			moonBlade.Size = Vector3.new(1, 26, 6)
			moonBlade.CFrame = hrp.CFrame * CFrame.new(0, 14, -12) * CFrame.Angles(math.rad(45), 0, 0)
			moonBlade.Color = magmaCoreColor
			moonBlade.Material = Enum.Material.Neon
			moonBlade.CanCollide = false
			moonBlade.Anchored = true
			moonBlade.Parent = Workspace

			local mesh = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Scale = Vector3.new(0.1, 1.4, 0.6)
			mesh.Parent = moonBlade

			if isSunSlayer then
				local groundShockwave = Instance.new("Part")
				groundShockwave.Shape = Enum.PartType.Cylinder
				groundShockwave.Size = Vector3.new(0.5, 4, 4)
				groundShockwave.CFrame = CFrame.new(hrp.Position + hrp.CFrame.LookVector * 12 - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
				groundShockwave.Color = magmaDarkColor
				groundShockwave.Material = Enum.Material.Neon
				groundShockwave.CanCollide = false
				groundShockwave.Anchored = true
				groundShockwave.Parent = Workspace

				TweenService:Create(groundShockwave, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.5, 28, 28),
					Transparency = 1,
				}):Play()
				Debris:AddItem(groundShockwave, 0.55)
			end

			TweenService:Create(moonBlade, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.1, 36, 10),
				Transparency = 1,
			}):Play()
			Debris:AddItem(moonBlade, 0.55)
		end
	end
end

--------------------------------------------------------------------------------
-- UTILITY RENDER FUNCTIONS
--------------------------------------------------------------------------------

function CombatVFXController.CreateTelegraphRing(worldPos: Vector3, duration: number, color: Color3?)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(worldPos - Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = color or Color3.fromRGB(255, 30, 30)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.3
	ring.CanCollide = false
	ring.Anchored = true
	ring.Parent = Workspace

	local tween = TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = Vector3.new(0.2, 14, 14),
		Transparency = 0.8
	})
	tween:Play()

	Debris:AddItem(ring, duration + 0.1)
end

function CombatVFXController.CreateLightningStrike(worldPos: Vector3, color: Color3?)
	local strikeColor = color or Color3.fromRGB(255, 50, 50)

	local bolt = Instance.new("Part")
	bolt.Name = "LightningBolt"
	bolt.Size = Vector3.new(3.5, 220, 3.5)
	bolt.Position = worldPos + Vector3.new(0, 110, 0)
	bolt.Color = strikeColor
	bolt.Material = Enum.Material.Neon
	bolt.CanCollide = false
	bolt.Anchored = true
	bolt.Parent = Workspace

	local lightPart = Instance.new("Part")
	lightPart.Position = worldPos
	lightPart.Transparency = 1
	lightPart.Anchored = true
	lightPart.CanCollide = false
	lightPart.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = 15
	light.Color = strikeColor
	light.Parent = lightPart

	pcall(function()
		CombatVFXController.PlaySound(THUNDER_SOUND_ID, lightPart, 0.8)
	end)

	TweenService:Create(bolt, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.1, 220, 0.1),
		Transparency = 1
	}):Play()

	TweenService:Create(light, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0
	}):Play()

	Debris:AddItem(bolt, 0.3)
	Debris:AddItem(lightPart, 0.5)
end

function CombatVFXController.CreateAscensionBurst(character: Model, color: Color3?)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local burstColor = color or Color3.fromRGB(255, 70, 0)

	local burstRing = Instance.new("Part")
	burstRing.Shape = Enum.PartType.Cylinder
	burstRing.Size = Vector3.new(0.5, 2, 2)
	burstRing.CFrame = CFrame.new(hrp.Position - Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	burstRing.Color = burstColor
	burstRing.Material = Enum.Material.Neon
	burstRing.CanCollide = false
	burstRing.Anchored = true
	burstRing.Parent = Workspace

	TweenService:Create(burstRing, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.5, 30, 30),
		Transparency = 1
	}):Play()

	Debris:AddItem(burstRing, 0.65)
end

function CombatVFXController.TriggerShiftDashTrail(character: Model, duration: number)
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 1.8, 0)
	att0.Parent = hrp

	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, -1.8, 0)
	att1.Parent = hrp

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 120, 0), Color3.fromRGB(180, 15, 0))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = 0.3
	trail.MinLength = 0.1
	trail.LightEmission = 0.85
	trail.Parent = hrp

	task.delay(duration, function()
		trail.Enabled = false
		Debris:AddItem(att0, 0.4)
		Debris:AddItem(att1, 0.4)
		Debris:AddItem(trail, 0.4)
	end)
end

function CombatVFXController.TriggerWeaponTrail(character: Model, duration: number)
	local weapon = character:FindFirstChild("Equipped3DWeapon") or character:FindFirstChild("Equipped3DWeapon", true)
	if not weapon then return end

	local existingTrail = weapon:FindFirstChild("WeaponTrail", true) :: Trail?
	if existingTrail then
		existingTrail.Enabled = true
		task.delay(duration, function()
			if existingTrail then existingTrail.Enabled = false end
		end)
		return
	end

	local handle = weapon:FindFirstChild("Handle") or weapon:FindFirstChildOfClass("MeshPart") or weapon:FindFirstChildOfClass("BasePart")
	if not handle then return end

	local att0 = handle:FindFirstChild("TrailAtt0") :: Attachment? or Instance.new("Attachment")
	att0.Name = "TrailAtt0"
	att0.Position = Vector3.new(0, 1.5, 0)
	att0.Parent = handle

	local att1 = handle:FindFirstChild("TrailAtt1") :: Attachment? or Instance.new("Attachment")
	att1.Name = "TrailAtt1"
	att1.Position = Vector3.new(0, -1.5, 0)
	att1.Parent = handle

	local dynamicTrail = Instance.new("Trail")
	dynamicTrail.Attachment0 = att0
	dynamicTrail.Attachment1 = att1
	dynamicTrail.Color = ColorSequence.new(Color3.fromRGB(255, 120, 0), Color3.fromRGB(180, 15, 0))
	dynamicTrail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(1, 1),
	})
	dynamicTrail.Lifetime = 0.25
	dynamicTrail.LightEmission = 0.9
	dynamicTrail.Parent = handle

	task.delay(duration, function()
		dynamicTrail.Enabled = false
		Debris:AddItem(dynamicTrail, 0.3)
	end)
end

function CombatVFXController.PlaySound(soundId: string, parent: Instance, volume: number?)
	pcall(function()
		local sound = Instance.new("Sound")
		sound.SoundId = soundId
		sound.Volume = volume or 0.6
		sound.Parent = parent
		sound:Play()
		sound.Ended:Connect(function()
			sound:Destroy()
		end)
	end)
end

function CombatVFXController.ShakeCamera(duration: number, intensity: number)
	if not camera then return end

	local startTime = os.clock()
	task.spawn(function()
		while os.clock() - startTime < duration do
			local offset = Vector3.new(
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity,
				(math.random() - 0.5) * intensity
			)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
			task.wait(0.015)
		end
	end)
end

function CombatVFXController.CreateDamageNumber(worldPosition: Vector3, damageAmount: number, isCrit: boolean?)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Position = worldPosition + Vector3.new(math.random(-1, 1), 2, math.random(-1, 1))
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Parent = Workspace

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 120, 0, 48)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = part

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = tostring(math.round(damageAmount))
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextColor3 = if isCrit then Color3.fromRGB(255, 70, 0) else Color3.fromRGB(255, 255, 255)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 25)
	textLabel.Parent = billboard

	local tweenPosition = TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = part.Position + Vector3.new(0, 3.5, 0)
	})
	local tweenFade = TweenService:Create(textLabel, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})

	tweenPosition:Play()
	tweenFade:Play()

	tweenFade.Completed:Connect(function()
		part:Destroy()
	end)
end

function CombatVFXController.CreateHitImpactEffect(worldPosition: Vector3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.5, 0.5, 0.5)
	part.Position = worldPosition
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.Parent = Workspace

	local attachment = Instance.new("Attachment")
	attachment.Parent = part

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = "rbxassetid://132857904784003"
	particles.Rate = 0
	particles.Speed = NumberRange.new(12, 28)
	particles.Lifetime = NumberRange.new(0.15, 0.35)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(1, 0)
	})
	particles.Color = ColorSequence.new(Color3.fromRGB(255, 120, 0), Color3.fromRGB(180, 15, 0))
	particles.Parent = attachment

	particles:Emit(16)

	Debris:AddItem(part, 0.5)
end

return CombatVFXController