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

### ADR-031 — Sect Zone (Zone 1) V1 Scope
* **Date:** 2026-08-31
* **Status:** Agreed scope, not yet built or verified as built
* **Source:** Decided in Architect session
* **Context:** Zone 1 already has Alchemy shop, Sect shop, mission board, and training dummy built. Remaining V1 scope needed clarification before further work.
* **Decision:** In-scope additions for V1 (design agreement only — none confirmed built):
  1. Central Sect Altar / Sword Gacha roll (status unconfirmed — referenced in original MVP doc)
  2. Beginner tutorial/onboarding flow (linear: greet → M1 on dummy → alchemy demo → gathering intro → mission board intro), gated by a new save-flag (`TutorialComplete` or similar — does not yet exist in `PlayerDataManager`)
  3. Sect Elder Pavilion — needs clarification on whether distinct from Sect shop or the same structure
  4. Visible Contribution Point display/progress toward next Disciple promotion
  5. Confirmed spawn/respawn point tied to sect plaza
  6. Sect notice board / lore NPCs (optional, low-cost)
  7. Meditation spot / cultivation garden marker (visual only, ties to existing `C` meditate mechanic)
  8. Portal / zone-transition gateway to Zone 2 (can be visually locked/teased pre-Zone-2)
  9. Optional: storage/bank NPC separate from inventory
* **Consequences:** None of the above should be logged as complete until the developer confirms it in Studio.

### ADR-032 — 16 Personal Mini-Houses Deferred for V1
* **Date:** 2026-08-31
* **Status:** Deferred, not cancelled
* **Source:** Decided directly with developer
* **Context:** Developer raised a "16 personal mini-houses per server" feature for Zone 1.
* **Decision:** Cut from V1 scope. Not to be resurfaced as a pending task unless the developer brings it back up.

# Architecture Decision Log — ASCEND

## Purpose
Records structural architectural decisions, design paradigms, security patterns, and scope resolutions.

---

### ADR-033 — Studio-Authoritative GUI Migration & 2D Asset Standardization
* **Date:** 2026-09-02
* **Status:** Accepted & Implemented
* **Context:** Programmatic `Instance.new` UI generation caused layout drift, made Studio editing difficult, and introduced viewport scaling conflicts between PC and mobile.
* **Decision:**
  1. Replaced hardcoded client GUI generation with direct bindings to Studio Explorer instances (`SkillsGUI`, `LowViewPortSkillsGUI`, `CurrencyGUI`, `BottomMenuGui`, `SectMissionGui`, `GlobalToastNotifGui`).
  2. Maintained separate Desktop (`SkillsGUI`) and Mobile (`LowViewPortSkillsGUI` + right-side touch cluster) interfaces.
  3. Replaced 3D ViewportFrames in the inventory and market with high-resolution 2D PNG assets across all 8 sword tiers.

### ADR-034 — Looping Sword Intent Combat Engine
* **Date:** 2026-09-02
* **Status:** Accepted & Implemented
* **Context:** M1 combo strikes lacked mid-combat progression and mechanical reward for sustained aggression.
* **Decision:**
  1. Implemented a dynamic `SwordIntent` gauge ($0 \rightarrow 100$).
  2. Each landed M1 strike generates $+25\%$ Intent (4 hits to full charge).
  3. At $100\%$ Intent, the next M1 strike consumes the entire gauge to deal $1.75\times$ Empowered Damage with golden critical VFX and audio impact.
  4. Gauge immediately resets to $0\%$ upon strike execution, creating an infinite combat loop.
  5. If the player leaves combat for $>2.5$ seconds, Intent continuously decays at $8\%/\text{s}$.

### ADR-035 — Single-Bar Overhead UI & FredokaOne Styling
* **Date:** 2026-09-02
* **Status:** Accepted & Implemented
* **Context:** The player overhead display had redundant Qi bars, static text bindings, and lacked visual punch.
* **Decision:**
  1. Stripped the Qi bar from overheads (Qi is tracked in the bottom HUD).
  2. Applied a 3-stop $90^\circ$ emerald-to-jade vertical gradient to the HP bar (`#4ADE80` $\rightarrow$ `#22C55E` $\rightarrow$ `#15803D`) with a 2px solid white `UIStroke` and `UICorner` of 30.
  3. Standardized all overhead text to `Enum.Font.FredokaOne` with dynamic attribute listeners on `Realm` and `SectRank`.

### ADR-036 — Keybind Consolidation: Exclusive `C` Meditation
* **Date:** 2026-09-02
* **Status:** Accepted & Implemented
* **Context:** Multiple keys (`C` and `M`) were triggering meditation across `InputController` and `SkillBarController`.
* **Decision:**
  1. Removed `Enum.KeyCode.M` from all controllers.
  2. Assigned **`C`** as the exclusive keybind for Cultivation/Meditation on Desktop, with `C_SKILL` on the HUD.
  3. Centralized `V` (Flight), `R` (Draw/Sheath), `B` (Breakthrough), `Shift` (Dash), `CTRL` (Run Toggle), and `T` (Block/Parry).

### ADR-037 — Dynamic Market Sword Catalog & Exact Currency Synchronization
* **Date:** 2026-09-02
* **Status:** Accepted & Implemented
* **Context:** The Sect Exchange shop only displayed 3 hardcoded swords, and Contribution Points rounded to `2.0K CP` instead of showing exact values.
* **Decision:**
  1. Updated `MarketController.luau` to dynamically iterate through `ItemConfig.GetAllItems()`, auto-populating all Tier 1–8 swords into the `SWORDS` and `ALL` tabs.
  2. Swapped numerical rounding for exact integer formatting (`FormatCurrency`), ensuring `1,970 CP` displays accurately across the Pavilion header and HUD.


  # Architecture Decision Log — ASCEND

