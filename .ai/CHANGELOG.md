# CHANGELOG

## Purpose
This document tracks released and unreleased changes, feature additions, and architectural updates for ASCEND.

## Connectivity
- Use this file to audit historical development and ensure documentation aligns with actual progress.
- Pair it with `.ai/PROJECT_STATUS.md` to confirm which milestones are reflected in the current release state.

---

## [Unreleased] - 2026-08-08 — Phase 6.2 Completion & Ultra-Scaled Down MVP Architecture

### Added
- **Subtask 6.2C: Codebase Pruning & Pure Sword Paradigm**:
  - Deleted legacy non-sword weapon files (`GauntletServer.luau`, `SpearServer.luau`, `GauntletConfig.luau`, `SpearConfig.luau`).
  - Refactored `CombatStateManager.luau`, `ItemConfig.luau`, and `WeaponManager.luau` to route 100% of attack actions exclusively through Flying Swords.
- **Subtask 6.2D: Stat Curve Normalization ($100 \rightarrow 10,000$ HP/Qi Scale)**:
  - Scaled stat progression across all 5 Cultivation Realms (45 Orders) to a clean $100 \rightarrow 10,000$ HP / Qi scale in `CultivationConfig.luau`.
  - Rebalanced skill Qi consumption and added pure fallback bounds calculations.
- **Subtask 6.2E: Studio-Authoritative 3D Attachment Engine**:
  - Refactored `WeaponManager.luau` to read `RightGripAttachment` and `BodyBackAttachment` positioned visually inside 3D models in Studio + live CMD calibration.
  - Implemented 3D bounds scale normalization ensuring consistent $4.5$-stud sword lengths and $3.5$-stud crest bounds across all imported FBX models.
  - Added recursive searching (`ReplicatedStorage:FindFirstChild(modelName, true)`) to locate models nested inside tier folders (`Mythic tier`, `Rare tier`, etc.).
- **Subtask 6.2F: Traditional Xianxia Light-Mode UI/UX Palette Overhaul**:
  - Updated `UIAssets.luau`, `HUDController.luau`, `InventoryController.luau`, and `AlchemyController.luau` to the **Traditional Xianxia Palette**:
    - `#1D4533` (Deep Jade Green — Headers, Text, Borders, HP)
    - `#F7EAE0` (Warm Cream White — Main Modal Panel)
    - `#F9D2BA` (Soft Peach Accent — Cards & Grid Slots)
    - `#5E3122` (Rich Mahogany Wood — Buttons, Subtext, Qi)
  - Applied soft tinted rarity background colors to all Spirit Pouch grid slots.
  - Fixed inspection header text wrapping so long names like *Azure Spirit-Jade Crest Array (碧蓝灵铠)* fit without overlapping modal borders.
- **Master Item Database Registration (32 Equipment Items / 16 Sets)**:
  - Registered all 16 Cultivation Equipment Sets (Common, Uncommon, 5 Rare variations, 3 Epic, 2 Legendary, 4 Mythic) in `ItemConfig.luau`.
  - Standardized all 16 back armor names to end strictly with **`Crest Array`**.
- **60-Slot Spirit Pouch & On-Demand Inventory Sync Engine**:
  - Expanded storage capacity from 30 to 60 slots in `InventoryManager.luau` and `InventoryController.luau`.
  - Implemented client-side `RequestSync` on toggle (`K`) and server-side `EnsureTestItems` force-injecting all 32 equipment items into DataStore profiles for 1-click testing.

---

## [Unreleased] - 2026-08-06 — Pure Sword Cultivator Pivot & High-Number Scale

### Added
- Pivoted core combat paradigm from multi-weapon archetype switching to **Pure Sword Cultivation**.
- Designed the **Dynamic Jade Scripture / Sword Art Scroll System**.
- Implemented DataStore persistence engine in `PlayerDataManager.luau`.