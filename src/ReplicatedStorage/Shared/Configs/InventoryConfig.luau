--!strict
-- InventoryConfig.luau
-- Data schema and 3D placeholder item configuration for inventory items.

export type ItemCategory = "Weapon" | "Herb" | "Core" | "Pill" | "Material"

export type InventoryItem = {
	ItemId: string,
	DisplayName: string,
	Category: ItemCategory,
	MaxStack: number,
	Description: string,
	PlaceholderMeshId: string?,
	PlaceholderColor: Color3,
}

local InventoryConfig = {}

InventoryConfig.Items = {
	mat_spirit_herb = {
		ItemId = "mat_spirit_herb",
		DisplayName = "Spirit Gathering Herb",
		Category = "Herb",
		MaxStack = 99,
		Description = "A radiant leaf infused with raw natural Qi.",
		PlaceholderColor = Color3.fromRGB(46, 204, 113), -- Green
	} :: InventoryItem,

	mat_demon_core = {
		ItemId = "mat_demon_core",
		DisplayName = "Demon Beast Core",
		Category = "Core",
		MaxStack = 50,
		Description = "A crystallized core harvested from an enraged Demonic Beast.",
		PlaceholderColor = Color3.fromRGB(155, 89, 182), -- Purple
	} :: InventoryItem,

	pill_qi_gathering = {
		ItemId = "pill_qi_gathering",
		DisplayName = "Qi Gathering Pill",
		Category = "Pill",
		MaxStack = 20,
		Description = "Restores Qi and boosts meditation gathering rate.",
		PlaceholderColor = Color3.fromRGB(52, 152, 219), -- Blue
	} :: InventoryItem,

	pill_healing_dan = {
		ItemId = "pill_healing_dan",
		DisplayName = "Spirit Healing Dan",
		Category = "Pill",
		MaxStack = 20,
		Description = "Restores 40% of Maximum Health over 5 seconds.",
		PlaceholderColor = Color3.fromRGB(231, 76, 60), -- Red
	} :: InventoryItem,
}

function InventoryConfig.GetItem(itemId: string): InventoryItem?
	return InventoryConfig.Items[itemId]
end

return InventoryConfig