## Purpose
This document records structural architectural decisions, design paradigms, security standards, and engine pivots across the ASCEND project.

---

### ADR-012: Codebase Pruning & Legacy Non-Sword Purge
* **Status:** Accepted
* **Context:** Legacy gauntlet and spear scripts cluttered the codebase and diluted the Xianxia identity.
* **Decision:** Deleted `GauntletServer`, `SpearServer`, `GauntletConfig`, and `SpearConfig`. Routed 100% of attack requests strictly through `FlyingSwordServer.luau`.

### ADR-013: Stat Progression Curve Normalization
* **Status:** Accepted
* **Context:** Astronomical 50B numbers created arithmetic overflow and UI layout distortion.
* **Decision:** Re-anchored base stats to clean mathematical curves governed by `CultivationConfig.luau`.

### ADR-014: Studio-Authoritative 3D Attachment Workflow
* **Status:** Accepted
* **Context:** Pure CFrame code offsets required tedious trial-and-error manual adjustments.
* **Decision:** Position `RightGripAttachment` and `BodyBackAttachment` visually inside 3D models in Studio. `WeaponManager.luau` reads attachments directly on spawn.

### ADR-015: Dark Obsidian & Antique Gold UI Palette Standard
* **Status:** Accepted
* **Context:** Interface styling was fragmented between legacy pastel light-mode cards and dark modals.
* **Decision:** Standardized on `#111827` (Deep Background), `#1C2638` (Secondary Surface), `#8B6B32` / `#C49A4A` (Antique Gold Borders), `#F1E8D2` (Warm Ivory Text), `#10B981` (Jade Vitality), and `#3B82F6` (Azure Qi).

### ADR-028: 10 Major Realm Cultivation & Dantian Progression Overhaul
* **Status:** Accepted
* **Context:** Original 5-realm structure felt too brief and lacked the exponential progression loop characteristic of Xianxia literature.
* **Decision:** Expanded hierarchy to 10 Major Realms with 9 Orders each (90 total stages). Established tripartite Dantian architecture (`CurrentQi <= CultivatedQi <= MaxQiGoal`) where `CultivatedQi` and `CurrentQi` are 100% preserved upon breakthrough.

### ADR-029: Avatar Rig Paradigm Pivot (R6 Standard) & Dedicated Locomotion
* **Status:** Accepted
* **Context:** R15 15-joint keyframing was overly complex for a solo developer, whereas R6 ensures fast keyframing, snappy martial arts readability, and 60 FPS mobile performance.
* **Decision:** Pivoted character baseline to R6. Implemented `Animate.client.luau` in `StarterCharacterScripts` to override default movement scripts, adding idle yaw pinning, velocity-synced footstep audio, and anti-ragdoll state locking.

### ADR-030: Tree Collision Cleanup & Organic Wind Physics
* **Status:** Accepted
* **Context:** Foliage bounding boxes blocked character movement on slopes, and static world props felt lifeless.
* **Decision:** Created `TreeCollisionManager.luau` (sets foliage `CanCollide = false` while keeping trunks solid) and `WindEnvironmentController.luau` (organic desynchronized vertex swaying with <160 stud spatial culling).

### ADR-033: Studio-Authoritative GUI Architecture
* **Status:** Accepted
* **Context:** Programmatic `Instance.new` UI generation caused layout drift and made Studio visual editing impossible.
* **Decision:** Migrated all UI components to direct bindings on Studio `StarterGui` hierarchies (`SkillsGUI`, `LowViewPortSkillsGUI`, `CurrencyGUI`, `BottomMenuGui`, `SectMissionGui`, `GlobalToastNotifGui`).

### ADR-034: Looping Sword Intent Combat Engine
* **Status:** Accepted
* **Context:** Basic attack combos lacked mid-combat progression and mechanical reward for aggression.
* **Decision:** Implemented dynamic Sword Intent gauge (+25% per landed M1 strike; at 100%, next strike deals 1.75× Empowered Damage and resets gauge to 0%). Decay activates at 8%/s after 2.5s of hit inactivity.

### ADR-036: Keybind Consolidation
* **Status:** Accepted
* **Context:** Overlapping keys (`C` vs `M` for meditation; `F` skill naming collisions) caused input confusion.
* **Decision:** Enforced canonical bindings: `M1` (Combo), `Q` (Sword Tempest), `E` (Telekinesis Thrust), `F` (Falling Sky Slam), `T` (Block/Parry), `Shift` (Dash), `C` (Cultivate), `R` (Draw/Sheath), `B` (Breakthrough), `CTRL` (Sprint Toggle).

### ADR-038: Blacksmith Weapon Refinement (+10) & Blade Sharpening Engine
* **Status:** Accepted
* **Context:** Players needed permanent weapon progression sinks and temporary combat buffs using gathered materials and currency.
* **Decision:** Implemented server-authoritative `BlacksmithManager.luau` and client `BlacksmithController.luau`. Supported refining weapons up to `+10` (+5% base ATK per level). Added Blade Sharpening (100 Spirit Stones, +10% Crit for 15 minutes).

### ADR-039: Spirit Tea Pavilion Buff Architecture & Timed Attribute Modifiers
* **Status:** Accepted
* **Context:** The game lacked consumable session buffs tied to low-cortisol roleplay in the Sect hub.
* **Decision:** Implemented server-authoritative `TeaHouseManager.luau` and client `TeaHouseController.luau`. Added 3 distinct tea brews providing instant restoration (HP/Qi) plus timed attribute buffs (10–15 min) for meditation cultivation speed and sword intent accumulation.

