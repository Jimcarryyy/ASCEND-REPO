--!strict
--[[
    BloodlineConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau
    Sword Cultivator Bloodline Lineages, Gacha Probability Weights,
    Passive Buffs, and 3D Visual Artifact Manifests for ASCEND:
      - 5 Canonical Tiers: Common, Uncommon, Rare, Epic, Legendary
      - 10 Dedicated Spiritual Orbs (Mounted to UpperTorso/Torso Back)
      - Dynamic Normalized ID / Folder Name Resolution
      - Includes Legacy ID Aliases to prevent saves from breaking.
]]

export type BloodlineTier = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mortal" | "Spiritual" | "Earth" | "Heaven" | "Mythic"

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
	-- 1. COMMON (45% Weight)
	-- =========================================================================
	["MortalSteelVein"] = {
		Id = "MortalSteelVein",
		Name = "Mortal Steel Vein",
		Tier = "Common",
		Weight = 450,
		Description = "Mundane physical meridians tempered with unyielding iron. Increases Base Health and physical Defense.",
		Passives = { HealthMultiplier = 1.08, DefenseMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "Mortal Steel Vein",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(160, 150, 140),
			PromptForMeshyAI = "Dark iron spherical spirit cage with brass rivets and hanging counterweight pendulum, wuxia cultivator relic.",
		},
	},

	-- =========================================================================
	-- 2. UNCOMMON (25% Weight)
	-- =========================================================================
	["SpiritIronSwordBone"] = {
		Id = "SpiritIronSwordBone",
		Name = "Spirit Iron Sword-Bone",
		Tier = "Uncommon",
		Weight = 250,
		Description = "Skeletal structure infused with spiritual iron blades. Sharpens sword attack speed, base damage, and reduces dash cooldown.",
		Passives = { AttackSpeedMultiplier = 1.08, DamageMultiplier = 1.05, CooldownReduction = 0.08 },
		VisualArtifact = {
			ArtifactName = "Spirit Iron Sword-Bone",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(150, 195, 230),
			PromptForMeshyAI = "Pale blue-steel crossed curved blades enclosing a dark sphere with a miniature cross-guard sword, xianxia martial orb.",
		},
	},

	-- =========================================================================
	-- 3 & 4. RARE (15% Total Weight — 7.5% each)
	-- =========================================================================
	["GaleJadeSwordVein"] = {
		Id = "GaleJadeSwordVein",
		Name = "Gale-Jade Sword-Vein",
		Tier = "Rare",
		Weight = 75,
		Description = "Wind meridians swirling within celestial nephrite jade. Boosts Movement Speed, Dash Distance, and Qi Gathering rate.",
		Passives = { SpeedMultiplier = 1.10, DashDistanceMultiplier = 1.20, QiGatherMultiplier = 1.15 },
		VisualArtifact = {
			ArtifactName = "Gale-Jade Sword-Vein",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(120, 225, 195),
			PromptForMeshyAI = "Pale teal nephrite jade orb with wind swirl patterns enclosed in a gold crescent ring with hanging jade beads.",
		},
	},

	["JadeLotusOrb"] = {
		Id = "JadeLotusOrb",
		Name = "JadeLotusOrb",
		Tier = "Rare",
		Weight = 75,
		Description = "A sacred emerald lotus blooming within the spiritual sea. Enhances Max Qi, Health Regeneration, and Qi Gathering.",
		Passives = { MaxQiMultiplier = 1.20, QiGatherMultiplier = 1.25, HealthMultiplier = 1.08 },
		VisualArtifact = {
			ArtifactName = "JadeLotusOrb",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(34, 197, 94),
			PromptForMeshyAI = "Intricate emerald jade lotus flower crown with delicate golden filigree rim and hanging jade beads, immortal relic.",
		},
	},

	-- =========================================================================
	-- 5, 6 & 7. EPIC (10% Total Weight — 3.33% each)
	-- =========================================================================
	["ThunderSeveringSwordHeart"] = {
		Id = "ThunderSeveringSwordHeart",
		Name = "Thunder-Severing Sword-Heart",
		Tier = "Epic",
		Weight = 33,
		Description = "A tempest heart coursing with violet heavenly tribulation bolts. Heavily boosts Posture Damage and Critical Strike Chance.",
		Passives = { PostureDamageMultiplier = 1.25, CritChance = 0.15, DamageMultiplier = 1.12 },
		VisualArtifact = {
			ArtifactName = "Thunder-Severing Sword-Heart",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(168, 85, 247),
			PromptForMeshyAI = "Deep purple orb radiating outward with sharp jagged metallic lightning spikes and a central engraved ring.",
		},
	},

	["HeavyCragSwordMarrow"] = {
		Id = "HeavyCragSwordMarrow",
		Name = "Heavy-Crag Sword-Marrow",
		Tier = "Epic",
		Weight = 33,
		Description = "Mountain-density basalt and meteoric iron marrow. Massively enhances Max Health, Defense, and Posture resistance.",
		Passives = { HealthMultiplier = 1.25, DefenseMultiplier = 1.20, PostureDamageMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "Heavy-Crag Sword-Marrow",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(245, 158, 11),
			PromptForMeshyAI = "Warm amber sphere bound with heavy dark forged iron bands and jagged rock spikes, ancient mountain core.",
		},
	},

	["CosmicVoidSphere"] = {
		Id = "CosmicVoidSphere",
		Name = "CosmicVoidSphere",
		Tier = "Epic",
		Weight = 34,
		Description = "An armillary microcosm bound to stellar spatial rifts. Expands Max Qi capacity, reduces cooldowns, and pierces guard.",
		Passives = { MaxQiMultiplier = 1.30, CooldownReduction = 0.15, GuardPierce = 0.15 },
		VisualArtifact = {
			ArtifactName = "CosmicVoidSphere",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(99, 102, 241),
			PromptForMeshyAI = "Intricate golden armillary sphere with rotating rings enclosing an astral purple core pierced by a golden spear.",
		},
	},

	-- =========================================================================
	-- 8, 9 & 10. LEGENDARY (5% Total Weight — 1.67% each)
	-- =========================================================================
	["InnateSovereignSwordBone"] = {
		Id = "InnateSovereignSwordBone",
		Name = "Innate Sovereign Sword-Bone",
		Tier = "Legendary",
		Weight = 17,
		Description = "The celestial bones of a primordial sovereign swordsman. Grants immense Sword Damage, Max Qi, and unyielding Critical Strikes.",
		Passives = { DamageMultiplier = 1.30, MaxQiMultiplier = 1.25, CritChance = 0.20, HealthMultiplier = 1.15 },
		VisualArtifact = {
			ArtifactName = "Innate Sovereign Sword-Bone",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(250, 204, 21),
			PromptForMeshyAI = "Sovereign white bone orb nested inside an ornate celestial gold armillary sphere with carved ivory accents.",
		},
	},

	["GhostShadowSwordPulse"] = {
		Id = "GhostShadowSwordPulse",
		Name = "Ghost-Shadow Sword-Pulse",
		Tier = "Legendary",
		Weight = 16,
		Description = "Ethereal void pulse drifting between physical and phantom realms. Attacks pierce defenses completely and siphon vital life force.",
		Passives = { DamageMultiplier = 1.25, GuardPierce = 0.30, LifestealPercent = 0.10, SpeedMultiplier = 1.12 },
		VisualArtifact = {
			ArtifactName = "Ghost-Shadow Sword-Pulse",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(56, 189, 248),
			PromptForMeshyAI = "Deep midnight starfield sphere wrapped by sharp silver sickle blades, astral phantom ghost relic.",
		},
	},

	["ScarletLotusBladeBone"] = {
		Id = "ScarletLotusBladeBone",
		Name = "Scarlet-Lotus Blade-Bone",
		Tier = "Legendary",
		Weight = 17,
		Description = "A crimson slaughter lotus rooted in ashen battlefields. Bestows devastating Sword Damage, vicious Posture Shatter, and Blood Lifesteal.",
		Passives = { DamageMultiplier = 1.35, PostureDamageMultiplier = 1.35, LifestealPercent = 0.12, CritChance = 0.15 },
		VisualArtifact = {
			ArtifactName = "Scarlet-Lotus Blade-Bone",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(239, 68, 68),
			PromptForMeshyAI = "Glowing ruby-crimson sphere resting inside dark forged bone lotus petals, slaughter warlord relic.",
		},
	},
}

