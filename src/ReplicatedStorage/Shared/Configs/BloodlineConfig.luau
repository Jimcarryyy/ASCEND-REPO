--!strict
--[[
    BloodlineConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau
    Authoritative configuration for Sword Bloodlines (剑修血脉) in ASCEND:
      - Common (60%), Rare (25%), Legendary (12%), Mythic (3%)
      - Active combat passives (Posture, Qi costs, Sword Intent charge, Damage)
      - Physical 3D visual artifact references for Meshy AI models
]]

export type BloodlineRarity = "Common" | "Rare" | "Legendary" | "Mythic"

export type BloodlineDefinition = {
	Id: string,
	DisplayName: string,
	Rarity: BloodlineRarity,
	RollWeight: number,
	Description: string,
	Color: Color3,
	ArtifactMeshName: string, -- Model name to attach to character UpperTorso/back
	Stats: {
		SwordDamageBonus: number,    -- e.g. 0.10 for +10%
		SwordIntentRateBonus: number,-- e.g. 0.15 for +15%
		QiCostReduction: number,     -- e.g. 0.20 for -20%
		PostureBonus: number,        -- e.g. 0.15 for +15%
		FlightSpeedBonus: number,    -- studs/sec added to flying swords
		LifeStealPercent: number?,   -- e.g. 0.03 for 3% vampiric heal
	}
}

local BloodlineConfig = {}

