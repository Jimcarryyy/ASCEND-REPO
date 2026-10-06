--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Central configuration repository for all items in ASCEND:
    - 10 Canonical Weapons (NewWeapons Roster) with Dynamic Weapon VFX Color Palettes
    - 9 Major Realm Breakthrough Dans
    - 4-Tier Herb Ladder (1-Yr, 10-Yr, 100-Yr, 1000-Yr)
    - 4-Tier Graded Beast Cores (Base, 10-Yr, 100-Yr, 1000-Yr)
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

local WEAPON_PALETTES: { [string]: WeaponVFXPalette } = {
	-- 1. Iron Reed (Common Dao)
	["IronReed"] = {
		PrimaryColor = Color3.fromRGB(200, 215, 210),
		SecondaryColor = Color3.fromRGB(130, 145, 140),
		GlowColor = Color3.fromRGB(180, 200, 190),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(240, 245, 242)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(185, 205, 198)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(115, 130, 125)),
		}),
	},
	-- 2. Bronze Discipline (Common Cutlass)
	["BronzeDiscipline"] = {
		PrimaryColor = Color3.fromRGB(205, 127, 50),
		SecondaryColor = Color3.fromRGB(140, 80, 30),
		GlowColor = Color3.fromRGB(225, 155, 80),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(250, 210, 160)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(205, 127, 50)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(120, 65, 25)),
		}),
	},
	-- 3. Earthbound Steel (Uncommon Jian)
	["EarthboundSteel"] = {
		PrimaryColor = Color3.fromRGB(80, 180, 130),
		SecondaryColor = Color3.fromRGB(40, 110, 80),
		GlowColor = Color3.fromRGB(120, 210, 160),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(215, 250, 230)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(80, 180, 130)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(30, 90, 65)),
		}),
	},
	-- 4. Wandering Blade (Uncommon Jian)
	["WanderingBlade"] = {
		PrimaryColor = Color3.fromRGB(100, 180, 220),
		SecondaryColor = Color3.fromRGB(50, 110, 150),
		GlowColor = Color3.fromRGB(150, 210, 240),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(220, 242, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(100, 180, 220)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(35, 85, 120)),
		}),
	},
	-- 5. Crane Amidst Clouds (Rare Dao)
	["CraneAmidstClouds"] = {
		PrimaryColor = Color3.fromRGB(230, 245, 255),
		SecondaryColor = Color3.fromRGB(100, 160, 210),
		GlowColor = Color3.fromRGB(200, 230, 255),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 255, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(170, 215, 245)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(80, 140, 190)),
		}),
	},
	-- 6. Resonant Heart (Rare Jian)
	["ResonantHeart"] = {
		PrimaryColor = Color3.fromRGB(14, 165, 233),
		SecondaryColor = Color3.fromRGB(3, 105, 161),
		GlowColor = Color3.fromRGB(56, 189, 248),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(186, 230, 253)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(14, 165, 233)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(3, 105, 161)),
		}),
	},
	-- 7. Hollow Moon (Epic Cutlass)
	["HollowMoon"] = {
		PrimaryColor = Color3.fromRGB(192, 132, 252),
		SecondaryColor = Color3.fromRGB(107, 33, 168),
		GlowColor = Color3.fromRGB(216, 180, 254),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(245, 225, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(180, 110, 245)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(85, 20, 140)),
		}),
	},
	-- 8. Ascendant Gold (Epic Jian)
	["AscendantGold"] = {
		PrimaryColor = Color3.fromRGB(250, 204, 21),
		SecondaryColor = Color3.fromRGB(180, 83, 9),
		GlowColor = Color3.fromRGB(254, 240, 138),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(254, 249, 195)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(250, 204, 21)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(160, 70, 8)),
		}),
	},
	-- 9. Void Purity (Legendary Dao)
	["VoidPurity"] = {
		PrimaryColor = Color3.fromRGB(168, 85, 247),
		SecondaryColor = Color3.fromRGB(88, 28, 135),
		GlowColor = Color3.fromRGB(147, 51, 234),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(235, 190, 255)),
			ColorSequenceKeypoint.new(0.35, Color3.fromRGB(147, 51, 234)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(59, 7, 100)),
		}),
	},
	-- 10. Heaven-Piercing (Legendary Jian)
	["HeavenPiercing"] = {
		PrimaryColor = Color3.fromRGB(255, 220, 100),
		SecondaryColor = Color3.fromRGB(220, 38, 38),
		GlowColor = Color3.fromRGB(255, 245, 180),
		Gradient = ColorSequence.new({
			ColorSequenceKeypoint.new(0.0, Color3.fromRGB(255, 250, 215)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 195, 60)),
			ColorSequenceKeypoint.new(1.0, Color3.fromRGB(185, 25, 25)),
		}),
	},
}

