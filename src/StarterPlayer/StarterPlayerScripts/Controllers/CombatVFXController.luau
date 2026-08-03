--!strict
--[[
    CombatVFXController.luau
    Client-side visual and audio effects handler for ASCEND combat.
    Renders camera shake, floating damage text, white slash trails,
    swing audio SFX, and hit impact sounds locally.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local CombatVFXController = {}
CombatVFXController.__index = CombatVFXController

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Sound Effects Asset IDs
local SWING_SOUND_ID = "rbxassetid://12222216" -- Classic weapon swing SFX
local HIT_SOUND_ID = "rbxassetid://5633903110"  -- Impact hit SFX

function CombatVFXController.Init()
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	-- Listen for server combat broadcasts
	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		CombatVFXController.OnCombatAction(attacker, skillKey, payload)
	end)

	print("[ASCEND] CombatVFXController Initialized.")
end

function CombatVFXController.OnCombatAction(attacker: Player, skillKey: string, payload: any?)
	local attackerChar = attacker.Character
	if attackerChar then
		-- 1. Trigger Crisp White Weapon Slash Trail
		if skillKey == "M1" or skillKey == "F" or skillKey == "Q" or skillKey == "E" or skillKey == "R" then
			CombatVFXController.TriggerWeaponTrail(attackerChar, 0.25)
			CombatVFXController.PlaySound(SWING_SOUND_ID, attackerChar:FindFirstChild("HumanoidRootPart") or attackerChar, 0.5)
		end
	end

	-- 2. Camera Shake if Local Player is attacker
	if attacker == player then
		if skillKey == "F" or skillKey == "R" or skillKey == "E" then
			CombatVFXController.ShakeCamera(0.25, 0.7)
		elseif skillKey == "M1" or skillKey == "Q" then
			CombatVFXController.ShakeCamera(0.12, 0.3)
		end
	end

	-- 3. Render Floating Damage Text, Impact Particles, & Hit Sound ONLY when an enemy is hit
	if payload and type(payload) == "table" and payload.Damage and payload.Damage > 0 then
		if payload.TargetPosition then
			CombatVFXController.CreateDamageNumber(payload.TargetPosition, payload.Damage, payload.IsCrit)
			CombatVFXController.CreateHitImpactEffect(payload.TargetPosition)
			
			-- Play impact sound at hit location
			local hitPart = Instance.new("Part")
			hitPart.Position = payload.TargetPosition
			hitPart.Transparency = 1
			hitPart.Anchored = true
			hitPart.CanCollide = false
			hitPart.Parent = Workspace
			
			CombatVFXController.PlaySound(HIT_SOUND_ID, hitPart, 0.7)
			task.delay(1.0, function() hitPart:Destroy() end)
		end
	end
end

function CombatVFXController.TriggerWeaponTrail(character: Model, duration: number)
	local weapon = character:FindFirstChild("Equipped3DWeapon") or character:FindFirstChild("Equipped3DWeapon", true)
	if not weapon then return end

	local trail = weapon:FindFirstChild("WeaponTrail", true) :: Trail?
	if trail then
		trail.Enabled = true
		task.delay(duration, function()
			if trail then
				trail.Enabled = false
			end
		end)
	end
end

function CombatVFXController.PlaySound(soundId: string, parent: Instance, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = parent
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
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

	-- Animate floating upward and fading out over 0.8 seconds
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

	-- Spirit Impact Particle Burst
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

	task.delay(0.5, function()
		part:Destroy()
	end)
end

return CombatVFXController