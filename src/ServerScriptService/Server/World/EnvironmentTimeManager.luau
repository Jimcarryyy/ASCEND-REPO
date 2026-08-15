--!strict
--[[
    EnvironmentTimeManager.luau
    Location: src/ServerScriptService/Server/World/EnvironmentTimeManager.luau
    Server-authoritative time cycle and dynamic lighting engine tailored for
    Stylized Low-Poly Xianxia Fantasy Environments (12-Minute Cycle).
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local EnvironmentTimeManager = {}

-- CONFIGURATION (Standard Roblox Day/Night Cycle Duration: 12 Minutes)
local MINUTES_PER_DAY_CYCLE = 12
local STARTING_CLOCK_TIME = 14.0

local atmosphere: Atmosphere
local bloom: BloomEffect
local sunRays: SunRaysEffect

function EnvironmentTimeManager.Init()
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.ClockTime = STARTING_CLOCK_TIME

	-- Ensure Atmosphere instance exists
	local existingAtmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if existingAtmosphere then
		atmosphere = existingAtmosphere
	else
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Name = "StylizedXianxiaAtmosphere"
		atmosphere.Parent = Lighting
	end

	atmosphere.Density = 0.22
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(190, 215, 240)
	atmosphere.Decay = Color3.fromRGB(240, 180, 140)
	atmosphere.Glare = 0.35
	atmosphere.Haze = 1.1

	-- Ensure BloomEffect instance exists
	local existingBloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if existingBloom then
		bloom = existingBloom
	else
		bloom = Instance.new("BloomEffect")
		bloom.Name = "StylizedXianxiaBloom"
		bloom.Parent = Lighting
	end

	bloom.Intensity = 0.25
	bloom.Size = 18
	bloom.Threshold = 0.88

	-- Ensure SunRaysEffect instance exists
	local existingSunRays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if existingSunRays then
		sunRays = existingSunRays
	else
		sunRays = Instance.new("SunRaysEffect")
		sunRays.Name = "StylizedXianxiaSunRays"
		sunRays.Parent = Lighting
	end

	sunRays.Intensity = 0.14
	sunRays.Spread = 0.60

	-- Time Progression Loop (12-Minute Cycle)
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
	if clockTime >= 6.0 and clockTime < 8.0 then
		-- DAWN / MORNING (06:00 - 08:00)
		local alpha = (clockTime - 6.0) / 2.0
		Lighting.Brightness = math.clamp(1.2 + alpha * 1.2, 1.2, 2.4)
		Lighting.OutdoorAmbient = Color3.fromRGB(180, 195, 210):Lerp(Color3.fromRGB(220, 225, 230), alpha)
		Lighting.Ambient = Color3.fromRGB(110, 120, 140):Lerp(Color3.fromRGB(160, 165, 175), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 224, 178):Lerp(Color3.fromRGB(255, 250, 235), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(180, 150, 210):Lerp(Color3.fromRGB(200, 215, 230), alpha)
		atmosphere.Density = math.clamp(0.35 - alpha * 0.13, 0.22, 0.35)
		atmosphere.Color = Color3.fromRGB(240, 180, 140):Lerp(Color3.fromRGB(190, 215, 240), alpha)

	elseif clockTime >= 8.0 and clockTime < 16.5 then
		-- NOON / AFTERNOON (08:00 - 16:30)
		Lighting.Brightness = 2.4
		Lighting.OutdoorAmbient = Color3.fromRGB(220, 225, 230)
		Lighting.Ambient = Color3.fromRGB(160, 165, 175)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 235)
		Lighting.ColorShift_Bottom = Color3.fromRGB(200, 215, 230)
		atmosphere.Density = 0.22
		atmosphere.Color = Color3.fromRGB(190, 215, 240)

	elseif clockTime >= 16.5 and clockTime < 19.0 then
		-- SUNSET / TWILIGHT (16:30 - 19:00)
		local alpha = (clockTime - 16.5) / 2.5
		Lighting.Brightness = math.clamp(2.4 - alpha * 1.4, 1.0, 2.4)
		Lighting.OutdoorAmbient = Color3.fromRGB(220, 225, 230):Lerp(Color3.fromRGB(140, 105, 125), alpha)
		Lighting.Ambient = Color3.fromRGB(160, 165, 175):Lerp(Color3.fromRGB(75, 55, 75), alpha)
		Lighting.ColorShift_Top = Color3.fromRGB(255, 250, 235):Lerp(Color3.fromRGB(255, 152, 0), alpha)
		Lighting.ColorShift_Bottom = Color3.fromRGB(200, 215, 230):Lerp(Color3.fromRGB(150, 90, 180), alpha)
		atmosphere.Density = math.clamp(0.22 + alpha * 0.23, 0.22, 0.45)
		atmosphere.Color = Color3.fromRGB(190, 215, 240):Lerp(Color3.fromRGB(255, 152, 0), alpha)

	else
		-- MOONLIT NIGHT (19:00 - 06:00) - Boosted Moonlit Ambient for Foliage Depth
		Lighting.Brightness = 1.0
		Lighting.OutdoorAmbient = Color3.fromRGB(65, 80, 115) -- Clear moonlit visibility
		Lighting.Ambient = Color3.fromRGB(45, 52, 75)
		Lighting.ColorShift_Top = Color3.fromRGB(130, 170, 245)
		Lighting.ColorShift_Bottom = Color3.fromRGB(45, 55, 85)
		atmosphere.Density = 0.40
		atmosphere.Color = Color3.fromRGB(50, 65, 110)
	end
end

return EnvironmentTimeManager