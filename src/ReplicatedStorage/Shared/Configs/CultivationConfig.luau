--!strict
--[[
    CultivationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
    The definitive 10-Realm Cultivation Progression Specification for ASCEND.
    Calibrated Pacing Curve:
    - Tier 1 (Qi Condensation): 15 - 25 minutes active play total (Orders 1 -> 9)
    - Tier 10 (Immortal Ascension): ~50 cumulative active hours
]]

export type RealmTier = 
	"QiCondensation" 
	| "FoundationEstablishment" 
	| "GoldenCore" 
	| "NascentSoul" 
	| "SpiritSevering" 
	| "VoidRefining" 
	| "BodyIntegration" 
	| "Mahayana" 
	| "TribulationTranscending" 
	| "ImmortalAscension"

export type TribulationSpec = {
	StrikeCount: number,
	DamagePerStrike: number,
	StrikeInterval: number,
	TelegraphTime: number,
	AuraColor: Color3,
}

export type RealmDefinition = {
	Name: string,
	Tier: number,
	BaseMaxHealth: number,
	BaseTargetQi: number,
	AuraColor: Color3,
	HealthMultiplier: number,
	DamageMultiplier: number,
	GatherRate: number,
	Tribulation: TribulationSpec,
}

local CultivationConfig = {}

CultivationConfig.ORDER_TARGET_QI_EXPONENT = 1.45
CultivationConfig.ORDER_MAX_HP_INCREMENT = 0.05

CultivationConfig.QiCondensation = {
	Name = "Qi Condensation",
	Tier = 1,
	BaseMaxHealth = 1000,
	BaseTargetQi = 500,
	AuraColor = Color3.fromRGB(180, 240, 255),
	HealthMultiplier = 1.0,
	DamageMultiplier = 1.0,
	GatherRate = 20,
	Tribulation = {
		StrikeCount = 0,
		DamagePerStrike = 0,
		StrikeInterval = 0,
		TelegraphTime = 0,
		AuraColor = Color3.fromRGB(180, 240, 255),
	},
} :: RealmDefinition

CultivationConfig.FoundationEstablishment = {
	Name = "Foundation Establishment",
	Tier = 2,
	BaseMaxHealth = 8000,
	BaseTargetQi = 6000,
	AuraColor = Color3.fromRGB(100, 220, 255),
	HealthMultiplier = 5.0,
	DamageMultiplier = 2.5,
	GatherRate = 95,
	Tribulation = {
		StrikeCount = 3,
		DamagePerStrike = 50,
		StrikeInterval = 1.2,
		TelegraphTime = 1.2,
		AuraColor = Color3.fromRGB(100, 220, 255),
	},
} :: RealmDefinition

CultivationConfig.GoldenCore = {
	Name = "Golden Core",
	Tier = 3,
	BaseMaxHealth = 30000,
	BaseTargetQi = 50000,
	AuraColor = Color3.fromRGB(255, 215, 0),
	HealthMultiplier = 15.0,
	DamageMultiplier = 6.0,
	GatherRate = 220,
	Tribulation = {
		StrikeCount = 4,
		DamagePerStrike = 120,
		StrikeInterval = 1.2,
		TelegraphTime = 1.2,
		AuraColor = Color3.fromRGB(255, 215, 0),
	},
} :: RealmDefinition

CultivationConfig.NascentSoul = {
	Name = "Nascent Soul",
	Tier = 4,
	BaseMaxHealth = 120000,
	BaseTargetQi = 180000,
	AuraColor = Color3.fromRGB(160, 100, 255),
	HealthMultiplier = 40.0,
	DamageMultiplier = 15.0,
	GatherRate = 480,
	Tribulation = {
		StrikeCount = 5,
		DamagePerStrike = 300,
		StrikeInterval = 1.1,
		TelegraphTime = 1.1,
		AuraColor = Color3.fromRGB(160, 100, 255),
	},
} :: RealmDefinition

CultivationConfig.SpiritSevering = {
	Name = "Spirit Severing",
	Tier = 5,
	BaseMaxHealth = 450000,
	BaseTargetQi = 550000,
	AuraColor = Color3.fromRGB(255, 120, 50),
	HealthMultiplier = 100.0,
	DamageMultiplier = 35.0,
	GatherRate = 980,
	Tribulation = {
		StrikeCount = 6,
		DamagePerStrike = 750,
		StrikeInterval = 1.1,
		TelegraphTime = 1.1,
		AuraColor = Color3.fromRGB(255, 120, 50),
	},
} :: RealmDefinition

