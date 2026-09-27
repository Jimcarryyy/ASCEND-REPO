--!strict
--[[
    BloodlineConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau
    Sword Cultivator Bloodline Lineages, Gacha Probability Weights,
    Passive Buffs, and 3D Visual Artifact Manifests.
    Architecture:
      - 7 Tiers: Mortal, Common, Spiritual, Earth, Heaven, Legendary, Mythic
      - Tiers 1–4: Spiritual Orbs (Mounted to UpperTorso/Torso Back)
      - Tiers 5–7: 6-Pointed Sword Halos & Arrays (Mounted to UpperTorso/Torso Back)
      - Includes Legacy ID Aliases to prevent saves from breaking.
]]

export type BloodlineTier = "Mortal" | "Common" | "Spiritual" | "Earth" | "Heaven" | "Legendary" | "Mythic"

export type VisualArtifactSpec = {
	ArtifactName: string,
	AttachmentPoint: string,
	AuraColor: Color3,
	PromptForMeshyAI: string,
}

export type BloodlinePassives = {
	DamageMultiplier: number?,
	AttackSpeedMultiplier: number?,
	HealthMultiplier: number?,
	DefenseMultiplier: number?,
	SpeedMultiplier: number?,
	DashDistanceMultiplier: number?,
	QiGatherMultiplier: number?,
	MaxQiMultiplier: number?,
	HealthRegenMultiplier: number?,
	PostureDamageMultiplier: number?,
	CritChance: number?,
	LifestealPercent: number?,
	CooldownReduction: number?,
	RangeMultiplier: number?,
	GuardPierce: number?,
}

export type BloodlineDefinition = {
	Id: string,
	Name: string,
	Tier: BloodlineTier,
	Weight: number,
	Description: string,
	Passives: BloodlinePassives,
	VisualArtifact: VisualArtifactSpec,
}

local BloodlineConfig = {}

