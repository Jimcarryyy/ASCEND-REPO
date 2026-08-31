---

### **`.ai/CHANGELOG.md`**

```markdown
# CHANGELOG

## Purpose
This document tracks released and unreleased changes, feature additions, and architectural updates for ASCEND.

## Connectivity
- Use this file to audit historical development and ensure documentation aligns with actual progress.
- Pair it with `.ai/PROJECT_STATUS.md` to confirm which milestones are reflected in the current release state.

---

## [Archived Status Snapshots] — consolidated 2026-08-31
The following are historical `PROJECT_STATUS.md` completion snapshots, preserved here for reference. They were stacked in `PROJECT_STATUS.md` across multiple sessions rather than overwritten. Developer has since confirmed the final "~99%" figure was inaccurate — treat all of these as optimistic self-reports, not verified state.

- **~92%** (undated, Phase 7 in progress, Task 7.1C active) — subsystems through Alchemy/Gathering claimed operational.
- **~95%** (2026-08-16) — added Day/Night Engine, Loading Screen, Locomotion Engine to claimed-operational list.
- **~98%** (V1 Core Systems Complete, undated) — added Sect Economy, Arena claimed 100% operational.
- **~99%** (2026-08-27) — added Combat Overhaul, 3D Inventory, Arena polish; Flying Sword Flight Mode listed as sole remaining task.

## [Unreleased] - 2026-08-10 — Phase 7 World Gathering & Manual Cauldron Alchemy Engine

### Added
- **Task 1: Master Codebase Cleanup & DataStore V2 Reset**:
  - Deleted redundant legacy config files (`InventoryConfig.luau`, `RarityConfig.luau`, `SWORD_MASTERY_SPEC.md`, `ECONOMY_AND_MARKET_SPEC.md`).
  - Bumped DataStore persistence key to `"ASCEND_PlayerData_V2"` in `PlayerDataManager.luau`.
  - Upgraded `UIAssets.luau`, `HUDController.luau`, `InventoryController.luau`, and `AlchemyController.luau` to unified Light-Mode 2D palette with `Enum.Font.FredokaOne` typography.
- **Task 7.1A: World Resource Gathering System**:
  - Created `GatheringConfig.luau`, `GatheringManager.luau`, and `GatheringController.luau`.
  - Implemented support for `workspace.GatheringNodes` folder and `CollectionService` tags (`GatheringNode`).
  - Implemented weighted random herb age rolls (`1-Year`, `10-Year`, `100-Year`, `1,000-Year`) upon harvesting single world models.
  - Integrated audio feedback: plays `SoundService.GatherHerbsSound` on harvest completion.
- **Task 7.1B: Upgraded Manual 3-Slot Spirit Cauldron Alchemy Engine**:
  - Refactored `AlchemyConfig.luau`, `AlchemyManager.luau`, and `AlchemyController.luau` for manual herb selection.
  - Implemented 3 Cauldron Ingredient Slots allowing players to pick herbs from their Spirit Pouch.
  - Implemented dynamic age-based success calculations (higher herb ages boost success rate up to 100% and potency up to 3.0x).
  - Added new craftable buff pills: *Spirit Healing Dan*, *Qi Gathering Dan* (2x Meditation Speed), *Physique Tempering Dan* (+35% Damage), *Gale Wind Dan* (+40% Flight Speed), and *Foundation Gathering Dan*.
- **Zone 2 Map Construction**:
  - Constructed Zone 2 (*Verdant Bamboo & Spirit Herb Valley*) in Studio using a "stylish realism" aesthetic with PBR water, dense bamboo, timber cottage, and circular stone meditation pad.

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
  - Updated `UIAssets.luau`, `HUDController.luau`, `InventoryController.luau`, and `AlchemyController.luau` to the **Traditional Xianxia Palette**.
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


---\n
## [Unreleased] - 2026-08-12 — Expanded Low-Cortisol Alchemy, 2D PNG Assets, 12-Min Day/Night Engine, & Monetized Xianxia HUD

### Added
- **Non-Disappearing World Nodes & On-Screen Item Toasts (Task 7.1A Update)**:
  - Added `KeepModelVisible = true` flag in `GatheringConfig.luau` and `GatheringManager.luau` so environmental water features like `CelestialSpring` remain visible during cooldown.
  - Implemented `HUDController.ShowItemToast` in `HUDController.luau`—a light-mode animated toast banner that glides up on resource collection, displaying the item PNG icon, quantity, name, and rarity color border.
- **Interactive Qi Flame Temperature Minigame & Quality-Metadata Stacking (Task 7.1B Update)**:
  - Created an interactive flame temperature control minigame in `AlchemyController.luau` with needle slider precision locking across Cold, Optimal Qi Flame, and Overheat zones.
  - Implemented Quality-Grade Inventory Metadata (*Standard*, *Refined Medium*, *Century Superior*, *Sovereign Immortal*) in `InventoryManager.luau` and `AlchemyManager.luau`. Stacking checks both `ItemId` and `Quality` so high-grade 1000-Yr pills do not merge with basic pills.
  - Implemented persistent Alchemy Mastery EXP and Leveling (*Apprentice Alchemist* $\rightarrow$ *Pill Emperor*) in `PlayerDataManager.luau` under DataStore `ASCEND_PlayerData_V2` + Cauldron UI header EXP progress bar.
- **2D PNG Icon Assets & Dynamic Quality Card Tinting Engine**:
  - Registered 12 custom transparent 2D PNG asset IDs in `UIAssets.luau` and `ItemConfig.luau` (`FlameIcon`, `GaleWindLotus`, `GaleWindDan`, `QiGatheringDan`, `PhysiqueTemperingDan`, `DemonBeastCore`, `CelestialDew`, `FoundationGatheringDan`, `SpiritAsh`, `DragonBloodVine`, `SpiritGrass`, `SpiritHealingDan`).
  - Cards in Spirit Pouch (`InventoryController.luau`), Cauldron UI (`AlchemyController.luau`), and Hotbar/Toasts (`HUDController.luau`) adapt background colors and borders dynamically according to item rarity and quality grade.
- **Standard Roblox 12-Minute Day/Night Lighting Engine**:
  - Created `EnvironmentTimeManager.luau` running a server-authoritative 12-minute day/night cycle ($1\text{ in-game hour} = 30\text{ real-world seconds}$).
  - Dynamically interpolates `Atmosphere.Density`, `Atmosphere.Color`, and ambient lighting over static skybox textures (`rbxassetid://6444884337`), preserving high soft night ambients for low-poly model readability.
