# Current Task Specification — ASCEND

## Purpose
Defines the active milestone, progress summary, and approved tasks for immediate work.

## Connectivity
- Read this file first each session.
- `.ai/PROJECT_STATUS.md` — subsystem health and completion context.
- `.ai/DECISIONS.md` — architectural decision records (ADR-001 to ADR-019).

---

## Active Milestone: Phase 7 — Core Gameplay Loop, World Gathering & Monetization Integration

| Task ID | Description | Status |
| :--- | :--- | :--- |
| 6.2C | Codebase Pruning — delete legacy files (`GauntletServer`, `SpearServer`, etc.) | ✅ Completed |
| 6.2D | Stat Normalization — scale Qi/HP (100 → 10,000) in `CultivationConfig.luau` | ✅ Completed |
| 6.2E | 3D Attachment Engine — Studio-authoritative `RightGripAttachment` & `BodyBackAttachment` | ✅ Completed |
| 6.2F | UI/UX Overhaul — Light-Mode Flat 2D Xianxia palette (`#1D4533`, `#F7EAE0`) | ✅ Completed |
| 1 | Master Codebase Cleanup, DataStore V2 Reset & UI Refactor | ✅ Completed |
| 7.1A | World Resource Gathering (randomized herb ages, non-disappearing springs, item toasts) | ✅ Completed |
| 7.1B | Manual 3-Slot Alchemy Engine (flame minigame, quality grades, mastery EXP, 2D icons) | ✅ Completed |
| 7.1C | Environmental Qi Meditation Pads & Realm Breakthrough System | ✅ Completed |
| **7.1D** | **Spirit Beast AI Spawning & Flying Sword Combat Testing** | 🟡 **Active** |
| 7.1E | Sect Market Vendors & Monetization Integration (HUD skins & gamepasses) | ⬜ Planned |

---

## 🎯 CURRENT TASK: Task 7.1D — Spirit Beast AI & Hunting Engine

### Objective
Server-authoritative wild Spirit Beast AI (*Ironhide Boar*, *Spirit Deer*, *Demon Wolf*) roaming the Sect outskirts, Verdant Bamboo Valley, and Crystal Caverns.

### Checklist
- [ ] **7.1D-1 — Beast Spawning & Territory Anchoring**: Spawner scripts in `workspace.BeastSpawns`, anchored to regional biomes.
- [ ] **7.1D-2 — Server AI State Machine**: Patrol / Aggro-Chase / Attack / Flee via `PathfindingService`, with multi-player spatial distance culling.
- [ ] **7.1D-3 — Health Bars & Drop Tables**: 3D health bars, hitboxes, death animations, drop tables (*Spirit Beast Cores*, *Monster Hides*) for Alchemy Dan crafting.

---

## Recently Completed: Task 7.1C — Qi Meditation & Progression Overhaul
- [x] 10 Major Realms (90 Orders), 100M V1 stat scale.
- [x] 3-Tier Dantian Qi Architecture (`CurrentQi ≤ CultivatedQi ≤ MaxQiGoal`).
- [x] Grounded sitting meditation, golden aura highlights, audio (`103967342049425`).
- [x] Safe-zone Qi Multiplier Nodes (`workspace.QiNodes`).
- [x] DataStore V2 `CultivatedQi` persistence across rejoins, shutdowns, deaths.
- [x] Breakthrough guidance toast ("Keep cultivating! Your Qi isn't ready for breakthrough yet.").
- [x] Custom Xianxia Loading Screen (`LoadingScreen.client.luau`, `ReplicatedFirst`).
- [x] R6 Locomotion Engine (`Animate.client.luau`) — LeftShift sprint, velocity-synced audio, idle rotation lock, 0.3s jump recovery debounce.
- [x] Environment Polish — tree collision filtering (`TreeCollisionManager.luau`), 4-phase day/night lighting (`EnvironmentTimeManager.luau`), wind controller (`WindEnvironmentController.luau`).

---

## Backlog — Deferred From Earlier Sessions
*(Not scheduled; revisit after 7.1E)*

- [ ] **Flying Sword Flight Mode (御剑飞行)** — `V` toggle, sword-mount-under-feet, 3D omnidirectional flight physics with camera pitch/yaw steering + banking, realm-scaled speed (65 → 140+ studs/s).
- [ ] **Center-Reticle Skill Aim Trajectory** — wire Telekinesis Thrust (`E`), Sword Barrage (`R`), Tempest (`Q`) to camera-center raycast.
- [ ] **Bottom-Center Vital & Sword Intent HUD** — redesigned HP/Qi/Sword Intent frame in Studio.
- [ ] **Tier 5–8 Sword Model Integration** — `VioletSoulSovereignJian`, `VoidStarCleaverDao`, `AzurePatriarchHeritageJian`, `RadiantImmortalSovereignJian`.