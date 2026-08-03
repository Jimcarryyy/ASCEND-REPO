--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Master database registering item definitions, categories, rarities,
    UIAssets icon mappings, stack limits, and on-use stat recovery values.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

export type ItemCategory = "Consumable" | "Weapon" | "Herb" | "Material" | "Currency"
export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Immortal"

export type ItemData = {
	Id: string,
	Name: string,
	Description: string,
	Category: ItemCategory,
	Rarity: ItemRarity,
	Icon: string,
	MaxStack: number,
	
	-- Consumable Recovery Properties
	HealAmount: number?,
	QiAmount: number?,
	BuffDuration: number?,

	-- Weapon Equipment Key
	WeaponType: string?, -- "FlyingSword", "Gauntlet", "Spear"
}

local ItemConfig: { [string]: ItemData } = {
	-- 💊 SPIRIT PILLS & CONSUMABLES
	SpiritHealingDan = {
		Id = "SpiritHealingDan",
		Name = "Spirit Healing Dan",
		Description = "A refined green pill infused with life Qi. Restores 60 HP immediately.",
		Category = "Consumable",
		Rarity = "Uncommon",
		Icon = UIAssets.Currencies.PillQiGathering,
		MaxStack = 20,
		HealAmount = 60,
		QiAmount = 0,
	},
	FoundationGatheringDan = {
		Id = "FoundationGatheringDan",
		Name = "Foundation Gathering Dan",
		Description = "A glowing blue pill that condenses spiritual energy into the Danfield. Restores 100 Spirit Qi.",
		Category = "Consumable",
		Rarity = "Rare",
		Icon = UIAssets.Currencies.PillQiGathering,
		MaxStack = 20,
		HealAmount = 0,
		QiAmount = 100,
	},
	ImmortalQiPill = {
		Id = "ImmortalQiPill",
		Name = "Immortal Qi Pill",
		Description = "A legendary breakthrough pill created from heavenly herbs. Restores 200 Spirit Qi and 100 HP.",
		Category = "Consumable",
		Rarity = "Legendary",
		Icon = UIAssets.Currencies.PillBreakthrough,
		MaxStack = 10,
		HealAmount = 100,
		QiAmount = 200,
	},

	-- 🌿 HERBS & ALCHEMY INGREDIENTS
	SpiritGrass = {
		Id = "SpiritGrass",
		Name = "Nine-Leaf Spirit Grass",
		Description = "Abundant wild grass absorbing world Qi. Primary ingredient for basic spirit pills.",
		Category = "Herb",
		Rarity = "Common",
		Icon = UIAssets.Currencies.HerbGinseng,
		MaxStack = 99,
	},
	DragonLotus = {
		Id = "DragonLotus",
		Name = "Crimson Dragon Lotus",
		Description = "A rare ginseng herb growing near fiery spirit veins. Essential for high-tier alchemy.",
		Category = "Herb",
		Rarity = "Rare",
		Icon = UIAssets.Currencies.HerbGinseng,
		MaxStack = 50,
	},

	-- 💎 CURRENCIES & MATERIALS
	SpiritStoneLow = {
		Id = "SpiritStoneLow",
		Name = "Low-Grade Spirit Stone",
		Description = "Crystalline stone containing low-density world Qi. Standard currency for trading and cultivating.",
		Category = "Currency",
		Rarity = "Common",
		Icon = UIAssets.Currencies.SpiritStoneLow,
		MaxStack = 999,
	},
	SpiritStoneHigh = {
		Id = "SpiritStoneHigh",
		Name = "High-Grade Spirit Stone",
		Description = "Pure concentrated spirit crystal. Highly valued by high-tier cultivators and elders.",
		Category = "Currency",
		Rarity = "Epic",
		Icon = UIAssets.Currencies.SpiritStoneHigh,
		MaxStack = 999,
	},
	DemonCore = {
		Id = "DemonCore",
		Name = "Wild Demon Beast Core",
		Description = "The inner core of a slain spirit beast. Used as a high-grade catalyst for alchemy crafting.",
		Category = "Material",
		Rarity = "Rare",
		Icon = UIAssets.Currencies.DemonCore,
		MaxStack = 50,
	},

	-- ⚔️ WEAPON EQUIPMENT
	FlyingSwordItem = {
		Id = "FlyingSwordItem",
		Name = "Azure Flying Sword",
		Description = "A balanced flying sword forged from spiritual iron. Enables long-range sword art skills.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
	},
	GauntletItem = {
		Id = "GauntletItem",
		Name = "Dragon Core Gauntlets",
		Description = "Heavy martial arts gauntlets infused with dragon marrow. Enables explosive CQC skills.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.Gauntlet,
		MaxStack = 1,
		WeaponType = "Gauntlet",
	},
	SpearItem = {
		Id = "SpearItem",
		Name = "Jade Dragon Spear",
		Description = "A long polearm spear designed for sweeping thrusts and aerial meteor slams.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.Spear,
		MaxStack = 1,
		WeaponType = "Spear",
	},
}

return ItemConfig