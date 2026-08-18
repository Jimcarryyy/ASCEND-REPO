--!strict
--[[
    MonetizationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MonetizationConfig.luau
    Central configuration for Gamepasses, Developer Products, and Robux monetization.
]]

export type GamepassType = 
    "DoubleQiSpeed" 
    | "AutoMeditation" 
    | "TribulationShield" 
    | "InventoryExpansion" 
    | "VIPElder"

export type GamepassDefinition = {
    Id: string,
    RobloxAssetId: number, -- Place real Gamepass ID from Creator Dashboard here
    DisplayName: string,
    Description: string,
    PriceRobux: number,
    Icon: string?,
}

export type DevProductDefinition = {
    Id: string,
    RobloxProductId: number, -- Place real Product ID from Creator Dashboard here
    DisplayName: string,
    Description: string,
    PriceRobux: number,
    RewardType: "SpiritStones" | "InstantQi" | "ToxicityCleanse",
    RewardAmount: number,
}

local MonetizationConfig = {}

-- 1. GAMEPASSES (One-time Robux unlocks)
local GAMEPASSES: { [GamepassType]: GamepassDefinition } = {
    ["DoubleQiSpeed"] = {
        Id = "DoubleQiSpeed",
        RobloxAssetId = 0, -- Set your Gamepass ID in Creator Dashboard
        DisplayName = "2x Cultivation Speed",
        Description = "Permanently doubles Qi gained from meditation, Qi nodes, and combat essence.",
        PriceRobux = 299,
    },
    ["AutoMeditation"] = {
        Id = "AutoMeditation",
        RobloxAssetId = 0,
        DisplayName = "Auto-Meditation (AFK Farm)",
        Description = "Automatically gathers internal Qi even when standing still or exploring.",
        PriceRobux = 199,
    },
    ["TribulationShield"] = {
        Id = "TribulationShield",
        RobloxAssetId = 0,
        DisplayName = "Heavenly Tribulation Shield",
        Description = "Guarantees 100% breakthrough success across all 10 Realms with zero Qi backlash.",
        PriceRobux = 399,
    },
    ["InventoryExpansion"] = {
        Id = "InventoryExpansion",
        RobloxAssetId = 0,
        DisplayName = "+30 Spirit Pouch Slots",
        Description = "Expands your bag capacity to store more rare herbs, dans, and swords.",
        PriceRobux = 149,
    },
    ["VIPElder"] = {
        Id = "VIPElder",
        RobloxAssetId = 0,
        DisplayName = "Honorary Sect Elder VIP",
        Description = "Golden overhead crown badge, exclusive elder robe aura, and 1.5x Spirit Stones drop rate.",
        PriceRobux = 499,
    },
}

-- 2. DEVELOPER PRODUCTS (Repeatable Robux purchases)
local DEV_PRODUCTS: { [string]: DevProductDefinition } = {
    ["Stones_500"] = {
        Id = "Stones_500",
        RobloxProductId = 0,
        DisplayName = "Pouch of 500 Spirit Stones",
        Description = "Basic sack of shining spirit currency.",
        PriceRobux = 49,
        RewardType = "SpiritStones",
        RewardAmount = 500,
    },
    ["Stones_2500"] = {
        Id = "Stones_2500",
        RobloxProductId = 0,
        DisplayName = "Chest of 2,500 Spirit Stones",
        Description = "Large chest of spirit currency for buying high-tier pills.",
        PriceRobux = 199,
        RewardType = "SpiritStones",
        RewardAmount = 2500,
    },
    ["Stones_10000"] = {
        Id = "Stones_10000",
        RobloxProductId = 0,
        DisplayName = "Mountain of 10,000 Spirit Stones",
        Description = "Immense spirit stone fortune.",
        PriceRobux = 599,
        RewardType = "SpiritStones",
        RewardAmount = 10000,
    },
    ["InstantBreakthroughDan"] = {
        Id = "InstantBreakthroughDan",
        RobloxProductId = 0,
        DisplayName = "Supreme Heavenly Qi Pill",
        Description = "Instantly fills your Dantian CultivatedQi to 100% for the current order.",
        PriceRobux = 99,
        RewardType = "InstantQi",
        RewardAmount = 1,
    },
    ["ToxicityPurifier"] = {
        Id = "ToxicityPurifier",
        RobloxProductId = 0,
        DisplayName = "Celestial Cleansing Spring",
        Description = "Instantly purges all Dan toxicity, allowing immediate pill consumption.",
        PriceRobux = 49,
        RewardType = "ToxicityCleanse",
        RewardAmount = 1,
    },
}

function MonetizationConfig.GetGamepass(id: GamepassType): GamepassDefinition?
    return GAMEPASSES[id]
end

function MonetizationConfig.GetAllGamepasses(): { [GamepassType]: GamepassDefinition }
    return GAMEPASSES
end

function MonetizationConfig.GetDevProduct(id: string): DevProductDefinition?
    return DEV_PRODUCTS[id]
end

function MonetizationConfig.GetDevProductByRobloxId(productId: number): DevProductDefinition?
    for _, prod in pairs(DEV_PRODUCTS) do
        if prod.RobloxProductId == productId then
            return prod
        end
    end
    return nil
end

function MonetizationConfig.GetAllDevProducts(): { [string]: DevProductDefinition }
    return DEV_PRODUCTS
end

return MonetizationConfig