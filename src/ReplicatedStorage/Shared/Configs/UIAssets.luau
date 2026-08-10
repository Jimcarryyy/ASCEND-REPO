--!strict
--[[
    UIAssets.luau
    Location: src/ReplicatedStorage/Shared/Configs/UIAssets.luau
    Central UI asset and aesthetic style configuration for ASCEND.
    Unified Light-Mode Flat 2D Palette (Matching Alchemy Cauldron Aesthetic).
]]

export type ColorPalette = {
	LightMain: Color3,     -- #F8FAF9 Window Main
	LightPanel: Color3,    -- #F1F5F9 Sub-Panels
	LightCard: Color3,     -- #FFFFFF Cards & Slots
	LightBorder: Color3,   -- #CBD5E1 Edge Borders
	TextMain: Color3,      -- #0F172A Deep Charcoal Text
	TextSub: Color3,       -- #64748B Muted Subtext
	AzureBlue: Color3,     -- #3B82F6 Sapphire Blue (Qi)
	EmeraldGreen: Color3,  -- #10B981 Emerald Green (HP)
	ActionGold: Color3,    -- #D97706 Warm Amber Gold
	DangerRed: Color3,     -- #E11D48 Carmine Red
}

export type RarityColorMap = {
	Common: Color3,
	Uncommon: Color3,
	Rare: Color3,
	Epic: Color3,
	Legendary: Color3,
	Mythic: Color3,
}

local UIAssets = {}

-- Unified Light-Mode Aesthetic Color Palette
UIAssets.Palette = {
	LightMain    = Color3.fromRGB(248, 250, 249), -- #F8FAF9
	LightPanel   = Color3.fromRGB(241, 245, 249), -- #F1F5F9
	LightCard    = Color3.fromRGB(255, 255, 255), -- #FFFFFF
	LightBorder  = Color3.fromRGB(203, 213, 225), -- #CBD5E1
	TextMain     = Color3.fromRGB(15, 23, 42),    -- #0F172A
	TextSub      = Color3.fromRGB(100, 116, 139), -- #64748B
	AzureBlue    = Color3.fromRGB(59, 130, 246),  -- #3B82F6
	EmeraldGreen = Color3.fromRGB(16, 185, 129), -- #10B981
	ActionGold   = Color3.fromRGB(217, 119, 6),   -- #D97706
	DangerRed    = Color3.fromRGB(225, 29, 72),   -- #E11D48
}

-- Rarity Colors matching Alchemy Cauldron theme
UIAssets.RarityColors = {
	Common    = Color3.fromRGB(100, 116, 139), -- Slate Muted
	Uncommon  = Color3.fromRGB(16, 185, 129),  -- Emerald Green
	Rare      = Color3.fromRGB(59, 130, 246),  -- Sapphire Blue
	Epic      = Color3.fromRGB(147, 51, 234),  -- Spiritual Purple
	Legendary = Color3.fromRGB(217, 119, 6),   -- Flame Gold
	Mythic    = Color3.fromRGB(225, 29, 72),   -- Crimson Immortal
}

-- Typography Configuration (FredokaOne Bold Sans-Serif)
UIAssets.Fonts = {
	Header    = Enum.Font.FredokaOne,
	SubHeader = Enum.Font.FredokaOne,
	Body      = Enum.Font.SourceSans,
	BodyBold  = Enum.Font.SourceSansBold,
}

-- Image Assets
UIAssets.Images = {
	ParchmentBackground = "",
	JadeFrameBorder     = "",
	QiBarFill           = "",
	CrestSlotFrame      = "",
	SwordIcon           = "",
	PillIcon            = "",
}

function UIAssets.GetColor(colorName: string): Color3
	local color = (UIAssets.Palette :: { [string]: Color3 })[colorName]
	return color or UIAssets.Palette.LightMain
end

function UIAssets.GetRarityColor(rarity: string): Color3
	local color = (UIAssets.RarityColors :: { [string]: Color3 })[rarity]
	return color or UIAssets.RarityColors.Common
end

return UIAssets