-- Aliases for Exact Studio Folder Model Names
LINEAGES["Mortal Steel Vein"]            = LINEAGES["MortalSteelVein"]
LINEAGES["Spirit Iron Sword-Bone"]      = LINEAGES["SpiritIronSwordBone"]
LINEAGES["Gale-Jade Sword-Vein"]        = LINEAGES["GaleJadeSwordVein"]
LINEAGES["Thunder-Severing Sword-Heart"]= LINEAGES["ThunderSeveringSwordHeart"]
LINEAGES["Heavy-Crag Sword-Marrow"]     = LINEAGES["HeavyCragSwordMarrow"]
LINEAGES["Innate Sovereign Sword-Bone"] = LINEAGES["InnateSovereignSwordBone"]
LINEAGES["Ghost-Shadow Sword-Pulse"]    = LINEAGES["GhostShadowSwordPulse"]
LINEAGES["Scarlet-Lotus Blade-Bone"]    = LINEAGES["ScarletLotusBladeBone"]

-- Backward Compatibility Alias Map for Legacy Player Saves
local LEGACY_ID_MAP: { [string]: string } = {
	["MortalSwordBone"]          = "MortalSteelVein",
	["IronBloodVanguard"]        = "MortalSteelVein",
	["IronMeridianRoot"]         = "MortalSteelVein",
	["AzureWindPedigree"]        = "SpiritIronSwordBone",
	["BreezeSpiritVein"]         = "SpiritIronSwordBone",
	["VerdantLotusVein"]         = "JadeLotusOrb",
	["VerdantLifeCore"]          = "JadeLotusOrb",
	["FlowingMistStance"]        = "GaleJadeSwordVein",
	["EarthTremorBone"]          = "HeavyCragSwordMarrow",
	["AzureDragonMeridian"]      = "HeavyCragSwordMarrow",
	["VioletThunderCore"]        = "ThunderSeveringSwordHeart",
	["ThunderSoulVessel"]        = "ThunderSeveringSwordHeart",
	["CrimsonDemonHeart"]        = "ScarletLotusBladeBone",
	["AsuraBloodline"]           = "ScarletLotusBladeBone",
	["AsuraSlaughterBloodline"]  = "ScarletLotusBladeBone",
	["AbyssalFrostVein"]         = "GhostShadowSwordPulse",
	["VoidSpiritRoot"]           = "CosmicVoidSphere",
	["GoldenSunLineage"]         = "InnateSovereignSwordBone",
	["HeavenlySwordBody"]        = "InnateSovereignSwordBone",
	["PrimordialSwordImmortal"]  = "InnateSovereignSwordBone",
	["NineNetherSovereign"]      = "GhostShadowSwordPulse",
	["GlacialPhoenixMeridian"]   = "GhostShadowSwordPulse",
	["ChaosPrimordialDaoBody"]   = "InnateSovereignSwordBone",
}

function BloodlineConfig.GetBloodline(id: string): BloodlineDefinition?
	if not id or id == "" then return LINEAGES["MortalSteelVein"] end
	if LINEAGES[id] then return LINEAGES[id] end
	local mapped = LEGACY_ID_MAP[id]
	if mapped and LINEAGES[mapped] then return LINEAGES[mapped] end
	return LINEAGES["MortalSteelVein"]
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

	return "MortalSteelVein"
end

return BloodlineConfig