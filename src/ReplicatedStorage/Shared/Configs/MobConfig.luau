--!strict
--[[
    MobConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MobConfig.luau
    Authoritative enemy templates, zone distribution, combat stats,
    and 4-tier wilderness drops (including graded beast cores for Alchemy).
]]

export type MobDropItem = {
	ItemId: string,
	Chance: number,
	MinCount: number,
	MaxCount: number,
}

export type MobDefinition = {
	Id: string,
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

	["DemonWolf"] = {
		Id = "DemonWolf",
		DisplayName = "Wilderness Demon Wolf",
		MaxHealth = 550,
		BaseDamage = 40,
		WalkSpeed = 18,
		AttackRange = 5.5,
		AttackCooldown = 1.3,
		AggroRadius = 30,
		RespawnTime = 15,
		BaseSpiritStones = 25,
		BaseQiReward = 65,
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.40, MinCount = 1, MaxCount = 2 },
		},
	},

	["IronhideBoar"] = {
		Id = "IronhideBoar",
		DisplayName = "Ironhide Boar",
		MaxHealth = 800,
		BaseDamage = 55,
		WalkSpeed = 12,
		AttackRange = 5.0,
		AttackCooldown = 2.0,
		AggroRadius = 20,
		RespawnTime = 18,
		BaseSpiritStones = 40,
		BaseQiReward = 90,
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.70, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_1Yr", Chance = 0.35, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- TIER 2: MISTY BAMBOO WILDERNESS (Foundation Establishment & Golden Core)
	-- =========================================================================
	["BloodShadowAssassin"] = {
		Id = "BloodShadowAssassin",
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

	["CorruptedIronGuard"] = {
		Id = "CorruptedIronGuard",
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

	["SilverbackFrostApe"] = {
		Id = "SilverbackFrostApe",
		DisplayName = "Silverback Frost Ape (Decade Beast)",
		MaxHealth = 14000,
		BaseDamage = 450,
		WalkSpeed = 16,
		AttackRange = 6.5,
		AttackCooldown = 1.4,
		AggroRadius = 35,
		RespawnTime = 30,
		BaseSpiritStones = 250,
		BaseQiReward = 600,
		DropTable = {
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.85, MinCount = 2, MaxCount = 4 },
			{ ItemId = "GaleWindLotus_10Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 3: DEMON BURIAL VALLEY (Nascent Soul to Void Refining)
	-- =========================================================================
	["FallenInnerProdigy"] = {
		Id = "FallenInnerProdigy",
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

	["VoidChasmChimera"] = {
		Id = "VoidChasmChimera",
		DisplayName = "Void Chasm Chimera (Century Beast)",
		MaxHealth = 450000,
		BaseDamage = 6500,
		WalkSpeed = 20,
		AttackRange = 7.5,
		AttackCooldown = 1.1,
		AggroRadius = 50,
		RespawnTime = 60,
		BaseSpiritStones = 2000,
		BaseQiReward = 5000,
		IsBoss = true,
		DropTable = {
			{ ItemId = "DemonBeastCore_100Yr", Chance = 1.0, MinCount = 5, MaxCount = 10 },
			{ ItemId = "DragonBloodVine_100Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "GaleWindLotus_100Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- TIER 4: CELESTIAL ABYSS (Body Integration to Immortal Ascension)
	-- =========================================================================
	["Boss_FallenSwordGenius"] = {
		Id = "Boss_FallenSwordGenius",
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

	["AbyssalDemonSovereign"] = {
		Id = "AbyssalDemonSovereign",
		DisplayName = "Abyssal Demon Sovereign (Millennium World Boss)",
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