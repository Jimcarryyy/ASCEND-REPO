--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Central configuration registry for all items, weapons, herbs, and buff pills in ASCEND.
]]

export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
export type ItemType = "Weapon" | "Consumable" | "Material" | "Crest"
export type ItemArchetype = "FlyingSword" | "Gauntlet" | "Spear" | "Pill" | "Material" | "Crest"

export type ItemData = {
	Id: string,
	Name: string,
	Type: ItemType,
	Archetype: ItemArchetype,
	Rarity: ItemRarity,
	Description: string,
	MaxStack: number,
	ModelName: string?,
	PrimaryColor: Color3,
	AgeYears: number?, -- Vintage Age (1, 10, 100, 1000)
	Stats: { [string]: number }?,
}

local ItemConfig = {}

local ITEMS: { [string]: ItemData } = {
	-- =========================================================================
	-- VINTAGE ALCHEMY HERBS (1-YEAR TO 1,000-YEAR TIERS)
	-- =========================================================================
	["SpiritGrass_1Yr"] = {
		Id = "SpiritGrass_1Yr",
		Name = "1-Year Spirit Grass",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Common",
		Description = "Young spirit herb containing basic Qi. Standard solvent for elementary pills.",
		MaxStack = 999,
		AgeYears = 1,
		PrimaryColor = Color3.fromRGB(120, 200, 120),
	},
	["SpiritGrass_10Yr"] = {
		Id = "SpiritGrass_10Yr",
		Name = "10-Year Spirit Grass",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Uncommon",
		Description = "A matured herb harvested from high mountain ridges with concentrated Qi veins.",
		MaxStack = 999,
		AgeYears = 10,
		PrimaryColor = Color3.fromRGB(76, 175, 80),
	},
	["SpiritGrass_100Yr"] = {
		Id = "SpiritGrass_100Yr",
		Name = "100-Year Spirit Grass",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Rare",
		Description = "A rare century herb glowing with radiant spirit light. Significantly boosts pill success.",
		MaxStack = 999,
		AgeYears = 100,
		PrimaryColor = Color3.fromRGB(33, 150, 243),
	},
	["SpiritGrass_1000Yr"] = {
		Id = "SpiritGrass_1000Yr",
		Name = "1,000-Year Sovereign Spirit Grass",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Mythic",
		Description = "An immortal thousand-year herb. Guarantees supreme pill quality and maximum buff duration.",
		MaxStack = 999,
		AgeYears = 1000,
		PrimaryColor = Color3.fromRGB(225, 29, 72),
	},

	["DragonBloodVine_1Yr"] = {
		Id = "DragonBloodVine_1Yr",
		Name = "1-Year Dragon Blood Vine",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Uncommon",
		Description = "A crimson vine imbued with volcanic heat. Primary ingredient for Physique Tempering Dan.",
		MaxStack = 999,
		AgeYears = 1,
		PrimaryColor = Color3.fromRGB(230, 90, 50),
	},
	["DragonBloodVine_100Yr"] = {
		Id = "DragonBloodVine_100Yr",
		Name = "100-Year Dragon Blood Vine",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Epic",
		Description = "Century dragon vine pulsing with fierce crimson energy. Drastically amplifies attack power pills.",
		MaxStack = 999,
		AgeYears = 100,
		PrimaryColor = Color3.fromRGB(156, 39, 176),
	},

	["GaleWindLotus_1Yr"] = {
		Id = "GaleWindLotus_1Yr",
		Name = "1-Year Gale Wind Lotus",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Uncommon",
		Description = "A light cyan lotus flower that floats on wind currents. Essential for Gale Wind Dan.",
		MaxStack = 999,
		AgeYears = 1,
		PrimaryColor = Color3.fromRGB(100, 220, 180),
	},
	["GaleWindLotus_100Yr"] = {
		Id = "GaleWindLotus_100Yr",
		Name = "100-Year Gale Wind Lotus",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Epic",
		Description = "Century wind lotus creating localized air currents. Grants extreme flight speed buffs.",
		MaxStack = 999,
		AgeYears = 100,
		PrimaryColor = Color3.fromRGB(59, 130, 246),
	},

	["CelestialDew"] = {
		Id = "CelestialDew",
		Name = "Celestial Dew Water",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Common",
		Description = "Pure mountain water collected under lunar light. Solves furnace instability.",
		MaxStack = 999,
		PrimaryColor = Color3.fromRGB(180, 220, 255),
	},
	["DemonBeastCore"] = {
		Id = "DemonBeastCore",
		Name = "Demon Beast Core",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Rare",
		Description = "Crystallized monster core harvested from beasts. Catalyst for high-tier pills.",
		MaxStack = 999,
		PrimaryColor = Color3.fromRGB(217, 119, 6),
	},

	-- Legacy aliases for backwards compatibility
	["SpiritGrass"] = {
		Id = "SpiritGrass",
		Name = "1-Year Spirit Grass",
		Type = "Material",
		Archetype = "Material",
		Rarity = "Common",
		Description = "Young spirit herb containing basic Qi. Standard solvent for elementary pills.",
		MaxStack = 999,
		AgeYears = 1,
		PrimaryColor = Color3.fromRGB(120, 200, 120),
	},

	-- =========================================================================
	-- REFINED BUFF PILLS (CRAFTABLE)
	-- =========================================================================
	["SpiritHealingDan"] = {
		Id = "SpiritHealingDan",
		Name = "Spirit Healing Dan",
		Type = "Consumable",
		Archetype = "Pill",
		Rarity = "Common",
		Description = "Restores physical vitality over time.",
		MaxStack = 99,
		PrimaryColor = Color3.fromRGB(16, 185, 129),
		Stats = { HealAmount = 80 },
	},
	["QiGatheringDan"] = {
		Id = "QiGatheringDan",
		Name = "Qi Gathering Dan",
		Type = "Consumable",
		Archetype = "Pill",
		Rarity = "Uncommon",
		Description = "Grants +100 Qi instantly and 2x Meditation Qi Speed for 300s.",
		MaxStack = 99,
		PrimaryColor = Color3.fromRGB(59, 130, 246),
		Stats = { QiGrant = 100, CultivationSpeedMult = 2.0, BuffDuration = 300 },
	},
	["PhysiqueTemperingDan"] = {
		Id = "PhysiqueTemperingDan",
		Name = "Physique Tempering Dan",
		Type = "Consumable",
		Archetype = "Pill",
		Rarity = "Rare",
		Description = "Tempering pill granting +35% Attack Power for 300s.",
		MaxStack = 99,
		PrimaryColor = Color3.fromRGB(217, 119, 6),
		Stats = { AttackDamageMult = 1.35, BuffDuration = 300 },
	},
	["GaleWindDan"] = {
		Id = "GaleWindDan",
		Name = "Gale Wind Dan",
		Type = "Consumable",
		Archetype = "Pill",
		Rarity = "Rare",
		Description = "Lightness pill granting +40% Movement & Flight Speed for 300s.",
		MaxStack = 99,
		PrimaryColor = Color3.fromRGB(100, 220, 180),
		Stats = { MovementSpeedMult = 1.40, BuffDuration = 300 },
	},
	["FoundationGatheringDan"] = {
		Id = "FoundationGatheringDan",
		Name = "Foundation Gathering Dan",
		Type = "Consumable",
		Archetype = "Pill",
		Rarity = "Epic",
		Description = "High-tier pill containing condensed spirit power required for Realm Breakthroughs.",
		MaxStack = 99,
		PrimaryColor = Color3.fromRGB(147, 51, 234),
		Stats = { QiGrant = 300 },
	},

	-- STARTER WEAPONS
	["FlyingSword"] = {
		Id = "FlyingSword",
		Name = "Azure Cloud Flying Sword",
		Type = "Weapon",
		Archetype = "FlyingSword",
		Rarity = "Common",
		Description = "Standard steel-forged flying sword handed to novice cultivators of Azure Cloud Sect.",
		MaxStack = 1,
		ModelName = "FlyingSword",
		PrimaryColor = Color3.fromRGB(120, 180, 220),
		Stats = { Damage = 25, Speed = 1.0 },
	},
	["FlyingSwordItem"] = {
		Id = "FlyingSwordItem",
		Name = "Azure Cloud Flying Sword",
		Type = "Weapon",
		Archetype = "FlyingSword",
		Rarity = "Common",
		Description = "Standard steel-forged flying sword handed to novice cultivators of Azure Cloud Sect.",
		MaxStack = 1,
		ModelName = "FlyingSword",
		PrimaryColor = Color3.fromRGB(120, 180, 220),
		Stats = { Damage = 25, Speed = 1.0 },
	},
	["GauntletItem"] = {
		Id = "GauntletItem",
		Name = "Ironclad Spirit Gauntlets",
		Type = "Weapon",
		Archetype = "Gauntlet",
		Rarity = "Common",
		Description = "Heavy brass gauntlets reinforced with Qi channels for close-quarters strikes.",
		MaxStack = 1,
		ModelName = "Gauntlet",
		PrimaryColor = Color3.fromRGB(180, 140, 100),
		Stats = { Damage = 30, Speed = 0.8 },
	},
	["SpearItem"] = {
		Id = "SpearItem",
		Name = "Azure Wind Spear",
		Type = "Weapon",
		Archetype = "Spear",
		Rarity = "Common",
		Description = "A long thrusting spear capable of channeling long-range Qi pierces.",
		MaxStack = 1,
		ModelName = "Spear",
		PrimaryColor = Color3.fromRGB(100, 170, 200),
		Stats = { Damage = 35, Speed = 0.9 },
	},
}

function ItemConfig.GetItem(itemId: string): ItemData?
	return ITEMS[itemId]
end

function ItemConfig.GetAllItems(): { [string]: ItemData }
	return ITEMS
end

return ItemConfig