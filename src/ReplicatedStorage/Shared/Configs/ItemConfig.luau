--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Central configuration repository for all items in ASCEND:
    - 8 Sword Tiers (Mortal, Azure Cloud, Flowing Qi, Verdant Jade, Violet Soul, Void Star, Azure Patriarch, Radiant Immortal)
    - Dynamic Weapon VFX Color Palettes (Primary, Secondary, Glow, and Particle Gradient)
    - Full Alchemy Pills, Herbs & Monster Materials
]]

local UIAssets = require(script.Parent.UIAssets)

export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic" | "Divine" | "Immortal" | "Celestial"
export type ItemType = "Weapon" | "Consumable" | "Material" | "Currency" | "Crest"

export type WeaponVFXPalette = {
	PrimaryColor: Color3,
	SecondaryColor: Color3,
	GlowColor: Color3,
	Gradient: ColorSequence,
}

export type ItemDefinition = {
	Id: string,
	Name: string,
	Description: string,
	Rarity: ItemRarity,
	Type: ItemType,
	MaxStack: number,
	AgeYears: number?,
	Damage: number?,
	Stats: { [string]: number }?,
	Icon: string?,
}

local ItemConfig = {}

-- =============================================================================
-- WEAPON ELEMENTAL VFX COLOR PALETTES
-- =============================================================================
local WEAPON_PALETTES: { [string]: WeaponVFXPalette } = {
	["MortalIronJian"] = {
		PrimaryColor = Color3.fromRGB(220, 225, 235),
		SecondaryColor = Color3.fromRGB(140, 150, 165),
		GlowColor = Color3.fromRGB(200, 215, 230),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(245, 248, 255)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(200, 210, 225)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 135, 150)),
		}),
	},
	["AzureCloudDiscipleJian"] = {
		PrimaryColor = Color3.fromRGB(56, 189, 248),
		SecondaryColor = Color3.fromRGB(14, 116, 144),
		GlowColor = Color3.fromRGB(125, 211, 252),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(224, 242, 254)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(56, 189, 248)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(14, 116, 144)),
		}),
	},
	["FlowingQiSpiritSword"] = {
		PrimaryColor = Color3.fromRGB(14, 165, 233),
		SecondaryColor = Color3.fromRGB(3, 105, 161),
		GlowColor = Color3.fromRGB(56, 189, 248),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(186, 230, 253)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(14, 165, 233)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(3, 105, 161)),
		}),
	},
	["VerdantJadeFlyingSword"] = {
		PrimaryColor = Color3.fromRGB(52, 211, 153),
		SecondaryColor = Color3.fromRGB(5, 150, 105),
		GlowColor = Color3.fromRGB(110, 231, 183),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(209, 250, 229)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(52, 211, 153)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(4, 120, 87)),
		}),
	},
	["VioletSoulSovereignJian"] = {
		PrimaryColor = Color3.fromRGB(192, 132, 252),
		SecondaryColor = Color3.fromRGB(126, 34, 206),
		GlowColor = Color3.fromRGB(216, 180, 254),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(245, 200, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(180, 50, 255)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(90, 10, 160)),
		}),
	},
	["VoidStarCleaverDao"] = {
		PrimaryColor = Color3.fromRGB(168, 85, 247),
		SecondaryColor = Color3.fromRGB(88, 28, 135),
		GlowColor = Color3.fromRGB(147, 51, 234),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 190, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(147, 51, 234)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(59, 7, 100)),
		}),
	},
	["AzurePatriarchHeritageJian"] = {
		PrimaryColor = Color3.fromRGB(34, 211, 238),
		SecondaryColor = Color3.fromRGB(14, 116, 144),
		GlowColor = Color3.fromRGB(103, 232, 249),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(207, 250, 254)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(34, 211, 238)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(8, 145, 178)),
		}),
	},
	["RadiantImmortalSovereignJian"] = {
		PrimaryColor = Color3.fromRGB(250, 204, 21),
		SecondaryColor = Color3.fromRGB(217, 119, 6),
		GlowColor = Color3.fromRGB(254, 240, 138),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(254, 249, 195)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(250, 204, 21)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(180, 83, 9)),
		}),
	},
}

