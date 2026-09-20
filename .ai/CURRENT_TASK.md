# ASCEND — Active Task: Phase 2 Codebase Hardening & UI Drawer Integration

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Roadmap Status:** Phase 1 Verified Closed (5/5) | Phase 2 Active

---

## 🎯 Active Focus

Execute **Phase 2: Codebase Cleanup & Unified Drawer Controller Wiring**:
1. Complete wiring of docked drawer panels (`CharacterStatsController`, `BloodlineController`, embedded `CodexController`) to live server state without independent hotkeys or close buttons.
2. Finalize server-authoritative fixes for herb gathering channeled hold delay, strict Spirit Grass matching, and single-kill Rogue Disciple quest progression.
3. Complete memory leak audit across `characterConnections` and enforce `--!strict` typing.

---

## 📋 Task Verification & Acceptance Checklist

### Phase 1: Core Foundation & Verification (COMPLETED & CLOSED)
- [x] DataVersion 3 persistence with Samsara cycle tracking and Roman numeral title generator.
- [x] Studio Monkey Verification: 9/9 server checks passed (collision groups, network ownership, anti-ragdoll states).
- [x] Murim Spawn Dais pad fix (`CanCollide = true`, `Anchored = true`, `Neutral = true`).
- [x] Network remote pruning: 16 legacy unused remotes purged; 16 active remotes typed with `--!strict`.
- [x] Mob roster standardization: 10 Humanoid R6 Cultivators configured with `SPAWNER_ALIAS_MAP`.

### Phase 2: Architecture Cleanup, Anti-Pattern Purge & UI Integration (ACTIVE)
- [x] **Anti-Trip Physics Hardening:** Created `AntiTripServer` in `StarterCharacterScripts` with R6-safe pcall guard.
- [x] **MainHub Master Drawer:** Scaffolding complete with CoreGui top-bar button, sharp Fondamento sidebar, and zero bottom-seam overscan.
- [x] **Spirit Pouch Docking:** `Page_Inventory` docked, red `X` purged, pop-up tween removed, independent `I` keybind stripped.
- [x] **Sect Pavilion Docking:** `Page_Faction` docked, red `X` purged, `M` keybind stripped, 24h stipend persistence verified.
- [ ] **Bloodline Altar Wiring:** Resolve `Page_Bloodline` button interaction and `DecisionModal` gacha flow.
- [ ] **Codex Integration:** Finalize `Page_Archives` topic switching and purge legacy `StarterGui.CodexGui` infinite yield.
- [ ] **Gathering Channeled Delay:** Verify server-side 1.8s hold duration in `GatheringManager.luau` and single-count quest tracking.
- [ ] **Memory Leak & Connection Lifecycle Audit:**
  - Audit all `characterConnections` across `CombatStateManager.luau`, `CultivationManager.luau`, and `SkillBarController.luau`.
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