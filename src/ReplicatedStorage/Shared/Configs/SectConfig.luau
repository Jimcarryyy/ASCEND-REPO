--!strict
--[[
    SectConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/SectConfig.luau
    Defines Azure Cloud Sect Disciple hierarchy, contribution thresholds, daily quests, and market prices.
]]

export type DiscipleRank = 
    "OuterDisciple" 
    | "InnerDisciple" 
    | "CoreDisciple" 
    | "DirectDisciple" 
    | "SectElder" 
    | "GrandElder"

export type RankDefinition = {
    RankId: DiscipleRank,
    DisplayName: string,
    TitleColor: Color3,
    RequiredRealm: string,      -- e.g. "QiCondensation", "FoundationEstablishment"
    RequiredContribution: number,
    DailyStipendStones: number,
    QiBuffMultiplier: number,
}

export type SectQuestDefinition = {
    QuestId: string,
    Title: string,
    Description: string,
    QuestType: "Gather" | "Cultivate" | "DefeatMob" | "CraftDan",
    TargetId: string,
    TargetAmount: number,
    RewardContribution: number,
    RewardSpiritStones: number,
    RewardQi: number,
}

export type VendorItemDefinition = {
    ItemId: string,
    BuyPrice: number?,    -- Spirit Stones cost to buy (nil if cannot buy)
    SellPrice: number,   -- Spirit Stones earned when selling to vendor
    RequiredRank: DiscipleRank,
}

local SectConfig = {}

-- 1. DISCIPLE PROMOTION HIERARCHY
local RANKS: { [DiscipleRank]: RankDefinition } = {
    ["OuterDisciple"] = {
        RankId = "OuterDisciple",
        DisplayName = "Outer Disciple",
        TitleColor = Color3.fromRGB(180, 220, 255), -- Light Cyan
        RequiredRealm = "QiCondensation",
        RequiredContribution = 0,
        DailyStipendStones = 50,
        QiBuffMultiplier = 1.0,
    },
    ["InnerDisciple"] = {
        RankId = "InnerDisciple",
        DisplayName = "Inner Disciple",
        TitleColor = Color3.fromRGB(100, 255, 150), -- Jade Green
        RequiredRealm = "FoundationEstablishment",
        RequiredContribution = 500,
        DailyStipendStones = 150,
        QiBuffMultiplier = 1.15,
    },
    ["CoreDisciple"] = {
        RankId = "CoreDisciple",
        DisplayName = "Core Disciple",
        TitleColor = Color3.fromRGB(80, 180, 255),  -- Deep Azure
        RequiredRealm = "CoreFormation",
        RequiredContribution = 2500,
        DailyStipendStones = 400,
        QiBuffMultiplier = 1.30,
    },
    ["DirectDisciple"] = {
        RankId = "DirectDisciple",
        DisplayName = "Direct Disciple",
        TitleColor = Color3.fromRGB(255, 215, 0),   -- Radiant Gold
        RequiredRealm = "NascentSoul",
        RequiredContribution = 10000,
        DailyStipendStones = 1000,
        QiBuffMultiplier = 1.50,
    },
    ["SectElder"] = {
        RankId = "SectElder",
        DisplayName = "Sect Elder",
        TitleColor = Color3.fromRGB(255, 100, 100), -- Vermilion Crimson
        RequiredRealm = "SoulFormation",
        RequiredContribution = 50000,
        DailyStipendStones = 3000,
        QiBuffMultiplier = 1.75,
    },
    ["GrandElder"] = {
        RankId = "GrandElder",
        DisplayName = "Supreme Grand Elder",
        TitleColor = Color3.fromRGB(200, 100, 255), -- Imperial Purple
        RequiredRealm = "TribulationTranscendence",
        RequiredContribution = 150000,
        DailyStipendStones = 10000,
        QiBuffMultiplier = 2.0,
    },
}

