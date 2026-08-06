# CHANGELOG

All notable changes, system implementations, and architectural updates to the ASCEND Roblox project are documented in this file.

---

## [Unreleased] - 2026-08-06 — Pure Sword Cultivator Pivot & 45-Stage High-Number Scale

### Added
- **Pure "Sword Cultivator" (剑修) Architectural Shift**:
  - Pivoted core combat paradigm from multi-weapon archetype switching to **Pure Sword Cultivation**.
  - Streamlined weapon attachment pipeline (`WeaponManager.luau`) to focus 100% on **Flying Swords (飞剑)** attached to `RightGripAttachment` (hand) and `BodyBackAttachment` (sheathed/floating back-array).
  - Designed the **Dynamic Jade Scripture / Sword Art Scroll System**: Skills (`Q`, `E`, `R`, `Shift`, `F`) are equipped via collectible, craftable, and upgradeable **Sword Art Scrolls** rather than rigid weapon-locked classes.
  - Implemented **Sword Art Mastery Levels**: Using skills in combat earns Mastery XP (Rank 1 $\rightarrow$ Rank 10), increasing damage, reducing cooldowns, enlarging particle aura sizes, and unlocking floating back-sword slots.
- **4 Paired Mythic 3D Sets & Floating Back-Crest Arrays**:
  - Successfully generated, textured, and verified 4 Paired Mythic Sets in Meshy AI (3D Sword + Matching 3D Floating 5-Blade Back-Crest Array):
    1. **`Heavenly Void Set`** (Cosmic / Space / Telekinesis) — Dark purple steel, glowing white runes, gold wing guard, 3D floating purple diamond crystals. (Imported in Roblox Studio Workspace & `ReplicatedStorage` ✅).
    2. **`Sun-Slayer Crimson Set`** (Magma / Fire / Heavy Cleave) — Volcanic magma glass, glowing orange lava veins, golden lion head guard.
    3. **`Nine-Dragon Sovereign Set`** (Jade / Wind / Dragon) — Translucent cyan-emerald jade, glowing gold runes, coiled gold dragon guard.
    4. **`Frost-Dragon Flared Set`** (Ice / Frost / Thunder) — Ice-cyan crystal jade, wide flared ricasso throat, silver/gold winged dragon guard.
- **45-Stage High-Number Dopamine Progression (50B Cap)**:
  - Re-architected `CultivationConfig.luau` and `CultivationManager.luau` into 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*), each containing **9 Sub-Stage Orders** (45 Tiers total).
  - Scaled Qi capacity from $10,000$ Qi up to **$50,000,000,000$ (50 Billion)** at Spirit Severing Order 9.
  - Scaled player `MaxHealth` proportionally alongside Qi ($500 \rightarrow 25,000,000$ HP), maintaining combat balance and preventing glass-cannon one-shots.
  - Added **Natural Qi Carryover**: Breakthroughs preserve existing Qi reserves rather than wiping to $0$.
  - Added **Dual-Mode Fast Qi Regeneration**: Meditating (`Hotkey G`) when depleted restores Qi $3.5\times$ faster than deep breakthrough cultivation.
  - Added high-number suffix formatter helper (`FormatNumber`) converting values to clean UI readouts (`15.0K`, `2.50M`, `8.00B`, `50.0B`).
- **Sharp Dark Obsidian HUD Redesign ("Same Skin, Different Body")**:
  - Completely redesigned `HUDController.luau` to match the exact visual style, `FredokaOne` typography, and sharp 90° corners (0px border-radius) of the Spirit Pouch and Alchemy Cauldron panels.
  - Unified HP meter, Qi progress meter, action prompts, and skill hotbar into a single, clean, non-overlapping bottom-center dock (`#0C0E14` background, `#121520` cards, `#1E2330` 1.5px border stroke).
  - Enforced pure crisp white text (`#F1F5F9`) for all Realm / Order titles.
  - Stripped icon emojis from action prompts (`PRESS 'B' FOR MINOR BREAKTHROUGH`).
