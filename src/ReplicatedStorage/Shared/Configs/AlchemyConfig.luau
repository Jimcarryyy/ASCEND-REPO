--!strict
--[[
    AlchemyConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/AlchemyConfig.luau
    Alchemy recipes, flame temperature windows, and exact multiset archetype matching.
    Includes all 9 Major Realm Breakthrough Dans.
]]

export type AlchemyFormulaDefinition = {
	FormulaId: string,
	Name: string,
	ResultItemId: string,
	BaseSuccessRate: number,
	BaseQiCost: number,
	CraftDuration: number,
	RequiredArchetypes: { string },
	ExpReward: number,
}

local AlchemyConfig = {}

local ARCHETYPE_MAP: { [string]: boolean } = {
	["DragonBloodVine"] = true,
	["GaleWindLotus"]   = true,
	["CelestialDew"]    = true,
	["DemonBeastCore"]  = true,
	["SpiritGrass"]     = true,
}

local FORMULAS: { [string]: AlchemyFormulaDefinition } = {
	-- UTILITY & COMBAT PILLS
	["PhysiqueTemperingDan"] = {
		FormulaId = "PhysiqueTemperingDan",
		Name = "Physique Tempering Dan",
		ResultItemId = "PhysiqueTemperingDan",
		BaseSuccessRate = 0.55,
		BaseQiCost = 15,
		CraftDuration = 2.0,
		RequiredArchetypes = { "DragonBloodVine", "SpiritGrass" },
		ExpReward = 20,
	},
	["GaleWindDan"] = {
		FormulaId = "GaleWindDan",
		Name = "Gale Wind Dan",
		ResultItemId = "GaleWindDan",
		BaseSuccessRate = 0.60,
		BaseQiCost = 20,
		CraftDuration = 2.0,
		RequiredArchetypes = { "GaleWindLotus", "CelestialDew" },
		ExpReward = 25,
	},
	["QiGatheringDan"] = {
		FormulaId = "QiGatheringDan",
		Name = "Qi Gathering Dan",
		ResultItemId = "QiGatheringDan",
		BaseSuccessRate = 0.50,
		BaseQiCost = 30,
		CraftDuration = 2.5,
		RequiredArchetypes = { "SpiritGrass", "CelestialDew" },
		ExpReward = 35,
	},
	["SpiritHealingDan"] = {
		FormulaId = "SpiritHealingDan",
		Name = "Spirit Healing Dan",
		ResultItemId = "SpiritHealingDan",
		BaseSuccessRate = 0.70,
		BaseQiCost = 10,
		CraftDuration = 1.5,
		RequiredArchetypes = { "SpiritGrass" },
		ExpReward = 15,
	},

	-- THE 9 MAJOR REALM BREAKTHROUGH DANS
	["FoundationGatheringDan"] = {
		FormulaId = "FoundationGatheringDan",
		Name = "Foundation Gathering Dan",
		ResultItemId = "FoundationGatheringDan",
		BaseSuccessRate = 0.65,
		BaseQiCost = 50,
		CraftDuration = 3.0,
		RequiredArchetypes = { "SpiritGrass", "DemonBeastCore", "CelestialDew" },
		ExpReward = 80,
	},
	["GoldenCoreDan"] = {
		FormulaId = "GoldenCoreDan",
		Name = "Golden Core Dan",
		ResultItemId = "GoldenCoreDan",
		BaseSuccessRate = 0.60,
		BaseQiCost = 120,
		CraftDuration = 3.5,
		RequiredArchetypes = { "DragonBloodVine", "CelestialDew", "DemonBeastCore" },
		ExpReward = 150,
	},
	["NascentSoulDan"] = {
		FormulaId = "NascentSoulDan",
		Name = "Nascent Soul Dan",
		ResultItemId = "NascentSoulDan",
		BaseSuccessRate = 0.55,
		BaseQiCost = 300,
		CraftDuration = 4.0,
		RequiredArchetypes = { "GaleWindLotus", "CelestialDew", "DemonBeastCore" },
		ExpReward = 300,
	},
	["SpiritSeveringDan"] = {
		FormulaId = "SpiritSeveringDan",
		Name = "Spirit Severing Dan",
		ResultItemId = "SpiritSeveringDan",
		BaseSuccessRate = 0.50,
		BaseQiCost = 650,
		CraftDuration = 4.5,
		RequiredArchetypes = { "DragonBloodVine", "SpiritGrass", "DemonBeastCore" },
		ExpReward = 500,
	},
	["VoidRefiningDan"] = {
		FormulaId = "VoidRefiningDan",
		Name = "Void Refining Dan",
		ResultItemId = "VoidRefiningDan",
		BaseSuccessRate = 0.45,
		BaseQiCost = 1500,
		CraftDuration = 5.0,
		RequiredArchetypes = { "GaleWindLotus", "SpiritGrass", "DemonBeastCore" },
		ExpReward = 900,
	},
	["BodyIntegrationDan"] = {
		FormulaId = "BodyIntegrationDan",
		Name = "Body Integration Dan",
		ResultItemId = "BodyIntegrationDan",
		BaseSuccessRate = 0.40,
		BaseQiCost = 3500,
		CraftDuration = 5.5,
		RequiredArchetypes = { "DragonBloodVine", "DragonBloodVine", "DemonBeastCore" },
		ExpReward = 1500,
	},
	["MahayanaDan"] = {
		FormulaId = "MahayanaDan",
		Name = "Mahayana Dan",
		ResultItemId = "MahayanaDan",
		BaseSuccessRate = 0.35,
		BaseQiCost = 8000,
		CraftDuration = 6.0,
		RequiredArchetypes = { "SpiritGrass", "SpiritGrass", "DemonBeastCore" },
		ExpReward = 2500,
	},
	["TribulationTranscendingDan"] = {
		FormulaId = "TribulationTranscendingDan",
		Name = "Tribulation Transcending Dan",
		ResultItemId = "TribulationTranscendingDan",
		BaseSuccessRate = 0.30,
		BaseQiCost = 18000,
		CraftDuration = 7.0,
		RequiredArchetypes = { "GaleWindLotus", "DragonBloodVine", "DemonBeastCore" },
		ExpReward = 4500,
	},
	["ImmortalAscensionDan"] = {
		FormulaId = "ImmortalAscensionDan",
		Name = "Immortal Ascension Dan",
		ResultItemId = "ImmortalAscensionDan",
		BaseSuccessRate = 0.25,
		BaseQiCost = 45000,
		CraftDuration = 8.0,
		RequiredArchetypes = { "SpiritGrass", "DragonBloodVine", "GaleWindLotus", "DemonBeastCore" },
		ExpReward = 10000,
	},
}

