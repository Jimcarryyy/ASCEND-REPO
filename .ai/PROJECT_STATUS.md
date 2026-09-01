# ASCEND — Project Status Overview

## Purpose
This file reports the current phase status and subsystem readiness. It reflects **one current state only** — historical progress belongs in `CHANGELOG.md`, not here. Do not append new snapshots to this file; replace the relevant section instead.

**Last consolidated:** 2026-09-02, from `CHANGELOG.md` (most recent dated entry: 2026-08-27) cross-checked against live source files.

> ⚠️ Completion percentages are intentionally omitted. Prior figures (92%, 95%, 98%, 99%) were session-local estimates that stacked without reconciliation and the developer has confirmed they were inflated. Do not restate a percentage here without explicit developer sign-off.

---

## Subsystem Health & Readiness

| Subsystem | Status | Key Modules | Notes |
| :--- | :--- | :--- | :--- |
| **Sword Combat Engine** | 🟢 Implemented | `CombatStateManager`, `HitboxManager`, `WeaponManager`, `FlyingSwordServer` | 5-hit M1 combo, `T` Block/Perfect Parry, Posture/Guard-Break, 0.6s CC-immunity buffer, sword clashes |
| **Cultivation Engine** | 🟢 Implemented | `CultivationManager`, `CultivationConfig` | 10 Major Realms × 9 Orders (90 total). See `PROGRESSION_SPEC.md` for corrected numbers |
| **1v1 Sparring Arena** | 🟢 Implemented | `ArenaManager` | Dual-pad matchmaking, 3s countdown, 1,000 HP normalization, non-lethal concession |
| **Data Persistence** | 🟢 Implemented | `PlayerDataManager` | `DataStoreService` key `"ASCEND_PlayerData_V2"`, 5-min autosave |
| **Inventory & Items** | 🟢 Implemented | `ItemConfig`, `InventoryManager`, `InventoryController` | 60 slots, `Tab`/`I` toggle, 3D viewport previews, rarity-tinted cards |
| **World Gathering** | 🟢 Implemented | `GatheringConfig`, `GatheringManager`, `GatheringController` | Weighted herb-age rolls, non-disappearing spring nodes |
| **Spirit Cauldron Alchemy** | 🟢 Implemented | `AlchemyConfig`, `AlchemyManager`, `AlchemyController` | 3-slot manual combination, flame minigame, quality grades, Mastery EXP |
| **Sect Affairs & Quests** | 🟢 Implemented | `SectConfig`, `SectManager` | 3-tier daily quests, Contribution Points, 6 disciple ranks |
| **Market / Monetization** | 🟢 Implemented | `MonetizationConfig`, `MarketplaceManager`, `VendorManager` | Gamepasses + DevProducts defined — **verify live Creator Dashboard IDs are populated, not placeholders** |
| **Day/Night & Environment** | 🟢 Implemented | `EnvironmentTimeManager`, `TreeCollisionManager`, `WindEnvironmentController` | 12-min 4-phase cycle, trunk-only collision, organic wind sway |
| **R6 Locomotion** | 🟢 Implemented | `Animate.client.luau` (referenced in ADR-029, not yet in this manifest — flag for World role) | Idle lock, sprint, jump recovery debounce, anti-ragdoll |
| **UI/UX Suite** | 🟢 Implemented | `UIAssets`, `HUDSkinConfig`, `HUDController` | **Dark Obsidian & Antique Gold palette is live** (confirmed in `UIAssets.luau`) — light-mode Xianxia palette is superseded, do not use |
| **Zone Mobs & AI** | 🟢 Implemented | `MobConfig`, `MobAIManager` | Pathfinding patrol/aggro/attack/leash state machine |
| **Flying Sword Flight Mode** | 🟡 **Active / Next** | — | `V`-key toggle, horizontal foot-mount, 3D omnidirectional flight, realm-scaled speed (65→140+ studs/s). Not yet confirmed in source. |
| **Bottom-Center Vital HUD Redesign** | 🟡 **Active / Next** | — | HP/Qi/Sword Intent gauge relayout in Studio `StarterGui` |
| **Tier 5–8 Sword Assets** | 🟡 **Active / Next** | — | `VioletSoulSovereignJian`, `VoidStarCleaverDao`, `AzurePatriarchHeritageJian`, `RadiantImmortalSovereignJian` — import/mount status unconfirmed |
| **Spirit Beast AI / Hunting** | ⚪ **Status unclear** | — | Appears as "next task" in one CURRENT_TASK.md session block but is absent from the most recent (2026-08-27) next-steps list. **Needs developer confirmation: shipped, in progress, or deprioritized?** |
| **Sect Leaderboards** | ⚪ **Unconfirmed** | `LeaderboardManager.luau` | Designed and drafted per `DECISIONS.md`/`NEXT_STEPS.md` history but **not verified present in the live repo tree**. Treat as proposed until fetched and confirmed. |

---

## Known Live Contradictions Still Needing a Developer Ruling
(Resolved items removed — see `DECISIONS.md` ADR-031 for the full resolution log.)

1. **`UIAssets.RarityCardColors` has 8 keys** (`Common…Mythic` + `Sovereign`, `Celestial`) that don't match `RarityConfig.luau`'s 6-tier system (`Mortal…Immortal`). This is a live code-level mismatch, not just a docs one. Are `Sovereign`/`Celestial` reserved for a future rarity expansion, or should they be removed?
2. Monetization: are the Gamepass/DevProduct IDs in `MonetizationConfig.luau` real live Creator Dashboard IDs, or still placeholders?
3. Whether zones are actually playable end-to-end without bugs — the developer has flagged this as not true despite prior "100% Operational" claims. Needs a real playtest pass before this file claims anything is "Operational."

## Repository Documentation Directory Map
```text
ASCEND-REPO/
├── docs/
│   ├── ARCHITECTURE_SPEC.md
│   ├── COMBAT_SPEC.md
│   ├── PROGRESSION_SPEC.md
│   ├── ASSET_MANIFEST.md
│   ├── GAME_DESIGN.md
│   ├── UI_UX_SPEC.md
│   ├── CODEBASE_CLEANUP_GUIDE.md
│   ├── CODE_DEPENDENCY_GUIDE.md
│   ├── ROBLOX_PERFORMANCE_RULES.md
│   └── AI_PROMPT_GUIDE.md
└── .ai/
    ├── CURRENT_TASK.md
    ├── PROJECT_STATUS.md
    ├── DECISIONS.md
    ├── NEXT_STEPS.md
    ├── CHANGELOG.md
    └── AI_REPOSITORY_SCANNING_GUIDE.md   # stale — still references deleted Gauntlet/Spear files, needs a pass
```