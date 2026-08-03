--!strict
--[[
    UIAssets.luau
    Central asset registry mapping all UI visual elements to Roblox Asset IDs.
    Populated with live project asset IDs.
]]

export type AssetCategory = "HUD" | "Panels" | "Weapons" | "Skills" | "Currencies" | "StatusEffects"

local UIAssets = {
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
		Spear = "rbxassetid://137933099173294",
		Robes = "rbxassetid://89364653325641",
		TalismanBanner = "rbxassetid://80831618004196",
		FlyingSword = "rbxassetid://91700918054626",
		Gauntlet = "rbxassetid://139039770600421",
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