### ADR-040: Interactive Sect Starter Guide & Authoritative Training Grounds
* **Status:** Accepted
* **Context:** New players lacked in-game onboarding for martial controls, and there was no objective way to measure combo damage or test DPS.
* **Decision:** Implemented `StarterGuideController.luau` bound to `Sect_NPC_ElderQing` (4-tab interactive manual). Implemented `ImmortalDummyHandler.server.luau` on 3 Ironwood Dummies with server-authoritative DPS calculation and reset hooks via `SparringGuidanceController.luau`.

### ADR-041: Strict Prohibition of Runtime Programmatic UI Generation
* **Status:** Accepted (Developer Messages 168, 172, 178)
* **Context:** Generating UI layouts dynamically via Lua `Instance.new()` leads to layout misalignment, unmaintainable codebases, and inability to adjust styling visually in Roblox Studio.
* **Decision:** All GUI elements must be authored directly in `StarterGui` (via Studio Tools or Command Bar scripts). Client scripts are strictly limited to acquiring instance references, binding events, tweening, and populating live text data.

### ADR-042: Sect Typography Standard (`Bangers` & `Fundamento`)
* **Status:** Accepted (Developer Messages 107, 108, 125, 127, 128, 168)
* **Context:** Font choices were inconsistent across the game (mixing Cinzel, FredokaOne, and default sans-serif).
* **Decision:** Standardized typography across the entire project:
  1. **Headers, Titles, Station Billboards & NPC Names:** `Enum.Font.Bangers` with a mandatory solid black `UIStroke` outline (`Color3.fromRGB(0, 0, 0)`, `Thickness = 1.5 - 2.0`).
  2. **Body Copy, Descriptions, Quest Details & Dialogue:** `Enum.Font.Fundamento`.

### ADR-043: ScreenGui DisplayOrder Layering Hierarchy
* **Status:** Accepted (Developer Messages 175, 183)
* **Context:** Opening facility modals caused visual collision and input blocking with the persistent HUD.
* **Decision:** Enforced strict DisplayOrder hierarchy: `MasterHUDGui` = 1, `OverheadUI` = 5, all Facility Modals (`BlacksmithGui`, `TeaHouseGui`, etc.) = 10, `ArenaGUI` = 12, `GlobalToastNotifGui` = 20, `LoadingScreen` = 100.

### ADR-044: Three-Tier Elevation Sect World Architecture & Aesthetic
* **Status:** Accepted (Developer Messages 2, 38, 94, 105, 115, 131, 133, 134)
* **Context:** Flat world terrain felt uninspired and lacked the grand spatial hierarchy characteristic of prominent Xianxia sword sects.
* **Decision:** Structured Zone 1 into 3 distinct stepped elevation tiers:
  - **Tier 1 (Lower):** Practical services, crafting, training grounds, daily duties, outer disciples, and market.
  - **Tier 2 (Middle):** Elevated Dao Sanctuary and Sword Altar (blade attunement/gacha) with non-trip R6 stairs and inner disciple quarters.
  - **Tier 3 (Upper):** Sovereign Sect Palace with black roof tiles, housing the Supreme Sect Leader, Grand Sword Elder Liang, and the Top 7 Pillars of the Sect.

  ### ADR-045 — Jade Pure Sword Sect World Rebranding & 7 Sword Pillars
* **Date:** 2026-09-08
* **Status:** Accepted
* **Context:** "Azure Cloud Sect" was generic and did not reflect a dedicated Sword Dao sect. The developer chose a stylized homage to *Top Tier Providence* (*Yuqing / Jade Pure Sect*).
* **Decision:**
  1. Rebranded Sect to **Jade Pure Sword Sect** across all 3D signs, UI headers, and `SectConfig.luau`.
  2. Established **The 7 Sword Pillars of the Jade Pure Sect** representing the 7 paths of the blade: Ye Chen (Azure Dragon), Hong Lian (Crimson Flame), Leng Wushuang (Frost Lotus), Lei Zhen (Thunder Crag), Gu You (Cosmic Void), Feng Qing'er (Celestial Wind), and Mo Chen (Shadow Asura).
  3. Integrated **Ancestor Han's Avatar** into the Tier 3 secluded meditation cave (*1,000-Year Seclusion Qi* bonus).

### ADR-046 — Universal ProximityPrompt & Tag-Driven Stations Architecture
* **Date:** 2026-09-08
* **Status:** Accepted
* **Context:** Hardcoded folder scanning (`Workspace.MarketVendors`, `Workspace.AlchemyCauldrons`) broke when moving assets.
* **Decision:**
  1. Standardized all interactive world assets under **`Workspace.Functional_Stations`**.
  2. Replaced folder-dependent polling with universal `ProximityPrompt` event hooks across server managers (`VendorManager`, `BlacksmithManager`, `TeaHouseManager`, `AlchemyManager`, `SectManager`, `ArenaManager`).

### ADR-047 — Monolithic Flat Block Floor Physics & Z-Fighting Elimination
* **Date:** 2026-09-08
* **Status:** Accepted
* **Context:** Thin cylinders used as walkable floors caused severe character sinking due to Roblox cylinder collision faceting, and co-planar floor slabs caused GPU Z-fighting.
* **Decision:**
  1. Prohibited `PartType.Cylinder` on walkable floor collision surfaces. All walkable floors must be solid rectangular Blocks (`CanCollide = true`). Circular Dao inlays are set to `CanCollide = false`.
  2. Enforced a minimum $+0.08\text{-stud}$ vertical separation between decorative inlays and foundation beds.
  3. Merged `Sect_SwordAltar_Foundation` and `Sect_JadePure_SwordAltar` into **`Sect_SwordAltar_Complete`** with 4-way flush R6 steps ($1.0\text{-stud}$ height).

