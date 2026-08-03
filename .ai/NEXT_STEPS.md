# Next Steps & Immediate Priorities

## Immediate Tasks

1. **Task 5.2: Alchemy & Spirit Pill Crafting System**:
   - Create `ReplicatedStorage/Shared/Configs/AlchemyConfig.luau` for herb/core recipes and pill effects (*Breakthrough Pill, Qi Gathering Pill, Healing Pill*).
   - Create `ServerScriptService/Server/Cultivation/AlchemyManager.luau` to handle furnace crafting, recipe validation, and pill consumption.
   - Connect Inventory UI item usage for alchemy materials (`icon_mat_pill_breakthrough`, `icon_mat_herb_ginseng`, `icon_mat_demon_core`).

2. **Task 5.3: Heavenly Tribulation Lightning Event**:
   - Build server-authoritative Tribulation Lightning Strike event when attempting Golden Core or Nascent Soul breakthroughs.
   - Random lightning strike strikes down from the sky, requiring player dodge timing (Hotkey `Shift`) to survive the breakthrough.

3. **Phase 6: NPC AI & Boss Encounter Engines**:
   - Construct server-authoritative NPC enemy AI (*Demonic Beasts, Cultivator Rivals, Heavenly Demon Boss*).
   - Integrate `BossHealthBar` UI updates with live boss phase transitions.