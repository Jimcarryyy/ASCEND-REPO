# Current Task Specification — ASCEND

## Purpose
This file defines the active milestone, current progress summary, and the exact tasks approved for immediate work. Use it as the primary guide for what to build now.

## Connectivity
- Read this file first when starting a new session.
- Use `.ai/PROJECT_STATUS.md` for subsystem health and completion context.
- Use `.ai/DECISIONS.md` for architectural decision records (ADR-001 to ADR-019).

---

## Active Milestone: Phase 7 — Core Gameplay Loop, World Gathering & Monetization Integration

### Task Status Summary

| Task ID | Task Description | Status | Verification |
| :--- | :--- | :--- | :--- |
| **Subtask 6.2C** | Codebase Pruning — Delete legacy files (`GauntletServer`, `SpearServer`, etc.) | **Completed** | Verified in Repo |
| **Subtask 6.2D** | Stat Normalization — Scale Qi/HP ($100 \rightarrow 10,000$) in `CultivationConfig.luau` | **Completed** | Verified in Studio |
| **Subtask 6.2E** | 3D Attachment Engine — Studio-Authoritative `RightGripAttachment` & `BodyBackAttachment` | **Completed** | Verified in Studio |
| **Subtask 6.2F** | UI/UX Overhaul — Light-Mode Flat 2D Xianxia Palette (`#1D4533`, `#F7EAE0`) | **Completed** | Verified in Studio |
| **Task 1** | Master Codebase Cleanup, DataStore V2 Reset & UI Refactor | **Completed** | Verified in Studio |
| **Task 7.1A** | World Resource Gathering System (Randomized Herb Ages: 1-Yr to 1,000-Yr) | **Completed** | Verified in Studio |
| **Task 7.1B** | Upgraded Manual 3-Slot Spirit Cauldron Alchemy Engine & Buff Pills | **Completed** | Verified in Studio |
| **Task 7.1C** | Environmental Qi Meditation Pads & Realm Breakthrough System | **Pending** | Active Next Task |
| **Task 7.1D** | Spirit Beast AI Spawning & Flying Sword Combat Testing | **Pending** | Planned |
| **Task 7.1E** | Sect Market Vendors & Monetization Integration | **Pending** | Planned |

---

# 🎯 CURRENT TASK: Task 7.1C — Qi Meditation & Realm Breakthrough System

## 📌 Active Objective
Execute the master implementation of the **Environmental Qi Meditation Pads** and **Realm Breakthrough Engine** across Zone 4 and Zone 2 streams.

---

## 📋 Task Checklist

- [ ] **Task 7.1C-1**: Place interactive **Meditation Stone Pads** in `workspace.MeditationPads` with `ProximityPrompt` `[F]` interaction.
- [ ] **Task 7.1C-2**: Implement server-authoritative Qi channeling in `CultivationManager.luau` using character sit/float animations, filling the `800 / 800` Qi bar $3.5\times$ faster than passive absorption.
- [ ] **Task 7.1C-3**: Implement **Realm Breakthrough Trials**: consuming a *Foundation Gathering Dan* when Qi is full triggers celestial golden aura particles via `CombatVFXController`, advances cultivator tiers (*Qi Condensation* $\rightarrow$ *Foundation Establishment*), increases permanent stats, and updates HUD titles.

# Current Task Specification — ASCEND

## Active Milestone: Phase 7 — Core Gameplay Loop, World Gathering & Monetization Integration

### Task Status Summary

| Task ID | Task Description | Status | Verification |
| :--- | :--- | :--- | :--- |
| **Task 1** | Master Codebase Cleanup, DataStore V2 Reset & UI Refactor | **Completed** | Verified in Studio |
| **Task 7.1A** | World Resource Gathering System (Randomized Herb Ages, Non-Disappearing Springs, Item Toasts) | **Completed** | Verified in Studio |
| **Task 7.1B** | Upgraded Manual 3-Slot Alchemy Engine (Flame Minigame, Quality Grades, Mastery EXP, 2D Icons) | **Completed** | Verified in Studio |
| **Task 7.1C** | Environmental Qi Meditation Pads & Realm Breakthrough System | **Pending** | Active Next Task |
| **Task 7.1D** | Spirit Beast AI Spawning & Flying Sword Combat Testing | **Pending** | Planned |
| **Task 7.1E** | Sect Market Vendors & Monetization Integration (HUD Skins & Gamepasses) | **Pending** | Planned |

