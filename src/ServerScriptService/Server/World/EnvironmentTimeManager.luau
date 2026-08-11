--!strict
--[[
    EnvironmentTimeManager.luau
    Location: src/ServerScriptService/Server/World/EnvironmentTimeManager.luau
    Server-authoritative time cycle and dynamic lighting engine tailored for
    Stylized Hand-Painted Low-Poly Xianxia Fantasy Environments.
    Matches standard Roblox day/night cycle duration (12 Real-World Minutes).
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local EnvironmentTimeManager = {}

-- CONFIGURATION (Standard Roblox Day/Night Cycle Duration: 12 Minutes)
local MINUTES_PER_DAY_CYCLE = 12 -- 12 real-world minutes = 1 full in-game day (1 hour = 30 seconds)
local STARTING_CLOCK_TIME = 14.0 -- Starts at high afternoon

local atmosphere: Atmosphere
local bloom: BloomEffect
local sunRays: SunRaysEffect

function EnvironmentTimeManager.Init()
	-- 1. Configure Lighting Base Properties for Stylized Low-Poly Aesthetics
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.2 -- Soft stylized shadow edges
	Lighting.ClockTime = STARTING_CLOCK_TIME

	-- Ensure Atmosphere instance exists (Tints custom Skybox during night/sunset)
	local existingAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if existingAtmosphere then
		atmosphere = existingAtmosphere
	else
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "StylizedXianxiaAtmosphere"
		atmosphere.Parent = Lighting
	end

	atmosphere.Density = 0.25
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 215, 240)
	atmosphere.Decay = Color3.fromRGB(240, 180, 140)
	atmosphere.Glare = 0.3
	atmosphere.Haze = 1.2

	-- Ensure BloomEffect instance exists
	local existingBloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if existingBloom then
		bloom = existingBloom
	else
		bloom = Instance.new("BloomEffect")
		bloom.Name = "StylizedXianxiaBloom"
		bloom.Parent = Lighting
	end

	bloom.Intensity = 0.4
	bloom.Size = 24
	bloom.Threshold = 0.8

	-- Ensure SunRaysEffect instance exists
	local existingSunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if existingSunRays then
		sunRays = existingSunRays
	else
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "StylizedXianxiaSunRays"
		sunRays.Parent = Lighting
	end

	sunRays.Intensity = 0.15
	sunRays.Spread = 0.6

	-- 2. Time Progression Loop (Standard Roblox 12-Minute Cycle)
	local secondsPerCycle = MINUTES_PER_DAY_CYCLE * 60
	local clockTimeIncrementPerSecond = 24 / secondsPerCycle

	RunService.Heartbeat:Connect(function(deltaTime: number)
		local newTime = (Lighting.ClockTime + (clockTimeIncrementPerSecond * deltaTime)) % 24
		Lighting.ClockTime = newTime
		EnvironmentTimeManager.UpdateStylizedLighting(newTime)
	end)

	print(string.format("[ASCEND] EnvironmentTimeManager Engine Initialized (Standard Roblox %d-Min Day Cycle).", MINUTES_PER_DAY_CYCLE))
end

function EnvironmentTimeManager.UpdateStylizedLighting(clockTime: number)
	-- Determine Time Phase & Interpolate Lighting Parameters
	if clockTime >= 6.0 and clockTime < 8.0 then
		-- DAWN / SUNRISE (06:00 - 08:00)
		local alpha = (clockTime - 6.0) / 2.0
		Lighting.Brightness = math.clamp(1.0 + alpha * 1.2, 1.0, 2.2)
		Lighting.OutdoorAmbient = Color3.fromRGB(100, 110, 150):Lerp(Color3.fromRGB(180, 190, 205), alpha)
		Lighting.Ambient = Color3.fromRGB(60, 65, 90):Lerp(Color3.fromRGB(120, 130, 145), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 180, 120):Lerp(Color3.fromRGB(255, 245, 230), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(180, 150, 210):Lerp(Color3.fromRGB(160, 180, 210), alpha)
		atmosphere.Density = math.clamp(0.50 - alpha * 0.25, 0.25, 0.50)
		atmosphere.Color = Color3.fromRGB(240, 160, 120):Lerp(Color3.fromRGB(190, 215, 240), alpha)

	elseif clockTime >= 8.0 and clockTime < 16.5 then
		-- HIGH NOON / AFTERNOON (08:00 - 16:30)
		Lighting.Brightness = 2.2
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 190, 205)
		Lighting.Ambient = Color3.fromRGB(120, 130, 145)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230)
		Lighting.ColorShift_Bottom = Color3.fromRGB(160, 180, 210)
		atmosphere.Density = 0.25
		atmosphere.Color = Color3.fromRGB(190, 215, 240)

	elseif clockTime >= 16.5 and clockTime < 19.0 then
		-- SUNSET / GOLDEN TWILIGHT (16:30 - 19:00)
		local alpha = (clockTime - 16.5) / 2.5
		Lighting.Brightness = math.clamp(2.2 - alpha * 1.4, 0.8, 2.2)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 190, 205):Lerp(Color3.fromRGB(100, 80, 120), alpha)
		Lighting.Ambient = Color3.fromRGB(120, 130, 145):Lerp(Color3.fromRGB(55, 45, 75), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 245, 230):Lerp(Color3.fromRGB(255, 130, 80), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(160, 180, 210):Lerp(Color3.fromRGB(150, 90, 180), alpha)
		atmosphere.Density = math.clamp(0.25 + alpha * 0.30, 0.25, 0.55)
		atmosphere.Color = Color3.fromRGB(190, 215, 240):Lerp(Color3.fromRGB(255, 140, 100), alpha)

	else
		-- MOONLIT NIGHT (19:00 - 06:00)
		Lighting.Brightness = 0.8
		Lighting.OutdoorAmbient = Color3.fromRGB(50, 60, 95) -- High soft ambient for stylized model readability
		Lighting.Ambient = Color3.fromRGB(35, 40, 65)
		Lighting.ColorShift_Top = Color3.fromRGB(110, 150, 220) -- Soft blue moonlight
		Lighting.ColorShift_Bottom = Color3.fromRGB(30, 40, 70)
		atmosphere.Density = 0.55 -- Increased density tints custom Skybox to deep indigo night
		atmosphere.Color = Color3.fromRGB(40, 50, 95)
	end
end

return EnvironmentTimeManager