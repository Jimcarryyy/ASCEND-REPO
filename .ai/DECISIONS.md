# Architecture Decision Log

## Purpose
This document records key architecture decisions for ASCEND, including accepted design patterns, security rules, and strategic pivots.

---

## ADR-001 to ADR-011: Core Framework, Networking & Persistence
*(Preserved historical records: Server-authoritative state, RemoteEvent factory pattern, DataStoreService persistence, and spatial hitbox queries.)*

---

## ADR-012: Codebase Pruning & Legacy Non-Sword File Removal
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Legacy gauntlet and spear weapon scripts cluttered the codebase.
* **Decision:** Deleted `GauntletServer`, `SpearServer`, `GauntletConfig`, and `SpearConfig`. Routed 100% of attack requests strictly through `FlyingSwordServer.luau`.

## ADR-013: Stat Progression Curve Normalization ($100 \rightarrow 10,000$ HP/Qi)
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Astronomical 50B Qi numbers caused UI layout overflows and arithmetic issues.
* **Decision:** Normalized stat progression across all 5 Cultivation Realms (45 Orders) to a clean $100 \rightarrow 10,000$ HP/Qi RPG scale in `CultivationConfig.luau`.

## ADR-014: Studio-Authoritative 3D Attachment Workflow
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Pure CFrame offsets in code required tedious trial-and-error adjustments.
* **Decision:** Position `RightGripAttachment` and `BodyBackAttachment` visually inside 3D models in Studio + live CMD calibration. `WeaponManager.luau` reads model attachments directly on spawn.

## ADR-015: Traditional Xianxia Light-Mode Flat 2D UI Palette
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Needed a high-contrast, clean UI system suited for mobile & PC.
* **Decision:** Adopted the Light-Mode Palette across all HUDs and Modals:
  - `#F8FAF9` (Main Window Modal)
  - `#F1F5F9` (Sub-Panel Containers)
  - `#FFFFFF` (Cards & Grid Slots)
  - `#CBD5E1` (Edge Borders)
  - `#0F172A` (Deep Charcoal Text)
  - `#D97706` (Warm Amber Gold Action Buttons)

## ADR-016: Ultra-Scaled Down MVP Architecture (5 Master 3D Base Models & 1 Master Sect Island)
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Generating and calibrating 32 individual 3D models and massive continent maps creates severe developer burnout and mobile memory lag.
* **Decision:** 
  1. **Weapons = 100% Passive Stat Multipliers + Visual Prestige:** Launch V1 with 5 Master Base Sword Models (*Mortal Iron*, *Jade Dragon*, *Sun Slayer*, *Thunder Frost*, *Heavenly Void*) in `ReplicatedStorage` dynamically re-colored/tinted via `ItemConfig.luau` (`PrimaryColor`).
  2. **Universal 1-Pack Skillset:** All swords share 1 universal R15 animation pack and 6 hotbar skill keys (`M1` Slashes, `Shift` Windstep, `F` Magma 3-Wave Crescent Cleave, `Q` Area Blast, `E` Homing Sword, `R` Sunfall Ultimate).
  3. **1 Master Sect Island ($500 \times 500$ studs):** Launch V1 on a single, compact, high-density Stylized Painted Low-Poly island with a 15-second walk loop connecting Spawn, Practice Dummies, Herb Meadows, Bronze Cauldron, and Sword Gacha Altar.
  4. **Deprecated Obsolete Documents:** Marked `SWORD_MASTERY_SPEC.md` and `ECONOMY_AND_MARKET_SPEC.md` as deprecated for V1 MVP.

## ADR-017: World Resource Gathering Engine & Weighted Herb Age Randomization
* **Status:** Accepted (Updated 2026-08-10)
* **Context:** Creating separate 3D models for every vintage herb age (1-Yr, 10-Yr, 100-Yr, 1000-Yr) creates asset bloat in Studio.
* **Decision:** Placed world nodes (`SpiritGrass`, `DragonBloodVine`, `GaleWindLotus`) use a weighted random RNG roll upon harvest in `GatheringManager.luau`, granting randomized vintage item IDs (`SpiritGrass_1Yr`, `SpiritGrass_100Yr`, etc.) into player inventory from a single 3D model.