local function GetHerbAge(itemId: string): number
	if string.find(itemId, "1000Yr") then
		return 1000
	elseif string.find(itemId, "100Yr") then
		return 100
	elseif string.find(itemId, "10Yr") then
		return 10
	elseif string.find(itemId, "1Yr") then
		return 1
	end
	return 1
end

function AlchemyConfig.GetFormula(formulaId: string): AlchemyFormulaDefinition?
	return FORMULAS[formulaId]
end

function AlchemyConfig.GetAllFormulas(): { [string]: AlchemyFormulaDefinition }
	return FORMULAS
end

function AlchemyConfig.CalculateCombinationMetrics(herbItemIds: { string }): (AlchemyFormulaDefinition?, number, number, string)
	local detectedArchetypes: { string } = {}
	local totalAge = 0
	local count = #herbItemIds

	for _, itemId in ipairs(herbItemIds) do
		for arch, _ in pairs(ARCHETYPE_MAP) do
			if string.find(itemId, arch) then
				table.insert(detectedArchetypes, arch)
				break
			end
		end
		totalAge += GetHerbAge(itemId)
	end

	local formulasList = {}
	for _, formula in pairs(FORMULAS) do
		table.insert(formulasList, formula)
	end
	table.sort(formulasList, function(a, b)
		return #a.RequiredArchetypes > #b.RequiredArchetypes
	end)

	local matchedFormula: AlchemyFormulaDefinition? = nil

	for _, formula in ipairs(formulasList) do
		if #formula.RequiredArchetypes == #detectedArchetypes then
			local tempArchetypes = table.clone(detectedArchetypes)
			local allMatch = true

			for _, req in ipairs(formula.RequiredArchetypes) do
				local foundIdx = table.find(tempArchetypes, req)
				if foundIdx then
					table.remove(tempArchetypes, foundIdx)
				else
					allMatch = false
					break
				end
			end

			if allMatch then
				matchedFormula = formula
				break
			end
		end
	end

	if not matchedFormula then
		return nil, 0.0, 1.0, "Dross"
	end

	local avgAge = if count > 0 then (totalAge / count) else 1
	local ageBonus = 0.0

	if avgAge >= 1000 then
		ageBonus = 0.40
	elseif avgAge >= 100 then
		ageBonus = 0.30
	elseif avgAge >= 10 then
		ageBonus = 0.15
	end

	local calculatedSuccessRate = math.clamp(matchedFormula.BaseSuccessRate + ageBonus, 0.05, 0.95)
	local potencyMultiplier = 1.0 + (ageBonus * 1.5)

	local qualityTier = "Mortal Grade"
	if avgAge >= 1000 then
		qualityTier = "Transcendent Grade"
	elseif avgAge >= 100 then
		qualityTier = "Supreme Grade"
	elseif avgAge >= 10 then
		qualityTier = "Earth Grade"
	end

	return matchedFormula, calculatedSuccessRate, potencyMultiplier, qualityTier
end

return AlchemyConfig