### ADR-048 — 19-NPC Sect Roster & Native R6 Attachment Standard
* **Date:** 2026-09-08
* **Status:** Accepted
* **Context:** NPCs lacked standard R6 attachments for weapon socketing, and limbs were incorrectly anchored, breaking animations.
* **Decision:**
  1. Enforced standard R6 rigging with all 11 official attachments (`RootAttachment`, `HatAttachment`, `HairAttachment`, `FaceCenterAttachment`, `FaceFrontAttachment`, `BodyBackAttachment`, `WaistBackAttachment`, `RightGripAttachment`, `LeftGripAttachment`, `RightFootAttachment`, `LeftFootAttachment`).
  2. Enforced physics rule: **Only `HumanoidRootPart.Anchored = true`**; all limbs and armor are `Anchored = false`, `Massless = true`, `CanCollide = false` with `WeldConstraint`.
  3. Cleared geometric placeholder swords from back attachments so real 3D mesh swords snap cleanly onto `Torso.BodyBackAttachment`.

### ADR-049 — Unified MasterHUDGui & TopBar Inset Clearance
* **Date:** 2026-09-08
* **Status:** Accepted
* **Context:** 6 standalone legacy HUDs created screen clutter, and `TopLeftDutyTracker` overlapped the Roblox CoreGui topbar.
* **Decision:**
  1. Consolidated all persistent HUD elements into **`StarterGui.MasterHUDGui`**.
  2. Shifted `TopLeftDutyTracker` down by $+56\text{px}$ ($Y = 0.075$) to clear the Roblox topbar pill.
  3. Set `DisplayOrder = 50` and centered facility modals at $Y = 0.38$ with a compact $0.54\text{–}0.58$ height, giving $190\text{px}$ of clearance above the bottom HUD.

  ### ADR-050 — Server-Authoritative Flying Sword Flight Mode & Aerodynamic Hover Physics
* **Date:** 2026-09-09
* **Status:** Accepted & Implemented
* **Context:** Cultivators required an authentic Xianxia sword-riding traversal mechanic (御剑飞行) that felt smooth, responsive, and did not drag on terrain or tumble upon colliding with buildings.
* **Decision:**
  1. Wired `V` key toggle across `InputController.luau`, `CombatStateManager.luau`, and `WeaponManager.luau`.
  2. Mounted `ReplicatedStorage.FlyingSword` to character's `Left Leg` using `LeftFootAttachment` and `FeetAttachment` via synchronized `RigidConstraint` and `AnimationConstraint`.
  3. Enforced upright posture via an `AlignOrientation` (`MaxTorque = 10,000,000`, `Responsiveness = 35`) with `FLIGHT_YAW_OFFSET = 90`, locking the sword tip forward with the camera view and eliminating 360° spinning or collision tumbling.
  4. Implemented downward raycast **Ground Clearance Cushion** (`MIN_HOVER_ALTITUDE = 6.5 studs`) with upward spring force, keeping the sword hovering ~3.5 studs above ground/grass without clipping.
  5. Implemented forward **Proximity Obstacle Cushion** (`MIN_OBSTACLE_BUFFER = 8.5 studs`), eliminating inward velocity on solid models/cliffs to enable smooth wall-sliding.
  6. Flight velocity locked at **75 studs/s**, with Spacebar ascend (+42 studs/s), Ctrl/C descend (-42 studs/s), and gentle idle descent (-2.5 studs/s).
* **Consequences:** Created an authentic, fluid sword-flight experience that is physically stable across all terrain types.

### ADR-051 — Combat Weapon vs. Flying Sword Lifecycle Isolation & Cloud DataStore Sanitization
* **Date:** 2026-09-09
* **Status:** Accepted & Implemented
* **Context:** A previous test script cloned the Flying Sword mesh into `ReplicatedStorage.Weapons.MortalIronJian`. When auto-save ran during flight testing, `EquippedWeapon = "FlyingSword"` was written to production DataStore, causing players to spawn in the live published game holding the Flying Sword horizontally by its middle gem.
* **Decision:**
  1. **Strict Folder Isolation:** Combat weapons are sourced exclusively from `ReplicatedStorage.Weapons` (`VoidStarCleaverDao`, `MortalIronJian`, etc.). `ReplicatedStorage.FlyingSword` is exclusively reserved for the `V` key flight mount.
  2. **Cloud Data Sanitization:** `PlayerDataManager.luau` sanitizes `loadedData.EquippedWeapon` on join—if it equals `"FlyingSword"`, it is automatically overwritten with `"VoidStarCleaverDao"` (developer) or `"MortalIronJian"` (regular players).
  3. `SaveData(player)` strictly prohibits saving `"FlyingSword"` to cloud DataStores.
  4. Restored genuine `MortalIronJian` mesh from `ReplicatedStorage["Old swords (IGNORE)"]`.
* **Consequences:** Permanently eliminated cloud weapon corruption and cleanly separated combat weapons from flight mounts.

### ADR-052 — High-Impact Locomotion, Anti-Trip Elevation Dash & Movement Sound Governor
* **Date:** 2026-09-09
* **Status:** Accepted & Implemented
* **Context:** Sprinting at 35 studs/s felt sluggish, dashing while running tripped R6 characters into forward flips due to ground friction, and Roblox character audio looped footstep sounds during flight collisions and jump-spamming.
* **Decision:**
  1. Increased open-world sprint speed from 35 to **44 studs/s** (Arena: 34 studs/s).
  2. Added harmonic step-synced head-bobbing ($\pm 0.08$ studs vertical bounce, lateral sway, $\pm 0.75^\circ$ roll tilt) and dynamic sprint FOV ($70^\circ \rightarrow 76^\circ$).
  3. **Anti-Trip Qi Dash Engine:** Dashing at 150 studs/s lifts the character $+1.2\text{ studs}$, applies temporary `Freefall` state to disable ground friction, and locks upright posture with an `AlignOrientation` (`MaxTorque = 10,000,000`), completely eliminating tripping and faceplants.
  4. **Movement Sound Governor:** Bound a continuous listener in `AnimationController.luau` and `Animate.client.luau` that mutes `Running` audio and stops ground tracks whenever `IsFlying == true` or `FloorMaterial == Air`.
