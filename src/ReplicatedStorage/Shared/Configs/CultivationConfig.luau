--!strict
--[[
    CultivationConfig.luau
    Configuration data for cultivation realms, qi capacity, gather rates,
    health & damage multipliers, breakthrough thresholds, and skill Qi costs.
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
	GatherRate: number,         -- Qi gained per second during deep cultivation
	RegenMultiplier: number,    -- Faster multiplier when recovering spent Qi (CurrentQi < MaxQi)
	HealthMultiplier: number,
	DamageMultiplier: number,   -- Realm attack power scaling
	AuraColor: Color3,
	Tribulation: TribulationConfig,
}

export type SkillQiCost = {
	[string]: number,
}

local CultivationConfig: { [RealmTier]: RealmData } & { SkillCosts: SkillQiCost } = {
	SkillCosts = {
		M1 = 0,
		F = 5,
		Shift = 10,
		Q = 15,
		E = 25,
		R = 45,
	},

	QiCondensation = {
		Name = "Qi Condensation",
		Tier = 1,
		MaxQi = 100,
		GatherRate = 15,
		RegenMultiplier = 3.0,
		HealthMultiplier = 1.0,
		DamageMultiplier = 1.0,
		AuraColor = Color3.fromRGB(0, 220, 255),
		Tribulation = {
			StrikeCount = 3,
			DamagePerStrike = 25,
			TelegraphTime = 1.5,
			StrikeInterval = 2.5,
			AuraColor = Color3.fromRGB(0, 200, 255),
		},
	},
	FoundationEstablishment = {
		Name = "Foundation Establishment",
		Tier = 2,
		MaxQi = 250,
		GatherRate = 30,
		RegenMultiplier = 3.0,
		HealthMultiplier = 1.5,
		DamageMultiplier = 1.3,
		AuraColor = Color3.fromRGB(50, 255, 120),
		Tribulation = {
			StrikeCount = 4,
			DamagePerStrike = 35,
			TelegraphTime = 1.4,
			StrikeInterval = 2.2,
			AuraColor = Color3.fromRGB(50, 255, 120),
		},
	},
	GoldenCore = {
		Name = "Golden Core",
		Tier = 3,
		MaxQi = 500,
		GatherRate = 50,
		RegenMultiplier = 3.0,
		HealthMultiplier = 2.2,
		DamageMultiplier = 1.75,
		AuraColor = Color3.fromRGB(255, 215, 0),
		Tribulation = {
			StrikeCount = 5,
			DamagePerStrike = 50,
			TelegraphTime = 1.2,
			StrikeInterval = 2.0,
			AuraColor = Color3.fromRGB(255, 215, 0),
		},
	},
	NascentSoul = {
		Name = "Nascent Soul",
		Tier = 4,
		MaxQi = 1000,
		GatherRate = 85,
		RegenMultiplier = 3.0,
		HealthMultiplier = 3.5,
		DamageMultiplier = 2.5,
		AuraColor = Color3.fromRGB(180, 50, 255),
		Tribulation = {
			StrikeCount = 6,
			DamagePerStrike = 75,
			TelegraphTime = 1.0,
			StrikeInterval = 1.8,
			AuraColor = Color3.fromRGB(180, 50, 255),
		},
	},
	HeavenlyTribulation = {
		Name = "Heavenly Tribulation",
		Tier = 5,
		MaxQi = 2500,
		GatherRate = 120,
		RegenMultiplier = 3.0,
		HealthMultiplier = 5.0,
		DamageMultiplier = 4.0,
		AuraColor = Color3.fromRGB(255, 30, 30),
		Tribulation = {
			StrikeCount = 7,
			DamagePerStrike = 110,
			TelegraphTime = 0.9,
			StrikeInterval = 1.5,
			AuraColor = Color3.fromRGB(255, 30, 30),
		},
	},
}

return CultivationConfig