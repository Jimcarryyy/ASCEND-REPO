# ASCEND — Project Status Overview

## Purpose
This document provides the authoritative, single-state operational status of the ASCEND repository. It reflects the live codebase across all 16 server managers, 20 client controllers, shared configurations, and functional world stations, incorporating all bugfixes, world shifts, and design mandates up through Phase 8.2.

**Consolidation Date:** September 2026 (Post-Developer Message 183)  
**Master Persistence Key:** `ASCEND_PlayerData_V2`  
**Avatar Rig Standard:** Roblox R6 Standard Rig  
**Palette Standard:** Dark Obsidian (`#111827`) & Antique Bronze-Gold (`#8B6B32` / `#C49A4A`)  
**Typography Standard:** `Bangers` (Titles/Headers with Black UIStroke) & `Fundamento` (Body/Descriptions)  
**Active Operational Focus:** Clean Desktop HUD Rebuild in Studio (`StarterGui.MasterHUDGui`)

---

## Subsystem Health & Operational Readiness

| Subsystem | Status | Core Script / Module Architecture | Implementation Details & Live Capabilities |
| :--- | :---: | :--- | :--- |
| **Desktop HUD Suite** | 🟡 Active Rebuild | `StarterGui.MasterHUDGui`, `HUDController`, `SkillBarController`, `QuestTrackerController` | Legacy HUD hidden due to modal overlap. Active rebuild in progress: 5-cluster desktop layout (Toasts top-center, Vitals/Skills bottom-center, Duties top-left, Currency top-right, Menu tray bottom-left). `DisplayOrder = 1`. |
| **Sword Combat Engine** | 🟢 Operational | `CombatStateManager`, `HitboxManager`, `WeaponManager`, `FlyingSwordServer`, `FlyingSwordConfig` | 5-hit broadsword M1 chain with footwork damping (`WalkSpeed = 8`). Looping Sword Intent (+25%/hit, 1.75× empowered strike at 100%). `T` Guard (80% mitigation) & Perfect Parry (0.22s window, 100% negation, +5% Qi). 100-pt Posture & Guard-Break (1.2s stun, +25% vulnerability). 0.6s hyperarmor buffer. |
| **Blacksmithing Facility** | 🟢 Operational | `BlacksmithManager`, `BlacksmithController`, `StarterGui.BlacksmithGui` | Bound to `Sect_NPC_MadameTie` & `Master Blacksmith Anvil`. Weapon refinement up to +10 (+5% base ATK per level). Blade sharpening (100 Spirit Stones, +10% Crit for 15 min). Crash fixed (`nil` index on prompt hook resolved). |
| **Spirit Tea Pavilion** | 🟢 Operational | `TeaHouseManager`, `TeaHouseController`, `StarterGui.TeaHouseGui` | Bound to `Sect_NPC_XiaoLing`. 3 distinct brews: Jade Dew (+250 Qi, +10% Meditate speed), Crimson Ginseng (+500 HP, +15% Health regen), Dragon Well (+15% Sword Intent gain). Crash fixed (`math.min` nil check resolved). |
| **Training Grounds & Sparring** | 🟢 Operational | `ImmortalDummyHandler`, `SparringGuidanceController`, `StarterGui.SparringGuidanceGui` | 3 Ironwood Dummies in `Workspace.Functional_Stations.Sect_TrainingGround`. Server-authoritative damage logging, rolling 5s DPS calculation, floating damage numbers overhead. NPC guidance at `Sect_NPC_InstructorWu`. Reset DPS hook active. |
| **Starter Guidance System** | 🟢 Operational | `StarterGuideController`, `StarterGui.StarterGuideGui` | 4-tab interactive onboarding kiosk bound to `Sect_NPC_ElderQing`: Controls & Movement, Cultivation & Breakthroughs, Sword Intent & Blades, Sect Duties & Arena. Prompt collision bug fixed (no longer opens Sect Pavilion). |
| **Cultivation Engine** | 🟢 Operational | `CultivationManager`, `CultivationConfig` | 10 Major Realms × 9 Orders (90 total stages). Tripartite Dantian architecture (`CurrentQi <= CultivatedQi <= MaxQiGoal`). 100% preserved Qi on breakthrough (`B` key). Percentage skill costs (M1: 0%, Shift: 3%, F: 10%, E: 12%, Q: 15%, R: 30%). |
| **1v1 Sparring Arena** | 🟢 Operational | `ArenaManager`, `ArenaController`, `StarterGui.ArenaGUI` | Circular stone arena with impassable perimeter wall. Physical dual-pad standby (`DuelPad1` / `DuelPad2`), 3-second countdown with auto-abort, 1,000 HP stat normalization, non-lethal concession resolution, `RequestStreamAroundAsync` streaming protection. |
| **Data Persistence** | 🟢 Operational | `PlayerDataManager` | Server-authoritative `DataStoreService` under key `ASCEND_PlayerData_V2`. 5-minute autosave loop, safe session locking, disconnect saves, and developer item injection hooks (`Han_jueee`). |
| **Inventory & Items** | 🟢 Operational | `ItemConfig`, `InventoryManager`, `InventoryController`, `StarterGui.SpiritPouchInventoryGui` | 60-slot storage, 2D high-res weapon icons across 8 sword tiers, quality-grade metadata stacking, manual slot movement, item inspection modal. |
| **World Gathering** | 🟢 Operational | `GatheringConfig`, `GatheringManager`, `GatheringController` | Weighted herb age rolls (1-Yr, 10-Yr, 100-Yr, 1,000-Yr). Persistent water spring collection (`KeepModelVisible = true`). Screen toasts on harvest. |
| **Spirit Cauldron Alchemy** | 🟢 Operational | `AlchemyConfig`, `AlchemyManager`, `AlchemyController`, `StarterGui.AlchemyCauldronGui` | 3-slot manual herb combination, needle-slider flame minigame, quality-grade pill output (Standard -> Sovereign Immortal), persistent Alchemy EXP & rank progression. Migrated from hardcoded code UI to Studio-authoritative GUI. |
| **Sect Economy & Duties** | 🟢 Operational | `SectConfig`, `SectManager`, `VendorManager`, `SectController`, `QuestTrackerController` | 6 Disciple ranks, 3-tier daily duties (Herbs, Alchemy, Sparring), market buying/selling, exact Contribution Point syncing (`1,970 CP`), daily stipends. |
| **R6 Locomotion Engine** | 🟢 Operational | `src/StarterPlayer/StarterCharacterScripts/Animate.client.luau` | Custom R6 movement pipeline overriding default scripts. Idle yaw pinning, velocity-synced walk/run audio, cliff-fall height filter, jump recovery debounce, anti-ragdoll state locking. |
| **Environment & Day/Night**| 🟢 Operational | `EnvironmentTimeManager`, `TreeCollisionManager`, `WindEnvironmentController` | 12-minute 4-phase day/night lighting cycle, trunk-only collision filtering, organic desynchronized wind sway with spatial culling (<160 studs). |
| **Zone Mobs & AI** | 🟢 Operational | `MobConfig`, `MobAIManager` | R6 humanoid mobs (`RogueDisciple`, `DemonWolf`, `IronhideBoar`), pathfinding state machine, leash mechanics, realm-scaled rewards. |
| **Monetization Engine** | 🟡 Testing | `MonetizationConfig`, `MarketplaceManager` | Gamepass perk verification and DevProduct receipt handling. Live Creator Dashboard asset IDs require final production audit. |
| **Flying Sword Flight Mode** | 🟡 Queued Next | `FlyingSwordConfig`, `InputController` | `V`-key flight toggle, horizontal foot mount, omnidirectional 3D flight physics, realm-scaled speed (65 -> 140+ studs/s). |