- **Overhead UI Cleanup & Local Player Reduction**:
  - Updated `OverheadUIController.luau` to skip attaching 3D BillboardGuis to the local player's own character, eliminating local screen clutter while retaining 3D health/realm indicators above other players, NPCs, and training dummies.
- **Automatic Weapon Unequip & Serene Levitating Meditation**:
  - Updated `WeaponManager.luau` with `SetWeaponVisibility(player, visible)` to automatically hide equipped 3D weapon models during meditation and restore them upon exiting.
  - Fixed R15 character physics vibration during meditation by setting `Humanoid.PlatformStand = true` while anchored.
  - Added slow, 3.0-second celestial sine wave levitation loop ($0.5$ studs up and down) in `CultivationManager.luau`.
- **DataStore Persistence Engine (Phase 6.1 Objective 1)**:
  - Created `PlayerDataManager.luau` managing server-authoritative loading and saving of player Realm tier, Order, Current Qi, Inventory slots, Equipped Weapon, and Sect.
  - Implemented 3-attempt `pcall` retry wrapper, fallback defaults, 5-minute auto-save loop, and `game:BindToClose()` server shutdown handler.

---

## [Unreleased] - Phase 2, Phase 3, Phase 4, & Phase 5 Task 5.1 & Task 5.2 Completion

### Added
- **UI Assets & Rarity System**:
  - `ReplicatedStorage/Shared/Configs/UIAssets.luau`: Central registry populated with live uploaded Roblox Asset IDs.
  - `ReplicatedStorage/Shared/Configs/RarityConfig.luau`: Tier colors and hex mappings for Mortal through Immortal rarities.
- **HUD & Inventory UI**:
  - `HUDGui` with keybind badges, sweeping dark cooldown masks with live decimal timer text (`CooldownText`), reticle, boss health bar (`hud_boss_frame`), and tribulation bar (`hud_tribulation_bar`).
  - `InventoryGui` modal with dynamic `UIStroke` rarity borders.
- **Server-Authoritative Networking & State Engine**:
  - `RemoteEvents.luau`: Central remote factory (`CombatAction`, `UpdateSkillState`, `SyncCooldown`, `UpdateCultivation`, `AlchemyAction`, `InventoryAction`). Updated `RemoteEvents.Init()` to pre-create remotes.
  - `CombatStateManager.luau`: Server-authoritative state tracker (*Idle, Casting, Cooldown, Stunned, Qi Deviation*) with server-side cooldown validation.
  - `InputController.luau`: Mouse 3D targeting payloads (`mouse.Hit.Position` & `AimDirection`) with Classical ARPG keybind scheme (LMB, F, Q, E, R, Shift, 1, 2, 3, G, B).
- **Cultivation Realm & Qi Meditation Engine**:
  - `CultivationConfig.luau`: Config for Xianxia Realms.
  - `CultivationManager.luau`: Server-authoritative Qi absorption, meditation state (**Hotkey G**), steady hover, body wrap, front camera, breakthroughs (**Hotkey B**), and health stat scaling.
- **Alchemy & Spirit Pill Crafting System (Task 5.2)**:
  - `AlchemyConfig.luau` & `AlchemyManager.luau`: Furnace crafting engine with success rate rolls, ingredient inventory validation, and pill consumption effects.
- **Overhead Health & Cultivation Title Display**:
  - `OverheadUIController.luau`: Dynamic BillboardGuis above heads with real-time health bar fill updates and cultivation titles.
- **3D Inventory Item Engine**:
  - `InventoryConfig.luau` & `InventoryController.luau`: 3D ViewportFrame placeholders, Dark Obsidian palette, FredokaOne font, sharp 90° corners, and client-server sync.

### Changed
- Shifted heavy attack from RMB to **`F` key**, leaving RMB 100% free for camera rotation.
- Disabled Roblox default `Backpack` CoreGui.
- Removed auto-aim character body spinning on M1 attacks.