* **Consequences:** Dramatic improvement in character movement feel, responsiveness, and auditory polish.

### ADR-053 — 9-Slice Textured Panel Standard & Dedicated Cultivator Profile GUI
* **Date:** 2026-09-09
* **Status:** Accepted & Implemented
* **Context:** Procedural flat vector UI borders looked inconsistent with authored Xianxia art assets, and players had no in-game window to inspect their Blacksmith refinements, realm multipliers, or weapon damage.
* **Decision:**
  1. Adopted **`rbxassetid://115367926298823`** as the universal 9-slice background panel asset (`SliceCenter = Rect.new(146, 120, 878, 120)`, `SliceScale = 1`) across `SectPavilionGui`, `BlacksmithGui`, `TeaHouseGui`, `AlchemyGui`, and `StarterGuideGui`.
  2. Enforced `IgnoreGuiInset = true` on all facility modals for 100% full-screen backdrop coverage.
  3. Built and deployed **`CharacterStatsGui`** ($0.5, 0.5$ dead-center) with 4 tabs (`1. DAO REALM`, `2. COMBAT STATS`, `3. SPIRIT WEAPON`, `4. 3D AVATAR`) bound to keybind **`P`**.
  4. Enforced typography standard: `Enum.Font.Bangers` for headers and category badges; `Fondamento` for all stat descriptions and lore values.
* **Consequences:** Unified the visual identity of all game menus with high-contrast, scalable, calligraphic Xianxia presentation.

### ADR-054 — Q Skill: Purple Sword Tempest Dual-Hitbox Architecture
* **Date:** 2026-09-11
* **Status:** Accepted & Implemented
* **Context:** The original Q skill (Sword Tempest / Volcanic Tempest) was a static radial tick that felt disconnected from the cultivator's sword motion and lacked forward pressure.
* **Decision:**
  1. Redesigned Q into a dual-hitbox projectile attack: point-blank melee slice ($0\text{--}7\text{ studs}$) + 3 consecutive traveling purple sawblade waves ($16\text{-stud}$ width, $36\text{-stud}$ fixed distance, $70\text{ studs/s}$).
  2. Aligned release height strictly to mid-torso ($Y = -0.40\text{ studs}$ relative to HRP) matching the sword blade arc.
  3. Integrated client-side Qi pre-check ($15\%$ Max Qi): prevents playing animations or audio if energy is insufficient.
  4. Assigned Animation ID `rbxassetid://111677132360566`, release SFX `rbxassetid://109735549169421`, and hit SFX `rbxassetid://135448977656112`.
* **Rationale:** Provides high-impact ranged zoning with physical martial arts weight while preserving server authority.

### ADR-055 — F Skill: 100-Slash Flash Domain Ultimate & Phase-Dash Architecture
* **Date:** 2026-09-11
* **Status:** Accepted & Implemented
* **Context:** The legacy F skill ("Falling Sky Slam") lacked visual grandeur and mechanical identity as a high-tier sword technique.
* **Decision:**
  1. Replaced F with the "100-Slash Flash Domain" ultimate skill.
  2. Implemented hold-to-charge stance using `rbxassetid://84905841522350` (Looped = `true`, speed frozen at `0` on charge frame), locking the cultivator in a braced pose until release.
  3. Release executes a $28\text{-stud}$ flash-step dash at $150\text{ studs/s}$ with purple silhouette afterimages.
  4. Obstacle raycasting ignores Humanoid models (allowing the cultivator to phase straight through enemies) while strictly stopping $2\text{ studs}$ in front of Trees, Rocks, Walls, and Terrain.
  5. At the $14\text{-stud}$ midpoint, executes a $0.05\text{s}$ anime micro-hitstop, triggers mid-air slash `rbxassetid://111677132360566`, and detonates the $36\text{-stud}$ purple 100-slash sphere (`UltimateSkill` with `Wind1` and `Slashes1`).
  6. Assigned dedicated Ultimate SFX `rbxassetid://18781431019` (volume 2.8 in 3D).
* **Rationale:** Delivers the authentic anime flash-step sword fantasy where the swordsman cuts through the enemy pack and the sphere of slashes detonates behind them.

### ADR-056 — Permanent Anti-Trip Ground Physics Standard
* **Date:** 2026-09-11
* **Status:** Accepted & Implemented
* **Context:** Re-enabling `FallingDown` and `Ragdoll` humanoid states or applying sudden velocity changes on running R6 characters caused severe physics torque, causing characters to trip and faceplant into the ground.
* **Decision:**
  1. Permanently disabled `HumanoidStateType.FallingDown` and `Ragdoll` across all character lifecycles.
  2. Prohibited artificial CFrame ground-snapping post-dash; ground alignment is handled naturally by the Humanoid physics engine.
  3. When charging skills mid-sprint, horizontal velocity is arrested immediately (`Vector3.new(0, Y, 0)`), preventing forward momentum from tripping the character.
  4. Implemented automatic sprint state memory: pre-skill sprint state is recorded and automatically restored upon recovery without requiring player key re-presses.
* **Rationale:** Eliminates unintended ragdolls and stumbling on stepped terrain and during fast combat locomotion.

