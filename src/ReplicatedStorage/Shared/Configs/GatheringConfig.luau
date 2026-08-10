--!strict
--[[
    GatheringConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/GatheringConfig.luau
    Central configuration for all world gathering resource nodes in ASCEND.
    Rolls randomized herb ages (1-Yr, 10-Yr, 100-Yr, 1000-Yr) upon harvest.
]]

export type YearDropChance = {
	ItemId: string,
	Chance: number, -- Cumulative or weighted chance
}

export type NodeConfig = {
	NodeName: string,
	HarvestDuration: number,
	RespawnTime: number,
	MaxDistance: number,
	AgeDrops: { YearDropChance },
	PromptText: string,
	ActionText: string,
}

local GatheringConfig = {}

local NODES: { [string]: NodeConfig } = {
	["SpiritGrass"] = {
		NodeName = "Spirit Grass",
		HarvestDuration = 1.8,
		RespawnTime = 12.0,
		MaxDistance = 10,
		AgeDrops = {
			{ ItemId = "SpiritGrass_1Yr", Chance = 0.60 },    -- 60% chance 1-Year
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.25 },   -- 25% chance 10-Year
			{ ItemId = "SpiritGrass_100Yr", Chance = 0.12 },  -- 12% chance 100-Year
			{ ItemId = "SpiritGrass_1000Yr", Chance = 0.03 }, -- 3% chance 1,000-Year
		},
		PromptText = "Harvest Spirit Grass",
		ActionText = "Gathering Herbs...",
	},
	["DragonBloodVine"] = {
		NodeName = "Dragon Blood Vine",
		HarvestDuration = 2.2,
		RespawnTime = 15.0,
		MaxDistance = 10,
		AgeDrops = {
			{ ItemId = "DragonBloodVine_1Yr", Chance = 0.70 },   -- 70% chance 1-Year
			{ ItemId = "DragonBloodVine_100Yr", Chance = 0.30 }, -- 30% chance 100-Year
		},
		PromptText = "Harvest Dragon Vine",
		ActionText = "Gathering Crimson Vine...",
	},
	["GaleWindLotus"] = {
		NodeName = "Gale Wind Lotus",
		HarvestDuration = 2.0,
		RespawnTime = 15.0,
		MaxDistance = 10,
		AgeDrops = {
			{ ItemId = "GaleWindLotus_1Yr", Chance = 0.70 },   -- 70% chance 1-Year
			{ ItemId = "GaleWindLotus_100Yr", Chance = 0.30 }, -- 30% chance 100-Year
		},
		PromptText = "Gather Wind Lotus",
		ActionText = "Gathering Lotus...",
	},
	["CelestialSpring"] = {
		NodeName = "Celestial Dew Spring",
		HarvestDuration = 2.2,
		RespawnTime = 15.0,
		MaxDistance = 12,
		AgeDrops = {
			{ ItemId = "CelestialDew", Chance = 1.0 },
		},
		PromptText = "Collect Dew Water",
		ActionText = "Gathering Pure Water...",
	},
	["JadeOre"] = {
		NodeName = "Spirit Jade Ore",
		HarvestDuration = 2.5,
		RespawnTime = 20.0,
		MaxDistance = 10,
		AgeDrops = {
			{ ItemId = "SpiritGrass_10Yr", Chance = 0.70 },
			{ ItemId = "DemonBeastCore", Chance = 0.30 },
		},
		PromptText = "Mine Jade Ore",
		ActionText = "Mining Ore...",
	},
}

function GatheringConfig.GetNodeConfig(nodeType: string): NodeConfig?
	return NODES[nodeType]
end

function GatheringConfig.GetAllNodes(): { [string]: NodeConfig }
	return NODES
end

return GatheringConfig