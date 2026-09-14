--!strict
--[[
    WindEnvironmentController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/WindEnvironmentController.luau
    Client environmental controller for ASCEND.
    - 🚀 Environmental Ambient Wind Audio (rbxassetid://139095330035399) with dynamic gust modulation
    - Stylized Wind Ribbons (Speed trails) streaming through the world camera
    - Dynamic Day Spores vs. Night Celestial Fireflies
    - Organic gusting wind sway on trees, bamboo & foliage
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")

local WindEnvironmentController = {}

local MAX_CULL_DISTANCE = 160
local camera = Workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

-- Environmental Wind Audio Asset
local WIND_AMBIENT_SOUND_ID = "rbxassetid://139095330035399"
local ambientWindSound: Sound? = nil

export type PlantType = "LargeTree" | "SmallTree" | "Bamboo" | "Grass"

type AnimatedFoliageData = {
	Part: BasePart,
	OriginalCFrame: CFrame,
	PhaseOffset: number,
	PlantCategory: PlantType,
}

local foliageList: { AnimatedFoliageData } = {}

local FOLIAGE_PATTERNS = {
	"leaf", "leaves", "canopy", "foliage", "crown", "pineleaves", "top", "bamboo", "grass", "bush"
}

local function CategorizePlant(instance: Instance, partName: string): PlantType
	local nameLower = partName:lower()
	local modelName = (if instance.Parent then instance.Parent.Name else ""):lower()

	if nameLower:find("bamboo") or modelName:find("bamboo") then
		return "Bamboo"
	elseif nameLower:find("grass") or modelName:find("grass") then
		return "Grass"
	elseif nameLower:find("pine") or modelName:find("pine") or nameLower:find("large") then
		return "LargeTree"
	else
		return "SmallTree"
	end
end

function WindEnvironmentController.ScanEnvironment()
	table.clear(foliageList)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local partName = descendant.Name:lower()
			local isPlant = false

			for _, pattern in ipairs(FOLIAGE_PATTERNS) do
				if partName:find(pattern) then
					isPlant = true
					break
				end
			end

			if isPlant then
				local pos = descendant.Position
				local phase = (pos.X * 0.08) + (pos.Z * 0.08)
				local category = CategorizePlant(descendant, partName)

				table.insert(foliageList, {
					Part = descendant,
					OriginalCFrame = descendant.CFrame,
					PhaseOffset = phase,
					PlantCategory = category,
				})
			end
		end
	end
end

-- =============================================================================
-- AMBIENT WIND AUDIO ENGINE (Dynamic Gust Modulation)
-- =============================================================================
local function SetupAmbientWindAudio()
	local existing = SoundService:FindFirstChild("AmbientWindSound")
	if existing then existing:Destroy() end

	local sound = Instance.new("Sound")
	sound.Name = "AmbientWindSound"
	sound.SoundId = WIND_AMBIENT_SOUND_ID
	sound.Looped = true
	sound.Volume = 0.35
	sound.PlaybackSpeed = 1.0
	sound.Parent = SoundService

	sound:Play()
	ambientWindSound = sound
end

-- =============================================================================
-- CAMERA-FOLLOWING ATMOSPHERIC WIND TRAILS & FIREFLIES
-- =============================================================================
local function SetupAtmosphericWind()
	local existing = camera:FindFirstChild("AtmosphericWindAnchor")
	if existing then existing:Destroy() end

	local anchor = Instance.new("Part")
	anchor.Name = "AtmosphericWindAnchor"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanTouch = false
	anchor.CanQuery = false
	anchor.Parent = camera

	-- 1. Stylized Wind Streak Ribbons
	local windAtt = Instance.new("Attachment")
	windAtt.Name = "WindRibbonAtt"
	windAtt.Parent = anchor

	local windRibbons = Instance.new("ParticleEmitter")
	windRibbons.Name = "WindRibbons"
	windRibbons.Texture = "rbxassetid://6454399793" -- Soft streak line texture
	windRibbons.Orientation = Enum.ParticleOrientation.VelocityParallel
	windRibbons.Rate = 8
	windRibbons.Lifetime = NumberRange.new(1.4, 2.2)
	windRibbons.Speed = NumberRange.new(22, 38)
	windRibbons.SpreadAngle = Vector2.new(15, 8)
	windRibbons.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.1),
		NumberSequenceKeypoint.new(0.3, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.25),
		NumberSequenceKeypoint.new(1.0, 0.0),
	})
	windRibbons.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.0),
		NumberSequenceKeypoint.new(0.2, 0.60),
		NumberSequenceKeypoint.new(0.8, 0.70),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	windRibbons.Color = ColorSequence.new(Color3.fromRGB(235, 245, 255))
	windRibbons.LightEmission = 0.5
	windRibbons.Parent = windAtt

	-- 2. Ambient Floating Spirit Spores / Fireflies
	local fireflyAtt = Instance.new("Attachment")
	fireflyAtt.Name = "FireflyAtt"
	fireflyAtt.Parent = anchor

	local fireflies = Instance.new("ParticleEmitter")
	fireflies.Name = "SpiritFireflies"
	fireflies.Texture = "rbxassetid://242200234" -- Soft glowing orb
	fireflies.Rate = 12
	fireflies.Lifetime = NumberRange.new(2.5, 4.0)
	fireflies.Speed = NumberRange.new(3, 8)
	fireflies.SpreadAngle = Vector2.new(180, 180)
	fireflies.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 0.0),
		NumberSequenceKeypoint.new(0.4, 0.35),
		NumberSequenceKeypoint.new(1.0, 0.0),
	})
	fireflies.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0.0, 1.0),
		NumberSequenceKeypoint.new(0.3, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.20),
		NumberSequenceKeypoint.new(1.0, 1.0),
	})
	fireflies.LightEmission = 0.8
	fireflies.Color = ColorSequence.new(Color3.fromRGB(110, 255, 200)) -- Soft Jade Mint
	fireflies.Parent = fireflyAtt

	-- Real-time wind tracking loop
	RunService.RenderStepped:Connect(function()
		local camCF = camera.CFrame
		anchor.CFrame = camCF * CFrame.new(0, 0, -25) -- Placed 25 studs ahead of camera

		local currentWind = Workspace.GlobalWind
		local windMag = currentWind.Magnitude

		-- 🚀 Modulate Ambient Wind Audio Volume with Global Gusts
		if ambientWindSound then
			local targetVolume = math.clamp(0.25 + (windMag * 0.015), 0.25, 0.60)
			ambientWindSound.Volume = ambientWindSound.Volume + (targetVolume - ambientWindSound.Volume) * 0.05
		end

		if windMag > 1 then
			windAtt.CFrame = CFrame.lookAt(Vector3.zero, currentWind.Unit)
			windRibbons.Speed = NumberRange.new(windMag * 0.9, windMag * 1.4)
			windRibbons.Rate = math.clamp(windMag * 0.6, 6, 24)
		else
			windRibbons.Rate = 3
		end

		-- Switch firefly colors at night vs day
		local clockTime = Lighting.ClockTime
		local isNight = (clockTime < 6.0 or clockTime >= 19.5)
		if isNight then
			fireflies.Rate = 18
			fireflies.Color = ColorSequence.new(Color3.fromRGB(140, 220, 255)) -- Glowing Moonlit Cyan
		else
			fireflies.Rate = 8
			fireflies.Color = ColorSequence.new(Color3.fromRGB(245, 235, 180)) -- Sunlight Pollen Spores
		end
	end)
