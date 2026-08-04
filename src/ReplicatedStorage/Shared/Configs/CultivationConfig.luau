--!strict
--[[
    CultivationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
    Configuration for cultivation realms, 9 orders per realm, HP/Qi scaling,
    and server-authoritative skill costs.
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
	MaxQi: number,
	GatherRate: number,
	RegenMultiplier: number,
	BaseHealth: number,
	DamageMultiplier: number,
	AuraColor: Color3,
	Tribulation: TribulationConfig,
}

local CultivationConfig = {}

-- Server skill cost definitions required by CombatStateManager
CultivationConfig.SkillCosts = {
	M1 = 0,
	F = 10,
	Shift = 25,
	Q = 50,
	E = 100,
	R = 250,
}

CultivationConfig.QiCondensation = {
	Name = "Qi Condensation",
	Tier = 1,
	MaxQi = 100000,
	GatherRate = 120,
	RegenMultiplier = 3.5,
	BaseHealth = 500,
	DamageMultiplier = 1.0,
	AuraColor = Color3.fromRGB(0, 220, 255),
	Tribulation = {
		StrikeCount = 3,
		DamagePerStrike = 120,
		TelegraphTime = 1.5,
		StrikeInterval = 2.5,
		AuraColor = Color3.fromRGB(0, 200, 255),
	},
}

CultivationConfig.FoundationEstablishment = {
	Name = "Foundation Establishment",
	Tier = 2,
	MaxQi = 5000000,
	GatherRate = 1500,
	RegenMultiplier = 3.5,
	BaseHealth = 5000,
	DamageMultiplier = 1.3,
	AuraColor = Color3.fromRGB(50, 255, 120),
	Tribulation = {
		StrikeCount = 4,
		DamagePerStrike = 1250,
		TelegraphTime = 1.4,
		StrikeInterval = 2.2,
		AuraColor = Color3.fromRGB(50, 255, 120),
	},
}

CultivationConfig.GoldenCore = {
	Name = "Golden Core",
	Tier = 3,
	MaxQi = 250000000,
	GatherRate = 45000,
	RegenMultiplier = 3.5,
	BaseHealth = 50000,
	DamageMultiplier = 1.75,
	AuraColor = Color3.fromRGB(255, 215, 0),
	Tribulation = {
		StrikeCount = 5,
		DamagePerStrike = 12500,
		TelegraphTime = 1.2,
		StrikeInterval = 2.0,
		AuraColor = Color3.fromRGB(255, 215, 0),
	},
}

CultivationConfig.NascentSoul = {
	Name = "Nascent Soul",
	Tier = 4,
	MaxQi = 8000000000,
	GatherRate = 1200000,
	RegenMultiplier = 3.5,
	BaseHealth = 500000,
	DamageMultiplier = 2.5,
	AuraColor = Color3.fromRGB(180, 50, 255),
	Tribulation = {
		StrikeCount = 6,
		DamagePerStrike = 125000,
		TelegraphTime = 1.0,
		StrikeInterval = 1.8,
		AuraColor = Color3.fromRGB(180, 50, 255),
	},
}

CultivationConfig.HeavenlyTribulation = {
	Name = "Spirit Severing",
	Tier = 5,
	MaxQi = 50000000000,
	GatherRate = 80000000,
	RegenMultiplier = 3.5,
	BaseHealth = 5000000,
	DamageMultiplier = 4.0,
	AuraColor = Color3.fromRGB(255, 40, 40),
	Tribulation = {
		StrikeCount = 7,
		DamagePerStrike = 1250000,
		TelegraphTime = 0.9,
		StrikeInterval = 1.5,
		AuraColor = Color3.fromRGB(255, 40, 40),
	},
}

function CultivationConfig.GetOrderMaxQi(realm: RealmTier, order: number): number
	local baseConfig = CultivationConfig[realm]
	if not baseConfig then return 10000 end

	local clampedOrder = math.clamp(order or 1, 1, 9)
	local orderRatio = math.pow(1.38, clampedOrder - 1) / math.pow(1.38, 8)
	return math.floor(baseConfig.MaxQi * orderRatio)
end

function CultivationConfig.GetOrderMaxHealth(realm: RealmTier, order: number): number
	local baseConfig = CultivationConfig[realm]
	if not baseConfig then return 500 end

	local clampedOrder = math.clamp(order or 1, 1, 9)
	local orderHealthRatio = 1.0 + ((clampedOrder - 1) * 0.4)
	return math.floor(baseConfig.BaseHealth * orderHealthRatio)
end

function CultivationConfig.FormatNumber(n: number): string
	if n >= 1000000000000 then
		return string.format("%.2fT", n / 1000000000000)
	elseif n >= 1000000000 then
		return string.format("%.2fB", n / 1000000000)
	elseif n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	else
		return tostring(math.floor(n))
	end
end

return CultivationConfig