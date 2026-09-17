--!strict
--[[
    BloodlineConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau
    Sword Cultivator Bloodline Lineages, Gacha Probability Weights,
    Passive Buffs, and 3D Visual Artifact Manifests.
]]

export type BloodlineTier = "Common" | "Rare" | "Legendary" | "Mythic"

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
	-- COMMON TIER (60% Total Gacha Weight)
	-- =========================================================================
	["MortalSwordBone"] = {
		Id = "MortalSwordBone",
		Name = "Mortal Sword Bone",
		Tier = "Common",
		Weight = 20,
		Description = "Bones tempered with basic sword intent. Grants +5% sword attack speed and +5% base damage.",
		Passives = { DamageMultiplier = 1.05, AttackSpeedMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "SteelMeridianGlow",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(190, 210, 225),
			PromptForMeshyAI = "Subtle steel-silver glowing bracers.",
		},
	},

	["IronMeridianRoot"] = {
		Id = "IronMeridianRoot",
		Name = "Iron Meridian Root",
		Tier = "Common",
		Weight = 20,
		Description = "Meridians forged like reinforced iron. Grants +10% Max Health and +5% physical defense.",
		Passives = { HealthMultiplier = 1.10, DefenseMultiplier = 1.05 },
		VisualArtifact = {
			ArtifactName = "IronRootCore",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(160, 120, 90),
			PromptForMeshyAI = "Ancient copper meridian chest ornament.",
		},
	},

	["BreezeSpiritVein"] = {
		Id = "BreezeSpiritVein",
		Name = "Breeze Spirit Vein",
		Tier = "Common",
		Weight = 20,
		Description = "A light wind vein coursing through the legs. Grants +10% Dash Distance and +5% Movement Speed.",
		Passives = { SpeedMultiplier = 1.05, DashDistanceMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "WindGaleAnklets",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(150, 235, 200),
			PromptForMeshyAI = "Ethereal pale cyan wind tendril swirls.",
		},
	},

	-- =========================================================================
	-- RARE TIER (28% Total Gacha Weight)
	-- =========================================================================
	["AzureDragonMeridian"] = {
		Id = "AzureDragonMeridian",
		Name = "Azure Dragon Meridian",
		Tier = "Rare",
		Weight = 10,
		Description = "Ancient draconic lineage. Grants +15% Qi Gathering speed and +10% Max Qi.",
		Passives = { QiGatherMultiplier = 1.15, MaxQiMultiplier = 1.10 },
		VisualArtifact = {
			ArtifactName = "AzureDragonBracer",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(34, 211, 238),
			PromptForMeshyAI = "Azure dragon claw shoulder armor plate.",
		},
	},

	["VerdantLifeCore"] = {
		Id = "VerdantLifeCore",
		Name = "Verdant Life Core",
		Tier = "Rare",
		Weight = 9,
		Description = "A sacred seed of the primordial wood spirit. Grants +25% HP passive regeneration and +15% Max Health.",
		Passives = { HealthMultiplier = 1.15, HealthRegenMultiplier = 1.25 },
		VisualArtifact = {
			ArtifactName = "JadeLotusOrb",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(52, 211, 153),
			PromptForMeshyAI = "Glowing imperial jade green lotus bud floating above a golden spirit ring.",
		},
	},

	["ThunderSoulVessel"] = {
		Id = "ThunderSoulVessel",
		Name = "Thunder Soul Vessel",
		Tier = "Rare",
		Weight = 9,
		Description = "Veins charged with heavenly lightning. Attacks inflict +15% posture damage and +10% critical strike chance.",
		Passives = { PostureDamageMultiplier = 1.15, CritChance = 0.10 },
		VisualArtifact = {
			ArtifactName = "ThunderSpineNeedles",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(192, 132, 252),
			PromptForMeshyAI = "Four floating purple lightning crystal needles hovering along the spine.",
		},
	},

	-- =========================================================================
	-- LEGENDARY TIER (10% Total Gacha Weight)
	-- =========================================================================
	["AsuraSlaughterBloodline"] = {
		Id = "AsuraSlaughterBloodline",
		Name = "Asura Slaughter Bloodline",
		Tier = "Legendary",
		Weight = 3,
		Description = "Descendant of the Blood Asura. Grants +25% Base Sword Damage, +20% Posture Damage, and kills heal 5% Max HP.",
		Passives = { DamageMultiplier = 1.25, PostureDamageMultiplier = 1.20, LifestealPercent = 0.05 },
		VisualArtifact = {
			ArtifactName = "AsuraBloodWheelHalo",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(220, 20, 60),
			PromptForMeshyAI = "Dark crimson circular wheel halo adorned with 6 demon horns.",
		},
	},

	["VoidSpiritRoot"] = {
		Id = "VoidSpiritRoot",
		Name = "Void Spirit Root",
		Tier = "Legendary",
		Weight = 2,
		Description = "Meridians born from the cosmic void. Grants -20% Skill Cooldowns and +30% Qi Gathering Speed.",
		Passives = { CooldownReduction = 0.20, QiGatherMultiplier = 1.30 },
		VisualArtifact = {
			ArtifactName = "CosmicVoidSphere",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(147, 51, 234),
			PromptForMeshyAI = "Cosmic black-hole sphere with swirling celestial stardust rings.",
		},
	},

	["HeavenlySwordBody"] = {
		Id = "HeavenlySwordBody",
		Name = "Heavenly Sword Body",
		Tier = "Legendary",
		Weight = 2.5,
		Description = "A physique forged as a divine sword. Grants +30% Sword Damage, +20% Attack Range, and attacks pierce 25% guard block.",
		Passives = { DamageMultiplier = 1.30, RangeMultiplier = 1.20, GuardPierce = 0.25 },
		VisualArtifact = {
			ArtifactName = "EightBladeCelestialHalo",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(250, 204, 21),
			PromptForMeshyAI = "Circular halo composed of 8 radiant golden Chinese straight swords.",
		},
	},

	["GlacialPhoenixMeridian"] = {
		Id = "GlacialPhoenixMeridian",
		Name = "Glacial Phoenix Meridian",
		Tier = "Legendary",
		Weight = 2.5,
		Description = "Ancient frost meridian of the Ice Phoenix. Grants +20% Sword Damage, +30% Posture Damage, and attacks chill enemy posture.",
		Passives = { DamageMultiplier = 1.20, PostureDamageMultiplier = 1.30, GuardPierce = 0.15 },
		VisualArtifact = {
			ArtifactName = "GlacialPhoenixCrest",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(160, 230, 255),
			PromptForMeshyAI = "Radial snowflake-shaped back crest of six faceted ice-crystal swords.",
		},
	},

	-- =========================================================================
	-- MYTHIC TIER (2% Total Gacha Weight)
	-- =========================================================================
	["ChaosPrimordialDaoBody"] = {
		Id = "ChaosPrimordialDaoBody",
		Name = "Chaos Primordial Dao Body",
		Tier = "Mythic",
		Weight = 1,
		Description = "The legendary pinnacle lineage of ancient chaos. Grants +40% All Damage, +50% Qi Gathering, +30% Max HP & Max Qi.",
		Passives = { DamageMultiplier = 1.40, QiGatherMultiplier = 1.50, HealthMultiplier = 1.30, MaxQiMultiplier = 1.30 },
		VisualArtifact = {
			ArtifactName = "PrimordialDragonWings",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(255, 235, 120),
			PromptForMeshyAI = "Celestial spirit wings of golden-white divine feathers.",
		},
	},

	["NineNetherSovereign"] = {
		Id = "NineNetherSovereign",
		Name = "Nine Nether Sovereign Body",
		Tier = "Mythic",
		Weight = 1,
		Description = "Pinnacle Netherworld sovereign lineage. Grants +35% Sword Damage, +40% Critical Strike Damage, +30% Guard Pierce, and strikes reap unrefined soul Qi.",
		Passives = { DamageMultiplier = 1.35, CritChance = 0.25, GuardPierce = 0.30, LifestealPercent = 0.08 },
		VisualArtifact = {
			ArtifactName = "NineNetherSoulHalo",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(30, 220, 190),
			PromptForMeshyAI = "Circular Netherworld ghost-flame halo with dark obsidian dragon horns and soul lanterns.",
		},
	},
}

function BloodlineConfig.GetBloodline(id: string): BloodlineDefinition?
	return LINEAGES[id]
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