- **Custom Xianxia HUD Template & Monetized HUD Skin Engine**:
  - Integrated custom HUD template `rbxassetid://107254331482831` (`VitalHUDFrame`) featuring a 3D avatar headshot portrait, diamond level badge (`100`), display name, green HP fill, and azure QI fill.
  - Enforced $800\text{ Max Qi}$ backend sync in `CultivationManager.luau` and `HUDController.luau`.
  - Configured typography: `FredokaOne` (`UI_FONT`) for main titles/display names and `LuckiestGuy` (`UI_FONT_2`) for HP/QI bar labels and numbers with 14px/18px inner padding and centered vertical text alignment.
  - Implemented `HUDSkinConfig.luau` and `HUDController.ApplySkin()`, allowing players to equip custom HUD skins (*DefaultBronze*, *SakuraImmortal*, *AzureDragon*) with auto-aligning slot offset mappings.
  - Connected `ActionSkillBar` slots (`Slot_E`, `Slot_F`, `Slot_M1`, `Slot_Q`, `Slot_R`, `Slot_Shift`) to background `rbxassetid://97080305696865`, keybind badges, and dynamic skill cooldown swipe overlays with countdown timers (`HUDController.TriggerSkillCooldown`).
- **Azure Cloud Realm Jade & Cloud 2D Panel Design Identity**:
  - Approved flat 2D AI panel concept featuring pale jade celadon fills (`#E2F1ED`), azure cloud watermarks (`#38BDF8`), gold/jade cloud scroll borders, and an extended top-right circular close button plaque slot.

  ## [Phase 7 — Cultivation Overhaul, Custom Loading Screen & Environment Polish] — 2026-08-16

