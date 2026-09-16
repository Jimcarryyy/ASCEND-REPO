--!strict
--[[
    GatheringConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/GatheringConfig.luau
    Authoritative gathering resource nodes, interaction ranges, respawn timers,
    and 4-tier herb drop matrices (1-Yr, 10-Yr, 100-Yr, 1000-Yr).
]]

export type ResourceNodeDrop = {
	ItemId: string,
	Chance: number,
}

export type ResourceNodeDefinition = {
	NodeId: string,
	DisplayName: string,
	PromptText: string,
	HoldDuration: number,
	MaxDistance: number,
	RespawnTime: number,
	AuraColor: Color3,
	AgeDrops: { ResourceNodeDrop },
}

local GatheringConfig = {}

local NODE_DEFINITIONS: { [string]: ResourceNodeDefinition } = {
	["SpiritGrass"] = {
		NodeId = "SpiritGrass",
		DisplayName = "Spirit Grass Cluster",
		PromptText = "Harvest Spirit Grass",
		HoldDuration = 1.2,
		MaxDistance = 8.0,
		RespawnTime = 12.0,
		AuraColor = Color3.fromRGB(120, 255, 140),
		AgeDrops = {
			{ ItemId = "SpiritGrass_1Yr",    Chance = 0.50 },
			{ ItemId = "SpiritGrass_10Yr",   Chance = 0.30 },
			{ ItemId = "SpiritGrass_100Yr",  Chance = 0.15 },
			{ ItemId = "SpiritGrass_1000Yr", Chance = 0.05 },
		},
	},

	["DragonBloodVine"] = {
		NodeId = "DragonBloodVine",
		DisplayName = "Dragon Blood Vine",
		PromptText = "Sever Dragon Blood Vine",
		HoldDuration = 1.6,
		MaxDistance = 8.0,
		RespawnTime = 18.0,
		AuraColor = Color3.fromRGB(255, 60, 60),
		AgeDrops = {
			{ ItemId = "DragonBloodVine_1Yr",    Chance = 0.55 },
			{ ItemId = "DragonBloodVine_10Yr",   Chance = 0.25 },
			{ ItemId = "DragonBloodVine_100Yr",  Chance = 0.15 },
			{ ItemId = "DragonBloodVine_1000Yr", Chance = 0.05 },
		},
	},

	["GaleWindLotus"] = {
		NodeId = "GaleWindLotus",
		DisplayName = "Gale Wind Lotus",
		PromptText = "Pluck Gale Wind Lotus",
		HoldDuration = 1.4,
		MaxDistance = 8.0,
		RespawnTime = 15.0,
		AuraColor = Color3.fromRGB(100, 220, 255),
		AgeDrops = {
			{ ItemId = "GaleWindLotus_1Yr",    Chance = 0.55 },
			{ ItemId = "GaleWindLotus_10Yr",   Chance = 0.25 },
			{ ItemId = "GaleWindLotus_100Yr",  Chance = 0.15 },
			{ ItemId = "GaleWindLotus_1000Yr", Chance = 0.05 },
		},
	},

	["CelestialSpring"] = {
		NodeId = "CelestialSpring",
		DisplayName = "Celestial Spirit Spring",
		PromptText = "Bottle Celestial Dew",
		HoldDuration = 2.0,
		MaxDistance = 9.0,
		RespawnTime = 25.0,
		AuraColor = Color3.fromRGB(200, 240, 255),
		AgeDrops = {
			{ ItemId = "CelestialDew", Chance = 1.0 },
		},
	},

	["JadeOre"] = {
		NodeId = "JadeOre",
		DisplayName = "Spirit Jade Deposit",
		PromptText = "Extract Spirit Ore",
		HoldDuration = 2.2,
		MaxDistance = 8.0,
		RespawnTime = 30.0,
		AuraColor = Color3.fromRGB(150, 255, 200),
		AgeDrops = {
			{ ItemId = "SpiritGrass_10Yr",    Chance = 0.60 },
			{ ItemId = "DemonBeastCore_10Yr", Chance = 0.40 },
		},
	},
}

function GatheringConfig.GetNode(nodeId: string): ResourceNodeDefinition?
	return NODE_DEFINITIONS[nodeId]
end

function GatheringConfig.GetAllNodes(): { [string]: ResourceNodeDefinition }
	return NODE_DEFINITIONS
end

function GatheringConfig.RollHarvestResult(nodeId: string): string?
	local def = NODE_DEFINITIONS[nodeId]
	if not def or #def.AgeDrops == 0 then return nil end

	local roll = math.random()
	local cumulative = 0.0

	for _, drop in ipairs(def.AgeDrops) do
		cumulative += drop.Chance
		if roll <= cumulative then
			return drop.ItemId
		end
	end

	return def.AgeDrops[1].ItemId
end

return GatheringConfig