-- Studio Model Name Aliases for VFX Palettes
WEAPON_PALETTES["1.Iron Reed"]           = WEAPON_PALETTES["IronReed"]
WEAPON_PALETTES["2.Bronze Discipline"]   = WEAPON_PALETTES["BronzeDiscipline"]
WEAPON_PALETTES["3.Earthbound Steel"]    = WEAPON_PALETTES["EarthboundSteel"]
WEAPON_PALETTES["4.Wandering Blade"]     = WEAPON_PALETTES["WanderingBlade"]
WEAPON_PALETTES["5.Crane Amidst Clouds"] = WEAPON_PALETTES["CraneAmidstClouds"]
WEAPON_PALETTES["6.Resonant Heart"]      = WEAPON_PALETTES["ResonantHeart"]
WEAPON_PALETTES["7.Hollow Moon"]         = WEAPON_PALETTES["HollowMoon"]
WEAPON_PALETTES["8.Ascendant Gold"]      = WEAPON_PALETTES["AscendantGold"]
WEAPON_PALETTES["9.Void Purity"]         = WEAPON_PALETTES["VoidPurity"]
WEAPON_PALETTES["10.Heaven-Piercing"]    = WEAPON_PALETTES["HeavenPiercing"]

-- Legacy Palette Compatibility
WEAPON_PALETTES["MortalIronJian"]               = WEAPON_PALETTES["IronReed"]
WEAPON_PALETTES["AzureCloudDiscipleJian"]       = WEAPON_PALETTES["EarthboundSteel"]
WEAPON_PALETTES["FlowingQiSpiritSword"]         = WEAPON_PALETTES["ResonantHeart"]
WEAPON_PALETTES["VerdantJadeFlyingSword"]       = WEAPON_PALETTES["WanderingBlade"]
WEAPON_PALETTES["VioletSoulSovereignJian"]      = WEAPON_PALETTES["HollowMoon"]
WEAPON_PALETTES["VoidStarCleaverDao"]           = WEAPON_PALETTES["VoidPurity"]
WEAPON_PALETTES["AzurePatriarchHeritageJian"]   = WEAPON_PALETTES["CraneAmidstClouds"]
WEAPON_PALETTES["RadiantImmortalSovereignJian"] = WEAPON_PALETTES["HeavenPiercing"]

