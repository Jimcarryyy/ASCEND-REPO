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


# CHANGELOG — ASCEND

## [Phase 8 — Studio GUI Overhaul, Looping Sword Intent & Asset Polish] - 2026-09-02

### Added
- **Studio-Authoritative GUI Integration:**
  - Migrated `SkillBarController.luau`, `HUDController.luau`, `QuestTrackerController.luau`, and `CultivationController.luau` to bind directly to Studio `StarterGui` instances.
  - Linked `SkillsGUI` (Desktop), `LowViewPortSkillsGUI` (Mobile vitals), `CurrencyGUI`, `BottomMenuGui`, `SectMissionGui`, and `GlobalToastNotifGui`.
- **Looping Sword Intent Combat Engine:**
  - Integrated $+25\%$ Intent accumulation per landed M1 strike in `HitboxManager.luau` and `SkillBarController.luau`.
  - Added $1.75\times$ Empowered Strike consumption at $100\%$ Intent with instant $0\%$ loop reset.
  - Added continuous $8\%/\text{s}$ decay after $2.5\text{s}$ of hit inactivity.
  - Added floating combat combo badges (`INTENT +25% [COMBO x1]`, `INTENT 100% - FULL CHARGE!`, `SWORD INTENT UNLEASHED (1.75X)`).
- **Mobile Touch Combat Cluster:**
  - Designed an ergonomic 2×3 touch grid (`M1`, `R`, `V`, `B`, `C`) around the native Roblox Jump button using Roblox's translucent gray circle aesthetic.
  - Left native Roblox mobile jump button in `TouchGui` active and untouched.
- **2D High-Resolution Weapon Asset Registry (`UIAssets.luau`):**
  - Registered 8 live asset IDs for sword tiers: Mortal Iron (`109157084266033`), Azure Cloud (`115690610892281`), Flowing Qi (`85610178645930`), Verdant Jade (`114181885052834`), Violet Soul (`102454036931672`), Void Star (`73201319689599`), Azure Patriarch (`129279811461089`), and Radiant Immortal (`131309720641215`).
  - Replaced 3D ViewportFrames in `InventoryController.luau` and `MarketController.luau` with 2D icon showcases.
- **Dynamic Sect Market Weapon Catalog (`MarketController.luau`):**
  - Auto-populates all swords from `ItemConfig` into the `SWORDS` and `ALL` tabs.
  - Corrected Contribution Points header display from rounded `2.0K CP` to exact `1,970 CP`.
- **Generation-ID Anti-Spam Toast Engine (`HUDController.luau`):**
  - Implemented token-validated toast transitions preventing rapid consecutive harvests from hiding notifications prematurely.

### Changed
- **Overhead UI Overhaul (`OverheadUIController.luau`):**
  - Replaced font with `Enum.Font.FredokaOne`.
  - Applied 3-stop $90^\circ$ vertical green gradient (`#4ADE80` $\rightarrow$ `#22C55E` $\rightarrow$ `#15803D`) with a 2px solid white `UIStroke` and `UICorner` of 30.
  - Removed overhead Qi bar to reduce screen clutter.
- **3D Qi Node Billboards (`CultivationController.luau`):**
  - Styled floating node billboards with `Enum.Font.Bangers` and 2px black `UIStroke`.
  - Fixed client zone banner calculation to display true node rates (e.g. `5.0X SPEED`) without artificial doubling.
- **Keybind Consolidation (`InputController.luau`):**
  - Removed `M` keybind; assigned `C` as the exclusive cultivation key.
  - Added desktop toast feedback for `B` (Breakthrough) and `C` (Meditation).

### Fixed
- Fixed `AlchemyController.luau` line 132 nil callback by exporting `HUDController.ShowItemToast`.
- Fixed `AlchemyController.luau` line 716 `UIGridLayout.CellPadding` type error (`UDim2` expected, got `UDim`).
- Fixed trailing backslash syntax error in `InventoryController.luau` line 430.
- Fixed non-existent `NotifyClient` remote timeout in `RemoteEvents.luau`.


# CHANGELOG — ASCEND

## Purpose
This document records historical feature additions, engine enhancements, balance passes, and architectural updates across all development milestones.

---

## [Phase 8.2 — Lower Layer Debug Pass, Typography Standard & Desktop HUD Rebuild] — September 2026

### Added
- **Typography Standard Enforcement (ADR-042):**
  - Standardized all titles, headers, station signs, and NPC names to **`Enum.Font.Bangers`** with a solid black `UIStroke` outline (`Thickness = 1.5 - 2.0`).
  - Standardized all body copy, descriptions, lore text, and dialogue to **`Enum.Font.Fundamento`**.
- **DisplayOrder Layering Architecture (ADR-043):**
  - Assigned strict `DisplayOrder` layers to all 10 ScreenGuis in `StarterGui` (HUD = 1, Facilities = 10, Toasts = 20, Loading = 100), permanently eliminating modal overlap.
- **Three-Tier Elevation Sect World Architecture (ADR-044):**
  - Structured the Jade Pure Sect hub across 3 distinct elevation tiers (Lower Services & Training, Middle Dao Sanctuary & Sword Altar, Upper Sovereign Palace Hall with black roof tiles).
  - Placed the Top 7 Pillars of the Sect (elite lore masters) on Tier 3.
- **Studio-Authoritative UI Mandate (ADR-041):**
  - Permanently prohibited runtime `Instance.new` UI generation inside Lua controllers. All UI elements must exist natively in `StarterGui`.

### Fixed & Debugged (Messages 175–179)
- **Tea House Crash Fix (`TeaHouseManager.luau:88`):** Fixed `invalid argument #1 to 'min' (number expected, got nil)` by validating numeric health parameters before clamp/min operations.
- **Blacksmith Initialization & Prompt Fix (`BlacksmithManager.luau:14, 63`):** Resolved `attempt to call a nil value` and `attempt to index nil with 'WaitForChild'` by properly decoupling character load dependencies and connecting the ProximityPrompt directly to `Sect_NPC_MadameTie` and `Master Blacksmith Anvil`.
- **Sect Starter Guide Prompt Collision Fix (`StarterGuideController.luau`):** Resolved bug where interacting with Elder Qing inadvertently triggered `SectPavilionGui`. Bound ProximityPrompt strictly to `StarterGui.StarterGuideGui`.
- **Sparring Guidance DPS Reset Loop Fix (`SparringGuidanceController.luau`):** Resolved client spam loop during dummy DPS reset routines and bound UI buttons cleanly to Instructor Wu.
- **Alchemy Cauldron Interface Migration:** Migrated hardcoded Lua UI in `AlchemyController.luau` to native Studio ScreenGui (`StarterGui.AlchemyCauldronGui`).
- **Character Locomotion Stair Tripping Fix:** Corrected wedge collisions and step height sizing on the Grand Staircase and Sword Altar foundation to prevent R6 characters from flipping or getting stuck while running.

---

