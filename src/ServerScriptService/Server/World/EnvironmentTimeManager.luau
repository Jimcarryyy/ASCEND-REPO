--!strict
--[[
    EnvironmentTimeManager.luau
    Location: src/ServerScriptService/Server/World/EnvironmentTimeManager.luau
    Server-authoritative environmental lighting & dynamic wind engine for ASCEND.
    - 24-Minute Weighted Cycle: 75% Bright Day & Dusk (18 mins) / 25% Celestial Night (6 mins)
    - High-Visibility "Celestial Moonlit Sapphire" Night (Zero pitch-black shadows)
    - Authoritative workspace.GlobalWind simulation (Powers wind lines & plant sways)
]]

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local EnvironmentTimeManager = {}

local MINUTES_PER_DAY_CYCLE = 24
local STARTING_CLOCK_TIME = 13.0 -- Start at clear, vibrant midday

-- Distant Fog Bounds: Never drowns near or mid-range terrain
local FOG_START_STUDS = 800
local FOG_END_STUDS = 2200

local atmosphere: Atmosphere
local bloom: BloomEffect
local sunRays: SunRaysEffect
local colorCorrection: ColorCorrectionEffect
local sky: Sky

local function GetOrCreate(className: string, name: string): Instance
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	created.Parent = Lighting
	return created
end

function EnvironmentTimeManager.Init()
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.2
	Lighting.ClockTime = STARTING_CLOCK_TIME

	-- Initial Distant Fog Setup
	Lighting.FogStart = FOG_START_STUDS
	Lighting.FogEnd = FOG_END_STUDS
	Lighting.FogColor = Color3.fromRGB(190, 215, 235)

	sky = GetOrCreate("Sky", "MurimSky") :: Sky
	sky.CelestialBodiesShown = true
	sky.StarCount = 4500
	sky.SunAngularSize = 11
	sky.MoonAngularSize = 14

	atmosphere = GetOrCreate("Atmosphere", "MurimAtmosphere") :: Atmosphere
	atmosphere.Density = 0.16
	atmosphere.Offset = 0.10
	atmosphere.Color = Color3.fromRGB(195, 220, 240)
	atmosphere.Decay = Color3.fromRGB(220, 210, 200)
	atmosphere.Glare = 0.12
	atmosphere.Haze = 0.2

	bloom = GetOrCreate("BloomEffect", "MurimBloom") :: BloomEffect
	bloom.Intensity = 0.35
	bloom.Size = 18
	bloom.Threshold = 1.1

	sunRays = GetOrCreate("SunRaysEffect", "MurimSunRays") :: SunRaysEffect
	sunRays.Intensity = 0.18
	sunRays.Spread = 0.70

	colorCorrection = GetOrCreate("ColorCorrectionEffect", "MurimColorGrading") :: ColorCorrectionEffect
	colorCorrection.Saturation = 0.08
	colorCorrection.Contrast = 0.08
	colorCorrection.Brightness = 0.00
	colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

	local existingDof = Lighting:FindFirstChild("MurimDepthOfField")
	if existingDof then existingDof:Destroy() end

	-- 🚀 Authoritative Global Wind Simulation (Simulates mountain gusts)
	task.spawn(function()
		local windClock = 0
		while true do
			windClock += 0.5
			local noiseX = math.noise(windClock * 0.08, 0, 0)
			local noiseZ = math.noise(0, windClock * 0.08, 0)
			local gustSpeed = 14 + (math.clamp(math.sin(windClock * 0.25) * 12 + noiseX * 10, -4, 18))
			local windDir = Vector3.new(0.8 + noiseX * 0.3, 0, 0.5 + noiseZ * 0.3).Unit
			Workspace.GlobalWind = windDir * gustSpeed
			task.wait(0.5)
		end
	end)

	-- Time Progression Loop (Weighted 24-Minute Cycle)
	local secondsPerCycle = MINUTES_PER_DAY_CYCLE * 60
	local baseClockRate = 24 / secondsPerCycle

	RunService.Heartbeat:Connect(function(deltaTime: number)
		local current = Lighting.ClockTime
		-- Weighted progression: Day runs at 0.75x speed (longer), Night runs at 1.4x speed (quicker)
		local isDay = (current >= 6.0 and current < 19.5)
		local rateMultiplier = if isDay then 0.78 else 1.45
		local newTime = (current + (baseClockRate * rateMultiplier * deltaTime)) % 24

		Lighting.ClockTime = newTime
		EnvironmentTimeManager.UpdateStylizedLighting(newTime)
	end)

	print(string.format("[ASCEND] EnvironmentTimeManager Initialized (%d-Min Weighted Cycle, High-Vis Night & Global Wind Active).", MINUTES_PER_DAY_CYCLE))
