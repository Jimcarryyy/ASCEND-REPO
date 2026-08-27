--!strict
--[[
    EnvironmentTimeManager.luau
    Location: src/ServerScriptService/Server/World/EnvironmentTimeManager.luau
    Server-authoritative time cycle and dynamic lighting engine tailored for a
    Murim / Xianxia Sword-Cultivation atmosphere (12-Minute Cycle).

    Design intent: cooler, muted, mist-shrouded palette (temple ink-wash) instead
    of a bright pastel fantasy look, plus real fog + a Sky instance to hide the
    map's exposed edges/void at a distance rather than exposing them.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local EnvironmentTimeManager = {}

-- CONFIGURATION (Standard Roblox Day/Night Cycle Duration: 12 Minutes)
local MINUTES_PER_DAY_CYCLE = 12
local STARTING_CLOCK_TIME = 7.0 -- Misty dawn on server start, fits the murim mood better than midday

-- Fog tuning: these distances are a starting point, NOT measured against your actual
-- map scale (that lives in the .rbxl place, not in source-controlled scripts, so it
-- can't be verified from the repo). Tune FogStart/FogEnd in Studio against how far
-- your map edges actually sit from typical player positions.
local FOG_START_STUDS = 150
local FOG_END_STUDS = 700

local atmosphere: Atmosphere
local bloom: BloomEffect
local sunRays: SunRaysEffect
local colorCorrection: ColorCorrectionEffect
local depthOfField: DepthOfFieldEffect
local sky: Sky

local function GetOrCreate<T>(className: string, name: string): Instance
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

	-- Classic fog: the direct fix for "can see outside the map." Distance fog
	-- fades geometry to FogColor before the player's view reaches the exposed edges.
	Lighting.FogStart = FOG_START_STUDS
	Lighting.FogEnd = FOG_END_STUDS
	Lighting.FogColor = Color3.fromRGB(150, 160, 170)

	-- Sky instance so the horizon past the fog is a stylized sky, not Studio's default void.
	sky = GetOrCreate("Sky", "MurimSky") :: Sky
	sky.CelestialBodiesShown = true
	sky.StarCount = 3000
	sky.SunAngularSize = 11
	sky.MoonAngularSize = 12
	-- NOTE: no custom SkyboxBk/Dn/Ft/Lf/Rt/Up texture ids are set here — doing so
	-- would require real uploaded skybox images, which don't exist in this repo.
	-- A painted mountain-silhouette skybox would be the strongest single upgrade
	-- to this scene; flagging it as a follow-up rather than guessing asset ids.

	atmosphere = GetOrCreate("Atmosphere", "MurimAtmosphere") :: Atmosphere
	atmosphere.Density = 0.35
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(150, 165, 175)
	atmosphere.Decay = Color3.fromRGB(120, 110, 130)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 2.4

	bloom = GetOrCreate("BloomEffect", "MurimBloom") :: BloomEffect
	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 1.1

	sunRays = GetOrCreate("SunRaysEffect", "MurimSunRays") :: SunRaysEffect
	sunRays.Intensity = 0.2
	sunRays.Spread = 0.75

	-- Ink-wash color grading: desaturated, slightly cool, higher contrast so the
	-- scene reads as a deliberate painterly palette rather than default-bright Studio colors.
	colorCorrection = GetOrCreate("ColorCorrectionEffect", "MurimColorGrading") :: ColorCorrectionEffect
	colorCorrection.Saturation = -0.35
	colorCorrection.Contrast = 0.12
	colorCorrection.Brightness = -0.02
	colorCorrection.TintColor = Color3.fromRGB(225, 235, 240)

	-- Subtle depth blur helps distant fog-obscured geometry read as atmospheric
	-- rather than as an obvious pop-in/fog wall.
	depthOfField = GetOrCreate("DepthOfFieldEffect", "MurimDepthOfField") :: DepthOfFieldEffect
	depthOfField.FarIntensity = 0.15
	depthOfField.FocusDistance = 60
	depthOfField.InFocusRadius = 40
	depthOfField.NearIntensity = 0

	-- Time Progression Loop (12-Minute Cycle)
	local secondsPerCycle = MINUTES_PER_DAY_CYCLE * 60
	local clockTimeIncrementPerSecond = 24 / secondsPerCycle

	RunService.Heartbeat:Connect(function(deltaTime: number)
		local newTime = (Lighting.ClockTime + (clockTimeIncrementPerSecond * deltaTime)) % 24
		Lighting.ClockTime = newTime
		EnvironmentTimeManager.UpdateStylizedLighting(newTime)
	end)

	print(string.format("[ASCEND] EnvironmentTimeManager Engine Initialized (Murim Atmosphere, %d-Min Day Cycle, Fog-Masked Horizon).", MINUTES_PER_DAY_CYCLE))
end

function EnvironmentTimeManager.UpdateStylizedLighting(clockTime: number)
	if clockTime >= 6.0 and clockTime < 8.0 then
		-- MISTY DAWN (06:00 - 08:00) — pale, cool, heavy ground mist
		local alpha = (clockTime - 6.0) / 2.0
		Lighting.Brightness = math.clamp(1.0 + alpha * 0.6, 1.0, 1.6)
		Lighting.OutdoorAmbient = Color3.fromRGB(140, 150, 165):Lerp(Color3.fromRGB(165, 175, 185), alpha)
		Lighting.Ambient = Color3.fromRGB(85, 95, 115):Lerp(Color3.fromRGB(110, 120, 135), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(210, 200, 200):Lerp(Color3.fromRGB(220, 215, 210), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(140, 130, 150):Lerp(Color3.fromRGB(160, 165, 175), alpha)
		atmosphere.Density = math.clamp(0.55 - alpha * 0.15, 0.40, 0.55)
		atmosphere.Color = Color3.fromRGB(170, 175, 180):Lerp(Color3.fromRGB(150, 165, 175), alpha)
		Lighting.FogStart = math.clamp(90 - alpha * 40, 50, 90)
		Lighting.FogEnd = math.clamp(500 - alpha * 100, 400, 500)
		Lighting.FogColor = Color3.fromRGB(175, 180, 185)

	elseif clockTime >= 8.0 and clockTime < 16.5 then
		-- OVERCAST DAY (08:00 - 16:30) — muted daylight, still hazy, never bright/pastel
		Lighting.Brightness = 1.7
		Lighting.OutdoorAmbient = Color3.fromRGB(165, 175, 185)
		Lighting.Ambient = Color3.fromRGB(110, 120, 135)
		Lighting.ColorShift_Top = Color3.fromRGB(220, 215, 210)
		Lighting.ColorShift_Bottom = Color3.fromRGB(160, 165, 175)
		atmosphere.Density = 0.35
		atmosphere.Color = Color3.fromRGB(150, 165, 175)
		Lighting.FogStart = FOG_START_STUDS
		Lighting.FogEnd = FOG_END_STUDS
		Lighting.FogColor = Color3.fromRGB(150, 160, 170)

	elseif clockTime >= 16.5 and clockTime < 19.0 then
		-- DUSK (16:30 - 19:00) — deep golden-grey twilight, temple-lantern warmth without going pastel
		local alpha = (clockTime - 16.5) / 2.5
		Lighting.Brightness = math.clamp(1.7 - alpha * 0.9, 0.8, 1.7)
		Lighting.OutdoorAmbient = Color3.fromRGB(165, 175, 185):Lerp(Color3.fromRGB(95, 80, 95), alpha)
		Lighting.Ambient = Color3.fromRGB(110, 120, 135):Lerp(Color3.fromRGB(55, 45, 65), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(220, 215, 210):Lerp(Color3.fromRGB(200, 130, 80), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(160, 165, 175):Lerp(Color3.fromRGB(110, 75, 120), alpha)
		atmosphere.Density = math.clamp(0.35 + alpha * 0.25, 0.35, 0.60)
		atmosphere.Color = Color3.fromRGB(150, 165, 175):Lerp(Color3.fromRGB(190, 130, 100), alpha)
		Lighting.FogStart = math.clamp(FOG_START_STUDS - alpha * 60, 90, FOG_START_STUDS)
		Lighting.FogEnd = math.clamp(FOG_END_STUDS - alpha * 150, 550, FOG_END_STUDS)
		Lighting.FogColor = Color3.fromRGB(150, 160, 170):Lerp(Color3.fromRGB(140, 110, 120), alpha)

	else
		-- MOONLIT NIGHT (19:00 - 06:00) — deep blue-grey, faint mist glow, sword-cultivator-at-night mood
		Lighting.Brightness = 0.75
		Lighting.OutdoorAmbient = Color3.fromRGB(50, 60, 85)
		Lighting.Ambient = Color3.fromRGB(35, 40, 60)
		Lighting.ColorShift_Top = Color3.fromRGB(90, 110, 160)
		Lighting.ColorShift_Bottom = Color3.fromRGB(35, 40, 65)
		atmosphere.Density = 0.50
		atmosphere.Color = Color3.fromRGB(45, 55, 85)
		Lighting.FogStart = 80
		Lighting.FogEnd = 450
		Lighting.FogColor = Color3.fromRGB(30, 35, 55)
	end
end

return EnvironmentTimeManager