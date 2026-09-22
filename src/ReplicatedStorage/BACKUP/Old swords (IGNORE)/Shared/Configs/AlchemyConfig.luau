--!strict
--[[
    AlchemyConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/AlchemyConfig.luau
    Strict formula matching, dynamic age-tier calculations, and flame precision metrics for ASCEND.
]]

export type QualityTier = "TopGrade" | "Normal" | "LowGrade"

export type PillFormula = {
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

local FORMULAS: { [string]: PillFormula } = {
	["PhysiqueTemperingDan"] = {
		FormulaId = "PhysiqueTemperingDan",
		Name = "Physique Tempering Dan",
		ResultItemId = "PhysiqueTemperingDan",
		BaseSuccessRate = 0.55,
		BaseQiCost = 40,
		CraftDuration = 3.0,
		RequiredArchetypes = { "DragonBloodVine", "SpiritGrass" },
		ExpReward = 50,
	},
	["GaleWindDan"] = {
		FormulaId = "GaleWindDan",
		Name = "Gale Wind Dan",
		ResultItemId = "GaleWindDan",
		BaseSuccessRate = 0.60,
		BaseQiCost = 30,
		CraftDuration = 2.5,
		RequiredArchetypes = { "GaleWindLotus", "SpiritGrass" },
		ExpReward = 40,
	},
	["QiGatheringDan"] = {
		FormulaId = "QiGatheringDan",
		Name = "Qi Gathering Dan",
		ResultItemId = "QiGatheringDan",
		BaseSuccessRate = 0.65,
		BaseQiCost = 25,
		CraftDuration = 2.5,
		RequiredArchetypes = { "SpiritGrass", "CelestialDew" },
		ExpReward = 35,
	},
	["FoundationGatheringDan"] = {
		FormulaId = "FoundationGatheringDan",
		Name = "Foundation Gathering Dan",
		ResultItemId = "FoundationGatheringDan",
		BaseSuccessRate = 0.50,
		BaseQiCost = 60,
		CraftDuration = 3.5,
		RequiredArchetypes = { "SpiritGrass", "DemonBeastCore", "CelestialDew" },
		ExpReward = 80,
	},
	["SpiritHealingDan"] = {
		FormulaId = "SpiritHealingDan",
		Name = "Spirit Healing Dan",
		ResultItemId = "SpiritHealingDan",
		BaseSuccessRate = 0.70,
		BaseQiCost = 15,
		CraftDuration = 2.0,
		RequiredArchetypes = { "SpiritGrass", "SpiritGrass" },
		ExpReward = 20,
	},
}

function AlchemyConfig.CalculateCombinationMetrics(herbItemIds: { string }): (PillFormula?, number, number, string)
	if #herbItemIds == 0 then
		return nil, 0, 1.0, "Empty Cauldron"
	end

	local ItemConfig = require(script.Parent.ItemConfig)

	local insertedArchetypes: { string } = {}
	local totalAge = 0
	local validHerbCount = 0

	for _, itemId in ipairs(herbItemIds) do
		local itemDef = ItemConfig.GetItem(itemId)
		if itemDef then
			validHerbCount += 1
			totalAge += (itemDef.AgeYears or 1)

			if itemId:find("DragonBloodVine", 1, true) then
				table.insert(insertedArchetypes, "DragonBloodVine")
			elseif itemId:find("GaleWindLotus", 1, true) then
				table.insert(insertedArchetypes, "GaleWindLotus")
			elseif itemId:find("CelestialDew", 1, true) then
				table.insert(insertedArchetypes, "CelestialDew")
			elseif itemId:find("DemonBeastCore", 1, true) then
				table.insert(insertedArchetypes, "DemonBeastCore")
			elseif itemId:find("SpiritGrass", 1, true) then
				table.insert(insertedArchetypes, "SpiritGrass")
			end
		end
	end

	local matchedFormula: PillFormula? = nil

	for _, formula in pairs(FORMULAS) do
		local matchedAllReqs = true
		local tempArchetypes = table.clone(insertedArchetypes)

		for _, reqType in ipairs(formula.RequiredArchetypes) do
			local foundIndex: number? = nil
			for idx, arch in ipairs(tempArchetypes) do
				if arch == reqType then
					foundIndex = idx
					break
				end
			end

			if foundIndex then
				table.remove(tempArchetypes, foundIndex)
			else
				matchedAllReqs = false
				break
			end
		end

		if matchedAllReqs then
			matchedFormula = formula
			break
		end
	end

	if not matchedFormula then
		return nil, 0.15, 0.5, "Unknown Herb Mixture (High Furnace Ash Risk)"
	end

	local avgAge = if validHerbCount > 0 then (totalAge / validHerbCount) else 1

	local ageSuccessBonus = 0
	if avgAge >= 1000 then
		ageSuccessBonus = 0.40
	elseif avgAge >= 100 then
		ageSuccessBonus = 0.30
	elseif avgAge >= 10 then
		ageSuccessBonus = 0.15
	end

	local calculatedSuccessRate = math.clamp(matchedFormula.BaseSuccessRate + ageSuccessBonus, 0.10, 1.00)
	local potencyMult = 1.0 + (math.log10(math.max(1, avgAge)) * 0.5)

	local qualityText = "Standard Quality"
	if avgAge >= 1000 then
		qualityText = "Sovereign Immortal Quality"
	elseif avgAge >= 100 then
		qualityText = "Century Superior Quality"
	elseif avgAge >= 10 then
		qualityText = "Refined Medium Quality"
	end

	return matchedFormula, calculatedSuccessRate, potencyMult, qualityText
end

function AlchemyConfig.GetFormula(formulaId: string): PillFormula?
	return FORMULAS[formulaId]
end

function AlchemyConfig.GetAllFormulas(): { [string]: PillFormula }
	return FORMULAS
end

return AlchemyConfig