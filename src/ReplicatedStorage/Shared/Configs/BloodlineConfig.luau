--!strict
--[[
    BloodlineConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau
    Sword Cultivator Bloodline Lineages, Gacha Probability Weights,
    Passive Buffs, and 3D Visual Artifact Manifests for Meshy AI.
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
			AttachmentPoint = "RightHand",
			AuraColor = Color3.fromRGB(190, 210, 225),
			PromptForMeshyAI = "Subtle steel-silver glowing wrist bracers with sharp metallic sword runes, stylized xianxia game prop.",
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
			PromptForMeshyAI = "Ancient copper meridian chest ornament with glowing vein lines, metallic luster, stylized.",
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
			AttachmentPoint = "LowerTorso",
			AuraColor = Color3.fromRGB(150, 235, 200),
			PromptForMeshyAI = "Ethereal pale cyan wind tendril swirls forming floating ring ribbons, stylized particle prop.",
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
			AttachmentPoint = "RightUpperArm",
			AuraColor = Color3.fromRGB(34, 211, 238),
			PromptForMeshyAI = "An azure dragon claw shoulder armor plate with glowing cyan scales and trailing spirit mist, high-detail game asset.",
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
			AttachmentPoint = "LeftUpperArm",
			AuraColor = Color3.fromRGB(52, 211, 153),
			PromptForMeshyAI = "A glowing imperial jade green lotus flower bud floating above a golden spirit ring, stylized xianxia.",
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
			PromptForMeshyAI = "Four floating purple lightning crystal needles hovering along the spine, crackling electric arcs, game model.",
		},
	},

	-- =========================================================================
	-- LEGENDARY TIER (10% Total Gacha Weight)
	-- =========================================================================
	["AsuraSlaughterBloodline"] = {
		Id = "AsuraSlaughterBloodline",
		Name = "Asura Slaughter Bloodline",
		Tier = "Legendary",
		Weight = 4,
		Description = "Descendant of the Blood Asura. Grants +25% Base Sword Damage, +20% Posture Damage, and kills heal 5% Max HP.",
		Passives = { DamageMultiplier = 1.25, PostureDamageMultiplier = 1.20, LifestealPercent = 0.05 },
		VisualArtifact = {
			ArtifactName = "AsuraBloodWheelHalo",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(220, 20, 60),
			PromptForMeshyAI = "A dark crimson circular wheel halo adorned with 6 curved demon horns and floating curved blades, blood-red glow, stylized.",
		},
	},

	["VoidSpiritRoot"] = {
		Id = "VoidSpiritRoot",
		Name = "Void Spirit Root",
		Tier = "Legendary",
		Weight = 3,
		Description = "Meridians born from the cosmic void. Grants -20% Skill Cooldowns and +30% Qi Gathering Speed.",
		Passives = { CooldownReduction = 0.20, QiGatherMultiplier = 1.30 },
		VisualArtifact = {
			ArtifactName = "CosmicVoidSphere",
			AttachmentPoint = "Head",
			AuraColor = Color3.fromRGB(147, 51, 234),
			PromptForMeshyAI = "A miniature deep purple cosmic black-hole sphere with swirling celestial stardust rings and orbiting crystalline runes, stylized game prop.",
		},
	},

	["HeavenlySwordBody"] = {
		Id = "HeavenlySwordBody",
		Name = "Heavenly Sword Body",
		Tier = "Legendary",
		Weight = 3,
		Description = "A physique forged as a divine sword. Grants +30% Sword Damage, +20% Attack Range, and attacks pierce 25% guard block.",
		Passives = { DamageMultiplier = 1.30, RangeMultiplier = 1.20, GuardPierce = 0.25 },
		VisualArtifact = {
			ArtifactName = "EightBladeCelestialHalo",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(250, 204, 21),
			PromptForMeshyAI = "An ethereal circular halo composed of 8 radiant golden Chinese straight swords (Jian) pointing outward, glowing with sacred celestial runes, golden metallic luster.",
		},
	},

	-- =========================================================================
	-- MYTHIC TIER (2% Total Gacha Weight)
	-- =========================================================================
	["ChaosPrimordialDaoBody"] = {
		Id = "ChaosPrimordialDaoBody",
		Name = "Chaos Primordial Dao Body",
		Tier = "Mythic",
		Weight = 2,
		Description = "The legendary pinnacle lineage of ancient chaos. Grants +40% All Damage, +50% Qi Gathering, +30% Max HP & Max Qi.",
		Passives = { DamageMultiplier = 1.40, QiGatherMultiplier = 1.50, HealthMultiplier = 1.30, MaxQiMultiplier = 1.30 },
		VisualArtifact = {
			ArtifactName = "PrimordialDragonWings",
			AttachmentPoint = "UpperTorso",
			AuraColor = Color3.fromRGB(255, 235, 120),
			PromptForMeshyAI = "Majestic ethereal celestial spirit wings made of golden-white divine feathers and flowing ribbon tendrils, glowing cosmic starlight particles, magnificent immortal god wings.",
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