end

function WindEnvironmentController.Init()
	WindEnvironmentController.ScanEnvironment()
	SetupAtmosphericWind()
	SetupAmbientWindAudio()

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.wait(0.2)
			local partName = descendant.Name:lower()
			for _, pattern in ipairs(FOLIAGE_PATTERNS) do
				if partName:find(pattern) then
					local pos = descendant.Position
					local phase = (pos.X * 0.08) + (pos.Z * 0.08)
					local category = CategorizePlant(descendant, partName)

					table.insert(foliageList, {
						Part = descendant,
						OriginalCFrame = descendant.CFrame,
						PhaseOffset = phase,
						PlantCategory = category,
					})
					break
				end
			end
		end
	end)

	-- Centralized Render Loop for Organic Gusting Wind Foliage Sway
	local clock = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		clock += deltaTime * 1.8
		local camPos = camera.CFrame.Position

		local noiseValue = math.noise(clock * 0.25, 0, 0)
		local gustEnvelope = math.clamp(noiseValue * 2.2 + math.sin(clock * 0.8) * 0.4, 0.1, 1.8)

		for _, data in ipairs(foliageList) do
			local part = data.Part
			if part and part.Parent then
				local dist = (part.Position - camPos).Magnitude
				if dist <= MAX_CULL_DISTANCE then
					local phase = clock + data.PhaseOffset
					local category = data.PlantCategory

					local maxSwayAngle = 0.065
					local frequencyMult = 1.0

					if category == "Bamboo" then
						maxSwayAngle = 0.140
						frequencyMult = 2.2
					elseif category == "Grass" then
						maxSwayAngle = 0.110
						frequencyMult = 3.2
					elseif category == "SmallTree" then
						maxSwayAngle = 0.095
						frequencyMult = 1.5
					else
						maxSwayAngle = 0.065
						frequencyMult = 1.0
					end

					local wave = math.sin(phase * frequencyMult) * gustEnvelope
					local sway = wave * maxSwayAngle
					local swayRotation = CFrame.Angles(sway, 0, sway * 0.4)

					part.CFrame = data.OriginalCFrame * swayRotation
				end
			end
		end
	end)

	print("[ASCEND] WindEnvironmentController Initialized (Ambient Wind Audio & Wind Ribbons Active).")
end

return WindEnvironmentController