---

## Zone 1 (Jade Pure Sect) Interactive NPC Roster

| NPC Identifier | World Elevation Tier | Station / Structure | Bound Function / System | Associated Controller / Manager |
| :--- | :---: | :--- | :--- | :--- |
| `Sect_NPC_MadameTie` | Tier 1 (Lower) | Blacksmith Forge / Anvil | Weapon Refinement (+10) & Blade Sharpening | `BlacksmithManager` / `BlacksmithController` |
| `Sect_NPC_XiaoLing` | Tier 1 (Lower) | Spirit Tea Pavilion | 3 Spirit Teas, Instant Recovery & Timed Buffs | `TeaHouseManager` / `TeaHouseController` |
| `Sect_NPC_InstructorWu`| Tier 1 (Lower) | Sect Training Grounds | Sparring Trials & Training Dummy DPS Tracking | `SparringGuidanceController` / `ImmortalDummyHandler` |
| `Sect_NPC_ElderQing` | Tier 1 (Lower) | Sect Central Plaza | 4-Tab Interactive Starter & Systems Guide | `StarterGuideController` |
| `Sect_NPC_MasterShen` | Tier 1 (Lower) | Bronze Alchemy Cauldron | Cauldron Crafting & Flame Temperature Minigame | `AlchemyManager` / `AlchemyController` |
| `Sect_NPC_DeaconZhao` | Tier 1 (Lower) | Sect Notice Board | 3-Tier Daily Duties & Bounty Submissions | `SectManager` / `QuestTrackerController` |
| `Sect_NPC_StewardJin` | Tier 1 (Lower) | Sect Exchange Pavilion | Dynamic Weapon Catalog & Loot Merchant | `VendorManager` / `MarketController` |
| `Sect_NPC_DaoistFeng` | Tier 1 (Lower) | Wilderness Gateway | Zone 2 Beast Domain Portal Transition | `WorldManager` (Planned) |
| `Ancestor Han` | Tier 1 (Lower) | Hidden Seclusion Alcove| Seclusion Cultivation Boost Multiplier | `CultivationManager` |
| `Elder Liang` | Tier 3 (Upper) | Sect Elder Pavilion | Grand Sword Elder / Disciple Advancement | `SectManager` |
| `Supreme Sect Leader` | Tier 3 (Upper) | Sovereign Palace Dais | Sect Sovereign (Black Robe Aesthetic) | Lore / Ambient |
| `Top 7 Pillars of Sect`| Tier 3 (Upper) | Sovereign Bastion | 7 Elite Lore Masters (7 Paths of the Blade) | Lore / Ambient |

---

## Verified Central Network Architecture (`RemoteEvents.luau`)

All communication flows strictly through the 22 centralized RemoteEvents:
- **Combat & Locomotion (5):** `CombatAction`, `UpdateSkillState`, `SyncCooldown`, `CombatVFX`, `BossStateUpdate`
- **Cultivation & Progression (2):** `UpdateCultivation`, `DialogueEvent`
- **Economy & Inventory (4):** `InventoryAction`, `UpdateInventory`, `MarketAction`, `MonetizationAction`
- **World & Lower Layer Facilities (4):** `GatheringAction`, `AlchemyAction`, `BlacksmithAction`, `TeaHouseAction`
- **Sect & Duties (4):** `SectAction`, `UpdateSect`, `QuestAction`, `UpdateQuestTracker`
- **1v1 Sparring Arena (3):** `ArenaAction`, `ArenaRegister`, `ArenaMatchUpdate`