---

# 🎯 CURRENT TASK: Task 7.1C — Qi Meditation & Realm Breakthrough System

## 📌 Active Objective
Execute the master implementation of the **Environmental Qi Meditation Pads** and **Realm Breakthrough Engine** across Zone 4 and Zone 2 streams.

---

## 📋 Task Checklist

- [ ] **Task 7.1C-1**: Place interactive **Meditation Stone Pads** in `workspace.MeditationPads` with `ProximityPrompt` `[F]` interaction.
- [ ] **Task 7.1C-2**: Implement server-authoritative Qi channeling in `CultivationManager.luau` using character sit/float animations, filling the `800 / 800` Qi bar $3.5\times$ faster than passive absorption.
- [ ] **Task 7.1C-3**: Implement **Realm Breakthrough Trials**: consuming a *Foundation Gathering Dan* when Qi is full triggers celestial golden aura particles via `CombatVFXController`, advances cultivator tiers (*Qi Condensation* $\rightarrow$ *Foundation Establishment*), increases permanent stats, and updates HUD titles.

# ACTIVE TASK: Task 7.1D — Spirit Beast AI & Hunting Engine

## Active Objective
Implementing server-authoritative wild Spirit Beast AI (e.g., *Ironhide Boar*, *Spirit Deer*, *Demon Wolf*) roaming the Sect outskirts, Verdant Bamboo Valley, and Crystal Caverns.

## Sub-Task Checklist
- [ ] **Task 7.1D-1: Beast Spawning & Territory Anchoring** — Spawner scripts in `workspace.BeastSpawns` anchoring beasts to regional biomes.
- [ ] **Task 7.1D-2: Server AI State Machine** — Implementing Patrol, Aggro/Chase, Attack, and Flee states using `PathfindingService` with multi-player spatial distance culling.
- [ ] **Task 7.1D-3: Health Bars & Drop Tables** — Attaching 3D health bars, hitboxes, death animations, and drop table rewards (*Spirit Beast Cores*, *Monster Hides*) for Alchemy Dan crafting.

---

## Recently Completed Milestone: Task 7.1C (Qi Meditation & Progression Overhaul)
- [x] 10 Major Realms (90 Orders) with $100\text{M}$ V1 stat scale.
- [x] 3-Tier Dantian Qi Architecture (`CurrentQi <= CultivatedQi <= MaxQiGoal`).
- [x] Grounded sitting meditation with golden aura highlights & audio (`103967342049425`).
- [x] Safe-zone Qi Multiplier Nodes (`workspace.QiNodes`).
- [x] DataStore V2 `CultivatedQi` persistence across rejoins, server shutdowns, and deaths.
- [x] Encouraging breakthrough guidance toast (*"Keep cultivating! Your Qi isn't ready for breakthrough yet."*).
- [x] Custom Xianxia Loading Screen (`LoadingScreen.client.luau`) in `ReplicatedFirst`.
- [x] R6 Locomotion Engine (`Animate.client.luau`) with LeftShift sprint, velocity-synced audio, 100% idle rotation lock, and 0.3s jump recovery debounce.
- [x] Environment Polish Pass: tree trunk collision filtering (`TreeCollisionManager.luau`), 12-min 4-phase Xianxia day/night lighting (`EnvironmentTimeManager.luau`), and organic gusting wind controller (`WindEnvironmentController.luau`).

# Current Task: Phase 7 — Version 1 Studio UI Hierarchy & Cross-Platform Polish

## Status: Active
- **Active Subtask:** Completing the Hybrid Studio UI setup (connecting custom Explorer ScreenGuis for Inventory, Alchemy, and Vitals to client controllers).
- **Completed in this session:**
  - Phase A (100% Server & Data Logic): `SectConfig`, `MonetizationConfig`, `PlayerDataManager` V2 schema, `VendorManager`, `SectManager`, `MobAIManager`, `ArenaManager`, `MarketplaceManager`.
  - Phase B (Initial UI Hooks): `QuestTrackerController`, `SkillBarController`, `MarketController`, and `HUDController` Top Menu.