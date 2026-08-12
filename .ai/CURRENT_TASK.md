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