## [Phase 8.1 — Lower Layer Sect Facilities & Interactive NPC Ecosystem] — September 2026

### Added
- **Blacksmithing Refinement & Sharpening Station (`BlacksmithManager.luau` & `BlacksmithController.luau`):**
  - Server-authoritative weapon refinement up to `+10` (+5% base ATK per level; up to +50% ATK).
  - Dynamic success scaling (`max(0.35, 0.95 - Refine * 0.08)`) with Spirit Stone and `MountainIronIngot` costs.
  - Blade sharpening: 100 Spirit Stones for +10% Critical Strike Chance for 15 minutes.
- **Spirit Tea Pavilion Subsystem (`TeaHouseManager.luau` & `TeaHouseController.luau`):**
  - 3 craftable spirit brews with instant recovery and 10–15 minute timed attribute buffs (*Jade Dew*, *Crimson Ginseng*, *Dragon Well*).
- **Training Grounds & Sparring Trials (`SparringGuidanceController.luau` & `ImmortalDummyHandler.server.luau`):**
  - 3 Ironwood Dummies in `Workspace.Functional_Stations.Sect_TrainingGround` featuring 10,000,000 HP, instant auto-regen, rolling 5s DPS tracking, and floating overhead numbers.
- **Interactive Sect Starter Guide (`StarterGuideController.luau`):**
  - 4-tab interactive guide bound to `Sect_NPC_ElderQing` (Controls, Cultivation, Sword Intent, Sect Duties).
- **Central Network Remote Expansion (`RemoteEvents.luau`):**
  - Registered `BlacksmithAction` and `TeaHouseAction`, expanding the network pool to 22 remotes.
- **Controller Reorganization:**
  - Consolidated `OverheadUIController.luau` into `src/StarterPlayer/StarterPlayerScripts/Controllers/`.

---

## [Phase 8.0 — Studio GUI Overhaul, Looping Sword Intent & Asset Polish] — 2026-09-02

### Added
- **Studio-Authoritative GUI Integration:** Bound client controllers to Studio `StarterGui` instances.
- **Looping Sword Intent Combat Engine:** Added dynamic Sword Intent gauge (+25%/hit, 1.75× empowered strike at 100%, 8%/s decay after 2.5s inactivity).
- **Mobile Touch Combat Cluster:** Ergonomic 2×3 touch layout (`M1`, `R`, `V`, `B`, `C`) around native Jump button.
- **2D Weapon Asset Showcase:** Integrated 8 live high-res sword icons (`UIAssets.luau`) and replaced 3D viewports with 2D cards.
- **Keybind Consolidation:** Standardized `C` as exclusive meditation key; removed redundant `M` keybind.

---

## [Phase 7.3 — Combat Overhaul, 3D Inventory Viewports & 1v1 Arena Polish] — 2026-08-27

### Added
- **Server Combat & CC State Machine (`CombatStateManager.luau`):** Managing `ActionState`, `CCState`, Posture, Guard-Break, and a 0.6s hyperarmor buffer.
- **Block & Perfect Parry (`T` Key):** 180° frontal guard arc (80% mitigation); 0.22s Perfect Parry window (100% negation, 0.5s stagger, +5% Qi).
- **Physical Dual-Pad Matchmaking (`ArenaManager.luau`):** Standby detection on `DuelPad1` and `DuelPad2`, 3-second countdown, 1,000 HP normalization, non-lethal defeat resolution.
- **Concurrent Client Boot (`ClientMain.client.luau`):** Concurrently boots all controllers via `task.spawn()`.

## [Phase 8.3 — Jade Pure Sect Architecture, 19-NPC Roster & Master HUD Integration] — September 2026

### Added
- **Complete 16-Station Functional Suite (`Workspace.Functional_Stations`):**
  - Rebuilt all interactive world assets: `Murim_SpawnDais`, `Sect_TrainingGround`, `Sect_AlchemyStation` (with 3D `EightTrigramsCauldron`), `Sect_Mission_And_Leaderboard`, `Sect_GuardHouse_VerificationPoint`, `Sect_Blacksmith_Forge`, `Sect_TeaHouse_Pavilion`, `Sect_SwordAltar_Complete`, `Sect_Duelist_Pavilion`, `Sect_Solitary_SwordArena`, `Sect_Treasury_Shopfront`, `Sect_BankVault_Stash`, `Sect_Wilderness_PortalGate`, `Sect_Patriarch_ThroneDais`, `Sect_Council_DiscussionPavilion`, and `Sect_Ancestor_SeclusionDais`.
- **Complete 19-Character Sect NPC Suite (`Workspace.NPCs`):**
  - **Tier 1 (Lower):** Guard, Guide Elder Qing, Master Shen (Alchemy), Deacon Zhao (Missions), Merchant Qian (Trader), Instructor Wu (Sparring), Outer Disciple, Madame Tie (Blacksmith), Xiao Ling (Tea Hostess), Disciple Shi (Sweeper).
  - **Tier 2 (Middle):** Grand Sword Elder Liang, Steward Jin (Treasury), Vault Keeper Lu (Bank), Daoist Feng (Portal Gatekeeper), Inner Disciple, Senior Sister Xue (Sword Prodigy), Disciple Wei (Formations), Disciple Lin (Formations).
  - **Tier 3 (Upper):** Patriarch Han (Sect Master), Elder Tie (Discipline/War), Ancestor Han's Avatar (1,000-Yr Seclusion), Core Disciple, Elder Mu (Medicine), Elder Ba (Formations), Elder Ling (Scriptures), Elite Sky-Sword Guard (Male), Elite Sky-Sword Guard (Female), Palace Maid Attendant.
- **The 7 Sword Pillars of the Jade Pure Sect:**
  - Ye Chen (Azure Dragon), Hong Lian (Crimson Flame), Leng Wushuang (Frost Lotus), Lei Zhen (Thunder Crag), Gu You (Cosmic Void), Feng Qing'er (Celestial Wind), and Mo Chen (Shadow Asura).
- **MasterHUDGui Live Integration:**
  - Connected `SkillBarController.luau`, `HUDController.luau`, `QuestTrackerController.luau`, and `CultivationController.luau` directly to `StarterGui.MasterHUDGui`.
- **12 Pre-Built Modal GUIs in `StarterGui`:**
  - `BlacksmithGui`, `TeaHouseGui`, `StarterGuideGui`, `SparringGuidanceGui`, `AlchemyGui`, `SwordAltarGachaGui`, `ContributionShopGui`, `BankVaultGui`, `WildernessPortalGui`, `PatriarchAudienceGui`, `CouncilElderDiscussionGui`, `AncestorSeclusionGui`, `DisciplineHallGui`, `BossHealthHUD`, `GatheringHUD`, `DeathReincarnationGui`, `HeavenlyTreasuryGui`, `SettingsGui`.