### ADR-057 — Client-Authoritative Combat Movement with Server Hitbox Validation
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Running high-speed physics movers (`LinearVelocity`) on the server for client-owned character assemblies caused violent rubber-banding and physics desync during the `F` Ultimate.
* **Decision:**
  1. Standardized all character locomotion skills (`Shift` Dash and `F` Ultimate) to client-authoritative execution matching the proven `AnimationController.PerformDash` pattern.
  2. The client applies `LinearVelocity` with `AlignOrientation` (`MaxTorque = 10,000,000`), $+2.2\text{ studs}$ elevation lift, and temporary `Freefall` state.
  3. The server retains 100% authority over hitboxes, damage, posture drain, Qi consumption, and cooldown gates.
  4. Server-side `LinearVelocity` and forced `CFrame` ground snapping on player characters are permanently prohibited.
* **Consequences:** Completely eliminated rubber-banding, snapping backwards, and sideways tripping during combat mobility skills.

### ADR-058 — Instant-Trigger Ultimate Skill Pipeline
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Hold-to-charge mechanics on `F` introduced input-release race conditions, server recovery lockout drops, and movement lockouts when releasing early.
* **Decision:**
  1. Converted `F` Ultimate to an instant single-click activation (`TriggerUltimateF`).
  2. Retained the charge stance animation as a rapid $0.12\text{s}$ airborne windup that smoothly chains into the flash-step forward dash.
  3. Purged `StartChargeF` remote listeners and hold-detection loops.
* **Consequences:** Delivers snappy, responsive ultimate skill execution with zero input-delay dropped packets.

### ADR-059 — Dynamic Weapon-Attuned Combat VFX Architecture
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Hardcoded purple particle colors on `Q` and `F` clashed with the 8 distinct elemental sword tiers.
* **Decision:**
  1. Implemented `WeaponVFXPalette` in `ItemConfig.luau` and `ItemConfig.GetWeaponPalette(weaponId)` defining primary colors, secondary tones, glow colors, and multi-stop particle gradients across all 8 sword tiers.
  2. Replicated `character:SetAttribute("EquippedWeapon", weaponId)` in `WeaponManager.luau`.
  3. Client controllers dynamically query this attribute, automatically attuning `Q` sawblade waves, `F` 100-slash spheres, dash afterimage trails, and Shunpo ghosts to the equipped blade.
  4. Removed point light sources beneath skill projectiles to maintain clean, high-performance particle aesthetics.
* **Consequences:** Greatly elevates visual weapon prestige and player progression feedback.

### ADR-060 — Unified Bottom-Left HUD Column Standard
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Vitals bars on `BottomCenterFrame` clashed with hotbars, currency in the top-right crowded mobile topbars, and nav buttons under the hotbar were difficult to click.
* **Decision:**
  1. Consolidated vitals, currencies, and navigation into a unified $340\text{px}$ column anchored at the bottom-left corner of the screen:
     - **Top ($Y = -206$):** 2×2 Navigation Tray (`BottomNavTray`: Arena, Pouch, Guide, Mission).
     - **Middle ($Y = -164$):** 2-badge side-by-side Currency Bar (`TopRightCurrencyFrame`: Spirit Stones & CP).
     - **Bottom ($Y = -32$):** 3 equal-length $340\text{px} \times 14\text{px}$ bars (`VitalsContainer`: HP, QI, INT).
  2. Permanently prohibited `UICorner` across this cluster for a sharp, sleek ARPG aesthetic.
  3. Separated text indicators above each bar: Left title (`HP`, `QI`, `INT`) and Right dynamic real numbers (`2.02M / 2.02M`) in `Bangers` font with black outlines.
* **Consequences:** Created an ergonomic, modern ARPG HUD layout with high contrast and zero central screen clutter.

### ADR-061 — Master Xianxia UI Color & Gradient Specification
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Modal windows using dark bamboo image frames (`115367926298823`) distorted across screen sizes and lacked modern color contrast.
* **Decision:**
  1. Replaced 9-slice image frames with standard `Frame`s styled under the Master Xianxia UI Color System:
     - **Main Frame Base:** Celestial Midnight Navy vertical gradient (`#141F36` $\rightarrow$ `#1E2D4A` $\rightarrow$ `#0B111E`).
     - **Sub-Panels / Cards:** Twilight Slate 45° diagonal gradient (`#121B2D` $\rightarrow$ `#18243C` $\rightarrow$ `#0E1524`).
     - **Prestige / Titles:** Solar Dao Gold vertical gradient (`#FFFBEB` $\rightarrow$ `#FDE047` $\rightarrow$ `#EAB308`).
     - **Interactive / Badges:** Celestial Spirit Cyan vertical gradient (`#22D3EE` $\rightarrow$ `#0EA5E9` $\rightarrow$ `#0369A1`).
     - **Danger / Close:** Cinnabar Crimson vertical gradient (`#FB7185` $\rightarrow$ `#E11D48` $\rightarrow$ `#9F1239`).
     - **Outlines:** Razor-thin solid black `UIStroke` (`1.0px` to `1.2px`).
  2. Isolated button text into inner `TextLabel`s (`TextColor3 = 255, 255, 255` with black stroke) so button `UIGradient`s do not bleed into the text.
* **Consequences:** Unified the visual identity of all game menus with crisp, scalable, high-contrast presentation.

