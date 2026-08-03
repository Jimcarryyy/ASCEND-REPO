--!strict
--[[
    CultivationConfig.luau
    Configuration data for cultivation realms, qi capacity, gather rates,
    health multipliers, and breakthrough thresholds.
]]

export type RealmTier = "QiCondensation" | "FoundationEstablishment" | "GoldenCore" | "NascentSoul" | "HeavenlyTribulation"

export type RealmData = {
	Name: string,
	Tier: number,
	MaxQi: number,
	GatherRate: number, -- Qi absorbed per second during meditation
	HealthMultiplier: number,
	AuraColor: Color3,
}

local CultivationConfig: { [RealmTier]: RealmData } = {
	QiCondensation = {
		Name = "Qi Condensation",
		Tier = 1,
		MaxQi = 100,
		GatherRate = 15,
		HealthMultiplier = 1.0,
		AuraColor = Color3.fromRGB(0, 220, 255), -- Cyan Qi
	},
	FoundationEstablishment = {
		Name = "Foundation Establishment",
		Tier = 2,
		MaxQi = 250,
		GatherRate = 30,
		HealthMultiplier = 1.5,
		AuraColor = Color3.fromRGB(50, 255, 120), -- Emerald Jade Qi
	},
	GoldenCore = {
		Name = "Golden Core",
		Tier = 3,
		MaxQi = 500,
		GatherRate = 50,
		HealthMultiplier = 2.2,
		AuraColor = Color3.fromRGB(255, 215, 0), -- Imperial Gold Qi
	},
	NascentSoul = {
		Name = "Nascent Soul",
		Tier = 4,
		MaxQi = 1000,
		GatherRate = 85,
		HealthMultiplier = 3.5,
		AuraColor = Color3.fromRGB(180, 50, 255), -- Spirit Purple Qi
	},
	HeavenlyTribulation = {
		Name = "Heavenly Tribulation",
		Tier = 5,
		MaxQi = 2500,
		GatherRate = 120,
		HealthMultiplier = 5.0,
		AuraColor = Color3.fromRGB(255, 30, 30), -- Crimson Tribulation Qi
	},
}

return CultivationConfig