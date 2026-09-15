# ASCEND — Active Task: Documentation Synchronization & Combat Engine Polish

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 🎯 Active Focus

Resolve severe documentation drift by purging all stacked historical drafts across `docs/`, aligning technical specifications 1:1 with the live codebase, and executing the Phase 8.5 combat polish items (Skill `E` overhaul and remaining defensive/intent VFX wiring).

---

## 📋 Task Verification & Acceptance Checklist

### 1. Ground-Truth Documentation Reconciliation Pass
- [x] **`docs/README.md`:** Standardize DataStore to V3 (`ASCEND_PlayerData_V3`), unify canonical keybind map (`R` = Draw/Sheath, `C` = Meditate, `V` = Flight, `F` = 100-Slash), document 8 sword tiers and 10 cultivation realms.
- [x] **`docs/COMBAT_SPEC.md`:** Purge 3 stacked legacy drafts; delete Magma Cleave, Volcanic Tempest, and Celestial Sunfall; codify 5-hit M1 combo, Sword Intent, Posture/Parry, and Q/E/F skills.
- [x] **`docs/PROGRESSION_SPEC.md`:** Reconcile cultivation math with `CultivationConfig.luau` (10 realms × 9 orders = 90 stages; Order 9 math computes ~220,000× base power; Heavenly Tribulation strikes).
- [x] **`docs/ARCHITECTURE_SPEC.md`:** Document all 18 Server Managers, 24 Client Controllers, and 22 centralized RemoteEvents.
- [x] **`docs/UI_UX_SPEC.md`:** Formalize Studio UI authority (ADR-041), Bangers/Fundamento typography (ADR-042), 9-slice standard `115367926298823`, and bottom-left 340px column stack.
- [x] **`docs/GAME_DESIGN.md`:** Purge stacked drafts; codify core 4-step loop, 3-tier Jade Pure Sect mountain hub (ADR-044), NPC roster, bestiary, and arena.
- [ ] **`.ai/` Tracking Suite:** Update `CURRENT_TASK.md`, `NEXT_STEPS.md`, and `PROJECT_STATUS.md` to reflect verified live facts with zero inflated metrics.

### 2. Combat Engine Implementation (Phase 8.5)
- [ ] **Overhaul Skill `E` (Piercing Void Thrust):**
  - Implement client/server projectile casting (120 studs/s forward beam velocity).
  - Integrate dynamic weapon-attuned color palette (`ItemConfig.GetWeaponPalette`) so thrust beam matches equipped sword.
  - Wire damage (80 base / 220 arena) and knockback (`Vector3.new(0, 10, -40)`).
  - Add visual and sound handling to `CombatVFXController.luau`.
- [ ] **Wire Remaining `ReplicatedStorage.VFX` Assets:**
  - `ActiveShield` $\rightarrow$ Wire to `T` Block hold in `CombatVFXController.luau` (attach/detach via `BlockStart` / `BlockEnd`).
  - `ShieldBreakEffects` $\rightarrow$ Trigger at target root upon Posture guard break (`payload.WasGuardBroken == true`).
  - `SwordIntentAnim` $\rightarrow$ Detonate on caster/blade upon 100% Sword Intent Empowered Strike ($1.75\times$).
  - `FireSlashSkill` $\rightarrow$ Map to flame blade variant or dedicated elemental skill slot.
- [ ] **Boss Health HUD Wiring:**
  - Wire `StarterGui.BossHealthHUD` to detect proximity ($<65\text{ studs}$) or damage engagement with `Boss_FallenSwordGenius`.

---

## 🚫 Explicit Constraints (Ground Rules)
1. **The Codebase is the Only Truth:** Never trust numbers in unverified documents over live scripts. If code and docs disagree, code wins.
2. **No Inflated Percentages:** Do not fabricate completion percentages or declare systems "done" without code verification.
3. **No Dynamic UI via Code (ADR-041):** Never create static UI frames using `Instance.new`. All UI hierarchies must reside natively in `StarterGui`.
4. **Single-Weapon Purity (ADR-038):** Combat logic belongs exclusively to Flying Swords. Do not introduce branching weapon archetypes.