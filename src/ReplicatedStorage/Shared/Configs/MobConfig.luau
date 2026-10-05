--!strict
--[[
    MobConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MobConfig.luau
    Shared configuration dictionary for mob definitions, zone assignments, stats, and drop tables.
]]

local MobConfig = {}

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

local MOBS: { [string]: MobDefinition } = {
	["RogueDisciple"] = {
		Id = "RogueDisciple",
		Name = "Rogue Initiate",
		DisplayName = "Rogue Initiate",
		MaxHealth = 80,
		BaseDamage = 12,
		WalkSpeed = 14,
		AttackRange = 5.0,
		AttackCooldown = 1.8,
		AggroRadius = 30,
		RespawnTime = 15,
		BaseSpiritStones = 12,
		BaseQiReward = 30,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.60, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore", Chance = 0.35, MinCount = 1, MaxCount = 1 },
		},
	},

	["BanditCultivator"] = {
		Id = "BanditCultivator",
		Name = "Bandit Cultivator",
		DisplayName = "Bandit Cultivator",
		MaxHealth = 120,
		BaseDamage = 18,
		WalkSpeed = 13,
		AttackRange = 5.5,
		AttackCooldown = 2.0,
		AggroRadius = 28,
		RespawnTime = 20,
		BaseSpiritStones = 18,
		BaseQiReward = 45,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.70, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DemonBeastCore", Chance = 0.40, MinCount = 1, MaxCount = 1 },
		},
	},

	["CorruptedIronGuard"] = {
		Id = "CorruptedIronGuard",
		Name = "Corrupted Iron Guard",
		DisplayName = "Corrupted Iron Guard",
		MaxHealth = 250,
		BaseDamage = 32,
		WalkSpeed = 11,
		AttackRange = 6.0,
		AttackCooldown = 2.2,
		AggroRadius = 25,
		RespawnTime = 30,
		BaseSpiritStones = 35,
		BaseQiReward = 90,
		DropTable = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.30, MinCount = 1, MaxCount = 1 },
		},
	},

	["GhostBladeMarauder"] = {
		Id = "GhostBladeMarauder",
		Name = "Ghost Blade Marauder",
		DisplayName = "Ghost Blade Marauder",
		MaxHealth = 180,
		BaseDamage = 45,
		WalkSpeed = 16,
		AttackRange = 5.0,
		AttackCooldown = 1.4,
		AggroRadius = 35,
		RespawnTime = 25,
		BaseSpiritStones = 40,
		BaseQiReward = 110,
		DropTable = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.55, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DragonBloodVine_10Yr", Chance = 0.25, MinCount = 1, MaxCount = 1 },
		},
	},

	["BloodShadowAssassin"] = {
		Id = "BloodShadowAssassin",
		Name = "Blood Shadow Assassin",
		DisplayName = "Blood Shadow Assassin",
		MaxHealth = 350,
		BaseDamage = 70,
		WalkSpeed = 17,
		AttackRange = 5.0,
		AttackCooldown = 1.2,
		AggroRadius = 40,
		RespawnTime = 45,
		BaseSpiritStones = 75,
		BaseQiReward = 220,
		DropTable = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.80, MinCount = 2, MaxCount = 4 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	["FallenInnerProdigy"] = {
		Id = "FallenInnerProdigy",
		Name = "Fallen Inner Prodigy",
		DisplayName = "Fallen Inner Prodigy",
		MaxHealth = 600,
		BaseDamage = 110,
		WalkSpeed = 15,
		AttackRange = 6.0,
		AttackCooldown = 1.5,
		AggroRadius = 45,
		RespawnTime = 60,
		BaseSpiritStones = 140,
		BaseQiReward = 450,
		DropTable = {
			{ ItemId = "SpiritGrass_100Yr", Chance = 0.40, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.25, MinCount = 1, MaxCount = 1 },
		},
	},

	["FrostPeakApostle"] = {
		Id = "FrostPeakApostle",
		Name = "Frost Peak Apostle",
		DisplayName = "Frost Peak Apostle",
		MaxHealth = 1000,
		BaseDamage = 160,
		WalkSpeed = 14,
		AttackRange = 6.0,
		AttackCooldown = 1.6,
		AggroRadius = 45,
		RespawnTime = 90,
		BaseSpiritStones = 250,
		BaseQiReward = 850,
		DropTable = {
			{ ItemId = "GaleWindLotus_100Yr", Chance = 0.35, MinCount = 1, MaxCount = 1 },
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.35, MinCount = 1, MaxCount = 2 },
		},
	},

	["VoidPhantomSwordmaster"] = {
		Id = "VoidPhantomSwordmaster",
		Name = "Void Phantom Swordmaster",
		DisplayName = "Void Phantom Swordmaster",
		MaxHealth = 1600,
		BaseDamage = 240,
		WalkSpeed = 18,
		AttackRange = 7.0,
		AttackCooldown = 1.1,
		AggroRadius = 50,
		RespawnTime = 120,
		BaseSpiritStones = 450,
		BaseQiReward = 1600,
		DropTable = {
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.60, MinCount = 2, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_100Yr", Chance = 0.30, MinCount = 1, MaxCount = 1 },
		},
	},

	["Boss_FallenSwordGenius"] = {
		Id = "Boss_FallenSwordGenius",
		Name = "Sword Fiend Patriarch",
		DisplayName = "Sword Fiend Patriarch",
		MaxHealth = 2500,
		BaseDamage = 120,
		WalkSpeed = 16,
		AttackRange = 8.0,
		AttackCooldown = 1.0,
		AggroRadius = 60,
		RespawnTime = 300,
		BaseSpiritStones = 500,
		BaseQiReward = 2000,
		IsBoss = true,
		DropTable = {
			{ ItemId = "DemonBeastCore_10Yr", Chance = 1.00, MinCount = 2, MaxCount = 4 },
			{ ItemId = "DemonBeastCore_1000Yr", Chance = 0.20, MinCount = 1, MaxCount = 1 },
		},
	},

	["AsuraSwordSovereign"] = {
		Id = "AsuraSwordSovereign",
		Name = "Asura Sword Sovereign",
		DisplayName = "Asura Sword Sovereign",
		MaxHealth = 12000,
		BaseDamage = 480,
		WalkSpeed = 19,
		AttackRange = 10.0,
		AttackCooldown = 0.8,
		AggroRadius = 80,
		RespawnTime = 900,
		BaseSpiritStones = 3000,
		BaseQiReward = 10000,
		IsBoss = true,
		DropTable = {
			{ ItemId = "DemonBeastCore_1000Yr", Chance = 1.00, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_1000Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "GaleWindLotus_1000Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- 3D MONSTERS & BEASTS
	-- =========================================================================
	["IronTuskBoar"] = {
		Id = "IronTuskBoar",
		Name = "Iron-Tusk Spirit Boar",
		DisplayName = "Iron-Tusk Spirit Boar",
		MaxHealth = 1200,
		BaseDamage = 45,
		WalkSpeed = 16,
		AttackRange = 6.0,
		AttackCooldown = 1.8,
		AggroRadius = 30,
		RespawnTime = 15,
		BaseSpiritStones = 35,
		BaseQiReward = 85,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.75, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DemonBeastCore", Chance = 0.60, MinCount = 1, MaxCount = 2 },
		},
	},
}

function MobConfig.GetMob(mobId: string): MobDefinition?
	return MOBS[mobId]
end

function MobConfig.GetMobConfig(mobId: string): MobDefinition?
	return MOBS[mobId]
end

MobConfig.Mobs = MOBS

return MobConfig