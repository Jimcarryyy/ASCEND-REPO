--!strict
--[[
    CultivationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
    Central configuration registry for 10 Major Cultivation Realms, 9 Orders each (90 Total Orders),
    Dantian Capacity scaling, Realm Breakthrough Goals, percentage Qi costs, and unit number formatting.
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

export type RealmInfo = {
	Name: string,
	Tier: number,
	BaseMaxHealth: number,
	BaseTargetQi: number,
	GatherRate: number,
	RegenMultiplier: number,
	AuraColor: Color3,
	HealthMultiplier: number,
	Tribulation: TribulationSpec,
}

export type OrderRequirements = {
	MaxQi: number,
}

local CultivationConfig = {
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

	SkillCostPercent = {
		M1 = 0.00,
		Shift = 0.03,
		F = 0.08,
		E = 0.12,
		Q = 0.15,
		R = 0.30,
	},

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

function CultivationConfig.GetRealmDisplayName(realmTier: RealmTier): string
	local info = CultivationConfig[realmTier]
	return if info and info.Name then info.Name else tostring(realmTier)
end

-- Returns this realm's ordinal position (1 = QiCondensation ... 10 = ImmortalAscension).
-- Used for reward/difficulty scaling that needs to know "how far along" a realm is,
-- e.g. MobAIManager's kill-reward multiplier.
function CultivationConfig.GetRealmIndex(realmTier: RealmTier): number
	local info = CultivationConfig[realmTier]
	return if info and info.Tier then info.Tier else 1
end

function CultivationConfig.GetOrderMaxHealth(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1000 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderScale = math.pow(1.35, clampedOrder - 1)
	return math.floor(info.BaseMaxHealth * orderScale)
end

function CultivationConfig.GetOrderTargetQi(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1000 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderScale = math.pow(1.45, clampedOrder - 1)
	return math.floor(info.BaseTargetQi * orderScale)
end

function CultivationConfig.GetOrderMaxQi(realmTier: RealmTier, order: number): number
	return CultivationConfig.GetOrderTargetQi(realmTier, order)
end

function CultivationConfig.GetOrderStartingMaxQi(realmTier: RealmTier, order: number): number
	local targetQi = CultivationConfig.GetOrderTargetQi(realmTier, order)
	return math.floor(targetQi * 0.20)
end

-- Returns the full breakthrough requirement bundle for a given realm+order.
-- Currently just wraps GetOrderTargetQi as MaxQi; used by MarketplaceManager's
-- "InstantQi" dev-product reward to fully cap out a player's current Qi.
function CultivationConfig.GetOrderRequirements(realmTier: RealmTier, order: number): OrderRequirements
	return {
		MaxQi = CultivationConfig.GetOrderTargetQi(realmTier, order),
	}
end

function CultivationConfig.GetPowerMultiplier(realmTier: RealmTier, order: number): number
	local info = CultivationConfig[realmTier]
	if not info then return 1.0 end

	local clampedOrder = math.clamp(order, 1, 9)
	local orderBonus = 1 + ((clampedOrder - 1) * 0.15)
	return info.HealthMultiplier * orderBonus
end

return CultivationConfig