local BLOODLINES: { [string]: BloodlineDefinition } = {
	-- =========================================================================
	-- COMMON TIER (60% Total Weight)
	-- =========================================================================
	["MortalSwordBone"] = {
		Id = "MortalSwordBone",
		DisplayName = "Mortal Sword Bone",
		Rarity = "Common",
		RollWeight = 35.0,
		Description = "An ordinary physical body refined by basic martial sword stances. +5% Posture stability.",
		Color = Color3.fromRGB(180, 190, 205),
		ArtifactMeshName = "Artifact_MortalScabbard",
		Stats = {
			SwordDamageBonus = 0.0,
			SwordIntentRateBonus = 0.0,
			QiCostReduction = 0.0,
			PostureBonus = 0.05,
			FlightSpeedBonus = 0,
		},
	},

	["IronVeinRoot"] = {
		Id = "IronVeinRoot",
		DisplayName = "Iron Vein Spiritual Root",
		Rarity = "Common",
		RollWeight = 25.0,
		Description = "Hardened spiritual veins infused with mountain iron ore. +8% Guard Break resistance.",
		Color = Color3.fromRGB(140, 150, 165),
		ArtifactMeshName = "Artifact_IronCoreGourd",
		Stats = {
			SwordDamageBonus = 0.0,
			SwordIntentRateBonus = 0.0,
			QiCostReduction = 0.0,
			PostureBonus = 0.08,
			FlightSpeedBonus = 0,
		},
	},

	-- =========================================================================
	-- RARE TIER (25% Total Weight)
	-- =========================================================================
	["FlowingRiverMeridian"] = {
		Id = "FlowingRiverMeridian",
		DisplayName = "Flowing River Meridian",
		Rarity = "Rare",
		RollWeight = 15.0,
		Description = "Meridians smooth as celestial mountain streams. +12% Qi regeneration speed while wielding a blade.",
		Color = Color3.fromRGB(56, 189, 248),
		ArtifactMeshName = "Artifact_AzureWaterRibbon",
		Stats = {
			SwordDamageBonus = 0.03,
			SwordIntentRateBonus = 0.05,
			QiCostReduction = 0.05,
			PostureBonus = 0.05,
			FlightSpeedBonus = 6,
		},
	},

	["StoneHeartAegis"] = {
		Id = "StoneHeartAegis",
		DisplayName = "Stone Heart Sword Aegis",
		Rarity = "Rare",
		RollWeight = 10.0,
		Description = "An unshakeable martial heart. +15% Posture and reduces incoming guard damage by 10%.",
		Color = Color3.fromRGB(120, 180, 120),
		ArtifactMeshName = "Artifact_BasaltTalismanPlaque",
		Stats = {
			SwordDamageBonus = 0.0,
			SwordIntentRateBonus = 0.0,
			QiCostReduction = 0.0,
			PostureBonus = 0.15,
			FlightSpeedBonus = 0,
		},
	},

	-- =========================================================================
	-- LEGENDARY TIER (12% Total Weight)
	-- =========================================================================
	["ThunderForgedFlesh"] = {
		Id = "ThunderForgedFlesh",
		DisplayName = "Thunder-Forged Flesh",
		Rarity = "Legendary",
		RollWeight = 7.0,
		Description = "A body tempered by heavenly lightning tribulation. +8% Sword Damage and +10 studs/s Flying Sword velocity.",
		Color = Color3.fromRGB(168, 85, 247),
		ArtifactMeshName = "Artifact_ThunderHaloWheel",
		Stats = {
			SwordDamageBonus = 0.08,
			SwordIntentRateBonus = 0.10,
			QiCostReduction = 0.08,
			PostureBonus = 0.10,
			FlightSpeedBonus = 10,
		},
	},

	["CrimsonAsuraSlaughter"] = {
		Id = "CrimsonAsuraSlaughter",
		DisplayName = "Crimson Asura Slaughter",
		Rarity = "Legendary",
		RollWeight = 5.0,
		Description = "An ancient martial lineage of relentless slaughter. +12% Sword Damage and 3% Life-Steal on critical sword strikes.",
		Color = Color3.fromRGB(239, 68, 68),
		ArtifactMeshName = "Artifact_AsuraBladeWings",
		Stats = {
			SwordDamageBonus = 0.12,
			SwordIntentRateBonus = 0.10,
			QiCostReduction = 0.0,
			PostureBonus = 0.08,
			FlightSpeedBonus = 8,
			LifeStealPercent = 0.03,
		},
	},

	-- =========================================================================
	-- MYTHIC TIER (3% Total Weight)
	-- =========================================================================
	["CelestialJadeDragonBody"] = {
		Id = "CelestialJadeDragonBody",
		DisplayName = "Celestial Jade Dragon Body",
		Rarity = "Mythic",
		RollWeight = 1.8,
		Description = "Embodied with the primordial soul of the True Celestial Dragon. +15% Sword Intent charge rate, +15% Sword Damage, and +18 studs/s Flying Sword speed.",
		Color = Color3.fromRGB(255, 215, 110),
		ArtifactMeshName = "Artifact_CelestialJadeDragonHalo",
		Stats = {
			SwordDamageBonus = 0.15,
			SwordIntentRateBonus = 0.20,
			QiCostReduction = 0.15,
			PostureBonus = 0.15,
			FlightSpeedBonus = 18,
		},
	},

	["VoidPrimordialOrigin"] = {
		Id = "VoidPrimordialOrigin",
		DisplayName = "Void Primordial Origin",
		Rarity = "Mythic",
		RollWeight = 1.2,
		Description = "Born from the boundless cosmic void. -25% Qi skill expenditure, +18% Sword Damage, and grants extended invulnerability on perfect parry.",
		Color = Color3.fromRGB(244, 114, 182),
		ArtifactMeshName = "Artifact_VoidAstralOrbs",
		Stats = {
			SwordDamageBonus = 0.18,
			SwordIntentRateBonus = 0.15,
			QiCostReduction = 0.25,
			PostureBonus = 0.20,
			FlightSpeedBonus = 22,
		},
	},
}

function BloodlineConfig.GetBloodline(id: string): BloodlineDefinition
	return BLOODLINES[id] or BLOODLINES["MortalSwordBone"]
end

function BloodlineConfig.GetAllBloodlines(): { [string]: BloodlineDefinition }
	return BLOODLINES
end

function BloodlineConfig.RollRandomBloodline(): BloodlineDefinition
	local totalWeight = 0
	for _, def in pairs(BLOODLINES) do
		totalWeight += def.RollWeight
	end

	local roll = math.random() * totalWeight
	local accumulated = 0

	for _, def in pairs(BLOODLINES) do
		accumulated += def.RollWeight
		if roll <= accumulated then
			return def
		end
	end

	return BLOODLINES["MortalSwordBone"]
end

return BloodlineConfig