### Changed
- **Sect Identity & Palette Lock:** Standardized on the **Cobblestone (`#9B968C`) + Dark Slate (`#282D37`) + Antique Brass (`#C3A55F`)** suite with black ceramic pagoda roof tiles.
- **Typography Standard:** Enforced `Bangers` with black `UIStroke` for headers, titles, and buttons; `Fondamento` for lore, descriptions, and stats.
- **DisplayOrder Hierarchy:** Set `MasterHUDGui = 10`, all Facility Modals = `50`, and `DeathReincarnationGui = 60`.

### Fixed
- **Stair Tripping Bug:** Implemented $1.0\text{-stud}$ step increments ($28\text{ steps}$ over $28\text{ studs}$) on the Grand Staircase and Sword Altar Foundation, allowing R6 characters to sprint without tripping.
- **Floor Sinking & Z-Fighting Bug:** Replaced large flat cylinder floor colliders with solid flat blocks, eliminating texture flickering and character floor dipping.
- **Madame Tie & Anvil Prompt Fix:** Added recursive ancestor detection in `BlacksmithManager.luau` and `BlacksmithController.luau`.
- **Elder Qing Prompt Collision Fix:** Removed `"seek guidance"` from `SectManager.luau` so Elder Qing exclusively opens `StarterGuideGui`.
- **TopBar Overlap:** Shifted `TopLeftDutyTracker` down by $+56\text{px}$ to clear Roblox CoreGui buttons.

## [Phase 8.4 — Flying Sword Flight Mode, High-Impact Locomotion & 9-Slice UI Overhaul] — September 2026

### Added
- **Server-Authoritative Flying Sword Flight Mode (`WeaponManager.luau` & `InputController.luau`):**
  - Bound flight toggle to the **`V`** key (and `V_SKILL` on desktop/mobile HUDs).
  - Mounted dedicated `ReplicatedStorage.FlyingSword` horizontally under the character's feet using pre-defined `FeetAttachment` and `LeftFootAttachment` via synchronized `RigidConstraint` (physics weld) and `AnimationConstraint`.
  - Registered R6 Daoist sword-surfing animation (`rbxassetid://81098622855235`) in `AnimationConfig.Movement.Flight`, playing at `Enum.AnimationPriority.Action4`.
  - Implemented 3D omnidirectional flight physics with locked directional steering:
    - Set `Humanoid.AutoRotate = false` and added high-torque `AlignOrientation` (`MaxTorque = 10,000,000`, `Responsiveness = 35`) with `FLIGHT_YAW_OFFSET = 90`, locking the sword tip and character forward with the camera view and eliminating 360° spinning and collision tumbling.
    - Added downward raycast **Ground Clearance Cushion** (`MIN_HOVER_ALTITUDE = 6.5 studs`), automatically pushing the sword ~3.5 studs above grass, rocks, and terrain so it never drags or clips.
    - Added forward **Proximity Obstacle Cushion** (`MIN_OBSTACLE_BUFFER = 8.5 studs`), eliminating inward velocity on solid models/cliffs and allowing smooth sliding along walls with zero snagging.
    - Flight vertical controls: `Spacebar` to ascend (+42 studs/s), `LeftControl` / `C` to descend (-42 studs/s), and camera pitch steering.
    - Natural slow idle descent: drifts downward gently at -2.5 studs/s when hands are off the controls until cushioned above the ground.
    - Increased flight velocity to **75 studs/s**.
  - Generated complete **Celestial Thunder Sword Flight VFX Suite**:
    - `FlightRibbon` 4-stop azure-to-indigo trail (`#E0F2FE` -> `#38BDF8` -> `#2563EB` -> `#1E1B4B`).
    - `BladeEdgeAura` particle mist wafting along the blade edges.
    - `CoreThunderSparks` & `SwordCoreLight` (12-stud range, 1.4 brightness) around the crossguard cyan gem.
    - `TipSlipstream` air-condensation streaks cutting through clouds at the blade tip.

- **High-Impact Locomotion & Lightning Flash-Step Dash (`AnimationController.luau` & `InputController.luau`):**
  - Boosted sprint speed from 35 studs/s to **44 studs/s** (Open World) and **34 studs/s** (Arena).
  - Added step-synced harmonic running head-bobbing (vertical footfall compression $\pm 0.08$ studs, lateral weight sway $\pm 0.05$ studs, and roll tilt $\pm 0.75^\circ$).
  - Added dynamic speed-tunnel FOV smoothly expanding from $70^\circ \rightarrow 76^\circ$ while sprinting.
  - Overhauled **Lightning Qi Dash (`LeftShift`)**:
    - Explosive instantaneous impulse: **150 studs/s** burst over 0.16s covering $\approx 20\text{ studs}$.
    - Fixed running-dash tripping/flipping bug by adding **$+1.2\text{ stud}$ elevation lift**, setting temporary `Freefall` state, and locking upright posture with an `AlignOrientation` (`MaxTorque = 10,000,000`).
    - Added camera speed-warp FOV punch ($70^\circ \rightarrow 79^\circ \rightarrow 70^\circ$) + high-frequency micro-trauma camera shake.
    - Spawns two fading Celestial Cyan Neon ghost afterimages (`#38BDF8`) at $t = 0\text{s}$ and $t = 0.06\text{s}$.

- **Floating Daoist Meditation Elevation (`CultivationManager.luau` & `AnimationController.luau`):**
  - Fixed buried-in-ground meditation bug by lifting `HumanoidRootPart` to `groundY + 4.8` studs upon pressing **`C`** (hovering ~2.8 studs above the floor in lotus posture) and removing `humanoid.Sit = true`.
  - Added downward raycast on exit to land flush at `groundY + 3.0` studs on any slope, stair, or terrain.
  - Pre-warmed `MEDITATION_ANIM_ID` via `ContentProvider:PreloadAsync` and pre-loaded `meditationTrack` on character spawn, eliminating the first-press standing-freeze bug.

- **Dedicated Character & Weapon Profile (`StarterGui.CharacterStatsGui` & `CharacterStatsController.luau`):**
  - Created 4-tab middle-center modal ($0.5, 0.5$) with `DisplayOrder = 50`:
    - `1. DAO REALM`: Live Disciple name, Sect Rank, Realm, Realm Power Multiplier, Alchemy Rank, and Dantian Qi progress bar.
    - `2. COMBAT STATS`: Live Max HP, Poise (Posture), Ground Speed, Flight Velocity, Sword Intent %, and Critical Chance.
    - `3. SPIRIT WEAPON`: Equipped Blade name, rarity, base ATK damage, swing cadence, Blacksmith Refinement Grade (+Grade = +5%/lvl), and Whetstone Buff countdown timer.
    - `4. 3D AVATAR`: Real-time 3D rotating ViewportFrame of character holding equipped weapon.
  - Sourced with genuine `Fondamento` descriptions and bold `Bangers` badges.
  - Toggled with keybind **`P`**.

