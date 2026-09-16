--!strict
--[[
    MobConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MobConfig.luau
    Authoritative enemy templates, zone distribution, combat stats,
    and 4-tier wilderness drops (including graded beast cores for Alchemy).
    100% Pure Humanoid Cultivator roster (Beasts purged).
]]

export type MobDropItem = {
	ItemId: string,
	Chance: number,
	MinCount: number,
	MaxCount: number,
}

export type MobDefinition = {
	Id: string,
	Name: string?,
	DisplayName: string,
	MaxHealth: number,
	BaseDamage: number,
	WalkSpeed: number,
	AttackRange: number,
	AttackCooldown: number,
	AggroRadius: number,
	RespawnTime: number,
	BaseSpiritStones: number,
	BaseQiReward: number,
	IsBoss: boolean?,
	DropTable: { MobDropItem },
}

local MobConfig = {}

local MOBS: { [string]: MobDefinition } = {
	-- =========================================================================
	-- TIER 1: OUTER DISCIPLE GROUNDS (Qi Condensation)
	-- =========================================================================
	["RogueDisciple"] = {
		Id = "RogueDisciple",
		Name = "Rogue Initiate",
		DisplayName = "Rogue Initiate",
		MaxHealth = 350,
		BaseDamage = 25,
		WalkSpeed = 14,
		AttackRange = 5.0,
		AttackCooldown = 1.6,
		AggroRadius = 24,
		RespawnTime = 12,
		BaseSpiritStones = 15,
		BaseQiReward = 40,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.60, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritHealingDan", Chance = 0.15, MinCount = 1, MaxCount = 1 },
		},
	},

	["BanditCultivator"] = {
		Id = "BanditCultivator",
		Name = "Bandit Cultivator",
		DisplayName = "Bandit Cultivator",
		MaxHealth = 550,
		BaseDamage = 40,
		WalkSpeed = 16,
		AttackRange = 5.5,
		AttackCooldown = 1.4,
		AggroRadius = 28,
		RespawnTime = 15,
		BaseSpiritStones = 25,
		BaseQiReward = 65,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.70, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 2: MISTY BAMBOO WILDERNESS (Foundation Establishment)
	-- =========================================================================
	["CorruptedIronGuard"] = {
		Id = "CorruptedIronGuard",
		Name = "Corrupted Iron Guard",
		DisplayName = "Corrupted Iron Guard",
		MaxHealth = 8000,
		BaseDamage = 280,
		WalkSpeed = 13,
		AttackRange = 6.0,
		AttackCooldown = 1.8,
		AggroRadius = 28,
		RespawnTime = 25,
		BaseSpiritStones = 200,
		BaseQiReward = 500,
		DropTable = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.70, MinCount = 2, MaxCount = 3 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.65, MinCount = 1, MaxCount = 2 },
		},
	},

	["GhostBladeMarauder"] = {
		Id = "GhostBladeMarauder",
		Name = "Ghost Blade Marauder",
		DisplayName = "Ghost Blade Marauder",
		MaxHealth = 12000,
		BaseDamage = 380,
		WalkSpeed = 17,
		AttackRange = 6.0,
		AttackCooldown = 1.4,
		AggroRadius = 32,
		RespawnTime = 25,
		BaseSpiritStones = 220,
		BaseQiReward = 550,
		DropTable = {
			{ ItemId = "DragonBloodVine_10Yr", Chance = 0.60, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.60, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 3: GOLDEN CORE
	-- =========================================================================
	["BloodShadowAssassin"] = {
		Id = "BloodShadowAssassin",
		Name = "Blood Shadow Assassin",
		DisplayName = "Blood Shadow Assassin",
		MaxHealth = 2500,
		BaseDamage = 120,
		WalkSpeed = 19,
		AttackRange = 5.0,
		AttackCooldown = 1.2,
		AggroRadius = 32,
		RespawnTime = 20,
		BaseSpiritStones = 120,
		BaseQiReward = 280,
		DropTable = {
			{ ItemId = "DragonBloodVine_10Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.45, MinCount = 1, MaxCount = 1 },
		},
	},

	["Boss_FallenSwordGenius"] = {
		Id = "Boss_FallenSwordGenius",
		Name = "Sword Fiend Patriarch",
		DisplayName = "Sword Fiend Patriarch",
		MaxHealth = 2500000,
		BaseDamage = 25000,
		WalkSpeed = 20,
		AttackRange = 8.0,
		AttackCooldown = 1.0,
		AggroRadius = 60,
		RespawnTime = 180,
		BaseSpiritStones = 15000,
		BaseQiReward = 45000,
		IsBoss = true,
		DropTable = {
			{ ItemId = "DemonBeastCore_1000Yr", Chance = 0.90, MinCount = 5, MaxCount = 10 },
			{ ItemId = "SpiritGrass_1000Yr", Chance = 0.70, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 4: NASCENT SOUL
	-- =========================================================================
	["FallenInnerProdigy"] = {
		Id = "FallenInnerProdigy",
		Name = "Fallen Inner Prodigy",
		DisplayName = "Fallen Inner Prodigy",
		MaxHealth = 65000,
		BaseDamage = 1200,
		WalkSpeed = 17,
		AttackRange = 6.0,
		AttackCooldown = 1.3,
		AggroRadius = 40,
		RespawnTime = 45,
		BaseSpiritStones = 800,
		BaseQiReward = 2200,
		DropTable = {
			{ ItemId = "SpiritGrass_100Yr", Chance = 0.55, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.75, MinCount = 2, MaxCount = 4 },
		},
	},

	-- =========================================================================
	-- TIER 5: SPIRIT SEVERING
	-- =========================================================================
	["FrostPeakApostle"] = {
		Id = "FrostPeakApostle",
		Name = "Frost Peak Apostle",
		DisplayName = "Frost Peak Apostle",
		MaxHealth = 180000,
		BaseDamage = 3200,
		WalkSpeed = 18,
		AttackRange = 6.5,
		AttackCooldown = 1.2,
		AggroRadius = 42,
		RespawnTime = 50,
		BaseSpiritStones = 1400,
		BaseQiReward = 3800,
		DropTable = {
			{ ItemId = "GaleWindLotus_100Yr", Chance = 0.65, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.80, MinCount = 2, MaxCount = 4 },
		},
	},

	-- =========================================================================
	-- TIER 6: VOID REFINING
	-- =========================================================================
	["VoidPhantomSwordmaster"] = {
		Id = "VoidPhantomSwordmaster",
		Name = "Void Phantom Swordmaster",
		DisplayName = "Void Phantom Swordmaster",
		MaxHealth = 450000,
		BaseDamage = 6500,
		WalkSpeed = 20,
		AttackRange = 7.5,
		AttackCooldown = 1.1,
		AggroRadius = 50,
		RespawnTime = 60,
		BaseSpiritStones = 2000,
		BaseQiReward = 5000,
		DropTable = {
			{ ItemId = "DemonBeastCore_100Yr", Chance = 1.0, MinCount = 5, MaxCount = 10 },
			{ ItemId = "DragonBloodVine_100Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 8-10: MAHAYANA / TRANSGENDENT WORLD BOSS
	-- =========================================================================
	["AsuraSwordSovereign"] = {
		Id = "AsuraSwordSovereign",
		Name = "Asura Sword Sovereign",
		DisplayName = "Asura Sword Sovereign",
		MaxHealth = 25000000,
		BaseDamage = 200000,
		WalkSpeed = 22,
		AttackRange = 9.0,
		AttackCooldown = 0.9,
		AggroRadius = 75,
		RespawnTime = 300,
		BaseSpiritStones = 50000,
		BaseQiReward = 150000,
		IsBoss = true,
		DropTable = {
			{ ItemId = "DemonBeastCore_1000Yr", Chance = 1.0, MinCount = 15, MaxCount = 30 },
			{ ItemId = "SpiritGrass_1000Yr", Chance = 0.80, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_1000Yr", Chance = 0.80, MinCount = 1, MaxCount = 3 },
			{ ItemId = "GaleWindLotus_1000Yr", Chance = 0.80, MinCount = 1, MaxCount = 3 },
		},
	},
}

function MobConfig.GetMob(mobId: string): MobDefinition?
	return MOBS[mobId]
end

function MobConfig.GetAllMobs(): { [string]: MobDefinition }
	return MOBS
end

function MobConfig.RollDropTable(mobId: string): { { ItemId: string, Count: number } }
	local def = MOBS[mobId]
	if not def then return {} end

	local dropped: { { ItemId: string, Count: number } } = {}

	for _, entry in ipairs(def.DropTable) do
		if math.random() <= entry.Chance then
			local count = math.random(entry.MinCount, entry.MaxCount)
			table.insert(dropped, { ItemId = entry.ItemId, Count = count })
		end
	end

	return dropped
end

return MobConfig