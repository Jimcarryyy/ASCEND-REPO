--!strict
--[[
    RarityConfig.luau
    Maps rarity tiers to Hex and Color3 values, display names, and rankings.
]]

export type RarityTier = "Mortal" | "Earth" | "Heaven" | "Spirit" | "Divine" | "Immortal"

export type RarityData = {
	Name: string,
	Rank: number,
	HexColor: string,
	Color: Color3,
}

local RarityConfig: { [RarityTier]: RarityData } = {
	Mortal = {
		Name = "Mortal (Common)",
		Rank = 1,
		HexColor = "#FFFFFF",
		Color = Color3.fromRGB(255, 255, 255),
	},
	Earth = {
		Name = "Earth (Uncommon)",
		Rank = 2,
		HexColor = "#38E54D",
		Color = Color3.fromRGB(56, 229, 77),
	},
	Heaven = {
		Name = "Heaven (Rare)",
		Rank = 3,
		HexColor = "#2192FF",
		Color = Color3.fromRGB(33, 146, 255),
	},
	Spirit = {
		Name = "Spirit (Epic)",
		Rank = 4,
		HexColor = "#9C2C77",
		Color = Color3.fromRGB(156, 44, 119),
	},
	Divine = {
		Name = "Divine (Legendary)",
		Rank = 5,
		HexColor = "#FFD700",
		Color = Color3.fromRGB(255, 215, 0),
	},
	Immortal = {
		Name = "Immortal (Mythic)",
		Rank = 6,
		HexColor = "#FF1E1E",
		Color = Color3.fromRGB(255, 30, 30),
	},
}

return RarityConfig