### ADR-062 — R6 Humanoid Mob & Boss Standardization (1-Handed Sword Doctrine)
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Solo-developer budget and time constraints make custom 3D beast rigging and procedural animation math a high-risk trap.
* **Decision:**
  1. Standardized 100% of zone mobs, elites, and world bosses to the **Roblox R6 Humanoid rig** wielding **1-handed swords**.
  2. All mobs share the player's martial walk, sprint run, and 5-hit M1 broadsword combo animations from `AnimationConfig.luau`.
  3. Visual diversity is achieved strictly through scale (`0.92x` to `1.45x`), color palettes, clothing, accessories, and sword auras.
  4. Physical integrity rule: All cosmetic accessories must have `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, and `Massless = true`. Both legs and torso must have `CanCollide = true` to preserve ground traction.
  5. Retired `Boss_ElderYan`; established **`Boss_FallenSwordGenius` ("Fallen Sword Genius - Mo Chen")** as the Zone 1 World Boss.
* **Consequences:** Guaranteed 100% animation compatibility, zero ground-jamming bugs, and rapid enemy authoring velocity.

### ADR-063 — Smart Teammate Flocking & Boids Spatial Separation AI
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Multiple mobs chasing a player moved in a straight line toward the exact same coordinate, colliding, stacking inside each other, and moving unnaturally.
* **Decision:**
  1. Implemented angular surround slots: When $N$ mobs target a player, each mob calculates an equidistant angular flank position around the player at a $3.5\text{--}6.0\text{ stud}$ radius.
  2. Implemented Boids lateral repulsion: Mobs within $5.5\text{ studs}$ of teammates apply an inverse-distance repulsion vector pushing them into open space.
* **Consequences:** Mobs fan out and encircle players naturally like a disciplined martial arts squad.

### ADR-064 — Persistent HUD Lifecycle & Zero-Delay Health Revival Architecture
* **Date:** September 2026
* **Status:** Accepted & Implemented
* **Context:** Default `ResetOnSpawn = true` destroyed the HUD on death, leaving client controllers pointing to dead instances and causing health bars to freeze at `100/100` or `0 HP`. Event listeners on `LocalPlayer` created zombie closures that overwrote live health with dead character stats.
* **Decision:**
  1. Set `MasterHUDGui.ResetOnSpawn = false` across client and Studio.
  2. Implemented a strict `characterConnections` garbage collector in `SkillBarController.luau` that disconnects all previous listeners immediately upon respawn.
  3. `checkVitals()` always resolves `LocalPlayer.Character.Humanoid.Health` directly rather than closing over dead variables.
  4. `CultivationManager.luau` removed the `task.wait(0.2)` delay on `CharacterAdded`: Synchronously sets `MaxHealth` and `Health` to full realm values and replenishes Qi to 100% on the exact frame of spawn.
* **Consequences:** Guaranteed full health and Qi restoration across unlimited deaths with zero GUI freezing.

### ADR-065: Strict Phase Verification & Server Command Bar Hot-Patch Protocol
* **Date:** 2026-09-17 (backfilled from Session Digest #2026-09-17)
* **Status:** Accepted
* **Context:** Blindly applying full script rewrites led to subtle regressions, nil method crashes, and broken state machines.
* **Decision:** Every development phase strictly requires raw URL fetches followed by a live Server Command Bar hot-patch test before full file code is provided and committed.

### ADR-066: MobAIManager Preservation & Phase Deferral
* **Date:** 2026-09-17 (backfilled from Session Digest #2026-09-17)
* **Status:** Accepted
* **Context:** `MobAIManager.luau` contained a 727-line animation and AI state machine that was highly susceptible to regression.
* **Decision:** Keep `MobAIManager.luau` 100% untouched during cultivation and bloodline phases. Combat hardening, ragdoll tripping, flight/meditation combat lockouts, and fall damage are deferred to dedicated hardening passes to avoid scope creep.

### ADR-067: Celestial Flash-Step Instant Blink Traversal
* **Date:** 2026-09-17 (backfilled from Session Digest #2026-09-17)
* **Status:** Accepted
* **Context:** High-speed physics dashes on Skill F interacted poorly with terrain and caused tripping/ragdoll.
* **Decision:** Re-engineered Skill F from a physics velocity dash into a 28-stud instant Celestial Flash-Step / Blink slash, ensuring clean repositioning without tripping physics.

### ADR-068: Bloodline Meridian Vault Architecture, Gacha Pity & Floating Relic Standard
* **Date:** 2026-09-18 (backfilled from Session Digest #1)
* **Status:** Accepted
* **Context:** Bloodline mechanics required transparent pity systems, backward-compatible persistence, and visual prestige that avoided clipping with character clothing.
* **Decision:**
  1. Implemented Bloodline Meridian Vault in `PlayerDataManager.luau` (V3 schema) with 30-pull Legendary and 100-pull Mythic pity guarantees.
  2. Substituted body-clinging 3D relics (bracers, chestplates) with floating companion orbs/halos across all bloodline lineages (`ARTIFACT_OFFSETS`).
  3. Gated gacha interactions behind Bloodline Altar ProximityPrompt (`E`). Breakthrough remains bound to `[B]`. Feature guide bound to `[H]` (`CodexGui`).

### ADR-069: Universal Sharp Rectangular Xianxia UI Standard (Zero UICorner Mandate)
* **Date:** 2026-09-18 & 2026-09-19 (backfilled from Session Digests #1 & #3)
* **Status:** Accepted
* **Context:** Rounded corners (`UICorner`) eroded the traditional Xianxia martial plaque aesthetic and created visual inconsistency across modals.
* **Decision:**
  1. Strictly prohibited `UICorner` across all GUI elements (frames, buttons, pills, slots) to enforce a sharp, rectangular Xianxia plaque visual identity.
  2. Standardized UI containers on dark celestial slate backgrounds (`#111827` / `#1C2638`), multi-stop subtle gradients, zero outer frame borders, and responsive text sizing (`TextScaled` + `UITextSizeConstraint` + `UIPadding`).
  3. All UI hierarchies must reside directly in `StarterGui` via Edit Mode CMD scripts; runtime `Instance.new` UI creation in client scripts is prohibited.