local LINEAGES: { [string]: BloodlineDefinition } = {
	-- =========================================================================
	-- TIER 1: MORTAL (45% Weight) — Spiritual Orb
	-- =========================================================================
	["MortalSwordBone"] = {
		Id = "MortalSwordBone",
		Name = "Mortal Sword Bone",
		Tier = "Mortal",
		Weight = 450,
		Description = "Mundane bones tempered with basic sword intent. Grants +5% sword attack speed and +5% base damage.",
		Passives = { DamageMultiplier = 1.05, AttackSpeedMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "MortalSpineBone",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(180, 195, 210),
			PromptForMeshyAI = "Stylized wuxia floating metallic spirit orb, polished dark steel and bone sphere with subtle white-grey orbital ring, game asset.",
		},
	},

	-- =========================================================================
	-- TIER 2: COMMON (25% Weight) — Spiritual Orbs
	-- =========================================================================
	["AzureWindPedigree"] = {
		Id = "AzureWindPedigree",
		Name = "Azure Wind Pedigree",
		Tier = "Common",
		Weight = 125,
		Description = "A light wind vein coursing through the meridians. Grants +10% Dash Distance and +5% Movement Speed.",
		Passives = { SpeedMultiplier = 1.05, DashDistanceMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "WindCrestFeather",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(150, 235, 200),
			PromptForMeshyAI = "Pale cyan floating wind spirit orb, translucent jade and air swirl sphere with delicate cloud wisps, xianxia game prop.",
		},
	},

	["IronBloodVanguard"] = {
		Id = "IronBloodVanguard",
		Name = "Iron Blood Vanguard",
		Tier = "Common",
		Weight = 125,
		Description = "Meridians forged like reinforced iron. Grants +10% Max Health and +5% physical defense.",
		Passives = { HealthMultiplier = 1.10, DefenseMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "VanguardIronGorget",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(175, 130, 95),
			PromptForMeshyAI = "Heavy dark iron and bronze spirit orb, rough forged metallic sphere with engraved fortress crest lines, stylized low poly.",
		},
	},

	-- =========================================================================
	-- TIER 3: SPIRITUAL (15% Weight) — Spiritual Orbs
	-- =========================================================================
	["VerdantLotusVein"] = {
		Id = "VerdantLotusVein",
		Name = "Verdant Lotus Vein",
		Tier = "Spiritual",
		Weight = 75,
		Description = "A sacred root of the spiritual lotus. Grants +15% Qi Gathering speed and +10% Max Qi.",
		Passives = { QiGatherMultiplier = 1.15, MaxQiMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "LotusBackRelic",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(52, 211, 153),
			PromptForMeshyAI = "Glowing imperial emerald jade lotus spirit orb, translucent green crystal sphere resting in a gold lotus petal ring.",
		},
	},

	["FlowingMistStance"] = {
		Id = "FlowingMistStance",
		Name = "Flowing Mist Stance",
		Tier = "Spiritual",
		Weight = 75,
		Description = "Evasive fluid constitution. Grants -10% Dash Cooldown, +8% Posture Regen, and +10% Max Health.",
		Passives = { CooldownReduction = 0.10, HealthMultiplier = 1.10, SpeedMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "MistVeilShoulder",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(200, 225, 255),
			PromptForMeshyAI = "Flowing azure mist spirit orb, swirling celestial water vapor and soft silver cloud orb, xianxia cultivator relic.",
		},
	},

	-- =========================================================================
	-- TIER 4: EARTH (8% Weight) — Subterranean & Thunder Orbs
	-- =========================================================================
	["EarthTremorBone"] = {
		Id = "EarthTremorBone",
		Name = "Earth Tremor Bone",
		Tier = "Earth",
		Weight = 40,
		Description = "Dense mountain core weight. Grants +20% Max Posture, +15% Posture Damage, and +10% Defense.",
		Passives = { PostureDamageMultiplier = 1.15, DefenseMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "TremorGildedBracer",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(234, 179, 8),
			PromptForMeshyAI = "Heavy mountain basalt rock spirit orb, geometric gold vein inlays traversing dense grey granite sphere, ancient mountain orb.",
		},
	},

	["VioletThunderCore"] = {
		Id = "VioletThunderCore",
		Name = "Violet Thunder Core",
		Tier = "Earth",
		Weight = 40,
		Description = "Veins charged with heavenly lightning. Attacks inflict +15% posture damage and +10% critical strike chance.",
		Passives = { DamageMultiplier = 1.12, PostureDamageMultiplier = 1.15, CritChance = 0.10 },
		VisualArtifact = {
			ArtifactName = "ThunderRuneBackplate",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(192, 132, 252),
			PromptForMeshyAI = "Violet lightning spirit orb, pulsating amethyst crystal sphere surrounded by floating jagged purple thunder rings.",
		},
	},

	-- =========================================================================
	-- TIER 5: HEAVEN (4.5% Weight) — 6-Pointed Sword Halos
	-- =========================================================================
	["CrimsonDemonHeart"] = {
		Id = "CrimsonDemonHeart",
		Name = "Crimson Demon Heart",
		Tier = "Heaven",
		Weight = 23,
		Description = "Ferocious demonic blood drive. Grants +18% Sword Damage, +5% Lifesteal, and attacks pierce 15% guard block.",
		Passives = { DamageMultiplier = 1.18, LifestealPercent = 0.05, GuardPierce = 0.15 },
		VisualArtifact = {
			ArtifactName = "DemonHeartCrown",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(220, 20, 60),
			PromptForMeshyAI = "Demonic 6-pointed sword mandala halo, sharp dark metal hexagram ring with 6 crimson carnelian horn-like blades pointing outward, large central ruby gem, xianxia back ornament.",
		},
	},

	["AbyssalFrostVein"] = {
		Id = "AbyssalFrostVein",
		Name = "Abyssal Frost Vein",
		Tier = "Heaven",
		Weight = 22,
		Description = "Freezing void spiritual veins. Grants +20% Sword Damage, +20% Posture Damage, and +15% Guard Pierce.",
		Passives = { DamageMultiplier = 1.20, PostureDamageMultiplier = 1.20, GuardPierce = 0.15 },
		VisualArtifact = {
			ArtifactName = "FrostChasmHorns",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(140, 230, 255),
			PromptForMeshyAI = "Glacial frost 6-pointed sword snowflake halo, crystalline pale-cyan ice facets and 6 sharp ice-crystal daggers radiating outward, central sapphire gem, back crest.",
		},
	},

	-- =========================================================================
	-- TIER 6: LEGENDARY (2.0% Weight) — Mythical 6-Pointed Sword Halos
	-- =========================================================================
	["GoldenSunLineage"] = {
		Id = "GoldenSunLineage",
		Name = "Golden Sun Lineage",
		Tier = "Legendary",
		Weight = 10,
		Description = "Solar immortal emperor heritage. Grants +25% Power Multiplier, +20% Qi Recovery, and +15% Max Health.",
		Passives = { DamageMultiplier = 1.25, QiGatherMultiplier = 1.20, HealthMultiplier = 1.15 },
		VisualArtifact = {
			ArtifactName = "SolarHaloRing",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(250, 204, 21),
			PromptForMeshyAI = "Radiant golden 6-pointed sword mandala halo, ornate celestial gold ring with 6 glowing amber-gold sword blades radiating outward, faceted central yellow-gold diamond crystal, immortal sun relic, game asset.",
		},
	},

	["AsuraBloodline"] = {
		Id = "AsuraBloodline",
		Name = "Asura Bloodline",
		Tier = "Legendary",
		Weight = 10,
		Description = "Descendant of the Slaughter God. Grants +25% Sword Damage, +30% Posture Damage, and +15% Critical Strike Chance.",
		Passives = { DamageMultiplier = 1.25, PostureDamageMultiplier = 1.30, CritChance = 0.15 },
		VisualArtifact = {
			ArtifactName = "AsuraSpikePauldrons",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(220, 38, 38),
			PromptForMeshyAI = "Dark red and obsidian 6-pointed sword mandala halo, dark metallic hexagram ring adorned with 6 crimson-glowing broadsword blades pointing outward, large central red diamond gemstone, warlord back ornament, xianxia game asset.",
		},
	},

	-- =========================================================================
	-- TIER 7: MYTHIC (0.5% Weight) — Apex Sovereign Sword Array
	-- =========================================================================
	["PrimordialSwordImmortal"] = {
		Id = "PrimordialSwordImmortal",
		Name = "Primordial Sword Immortal",
		Tier = "Mythic",
		Weight = 5,
		Description = "The apex sovereign sword physique. Grants +35% Power Multiplier, +25% Max Qi, +20% Crit Chance, and -15% Universal Cooldowns.",
		Passives = {
			DamageMultiplier = 1.35,
			MaxQiMultiplier = 1.25,
			CritChance = 0.20,
			CooldownReduction = 0.15,
			HealthMultiplier = 1.20,
		},
		VisualArtifact = {
			ArtifactName = "PrimordialFloatingSwords",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(255, 235, 120),
			PromptForMeshyAI = "Supreme primordial sovereign sword array, arched golden mandala back ring with fanned array of white-gold celestial flying swords, divine immortal relic.",
		},
	},
}

