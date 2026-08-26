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

  # Current Task & Work Session State

## Completed in this Session:
- [x] **5-Hit Heavy Broadsword Combo Engine:** Integrated 5-hit string (`MouseButton1`) with natural 1.0x speeds, fixed commitment durations (`0.40s – 0.54s`), anti-spam lockouts, and 1.3s pause reset back to Attack 1.
- [x] **2-Stage Repeatable Qi Dash (`LeftShift`):** 3.0s cooldown, ~18-stud burst distance (`LinearVelocity` with `ForceLimitMode.PerAxis`, Y-force clamped), smooth 0.08s deceleration decay, and sprint preservation when holding `W`.
- [x] **Dynamic Weapon Attachment & Sheath Engine (`WeaponManager.luau`):** Snaps between Hand (`RightGripAttachment`) and diagonal Back Sheath (`BackSwordMount` at 135°). Dedicated `R` key to sheath/draw (strictly locked during meditation).
- [x] **Grounded Meditation & Realm Aura:** `C` key toggle, custom R6 pose (`rbxassetid://129333803961409`), dynamic 10-realm color-tinted particle aura (`ReplicatedStorage["Full body aura"]`), and automatic back-sheathing.
- [x] **Locomotion & Physics Hardening:**
  - Double-Tap `W` to Sprint.
  - Dynamic Speed Scaling: Sector 3 Arena (**Walk: 16 | Sprint: 28**) vs Open World (**Walk: 18 | Sprint: 52**).
  - Combat Footwork Commitment: Movement dampens to `WalkSpeed = 8` during M1 swings for fair Arena PvP.
  - Idle Yaw Pinning: 100% eliminated slow 360° idle rotation drift.
  - Anti-Ragdoll Hardening: Permanently disabled `FallingDown`, `Ragdoll`, `PlatformStanding`, and `GettingUp`.
  - UI Input Gating: Sinks mouse attacks and Spacebar jumps while interacting with menus/alchemy.
- [x] **Focus Target Controller (`FocusTargetController.luau`):** Screen-center Azure Qi reticle with upper-body / RootPart yaw/pitch aiming (`LeftControl` / `MMB`).
- [x] **Spirit Pouch Hotkeys:** Replaced legacy `K` with `Tab` / `I` and exposed `InventoryController.Toggle()`.

## Next Immediate Tasks (Next Session):
- [ ] **Flying Sword Flight Mode (御剑飞行):**
  - Implement dedicated `V` key flight toggle.
  - Sword snaps beneath feet horizontally (`HumanoidRootPart.FlightSwordMount`).
  - True 3D omnidirectional flight physics with camera pitch/yaw steering and dynamic banking into turns.
- [ ] **Center-Reticle Skill Aim Trajectory:**
  - Wire Telekinesis Thrust (`E`), Sword Barrage (`R`), and Tempest (`Q`) to unleash along the exact camera-center reticle raycast trajectory.
- [ ] **Generate Remaining 4 Swords (Tiers 5–8):**
  - Generate, import, pivot, and hook `VioletSoulSovereignJian`, `VoidStarCleaverDao`, `AzurePatriarchHeritageJian`, and `RadiantImmortalSovereignJian`.


  ## Active Milestone: Phase 7 — Combat Mechanics, UI/UX Studio Migration & Audio Polish (Completed)

### Completed in this Session:
- [x] **5-Hit M1 Broadsword Combo & Hitbox Synchronization:** Fixed step-5 finisher desync, added weapon stat scaling, and aim-projected box hitboxes.
- [x] **Attacker Hit Feedback Loop:** Fixed server replication so the attacker immediately receives damage numbers, camera shake, and impact audio (`140462043853173`).
- [x] **Sword Cultivator Block & Perfect Parry Engine (`T` Key):** $180^\circ$ front-guard arc ($80\%$ mitigation), $0.22\text{s}$ Perfect Parry ($100\%$ negation, $0.5\text{s}$ stagger, $+5\%$ Qi, spark VFX, and clash audio `9114223175`).
- [x] **Posture & Guard-Break System:** $100\text{-point}$ Posture pool, $25\text{ pts/s}$ recovery, and $1.2\text{s}$ Guard-Break vulnerability stun ($+25\%$ bonus damage).
- [x] **Unified CC & Anti-Stunlock Hyperarmor State Machine:** Single `CCState` providing $0.6\text{s}$ hard CC-immunity buffer after recovering from any stun.
- [x] **Sector 3 1v1 Sparring Arena Overhaul:** Physical dual-pad standing detection (`DuelPad1` & `DuelPad2`), 3s countdown with auto-cancel, 1,000 HP normalization, non-lethal concession, and live streaming protection (`RequestStreamAroundAsync`).
- [x] **Studio-Bound Spirit Pouch (`InventoryController.luau`):** Direct Studio hierarchy binding, automated 3D sword/herb mesh viewports with live spinning inspection, adaptive 6-to-4 column grid, and UIAssets rarity color coding.
- [x] **3-Tiered Sect Duties (`SectManager.luau` & `SectConfig.luau`):** Easy $\rightarrow$ Medium $\rightarrow$ Hard progression for Herbal Foraging, Alchemy Refinement, and Sparring Discipline with permanent tier-3 lockouts.
- [x] **5-Gate Synchronized Loading Screen (`LoadingScreen.client.luau`):** 5-gate sync engine driving Studio `CustomLoadingScreen` with continuous exploration BGM (`137280276426447`).
- [x] **Audio Suite Integration (`UIAssets.luau`):** Integrated Menu Select SFX (`101735926591481`), Panel Click SFX (`138567614125924`), Sword Equip SFX (`114060318185092`), and Sword Unequip SFX (`97568182472477`).

## Next Immediate Tasks (Next Session):
- [ ] **Flying Sword Flight Mode (御剑飞行):**
  - Implement dedicated `V` key (and mobile flight toggle) sword riding.
  - Horizontal mounting under feet (`HumanoidRootPart.FlightSwordMount`).
  - Full 3D omnidirectional flight physics with camera pitch/yaw steering and dynamic aerodynamic banking.
  - Realm-scaled flight speed ($65 \rightarrow 140+\text{ studs/s}$).
- [ ] **Bottom-Center Vital & Sword Intent Bar Implementation:**
  - Build the redesigned bottom-center HP, Qi, and Sword Intent HUD frame in Studio.
- [ ] **Tier 5–8 Sword Model Asset Integration:**
  - Hook and mount `VioletSoulSovereignJian`, `VoidStarCleaverDao`, `AzurePatriarchHeritageJian`, and `RadiantImmortalSovereignJian`.