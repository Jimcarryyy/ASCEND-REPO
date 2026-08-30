--!strict
--[[
    CombatVFXController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
    Client VFX and Audio engine:
    - Spawns "SlashHitAnimation" Attachment VFX on targets when struck
    - Hitstop Micro-Pause, Guard-Break Shatter, Clash Sparks, and Scaled Damage Numbers
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
local HIT_IMPACT_SOUND_ID = "rbxassetid://140462043853173"
local PARRY_CLASH_SOUND_ID = "rbxassetid://9114223175"

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

-- Spawns "SlashHitAnimation" on target position
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

function CombatVFXController.Init()
	combatVFXRemote = RemoteEvents.GetRemote("CombatVFX")
	combatActionRemote = RemoteEvents.GetRemote("CombatAction")

	combatActionRemote.OnClientEvent:Connect(function(attacker: Player, skillKey: string, payload: any?)
		local attackerChar = attacker.Character
		local hrp = if attackerChar then attackerChar:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local origin = if hrp then hrp.Position else Vector3.zero

		if skillKey == "M1" and attacker ~= player then
			Play3DSound(SWING_AIR_SOUND_ID, origin, 0.7)
		end

		if type(payload) == "table" and payload.HasHit == true and payload.TargetPosition ~= nil then
			if payload.WasParried then
				-- Handled by ParryClash
			elseif payload.WasGuardBroken then
				Play3DSound(PARRY_CLASH_SOUND_ID, payload.TargetPosition, 1.0)
				CombatVFXController.AddCameraShake(0.55)
				CombatVFXController.ApplyHitstop(0.06)
				CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.Damage, true, Color3.fromRGB(255, 60, 60), "💥 GUARD BREAK!")
			elseif payload.WasBlocked then
				Play3DSound(PARRY_CLASH_SOUND_ID, payload.TargetPosition, 0.7)
				if attacker == player then CombatVFXController.AddCameraShake(0.15) end
				CombatVFXController.SpawnDamageNumber(payload.TargetPosition, payload.Damage, false, Color3.fromRGB(175, 195, 220), "🛡️")
			else
				-- Clean Strike: Spawn SlashHitAnimation
				Play3DSound(HIT_IMPACT_SOUND_ID, payload.TargetPosition, 0.95)
				CombatVFXController.SpawnSlashHitVFX(payload.TargetPosition, hrp and hrp.CFrame)

				if attacker == player then
					CombatVFXController.AddCameraShake(payload.IsCrit and 0.45 or 0.25)
					CombatVFXController.ApplyHitstop(0.04)
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

	print("[ASCEND] CombatVFXController Initialized (Hitstop & Slash Hit Active).")
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

function CombatVFXController.AddCameraShake(intensity: number)
	shakeIntensity = math.clamp(shakeIntensity + intensity, 0, 1.5)
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
		label.Text = string.format("%s %s", prefixText, formattedNum)
	elseif isCrit then
		label.Text = string.format("CRIT! %s", formattedNum)
	else
		label.Text = formattedNum
	end

	label.Font = Enum.Font.LuckiestGuy

	if isCrit then
		label.TextSize = 34
		label.TextColor3 = customColor or Color3.fromRGB(255, 215, 0)
		label.TextStrokeTransparency = 0
		label.TextStrokeColor3 = Color3.fromRGB(130, 25, 0)
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