## ADR-018: Manual 3-Slot Cauldron Combination Alchemy Architecture
* **Status:** Accepted (Updated 2026-08-10)
* **Context:** Static 1-click recipes lacked depth and player agency.
* **Decision:** Upgraded `AlchemyController.luau` to feature 3 Cauldron Slots where players manually select herbs from their Spirit Pouch. `AlchemyConfig.luau` strictly validates archetype requirements and applies dynamic success/potency multipliers based on inserted herb ages.

## ADR-019: Stylish Realism World Design Strategy (Zone 2 Verdant Bamboo Valley)
* **Status:** Accepted (Updated 2026-08-10)
* **Context:** Transitioned map environment from flat low-poly to high-contrast semi-realistic PBR style.
* **Decision:** Constructed Zone 2 with PBR river water reflections, dense bamboo foliage, timber cottage, and stone meditation pads. Kept all node interactions decoupled via `workspace.GatheringNodes` and `workspace.AlchemyCauldrons`.

---\n
## ADR-020: Non-Disappearing World Nodes & On-Screen Item Toast Architecture
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Permanent world water features like `CelestialSpring` disappeared upon harvest, and herb collection lacked immediate visual feedback.
* **Decision:** Added `KeepModelVisible = true` flag in `GatheringConfig.luau` so springs remain visible during cooldown. Built `HUDController.ShowItemToast` displaying animated rarity-colored PNG banners on resource collection.

## ADR-021: Interactive Qi Flame Temperature Minigame & Quality-Metadata Stacking Architecture
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Instant alchemy loading bars lacked skill-based gameplay, and pills merged into generic stacks regardless of herb vintage.
* **Decision:** Added a needle slider flame control minigame in `AlchemyController.luau`. Updated `InventoryManager.luau` and `AlchemyManager.luau` to store quality metadata (*Standard*, *Refined Medium*, *Century Superior*, *Sovereign Immortal*) and prevent high-grade pill stack merging.

## ADR-022: Alchemy Mastery Rank & EXP Progression
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Peaceful crafting playstyles required dedicated profession leveling.
* **Decision:** Added persistent `AlchemyExp` and `AlchemyLevel` tracking in `PlayerDataManager.luau` under DataStore `ASCEND_PlayerData_V2` + Cauldron UI header progress bar (*Apprentice Alchemist* $\rightarrow$ *Pill Emperor*).

## ADR-023: 2D PNG Asset Registry & Dynamic Quality Card Tinting Engine
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Plain text placeholders in inventory slots looked unpolished and lacked identity.
* **Decision:** Registered 12 custom transparent 2D PNG asset IDs in `UIAssets.luau` and `ItemConfig.luau`. Cards in Spirit Pouch (`InventoryController.luau`), Cauldron UI (`AlchemyController.luau`), and Hotbar/Toasts (`HUDController.luau`) adapt background colors and borders dynamically based on rarity and quality grade.

## ADR-024: Standard Roblox 12-Minute Day/Night Lighting Engine
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** World environment remained static daytime blue without day/night progression.
* **Decision:** Built `EnvironmentTimeManager.luau` running a server-authoritative 12-minute day/night cycle ($1\text{ in-game hour} = 30\text{ real-world seconds}$) with dynamic `Atmosphere` fog density blending over static skybox textures.

## ADR-025: Custom Xianxia HUD Template & Monetized HUD Skin Engine
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Default HUD box lacked visual identity, and swapping custom HUD templates broke slot alignments.
* **Decision:** Integrated custom HUD template `rbxassetid://107254331482831` (`VitalHUDFrame`) with $800\text{ Max Qi}$ backend sync. Created `HUDSkinConfig.luau` storing skin asset IDs alongside custom slot coordinate offsets (`DefaultBronze`, `SakuraImmortal`, `AzureDragon`) so equipping skins auto-snaps slot alignments without layout destruction.

## ADR-026: ActionSkillBar Integration & Cooldown Overlays
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Action skill hotbar needed background styling and skill cooldown feedback.
* **Decision:** Bound `ActionSkillBar` slots (`Slot_E`, `Slot_F`, `Slot_M1`, `Slot_Q`, `Slot_R`, `Slot_Shift`) to background `rbxassetid://97080305696865` in `HUDController.luau`, adding keybind badges and dark radial/vertical swipe cooldown overlays with countdown timers (`HUDController.TriggerSkillCooldown`).