- **Mobile Scatter Cluster Full Interactivity (`SkillBarController.luau`):**
  - Wired all 10 mobile buttons in `MasterHUDGui.MobileScatterCluster` (`M1`, `Shift`, `T` hold-to-block, `Q`, `E`, `F`, `R`, `V`, `C`, `B`).
  - Synchronized dual cooldown sweeps across desktop hotbar and mobile touch buttons simultaneously.

- **9-Slice Textured Panel Architecture (`rbxassetid://115367926298823`):**
  - Standardized facility modal main windows to 9-slice `ImageLabel`s with `SliceCenter = Rect.new(146, 120, 878, 120)` and `SliceScale = 1`.
  - Applied to `SectPavilionGui`, `BlacksmithGui`, `TeaHouseGui`, `AlchemyGui`, and `StarterGuideGui`.
  - Styled inner sub-panels to Deep Warm Obsidian (`#0E1016`, 0.20 transparency) with Antique Gold borders (`#B4914B`).
  - Upgraded action buttons (`RefineButton`, `SharpenButton`, `BrewButton`) with high-contrast glowing backgrounds and bold pure white Bangers text.

### Changed
- **Overhead UI Standard (`OverheadUIController.luau`):**
  - Slimmed health bar from $22\text{px}$ pill to $11\text{px}$ sleek rectangle with $1\text{px}$ micro-corners and $1\text{px}$ dark slate border (`#37414E`).
  - Applied 3-stop Celestial Jade green gradient (`#4ADE80` -> `#22C55E` -> `#108043`).
  - Standardized all overhead typography to `Enum.Font.FredokaOne` and centered numeric HP text directly on the bar.
  - Stripped overhead Qi bar to reduce clutter and enforced strict player-only attachment (ignoring all NPCs and dummies).

### Fixed
- **Combat Weapon vs Flying Sword Isolation:**
  - Resolved bug where the Flying Sword spawned in hand on player join in the live published game.
  - Sanitized `PlayerDataManager.luau` to purge any saved `"FlyingSword"` from cloud DataStores, defaulting developer `Han_jueee` to `"VoidStarCleaverDao"`.
  - Sourced combat weapons strictly from `ReplicatedStorage.Weapons`, reserving `ReplicatedStorage.FlyingSword` strictly for the `V` key flight mount.
  - Restored genuine `MortalIronJian` mesh from `ReplicatedStorage["Old swords (IGNORE)"]`.
- **`SkillBarController:227` Subtraction Crash:** Added defensive fallback (`local cd = duration or 1.5`) in `TriggerCooldown`, eliminating nil arithmetic errors when triggering block (`T`).
- **`WeaponManager:245` Arithmetic Crash:** Resolved string-to-number multiplication error by safely resolving realm tier indices through `CultivationConfig.GetRealmIndex`.
- **`CultivationController:142` Syntax Error:** Removed stray backslash that prevented client controller booting.
- **Deacon Zhao Sect Pavilion Prompt:** Resolved hierarchy lookup bug in `SectController.luau` so pressing `E` on Deacon Zhao opens `SectPavilionGui` with 0ms lag.
- **Movement Sound Governor:** Muted phantom footstep audio during flight collisions and mid-air jump spamming.

## [2026-09-11] — Combat Skills Overhaul, Gathering HUD Integration & Mob Spawner Engine

### Added
- **Q Skill (Purple Sword Tempest):** Implemented server-authoritative skill in `FlyingSwordConfig.luau`, `AnimationConfig.luau`, `InputController.luau`, `FlyingSwordServer.luau`, and `CombatVFXController.luau`. Features dual hitbox (point-blank melee slice + 3x traveling sawblade waves @ 70 studs/s, 36-stud reach), 15% Qi cost, camera shake, release SFX (`rbxassetid://109735549169421`), and hit SFX (`rbxassetid://135448977656112`).
- **F Skill (100-Slash Flash Domain):** Implemented Ultimate skill on `F` key replacing Falling Sky Slam. Hold `F` to charge stance (`rbxassetid://84905841522350`, locked pose, 20% Qi cost); release to flash-step ($150\text{ studs/s}$ across $28\text{ studs}$) phasing through enemies while raycast-respecting trees/walls/terrain; midpoint micro-hitstop ($0.05\text{s}$) triggering mid-air slash (`rbxassetid://111677132360566`) and 36-stud purple 100-slash sphere (`UltimateSkill`); dedicated audio (`rbxassetid://18781431019`).
- **Automatic Sprint Resumption:** Cultivator automatically returns to a full $44\text{ studs/s}$ sprint after casting `Q` or `F` if movement was active prior to cast, with less than $0.25\text{s}$ post-skill recovery pause.
- **R6 RogueDisciple Rig:** Fully rigged R6 enemy template in `ReplicatedStorage.MobModels.RogueDisciple` with standard Motor6D joints, 19 native attachments, welded geometric clothing, and equipped `MortalIronJian` via `RightGrip`.
- **GatheringHUD 1-Click Harvesting:** Bound `StarterGui.GatheringHUD` with smooth progress bar fill, custom floating Xianxia billboard prompt, and suppressed default Roblox UI (`HoldDuration = 0`, `Style = Custom`). Attached elemental PointLight glows across all 5 gathering nodes.

### Fixed
- **Anti-Trip Ground Physics:** Permanently disabled `HumanoidStateType.FallingDown` and `Ragdoll` across character lifecycles. Zeroed horizontal velocity on charge and eliminated artificial CFrame ground snaps, completely preventing forward ragdoll tumbles when casting mid-sprint.
- **Obstacle Collision on Dashes:** Fixed bug where phasing through enemies caused characters to phase through trees, rocks, and terrain. Implemented forward obstacle raycast that specifically ignores Humanoids but stops cleanly 2 studs in front of static environment models.
- **ServerMain Initialization:** Resolved missing `MobAIManager.Init()` call in `ServerMain.server.luau` that previously prevented all enemy spawners from running.
- **MobConfig Data Lookup:** Resolved silent spawn failure where `MobConfig[mobId]` returned `nil`. Updated `MobAIManager.luau` to call `MobConfig.GetMob(mobId)` and read real properties (`BaseSpiritStones`, `BaseQiReward`, `DropTable`).
- **Gathering Crashes:** Fixed `GatheringController.luau` line 6 client crash by removing invalid server `State.InventoryManager` require and resolved `RemoteEvents` infinite yield. Fixed `GatheringManager.luau` nil index crash using schema-safe `GetNodeConfig` resolver.
- **Tree Collision & Axis Alignment:** Cleaned foliage collision across tree models (`CanCollide = false`, trunks = `Hull`). Fixed Blender FBX Z-up orientation matrix bug that previously knocked trees 90° flat on their sides.
- **Foliage Wind Shaking:** Renamed internal meshes of gathering herbs from `"Grass"` to `"HerbMesh"` to bypass unwanted `WindEnvironmentController.luau` gust shaking.

## [Phase 8.5 — Combat Engine Hardening, Mob AI Overhaul & Master HUD Rebuild] — September 2026