### Added
- **10 Major Realm Progression (90 Orders):** Expanded cultivation framework from 5 realms to 10 Major Realms with 9 Orders each ($1,000 \rightarrow 150\text{M}$ V1 Cap).
- **3-Tier Dantian Qi Architecture:** Implemented `CurrentQi` (combat resource), `CultivatedQi` (recoverable capacity limit), and `MaxQiGoal` (internal breakthrough goal).
- **Safe-Zone Qi Multiplier Nodes:** `workspace.QiNodes` detection giving $2.5\times - 5.0\times$ Dantian capacity expansion boost during meditation.
- **CultivatedQi DataStore V2 Persistence:** Updated `PlayerDataManager.luau` to save and restore exact `CultivatedQi` progress across rejoins, server shutdowns, and respawns.
- **Encouraging Breakthrough Guidance Toast:** Triggered when attempting breakthrough before meeting the requirement (`CultivatedQi < MaxQiGoal`), displaying *"Keep cultivating! Your Qi isn't ready for breakthrough yet."* in light-mode Xianxia UI style.
- **Custom Xianxia Loading Screen (`LoadingScreen.client.luau`):** Created in `ReplicatedFirst` with `RemoveDefaultLoadingScreen()`, fullscreen artwork (`BACKGROUND_IMAGE_ID`), dynamic `ContentProvider` asset scanning, server profile sync check (95%), and optional `"SKIP [SPACE / CLICK]"` button.
- **R6 Locomotion Engine (`Animate.client.luau`):** Custom R6 movement script in `StarterCharacterScripts` handling Idle, Walk V1, Run V1 (Shift), Jump, Fall (>0.35s height filter), Land, Climb, and Swim.
- **Velocity-Synced Movement Audio:** Integrated custom looped Walk sound (`4416041299`), Run sound (`79250663775359`), Jump sound, and Land sound from `SoundService["Movement sounds"].Main.Character` with speed-matching and default footstep muting.
- **Tree & Bamboo Collision Cleaner (`TreeCollisionManager.luau`):** Server module disabling canopy/foliage collision while keeping trunks and bamboo stalks physically collidable.
- **Organic Gusting Wind Controller (`WindEnvironmentController.luau`):** Single-loop client controller using spatial distance culling (<160 studs) and `math.noise` phase offsets for realistic plant-specific wind sways.
- **Polished 12-Min Day/Night Lighting (`EnvironmentTimeManager.luau`):** 4 cohesive Xianxia lighting phases (Morning, Noon, Sunset, Night) with moonlit foliage visibility.
- **Unit Number Formatting (`FormatNumber`):** Universal helper formatting numbers into short units (`1.0k`, `84.0k`, `1.50M`, `2.50B`).

### Changed
- **Pure Sword Paradigm R6 Dual Compatibility:** Updated `WeaponManager.luau` to dynamically detect `Right Arm` (R6) or `RightHand` (R15) with `Massless = true` and `CanCollide = false` safeguards.
- **Grounded Meditation Sitting:** Converted meditation pose to natural ground level (`groundY + 1.6` studs) with aura highlight VFX, removing floating levitation and heartbeat bobbing.
- **Dynamic Skill Qi Costs:** Converted skill Qi costs from static numbers to percentage of `CultivatedQi` (Shift = 3%, F = 8%, E = 12%, Q = 15%, R = 30%).
- **Percentage-Normalized Combat Damage:** Skill damage now scales with Realm/Order Power Multipliers ($1.0\times \rightarrow 100,000\times$).
- **Camera Max Zoom Distance:** Hard-capped camera zoom to **30 studs** in `ClientMain.client.luau` to prevent open-world vision exploits.
- **3D Overhead Badges (`OverheadUIController.luau`):** Cleaned overhead display down to 2 dynamic lines (Line 1: Realm Name & Rank, Line 2: Alchemy Rank) rendered in `LuckiestGuy` font with thick black text stroke.
- **Main HUD Qi Display (`HUDController.luau`):** Simplified Qi bar text to strictly display `CurrentQi / CultivatedQi` (e.g. `43.3k / 75.0k`), removing all `[Goal: ...]` wording.

