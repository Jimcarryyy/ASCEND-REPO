--!strict
--[[
    CultivationConfig.luau
    Configuration data for cultivation realms, qi capacity, gather rates,
    health multipliers, breakthrough thresholds, and Heavenly Tribulation boss mechanics.
]]

export type RealmTier = "QiCondensation" | "FoundationEstablishment" | "GoldenCore" | "NascentSoul" | "HeavenlyTribulation"

export type TribulationConfig = {
	StrikeCount: number,        -- Total lightning strikes to endure
	DamagePerStrike: number,    -- Base damage per lightning strike
	TelegraphTime: number,      -- Seconds of ground warning telegraph before strike
	StrikeInterval: number,     -- Delay between consecutive strikes
	AuraColor: Color3,          -- Tribulation storm glow color
}

export type RealmData = {
	Name: string,
	Tier: number,
	MaxQi: number,
	GatherRate: number, -- Qi absorbed per second during meditation
	HealthMultiplier: number,
	AuraColor: Color3,
	Tribulation: TribulationConfig,
}

local CultivationConfig: { [RealmTier]: RealmData } = {
	QiCondensation = {
		Name = "Qi Condensation",
		Tier = 1,
		MaxQi = 100,
		GatherRate = 15,
		HealthMultiplier = 1.0,
		AuraColor = Color3.fromRGB(0, 220, 255), -- Cyan Qi
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
		HealthMultiplier = 1.5,
		AuraColor = Color3.fromRGB(50, 255, 120), -- Emerald Jade Qi
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
		HealthMultiplier = 2.2,
		AuraColor = Color3.fromRGB(255, 215, 0), -- Imperial Gold Qi
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
		HealthMultiplier = 3.5,
		AuraColor = Color3.fromRGB(180, 50, 255), -- Spirit Purple Qi
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
		HealthMultiplier = 5.0,
		AuraColor = Color3.fromRGB(255, 30, 30), -- Crimson Tribulation Qi
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