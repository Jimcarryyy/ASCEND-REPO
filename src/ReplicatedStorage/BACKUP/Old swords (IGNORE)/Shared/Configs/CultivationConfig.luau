--!strict
-- CultivationConfig.luau
-- Location: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
-- Central configuration registry for 10 Major Cultivation Realms, 9 Orders each (90 Total Orders),
-- Dantian Capacity scaling, Realm Breakthrough Goals, percentage Qi costs, and unit number formatting.

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

export type RealmInfo = {
	Name: string,
	Tier: number,
	BaseMaxHealth: number,
	BaseTargetQi: number, -- Realm Order 1 Breakthrough Goal
	GatherRate: number, -- Dantian Expansion Rate per second
	RegenMultiplier: number, -- Meditation base multiplier
	AuraColor: Color3,
	HealthMultiplier: number,
	Tribulation: TribulationSpec,
}

local CultivationConfig = {
	-- Universal Number Formatting Helper (1k, 1M, 1B, 1T)
	FormatNumber = function(num: number): string
		local absolute = math.abs(num)
		if absolute >= 1e15 then
			return string.format("%.2fQa", num / 1e15)
		elseif absolute >= 1e12 then
			return string.format("%.2fT", num / 1e12)
		elseif absolute >= 1e9 then
			return string.format("%.2fB", num / 1e9)
		elseif absolute >= 1e6 then
			return string.format("%.2fM", num / 1e6)
		elseif absolute >= 1e3 then
			return string.format("%.1fk", num / 1e3)
		else
			return tostring(math.floor(num))
		end
	end,

	-- Strategic Skill Qi Costs as a Percentage of Player's Current CultivatedQi
	SkillCostPercent = {
		M1 = 0.00,    -- 0% CultivatedQi
		Shift = 0.03, -- 3% CultivatedQi
		F = 0.08,     -- 8% CultivatedQi
		E = 0.12,     -- 12% CultivatedQi
		Q = 0.15,     -- 15% CultivatedQi
		R = 0.30,     -- 30% CultivatedQi (Ultimate)
	},

	-- Tier 1: Qi Condensation ($1,000 -> $12,000)
	QiCondensation = {
		Name = "Qi Condensation",
		Tier = 1,
		BaseMaxHealth = 1000,
		BaseTargetQi = 1000,
		GatherRate = 5,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(0, 220, 255),
		HealthMultiplier = 1.0,
		Tribulation = { StrikeCount = 0, DamagePerStrike = 0, StrikeInterval = 0, TelegraphTime = 0, AuraColor = Color3.fromRGB(0, 220, 255) }
	},

	-- Tier 2: Foundation Establishment ($15,000 -> $120,000)
	FoundationEstablishment = {
		Name = "Foundation Establishment",
		Tier = 2,
		BaseMaxHealth = 15000,
		BaseTargetQi = 15000,
		GatherRate = 15,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 215, 0),
		HealthMultiplier = 15.0,
		Tribulation = { StrikeCount = 2, DamagePerStrike = 2000, StrikeInterval = 1.5, TelegraphTime = 1.2, AuraColor = Color3.fromRGB(255, 215, 0) }
	},

	-- Tier 3: Golden Core ($75,000 -> $850,000)
	GoldenCore = {
		Name = "Golden Core",
		Tier = 3,
		BaseMaxHealth = 75000,
		BaseTargetQi = 75000,
		GatherRate = 40,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 140, 0),
		HealthMultiplier = 75.0,
		Tribulation = { StrikeCount = 3, DamagePerStrike = 10000, StrikeInterval = 1.5, TelegraphTime = 1.2, AuraColor = Color3.fromRGB(255, 140, 0) }
	},

	-- Tier 4: Nascent Soul ($350,000 -> $4.5M)
	NascentSoul = {
		Name = "Nascent Soul",
		Tier = 4,
		BaseMaxHealth = 350000,
		BaseTargetQi = 350000,
		GatherRate = 120,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(180, 50, 255),
		HealthMultiplier = 350.0,
		Tribulation = { StrikeCount = 4, DamagePerStrike = 50000, StrikeInterval = 1.5, TelegraphTime = 1.0, AuraColor = Color3.fromRGB(180, 50, 255) }
	},

	-- Tier 5: Spirit Severing ($1.5M -> $22M)
	SpiritSevering = {
		Name = "Spirit Severing",
		Tier = 5,
		BaseMaxHealth = 1500000,
		BaseTargetQi = 1500000,
		GatherRate = 400,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 50, 80),
		HealthMultiplier = 1500.0,
		Tribulation = { StrikeCount = 5, DamagePerStrike = 200000, StrikeInterval = 1.2, TelegraphTime = 1.0, AuraColor = Color3.fromRGB(255, 50, 80) }
	},

	-- Tier 6: Void Refining ($7.5M -> $90M)
	VoidRefining = {
		Name = "Void Refining",
		Tier = 6,
		BaseMaxHealth = 7500000,
		BaseTargetQi = 7500000,
		GatherRate = 1200,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(120, 0, 220),
		HealthMultiplier = 7500.0,
		Tribulation = { StrikeCount = 5, DamagePerStrike = 1000000, StrikeInterval = 1.2, TelegraphTime = 0.9, AuraColor = Color3.fromRGB(120, 0, 220) }
	},

	-- Tier 7: Body Integration ($25M -> $280M)
	BodyIntegration = {
		Name = "Body Integration",
		Tier = 7,
		BaseMaxHealth = 25000000,
		BaseTargetQi = 25000000,
		GatherRate = 3500,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(50, 220, 150),
		HealthMultiplier = 25000.0,
		Tribulation = { StrikeCount = 6, DamagePerStrike = 3000000, StrikeInterval = 1.0, TelegraphTime = 0.8, AuraColor = Color3.fromRGB(50, 220, 150) }
	},

	-- Tier 8: Mahayana ($55M -> $650M)
	Mahayana = {
		Name = "Mahayana",
		Tier = 8,
		BaseMaxHealth = 55000000,
		BaseTargetQi = 55000000,
		GatherRate = 10000,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 230, 120),
		HealthMultiplier = 55000.0,
		Tribulation = { StrikeCount = 7, DamagePerStrike = 7000000, StrikeInterval = 1.0, TelegraphTime = 0.8, AuraColor = Color3.fromRGB(255, 230, 120) }
	},

	-- Tier 9: Tribulation Transcending ($80M -> $950M)
	TribulationTranscending = {
		Name = "Tribulation Transcending",
		Tier = 9,
		BaseMaxHealth = 80000000,
		BaseTargetQi = 80000000,
		GatherRate = 30000,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 255, 255),
		HealthMultiplier = 80000.0,
		Tribulation = { StrikeCount = 9, DamagePerStrike = 12000000, StrikeInterval = 0.8, TelegraphTime = 0.7, AuraColor = Color3.fromRGB(255, 255, 255) }
	},

	-- Tier 10: Immortal Ascension ($100M -> $1.5B V1 Cap)
	ImmortalAscension = {
		Name = "Immortal Ascension",
		Tier = 10,
		BaseMaxHealth = 100000000,
		BaseTargetQi = 100000000,
		GatherRate = 80000,
		RegenMultiplier = 6.0,
		AuraColor = Color3.fromRGB(255, 215, 0),
		HealthMultiplier = 100000.0,
		Tribulation = { StrikeCount = 0, DamagePerStrike = 0, StrikeInterval = 0, TelegraphTime = 0, AuraColor = Color3.fromRGB(255, 215, 0) }
	},
}

function CultivationConfig.GetOrderMaxHealth(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1000 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderScale = math.pow(1.35, clampedOrder - 1)
	return math.floor(info.BaseMaxHealth * orderScale)
end

-- Realm Breakthrough Goal (MaxQiGoal)
function CultivationConfig.GetOrderTargetQi(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1000 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderScale = math.pow(1.45, clampedOrder - 1)
	return math.floor(info.BaseTargetQi * orderScale)
end

-- Alias for GetOrderTargetQi for backward compatibility
function CultivationConfig.GetOrderMaxQi(realmTier: RealmTier, order: number): number
	return CultivationConfig.GetOrderTargetQi(realmTier, order)
end

-- Starting CultivatedQi Capacity for a new Order (20% of MaxQiGoal)
function CultivationConfig.GetOrderStartingMaxQi(realmTier: RealmTier, order: number): number
	local targetQi = CultivationConfig.GetOrderTargetQi(realmTier, order)
	return math.floor(targetQi * 0.20)
end

-- Dynamic Power Multiplier based on Realm & Order
function CultivationConfig.GetPowerMultiplier(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1.0 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderBonus = 1 + ((clampedOrder - 1) * 0.15)
	return info.HealthMultiplier * orderBonus
end

return CultivationConfig