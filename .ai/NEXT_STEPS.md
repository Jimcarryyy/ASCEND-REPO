# Next Steps & Project Roadmap — ASCEND

## Purpose
This file lays out the next planned development milestones and future roadmap. Use it after completing current objectives or when planning upcoming phases.

## Connectivity
- Follows `.ai/CURRENT_TASK.md` and `.ai/PROJECT_STATUS.md`.
- Points to active Phase 7 and future Phase 8 work.

---

## 🚀 Immediate Next Steps (Phase 7: Core Loop & World Gathering)

### 1. Zone 1 & Zone 2 Herb Gathering Node System (Task 7.1A) — [COMPLETED]
- [x] Place physical 3D harvestable herb nodes in `workspace.GatheringNodes` (`SpiritGrass`, `DragonBloodVine`, `GaleWindLotus`, `CelestialSpring`, `JadeOre`).
- [x] Add `ProximityPrompt` `[E]` interaction to harvest herbs directly into the player's Spirit Pouch (`K`).
- [x] Implement node respawn timers (12-to-30-second cooldown) and weighted random herb age rolls (1-Yr to 1,000-Yr).
- [x] Connect audio playback for `SoundService.GatherHerbsSound` on harvest.

### 2. Upgraded Manual 3-Slot Spirit Cauldron Alchemy Engine (Task 7.1B) — [COMPLETED]
- [x] Refactor `AlchemyConfig.luau`, `AlchemyManager.luau`, and `AlchemyController.luau` for manual 3-slot herb selection.
- [x] Add dynamic age-based success calculations (higher herb ages boost success rate up to 100% and potency up to 3.0x).
- [x] Add craftable buff pills: *Spirit Healing Dan*, *Qi Gathering Dan* (2x Meditation Speed), *Physique Tempering Dan* (+35% Damage), *Gale Wind Dan* (+40% Flight Speed), and *Foundation Gathering Dan*.

### 3. Environmental Qi Meditation Pads & Realm Breakthroughs (Task 7.1C) — [ACTIVE NEXT TASK]
- [ ] Place interactive **Meditation Stone Pads** (`workspace.MeditationPads`) in Zone 4 / Zone 2 streams.
- [ ] Implement meditation channeling (**[F]** key / ProximityPrompt) with `Celestial Float System` pose to fill the `800 / 800` Qi bar $3.5\times$ faster than passive absorption.
- [ ] Implement **Realm Breakthrough Trials**: consuming a *Foundation Gathering Dan* when Qi is full triggers celestial golden aura particles, advances cultivator tiers (*Qi Condensation* $\rightarrow$ *Foundation Establishment*), increases permanent stats, and updates HUD titles.

### 4. Spirit Beast AI Spawning & Flying Sword Combat (Task 7.1D)
- [ ] Spawn wild spirit beasts in Zone 2 to fight with Flying Swords.
- [ ] Implement beast loot drops (`DemonBeastCore`) on death.

### 5. Sect Market Vendors & Monetization Integration (Task 7.1E)
- [ ] Set up shop vendor NPCs in Zone 1 (Azure Sect Hub) to trade Spirit Stones and process Roblox Developer Products / GamePasses.

---

## 🔮 Future Roadmap (Phase 8 & Beyond)

### Phase 8: Xianxia World Expansion & Monetization
- [ ] Add Gamepass Store (Auto-Meditate, $2\times$ Qi Speed, Tribulation Protection Pills).
- [ ] Add Leaderboards (Highest Realm Rank, Top Sword Mastery).


---\n
## 🚀 Immediate Next Steps (Phase 7: Core Loop & World Gathering)

### 1. Zone 1 & Zone 2 Herb Gathering Node System (Task 7.1A) — [COMPLETED]
- [x] Place physical 3D harvestable herb nodes in `workspace.GatheringNodes`.
- [x] Add `ProximityPrompt` `[E]` interaction and animated on-screen Item Toast banners (`HUDController.ShowItemToast`).
- [x] Support non-disappearing nodes (`KeepModelVisible = true` for `CelestialSpring`).

### 2. Upgraded Manual 3-Slot Spirit Cauldron Alchemy Engine (Task 7.1B) — [COMPLETED]
- [x] Add interactive Qi Flame Temperature Control minigame in `AlchemyController.luau`.
- [x] Add Quality-Grade Metadata (*Standard*, *Refined Medium*, *Century Superior*, *Sovereign Immortal*) and stack separation.
- [x] Add persistent Alchemy Mastery EXP and Leveling (*Apprentice Alchemist* $\rightarrow$ *Pill Emperor*).
- [x] Register 12 2D PNG asset icons and implement dynamic quality/rarity card background tinting.

### 3. Monetized Xianxia HUD & Action Skill Bar Integration — [COMPLETED]
- [x] Integrate custom HUD template `rbxassetid://107254331482831` (`VitalHUDFrame`) with headshot portrait, level badge (`100`), display name, green HP fill, and blue QI fill.
- [x] Build `HUDSkinConfig.luau` supporting `DefaultBronze`, `SakuraImmortal`, and `AzureDragon` with auto-aligning slot offset mappings.
- [x] Bind `ActionSkillBar` slots (`Slot_E`, `Slot_F`, `Slot_M1`, `Slot_Q`, `Slot_R`, `Slot_Shift`) with background `rbxassetid://97080305696865`, keybind badges, and dynamic skill cooldown swipe overlays.

