# Next Steps & Project Roadmap — ASCEND

## Purpose
This document outlines planned upcoming engineering and design milestones for ASCEND, ordered strictly by priority.

**Consolidation Date:** September 2026

---

## Phase 8.5 Roadmap: Combat Skills & Combat Feel Hardening

### 1. Immediate Priority (Active Milestone)
- **Skill `E` Overhaul (Piercing Void Thrust):**
  - Standardize projectile speed and hitbox casting across `FlyingSwordServer.luau` and `CombatVFXController.luau`.
  - Integrate dynamic weapon-attuned color palette (`ItemConfig.GetWeaponPalette`) so the projectile beam matches the equipped blade.
  - Tune knockback and range to establish a distinct long-range piercing zoning tool.
- **Defensive VFX Pipeline Integration (`ReplicatedStorage.VFX`):**
  - `ActiveShield` $\rightarrow$ Bind to `T` Guard hold in `CombatVFXController.luau`.
  - `ShieldBreakEffects` $\rightarrow$ Trigger on player and mob guard breaks when Posture reaches 0.
  - `SwordIntentAnim` $\rightarrow$ Trigger on 100% Sword Intent Empowered M1 strike.
  - `FireSlashSkill` $\rightarrow$ Map to elemental blade variant or skill slot.
- **World Boss HUD Integration (`BossHealthHUD`):**
  - Wire `StarterGui.BossHealthHUD` to track `Boss_FallenSwordGenius` whenever a player enters combat with him.
  - Style `BossHealthHUD` to match the Master Xianxia UI Color Specification (sharp rectangular frame, Bangers font, vibrant crimson/gold gradient).

### 2. High Priority (World Spawners & Combat Balance)
- **Wilderness Mob Spawner Placement:**
  - Drag and arrange the 5 newly configured spawner anchors (`Spawner_RogueDisciples`, `Spawner_BloodShadowAssassin`, `Spawner_CorruptedIronGuard`, `Spawner_FallenInnerProdigy`, `Spawner_BossFallenSwordGenius`) across their designated zones in Studio.
  - Add world spawn anchors for `DemonWolf` and `IronhideBoar` in Zone 1 forests.
- **Combat Audio & Volume Balance Pass:**
  - Balance volume curves across `SWORD_RELEASE_SFX` (`109735549169421`), `HIT_IMPACT_SOUND_ID` (`135448977656112`), and `ULTIMATE_SFX_ID` (`18781431019`).
- **Keybind Conflict Resolution:**
  - Resolve `R` keybind: Confirm whether `R` remains Draw/Sheath while `F` is the primary Ultimate, or remap Draw/Sheath to free `R` for `Celestial Sunfall`.

### 3. Medium Priority (World Dressing & Monetization)
- **Zone 1 Foliage & Tree Collision Audit:**
  - Scatter pine and stylized trees across remaining empty terrain zones using the calibrated non-colliding canopy rules.
  - Ensure all 16 `Functional_Stations` have clean collision bounds and verified ProximityPrompts.
- **Creator Dashboard Monetization Audit:**
  - Audit live Gamepass IDs and DevProduct IDs in `MonetizationConfig.luau` against active Roblox Creator Dashboard assets.

---

## Open Items From This Session

- [ ] **`E` Skill Projectile Pipeline:** Verify if `E` skill should spawn a physical traveling projectile model or use a compensated raycast beam with particle trails.
- [ ] **Boss Health Bar Binding:** Wire `StarterGui.BossHealthHUD` to activate when within 65 studs of `Boss_FallenSwordGenius` or when taking damage from him.
- [ ] **R Keybind Canonicalization:** Formally update `COMBAT_SPEC.md` to reflect `R` as Draw/Sheath or reassign Draw/Sheath to allow `R` to function as an additional active skill.
- [ ] **Remaining Facility GUI Conversions:** Apply the Master Xianxia Color System to the remaining facility modals in `StarterGui` (`AlchemyGui`, `TeaHouseGui`, `SparringGuidanceGui`, `SpiritPouchInventoryGui`).