### Added
- **Dynamic Weapon-Attuned Visual Palette System:**
  - Integrated `WeaponVFXPalette` in `ItemConfig.luau` and `ItemConfig.GetWeaponPalette(weaponId)` mapping all 8 sword tiers to unique primary colors, secondary tones, glow colors, and multi-stop particle gradients (Mortal Steel, Azure Cloud, Flowing Sapphire, Verdant Jade, Violet Soul, Void Star, Divine Cyan, Radiant Gold).
  - Replicated `character:SetAttribute("EquippedWeapon", weaponId)` in `WeaponManager.luau`.
  - Dynamically attuned `Q` sawblade waves, `F` 100-slash sphere, Dash afterimage trail, and `F` Shunpo ghost silhouettes to the equipped sword's palette.
- **R6 1-Handed Sword Cultivator Roster (`MobConfig.luau` & `MobAIManager.luau`):**
  - **`RogueDisciple` (1.0x):** Common swarm cultivator with mortal iron sword.
  - **`BloodShadowAssassin` (0.92x):** High-speed flanker (`WalkSpeed = 22`), straw hat, glowing red eyes.
  - **`CorruptedIronGuard` (1.35x):** Heavy brute tank (`1250 HP`, `WalkSpeed = 12`), iron armor, demon horns.
  - **`FallenInnerProdigy` (1.20x):** Field mini-boss Senior Brother Bai (`3500 HP`, `WalkSpeed = 18`).
  - **`Boss_FallenSwordGenius` (1.28x):** World Boss Mo Chen (`28000 HP`, `WalkSpeed = 20`), Ink-and-Blood robes, single cursed horn, demonic sword intent aura.
  - Generated dedicated color-coded spawner anchors in `Workspace.MobSpawns` with high-contrast `Fondamento` developer billboards.
- **Smart Teammate Flocking & Boids Separation AI:**
  - Mobs targeting the same player calculate angular surround slots around the player instead of running in a single file line.
  - Implemented Boids lateral repulsion force pushing mobs apart if within 5.5 studs of each other, fanning out into open space naturally.
- **Master Xianxia UI Color Specification:**
  - Established canonical design system: Celestial Midnight Navy (`#141F36` / `#1E2D4A` / `#0B111E`), Solar Dao Gold (`#FFFBEB` / `#FDE047` / `#EAB308`), Celestial Spirit Cyan (`#22D3EE` / `#0EA5E9` / `#0369A1`), Twilight Card Slate (`#121B2D` / `#18243C` / `#0E1524`), Cinnabar Crimson (`#FB7185` / `#E11D48` / `#9F1239`).
  - Applied across `MasterHUDGui`, `SectPavilionGui`, `StarterGuideGui`, and `BlacksmithGui`.
- **Universal Selection-Based GUI Inspector:**
  - Created Studio Command Bar inspection tool using `Selection:Get()` to dump hierarchy trees, positions, sizes, fonts, and properties of any selected GUI to the Output window.

### Changed
- **F Ultimate Skill Overhaul (`InputController.luau` & `FlyingSwordServer.luau`):**
  - Purged hold-to-charge mechanic; converted to responsive instant 1-click activation (`TriggerUltimateF`).
  - Implemented client-authoritative dash physics: +2.2 studs elevation lift into `Freefall`, `AlignOrientation` (10M torque), 145 studs/s burst over 0.22s, and smooth decay.
  - Added downward raycast slope-normal validation (`groundHit.Normal.Y > 0.65`) before ground snapping (`groundHit.Position.Y + 3.0`), preventing collision glitches against cliffs and steep rocks.
  - Completely zeroed residual horizontal `AssemblyLinearVelocity` at end of burst.
  - Eliminated server-side `LinearVelocity` and CFrame snaps in `FlyingSwordServer.luau`, permanently resolving rubber-banding.
- **Master HUD Layout Rebuild (`MasterHUDGui`):**
  - **`VitalsContainer`:** Relocated to Bottom-Left (`UDim2.new(0, 32, 1, -32)`). Standardized all 3 bars (HP, QI, INT) to equal 340px width and 14px height. Removed all `UICorner` instances. Split top text into Left title (`HP`, `QI`, `INT`) and Right real values (`2.02M / 2.02M`) in `Bangers` font with black outlines.
  - **`TopRightCurrencyFrame`:** Relocated to Bottom-Left directly above `VitalsContainer` (`UDim2.new(0, 32, 1, -164)`). Formatted as two 165px side-by-side rectangular badges (340px total width). Corrected icon mapping (Blue Gem = Spirit Stones, Gold Crest = CP).
  - **`BottomNavTray`:** Relocated to Top-Right corner (`UDim2.new(1, -28, 0, 28)`). Vertical 4-button stack (`Arena`, `Pouch`, `Guide`, `Mission`) with custom left-aligned icons and vibrant gradients.
- **Overhead UI Overhaul (`OverheadUIController.luau`):**
  - Removed overhead HP bar entirely (HP is tracked on the Bottom-Left HUD).
  - Retained only Cultivation Realm & Order + Sect Rank in `Bangers` font with vertical gradients.
  - Deduplicated order text formatting (`SPIRIT SEVERING - ORDER 2 - ORDER 2` $\rightarrow$ `SPIRIT SEVERING - ORDER 2`).
- **Gathering HUD & ProximityPrompt Overhaul (`GatheringController.luau` & `GatheringManager.luau`):**
  - Resized `HarvestProgressContainer` to compact 210x40 size; displays clean `"HARVESTING..."` label.
  - Applied vibrant Amber-Gold gradient and normal black borders.
  - Added elastic spring pop-in / fade-out animations.
  - Implemented prompt suppression: prompt hides immediately upon pressing E and remains hidden while harvesting or depleted (`Depleted = true` attribute sync).
- **Modal Window Modernization:**
  - Converted `SectPavilionGui.MainFrame`, `StarterGuideGui.GuideWindow`, and `BlacksmithGui.ForgeWindow` from ornate bamboo `ImageLabel`s to clean, sharp rectangular `Frame`s with Celestial Midnight Navy gradients and thin black borders.
  - Isolated button text into inner `TextLabel`s (`TextColor3 = 255, 255, 255` with black `UIStroke`) so button `UIGradient`s do not corrupt text legibility.

### Fixed
- **Mob Death Crash (`MobAIManager.luau:184 & 195`):**
  - Wrapped `SectManager.AddQuestProgress` in safe `pcall`.
  - Eliminated legacy call to non-existent `PlayerDataManager.GetProfile(killer)`. Sourced rewards directly from `PlayerDataManager.AddSpiritStones` and `CultivationManager.AddInternalQi`.
  - Added compatibility alias `MobAIManager.RegisterDamage` matching `HitboxManager.luau:233`.
- **Mob Hit Resolution Crash (`HitboxManager.luau:96`):**
  - Fixed `attempt to index nil with 'Character'` by safely supporting `attackerPlayer: Player?` (nil for mob attackers).