### 4. Environmental Qi Meditation Pads & Realm Breakthroughs (Task 7.1C) — [ACTIVE NEXT TASK]
- [ ] Place interactive **Meditation Stone Pads** (`workspace.MeditationPads`) in Zone 4 / Zone 2 streams.
- [ ] Implement meditation channeling (**[F]** key / ProximityPrompt) with `Celestial Float System` pose to fill the `800 / 800` Qi bar $3.5\times$ faster than passive absorption.
- [ ] Implement **Realm Breakthrough Trials**: consuming a *Foundation Gathering Dan* when Qi is full triggers celestial golden aura particles, advances cultivator tiers (*Qi Condensation* $\rightarrow$ *Foundation Establishment*), increases permanent stats, and updates HUD titles.


# NEXT STEPS ROADMAP

## Immediate Focus (Phase 7 Remaining)
1. **Task 7.1D — Spirit Beast AI & Hunting Engine:**
   - Server-side Pathfinding AI for wild beasts (*Ironhide Boar*, *Spirit Deer*, *Demon Wolf*) in Bamboo Valley, Ice Crags, and Magma Ridge.
   - Drop tables for *Beast Cores* and *Monster Hides* used in advanced Alchemy Breakthrough Pills.
2. **Task 7.1E — Sect Market Vendors & Monetization Engine:**
   - Interactive Market NPCs in Sect Sanctuary with `ProximityPrompt` interaction.
   - Equippable HUD Skin GUI (`DefaultBronze`, `SakuraImmortal`, `AzureDragon`).
   - Spirit Stone currency transactions, item buying/selling, and Roblox Gamepass / Developer Product integration.

## Future Phase Roadmap
1. **Cultivation Realm Breakthrough Rewards System (Manhwa/Manhua Advancement):**
   - Physical & spiritual advancements per realm conquered (*Body Tempering*, *Golden Bones*, *Meridian Talent Nodes*, *Divine Spirit Consciousness*).
2. **World Boss Battles & Sovereign Sword Peak Arena (Zone 5):**
   - Multi-phase World Boss encounters, flying sword flight showcases, and raid mechanics.
3. **Upper Realm / Divine Plane Expansion (Post-V1):**
   - Expanding beyond the 10 Major Realms ($100\text{M}$ V1 Cap) into Trillions/Quintillions Divine Realms in future expansion updates.

   # Immediate Next Steps for Next Session

1. **Complete Hybrid UI Studio Hookup for Remaining Modals:**
   - Hook Studio Explorer frames for `SpiritPouchGui` (Inventory) and `SpiritCauldronGui` (Alchemy) to `InventoryController.luau` and `AlchemyController.luau`.
   - Update `VitalHUDGui` in Studio to match the dark obsidian and gold talisman styling.
2. **End-to-End Gameplay Loop Testing in 2-Player Test Mode:**
   - Test full progression: Gather Herbs -> Brew Pills -> Defeat R6 Mobs -> Submit Sect Quests -> Gain Contribution -> Promote Disciple Rank -> Duel in 1v1 Arena -> Buy/Sell in Market.
3. **Roblox Creator Dashboard Setup:**
   - Create and input live Gamepass IDs and Developer Product IDs into `MonetizationConfig.luau`.
4. **Final Zone 1 Map Placement:**
   - Verify physical placement of `workspace.MarketVendors`, `workspace.QuestNPCs`, `workspace.MobSpawns`, and `workspace.SparringArena` parts.


   # Immediate Development Roadmap

## Phase 7 Next Steps:

### 1. Flying Sword Flight Engine (御剑飞行)
* Toggle flight mode via `V` keybind.
* Position sword horizontally under cultivator's feet (`HumanoidRootPart.FlightSwordMount`).
* Smooth 3D omnidirectional flight physics (W/S pitch & thrust, A/D strafe, Space ascend, Shift descend).
* Aerodynamic banking tilt when turning.
* Cultivation realm flight speed scaling (Base: 65 -> Peak: 140+ studs/sec).

### 2. Center-Reticle Combat Aiming Trajectory
* Cast sword skill projectiles (Telekinesis Thrust `E`, Sword Tempest `Q`, Falling Sky Slam `F`) directly toward the center focus reticle in 3D world space.

### 3. Complete Remaining 4 Sword Assets (Tiers 5–8)
* Generate, import, add SurfaceAppearance, and attach `SwordAttachment` + `BackSwordAttachment` for:
  * `VioletSoulSovereignJian` (Tier 5 Legendary)
  * `VoidStarCleaverDao` (Tier 6 Mythic)
  * `AzurePatriarchHeritageJian` (Sect Prestige)
  * `RadiantImmortalSovereignJian` (VIP / Celestial)