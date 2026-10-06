--!strict
--[[
    UIAssets.luau
    Location: src/ReplicatedStorage/Shared/Configs/UIAssets.luau
    Centralized UI Asset Registry & Audio Definitions for ASCEND.
]]

local UIAssets = {}

UIAssets.Audio = {
	MenuSelect     = "rbxassetid://138567614125924", -- HUD Menu Open / Select SFX
	PanelClick     = "rbxassetid://101735926591481", -- Panel Button & Slot Click SFX
	ExplorationBGM = "rbxassetid://137280276426447", -- Looping Background Music
	SwordEquip     = "rbxassetid://114060318185092", -- Sword Equip / Draw (Hand)
	SwordUnequip   = "rbxassetid://97568182472477",  -- Sword Unequip / Sheath (Back)
}

UIAssets.Icons = {
	HealthbarHUD           = "rbxassetid://107254331482831",
	SkillBoxHUD            = "rbxassetid://97080305696865",
	FlameIcon              = "rbxassetid://98860036623590",
	GaleWindLotus          = "rbxassetid://97399822723211",
	GaleWindDan            = "rbxassetid://108842260002164",
	QiGatheringDan         = "rbxassetid://136942657595135",
	PhysiqueTemperingDan   = "rbxassetid://127548831742229",
	DemonBeastCore         = "rbxassetid://127840279619766",
	CelestialDew           = "rbxassetid://131403489720983",
	FoundationGatheringDan = "rbxassetid://135779673578731",
	SpiritAsh              = "rbxassetid://128820714120893",
	DragonBloodVine        = "rbxassetid://87215598829275",
	SpiritGrass            = "rbxassetid://112390155425328",
	SpiritHealingDan       = "rbxassetid://72471225624084",

	-- Universal Sword Placeholder Icon (NewWeapons Roster)
	SwordPlaceholder       = "rbxassetid://109157084266033",

	-- 10 Canonical Weapons
	IronReed               = "rbxassetid://109157084266033",
	BronzeDiscipline       = "rbxassetid://109157084266033",
	EarthboundSteel        = "rbxassetid://109157084266033",
	WanderingBlade         = "rbxassetid://109157084266033",
	CraneAmidstClouds      = "rbxassetid://109157084266033",
	ResonantHeart          = "rbxassetid://109157084266033",
	HollowMoon             = "rbxassetid://109157084266033",
	AscendantGold          = "rbxassetid://109157084266033",
	VoidPurity             = "rbxassetid://109157084266033",
	HeavenPiercing         = "rbxassetid://109157084266033",

	-- Studio Folder Name Aliases
	["1.Iron Reed"]           = "rbxassetid://109157084266033",
	["2.Bronze Discipline"]   = "rbxassetid://109157084266033",
	["3.Earthbound Steel"]    = "rbxassetid://109157084266033",
	["4.Wandering Blade"]     = "rbxassetid://109157084266033",
	["5.Crane Amidst Clouds"] = "rbxassetid://109157084266033",
	["6.Resonant Heart"]      = "rbxassetid://109157084266033",
	["7.Hollow Moon"]         = "rbxassetid://109157084266033",
	["8.Ascendant Gold"]      = "rbxassetid://109157084266033",
	["9.Void Purity"]         = "rbxassetid://109157084266033",
	["10.Heaven-Piercing"]    = "rbxassetid://109157084266033",

	-- Legacy Sword Tiers (Retained for Backwards Compatibility)
	MortalIronJian              = "rbxassetid://109157084266033",
	AzureCloudDiscipleJian      = "rbxassetid://115690610892281",
	FlowingQiSpiritSword        = "rbxassetid://85610178645930",
	VerdantJadeFlyingSword      = "rbxassetid://114181885052834",
	VioletSoulSovereignJian     = "rbxassetid://102454036931672",
	VoidStarCleaverDao          = "rbxassetid://73201319689599",
	AzurePatriarchHeritageJian  = "rbxassetid://129279811461089",
	RadiantImmortalSovereignJian= "rbxassetid://131309720641215",
}

-- Master Design Tokens
UIAssets.Theme = {
	DeepBackground   = Color3.fromHex("#111827"),
	SecondarySurface = Color3.fromHex("#1C2638"),
	RaisedSurface    = Color3.fromHex("#273246"),
	MainBorder       = Color3.fromHex("#8B6B32"),
	HighlightBorder  = Color3.fromHex("#C49A4A"),
	PrimaryText      = Color3.fromHex("#F1E8D2"),
	SecondaryText    = Color3.fromHex("#A9A99F"),
	JadeAccent       = Color3.fromHex("#10B981"),
	SpiritBlue       = Color3.fromHex("#3B82F6"),
	CyanHighlight    = Color3.fromHex("#22D3EE"),
	Vermilion        = Color3.fromHex("#E63946"),
	AmberRank        = Color3.fromHex("#D97706"),
}

-- Rarity Card Colors
UIAssets.RarityCardColors = {
	Celestial = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#F8FAFC"), Text = Color3.fromHex("#1E232A") },
	Sovereign = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#22D3EE"), Text = Color3.fromHex("#A5F3FC") },
	Mythic    = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#E11D48"), Text = Color3.fromHex("#FDA4AF") },
	Legendary = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#F59E0B"), Text = Color3.fromHex("#FDE68A") },
	Epic      = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#A855F7"), Text = Color3.fromHex("#E9D5FF") },
	Rare      = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#3B82F6"), Text = Color3.fromHex("#BFDBFE") },
	Uncommon  = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#10B981"), Text = Color3.fromHex("#A7F3D0") },
	Common    = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#64748B"), Text = Color3.fromHex("#E2E8F0") },
}

UIAssets.GradeCardColors = {
	["Sovereign Immortal Quality"] = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#F8FAFC"), Text = Color3.fromHex("#1E232A") },
	["Century Superior Quality"]   = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#F59E0B"), Text = Color3.fromHex("#FDE68A") },
	["Refined Medium Quality"]     = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#3B82F6"), Text = Color3.fromHex("#BFDBFE") },
	["Standard Quality"]           = { Background = Color3.fromHex("#1C2638"), Border = Color3.fromHex("#64748B"), Text = Color3.fromHex("#E2E8F0") },
}

-- Fonts
UIAssets.Fonts = {
	Header = Enum.Font.LuckiestGuy,
	Body   = Enum.Font.FredokaOne,
	Accent = Enum.Font.Fondamento,
}

return UIAssets