- **Mob Sliding Feet Bug (`MobAIManager.luau`):**
  - Replaced `Humanoid.MoveDirection` check (which is always 0 on server NPCs) with `AssemblyLinearVelocity` horizontal speed detection. Mobs now play martial walk during Patrol and sprint run during Chase.
- **Missing Mob Hit Feedback:**
  - Routed mob attacks through `HitboxManager.ApplyCombatResolution`, enabling player block mitigation (80%), perfect parries, posture breaks, and physical knockback.
  - Added procedural fallback in `CombatVFXController.SpawnSlashHitVFX` so slashmarks always render. Added camera shake (`0.85`), FOV kick, blade impact audio, and screen hit-flash.
- **Infinite 0 HP Respawn Bug (`SkillBarController.luau` & `CultivationManager.luau`):**
  - Fixed zombie closure leak in `SkillBarController.luau`: Implemented `characterConnections` garbage collector to disconnect all previous listeners on death.
  - Enforced `MasterHUDGui.ResetOnSpawn = false` to prevent GUI destruction on respawn.
  - Removed `task.wait(0.2)` delay on `CharacterAdded` in `CultivationManager.luau`: Synchronously applies full realm MaxHealth and replenishes Qi to 100% on spawn.
- **Arena Reset Bug (`ArenaManager.luau:220`):**
  - Replaced hardcoded `hum.MaxHealth = 100` with `CultivationManager.ApplyRealmStats(p)`.
- **Arena Modal Client Crash (`ArenaController.luau:136`):**
  - Added nil guard to `arenaGui.Enabled = true`. Emits guidance toast and teleports to lobby if GUI is absent.
- **Q Skill Rogue Velocity & PointLight:**
  - Removed unvalidated client-side `AssemblyLinearVelocity` injection from `InputController.TriggerSkill("Q")`.
  - Removed `PointLight` glow beneath Q sawblade waves in `CombatVFXController.luau`.
- **Vitals HUD Artifacts:**
  - Deleted obsolete white `LeadingCap` artifact from `HPBarFrame.BarFill`.

  ## [Phase 8.5] — Master Documentation & Architectural Ground-Truth Calibration

### 🧹 Purged Technical Drift & Reconciled Specs
- **Purged Stacked Historical Drafts:** Completely rewrote and unified `docs/COMBAT_SPEC.md`, `docs/PROGRESSION_SPEC.md`, `docs/ARCHITECTURE_SPEC.md`, `docs/UI_UX_SPEC.md`, and `docs/GAME_DESIGN.md` into clean, single-version authoritative specifications.
- **Master Technical Index Updated (`docs/README.md`):** Updated the foundational index to reflect `ASCEND_PlayerData_V3`, Phase 8.5 active status, the 8-tier Flying Sword arsenal, and the 10-realm matrix.
- **Canonical Keybind Map Codified:** Settle all keybinding conflicts across all documentation:
  - `M1` = 5-Hit Broadsword Combo (with +25% Sword Intent per hit)
  - `Left Control` = Sprint Toggle
  - `Left Shift` = Qi Flash-Step Dash (150 studs/s burst, +1.2 stud lift)
  - `T` = Guard (Hold) / Perfect Parry (Tap $<0.22\text{s}$)
  - `C` = Qi Meditation (10.0%/s Qi recovery)
  - `R` = Draw / Sheathe Weapon (Hand grip vs Back mount)
  - `V` = Flying Sword Flight Mode (75 studs/s aerial navigation)
  - `B` = Realm Breakthrough (Tribulation trial at 100% Qi)
  - `Q` = Skill: Sword Tempest (Melee cleave + 3 sawblades)
  - `E` = Skill: Piercing Void Thrust (High-velocity beam)
  - `F` = Ultimate: 100-Slash Flash Domain (Single-click domain)
  - `P` = Character Stats Sheet
  - `Tab` = Notice Board / Daily Duties
- **Cultivation Math Reconciled:** Verified progression formulas against `CultivationConfig.luau`. Codified the exact Order 9 power multiplier calculation ($220,000\times$ at Immortal Ascension Order 9) and Tribulation strike counts.
- **UI & Architectural Standards Formally Documented:**
  - Codified ADR-041 (Studio-Authoritative UI in `StarterGui`).
  - Codified ADR-042 (Bangers with black stroke for titles/billboards; Fundamento for body text).
  - Codified ADR-043 (`ModalWindowManager.luau` mutual exclusion).
  - Codified ADR-044 (3-Tier Jade Pure Sect stepped mountain layout).
- **Subsystem & Task Tracking Synchronized:** Fully refreshed `.ai/CURRENT_TASK.md`, `.ai/NEXT_STEPS.md`, and `.ai/PROJECT_STATUS.md` with 100% codebase-verified facts and zero inflated completion claims.

## [Unreleased] - 2026-09-17 (backfilled from Session Digest #2026-09-17)

### Added
- **Cultivation & Breakthrough Engine Calibration (`CultivationConfig.luau` & `CultivationManager.luau`):**
  - Calibrated 10-realm pacing curve (~20m Qi Condensation to ~49.4h Immortal Ascension).
  - Applied 20% starting Qi clamp, wired Sect `QiBuffMultiplier` into passive recovery, added Breakthrough Dan check, and integrated Inner Demon QTE trial with non-lethal backlash.
  - Aligned realm keys in `SectConfig.luau` to `GoldenCore`, `SpiritSevering`, and `TribulationTranscending`, adding Tier 3 quest Bloodline Spin rewards.
- **Client Inner Demon QTE Presentation (`CultivationController.luau`):**
  - Added dark vignette, camera shake, and focus pulse QTE UI during breakthrough trials.
- **Multiset Cauldron Alchemy Matching (`AlchemyConfig.luau`):**
  - Registered all 9 Breakthrough Dans with exact multiset ingredient count matching, preventing subset recipe conflicts.
- **4-Tier Wilderness Herb & Beast Core Balancing (`GatheringConfig.luau`, `MobConfig.luau`, `ItemConfig.luau`):**
  - Configured 4-tier herb ages across world nodes.
  - Added 4 wilderness mob danger tiers dropping graded beast cores (`DemonBeastCore` to `DemonBeastCore_1000Yr`).
- **On-Demand Sparring Duel Engine (`ArenaManager.luau` & `ArenaController.luau`):**
  - Implemented on-demand sparring with 50-stud circular Qi Ring, challenge modal, timer HUD, and 1-HP non-lethal concession.
- **Sect Safe Zones & Karmic Retribution (`HitboxManager.luau`):**
  - Integrated Sect Safe Zone 0-damage peace and Wilderness Karmic Retribution (75% penalty, 50% reflection) while preserving `CastCompensatedBox` and native posture logic.
