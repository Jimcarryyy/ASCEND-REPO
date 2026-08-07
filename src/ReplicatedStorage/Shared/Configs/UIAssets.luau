--!strict
--[[
    UIAssets.luau
    Central asset registry mapping all UI visual elements to Roblox Asset IDs.
    Includes Light-Mode Flat 2D UI color palette.
]]

export type AssetCategory = "HUD" | "Panels" | "Weapons" | "Skills" | "Currencies" | "StatusEffects"

local UIAssets = {
	Colors = {
		MainPanel = Color3.fromRGB(248, 250, 249),      -- #F8FAF9 Crisp Light Panel
		CardBackground = Color3.fromRGB(241, 245, 249), -- #F1F5F9 Soft Slate Card
		BorderStroke = Color3.fromRGB(203, 213, 225),   -- #CBD5E1 Muted Slate Border
		TextPrimary = Color3.fromRGB(15, 23, 42),       -- #0F172A Deep Charcoal Text
		TextMuted = Color3.fromRGB(100, 116, 139),      -- #64748B Muted Subtext
		HealthFill = Color3.fromRGB(16, 185, 129),      -- #10B981 Jade Emerald Green
		QiFill = Color3.fromRGB(59, 130, 246),          -- #3B82F6 Sapphire Blue
	},
	HUD = {
		ReticleDot = "rbxassetid://91967824711199",
		SlotBase = "rbxassetid://130801066203315",
		KeyBadge = "rbxassetid://100047016230704",
		BossFrame = "rbxassetid://135743022798866",
		SlotActive = "rbxassetid://101243757444363",
		TribulationBar = "rbxassetid://116053311300978",
		CooldownMask = "rbxassetid://122590929808037",
	},
	Panels = {
		HeaderBanner = "rbxassetid://98859547252438",
		ModalBG = "rbxassetid://107541216755976",
		DividerLine = "rbxassetid://84097505475730",
		ButtonPrimary = "rbxassetid://85491533300951",
		GridSlot = "rbxassetid://102206331438130",
	},
	Weapons = {
		FlyingSword = "rbxassetid://91700918054626",
		Robes = "rbxassetid://89364653325641",
		TalismanBanner = "rbxassetid://80831618004196",
		Pendant = "rbxassetid://82725794143925",
		Ring = "rbxassetid://91941666846046",
	},
	Skills = {
		M1_SwordArt = "rbxassetid://105049604836680",
		M2_HeavySlam = "rbxassetid://112434505017874",
		DragonRoar = "rbxassetid://125652382062875",
		ParryQiShield = "rbxassetid://102896450348273",
		DodgeWindstep = "rbxassetid://112980465072041",
		TribulationBolt = "rbxassetid://128833809862475",
		HundredPalms = "rbxassetid://99885781952768",
		SwordTempest = "rbxassetid://78370022706412",
	},
	Currencies = {
		SpiritStoneLow = "rbxassetid://86714482204043",
		SpiritStoneHigh = "rbxassetid://103503361995261",
		PillBreakthrough = "rbxassetid://126575322817243",
		PillQiGathering = "rbxassetid://88019278886655",
		HerbGinseng = "rbxassetid://109989287833700",
		DemonCore = "rbxassetid://99733786523930",
	},
	StatusEffects = {
		BodyTempered = "rbxassetid://132857904784003",
		QiDeviation = "rbxassetid://75594204304893",
		TribulationBurn = "rbxassetid://84311417281254",
		Poison = "rbxassetid://105584493403425",
	},
}

return UIAssets