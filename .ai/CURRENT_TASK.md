# ASCEND — Active Task: Phase 2 Codebase Hardening & UI Drawer Integration

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Roadmap Status:** Phase 1 Closed | Phase 2 Active (In Progress)

---

## 🎯 Active Focus

Execute remaining items of **Phase 2: Codebase Cleanup & Unified Drawer Controller Wiring**:
1. Finalize **Codex Integration**: Complete `Page_Archives` topic switching and purge legacy `StarterGui.CodexGui` infinite yield.
2. Complete docked master drawer integration for `CharacterStatsController` (`Page_Stats`).
3. Complete memory leak audit across `characterConnections` in `CombatStateManager.luau`, `CultivationManager.luau`, and `SkillBarController.luau`.
4. Enforce `--!strict` typing across shared configs in `src/ReplicatedStorage/Shared/Configs/`.

---

## 📋 Task Verification & Acceptance Checklist

### Phase 1: Core Foundation & Verification (COMPLETED & CLOSED)
- [x] DataVersion 3 persistence with Samsara cycle tracking and Roman numeral title generator.
- [x] Studio Monkey Verification: 9/9 server checks passed (collision groups, network ownership, anti-ragdoll states).
- [x] Murim Spawn Dais pad fix (`CanCollide = true`, `Anchored = true`, `Neutral = true`).
- [x] Network remote pruning: 16 active remotes typed with `--!strict`.
- [x] Mob roster standardization: 10 Humanoid R6 Cultivators configured with `SPAWNER_ALIAS_MAP`.

### Phase 2: Architecture Cleanup, Anti-Pattern Purge & UI Integration (ACTIVE)
- [x] **Anti-Trip Physics Hardening:** Created `AntiTripServer` in `StarterCharacterScripts` with R6-safe pcall guard.
- [x] **MainHub Master Drawer:** Top-bar button, sharp Fondamento sidebar, and zero bottom-seam overscan.
- [x] **Spirit Pouch (Page_Inventory) Docking:** Cloned inventory panel into Master Drawer; disabled legacy standalone `SpiritPouchInventoryGui`.
- [x] **Sect Pavilion (Page_Faction) Docking:** Cloned Sect Pavilion into `Page_Faction`; disabled legacy `SectPavilionGui`; 24h stipend verified.
- [x] **Bloodline Altar & Gacha Engine Wiring:**
  - Resolved 9 client-server remote action mismatches (`ExchangeSpins`, `Spin`, `Spin10x`, `ClaimRoll`, `DiscardRoll`, `GetState`, `StateUpdate`, `RollDecide`, `RollDiscarded`).
  - Fixed `DecisionModal` text visibility (brought `LineageName` and `DecSummary` to `ZIndex = 35`).
  - Expanded Meridian Storage Vault to 5 slots in `VaultCard` (Slots 1–2 free; Slots 3–5 locked behind Robux unlock flow).
  - Built dynamic 35-card Gacha Roulette Reel in `ModalCard` with 3.2s exponential deceleration, rarity-tinted cards across all 12 lineages, near-miss suspense at Card 27, and golden impact flash.
- [x] **Universal 4-Slot Alchemy Engine & Pouch Integration:**
  - Overhauled all 13 formulas in `AlchemyConfig.luau` (4 utility + 9 Breakthrough Dans) to require strict 4-herb combinations.
  - Expanded Cauldron slots in `AlchemyGui` to 4 slots (`Slot1`, `Slot2`, `Slot3`, `Slot4`) and corrected `Slot4.SlotHeader`.
  - Rebuilt `RecipeScrollFrame` into an auto-scrolling catalog rendering all 13 formulas with celestial gold styling on Breakthrough Dans.
  - Upgraded `HerbScrollFrame` to `AutomaticCanvasSize.Y` with `(0, 0)` auto-reset, removing the 9-slot ceiling.
  - Non-selectively consolidated 100% of inventory Mats and Supplies by `ItemId` with combined stack counts, eliminating all duplicates while barring weapons/gear.
  - Added multi-item stack safety validation in `AlchemyManager.luau` before deducting ingredients.
- [x] **Gathering to Inventory Pipeline Fix:**
  - Resolved server crash by importing missing `ItemConfig` require at line 18 of `GatheringManager.luau`.
  - Decoupled `ResolveNode` from `activeNodes` cooldown state so nodes and configs resolve regardless of cooldown.
  - Fixed prompt disabling/re-enabling across all 57 nodes in `Workspace.GatheringNodes`.
  - Added `ActionFailed` fail-safe in `GatheringManager` and `GatheringController`, preventing progress bar freezing on depleted nodes.
  - Expanded player inventory capacity from 60 to **100 slots** across `InventoryManager.luau`, `InventoryController.luau`, and `AlchemyController.luau`.
- [x] **Sect Exchange Pavilion (Merchant Market):**
  - Updated `MarketController.luau` to accept both raw inventory tables and `{ Inventory = ... }` payloads from `updateInventoryRemote`.
  - Updated `VendorManager.luau` to send live inventory on `RequestMarketData` and `TransactionSuccess (Sell)`, eliminating the "No tradeable loot" bug.
- [ ] **Codex Integration:** Finalize `Page_Archives` topic switching and purge legacy `StarterGui.CodexGui` infinite yield.
- [ ] **CharacterStats Docking:** Dock `Page_Stats` into master drawer without standalone hotkey conflicts.
- [ ] **Memory Leak & Connection Lifecycle Audit:**
  - Audit `characterConnections` across `CombatStateManager.luau`, `CultivationManager.luau`, and `SkillBarController.luau`.
  - Audit cleanup routines on ProximityPrompts and temporary spatial queries.
- [ ] **Strict Typing & Schema Safety:**
  - Apply `--!strict` typing to all configs in `src/ReplicatedStorage/Shared/Configs/`.
  - Validate all data payloads across active `RemoteEvents`.

---

## 🚫 Explicit Constraints (Ground Rules)
1. **The Codebase is the Only Truth:** Never trust numbers in unverified documents over live scripts. If code and docs disagree, code wins.
2. **Unified Master Drawer Rule (ADR-065):** Independent panel hotkeys (`I`, `P`, `M`, `H`) and red `X` close buttons on docked panels are prohibited.
3. **Proximity Station Isolation (ADR-066):** Physical world stations (`AlchemyGui`, `StarterGuideGui`) must remain standalone in-world ProximityPrompts.
4. **No Dynamic UI via Code (ADR-041, ADR-069):** All UI hierarchies must reside natively in `StarterGui` with zero `UICorner` on panels.
5. **Humanoid R6 Integrity (ADR-062, ADR-076):** 100% of characters and enemies use standard Roblox R6 rigs. R15-only properties (like `StepHeight`) are prohibited.