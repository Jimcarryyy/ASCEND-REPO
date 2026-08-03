--!strict
-- AlchemyConfig.luau
-- Configuration repository for Xianxia Spirit Pills, Herbs, and Crafting Recipes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

export type PillEffect = {
	Type: "InstantQi" | "QiGatherBoost" | "HealOverTime" | "StatBuff" | "BreakthroughBoost",
	Value: number,
	Duration: number?, -- In seconds, if temporary
	StatName: string?,
}

export type RecipeIngredient = {
	MaterialId: string,
	Amount: number,
}

export type PillRecipe = {
	RecipeId: string,
	DisplayName: string,
	Description: string,
	IconId: string,
	Rarity: string,
	Ingredients: { RecipeIngredient },
	CraftTime: number, -- Time in seconds
	SuccessRate: number, -- 0.0 to 1.0 (e.g. 0.9 = 90%)
	Effects: { PillEffect },
}

local AlchemyConfig = {}

-- Safe icon helper to prevent crashes if UIAssets sub-tables do not exist
local function getIcon(category: string, name: string): string
	local icons = (UIAssets :: any) and (UIAssets :: any).Icons
	if type(icons) == "table" and type(icons[category]) == "table" and icons[category][name] then
		return icons[category][name]
	end
	return "rbxassetid://0"
end

-- Registered Materials / Ingredients
AlchemyConfig.Materials = {
	SpiritHerb = {
		Id = "mat_spirit_herb",
		Name = "Spirit Gathering Herb",
		Description = "A radiant leaf infused with raw natural Qi.",
		IconId = getIcon("Materials", "SpiritHerb"),
	},
	DemonCore = {
		Id = "mat_demon_core",
		Name = "Demon Beast Core",
		Description = "A crystallized core harvested from an enraged Demonic Beast.",
		IconId = getIcon("Materials", "DemonCore"),
	},
	SpiritWater = {
		Id = "mat_spirit_water",
		Name = "Celestial Dew Water",
		Description = "Pure water collected from high mountain peaks under lunar light.",
		IconId = getIcon("Materials", "SpiritWater"),
	},
}

-- Registered Craftable Spirit Pills
AlchemyConfig.Pills = {
	QiGatheringPill = {
		RecipeId = "pill_qi_gathering",
		DisplayName = "Qi Gathering Pill",
		Description = "Restores 50 Qi instantly and increases Qi meditation speed by 50% for 30s.",
		IconId = getIcon("Pills", "QiGathering"),
		Rarity = "Earth",
		Ingredients = {
			{ MaterialId = "mat_spirit_herb", Amount = 3 },
			{ MaterialId = "mat_spirit_water", Amount = 1 },
		},
		CraftTime = 2.0,
		SuccessRate = 0.95,
		Effects = {
			{ Type = "InstantQi", Value = 50 },
			{ Type = "QiGatherBoost", Value = 0.50, Duration = 30 },
		},
	} :: PillRecipe,

	HealingDan = {
		RecipeId = "pill_healing_dan",
		DisplayName = "Spirit Healing Dan",
		Description = "Restores 40% of Maximum Health over 5 seconds.",
		IconId = getIcon("Pills", "HealingDan"),
		Rarity = "Earth",
		Ingredients = {
			{ MaterialId = "mat_spirit_herb", Amount = 2 },
			{ MaterialId = "mat_spirit_water", Amount = 2 },
		},
		CraftTime = 1.5,
		SuccessRate = 0.90,
		Effects = {
			{ Type = "HealOverTime", Value = 0.40, Duration = 5 },
		},
	} :: PillRecipe,

	PhysiqueTemperingPill = {
		RecipeId = "pill_physique_tempering",
		DisplayName = "Physique Tempering Pill",
		Description = "Refines the cultivator's body, increasing Physique damage by 20% for 60 seconds.",
		IconId = getIcon("Pills", "PhysiquePill"),
		Rarity = "Heaven",
		Ingredients = {
			{ MaterialId = "mat_spirit_herb", Amount = 4 },
			{ MaterialId = "mat_demon_core", Amount = 1 },
		},
		CraftTime = 3.0,
		SuccessRate = 0.85,
		Effects = {
			{ Type = "StatBuff", StatName = "PhysiqueBuff", Value = 0.20, Duration = 60 },
		},
	} :: PillRecipe,

	BreakthroughPill = {
		RecipeId = "pill_breakthrough",
		DisplayName = "Foundation Gathering Dan",
		Description = "Empowers meridians, providing maximum Qi surge required for Realm Breakthroughs.",
		IconId = getIcon("Materials", "BreakthroughPill"),
		Rarity = "Spirit",
		Ingredients = {
			{ MaterialId = "mat_spirit_herb", Amount = 8 },
			{ MaterialId = "mat_demon_core", Amount = 3 },
			{ MaterialId = "mat_spirit_water", Amount = 5 },
		},
		CraftTime = 5.0,
		SuccessRate = 0.75,
		Effects = {
			{ Type = "InstantQi", Value = 250 },
			{ Type = "BreakthroughBoost", Value = 1.0 },
		},
	} :: PillRecipe,
}

function AlchemyConfig.GetRecipe(recipeId: string): PillRecipe?
	for _, recipe in pairs(AlchemyConfig.Pills) do
		if recipe.RecipeId == recipeId then
			return recipe
		end
	end
	return nil
end

return AlchemyConfig