### Fixed
- Fixed 1-second meditation animation looping bug by using non-looped track pausing and `ContentProvider:PreloadAsync()` pre-warming.
- Fixed sticky camera bug when exiting meditation by correcting `CameraType` restoration checks in `AnimationController.luau`.
- Fixed console error spam from empty `RunAnimationId = "rbxassetid://"` in `AnimationConfig.luau`.
- Fixed circular require lock between `CombatStateManager.luau` and `CultivationManager.luau` by using runtime dynamic require.
- Fixed instant full Qi refill on meditation by removing forced `CurrentQi = MaxQi` assignment in `CultivationManager.luau`.
- Fixed `ShowItemToast` crash on line 430 by adding `tostring(qualityText)` serialization before `string.gsub()`.
- Fixed local function scope crash in `HUDController.luau` by calling `HookExplorerHUD()` directly.
- Fixed level diamond snapping to 1 on resource harvesting by requiring explicit `payload.Tier ~= nil` checks.
- Fixed 360° idle rotation spin by adding Y-axis rotation lock (`idleLockCFrame`) on `RootPart` in `RenderStepped`.
- Fixed rigid jump spam by adding a 0.3s landing recovery debounce and skipping `Fall` on short jumps.
- Fixed R6 character tripping/flop pose bug by disabling `FallingDown` and `Ragdoll` humanoid states.
- Fixed orphaned `Animator` tracks caused by server `ApplyDescription()` runtime calls.


## [Phase 7 — Fast-Track V1 & Azure Cloud Sect Expansion] - 2026-08-20

### Added
- **Sect Configuration & Economy Engine (`SectConfig.luau` & `MonetizationConfig.luau`):**
  - Defined 6 Disciple Ranks (*Outer -> Inner -> Core -> Direct -> Sect Elder -> Grand Elder*) aligned with `CultivationConfig.RealmTier`.
  - Added daily sect quests (*Herbal Foraging, Alchemy Refinement, Sparring Discipline*) and market catalog pricing for herbs, dans, and beast cores.
  - Added Gamepass definitions (2x Qi Speed, Auto-Meditation, Tribulation Shield, +20 Slots, VIP Elder) and DevProducts (Spirit Stone packs, Instant Qi Dan, Cleansing Water).
- **Server Marketplace & Receipt Engine (`MarketplaceManager.luau`):**
  - Integrated `MarketplaceService.ProcessReceipt` and real-time gamepass perk activation.
- **Sect Duties & Promotion Manager (`SectManager.luau`):**
  - Server validation for quest submission, contribution point tracking, disciple rank promotions, daily stipends, and `workspace.QuestNPCs` ProximityPrompts.
- **Sect Market & Trading Manager (`VendorManager.luau`):**
  - Server-authoritative buying and selling of items using Spirit Stones with `workspace.MarketVendors` ProximityPrompts.
- **R6 Zone Mob Engine (`MobConfig.luau` & `MobAIManager.luau`):**
  - Spawner subsystem in `workspace.MobSpawns`, pathfinding AI, attack/leash state machine, and realm-scaled dynamic rewards.
- **1v1 Sparring Arena Engine (`ArenaManager.luau`):**
  - Same-realm matchmaking queue, non-lethal knockdown resolution in Sector 3, 90s duel countdown, and `workspace.SparringArena` ProximityPrompts.
