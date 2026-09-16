--!strict
--[[
    MonetizationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MonetizationConfig.luau
    Authoritative monetization registry for Gamepasses and Developer Products,
    including Bloodline Spin reroll packages.
]]

export type GamepassDefinition = {
	Id: string,
	RobloxPassId: number,
	DisplayName: string,
	Description: string,
	PriceRobux: number,
	Icon: string?,
}

export type DevProductDefinition = {
	Id: string,
	RobloxProductId: number,
	DisplayName: string,
	Description: string,
	PriceRobux: number,
	RewardType: "SpiritStones" | "QiPill" | "WeaponSkin" | "BloodlineSpins",
	RewardAmount: number,
	Icon: string?,
}

local MonetizationConfig = {}

local GAMEPASSES: { [string]: GamepassDefinition } = {
	["AutoMeditate"] = {
		Id = "AutoMeditate",
		RobloxPassId = 0,
		DisplayName = "Infinite Dao Meditation",
		Description = "Automatically gathers and refines Spirit Qi even while running or roaming the world.",
		PriceRobux = 299,
	},
	["FastFlight"] = {
		Id = "FastFlight",
		RobloxPassId = 0,
		DisplayName = "Void Rift Flight Engine",
		Description = "Doubles the flight movement speed across all flying sword tiers.",
		PriceRobux = 499,
	},
	["VipElder"] = {
		Id = "VipElder",
		RobloxPassId = 0,
		DisplayName = "Honorary Sect Elder VIP",
		Description = "Grants +50% daily sect stipend, exclusive golden elder nameplate, and elder pavilion access.",
		PriceRobux = 799,
	},
}

local DEV_PRODUCTS: { [string]: DevProductDefinition } = {
	-- Spirit Stone Currency Top-ups
	["SpiritStones_Small"] = {
		Id = "SpiritStones_Small",
		RobloxProductId = 0,
		DisplayName = "Pouch of Spirit Stones",
		Description = "Contains 500 pure immortal spirit stones.",
		PriceRobux = 49,
		RewardType = "SpiritStones",
		RewardAmount = 500,
	},
	["SpiritStones_Medium"] = {
		Id = "SpiritStones_Medium",
		RobloxProductId = 0,
		DisplayName = "Chest of Spirit Stones",
		Description = "Contains 2,500 pure immortal spirit stones.",
		PriceRobux = 199,
		RewardType = "SpiritStones",
		RewardAmount = 2500,
	},
	["SpiritStones_Large"] = {
		Id = "SpiritStones_Large",
		RobloxProductId = 0,
		DisplayName = "Treasury of Spirit Stones",
		Description = "Contains 10,000 pure immortal spirit stones.",
		PriceRobux = 699,
		RewardType = "SpiritStones",
		RewardAmount = 10000,
	},

	-- Bloodline Spin Packages
	["BloodlineSpin_1"] = {
		Id = "BloodlineSpin_1",
		RobloxProductId = 0,
		DisplayName = "1x Bloodline Reroll",
		Description = "Reroll your sword cultivator lineage once.",
		PriceRobux = 25,
		RewardType = "BloodlineSpins",
		RewardAmount = 1,
	},
	["BloodlineSpin_5"] = {
		Id = "BloodlineSpin_5",
		RobloxProductId = 0,
		DisplayName = "5x Bloodline Rerolls",
		Description = "Batch of 5 bloodline rerolls.",
		PriceRobux = 99,
		RewardType = "BloodlineSpins",
		RewardAmount = 5,
	},
	["BloodlineSpin_25"] = {
		Id = "BloodlineSpin_25",
		RobloxProductId = 0,
		DisplayName = "25x Bloodline Rerolls (Popular)",
		Description = "High chance of unlocking Legendary or Mythic lineages.",
		PriceRobux = 399,
		RewardType = "BloodlineSpins",
		RewardAmount = 25,
	},
	["BloodlineSpin_75"] = {
		Id = "BloodlineSpin_75",
		RobloxProductId = 0,
		DisplayName = "75x Bloodline Rerolls (Ultimate)",
		Description = "Massive lineage bundle for unlocking Mythic Chaos Dao Bodies.",
		PriceRobux = 999,
		RewardType = "BloodlineSpins",
		RewardAmount = 75,
	},
}

function MonetizationConfig.GetGamepass(passId: string): GamepassDefinition?
	return GAMEPASSES[passId]
end

function MonetizationConfig.GetAllGamepasses(): { [string]: GamepassDefinition }
	return GAMEPASSES
end

function MonetizationConfig.GetDevProduct(productId: string): DevProductDefinition?
	return DEV_PRODUCTS[productId]
end

function MonetizationConfig.GetAllDevProducts(): { [string]: DevProductDefinition }
	return DEV_PRODUCTS
end

return MonetizationConfig