## ADR-027: Azure Cloud Realm Jade & Cloud 2D UI Panel Identity
* **Status:** Accepted (Updated 2026-08-12)
* **Context:** Main modal windows required a distinct Xianxia visual identity matching *The Azure Cloud Realm*.
* **Decision:** Approved flat 2D AI panel concept featuring pale jade celadon fills (`#E2F1ED`), azure cloud watermarks (`#38BDF8`), gold/jade cloud scroll borders, and an extended top-right circular close button plaque slot.

### ADR-028 — 10 Major Realm Cultivation & Dantian Progression Overhaul
* **Date:** 2026-08-15
* **Status:** Confirmed & Implemented
* **Context:** The original 5 Major Realm scale ($100 \rightarrow 10,000$ HP/Qi) felt too short for Version 1 and lacked the "Number Go Up" progression feedback loop characteristic of Xianxia cultivation literature.
* **Decision:**
  1. Expanded cultivation hierarchy to **10 Major Realms with 9 Orders each (90 total sub-stage orders)**: Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing, Void Refining, Body Integration, Mahayana, Tribulation Transcending, and Immortal Ascension.
  2. Moderately exaggerated stat scale capping at **$100\text{M} - 150\text{M}$ HP/Qi** for Version 1 Immortal Ascension Order 9, preserving the Billions/Trillions scale for future Upper Realm expansion updates.
  3. Established three distinct Qi concepts to govern Dantian progression:
     * `CurrentQi`: Active energy usable for combat skills ($\text{CurrentQi} \le \text{CultivatedQi}$).
     * `CultivatedQi`: The player's reached Dantian capacity limit. In-combat passive and active recovery strictly caps at `CultivatedQi`.
     * `MaxQiGoal`: Internal breakthrough goal threshold ($\text{CultivatedQi} \le \text{MaxQiGoal}$).
  4. Breakthroughs (**[B]** key) require $\text{CultivatedQi} \ge \text{MaxQiGoal}$. Achieving a breakthrough advances the Order/Realm and expands `MaxQiGoal` while **preserving existing `CurrentQi` and `CultivatedQi`** (no reset to 0).
  5. Implemented dynamic percentage-based skill Qi consumption (Shift = 3%, F = 8%, E = 12%, Q = 15%, R = 30% of `CultivatedQi`).
  6. Implemented percentage-normalized combat damage multipliers ($\text{Damage} = \text{Base} \times \text{PowerMultiplier}$) ensuring balanced Time-To-Kill between equal-tier cultivators while allowing high-realm cultivators to instant one-shot low-realm cultivators.
* **Consequences:** Created an addictive, long-term progression loop while keeping combat TTK balanced across all 10 realms.

### ADR-029 — Avatar Rig Paradigm Pivot (R15 to R6) & Locomotion Engine
* **Date:** 2026-08-15
* **Status:** Confirmed & Implemented
* **Context:** R15 15-joint animation keyframing was too complex and time-consuming for solo development, while R6 provides faster keyframing velocity, snappy combat readability, and superior mobile performance.
* **Decision:**
  1. Pivoted avatar rig baseline from R15 to **R6** in Roblox Game Settings (`Standard R6`).
  2. Updated `WeaponManager.luau` with dual R6 (`Right Arm`) and R15 (`RightHand`) limb detection for forward-compatibility with future custom rigs.
  3. Created `src/StarterPlayer/StarterCharacterScripts/Animate.client.luau` as a dedicated R6 locomotion engine that overrides default Roblox movement scripts on all spawned characters.
  4. Registered custom R6 movement animation suite in `AnimationConfig.luau`: Idle (`98257310687211`), Walk V1 (`92949542384678`), Run V1 (`106115576089829`), Jump (`115002701112708`), Fall (`105371732122929`), Land (`127232864368618`), Climb (`92318229141460`), and Swim (`232873130`).
  5. Implemented holding LeftShift to sprint (`WalkSpeed = 28` playing `Run V1`) vs normal walking (`WalkSpeed = 16` playing `Walk V1`).
  6. Applied dynamic wide R6 body scale (`BodyWidthScale = 1.18`, `BodyDepthScale = 1.08`) on server character spawn in `ServerMain.server.luau` for all players.
* **Consequences:** Dramatically accelerated animation development velocity and improved combat visual clarity.