end

function EnvironmentTimeManager.UpdateStylizedLighting(clockTime: number)
	if clockTime >= 6.0 and clockTime < 8.5 then
		-- DAWN: Fresh morning sun
		local alpha = (clockTime - 6.0) / 2.5
		Lighting.Brightness = 2.0 + (alpha * 0.5)
		Lighting.OutdoorAmbient = Color3.fromRGB(160, 175, 195):Lerp(Color3.fromRGB(190, 200, 215), alpha)
		Lighting.Ambient = Color3.fromRGB(115, 125, 140):Lerp(Color3.fromRGB(140, 150, 165), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 235, 215):Lerp(Color3.fromRGB(255, 250, 240), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(165, 160, 170)
		atmosphere.Density = 0.18
		atmosphere.Haze = 0.25
		Lighting.FogStart = FOG_START_STUDS
		Lighting.FogEnd = FOG_END_STUDS
		Lighting.FogColor = Color3.fromRGB(215, 225, 235)
		colorCorrection.Saturation = 0.08
		colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

	elseif clockTime >= 8.5 and clockTime < 16.5 then
		-- MIDDAY: Crisp, bright stylized daylight
		Lighting.Brightness = 2.6
		Lighting.OutdoorAmbient = Color3.fromRGB(195, 205, 218)
		Lighting.Ambient = Color3.fromRGB(145, 155, 168)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 242)
		Lighting.ColorShift_Bottom = Color3.fromRGB(175, 180, 188)
		atmosphere.Density = 0.15
		atmosphere.Haze = 0.18
		Lighting.FogStart = FOG_START_STUDS
		Lighting.FogEnd = FOG_END_STUDS
		Lighting.FogColor = Color3.fromRGB(195, 220, 240)
		colorCorrection.Saturation = 0.10
		colorCorrection.TintColor = Color3.fromRGB(255, 255, 255)

	elseif clockTime >= 16.5 and clockTime < 19.5 then
		-- DUSK: Warm martial golden hour
		local alpha = (clockTime - 16.5) / 3.0
		Lighting.Brightness = 2.6 - (alpha * 0.8)
		Lighting.OutdoorAmbient = Color3.fromRGB(195, 205, 218):Lerp(Color3.fromRGB(160, 130, 130), alpha)
		Lighting.Ambient = Color3.fromRGB(145, 155, 168):Lerp(Color3.fromRGB(110, 85, 95), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 242):Lerp(Color3.fromRGB(255, 175, 100), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(175, 180, 188):Lerp(Color3.fromRGB(150, 100, 130), alpha)
		atmosphere.Density = 0.18
		atmosphere.Haze = 0.35
		Lighting.FogStart = FOG_START_STUDS - 100
		Lighting.FogEnd = FOG_END_STUDS - 200
		Lighting.FogColor = Color3.fromRGB(235, 175, 145)
		colorCorrection.Saturation = 0.12

	else
		-- 🚀 CELESTIAL MOONLIT NIGHT (High Visibility, Zero Pitch-Black Darkness)
		Lighting.Brightness = 1.9 -- High brightness powered by full moon
		Lighting.OutdoorAmbient = Color3.fromRGB(118, 138, 178) -- Luminous blue-gray ambient light
		Lighting.Ambient = Color3.fromRGB(95, 112, 145)
		Lighting.ColorShift_Top = Color3.fromRGB(175, 210, 255) -- Cool celestial moonbeams
		Lighting.ColorShift_Bottom = Color3.fromRGB(75, 88, 115)
		atmosphere.Density = 0.15 -- Clear, crisp atmosphere (no dark fog smog)
		atmosphere.Haze = 0.15
		Lighting.FogStart = 750 -- Pushed far away
		Lighting.FogEnd = 2000
		Lighting.FogColor = Color3.fromRGB(90, 115, 160) -- Glowing night-sky fog
		colorCorrection.Saturation = 0.12 -- Keeps world colorful under moonlight
		colorCorrection.TintColor = Color3.fromRGB(240, 245, 255)
	end
end

return EnvironmentTimeManager