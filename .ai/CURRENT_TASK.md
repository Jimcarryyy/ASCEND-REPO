# Current Task Specification — ASCEND

## Purpose
This file defines the active milestone, current progress summary, and the exact tasks approved for immediate work. Use it as the primary guide for what to build now.

## Connectivity
- Read this file first when starting a new session.
- Use `.ai/PROJECT_STATUS.md` for subsystem health and completion context.
- Use `.ai/DECISIONS.md` for architectural decision records (ADR-001 to ADR-016).

---

## Active Milestone: Phase 7 — Core Gameplay Loop, World Gathering & Monetization Integration

### Task Status Summary

| Task ID | Task Description | Status | Verification |
| :--- | :--- | :--- | :--- |
| **Subtask 6.2C** | Codebase Pruning — Delete legacy files (`GauntletServer`, `SpearServer`, etc.) | **Completed** | Verified in Repo |
| **Subtask 6.2D** | Stat Normalization — Scale Qi/HP ($100 \rightarrow 10,000$) in `CultivationConfig.luau` | **Completed** | Verified in Studio |
| **Subtask 6.2E** | 3D Attachment Engine — Studio-Authoritative `RightGripAttachment` & `BodyBackAttachment` | **Completed** | Verified in Studio |
| **Subtask 6.2F** | UI/UX Overhaul — Light-Mode Flat 2D Xianxia Palette (`#1D4533`, `#F7EAE0`) | **Completed** | Verified in Studio |
| **Task 7.1A** | Zone 1 Herb Gathering Node Engine (`Nine-Leaf Grass` & `Dragon Lotus`) | **Pending** | Active Next Task |
| **Task 7.1B** | Sect Sword Altar Gacha Engine (Spirit Stone rolling for Flying Swords) | **Pending** | Planned |
| **Task 7.1C** | Sector Teleportation Portal & Zone Boundary Anchors | **Pending** | Planned |

---

# 🎯 CURRENT TASK: Phase 7 — Core Gameplay Loop & World Gathering

## 📌 Active Objective
Execute the master implementation of the **Zone 1 Herb Gathering System**, **Sect Sword Altar Gacha Engine**, and **Sector Teleportation Portal**.

---

## 📋 Task Checklist

- [ ] **Task 7.1A**: Zone 1 Herb Gathering Node System (`Nine-Leaf Spirit Grass` & `Crimson Dragon Lotus` harvestable nodes with `ProximityPrompt` `[E]` interaction).
- [ ] **Task 7.1B**: Sect Sword Altar Gacha Engine (Spirit Stone rolling for Flying Swords from Common $\rightarrow$ Mythic).
- [ ] **Task 7.1C**: Zone Boundary Teleportation Portal & Boat System.