-- 2. DAILY SECT QUESTS & MISSIONS
local QUESTS: { [string]: SectQuestDefinition } = {
    ["Quest_GatherSpiritGrass"] = {
        QuestId = "Quest_GatherSpiritGrass",
        Title = "Herbal Foraging Duty",
        Description = "Harvest 5 stalks of Spirit Grass from the sect valley.",
        QuestType = "Gather",
        TargetId = "SpiritGrass",
        TargetAmount = 5,
        RewardContribution = 50,
        RewardSpiritStones = 100,
        RewardQi = 150,
    },
    ["Quest_SparringTrial"] = {
        QuestId = "Quest_SparringTrial",
        Title = "Sparring Ground Discipline",
        Description = "Defeat 3 Rogue Disciples in the sparring grounds.",
        QuestType = "DefeatMob",
        TargetId = "RogueDisciple",
        TargetAmount = 3,
        RewardContribution = 75,
        RewardSpiritStones = 150,
        RewardQi = 200,
    },
    ["Quest_RefineDan"] = {
        QuestId = "Quest_RefineDan",
        Title = "Alchemy Cauldron Refinement",
        Description = "Refine any 1 Spirit Dan in the Sect Cauldron.",
        QuestType = "CraftDan",
        TargetId = "AnyDan",
        TargetAmount = 1,
        RewardContribution = 60,
        RewardSpiritStones = 120,
        RewardQi = 180,
    },
}

-- 3. SECT MARKET VENDOR PRICING
local MARKET_ITEMS: { [string]: VendorItemDefinition } = {
    -- Potion / Dan Buy & Sell
    ["SpiritHealingDan"] = { ItemId = "SpiritHealingDan", BuyPrice = 80, SellPrice = 30, RequiredRank = "OuterDisciple" },
    ["PhysiqueTemperingDan"] = { ItemId = "PhysiqueTemperingDan", BuyPrice = 150, SellPrice = 60, RequiredRank = "OuterDisciple" },
    ["QiGatheringDan"] = { ItemId = "QiGatheringDan", BuyPrice = 250, SellPrice = 100, RequiredRank = "InnerDisciple" },
    ["GaleWindDan"] = { ItemId = "GaleWindDan", BuyPrice = 300, SellPrice = 120, RequiredRank = "InnerDisciple" },
    ["FoundationGatheringDan"] = { ItemId = "FoundationGatheringDan", BuyPrice = 1000, SellPrice = 400, RequiredRank = "CoreDisciple" },

    -- Raw Materials & Herbs (Sellable by players)
    ["SpiritGrass_1Yr"] = { ItemId = "SpiritGrass_1Yr", BuyPrice = 20, SellPrice = 8, RequiredRank = "OuterDisciple" },
    ["SpiritGrass_10Yr"] = { ItemId = "SpiritGrass_10Yr", BuyPrice = 60, SellPrice = 25, RequiredRank = "OuterDisciple" },
    ["SpiritGrass_100Yr"] = { ItemId = "SpiritGrass_100Yr", BuyPrice = 250, SellPrice = 100, RequiredRank = "InnerDisciple" },
    ["DragonBloodVine_1Yr"] = { ItemId = "DragonBloodVine_1Yr", BuyPrice = 35, SellPrice = 15, RequiredRank = "OuterDisciple" },
    ["DragonBloodVine_100Yr"] = { ItemId = "DragonBloodVine_100Yr", BuyPrice = 300, SellPrice = 125, RequiredRank = "InnerDisciple" },
    ["CelestialDew"] = { ItemId = "CelestialDew", BuyPrice = 50, SellPrice = 20, RequiredRank = "OuterDisciple" },
    ["DemonBeastCore"] = { ItemId = "DemonBeastCore", BuyPrice = 400, SellPrice = 180, RequiredRank = "InnerDisciple" },
    ["SpiritAsh"] = { ItemId = "SpiritAsh", BuyPrice = nil, SellPrice = 2, RequiredRank = "OuterDisciple" },
}

function SectConfig.GetRank(rank: DiscipleRank): RankDefinition
    return RANKS[rank] or RANKS["OuterDisciple"]
end

function SectConfig.GetAllRanks(): { [DiscipleRank]: RankDefinition }
    return RANKS
end

function SectConfig.GetQuest(questId: string): SectQuestDefinition?
    return QUESTS[questId]
end

function SectConfig.GetAllQuests(): { [string]: SectQuestDefinition }
    return QUESTS
end

function SectConfig.GetMarketItem(itemId: string): VendorItemDefinition?
    return MARKET_ITEMS[itemId]
end

function SectConfig.GetAllMarketItems(): { [string]: VendorItemDefinition }
    return MARKET_ITEMS
end

return SectConfig