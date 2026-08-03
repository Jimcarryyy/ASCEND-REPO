--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Client-side visual and audio effects handler for ASCEND combat and Heavenly Tribulation events.
    Renders camera shake, floating damage text, slash trails, lightning beams, weapon hit sounds, and ascension bursts.
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
local SWING_SOUND_ID = "rbxassetid://134671877618939"     -- Universal Swing for all weapons
local THUNDER_SOUND_ID = "rbxassetid://9120021541"   -- Heavenly Tribulation Thunder

local WEAPON_HIT_SOUNDS = {
	FlyingSword = "rbxassetid://140462043853173",       -- Sword Hit Impact
	Gauntlet    = "rbxassetid://138208560796742",       -- Punch/Gauntlet Hit Impact
	Spear       = "rbxassetid://135278368445325",       -- Spear Piercing Hit Impact
}

function CombatVFXController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		CombatVFXController.OnCombatAction(attacker, skillKey, payload)
	end)

	print("[ASCEND] CombatVFXController Initialized with Weapon SFX.")
end

function CombatVFXController.OnCombatAction(attacker: Player, skillKey: string, payload: any?)
	-- 1. Handle Heavenly Tribulation Visuals & SFX
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

	-- 2. Standard Weapon Swing Trails & Swing SFX
	local attackerChar = attacker and attacker.Character
	if attackerChar then
		if skillKey == "M1" or skillKey == "F" or skillKey == "Q" or skillKey == "E" or skillKey == "R" then
			CombatVFXController.TriggerWeaponTrail(attackerChar, 0.25)
			CombatVFXController.PlaySound(SWING_SOUND_ID, attackerChar:FindFirstChild("HumanoidRootPart") or attackerChar, 0.6)
		elseif skillKey == "Shift" then
			CombatVFXController.TriggerShiftDashTrail(attackerChar, 0.3)
		end
	end

	-- 3. Camera Shake for local player attacks
	if attacker == player then
		if skillKey == "F" or skillKey == "R" or skillKey == "E" then
			CombatVFXController.ShakeCamera(0.25, 0.7)
		elseif skillKey == "M1" or skillKey == "Q" then
			CombatVFXController.ShakeCamera(0.12, 0.3)
		end
	end

	-- 4. Hit Impacts & Weapon-Specific Hit Sounds
	if payload and type(payload) == "table" and payload.Damage and payload.Damage > 0 then
		if payload.TargetPosition then
			CombatVFXController.CreateDamageNumber(payload.TargetPosition, payload.Damage, payload.IsCrit)
			CombatVFXController.CreateHitImpactEffect(payload.TargetPosition)
			
			-- Resolve Weapon Type: 1) Payload -> 2) Attacker Character Attribute -> 3) Equipped Model -> Fallback
			local detectedWeapon = payload.WeaponType
			if not detectedWeapon and attackerChar then
				detectedWeapon = attackerChar:GetAttribute("WeaponType")
			end
			if not detectedWeapon and attackerChar then
				local equipped3D = attackerChar:FindFirstChild("Equipped3DWeapon") or attackerChar:FindFirstChild("Equipped3DWeapon", true)
				if equipped3D then
					detectedWeapon = equipped3D:GetAttribute("WeaponType")
				end
			end

			local weaponType = detectedWeapon or "FlyingSword"
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

	local burstColor = color or Color3.fromRGB(255, 215, 0)

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
	trail.Color = ColorSequence.new(Color3.fromRGB(0, 230, 255), Color3.fromRGB(255, 255, 255))
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
	dynamicTrail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 220, 255))
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
	textLabel.TextColor3 = if isCrit then Color3.fromRGB(255, 215, 0) else Color3.fromRGB(255, 255, 255)
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
	particles.Color = ColorSequence.new(Color3.fromRGB(120, 230, 255), Color3.fromRGB(255, 255, 255))
	particles.Parent = attachment

	particles:Emit(16)

	Debris:AddItem(part, 0.5)
end

return CombatVFXController