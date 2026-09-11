# Next Steps & Project Roadmap — ASCEND

## Purpose
This document outlines planned upcoming engineering and design milestones for ASCEND, ordered strictly by priority.

**Consolidation Date:** September 2026

---

## Phase 8.5 Roadmap: Combat Skills & Combat Feel Hardening

### 1. Immediate Priority (Active Milestone)
- **Patch `HitboxManager.luau` Line 228:**
  - Audit `HitboxManager.ApplyCombatResolution` to handle `hit.Character` targets that are Mobs/NPCs (where `Players:GetPlayerFromCharacter(hit.Character)` is `nil`), preventing server crashes during combat.
- **VFX Skill Pipeline Integration:**
  - Integrate the remaining assets in `ReplicatedStorage.VFX` into live gameplay:
    - `ActiveShield` $\rightarrow$ Wire to `T` Block (Hold) in `CombatVFXController.luau`.
    - `ShieldBreakEffects` $\rightarrow$ Trigger when Posture hits 0 on players and mobs.
    - `SwordIntentAnim` $\rightarrow$ Wire to 100% Sword Intent Empowered M1 Strike.
    - `FireSlashSkill` $\rightarrow$ Map to elemental blade variant or skill slot.
- **Keybind Conflict Resolution:**
  - Resolve `R` keybind conflict: Currently bound to `Draw/Sheath` on HUD while documented as `Celestial Sunfall` ultimate in `COMBAT_SPEC.md`.

### 2. High Priority (Mob Encounters & Combat Balance)
- **Zone 1 Mob Spawner Distribution:**
  - Place `Spawner_RogueDisciples` pads in designated wilderness camps outside the Sect walls.
  - Add mob definitions and spawn anchors for `DemonWolf` and `IronhideBoar` using `MobConfig.luau`.
- **Combat Audio Balance Pass:**
  - Balance volume curves for `SWORD_RELEASE_SFX` (`109735549169421`), `HIT_IMPACT_SOUND_ID` (`135448977656112`), and `ULTIMATE_SFX_ID` (`18781431019`).

### 3. Medium Priority (World Dressing & Monetization)
- **Zone 1 Foliage & Dressing Finalization:**
  - Scatter pine and stylized trees across remaining empty terrain zones using the calibrated non-colliding canopy rules.
  - Ensure all 16 `Functional_Stations` have clean collision bounds and verified ProximityPrompts.
- **Creator Dashboard Monetization Audit:**
  - Audit live Gamepass IDs and DevProduct IDs in `MonetizationConfig.luau` against active Roblox Creator Dashboard assets.

---

## Open Items From This Session

- [ ] **`HitboxManager:228` Server Nil Error:** Investigate line 228 of `src/ServerScriptService/Server/Combat/HitboxManager.luau`. Currently wrapped via `pcall` in `FlyingSwordServer.luau`, but needs clean NPC target handling in the manager itself.
- [ ] **R Keybind Resolution:** Decide whether to move Draw/Sheath to another hotkey (e.g. `Z` or double-tap) so `R` can be freed for an Ultimate skill, or keep `R` as Draw/Sheath and use `F` as the primary Ultimate slot.
- [ ] **`ReplicatedStorage.VFX` Organization:** Move `UltimateSkill`, `ActiveShield`, `ShieldBreakEffects`, `SwordIntentAnim`, and `FireSlashSkill` into a standardized subfolder in `ReplicatedStorage.VFX` to ensure consistent client preloading.