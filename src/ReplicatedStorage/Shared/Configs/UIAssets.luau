--!strict
--[[
    UIAssets.luau
    Location: src/ReplicatedStorage/Shared/Configs/UIAssets.luau
    Centralized UI Asset Registry & Color Palette definitions for ASCEND.
]]

local UIAssets = {}

UIAssets.Icons = {
	HealthbarHUD            = "rbxassetid://107254331482831",
	FlameIcon               = "rbxassetid://98860036623590",
	GaleWindLotus           = "rbxassetid://97399822723211",
	GaleWindDan             = "rbxassetid://108842260002164",
	QiGatheringDan          = "rbxassetid://136942657595135",
	PhysiqueTemperingDan    = "rbxassetid://127548831742229",
	DemonBeastCore          = "rbxassetid://127840279619766",
	CelestialDew            = "rbxassetid://131403489720983",
	FoundationGatheringDan = "rbxassetid://135779673578731",
	SpiritAsh               = "rbxassetid://128820714120893",
	DragonBloodVine         = "rbxassetid://87215598829275",
	SpiritGrass             = "rbxassetid://112390155425328",
	SpiritHealingDan        = "rbxassetid://72471225624084",
}

UIAssets.GradeCardColors = {
	["Sovereign Immortal Quality"] = {
		Background = Color3.fromRGB(254, 226, 226), -- Soft Crimson
		Border     = Color3.fromRGB(225, 29, 72),   -- Ruby Red
	},
	["Century Superior Quality"]   = {
		Background = Color3.fromRGB(243, 232, 255), -- Soft Purple
		Border     = Color3.fromRGB(147, 51, 234),   -- Epic Purple
	},
	["Refined Medium Quality"]    = {
		Background = Color3.fromRGB(224, 242, 254), -- Soft Azure
		Border     = Color3.fromRGB(59, 130, 246),   -- Rare Blue
	},
	["Standard Quality"]          = {
		Background = Color3.fromRGB(209, 250, 229), -- Soft Emerald
		Border     = Color3.fromRGB(16, 185, 129),   -- Emerald Green
	},
}

UIAssets.RarityCardColors = {
	Mythic    = { Background = Color3.fromRGB(254, 226, 226), Border = Color3.fromRGB(225, 29, 72) },
	Legendary = { Background = Color3.fromRGB(254, 243, 199), Border = Color3.fromRGB(217, 119, 6) },
	Epic      = { Background = Color3.fromRGB(243, 232, 255), Border = Color3.fromRGB(147, 51, 234) },
	Rare      = { Background = Color3.fromRGB(224, 242, 254), Border = Color3.fromRGB(59, 130, 246) },
	Uncommon  = { Background = Color3.fromRGB(209, 250, 229), Border = Color3.fromRGB(16, 185, 129) },
	Common    = { Background = Color3.fromRGB(255, 255, 255), Border = Color3.fromRGB(203, 213, 225) },
}

return UIAssets