- **Bloodline Foundation & Monetization (`BloodlineConfig.luau`, `MonetizationConfig.luau`, `PlayerDataManager.luau`):**
  - Configured bloodline lineages across 4 tiers with passives, gacha weights, and Meshy AI 3D manifests.
  - Registered Robux Bloodline spin DevProducts (25, 99, 399, 999 R$).
  - Integrated Bloodline & Spins persistence in `PlayerDataManager.luau` with lazy fallback init and 3D artifact welder.

### Changed
- **Skill F Refactor:** Re-engineered Skill F from a high-speed physics dash into a 28-stud instant Celestial Flash-Step / Blink slash to stop ragdoll tripping.

### Fixed
- Routed server announcements via `HeavenlyAnnouncement` remote after discovering `TextChannel:DisplaySystemMessage` is client-only.
- Fixed `PlayerDataManager` method invocation from invalid `AddSectContribution` to `AddContributionPoints`.
- Restored native posture handling in `HitboxManager.luau` after removing invalid require of non-existent `CombatConfig.luau`.
- Fixed secondary weapon/flight parts remaining anchored in `WeaponManager.luau`, which previously caused network ownership crashes (`serverHumanoidShim:39`) on dismount.
- Fixed `AddBloodlineSpins` static 5 return via lazy fallback attribute resolution.

---

## [Unreleased] - 2026-09-18 (backfilled from Session Digest #1)

### Added
- **Bloodline Manager & Controller Integration:**
  - Registered `BloodlineController` in `ClientMain.client.luau` and `BloodlineManager` in `ServerMain.server.luau`.
  - Implemented 30-pull Legendary and 100-pull Mythic pity counters, Keep/Discard refund actions, slot unlocking, and floating artifact offsets in `BloodlineManager.luau`.
  - Extended `PlayerDataManager.luau` schema with `BloodlineSlots`, `MaxBloodlineSlots`, and `BloodlinePity` with backward-compatible V3 migration.
  - Built `StarterGui.BloodlineGui` programmatically via Edit Mode Command Bar (100% scale, zero UICorner, Bangers/Fondamento typography).
  - Wired `BloodlineController.luau` to Altar ProximityPrompt (`E`), Pity readouts, Meridian Vault, and Keep/Discard modal with SFX `rbxassetid://138567614125924`.
- **Heavenly Cultivation Codex:**
  - Built `StarterGui.CodexGui` via Edit Mode Command Bar, mapping the feature manual to unmapped keybind `[H]`.
- **Dynamic Bloodline Meditation Auras (`CultivationManager.luau`):**
  - Moved `AuraTemplates` from Workspace to `ReplicatedStorage.AuraTemplates` (Tiers 1–4 modular attachments).
  - Decoupled meditation aura colors from Realm tiers; bound them directly to active Bloodline element palettes with a 12-palette `ColorSequence` dictionary.
