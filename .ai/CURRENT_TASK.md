# Current Task Specification — ASCEND

## Purpose
This document defines the single active operational focus of development for ASCEND. Historical task threads are permanently archived in `CHANGELOG.md`.

**Current Milestone:** Phase 8.5 — Combat Engine Hardening & Skills Overhaul  
**Active Timestamp:** September 2026  
**Active Role Context:** Systems Architect, Combat & Progression Designer, UI/UX & Asset Director  

---

## 🎯 ACTIVE TASK: Skill E (Piercing Void Thrust) Overhaul & Shield VFX Integration

Following the successful stabilization of the `F` Ultimate (100-Slash Flash Domain), `Q` Skill (Purple Sword Tempest), full-body R6 mob AI with smart flocking, and the Master HUD bottom-left overhaul:

### Active Verification & Acceptance Checklist
- [x] Fix server nil crash on mob death (`MobAIManager.luau:184` and `195`) by eliminating legacy profile dependencies and routing rewards through `PlayerDataManager` and `CultivationManager`.
- [x] Overhaul `F` Ultimate Skill physics: Eliminate tripping, ragdoll, and rubber-banding by deploying client-authoritative elevation lift (+2.2 studs into Freefall), `AlignOrientation` (10M torque), slope-normal ground landing (`Normal.Y > 0.65`), and instant 1-click trigger.
- [x] Integrate dynamic weapon-attuned color palette across `Q`, `F`, `Shift` dash afterimages, and `F` Shunpo ghosts via `ItemConfig.GetWeaponPalette`.
- [x] Rebuild Master HUD layout: Relocate `VitalsContainer` and `TopRightCurrencyFrame` to the bottom-left corner with equalized 340px bars, no `UICorner`, split header labels, and `Bangers` font.
- [x] Rebuild `BottomNavTray`: Relocate to the top-right corner as a vertical 4-button stack (`Arena`, `Pouch`, `Guide`, `Mission`) with custom left-aligned icons and vibrant gradients.
- [x] Overhaul player overheads: Remove redundant overhead HP bar; retain only Cultivation Realm & Order + Sect Rank in `Bangers` with vertical text gradients and deduplicated order formatting.
- [x] Fix player revival and respawn vitals bug: Purge zombie event listeners in `SkillBarController.luau`, set `MasterHUDGui.ResetOnSpawn = false`, and apply synchronous full realm HP/Qi on spawn in `CultivationManager.luau`.
- [x] Overhaul Mob AI: Fix mob walking/running animation detection via `AssemblyLinearVelocity`, implement smart teammate flocking and Boids separation, add 5-step M1 combo attack sequencing, and route damage through `HitboxManager` with full player parry/block support, camera shudder, and slashmarks.
- [x] Replace `Boss_ElderYan` with `Boss_FallenSwordGenius` ("Fallen Sword Genius - Mo Chen") based on the proven `CorruptedIronGuard` R6 armature with 1.28x athletic scale, Ink & Blood robes, and single cursed horn.
- [x] Overhaul `GatheringHUD` & ProximityPrompts: Compact 210x40 size, `"HARVESTING..."` text, vibrant Amber-Gold gradient, and reliable model/part adornee resolution with instant suppression upon interaction.
- [x] Overhaul `SectPavilionGui`, `StarterGuideGui`, and `BlacksmithGui`: Convert bamboo `ImageLabel`s into clean, sharp `Frame`s following the Master Xianxia UI Color Specification.
- [ ] **Overhaul Skill `E` (Piercing Void Thrust):** Standardize server/client execution, integrate weapon-attuned color palette, and calibrate knockback/projectile timings.
- [ ] **Wire Remaining `ReplicatedStorage.VFX` Assets:**
  - `ActiveShield` $\rightarrow$ Wire to `T` Block (Hold) in `CombatVFXController.luau`.
  - `ShieldBreakEffects` $\rightarrow$ Wire to Posture GuardBreak trigger.
  - `SwordIntentAnim` $\rightarrow$ Wire to 100% Sword Intent Empowered Strike.
  - `FireSlashSkill` $\rightarrow$ Map to blade variant or skill slot.
- [ ] **Reconcile `R` Keybind Conflict:** Formally settle Draw/Sheath vs `Celestial Sunfall` ultimate keybinding.

---

## 🚀 QUEUED NEXT: Skill E Overhaul & Defensive Shield VFX
1. Implement full client/server overhaul for `E` Skill (Piercing Void Thrust) with weapon-attuned projectile VFX.
2. Wire `ActiveShield` and `ShieldBreakEffects` into `CombatVFXController.luau` for `T` Guard and GuardBreak states.
3. Wire `Boss_FallenSwordGenius` to live `BossHealthHUD`.