### ADR-070: Bloodline Roster Expansion & Element-Attuned Meditation Aura Decoupling
* **Date:** 2026-09-18 (backfilled from Session Digest #1)
* **Status:** Accepted
* **Context:** A single Mythic bloodline created a progression bottleneck, and tying meditation aura colors to Cultivation Realm tiers ignored player lineage flavor.
* **Decision:**
  1. Expanded bloodlines from 10 to 12 by adding `NineNetherSovereign` (Mythic #2) and `GlacialPhoenixMeridian` (Legendary #4).
  2. Decoupled meditation aura coloring from Cultivation Realms; dynamic aura cloning (`ReplicatedStorage.AuraTemplates`) is driven by the active Bloodline element via a 12-palette `ColorSequence` dictionary.

### ADR-071: ASCEND Monkey Protocol for Live Studio Command Bar Verification
* **Date:** 2026-09-19 (backfilled from Session Digest #2026-09-19A)
* **Status:** Accepted
* **Context:** Manual playtesting failed to detect latent network ownership errors, collision matrix bugs, and state machine stalls.
* **Decision:** Adopted the ASCEND Monkey Protocol—a live Studio Command Bar verification suite that executes automated assertions across server subsystems (collision groups, mob ownership, anti-ragdoll states, and promotion queues) before code is accepted.

### ADR-072: Damage Number Arcade Font & Clutter Purge
* **Date:** 2026-09-19 (backfilled from Session Digest #2026-09-19A)
* **Status:** Accepted
* **Context:** Floating text popups ("CRIT!", "PARRY!", Intent badges) cluttered the screen during intense combat.
* **Decision:** Standardized damage numbers to "Press Start 2P" / `Enum.Font.Arcade` and restricted popups to pure numeric values only, completely removing text popups.

### ADR-073: Zero-Knockback Skill Q & Weighted Locomotion Sluggish Glide
* **Date:** 2026-09-19 (backfilled from Session Digest #2026-09-19A)
* **Status:** Accepted
* **Context:** Skill Q knockback launched enemies out of melee range, and high-cadence twitchy movement felt ungrounded.
* **Decision:**
  1. Zeroed knockback on Skill Q (`Vector3.zero`) to slice enemies in place.
  2. Reverted locomotion to a weighted, sluggish glide (0.70x playback, upper body holding idle pose while legs run) with committed, slower M1 slashes.
  3. Re-enabled 4-way camera-relative dash with Shunpo vanish/reappear visual effects.

### ADR-074: Sacred Weapon Market Exclusion Policy
* **Date:** 2026-09-19 (backfilled from Session Digest #2026-09-19B)
* **Status:** Accepted
* **Context:** Selling swords at the general sect merchant diluted their lore identity as sacred spiritual artifacts.
* **Decision:** Permanently purged all sword/weapon buying and selling from `SectMerchantMarketGui`. Flying swords and spirit blades are acquired exclusively through Sect progression, boss drops, and the Sacred Sword Altar.

### ADR-075: Dynamic Realm Flight Speed Scaling & Qi Drain Synchronization
* **Date:** 2026-09-19 (backfilled from Session Digest #2026-09-19B)
* **Status:** Accepted
* **Context:** Static flight speed ignored realm progression, and concurrent passive Qi recovery caused flight energy to oscillate.
* **Decision:**
  1. Scaled flight velocity dynamically with cultivation realm (Foundation Establishment: 48 studs/s).
  2. Flight imposes a continuous 25 Qi/s drain and pauses passive Qi recovery. Reaching 0 Qi or taking damage in combat forces an immediate dismount.

### ADR-076: Pure Humanoid R6 Cultivator Roster & Complete Beast Rig Purge
* **Date:** 2026-09-20 (backfilled from Session Digest #2026-09-20)
* **Status:** Accepted
* **Context:** Custom 3D quadruped/beast rigs caused severe animation overhead, tripping bugs, and network ownership crashes.
* **Decision:**
  1. Permanently purged all beast mob rigs (`DemonWolf`, `IronhideBoar`, `SilverbackFrostApe`, `VoidChasmChimera`, `AbyssalDemonSovereign`).
  2. Standardized 100% of zone enemies to 10 Humanoid R6 Cultivators using standard R6 joints, `Motor6D` `RightGrip`, and shared animation tables.
  3. Mobs utilize `SPAWNER_ALIAS_MAP` and Boids spatial separation. Graded beast cores remain as item drops representing wilderness alchemy ingredients.

### ADR-077: 11-Phase Production Roadmap Restructuring & Codebase Hardening Priority
* **Date:** 2026-09-20 (backfilled from Session Digest #2026-09-20)
* **Status:** Accepted
* **Context:** Unsynced phase numbering across historical sessions caused architectural drift and compounding technical debt.
* **Decision:**
  1. Reset phase numbering to a clean 11-Phase Priority Roadmap.
  2. Formally marked Phase 1 (Core Foundations) closed following 5/5 verification tests.
  3. Elevated Phase 2 (Code cleanup, memory leak audit, circular dependency decoupling, strict typing) to active priority before continuing feature additions.
  4. Deferred live M1/running cadence tuning and ribbon trails to Phase 3.

### ADR-078: Network Remote Pruning & Strict Typing Standard
* **Date:** 2026-09-20 (backfilled from Session Digest #2026-09-20)
* **Status:** Accepted
* **Context:** 16 legacy declared remotes had zero references across 87 project scripts, inflating network surface area.
* **Decision:** Pruned all 16 unused remotes from `RemoteEvents.luau`. Strictly declared and instantiated only the 16 active remotes using `--!strict` Luau typing and discriminated union payloads.