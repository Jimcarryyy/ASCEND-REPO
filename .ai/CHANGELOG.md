# CHANGELOG

## [Unreleased] - Phase 2, Phase 3, Phase 4, & Phase 5 Task 5.1 & Task 5.2 Completion

### Added
- **UI Assets & Rarity System**:
  - `ReplicatedStorage/Shared/Configs/UIAssets.luau`: Central registry populated with live uploaded Roblox Asset IDs across HUD, Panels, Weapons, Skills, Currencies, and Status Effects.
  - `ReplicatedStorage/Shared/Configs/RarityConfig.luau`: Tier colors and hex mappings for Mortal through Immortal rarities.
- **HUD & Inventory UI**:
  - `HUDGui` with keybind badges, sweeping dark cooldown masks with live decimal timer text (`CooldownText`), reticle, boss health bar (`hud_boss_frame`), and tribulation bar (`hud_tribulation_bar`).
  - `InventoryGui` modal with dynamic `UIStroke` rarity borders.
- **Server-Authoritative Networking & State Engine**:
  - `RemoteEvents.luau`: Central remote factory (`CombatAction`, `UpdateSkillState`, `SyncCooldown`, `UpdateCultivation`, `AlchemyAction`, `InventoryAction`). Updated `RemoteEvents.Init()` to automatically pre-create all registered remote events on server startup, eliminating client wait timeouts.
  - `CombatStateManager.luau`: Server-authoritative state tracker (*Idle, Casting, Cooldown, Stunned, Qi Deviation*) with server-side cooldown validation.
  - `InputController.luau`: Mouse 3D targeting payloads (`mouse.Hit.Position` & `AimDirection`) with Classical ARPG keybind scheme (LMB, F, Q, E, R, Shift, 1, 2, 3, G, B).
- **Multi-Weapon Combat System**:
  - `FlyingSwordConfig.luau`, `SpearConfig.luau`, `GauntletConfig.luau`: Full skill and combo definitions for 3 distinct weapon styles.
  - `HitboxManager.luau`: Server spatial box hitboxes (`Workspace:GetPartBoundsInBox`), server damage, and physics knockbacks.
  - `FlyingSwordServer.luau`, `SpearServer.luau`, `GauntletServer.luau`: Weapon combat handlers.
  - `WeaponManager.luau`: Live weapon swapping (Hotkeys `1`, `2`, `3`), Motor6D attachment to `RightGripAttachment`, `Tool.Grip` compatibility, and procedural Qi placeholders (Cyan Sword, Gold Spear, Dual Cyan Qi Gauntlets).
- **Combat Juice, VFX & Audio**:
  - `CombatVFXController.luau`: 3D floating damage numbers, directional camera shake, impact particles, crisp white 3D weapon slash trails (`Trail`), swing SFX, hit impact SFX, dynamic fallback weapon trails for models without pre-built trails, and Shift Windstep Dash motion trails on `HumanoidRootPart`.
  - `AnimationController.luau`: R15 keyframe attack animations, action priority layering, WalkSpeed action dampening, physical Windstep dodge dash (`Shift`), calibrated meditation camera (`-13.5` studs front view, elevated `1.8` studs), and serene floating animation playback speed (`0.65`).
- **Cultivation Realm & Qi Meditation Engine**:
  - `CultivationConfig.luau`: Config for 5 Xianxia Realms (*Qi Condensation → Foundation Establishment → Golden Core → Nascent Soul → Heavenly Tribulation*).
  - `CultivationManager.luau`: Server-authoritative Qi absorption, meditation state (**Hotkey G**), steady hover, lightweight ethereal body wrap (`Highlight` at 95% fill transparency), cinematic front-view camera, realm breakthroughs (**Hotkey B**), and health stat scaling.
  - `CultivationController.luau`: Dedicated client controller handling meditation floating motion and wide camera framing.
- **Alchemy & Spirit Pill Crafting System (Task 5.2)**:
  - `AlchemyConfig.luau`: Configuration repository for Xianxia spirit pill recipes (`pill_qi_gathering`, `pill_healing_dan`, `pill_physique_tempering`, `pill_breakthrough`) and materials (`mat_spirit_herb`, `mat_demon_core`, `mat_spirit_water`). Embedded safe icon helper `getIcon()` to prevent nil path indexing.
  - `AlchemyManager.luau`: Server-authoritative furnace crafting engine with success rate probability rolls, ingredient inventory validation, and pill consumption effects (instant Qi, heal-over-time, gather rate boosts, stat buffs). Included `EnsurePlayerData()` to auto-populate initial starter materials.
- **Overhead Health & Cultivation Title Display**:
  - `OverheadUIController.luau`: Client UI controller creating dynamic BillboardGuis above players and workspace dummies with real-time health bar fill updates, color transitions (Green/Yellow/Red), and cultivation realm titles.
- **3D Inventory Item & Placeholder Engine**:
  - `InventoryConfig.luau`: Metadata schema and 3D item placeholder definitions for Herbs, Cores, Pills, and Weapons.
  - `InventoryController.luau`: Client controller rendering 3D ViewportFrame placeholders and handling server inventory synchronization.

### Changed
- Shifted heavy attack from RMB to **`F` key**, leaving RMB 100% free for camera rotation.
- Disabled Roblox default `Backpack` CoreGui to prevent inventory hotbar overlap.
- Removed auto-aim character body spinning on M1 attacks for natural directional movement.
- Removed open-air spell particle bursts on LMB clicks; impact particles now only trigger on enemy contact.
- Fixed server module loading errors and client network remote queue warnings.
- Fixed meditation camera distance bug in `AnimationController.luau` where camera was positioned `-6.0` studs close-up; extended to `-13.5` studs for wide cinematic framing.