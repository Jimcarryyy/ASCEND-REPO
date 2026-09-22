--!strict
--[[
    UIAssets.luau
    Location: src/ReplicatedStorage/Shared/Configs/UIAssets.luau
    Centralized UI Asset Registry & Color Palette definitions for ASCEND.
    Theme: Blackened Lacquer + Aged Gold + Jade Cultivation + Spiritual Blue.
]]

local UIAssets = {}

UIAssets.Icons = {
	HealthbarHUD            = "rbxassetid://107254331482831",
	SkillBoxHUD             = "rbxassetid://97080305696865",
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

-- Master Design Tokens
UIAssets.Theme = {
	DeepBackground   = Color3.fromHex("#111827"), -- 70% Dark Navy Charcoal
	SecondarySurface = Color3.fromHex("#1C2638"), -- 15% Dark Blue-Gray
	RaisedSurface    = Color3.fromHex("#273246"), -- Elevated Card Surface
	MainBorder       = Color3.fromHex("#8B6B32"), -- Antique Bronze-Gold Frame
	HighlightBorder  = Color3.fromHex("#C49A4A"), -- Warm Celestial Gold
	PrimaryText      = Color3.fromHex("#F1E8D2"), -- Warm Ivory Text
	SecondaryText    = Color3.fromHex("#A9A99F"), -- Muted Gray-Beige Subtitle
	JadeAccent       = Color3.fromHex("#10B981"), -- HP / Vitality / Positive Action
	SpiritBlue       = Color3.fromHex("#3B82F6"), -- Qi Energy / Info
	CyanHighlight    = Color3.fromHex("#22D3EE"), -- Active Glow
	Vermilion        = Color3.fromHex("#E63946"), -- Warning / Danger / Drop
	AmberRank        = Color3.fromHex("#D97706"), -- Sect Rank / Premium Accent
}

-- Dark Charcoal Card Backgrounds with Accent Rarity Borders
UIAssets.RarityCardColors = {
	Mythic    = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#E11D48"), Text = Color3.fromHex("#FDA4AF") },
	Legendary = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#F59E0B"), Text = Color3.fromHex("#FDE68A") },
	Epic      = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#A855F7"), Text = Color3.fromHex("#E9D5FF") },
	Rare      = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#3B82F6"), Text = Color3.fromHex("#BFDBFE") },
	Uncommon  = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#10B981"), Text = Color3.fromHex("#A7F3D0") },
	Common    = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#64748B"), Text = Color3.fromHex("#E2E8F0") },
}

-- Quality Grade Accent Borders
UIAssets.GradeCardColors = {
	["Sovereign Immortal Quality"] = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#E11D48") },
	["Century Superior Quality"]   = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#A855F7") },
	["Refined Medium Quality"]    = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#3B82F6") },
	["Standard Quality"]          = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#10B981") },
}

return UIAssets