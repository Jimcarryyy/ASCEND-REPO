--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Central configuration repository for all items in ASCEND.
]]

local UIAssets = require(script.Parent.UIAssets)

export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
export type ItemType = "Weapon" | "Consumable" | "Material" | "Currency" | "Crest"

export type ItemDefinition = {
	Id: string,
	Name: string,
	Description: string,
	Rarity: ItemRarity,
	Type: ItemType,
	MaxStack: number,
	AgeYears: number?,
	Stats: { [string]: number }?,
	Icon: string?,
}

local ItemConfig = {}

local ITEMS: { [string]: ItemDefinition } = {
	-- REFINED PILLS & DANS
	["PhysiqueTemperingDan"] = {
		Id = "PhysiqueTemperingDan",
		Name = "Physique Tempering Dan",
		Description = "An elixir infused with Dragon Blood Vine and Spirit Grass. Permanently tempers physical muscle and bone density.",
		Rarity = "Uncommon",
		Type = "Consumable",
		MaxStack = 10,
		Stats = { HealAmount = 150, QiGrant = 50 },
		Icon = UIAssets.Icons.PhysiqueTemperingDan,
	},
	["GaleWindDan"] = {
		Id = "GaleWindDan",
		Name = "Gale Wind Dan",
		Description = "A swift pill refined from Gale Wind Lotus. Grants lightning-fast movement speed and agile dash recovery.",
		Rarity = "Rare",
		Type = "Consumable",
		MaxStack = 10,
		Stats = { HealAmount = 100, QiGrant = 100 },
		Icon = UIAssets.Icons.GaleWindDan,
	},
	["QiGatheringDan"] = {
		Id = "QiGatheringDan",
		Name = "Qi Gathering Dan",
		Description = "Pure cultivation pill refined from Celestial Dew and Spirit Grass. Replenishes internal Spirit Qi reserves.",
		Rarity = "Rare",
		Type = "Consumable",
		MaxStack = 10,
		Stats = { QiGrant = 300 },
		Icon = UIAssets.Icons.QiGatheringDan,
	},
	["FoundationGatheringDan"] = {
		Id = "FoundationGatheringDan",
		Name = "Foundation Gathering Dan",
		Description = "A supreme breakthrough elixir distilled from Demon Beast Core and Spirit Dew. Crucial for realm ascensions.",
		Rarity = "Epic",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 400, QiGrant = 500 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["SpiritHealingDan"] = {
		Id = "SpiritHealingDan",
		Name = "Spirit Healing Dan",
		Description = "Gentle herbal pill that rapidly knits severe wounds and restores physical vitality.",
		Rarity = "Uncommon",
		Type = "Consumable",
		MaxStack = 20,
		Stats = { HealAmount = 250 },
		Icon = UIAssets.Icons.SpiritHealingDan,
	},

	-- HERBS & MATERIALS
	["SpiritGrass_1Yr"] = {
		Id = "SpiritGrass_1Yr",
		Name = "1-Yr Spirit Grass",
		Description = "Basic immortal grass blade freshly sprouted in spirit terrain.",
		Rarity = "Common",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1,
		Icon = UIAssets.Icons.SpiritGrass,
	},
	["SpiritGrass_10Yr"] = {
		Id = "SpiritGrass_10Yr",
		Name = "10-Yr Spirit Grass",
		Description = "Decade-matured spirit herb blade with visible Qi veins.",
		Rarity = "Uncommon",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 10,
		Icon = UIAssets.Icons.SpiritGrass,
	},
	["SpiritGrass_100Yr"] = {
		Id = "SpiritGrass_100Yr",
		Name = "100-Yr Spirit Grass",
		Description = "Century-aged glowing blue herb with high spirit purity.",
		Rarity = "Rare",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 100,
		Icon = UIAssets.Icons.SpiritGrass,
	},
	["SpiritGrass_1000Yr"] = {
		Id = "SpiritGrass_1000Yr",
		Name = "1,000-Yr Sovereign Spirit Grass",
		Description = "Mythic millennium herb pulsing with ancient immortal essence.",
		Rarity = "Mythic",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1000,
		Icon = UIAssets.Icons.SpiritGrass,
	},
	["DragonBloodVine_1Yr"] = {
		Id = "DragonBloodVine_1Yr",
		Name = "1-Yr Dragon Blood Vine",
		Description = "Crimson vine with fiery thorned sap.",
		Rarity = "Common",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1,
		Icon = UIAssets.Icons.DragonBloodVine,
	},
	["DragonBloodVine_100Yr"] = {
		Id = "DragonBloodVine_100Yr",
		Name = "100-Yr Dragon Blood Vine",
		Description = "Thick century dragon-scale vine with intense incendiary energy.",
		Rarity = "Epic",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 100,
		Icon = UIAssets.Icons.DragonBloodVine,
	},
	["GaleWindLotus_1Yr"] = {
		Id = "GaleWindLotus_1Yr",
		Name = "1-Yr Gale Wind Lotus",
		Description = "Pale teal floating lotus petal with soft wind currents.",
		Rarity = "Common",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1,
		Icon = UIAssets.Icons.GaleWindLotus,
	},
	["GaleWindLotus_100Yr"] = {
		Id = "GaleWindLotus_100Yr",
		Name = "100-Yr Gale Wind Lotus",
		Description = "Deep blue century lotus blooming with ethereal wind energy.",
		Rarity = "Rare",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 100,
		Icon = UIAssets.Icons.GaleWindLotus,
	},
	["CelestialDew"] = {
		Id = "CelestialDew",
		Name = "Celestial Dew Water",
		Description = "Pure luminescent spirit water gathered from celestial mountain springs.",
		Rarity = "Uncommon",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1,
		Icon = UIAssets.Icons.CelestialDew,
	},
	["DemonBeastCore"] = {
		Id = "DemonBeastCore",
		Name = "Demon Beast Core",
		Description = "A crystallized amber core containing distilled monster energy.",
		Rarity = "Rare",
		Type = "Material",
		MaxStack = 50,
		AgeYears = 10,
		Icon = UIAssets.Icons.DemonBeastCore,
	},
	["SpiritAsh"] = {
		Id = "SpiritAsh",
		Name = "Furnace Ash",
		Description = "Charcoal residue from a failed alchemy refinement.",
		Rarity = "Common",
		Type = "Material",
		MaxStack = 99,
		Icon = UIAssets.Icons.SpiritAsh,
	},

	-- WEAPONS & EQUIPMENT
	["FlyingSwordItem"] = {
		Id = "FlyingSwordItem",
		Name = "Azure Cloud Flying Sword",
		Description = "An elegant flying sword capable of rapid Qi slashes and aerial dash strikes.",
		Rarity = "Uncommon",
		Type = "Weapon",
		MaxStack = 1,
		Stats = { Damage = 15, Speed = 1.0 },
	},
	["GauntletItem"] = {
		Id = "GauntletItem",
		Name = "Ironclad Spirit Gauntlets",
		Description = "Heavy martial gauntlets that channel earth-shattering Qi punches.",
		Rarity = "Common",
		Type = "Weapon",
		MaxStack = 1,
		Stats = { Damage = 18, Speed = 0.8 },
	},
	["SpearItem"] = {
		Id = "SpearItem",
		Name = "Serpent Qi Spear",
		Description = "A long-reaching spear built for piercing lunges.",
		Rarity = "Common",
		Type = "Weapon",
		MaxStack = 1,
		Stats = { Damage = 20, Speed = 0.9 },
	},
}

function ItemConfig.GetItem(itemId: string): ItemDefinition?
	return ITEMS[itemId]
end

function ItemConfig.GetAllItems(): { [string]: ItemDefinition }
	return ITEMS
end

return ItemConfig