CultivationConfig.VoidRefining = {
	Name = "Void Refining",
	Tier = 6,
	BaseMaxHealth = 1500000,
	BaseTargetQi = 1500000,
	AuraColor = Color3.fromRGB(50, 80, 255),
	HealthMultiplier = 250.0,
	DamageMultiplier = 80.0,
	GatherRate = 1850,
	Tribulation = {
		StrikeCount = 7,
		DamagePerStrike = 1800,
		StrikeInterval = 1.0,
		TelegraphTime = 1.0,
		AuraColor = Color3.fromRGB(50, 80, 255),
	},
} :: RealmDefinition

CultivationConfig.BodyIntegration = {
	Name = "Body Integration",
	Tier = 7,
	BaseMaxHealth = 4500000,
	BaseTargetQi = 3800000,
	AuraColor = Color3.fromRGB(0, 255, 200),
	HealthMultiplier = 600.0,
	DamageMultiplier = 180.0,
	GatherRate = 3800,
	Tribulation = {
		StrikeCount = 8,
		DamagePerStrike = 4000,
		StrikeInterval = 1.0,
		TelegraphTime = 1.0,
		AuraColor = Color3.fromRGB(0, 255, 200),
	},
} :: RealmDefinition

CultivationConfig.Mahayana = {
	Name = "Mahayana",
	Tier = 8,
	BaseMaxHealth = 12000000,
	BaseTargetQi = 9000000,
	AuraColor = Color3.fromRGB(255, 255, 255),
	HealthMultiplier = 1500.0,
	DamageMultiplier = 400.0,
	GatherRate = 7500,
	Tribulation = {
		StrikeCount = 9,
		DamagePerStrike = 9000,
		StrikeInterval = 0.9,
		TelegraphTime = 0.9,
		AuraColor = Color3.fromRGB(255, 255, 255),
	},
} :: RealmDefinition

CultivationConfig.TribulationTranscending = {
	Name = "Tribulation Transcending",
	Tier = 9,
	BaseMaxHealth = 30000000,
	BaseTargetQi = 20000000,
	AuraColor = Color3.fromRGB(255, 80, 80),
	HealthMultiplier = 3500.0,
	DamageMultiplier = 900.0,
	GatherRate = 14500,
	Tribulation = {
		StrikeCount = 9,
		DamagePerStrike = 20000,
		StrikeInterval = 0.9,
		TelegraphTime = 0.9,
		AuraColor = Color3.fromRGB(255, 80, 80),
	},
} :: RealmDefinition

CultivationConfig.ImmortalAscension = {
	Name = "Immortal Ascension",
	Tier = 10,
	BaseMaxHealth = 80000000,
	BaseTargetQi = 45000000,
	AuraColor = Color3.fromRGB(255, 235, 120),
	HealthMultiplier = 8000.0,
	DamageMultiplier = 2000.0,
	GatherRate = 28000,
	Tribulation = {
		StrikeCount = 9,
		DamagePerStrike = 50000,
		StrikeInterval = 0.8,
		TelegraphTime = 0.8,
		AuraColor = Color3.fromRGB(255, 235, 120),
	},
} :: RealmDefinition

function CultivationConfig.GetOrderTargetQi(realmTier: RealmTier, order: number): number
	local realmInfo = (CultivationConfig :: any)[realmTier] :: RealmDefinition?
	if not realmInfo then return 1000 end

	local clampedOrder = math.clamp(order, 1, 9)
	local cumTarget = 0
	for o = 1, clampedOrder do
		local delta = math.floor(realmInfo.BaseTargetQi * math.pow(CultivationConfig.ORDER_TARGET_QI_EXPONENT, o - 1))
		cumTarget += delta
	end
	return cumTarget
end

function CultivationConfig.GetOrderStartingMaxQi(realmTier: RealmTier, order: number): number
	local targetQi = CultivationConfig.GetOrderTargetQi(realmTier, order)
	return math.floor(targetQi * 0.20)
end

function CultivationConfig.GetOrderMaxHealth(realmTier: RealmTier, order: number): number
	local realmInfo = (CultivationConfig :: any)[realmTier] :: RealmDefinition?
	if not realmInfo then return 100 end

	local clampedOrder = math.clamp(order, 1, 9)
	local hpScale = 1.0 + ((clampedOrder - 1) * CultivationConfig.ORDER_MAX_HP_INCREMENT)
	return math.floor(realmInfo.BaseMaxHealth * hpScale)
end

function CultivationConfig.GetPowerMultiplier(realmTier: RealmTier, order: number): number
	local realmInfo = (CultivationConfig :: any)[realmTier] :: RealmDefinition?
	if not realmInfo then return 1.0 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderBonus = (clampedOrder - 1) * 0.05
	return realmInfo.DamageMultiplier * (1.0 + orderBonus)
end

return CultivationConfig