local DEFAULT_PALETTE: WeaponVFXPalette = WEAPON_PALETTES["IronReed"]

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

	-- BREAKTHROUGH DANS FOR MAJOR REALM ASCENSIONS
	["GoldenCoreDan"] = {
		Id = "GoldenCoreDan",
		Name = "Golden Core Dan",
		Description = "A radiant solar elixir required to condense the liquid Dantian into an indestructible Golden Core.",
		Rarity = "Epic",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 1000, QiGrant = 1500 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["NascentSoulDan"] = {
		Id = "NascentSoulDan",
		Name = "Nascent Soul Dan",
		Description = "Elixir of spiritual birth. Nourishes the primordial infant soul within the Dantian.",
		Rarity = "Legendary",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 2500, QiGrant = 4000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["SpiritSeveringDan"] = {
		Id = "SpiritSeveringDan",
		Name = "Spirit Severing Dan",
		Description = "Elixir forged with divine intent to sever mortal attachments and shatter inner demons.",
		Rarity = "Legendary",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 5000, QiGrant = 10000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["VoidRefiningDan"] = {
		Id = "VoidRefiningDan",
		Name = "Void Refining Dan",
		Description = "Distilled from spatial void essence. Calms meridian chaos when merging with the cosmos.",
		Rarity = "Mythic",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 12000, QiGrant = 25000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["BodyIntegrationDan"] = {
		Id = "BodyIntegrationDan",
		Name = "Body Integration Dan",
		Description = "Elixir that fuses the immortal spirit and the physical flesh into an unyielding celestial vessel.",
		Rarity = "Mythic",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 30000, QiGrant = 60000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["MahayanaDan"] = {
		Id = "MahayanaDan",
		Name = "Mahayana Dan",
		Description = "The supreme elixir of Great Ascension Dao. Harmonizes the inner sea of Qi with heavenly laws.",
		Rarity = "Divine",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 75000, QiGrant = 150000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["TribulationTranscendingDan"] = {
		Id = "TribulationTranscendingDan",
		Name = "Tribulation Transcending Dan",
		Description = "Immortal elixir that anchors the soul against the wrath of the 9-Wave Heavenly Tribulation.",
		Rarity = "Immortal",
		Type = "Consumable",
		MaxStack = 5,
		Stats = { HealAmount = 200000, QiGrant = 500000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},
	["ImmortalAscensionDan"] = {
		Id = "ImmortalAscensionDan",
		Name = "Immortal Ascension Dan",
		Description = "The legendary pinnacle elixir of the mortal realms. Stabilizes the immortal Dao body for true godhood.",
		Rarity = "Celestial",
		Type = "Consumable",
		MaxStack = 1,
		Stats = { HealAmount = 1000000, QiGrant = 2000000 },
		Icon = UIAssets.Icons.FoundationGatheringDan,
	},

	-- 4-TIER HERBS & MATERIALS
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
	["DragonBloodVine_10Yr"] = {
		Id = "DragonBloodVine_10Yr",
		Name = "10-Yr Dragon Blood Vine",
		Description = "Thick decade dragon vine coursing with warm draconic blood qi.",
		Rarity = "Uncommon",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 10,
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
	["DragonBloodVine_1000Yr"] = {
		Id = "DragonBloodVine_1000Yr",
		Name = "1,000-Yr Sovereign Dragon Blood Vine",
		Description = "Ancient dragon vein that soaked in true ancient dragon blood for a millennium.",
		Rarity = "Mythic",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1000,
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
	["GaleWindLotus_10Yr"] = {
		Id = "GaleWindLotus_10Yr",
		Name = "10-Yr Gale Wind Lotus",
		Description = "Decade wind lotus swirling with concentrated tempest qi.",
		Rarity = "Uncommon",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 10,
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
	["GaleWindLotus_1000Yr"] = {
		Id = "GaleWindLotus_1000Yr",
		Name = "1,000-Yr Sovereign Gale Wind Lotus",
		Description = "Millennium tempest flower that only blooms upon sky mountain peaks.",
		Rarity = "Mythic",
		Type = "Material",
		MaxStack = 99,
		AgeYears = 1000,
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

	-- 4-TIER GRADED DEMON BEAST CORES
	["DemonBeastCore"] = {
		Id = "DemonBeastCore",
		Name = "Demon Beast Core (Mortal Grade)",
		Description = "A crystallized amber core containing distilled monster energy.",
		Rarity = "Common",
		Type = "Material",
		MaxStack = 50,
		AgeYears = 1,
		Icon = UIAssets.Icons.DemonBeastCore,
	},
	["DemonBeastCore_10Yr"] = {
		Id = "DemonBeastCore_10Yr",
		Name = "Decade Demon Beast Core (Earth Grade)",
		Description = "A pulsating jade beast core harvested from decade-tier wilderness monsters.",
		Rarity = "Uncommon",
		Type = "Material",
		MaxStack = 50,
		AgeYears = 10,
		Icon = UIAssets.Icons.DemonBeastCore,
	},
	["DemonBeastCore_100Yr"] = {
		Id = "DemonBeastCore_100Yr",
		Name = "Century Demon Beast Core (Supreme Grade)",
		Description = "A radiant amethyst monster core radiating violent century monster essence.",
		Rarity = "Rare",
		Type = "Material",
		MaxStack = 50,
		AgeYears = 100,
		Icon = UIAssets.Icons.DemonBeastCore,
	},
	["DemonBeastCore_1000Yr"] = {
		Id = "DemonBeastCore_1000Yr",
		Name = "Millennium Sovereign Core (Transcendent Grade)",
		Description = "An immortal demonic heart crystal forged through a thousand years of slaughter.",
		Rarity = "Legendary",
		Type = "Material",
		MaxStack = 50,
		AgeYears = 1000,
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
	-- 10 CANONICAL WEAPONS (NewWeapons Roster)
	-- =========================================================================
	["IronReed"] = {
		Id = "IronReed",
		Name = "Iron Reed",
		Description = "A flexible mortal-forged Dao resembling a hardy river reed. Balanced for foundational blade katas.",
		Rarity = "Common",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 15,
		Stats = { Damage = 15, Speed = 1.0 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["BronzeDiscipline"] = {
		Id = "BronzeDiscipline",
		Name = "Bronze Discipline",
		Description = "A heavy, curved bronze cutlass forged under strict martial discipline to instill endurance and poise.",
		Rarity = "Common",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 18,
		Stats = { Damage = 18, Speed = 1.0 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["EarthboundSteel"] = {
		Id = "EarthboundSteel",
		Name = "Earthbound Steel",
		Description = "A double-edged Jian folded from dense terrestrial iron. Anchors the wielder's stance firmly to the earth.",
		Rarity = "Uncommon",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 25,
		Stats = { Damage = 25, Speed = 1.05 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["WanderingBlade"] = {
		Id = "WanderingBlade",
		Name = "Wandering Blade",
		Description = "A slender straight sword carried by itinerant vagabond cultivators across mountain ranges.",
		Rarity = "Uncommon",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 30,
		Stats = { Damage = 30, Speed = 1.05 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["CraneAmidstClouds"] = {
		Id = "CraneAmidstClouds",
		Name = "Crane Amidst Clouds",
		Description = "A graceful spirit Dao etched with soaring crane talismans, cutting the air like feathers through mist.",
		Rarity = "Rare",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 45,
		Stats = { Damage = 45, Speed = 1.10 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["ResonantHeart"] = {
		Id = "ResonantHeart",
		Name = "Resonant Heart",
		Description = "A refined spirit Jian pulsating in sync with the cultivator's heartbeat, sharpening focus and sword intent.",
		Rarity = "Rare",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 55,
		Stats = { Damage = 55, Speed = 1.10 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["HollowMoon"] = {
		Id = "HollowMoon",
		Name = "Hollow Moon",
		Description = "An ethereal curved cutlass bathed in cold lunar luminescence, slicing through defenses without resistance.",
		Rarity = "Epic",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 75,
		Stats = { Damage = 75, Speed = 1.15 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["AscendantGold"] = {
		Id = "AscendantGold",
		Name = "Ascendant Gold",
		Description = "An imperial auric Jian imbued with concentrated solar Qi, leaving searing radiant arcs in its wake.",
		Rarity = "Epic",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 95,
		Stats = { Damage = 95, Speed = 1.15 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["VoidPurity"] = {
		Id = "VoidPurity",
		Name = "Void Purity",
		Description = "A supreme Dao forged from deep space starmetal, cleanly severing mortal karmic ties with quiet void intent.",
		Rarity = "Legendary",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 135,
		Stats = { Damage = 135, Speed = 1.20 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
	["HeavenPiercing"] = {
		Id = "HeavenPiercing",
		Name = "Heaven-Piercing",
		Description = "The pinnacle Jian of the sovereign realms, capable of sundering thunder tribulations and piercing celestial firmaments.",
		Rarity = "Legendary",
		Type = "Weapon",
		MaxStack = 1,
		Damage = 160,
		Stats = { Damage = 160, Speed = 1.25 },
		Icon = UIAssets.Icons.SwordPlaceholder,
	},
}

-- Aliases for Studio Folder Model Names
ITEMS["1.Iron Reed"]           = ITEMS["IronReed"]
ITEMS["2.Bronze Discipline"]   = ITEMS["BronzeDiscipline"]
ITEMS["3.Earthbound Steel"]    = ITEMS["EarthboundSteel"]
ITEMS["4.Wandering Blade"]     = ITEMS["WanderingBlade"]
ITEMS["5.Crane Amidst Clouds"] = ITEMS["CraneAmidstClouds"]
ITEMS["6.Resonant Heart"]      = ITEMS["ResonantHeart"]
ITEMS["7.Hollow Moon"]         = ITEMS["HollowMoon"]
ITEMS["8.Ascendant Gold"]      = ITEMS["AscendantGold"]
ITEMS["9.Void Purity"]         = ITEMS["VoidPurity"]
ITEMS["10.Heaven-Piercing"]    = ITEMS["HeavenPiercing"]

-- Legacy ID Compatibility Aliases
ITEMS["MortalIronJian"]               = ITEMS["IronReed"]
ITEMS["AzureCloudDiscipleJian"]       = ITEMS["EarthboundSteel"]
ITEMS["FlowingQiSpiritSword"]         = ITEMS["ResonantHeart"]
ITEMS["VerdantJadeFlyingSword"]       = ITEMS["WanderingBlade"]
ITEMS["VioletSoulSovereignJian"]      = ITEMS["HollowMoon"]
ITEMS["VoidStarCleaverDao"]           = ITEMS["VoidPurity"]
ITEMS["AzurePatriarchHeritageJian"]   = ITEMS["CraneAmidstClouds"]
ITEMS["RadiantImmortalSovereignJian"] = ITEMS["HeavenPiercing"]

function ItemConfig.GetItem(itemId: string): ItemDefinition?
	return ITEMS[itemId]
end

function ItemConfig.GetAllItems(): { [string]: ItemDefinition }
	return ITEMS
end

return ItemConfig