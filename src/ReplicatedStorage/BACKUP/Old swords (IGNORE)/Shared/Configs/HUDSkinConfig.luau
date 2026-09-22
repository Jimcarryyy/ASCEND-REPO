--!strict
--[[
    HUDSkinConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/HUDSkinConfig.luau
    Central configuration repository for all monetized HUD Skins in ASCEND.
    Stores Asset IDs, rarities, Robux pricing, and slot coordinate offset mappings.
]]

export type SlotOffsetData = {
	HPSlotPosition: UDim2?,
	HPSlotSize: UDim2?,
	QISlotPosition: UDim2?,
	QISlotSize: UDim2?,
	PortraitPosition: UDim2?,
	PortraitSize: UDim2?,
	LevelBadgePosition: UDim2?,
	NameAndRealmPosition: UDim2?,
}

export type HUDSkin = {
	SkinId: string,
	Name: string,
	Description: string,
	AssetId: string,
	Rarity: string,
	PriceRobux: number?,
	SlotOffsets: SlotOffsetData,
}

local HUDSkinConfig = {}

local SKINS: { [string]: HUDSkin } = {
	["DefaultBronze"] = {
		SkinId = "DefaultBronze",
		Name = "Immortal Bronze HUD",
		Description = "The classic bronze-trimmed Xianxia vital gauge.",
		AssetId = "rbxassetid://107254331482831",
		Rarity = "Common",
		PriceRobux = 0,
		SlotOffsets = {
			HPSlotPosition = UDim2.new(0, 152, 0, 50),
			HPSlotSize     = UDim2.new(0, 250, 0, 26),
			QISlotPosition = UDim2.new(0, 152, 0, 86),
			QISlotSize     = UDim2.new(0, 250, 0, 26),
			PortraitPosition = UDim2.new(0, 12, 0, 12),
			PortraitSize     = UDim2.new(0, 128, 0, 128),
			LevelBadgePosition = UDim2.new(0, 95, 0, 102),
			NameAndRealmPosition = UDim2.new(0, 150, 0, 16),
		},
	},
	["SakuraImmortal"] = {
		SkinId = "SakuraImmortal",
		Name = "Sakura Immortal HUD",
		Description = "Enchanted rose-gold HUD embellished with cherry blossom petals.",
		AssetId = "rbxassetid://74345518999533", -- Replace with uploaded Sakura asset ID when generated
		Rarity = "Legendary",
		PriceRobux = 250,
		SlotOffsets = {
			HPSlotPosition = UDim2.new(0, 152, 0, 50),
			HPSlotSize     = UDim2.new(0, 250, 0, 26),
			QISlotPosition = UDim2.new(0, 152, 0, 86),
			QISlotSize     = UDim2.new(0, 250, 0, 26),
			PortraitPosition = UDim2.new(0, 12, 0, 12),
			PortraitSize     = UDim2.new(0, 128, 0, 128),
			LevelBadgePosition = UDim2.new(0, 95, 0, 102),
			NameAndRealmPosition = UDim2.new(0, 150, 0, 16),
		},
	},
	["AzureDragon"] = {
		SkinId = "AzureDragon",
		Name = "Azure Cloud Realm HUD",
		Description = "Celadon and azure cloud HUD infused with immortal sky mist.",
		AssetId = "rbxassetid://107254331482831", -- Replace with uploaded Azure Cloud asset ID when generated
		Rarity = "Mythic",
		PriceRobux = 500,
		SlotOffsets = {
			HPSlotPosition = UDim2.new(0, 152, 0, 50),
			HPSlotSize     = UDim2.new(0, 250, 0, 26),
			QISlotPosition = UDim2.new(0, 152, 0, 86),
			QISlotSize     = UDim2.new(0, 250, 0, 26),
			PortraitPosition = UDim2.new(0, 12, 0, 12),
			PortraitSize     = UDim2.new(0, 128, 0, 128),
			LevelBadgePosition = UDim2.new(0, 95, 0, 102),
			NameAndRealmPosition = UDim2.new(0, 150, 0, 16),
		},
	},
}

function HUDSkinConfig.GetSkin(skinId: string): HUDSkin
	return SKINS[skinId] or SKINS["DefaultBronze"]
end

function HUDSkinConfig.GetAllSkins(): { [string]: HUDSkin }
	return SKINS
end

return HUDSkinConfig