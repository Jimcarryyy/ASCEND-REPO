--!strict
--[[
    MobConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MobConfig.luau
    Authoritative configuration repository for all mobs, beasts, and bosses in ASCEND:
      - RogueDisciple: Common swarm cultivator (1.0x)
      - BloodShadowAssassin: High-speed stealth flanker (0.92x)
      - CorruptedIronGuard: Heavy tank brute (1.35x)
      - FallenInnerProdigy: Tactical elite mini-boss (1.20x)
      - Boss_FallenSwordGenius: Former prodigy fallen to the demonic path (1.28x World Boss)
      - DemonWolf & IronhideBoar: Zone 1 wilderness beasts
]]

export type DropEntry = {
	ItemId: string,
	Chance: number,
	MinCount: number?,
	MaxCount: number?,
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
	DropTable: { DropEntry },
}

local MobConfig = {}

local MOBS: { [string]: MobDefinition } = {
	-- =========================================================================
	-- 1. BASE SWARM: Corrupted Outer Disciple
	-- =========================================================================
	["RogueDisciple"] = {
		Id = "RogueDisciple",
		DisplayName = "Corrupted Outer Disciple",
		MaxHealth = 350,
		BaseDamage = 25,
		WalkSpeed = 15,
		AttackRange = 5.5,
		AttackCooldown = 1.35,
		AggroRadius = 32,
		RespawnTime = 18,
		BaseSpiritStones = 15,
		BaseQiReward = 35,
		DropTable = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritHealingDan", Chance = 0.20, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- 2. AGILITY FLANKER: Blood Shadow Assassin
	-- =========================================================================
	["BloodShadowAssassin"] = {
		Id = "BloodShadowAssassin",
		DisplayName = "Blood Shadow Assassin",
		MaxHealth = 260,
		BaseDamage = 32,
		WalkSpeed = 22, -- High-speed rush
		AttackRange = 4.8,
		AttackCooldown = 0.95, -- Fast attack cadence
		AggroRadius = 38,
		RespawnTime = 22,
		BaseSpiritStones = 25,
		BaseQiReward = 50,
		DropTable = {
			{ ItemId = "DragonBloodVine_1Yr", Chance = 0.40, MinCount = 1, MaxCount = 2 },
			{ ItemId = "GaleWindDan", Chance = 0.18, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- 3. HEAVY BRUTE: Corrupted Iron Guard
	-- =========================================================================
	["CorruptedIronGuard"] = {
		Id = "CorruptedIronGuard",
		DisplayName = "Corrupted Iron Guard",
		MaxHealth = 1250,
		BaseDamage = 65,
		WalkSpeed = 12, -- Slow, heavy relentless advance
		AttackRange = 6.2,
		AttackCooldown = 1.70,
		AggroRadius = 28,
		RespawnTime = 30,
		BaseSpiritStones = 60,
		BaseQiReward = 120,
		DropTable = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.35, MinCount = 1, MaxCount = 2 },
			{ ItemId = "PhysiqueTemperingDan", Chance = 0.25, MinCount = 1, MaxCount = 1 },
			{ ItemId = "DemonBeastCore", Chance = 0.15, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- 4. FIELD MINI-BOSS: Senior Brother Bai (Fallen Prodigy)
	-- =========================================================================
	["FallenInnerProdigy"] = {
		Id = "FallenInnerProdigy",
		DisplayName = "Senior Brother Bai (Fallen)",
		MaxHealth = 3500,
		BaseDamage = 110,
		WalkSpeed = 18,
		AttackRange = 5.8,
		AttackCooldown = 1.15,
		AggroRadius = 45,
		RespawnTime = 60,
		BaseSpiritStones = 200,
		BaseQiReward = 450,
		IsBoss = true,
		DropTable = {
			{ ItemId = "SpiritGrass_100Yr", Chance = 0.30, MinCount = 1, MaxCount = 1 },
			{ ItemId = "FoundationGatheringDan", Chance = 0.25, MinCount = 1, MaxCount = 1 },
			{ ItemId = "FlowingQiSpiritSword", Chance = 0.08, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- 5. WORLD BOSS: Fallen Sword Genius - Mo Chen
	-- =========================================================================
	["Boss_FallenSwordGenius"] = {
		Id = "Boss_FallenSwordGenius",
		DisplayName = "Fallen Sword Genius - Mo Chen",
		MaxHealth = 28000,
		BaseDamage = 220,
		WalkSpeed = 20, -- Swift and lethal
		AttackRange = 5.8,
		AttackCooldown = 1.10,
		AggroRadius = 65,
		RespawnTime = 240, -- 4-minute world respawn
		BaseSpiritStones = 1500,
		BaseQiReward = 3500,
		IsBoss = true,
		DropTable = {
			{ ItemId = "SpiritGrass_1000Yr", Chance = 0.25, MinCount = 1, MaxCount = 1 },
			{ ItemId = "DemonBeastCore", Chance = 0.85, MinCount = 2, MaxCount = 5 },
			{ ItemId = "VioletSoulSovereignJian", Chance = 0.08, MinCount = 1, MaxCount = 1 },
		},
	},

	-- =========================================================================
	-- WILDERNESS BEASTS (ZONE 1 FORESTS & MOUNTAINS)
	-- =========================================================================
	["DemonWolf"] = {
		Id = "DemonWolf",
		DisplayName = "Shadow Wind Wolf",
		MaxHealth = 550,
		BaseDamage = 40,
		WalkSpeed = 18,
		AttackRange = 4.5,
		AttackCooldown = 1.1,
		AggroRadius = 35,
		RespawnTime = 20,
		BaseSpiritStones = 30,
		BaseQiReward = 65,
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.60, MinCount = 1, MaxCount = 2 },
			{ ItemId = "DragonBloodVine_1Yr", Chance = 0.45, MinCount = 1, MaxCount = 2 },
		},
	},

	["IronhideBoar"] = {
		Id = "IronhideBoar",
		DisplayName = "Wild Ironhide Boar",
		MaxHealth = 800,
		BaseDamage = 55,
		WalkSpeed = 12,
		AttackRange = 5.0,
		AttackCooldown = 1.6,
		AggroRadius = 25,
		RespawnTime = 25,
		BaseSpiritStones = 45,
		BaseQiReward = 80,
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.70, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.35, MinCount = 1, MaxCount = 1 },
		},
	},
}

function MobConfig.GetMobConfig(mobId: string): MobDefinition?
	return MOBS[mobId]
end

function MobConfig.GetMob(mobId: string): MobDefinition?
	return MOBS[mobId]
end

function MobConfig.GetAllMobs(): { [string]: MobDefinition }
	return MOBS
end

MobConfig.Mobs = MOBS

return MobConfig