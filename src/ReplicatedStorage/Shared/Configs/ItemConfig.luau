--!strict
--[[
    ItemConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
    Master database registering all 16 Cultivation Equipment Sets (32 Items Total)
    ranging from Common Mortal Steel to Mythic Tribulation Artifacts.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

export type ItemCategory = "Consumable" | "Weapon" | "Herb" | "Material" | "Currency"
export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary" | "Mythic"
export type WeaponArchetype = "Physical" | "Flame" | "Void" | "Dragon" | "Thunder"

export type StatBonusData = {
	MaxHP: number?,
	DefPercent: number?,
	QiRegen: number?,
	AttackPower: number?,
	CritRate: number?,
}

export type ItemData = {
	Id: string,
	Name: string,
	Description: string,
	Category: ItemCategory,
	Rarity: ItemRarity,
	Icon: string?,
	MaxStack: number?,
	
	-- Consumable Recovery
	HealAmount: number?,
	QiAmount: number?,

	-- Weapon Equipment Properties
	WeaponType: string?, -- "FlyingSword", "BackArmor"
	ModelName: string?,
	Archetype: WeaponArchetype?,
	PrimaryColor: Color3?,
	GripOffset: CFrame?,
	StatBonus: StatBonusData?,
}

local ItemConfig: { [string]: ItemData } = {

	-- ============================================================================
	-- ⚪ 1. COMMON TIER (Mortal Steel — Physical Archetype)
	-- ============================================================================
	COMMON_IRON_SWORD = {
		Id = "COMMON_IRON_SWORD",
		Name = "Mortal Iron Sword (凡品铁剑)",
		Description = "A basic sword forged from mortal iron by village blacksmiths.",
		Category = "Weapon",
		Rarity = "Common",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Mortal Iron Sword",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(255, 255, 255), -- #FFFFFF
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 15, CritRate = 0.02 },
	},
	COMMON_IRON_CREST = {
		Id = "COMMON_IRON_CREST",
		Name = "Mortal Iron Crest (凡品铁背铠)",
		Description = "A simple iron crest array offering basic physical protection.",
		Category = "Weapon",
		Rarity = "Common",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Mortal Iron Crest",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(255, 255, 255),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 50, DefPercent = 0.02, QiRegen = 0.5 },
	},

	-- ============================================================================
	-- 🟢 2. UNCOMMON TIER (Refined Spirit-Steel — Physical/Qi Archetype)
	-- ============================================================================
	UNCOMMON_STEEL_SWORD = {
		Id = "UNCOMMON_STEEL_SWORD",
		Name = "Refined Spirit-Steel Sword (精炼灵钢剑)",
		Description = "Forged from spirit steel tempered in mountain spring Qi.",
		Category = "Weapon",
		Rarity = "Uncommon",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Refined Spirit-Steel Sword",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(56, 229, 77), -- #38E54D
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 45, CritRate = 0.05 },
	},
	UNCOMMON_STEEL_CREST = {
		Id = "UNCOMMON_STEEL_CREST",
		Name = "Refined Spirit-Steel Crest (精炼灵钢背铠)",
		Description = "A sturdy spirit-steel back armor refined by junior sect elders.",
		Category = "Weapon",
		Rarity = "Uncommon",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Refined Spirit-Steel Crest",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(56, 229, 77),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 150, DefPercent = 0.05, QiRegen = 1.0 },
	},

	-- ============================================================================
	-- 🔵 3. RARE TIER (5 Skin Variations — Foundation Establishment Scale)
	-- ============================================================================
	RARE_AZURE_JADE_SWORD = {
		Id = "RARE_AZURE_JADE_SWORD",
		Name = "Azure Spirit-Jade Sword (碧蓝灵玉剑)",
		Description = "Carved from translucent azure spirit jade.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Azure Spirit-Jade Sword",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(33, 146, 255), -- #2192FF
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 110, CritRate = 0.08 },
	},
	RARE_AZURE_JADE_CREST = {
		Id = "RARE_AZURE_JADE_CREST",
		Name = "Azure Spirit-Jade Crest (碧蓝灵铠)",
		Description = "A glowing azure jade back array hovering behind the cultivator.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Azure Spirit-Jade Crest",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(33, 146, 255),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 400, DefPercent = 0.08, QiRegen = 2.5 },
	},

	RARE_CRIMSON_FLAME_SWORD = {
		Id = "RARE_CRIMSON_FLAME_SWORD",
		Name = "Crimson Flame Spirit Sword (赤炎灵剑)",
		Description = "Infused with molten spirit fire from fiery mountain veins.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Crimson Flame Spirit Sword",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(255, 77, 77), -- #FF4D4D
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 125, CritRate = 0.10 },
	},
	RARE_CRIMSON_FLAME_CREST = {
		Id = "RARE_CRIMSON_FLAME_CREST",
		Name = "Crimson Flame Spirit Crest (赤炎灵铠)",
		Description = "A burning red spirit crest array casting warmth on the bearer.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Crimson Flame Spirit Crest",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(255, 77, 77),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 450, DefPercent = 0.09, QiRegen = 3.0 },
	},

	RARE_GLACIAL_FROST_SWORD = {
		Id = "RARE_GLACIAL_FROST_SWORD",
		Name = "Glacial Frost Spirit Sword (寒冰灵剑)",
		Description = "Forged in arctic spirit springs, emitting cold frost mist.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Glacial Frost Spirit Sword",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(0, 229, 255), -- #00E5FF
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 120, CritRate = 0.09 },
	},
	RARE_GLACIAL_FROST_CREST = {
		Id = "RARE_GLACIAL_FROST_CREST",
		Name = "Glacial Frost Spirit Crest (寒冰灵铠)",
		Description = "A frosty back crest array glittering like arctic ice.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Glacial Frost Spirit Crest",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(0, 229, 255),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 420, DefPercent = 0.10, QiRegen = 2.8 },
	},

	RARE_GOLDEN_THUNDER_SWORD = {
		Id = "RARE_GOLDEN_THUNDER_SWORD",
		Name = "Golden Thunder Spirit Sword (金雷灵剑)",
		Description = "Pulsing with golden lightning bolts from thunder cloud veins.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Golden Thunder Spirit Sword",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(255, 193, 7), -- #FFC107
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 130, CritRate = 0.12 },
	},
	RARE_GOLDEN_THUNDER_CREST = {
		Id = "RARE_GOLDEN_THUNDER_CREST",
		Name = "Golden Thunder Spirit Crest (金雷灵铠)",
		Description = "A crackling golden thunder crest array shielding the back.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Golden Thunder Spirit Crest",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(255, 193, 7),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 480, DefPercent = 0.08, QiRegen = 3.2 },
	},

	RARE_SHADOW_SLATE_SWORD = {
		Id = "RARE_SHADOW_SLATE_SWORD",
		Name = "Shadow Slate Spirit Sword (玄岩灵剑)",
		Description = "Heavy dark stone sword infused with mountain vein density.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Shadow Slate Spirit Sword",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(100, 116, 139), -- #64748B
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 140, CritRate = 0.06 },
	},
	RARE_SHADOW_SLATE_CREST = {
		Id = "RARE_SHADOW_SLATE_CREST",
		Name = "Shadow Slate Spirit Crest (玄岩灵铠)",
		Description = "A dense dark slate back array providing heavy poise defense.",
		Category = "Weapon",
		Rarity = "Rare",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Shadow Slate Spirit Crest",
		Archetype = "Physical",
		PrimaryColor = Color3.fromRGB(100, 116, 139),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 600, DefPercent = 0.15, QiRegen = 2.0 },
	},

	-- ============================================================================
	-- 🟣 4. EPIC TIER (In-Game Bounties — Golden Core Scale)
	-- ============================================================================
	EPIC_SAKURA_SWORD = {
		Id = "EPIC_SAKURA_SWORD",
		Name = "Sakura Blossom Blade (樱花灵剑)",
		Description = "Leaves behind a trail of glowing rose-pink spirit petals with every swing.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Sakura Blossom Blade",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(236, 72, 153), -- #EC4899
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 280, CritRate = 0.15 },
	},
	EPIC_SAKURA_CREST = {
		Id = "EPIC_SAKURA_CREST",
		Name = "Sakura Blossom Back Crest (樱花灵铠)",
		Description = "A pink petal crest array surrounding the cultivator in fragrance.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Sakura Blossom Back Crest",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(236, 72, 153),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 1200, DefPercent = 0.15, QiRegen = 5.0 },
	},

	EPIC_LIGHT_SWORD = {
		Id = "EPIC_LIGHT_SWORD",
		Name = "Radiant Light Blade (圣光灵剑)",
		Description = "Radiates holy white-gold light that purifies evil Qi.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Radiant Light Blade",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(245, 158, 11), -- #F59E0B
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 300, CritRate = 0.18 },
	},
	EPIC_LIGHT_CREST = {
		Id = "EPIC_LIGHT_CREST",
		Name = "Radiant Light Back Crest (圣光灵铠)",
		Description = "A luminous white-gold crest array emanating holy light.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Radiant Light Back Crest",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(245, 158, 11),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 1350, DefPercent = 0.18, QiRegen = 6.0 },
	},

	EPIC_SHADOW_SWORD = {
		Id = "EPIC_SHADOW_SWORD",
		Name = "Shadow Void Blade (暗影灵剑)",
		Description = "Forged in abyssal dark Qi, slicing through light and shadow.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Shadow Void Blade",
		Archetype = "Void",
		PrimaryColor = Color3.fromRGB(139, 92, 246), -- #8B5CF6
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 320, CritRate = 0.20 },
	},
	EPIC_SHADOW_CREST = {
		Id = "EPIC_SHADOW_CREST",
		Name = "Shadow Void Back Crest (暗影灵铠)",
		Description = "An abyssal purple back array absorbing surrounding light.",
		Category = "Weapon",
		Rarity = "Epic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Shadow Void Back Crest",
		Archetype = "Void",
		PrimaryColor = Color3.fromRGB(139, 92, 246),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 1400, DefPercent = 0.20, QiRegen = 7.0 },
	},

	-- ============================================================================
	-- 🟡 5. LEGENDARY TIER (Shop / Gamepass — Nascent Soul Scale)
	-- ============================================================================
	LEGENDARY_GOLD_DRAGON_SWORD = {
		Id = "LEGENDARY_GOLD_DRAGON_SWORD",
		Name = "Sovereign Gold Dragon Sword (金龙圣剑)",
		Description = "A sacred imperial golden blade carved with dragon scales.",
		Category = "Weapon",
		Rarity = "Legendary",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Sovereign Gold Dragon Sword",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(255, 215, 0), -- #FFD700
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 650, CritRate = 0.22 },
	},
	LEGENDARY_GOLD_DRAGON_CREST = {
		Id = "LEGENDARY_GOLD_DRAGON_CREST",
		Name = "Sovereign Gold Dragon Crest (金龙背铠)",
		Description = "An imperial gold 4-piece dragon crest array radiating sacred light.",
		Category = "Weapon",
		Rarity = "Legendary",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Sovereign Gold Dragon Crest",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(255, 215, 0),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 2800, DefPercent = 0.22, QiRegen = 10.0 },
	},

	LEGENDARY_THUNDER_SWORD = {
		Id = "LEGENDARY_THUNDER_SWORD",
		Name = "Celestial Thunder Sovereign Sword (霄雷圣剑)",
		Description = "Forged from sky thunderbolts, crackling with intense cyan storm energy.",
		Category = "Weapon",
		Rarity = "Legendary",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Celestial Thunder Sovereign Sword",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(0, 229, 255), -- #00E5FF
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 700, CritRate = 0.25 },
	},
	LEGENDARY_THUNDER_CREST = {
		Id = "LEGENDARY_THUNDER_CREST",
		Name = "Celestial Thunder Sovereign Crest (霄雷背铠)",
		Description = "A cyan storm crest array crackling with lightning bolts.",
		Category = "Weapon",
		Rarity = "Legendary",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Celestial Thunder Sovereign Crest",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(0, 229, 255),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 3000, DefPercent = 0.25, QiRegen = 12.0 },
	},

	-- ============================================================================
	-- 🔴 6. MYTHIC TIER (Shop Exclusive / 5-Blade Array — Spirit Severing Scale)
	-- ============================================================================
	MYTHIC_HEAVENLY_VOID_SWORD = {
		Id = "MYTHIC_HEAVENLY_VOID_SWORD",
		Name = "Heavenly Void Sword (天虚剑)",
		Description = "An ancient deep purple cosmic blade slicing through dimensions.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Heavenly Void Sword",
		Archetype = "Void",
		PrimaryColor = Color3.fromRGB(147, 51, 234), -- #9333EA
		GripOffset = CFrame.new(-0.2, 0.5, -0.5) * CFrame.Angles(math.rad(45), math.rad(-90), math.rad(90)),
		StatBonus = { AttackPower = 1200, CritRate = 0.30 },
	},
	MYTHIC_HEAVENLY_VOID_CREST = {
		Id = "MYTHIC_HEAVENLY_VOID_CREST",
		Name = "Heavenly Void Crest Array (天虚背铠)",
		Description = "A 5-blade cosmic space array hovering in a dimensional rift behind the bearer.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Heavenly Void Crest Array",
		Archetype = "Void",
		PrimaryColor = Color3.fromRGB(147, 51, 234),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 5000, DefPercent = 0.30, QiRegen = 15.0 },
	},

	MYTHIC_SUN_SLAYER_SWORD = {
		Id = "MYTHIC_SUN_SLAYER_SWORD",
		Name = "Sun-Slayer Crimson Sword (斩日红莲剑)",
		Description = "A divine magma sword forged from golden sun core iron.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Sun-Slayer Crimson Sword",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(239, 68, 68), -- #EF4444
		GripOffset = CFrame.new(-2.7, 0.8, 0) * CFrame.Angles(math.rad(90), math.rad(-110), math.rad(90)),
		StatBonus = { AttackPower = 1250, CritRate = 0.30 },
	},
	MYTHIC_SUN_SLAYER_CREST = {
		Id = "MYTHIC_SUN_SLAYER_CREST",
		Name = "Sun-Slayer Crimson Crest Array (斩日背铠)",
		Description = "A radiant sovereign magma crest array floating behind the cultivator.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Sun-Slayer Crimson Crest Array",
		Archetype = "Flame",
		PrimaryColor = Color3.fromRGB(239, 68, 68),
		GripOffset = CFrame.new(0, 2.0, 1.2) * CFrame.Angles(0.1, 0, 0),
		StatBonus = { MaxHP = 5200, DefPercent = 0.30, QiRegen = 15.0 },
	},

	MYTHIC_NINE_DRAGON_SWORD = {
		Id = "MYTHIC_NINE_DRAGON_SWORD",
		Name = "Nine-Dragon Sovereign Sword (九龙帝尊剑)",
		Description = "Infused with nine emerald dragon spirits commanding wind and jade.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Nine-Dragon Sovereign Sword",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(16, 185, 129), -- #10B981
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 1300, CritRate = 0.32 },
	},
	MYTHIC_NINE_DRAGON_CREST = {
		Id = "MYTHIC_NINE_DRAGON_CREST",
		Name = "Nine-Dragon Sovereign Crest Array (九龙背铠)",
		Description = "An emerald dragon array whirling with perpetual wind vortexes.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Nine-Dragon Sovereign Crest Array",
		Archetype = "Dragon",
		PrimaryColor = Color3.fromRGB(16, 185, 129),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 5500, DefPercent = 0.32, QiRegen = 18.0 },
	},

	MYTHIC_FROST_DRAGON_SWORD = {
		Id = "MYTHIC_FROST_DRAGON_SWORD",
		Name = "Frost-Dragon Flared Sword (冰龙霜华剑)",
		Description = "Carved from absolute zero arctic ice core, freezing ambient air on touch.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "FlyingSword",
		ModelName = "Frost-Dragon Flared Sword",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(6, 182, 212), -- #06B6D4
		GripOffset = CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0),
		StatBonus = { AttackPower = 1280, CritRate = 0.35 },
	},
	MYTHIC_FROST_DRAGON_CREST = {
		Id = "MYTHIC_FROST_DRAGON_CREST",
		Name = "Frost-Dragon Flared Crest Array (冰龙背铠)",
		Description = "A 5-blade glacial ice array surrounded by falling frost crystals.",
		Category = "Weapon",
		Rarity = "Mythic",
		Icon = UIAssets.Weapons.FlyingSword,
		MaxStack = 1,
		WeaponType = "BackArmor",
		ModelName = "Frost-Dragon Flared Crest Array",
		Archetype = "Thunder",
		PrimaryColor = Color3.fromRGB(6, 182, 212),
		GripOffset = CFrame.new(0, 2.0, 1.2),
		StatBonus = { MaxHP = 5400, DefPercent = 0.35, QiRegen = 16.0 },
	},
}

return ItemConfig