-- Backward compatibility alias map for pre-existing player saves
local LEGACY_ID_MAP: { [string]: string } = {
	["IronMeridianRoot"] = "IronBloodVanguard",
	["BreezeSpiritVein"] = "AzureWindPedigree",
	["AzureDragonMeridian"] = "EarthTremorBone",
	["VerdantLifeCore"] = "VerdantLotusVein",
	["ThunderSoulVessel"] = "VioletThunderCore",
	["AsuraSlaughterBloodline"] = "AsuraBloodline",
	["VoidSpiritRoot"] = "AbyssalFrostVein",
	["HeavenlySwordBody"] = "GoldenSunLineage",
	["GlacialPhoenixMeridian"] = "AbyssalFrostVein",
	["ChaosPrimordialDaoBody"] = "PrimordialSwordImmortal",
	["NineNetherSovereign"] = "CrimsonDemonHeart",
}

function BloodlineConfig.GetBloodline(id: string): BloodlineDefinition?
	if not id or id == "" then return LINEAGES["MortalSwordBone"] end
	if LINEAGES[id] then return LINEAGES[id] end
	local mapped = LEGACY_ID_MAP[id]
	if mapped and LINEAGES[mapped] then return LINEAGES[mapped] end
	return LINEAGES["MortalSwordBone"]
end

function BloodlineConfig.GetAllBloodlines(): { [string]: BloodlineDefinition }
	return LINEAGES
end

function BloodlineConfig.RollBloodline(): string
	local totalWeight = 0
	for _, def in pairs(LINEAGES) do
		totalWeight += def.Weight
	end

	local roll = math.random() * totalWeight
	local cumulative = 0

	for id, def in pairs(LINEAGES) do
		cumulative += def.Weight
		if roll <= cumulative then
			return id
		end
	end

	return "MortalSwordBone"
end

return BloodlineConfig