local DEFAULT_PALETTE: WeaponVFXPalette = WEAPON_PALETTES["MortalIronJian"]

function ItemConfig.GetWeaponPalette(weaponId: string?): WeaponVFXPalette
	if not weaponId then return DEFAULT_PALETTE end
	return WEAPON_PALETTES[weaponId] or DEFAULT_PALETTE
end

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

	-- =========================================================================
	-- WEAPONS & FLYING SWORDS (TIERS 1 - 8)
	-- =========================================================================
	["MortalIronJian"] = {
		Id = "MortalIronJian",
		Name = "Mortal Iron Jian",
		Description = "A beginner cultivator's mortal forged straight sword. Sturdy, reliable, and grounded in iron discipline.",
		Rarity = "Common",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 15,
		Stats = { Damage = 15, Speed = 1.0 },
	},
	["AzureCloudDiscipleJian"] = {
		Id = "AzureCloudDiscipleJian",
		Name = "Azure Cloud Disciple Jian",
		Description = "Official initiate straight sword of the Azure Cloud Sect, engraved with flowing cloud qi runes.",
		Rarity = "Uncommon",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 25,
		Stats = { Damage = 25, Speed = 1.0 },
	},
	["FlowingQiSpiritSword"] = {
		Id = "FlowingQiSpiritSword",
		Name = "Flowing Qi Spirit Sword",
		Description = "A refined spirit sword forged from deep sapphire crystal, channeling swirling currents of immortal wind qi.",
		Rarity = "Rare",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 40,
		Stats = { Damage = 40, Speed = 1.1 },
	},
	["VerdantJadeFlyingSword"] = {
		Id = "VerdantJadeFlyingSword",
		Name = "Verdant Jade Flying Sword",
		Description = "An exquisite flying sword carved from imperial spirit emerald jade, humming with vital life-force qi.",
		Rarity = "Epic",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 60,
		Stats = { Damage = 60, Speed = 1.15 },
	},
	["VioletSoulSovereignJian"] = {
		Id = "VioletSoulSovereignJian",
		Name = "Violet Soul Sovereign Jian",
		Description = "A legendary Jian forged from deep amethyst soul crystal, pulsating with an ethereal purple mist.",
		Rarity = "Legendary",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 120,
		Stats = { Damage = 120, Speed = 1.2 },
	},
	["VoidStarCleaverDao"] = {
		Id = "VoidStarCleaverDao",
		Name = "Void Star Cleaver Dao",
		Description = "A heavy cosmic saber forged from fallen meteorite, gleaming with stardust constellations.",
		Rarity = "Mythic",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 220,
		Stats = { Damage = 220, Speed = 1.25 },
	},
	["AzurePatriarchHeritageJian"] = {
		Id = "AzurePatriarchHeritageJian",
		Name = "Azure Patriarch Heritage Jian",
		Description = "An ancient ancestral straight sword handed down across millennia, humming with divine wind intent.",
		Rarity = "Divine",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 450,
		Stats = { Damage = 450, Speed = 1.35 },
	},
	["RadiantImmortalSovereignJian"] = {
		Id = "RadiantImmortalSovereignJian",
		Name = "Radiant Immortal Sovereign Jian",
		Description = "A supreme celestial blade radiating blinding solar light, pure lightning arcs, and immortal Dao power.",
		Rarity = "Immortal",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 1000,
		Stats = { Damage = 1000, Speed = 1.5 },
	},
}

function ItemConfig.GetItem(itemId: string): ItemDefinition?
	return ITEMS[itemId]
end

function ItemConfig.GetAllItems(): { [string]: ItemDefinition }
	return ITEMS
end

return ItemConfig