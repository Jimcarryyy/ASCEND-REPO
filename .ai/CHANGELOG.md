# CHANGELOG

## [Unreleased] - Phase 2, Phase 3, Phase 4, & Phase 5 Task 5.1 Completion

### Added
- **UI Assets & Rarity System**:
  - `ReplicatedStorage/Shared/Configs/UIAssets.luau`: Central registry populated with live uploaded Roblox Asset IDs across HUD, Panels, Weapons, Skills, Currencies, and Status Effects.
  - `ReplicatedStorage/Shared/Configs/RarityConfig.luau`: Tier colors and hex mappings for Mortal through Immortal rarities.
- **HUD & Inventory UI**:
  - `HUDGui` with keybind badges, sweeping dark cooldown masks with live decimal timer text (`CooldownText`), reticle, boss health bar (`hud_boss_frame`), and tribulation bar (`hud_tribulation_bar`).
  - `InventoryGui` modal with dynamic `UIStroke` rarity borders.
- **Server-Authoritative Networking & State Engine**:
  - `RemoteEvents.luau`: Central remote factory (`CombatAction`, `UpdateSkillState`, `SyncCooldown`, `UpdateCultivation`).
  - `CombatStateManager.luau`: Server-authoritative state tracker (*Idle, Casting, Cooldown, Stunned, Qi Deviation*) with server-side cooldown validation.
  - `InputController.luau`: Mouse 3D targeting payloads (`mouse.Hit.Position` & `AimDirection`) with Classical ARPG keybind scheme (LMB, F, Q, E, R, Shift, 1, 2, 3, G, B).
- **Multi-Weapon Combat System**:
  - `FlyingSwordConfig.luau`, `SpearConfig.luau`, `GauntletConfig.luau`: Full skill and combo definitions for 3 distinct weapon styles.
  - `HitboxManager.luau`: Server spatial box hitboxes (`Workspace:GetPartBoundsInBox`), server damage, and physics knockbacks.
  - `FlyingSwordServer.luau`, `SpearServer.luau`, `GauntletServer.luau`: Weapon combat handlers.
  - `WeaponManager.luau`: Live weapon swapping (Hotkeys `1`, `2`, `3`), Motor6D attachment to `RightGripAttachment`, `Tool.Grip` compatibility, and procedural Qi placeholders (Cyan Sword, Gold Spear, Dual Cyan Qi Gauntlets).
- **Combat Juice, VFX & Audio**:
  - `CombatVFXController.luau`: 3D floating damage numbers, directional camera shake, impact particles, crisp white 3D weapon slash trails (`Trail`), swing SFX, and hit impact SFX.
  - `AnimationController.luau`: R15 keyframe attack animations, action priority layering, WalkSpeed action dampening, and physical Windstep dodge dash (`Shift`).
- **Cultivation Realm & Qi Meditation Engine**:
  - `CultivationConfig.luau`: Config for 5 Xianxia Realms (*Qi Condensation → Foundation Establishment → Golden Core → Nascent Soul → Heavenly Tribulation*).
  - `CultivationManager.luau`: Server-authoritative Qi absorption, meditation state (**Hotkey G**), steady 2.2 stud hover, lightweight ethereal body wrap (`Highlight` at 95% fill transparency), cinematic front-view camera, realm breakthroughs (**Hotkey B**), and health stat scaling.

### Changed
- Shifted heavy attack from RMB to **`F` key**, leaving RMB 100% free for camera rotation.
- Disabled Roblox default `Backpack` CoreGui to prevent inventory hotbar overlap.
- Removed auto-aim character body spinning on M1 attacks for natural directional movement.
- Removed open-air spell particle bursts on LMB clicks; impact particles now only trigger on enemy contact.
- Fixed server module loading errors and client network remote queue warnings.