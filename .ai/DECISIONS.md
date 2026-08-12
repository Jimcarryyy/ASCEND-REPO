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