- **Roster Expansion:**
  - Expanded bloodline roster from 10 to 12 lineages by adding `NineNetherSovereign` (Mythic #2) and `GlacialPhoenixMeridian` (Legendary #4).

### Changed
- Scaled Lightning 1 and Lightning 2 inside `workspace.UltimateSkill.Main` to 8.5 studs via Command Bar.
- Standardized all 12 bloodlines to floating companion orbs/halos, replacing body-clinging relic meshes.

### Fixed
- Corrected `BloodlineManager.luau` function call from non-existent `RollRandomBloodline` to `RollBloodline`.
- Corrected schema keys in `BloodlineManager.luau` to match `BloodlineConfig.luau` (`Name`, `Tier`, `VisualArtifact.ArtifactName`).
- Fixed spin consumption crash by invoking `PlayerDataManager.AddBloodlineSpins(player, -count)` instead of non-existent `UseBloodlineSpin`.
- Aligned client-server remote payload actions between `ExchangeSpins` and spin purchasing.
- Fixed syntax error in `CultivationManager.luau:927` caused by duplicate dictionary block and dangling `})`.

---

## [Unreleased] - 2026-09-19 (backfilled from Session Digest #2026-09-19A)

### Added
- **ASCEND Monkey Verification Protocol:** Adopted Studio Command Bar automated test harness; passed 9/9 server verification checks (collision groups, mob network ownership, anti-ragdoll states, state promotion).
- **Movement & Reaction Animation Suite:** Registered asset IDs for 13 R6 animations (Dash_W/A/S/D, Idle, Walk, Run, Landed, Equip, Unequip, HitReaction1/2, Parryed).

### Changed
- **Damage Number Presentation:** Set font to "Press Start 2P" / `Enum.Font.Arcade` and restricted popups to pure numbers only (purging "CRIT!", "PARRY!", and intent text) for zero screen clutter.
- **Sword Sheathing:** Reverted sword sheath (`R`) back to upper back of Torso instead of lower-left hip.
- **Skill Q Knockback:** Zeroed knockback (`Vector3.zero`) so the cleave slices enemies in place without pushing them out of range.
- **Locomotion Cadence:** Reverted locomotion to a weighted, sluggish glide (0.70x playback, upper body holding idle pose while legs run) with committed, slower M1 slashes.
- **Dash Mobility:** Re-enabled 4-way camera-relative dash with Shunpo vanish/reappear VFX.

### Fixed
- Fixed runtime crash in `CombatVFXController.luau` by using `Font.fromName("Press Start 2P")` with fallback to `Enum.Font.Arcade`.
- Fixed `Network Ownership API cannot be called on Anchored parts` crash in `CultivationManager.luau` during `C` meditation.
- Fixed 1.10s delay between M1 swings in `CombatStateManager.luau` caused by undefined `FlyingSwordConfig.Skills.M1`.
- Fixed permanent guard block in `CombatStateManager.luau` where `ActionState` remained stuck in `Active` without promoting to `Recovery`/`Idle`.
- Fixed parry clock compensation in `CombatStateManager.luau` and `InputController.luau` to use `Workspace:GetServerTimeNow()` instead of unsynchronized client/server `os.clock()`.
- Fixed high Y-velocity in `HitboxManager.luau` that forced knockback victims into `Freefall` and caused tripping/ragdoll.
- Fixed character body twisting during M1 slashes by locking `Humanoid.AutoRotate` against animation `RootJoint` keyframe rotation.

---

## [Unreleased] - 2026-09-19 (backfilled from Session Digest #2026-09-19B)

### Added
- **Phase 4 Flight Engine Server Handover:**
  - Integrated dynamic realm flight speed table (Foundation Establishment: 48 studs/s) across `FlyingSwordConfig.luau`, `CultivationManager.luau`, `WeaponManager.luau`, and `CombatStateManager.luau`.
  - Added 25 Qi/s flight drain, paused passive Qi recovery while flying, added 0-Qi auto-dismount, and enforced InCombat force-dismount (passed Double-Check 6/6).
- **StarterGui ScreenGui Builds (Edit Mode CMD):**
  - Built `StarterGui.SparringDuelHUD` following sharp dark celestial slate aesthetic, zero UICorner, no frame borders, multi-stop gradients, and responsive text sizing.
  - Overhauled `StarterGui.SectMerchantMarketGui`: converted all ImageLabels to native Frames, stripped UICorners and borders, simplified counter buttons to `-` and `+`, and deleted `Tab_TALISMANS`.

### Changed
- **General Merchant Policy:** Permanently purged all sword/weapon buying and selling from `SectMerchantMarketGui` (swords are sacred artifacts).
- **UI Architecture Standard:** Prohibited programmatic runtime `Instance.new` GUI generation in client scripts; all UI trees must reside in `StarterGui`.
- **Market Interaction:** Gated strictly behind Merchant Qian ProximityPrompt, eliminating keyboard toggle keybind.

### Fixed
- Fixed `AttachBloodlineVisual` coordinate doubling bug in `PlayerDataManager.luau` caused by creating `WeldConstraint` before setting CFrame.
- Fixed Qi oscillation in `CultivationManager.luau` where passive recovery ran concurrently with flight drain.
- Fixed Play Solo startup yield in `ServerMain.server.luau` that prevented background managers from executing `InitializeServer()`.
- Fixed hierarchy lookup in `MarketController.luau` by using recursive search for `MainFrame` inside `OverlayBackdrop`.
- Fixed crash in `MarketController.luau:248` by calling `SectConfig.GetAllMarketItems()` instead of non-existent `GetSectVendorItems`.

---

## [Unreleased] - 2026-09-20 (backfilled from Session Digest #2026-09-20)

### Added
- **DataStore V3 Persistence & Samsara Engine (`PlayerDataManager.luau`):**
  - Deployed DataVersion 3 schema with Samsara cycle tracking, Roman numeral title generator, and authoritative `RouteToSpawnDais` spawn fallback.
- **Pure Humanoid R6 Cultivator Roster (`MobConfig.luau`, `MobAIManager.luau`):**
  - Updated definitions for 10 Humanoid R6 Cultivators with `Name` and `DisplayName` schema safety.
  - Integrated top-level `SPAWNER_ALIAS_MAP`, unanchoring loop on spawn, and `DisplayName` fallbacks in `MobAIManager.luau`.
  - Generated 5 new R6 Cultivator models (`BanditCultivator`, `GhostBladeMarauder`, `FrostPeakApostle`, `VoidPhantomSwordmaster`, `AsuraSwordSovereign`) in `ReplicatedStorage.MobModels` with Motor6D `RightGrip` articulation.
  - Placed and tagged 5 new spawner anchor parts in `Workspace.MobSpawns`.

### Changed
- **Beast Mob Purge:** Permanently purged all beast mobs (`DemonWolf`, `IronhideBoar`, `SilverbackFrostApe`, `VoidChasmChimera`, `AbyssalDemonSovereign`) in favor of 100% Humanoid R6 Cultivators.
- **Production Scope Restructure:** Reset legacy phase numbering to eliminate drift; established authoritative 11-Phase Priority Roadmap with Phase 1 closed and Phase 2 active.
- **Network Remote Pruning (`RemoteEvents.luau`):** Pruned 16 legacy unused remotes; strictly declared and instantiated the 16 active game remotes with `--!strict` union typing.

### Fixed
- Fixed Roblox spawn engine rejecting pad and dumping players at world origin (930, 37, -616) by setting `Murim_SpawnDais.SpawnLocation` properties to `CanCollide = true`, `Anchored = true`, and `Neutral = true`.
- Fixed starter sword +5% damage perk being erased by `math.floor(15 * 1.05)` in `FlyingSwordServer.luau`; applied `math.round` and exposed `payload.CalculatedDamage`.
- Fixed server boot crash in `MobAIManager.luau:752` by defining `SPAWNER_ALIAS_MAP`.
- Fixed `CreateHealthUI` crash in `MobAIManager.luau:395` by providing fallbacks for missing `DisplayName` in `MobConfig.luau`.
- Fixed nil session cache race condition in `CultivationManager.luau` by applying synchronous fallback in `GetPlayerData`.


## [Phase 8.6 — Unified MainHub Drawer, 24h Stipend Persistence & Anti-Trip Server Engine] — 2026-09-20 (backfilled from Session Digest #1)

### Added
- **Unified MainHub Master Drawer (`StarterGui.MainHubGui`):**
  - Scaffolding of master navigation drawer with a CoreGui-styled 36×36 circular 4-square topbar button, 300px sharp sidebar (`Fondamento` font, monochrome Lucide vector icons, `UITextSizeConstraint [14, 22]`, no `UICorner`).
  - Fullscreen `MenuBackdrop` with `ScreenInsets = Enum.ScreenInsets.None` and 100px overscan permanently eliminating the 75px bottom safe-area viewport gap.
  - Scaffolded placeholder pages for `Page_Shop` (Heavenly Treasury) and `Page_Updates` (Celestial Updates) with controller wiring deferred.
- **Server-Authoritative Anti-Trip Engine (`AntiTripServer`):**
  - Deployed `StarterPlayer.StarterCharacterScripts.AntiTripServer` server-authoritatively disabling `HumanoidStateType.FallingDown` and `Ragdoll` across R6 character lifecycles, eliminating physics stumble tumbles.
- **Persistent 24-Hour Daily Sect Stipend Cycle:**
  - Implemented exact 24-hour (`86,400s`) cooldown cycle in `SectManager.luau` persisted via DataStore in `PlayerDataManager.luau` and keyed to `player.UserId`.
  - Dispatches live ticking countdown clock (`CLAIM IN 23h 59m 59s`) that persists across session reloads.

### Changed
- **Docked Panel Integration:**
  - Docked `SpiritPouchInventoryGui.MainFrame` into `PageContainer` as `Page_Inventory`, purging red `X` close button, stripping spring pop-up scale tweens, and purging independent `I` keybind.
  - Docked `SectPavilionGui.MainFrame` into `PageContainer` as `Page_Faction`, purging red `X` close button and independent `M` keybind.
- **ProximityPrompt Station Isolation:**
  - Restored `AlchemyGui` and `StarterGuideGui` back to standalone ScreenGuis for physical in-world ProximityPrompt interactions.

### Fixed
- **`PlayerDataManager.luau` Syntax Error:** Corrected syntax error on line 412 (`Namespace:GetDataStore`), restoring the full 600+ line authoritative script.
- **R6 `StepHeight` Compatibility:** Wrapped `Humanoid.StepHeight` in `AntiTripServer` in a safe call to prevent runtime exceptions on R6 rigs.
- **`GatheringManager.luau` Silent Harvest Abort:** Corrected `GetConfig` to query `GatheringConfig.GetNode()`, unblocking node interaction.
- **Duplicate Quest Progression:** Diagnosed and isolated double-call bug in `MobAIManager.luau` and triple-call bug in `GatheringManager.luau`.
- **Machine-Gun Audio Click Bug:** Isolated duplicate `.Activated` listener stacking in `SectController.luau`.