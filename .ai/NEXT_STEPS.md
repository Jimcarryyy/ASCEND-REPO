# Next Steps & Project Roadmap — ASCEND

## Purpose
This document outlines planned upcoming engineering and design milestones for ASCEND, ordered strictly by priority.

**Consolidation Date:** September 2026 (Post-Developer Message 183)

---

## Phase 8.2 Roadmap: Desktop HUD Rebuild & Core Polish

### 1. Immediate Priority (Active Milestone)
- **Desktop HUD Construction in Studio (`StarterGui.MasterHUDGui`):**
  - Build the 5-cluster Desktop HUD layout natively in Studio:
    - *Top-Center:* Floating status & harvest toast notification container.
    - *Bottom-Center:* Dual-gradient HP bar (`#10B981`), Azure Qi bar (`#3B82F6`), Amber Sword Intent gauge (`#F59E0B`), and 6-slot skill hotbar (`M1`, `Q`, `E`, `F`, `T`, `Shift`).
    - *Top-Left:* Daily Sect Duty tracker card.
    - *Top-Right:* Currency counters for Spirit Stones and Contribution Points (CP).
    - *Bottom-Left:* Navigation button tray (`[Bag]`, `[Sect]`, `[Map]`, `[Meditate]`, `[Settings]`).
  - Set `DisplayOrder = 1` and enforce typography: `Bangers` with black `UIStroke` for headers/labels and `Fundamento` for body stats.
- **Client Controller Re-wiring:**
  - Update `HUDController.luau`, `SkillBarController.luau`, and `QuestTrackerController.luau` to bind directly to the new `MasterHUDGui` elements without runtime `Instance.new` generation.
  - Verify seamless toggle behavior between the HUD and lower facility modals (`BlacksmithGui`, `TeaHouseGui`, `SparringGuidanceGui`, `StarterGuideGui`, `AlchemyCauldronGui`).

### 2. High Priority (Upcoming Core Feature)
- **Flying Sword Flight Mode (御剑飞行):**
  - Implement `V` key flight toggle in `InputController.luau` (with corresponding mobile touch button).
  - Attach flying sword horizontally beneath character feet using `HumanoidRootPart.FlightSwordMount`.
  - Build 3D omnidirectional flight physics with dynamic roll banking on turns.
  - Scale flight speed dynamically by Cultivation Realm (`65` studs/s at Qi Condensation -> `140+` studs/s at Immortal Ascension).

### 3. Medium Priority (World Dressing & Production Audit)
- **Zone 1 World Asset & NPC Placement Audit:**
  - Finalize placement of `workspace.MarketVendors`, `workspace.QuestNPCs`, `workspace.MobSpawns`, and `workspace.GatheringNodes`.
  - Ensure all 9 Zone 1 NPCs have calibrated R6 rigs, idle animations, weapon back-mounts, and ProximityPrompts.
  - Verify smooth collision on all stairs, wedges, and plinths across the 3 elevation tiers to ensure zero character tripping.
- **Creator Dashboard Monetization Audit:**
  - Audit live Gamepass IDs and DevProduct IDs in `MonetizationConfig.luau` against active Roblox Creator Dashboard assets.

---

## Future Roadmap (Phase 9+)

- **Zone 2 Wilderness (Verdant Bamboo & Beast Domain):**
  - Activate transition through the Wilderness Portal (`DaoistFeng`).
  - Roaming beast AI: Ironhide Boars, Shadow Wind Wolves, and rare vintage herb groves (100-Yr / 1,000-Yr).
- **Sect Leaderboards:**
  - Merge and activate `LeaderboardManager.luau` with dual `OrderedDataStore` backends for Top Cultivators (Realm/Order) and Sect Contribution Points.
- **Heavenly Tribulation Lightning Visuals:**
  - Dynamic lightning arc strikes and screen flash shaders during Major Breakthroughs (Order 9 -> Order 1 of next Realm).