- **Hybrid Client UI/UX Controllers:**
  - `QuestTrackerController.luau`: Hooked to Studio `StarterGui.QuestTrackerGUI` with 56px legible duty cards and collapse toggle.
  - `SkillBarController.luau`: Hooked to Studio `StarterGui.SkillsGUI` driving real-time dark cooldown masks and countdown timers for M1, Q, E, and F.
  - `MarketController.luau`: Dedicated top-level `ToastGui` (`DisplayOrder = 99`), separated Merchant Market and Quest Elder Pavilion modals.
  - `HUDController.luau`: Hooked to Studio `StarterGui.TopMenuGUI` (`BagMenu`, `MeditateMenu`, `ArenaMenu`, `SettingsMenu`).

### Changed
- **DataStore V2 Persistence (`PlayerDataManager.luau`):** Extended schema to persist `SpiritStones`, `SectRank`, `ContributionPoints`, `OwnedGamepasses`, and `UnlockedSkins`.
- **Inventory Helpers (`InventoryManager.luau`):** Added `HasItem(player, itemId, count)` and `RemoveItem(player, itemId, count)`.
- **Quest Progression Sync:** Hooked `GatheringManager.luau` and `AlchemyManager.luau` to automatically report progress to `SectManager`.
- **UI/UX Design Tokens (`UIAssets.luau`):** Unified entire game palette to **Dark Obsidian (`#111827`) + Antique Bronze-Gold (`#8B6B32` / `#C49A4A`) + Cultivation Jade (`#10B981`) + Azure Spirit Blue (`#3B82F6`)**.
- **Input Gating (`InputController.luau`):** Prevented accidental M1 sword swings when clicking UI elements.
- **Locomotion Cleanliness (`Animate.client.luau`):** Silenced console print spam.

## [2026-08-22] - Pure Sword Combat, Dynamic Sheath, Locomotion Hardening & Qi Dash

### Added
- **5-Hit M1 Broadsword Combo:** Added 5-stage animation string with authentic heavy broadsword weight (`Speed = 0.75x–0.85x`, `FadeTime = 0.08s`):
  - Hit 1: `rbxassetid://129254042886405` (`0.44s`)
  - Hit 2: `rbxassetid://78342794513338` (`0.40s`)
  - Hit 3: `rbxassetid://133701354257850` (`0.44s`)
  - Hit 4: `rbxassetid://140582503077234` (`0.46s`)
  - Hit 5: `rbxassetid://111677132360566` (`0.54s` Heavy Finisher)
- **2-Stage Repeatable Qi Dash (`LeftShift`):** Looping flash-step dash (`Dash 1: rbxassetid://118004062849712` -> `Dash 2: rbxassetid://87494050060721`), 3.0s cooldown, ~18-stud burst distance, and smooth 0.08s deceleration decay.
- **Dedicated Audio & Trails:**
  - Authentic Sword Slash SFX: `rbxassetid://79218449800283`.
  - Qi Dash SFX: `rbxassetid://93272068959626`.
  - Custom HEX color gradient sword trails activated strictly during attack windows.
- **Dynamic Dual-Attachment Sheath System (`WeaponManager.luau`):**
  - In-Hand Combat: `Right Arm.RightGripAttachment` ── `SwordAttachment`.
  - Diagonal Back Sheath: `Torso.BackSwordMount` ── `BackSwordAttachment` (`-45°` / `135°` tilt).
  - Dedicated `R` key draw/sheath toggle.
- **Focus Target Mode (`FocusTargetController.luau`):** Center-screen Azure Qi reticle with upper-body aim lock (`LeftControl` / `MMB`).
- **Standardized V1 Keybind Map:** Double-Tap `W` (Sprint), `M1` (Combo), `Q/E/F` (Skills), `LeftShift` (Dash), `C` (Cultivate), `R` (Sheath), `B` (Breakthrough), `Tab/I` (Inventory), `P` (Arena).

### Changed
- **Dynamic Arena Speed Scaling:** Inside Sector 3 Sparring Arena (`Walk: 16 | Sprint: 28`) vs Outside Arena (`Walk: 18 | Sprint: 52`).
- **Combat Footwork Commitment:** Movement speed dampens to `WalkSpeed = 8` during M1 swings to eliminate floating/sliding and guarantee fair Arena hitbox connectivity.
- **M1 Server Cooldown:** Tuned to `0.28s` in `CombatStateManager.luau` to allow consecutive combo clicks without server dropping.
- **Inventory Keybind:** Replaced legacy `K` with `Tab` / `I` and exposed `InventoryController.Toggle()`.