### ADR-030 — Environment Polish Pass, Tree Collision Cleanup & Organic Wind Physics
* **Date:** 2026-08-16
* **Status:** Confirmed & Implemented
* **Context:** Tree foliage created invisible bounding box walls that blocked players away from visible trunks, world lighting lacked atmospheric depth, and forest vegetation appeared static.
* **Decision:**
  1. Implemented `TreeCollisionManager.luau` server module: automatically scans `Workspace` trees and bamboo, sets foliage/leaves to `CanCollide = false`, and keeps tree trunks and individual bamboo stalks (`CanCollide = true`), eliminating invisible canopy walls.
  2. Upgraded `EnvironmentTimeManager.luau` with a 12-minute 4-phase Xianxia lighting cycle (Morning, Noon, Sunset, Moonlit Night) featuring soft directional shadows and moonlit ambient depth (`OutdoorAmbient = #415073`) to prevent pitch-black tree silhouettes at night.
  3. Implemented `WindEnvironmentController.luau` client controller: single-loop organic gusting wind (`REST -> GUST -> SWAY -> SETTLE`) with spatial culling (<160 studs) and `math.noise` position offsets for desynchronized sway across large trees, small trees, flexible bamboo stalks, and grass.
* **Consequences:** Transformed the world into a living, responsive Xianxia environment without adding PointLight clutter or dropping mobile FPS.

## Architectural Decisions — Fast-Track V1 & UI/UX Hybrid Architecture

### 1. Fast-Track V1 Scope Pivot
- **Context:** Custom 3D beast rigs and multi-phase boss mechanics require high asset authoring overhead for a solo developer.
- **Decision:** Shift complex custom-rigged beasts to late-stage content. For V1 MVP, use standard R6 humanoid mobs and an equalized same-realm 1v1 Sparring Arena for combat progression, prioritizing monetization and sect loop retention.

### 2. Hybrid Studio UI Architecture (Explorer Hierarchy + Luau Data Binding)
- **Context:** Pure programmatic `Instance.new` UI makes visual styling tedious to adjust in Studio.
- **Decision:** Build visual UI layouts in Studio Explorer under `StarterGui` (using `Scale` and `UIAspectRatioConstraint`), while Luau controllers (`QuestTrackerController`, `SkillBarController`, `HUDController`, `MarketController`) handle data binding, remote syncing, and user interaction.

### 3. Unified Dark Obsidian & Antique Gold Palette
- **Context:** The UI was previously fragmented between bright white/pastel cards and dark modals.
- **Decision:** Standardized on `#111827` (Deep Background), `#1C2638` (Secondary Surface), `#8B6B32` / `#C49A4A` (Antique Gold Borders), `#F1E8D2` (Warm Ivory Text), `#10B981` (Jade Vitality), and `#3B82F6` (Azure Qi). Rarity colors are applied as subtle outer border strokes rather than full-card background fills.

### Architectural & Design Decisions (Combat & Locomotion Session)

1. **Pure Sword Focus for V1 Launch Scope:**
   - Eliminated legacy generic weapon classes (`Spear`, `Gauntlet`) from `AnimationConfig.luau`. All combat is 100% focused on Pure Sword Dao (Jian straight swords & Dao curved sabers).

2. **Combat Commitment vs Fast Sprinting:**
   - Sprinting at 52 studs/sec during attacks broke hitbox accuracy and Arena balance. We established **Combat Commitment Footwork**: attacks dampen speed to `WalkSpeed = 8` during swings, returning to normal speed upon recovery.

3. **Dynamic Arena Speed Scaling:**
   - Character speed dynamically adapts: Deepwoken-balanced speeds inside the Sector 3 Arena (`16 / 28`), fast high-mobility speeds in the Open World (`18 / 52`).

4. **Independent Studio Attachment Pairing:**
   - Swapped hardcoded programmatic CFrame rotations for calibrated attachment pairs (`RightGripAttachment` <-> `SwordAttachment` in hand, `BackSwordMount` <-> `BackSwordAttachment` on back).

5. **Anti-Ragdoll Physics Constraint in R6:**
   - Standard Roblox R6 physics introduces severe balance-tipping bugs on stepped terrain. Permanently disabling `Ragdoll`, `FallingDown`, `PlatformStanding`, and `GettingUp` produces a rock-solid, responsive martial arts combat feel.
