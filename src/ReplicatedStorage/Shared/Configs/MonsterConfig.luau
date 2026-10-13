--!strict
--[[
    MonsterConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MonsterConfig.luau
    Authoritative configuration for Non-Humanoid Monsters.
    Updates:
      - Distinct Stroll vs Sprint speeds (Slow WalkSpeed = 12, Fast Aggro RunSpeed = 38).
      - Expanded AggroRadius to 50 studs so boars spot players from afar and charge.
]]

export type MonsterDropItem = {
	ItemId: string,
	Chance: number,
	MinCount: number,
	MaxCount: number,
}

export type MonsterDefinition = {
	Id: string,
	DisplayName: string,
	Zone: "Wilderness" | "Magma" | "Ice",
	MaxHealth: number,
	MaxPosture: number,
	BaseDamage: number,
	WalkSpeed: number,
	RunSpeed: number,
	AttackRange: number,
	AttackCooldown: number,
	AggroRadius: number,
	RespawnTime: number,
	BaseSpiritStones: number,
	BaseQiReward: number,
	AIPattern: string,
	DropTable: { MonsterDropItem },
}

local MonsterConfig = {}

local MONSTERS: { [string]: MonsterDefinition } = {
	-- =========================================================================
	-- WILDERNESS ZONE
	-- =========================================================================
	["Iron-Tusk Spirit Boar"] = {
		Id = "Iron-Tusk Spirit Boar",
		DisplayName = "Iron-Tusk Spirit Boar",
		Zone = "Wilderness",
		MaxHealth = 22000,
		MaxPosture = 260,
		BaseDamage = 580,
		WalkSpeed = 12, -- Slow, calm strolling pace
		RunSpeed = 38,  -- Fast, aggressive charge when glimpse of player
		AttackRange = 8.5,
		AttackCooldown = 1.4,
		AggroRadius = 50,
		RespawnTime = 18,
		BaseSpiritStones = 450,
		BaseQiReward = 1100,
		AIPattern = "ArmoredTank",
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.60, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	["Wilderness Spirit Wolf"] = {
		Id = "Wilderness Spirit Wolf",
		DisplayName = "Wilderness Spirit Wolf",
		Zone = "Wilderness",
		MaxHealth = 1800,
		MaxPosture = 80,
		BaseDamage = 55,
		WalkSpeed = 14,
		RunSpeed = 36,
		AttackRange = 7.0,
		AttackCooldown = 1.2,
		AggroRadius = 45,
		RespawnTime = 18,
		BaseSpiritStones = 45,
		BaseQiReward = 100,
		AIPattern = "PackHunter",
		DropTable = {
			{ ItemId = "DemonBeastCore", Chance = 0.65, MinCount = 1, MaxCount = 2 },
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.40, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- MAGMA ZONE
	-- =========================================================================
	["Magma Hound"] = {
		Id = "Magma Hound",
		DisplayName = "Magma Hound",
		Zone = "Magma",
		MaxHealth = 14000,
		MaxPosture = 140,
		BaseDamage = 420,
		WalkSpeed = 14,
		RunSpeed = 36,
		AttackRange = 7.0,
		AttackCooldown = 1.0,
		AggroRadius = 45,
		RespawnTime = 25,
		BaseSpiritStones = 300,
		BaseQiReward = 750,
		AIPattern = "FlankingStalker",
		DropTable = {
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.70, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_10Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
		},
	},

	["Obsidian Lava-Boar"] = {
		Id = "Obsidian Lava-Boar",
		DisplayName = "Obsidian Lava-Boar",
		Zone = "Magma",
		MaxHealth = 22000,
		MaxPosture = 260,
		BaseDamage = 580,
		WalkSpeed = 12,
		RunSpeed = 38,
		AttackRange = 8.5,
		AttackCooldown = 1.4,
		AggroRadius = 50,
		RespawnTime = 30,
		BaseSpiritStones = 450,
		BaseQiReward = 1100,
		AIPattern = "ArmoredTank",
		DropTable = {
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.80, MinCount = 1, MaxCount = 3 },
			{ ItemId = "DragonBloodVine_10Yr", Chance = 0.60, MinCount = 1, MaxCount = 2 },
		},
	},

	-- =========================================================================
	-- ICE ZONE
	-- =========================================================================
	["Frost-Fang Wolf"] = {
		Id = "Frost-Fang Wolf",
		DisplayName = "Frost-Fang Wolf",
		Zone = "Ice",
		MaxHealth = 85000,
		MaxPosture = 200,
		BaseDamage = 1600,
		WalkSpeed = 14,
		RunSpeed = 36,
		AttackRange = 8.0,
		AttackCooldown = 1.1,
		AggroRadius = 45,
		RespawnTime = 40,
		BaseSpiritStones = 1200,
		BaseQiReward = 3200,
		AIPattern = "FrostPouncer",
		DropTable = {
			{ ItemId = "DemonBeastCore_100Yr", Chance = 0.75, MinCount = 1, MaxCount = 3 },
			{ ItemId = "GaleWindLotus_100Yr", Chance = 0.55, MinCount = 1, MaxCount = 2 },
		},
	},
}

local ALIASES: { [string]: string } = {
	["IronTuskSpiritBoar"] = "Iron-Tusk Spirit Boar",
	["WildernessSpiritWolf"] = "Wilderness Spirit Wolf",
	["MagmaHound"] = "Magma Hound",
	["ObsidianLavaBoar"] = "Obsidian Lava-Boar",
	["FrostFangWolf"] = "Frost-Fang Wolf",
}

function MonsterConfig.GetMonster(id: string): MonsterDefinition?
	local resolved = ALIASES[id] or id
	return MONSTERS[resolved]
end

function MonsterConfig.GetAllMonsters(): { [string]: MonsterDefinition }
	return MONSTERS
end

function MonsterConfig.RollDropTable(id: string): { { ItemId: string, Count: number } }
	local def = MonsterConfig.GetMonster(id)
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

return MonsterConfig