### Fixed
- **Idle 360° Rotation Drift:** Implemented Idle Yaw Pinning in `Animate.client.luau`, locking character facing angle upon stopping.
- **Rough Terrain / Bumping Physics Glitch:** Permanently disabled `FallingDown`, `Ragdoll`, `PlatformStanding`, and `GettingUp` states.
- **Meditation Animation Blending / Bouncing:** Explicitly stopped all active locomotion tracks on meditation start.
- **Meditation Sheath Bug:** Blocked `R` key draw during meditation and forced sword to remain on the back.
- **UI Interaction Conflicts:** Blocked mouse attacks and Spacebar jumps when clicking or interacting with game menus.
- **Zero-Distance Dash Bug:** Corrected `LinearVelocity.ForceLimitMode` to `Enum.ForceLimitMode.PerAxis` with Y-force clamped to 0.


## [Phase 7 — Combat Overhaul, 3D Inventory Viewports & 1v1 Arena Polish] - 2026-08-27

### Added
- **Unified Server Combat & CC State Machine (`CombatStateManager.luau`):** Single authoritative state machine managing Action States, CC States, Posture, Guard-Break, and a $0.6\text{s}$ hard CC-immunity hyperarmor buffer.
- **Sword Cultivator Block & Perfect Parry (`T` Key):** $180^\circ$ front-guard arc mitigating $80\%$ damage, and a $0.22\text{s}$ Perfect Parry deflection window ($100\%$ damage negation, $0.5\text{s}$ attacker stagger, $+5\%$ Qi restore, spark VFX, and metal clash audio `9114223175`).
- **Posture & Guard-Break System:** $100\text{-point}$ Posture pool with drain per blocked strike, $25\text{ pts/s}$ out-of-block regen, and a $1.2\text{s}$ Guard-Break vulnerability stun ($+25\%$ bonus damage).
- **Physical Dual-Pad Sparring Matchmaking (`ArenaManager.luau`):** Standby detection on `DuelPad1` and `DuelPad2`, 3-second countdown with auto-cancellation, 1,000 HP stat normalization, non-lethal defeat resolution, and live streaming protection (`RequestStreamAroundAsync`).
- **Studio-Bound Spirit Pouch (`InventoryController.luau`):** Replaced hardcoded UI with direct Studio hierarchy bindings, 3D sword/herb viewport previews with real-time spinning inspection, and adaptive 6-to-4 column grid sizing.
- **3-Tiered Sect Quests (`SectConfig.luau` & `SectManager.luau`):** 3 difficulty tiers (Easy $\rightarrow$ Medium $\rightarrow$ Hard) with server validation and permanent tier-3 lockouts.
- **5-Gate Synchronized Loading Screen (`LoadingScreen.client.luau`):** Fullscreen Studio-bound loading screen with 3D model preloading, character weapon mounting confirmation, and continuous looping BGM (`137280276426447`).
- **Complete Audio Suite Integration (`UIAssets.luau`):** Registered Menu Select SFX (`101735926591481`), Panel Click SFX (`138567614125924`), Sword Equip SFX (`114060318185092`), Sword Unequip SFX (`97568182472477`), and Exploration BGM (`137280276426447`).

### Changed
- **Keybind Schema Update:** Rebound Block/Parry to **`T`**, restored **`F`** as Falling Sky Slam, bound Sprint Toggle to **`CTRL`**, and rebound Focus Target to **`MouseButton3` / `Z`**.
- **Combat Footwork Gate:** Movement dampens to `WalkSpeed = 8` during M1 swings with `IsAttacking` locking, preventing mobile auto-sprint overrides while attacking.
- **Asynchronous Client Boot (`ClientMain.client.luau`):** Concurrently boots all client controllers in isolated `task.spawn()` threads, eliminating sequential 10-second boot freezes.