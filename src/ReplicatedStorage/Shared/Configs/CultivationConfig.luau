--!strict
--[[
    CultivationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
    Normalized RPG stat progression curve (100 -> 10,000 Max HP/Qi across 5 Realms / 45 Orders).
]]

export type RealmTier = "QiCondensation" | "FoundationEstablishment" | "GoldenCore" | "NascentSoul" | "HeavenlyTribulation"

export type TribulationConfig = {
	StrikeCount: number,
	DamagePerStrike: number,
	TelegraphTime: number,
	StrikeInterval: number,
	AuraColor: Color3,
}

export type RealmData = {
	Name: string,
	Tier: number,
	MinQi: number,
	MaxQi: number,
	MinHP: number,
	MaxHP: number,
	GatherRate: number,
	RegenMultiplier: number,
	DamageMultiplier: number,
	AuraColor: Color3,
	Tribulation: TribulationConfig,
}

local CultivationConfig = {}

-- Normalized skill Qi costs tuned for the 100 - 10,000 Qi pool
CultivationConfig.SkillCosts = {
	M1 = 0,
	F = 5,
	Shift = 10,
	Q = 15,
	E = 25,
	R = 45,
}

CultivationConfig.QiCondensation = {
	Name = "Qi Condensation",
	Tier = 1,
	MinQi = 100,
	MaxQi = 300,
	MinHP = 100,
	MaxHP = 300,
	GatherRate = 2,
	RegenMultiplier = 1.0,
	DamageMultiplier = 1.0,
	AuraColor = Color3.fromRGB(0, 220, 255),
	Tribulation = {
		StrikeCount = 3,
		DamagePerStrike = 30,
		TelegraphTime = 1.5,
		StrikeInterval = 2.5,
		AuraColor = Color3.fromRGB(0, 200, 255),
	},
}

CultivationConfig.FoundationEstablishment = {
	Name = "Foundation Establishment",
	Tier = 2,
	MinQi = 300,
	MaxQi = 800,
	MinHP = 300,
	MaxHP = 800,
	GatherRate = 5,
	RegenMultiplier = 1.2,
	DamageMultiplier = 1.3,
	AuraColor = Color3.fromRGB(50, 255, 120),
	Tribulation = {
		StrikeCount = 4,
		DamagePerStrike = 80,
		TelegraphTime = 1.4,
		StrikeInterval = 2.2,
		AuraColor = Color3.fromRGB(50, 255, 120),
	},
}

CultivationConfig.GoldenCore = {
	Name = "Golden Core",
	Tier = 3,
	MinQi = 800,
	MaxQi = 2000,
	MinHP = 800,
	MaxHP = 2000,
	GatherRate = 12,
	RegenMultiplier = 1.5,
	DamageMultiplier = 1.75,
	AuraColor = Color3.fromRGB(255, 215, 0),
	Tribulation = {
		StrikeCount = 5,
		DamagePerStrike = 200,
		TelegraphTime = 1.2,
		StrikeInterval = 2.0,
		AuraColor = Color3.fromRGB(255, 215, 0),
	},
}

CultivationConfig.NascentSoul = {
	Name = "Nascent Soul",
	Tier = 4,
	MinQi = 2000,
	MaxQi = 5000,
	MinHP = 2000,
	MaxHP = 5000,
	GatherRate = 25,
	RegenMultiplier = 2.0,
	DamageMultiplier = 2.5,
	AuraColor = Color3.fromRGB(180, 50, 255),
	Tribulation = {
		StrikeCount = 6,
		DamagePerStrike = 500,
		TelegraphTime = 1.0,
		StrikeInterval = 1.8,
		AuraColor = Color3.fromRGB(180, 50, 255),
	},
}

CultivationConfig.HeavenlyTribulation = {
	Name = "Spirit Severing",
	Tier = 5,
	MinQi = 5000,
	MaxQi = 10000,
	MinHP = 5000,
	MaxHP = 10000,
	GatherRate = 50,
	RegenMultiplier = 3.0,
	DamageMultiplier = 4.0,
	AuraColor = Color3.fromRGB(255, 40, 40),
	Tribulation = {
		StrikeCount = 7,
		DamagePerStrike = 1200,
		TelegraphTime = 0.9,
		StrikeInterval = 1.5,
		AuraColor = Color3.fromRGB(255, 40, 40),
	},
}

function CultivationConfig.GetOrderMaxQi(realm: RealmTier, order: number): number
	local baseConfig = CultivationConfig[realm] :: RealmData?
	if not baseConfig then return 100 end

	local clampedOrder = math.clamp(order or 1, 1, 9)
	local progress = (clampedOrder - 1) / 8
	return math.floor(baseConfig.MinQi + (baseConfig.MaxQi - baseConfig.MinQi) * progress)
end

function CultivationConfig.GetOrderMaxHealth(realm: RealmTier, order: number): number
	local baseConfig = CultivationConfig[realm] :: RealmData?
	if not baseConfig then return 100 end

	local clampedOrder = math.clamp(order or 1, 1, 9)
	local progress = (clampedOrder - 1) / 8
	return math.floor(baseConfig.MinHP + (baseConfig.MaxHP - baseConfig.MinHP) * progress)
end

function CultivationConfig.FormatNumber(n: number): string
	if n >= 1000000 then
		return string.format("%.1fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(math.floor(n))
	end
end

return CultivationConfig