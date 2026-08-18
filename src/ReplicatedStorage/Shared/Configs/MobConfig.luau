--!strict
--[[
    MobConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MobConfig.luau
    Data-driven configuration for standard R6 zone mobs and sparring disciples.
]]

export type MobDropItem = {
    ItemId: string,
    Chance: number,     -- 0.0 to 1.0
    MinCount: number,
    MaxCount: number,
}

export type MobDefinition = {
    MobId: string,
    DisplayName: string,
    MaxHealth: number,
    BaseDamage: number,
    WalkSpeed: number,
    AggroRadius: number,
    AttackRange: number,
    AttackCooldown: number,
    BaseSpiritStones: number,
    BaseQiReward: number,
    DropTable: { MobDropItem },
}

local MobConfig = {}

local MOBS: { [string]: MobDefinition } = {
    ["RogueDisciple"] = {
        MobId = "RogueDisciple",
        DisplayName = "Corrupted Outer Disciple",
        MaxHealth = 350,
        BaseDamage = 25,
        WalkSpeed = 14,
        AggroRadius = 30,
        AttackRange = 6.5,
        AttackCooldown = 1.8,
        BaseSpiritStones = 15,
        BaseQiReward = 35,
        DropTable = {
            { ItemId = "SpiritGrass_1Yr", Chance = 0.60, MinCount = 1, MaxCount = 2 },
            { ItemId = "SpiritHealingDan", Chance = 0.20, MinCount = 1, MaxCount = 1 },
        },
    },
    ["DemonWolf"] = {
        MobId = "DemonWolf",
        DisplayName = "Shadow Wind Wolf",
        MaxHealth = 550,
        BaseDamage = 40,
        WalkSpeed = 18,
        AggroRadius = 40,
        AttackRange = 7.0,
        AttackCooldown = 1.5,
        BaseSpiritStones = 30,
        BaseQiReward = 65,
        DropTable = {
            { ItemId = "DemonBeastCore", Chance = 0.35, MinCount = 1, MaxCount = 1 },
            { ItemId = "DragonBloodVine_1Yr", Chance = 0.50, MinCount = 1, MaxCount = 2 },
        },
    },
    ["IronhideBoar"] = {
        MobId = "IronhideBoar",
        DisplayName = "Wild Ironhide Boar",
        MaxHealth = 800,
        BaseDamage = 55,
        WalkSpeed = 12,
        AggroRadius = 35,
        AttackRange = 8.0,
        AttackCooldown = 2.2,
        BaseSpiritStones = 45,
        BaseQiReward = 90,
        DropTable = {
            { ItemId = "DemonBeastCore", Chance = 0.50, MinCount = 1, MaxCount = 1 },
            { ItemId = "SpiritGrass_10Yr", Chance = 0.30, MinCount = 1, MaxCount = 1 },
        },
    },
}

function MobConfig.GetMob(mobId: string): MobDefinition?
    return MOBS[mobId]
end

function MobConfig.GetAllMobs(): { [string]: MobDefinition }
    return MOBS
end

return MobConfig