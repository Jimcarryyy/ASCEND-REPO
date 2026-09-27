# ASCEND — Active Task: Combat V1 Implementation (Final Phase Plan v3)

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** ASCEND Combat V1 — Single-Kit Hardening & Architecture Dao-Shaping  
> **Governing Decision:** Ship ONE polished combat kit (Thunder, unnamed). Dao selection UI, respec tokens, Fire content, and talent trees are deferred to post-V1. Depth comes from sword passives (6a) and milestone skill upgrades (6b).

---

## 🎯 Active Focus: Phase 1 — Timing Fix
Replace the broken `CastDuration * 0.5` fallback in `src/ServerScriptService/Server/State/CombatStateManager.luau` with explicit `ActiveDuration` from `FlyingSwordConfig.Skills`.

---

## 📋 V1 Implementation Roadmap & Checklist

### Phase 1: Timing Fix (ACTIVE)
- [ ] Replace `CastDuration` fallback in `CombatStateManager.luau:407–419` with `FlyingSwordConfig.Skills[skillKey].ActiveDuration or 0.20`.
- [x] Verify `Windup` usage: confirmed unconsumed by `InputController.luau` and `FlyingSwordServer.luau` [DEV-CONFIRMED].
- [ ] Acceptance Test: Verify server logs show distinct active-hit windows (`Q = 0.35s`, `E = 0.14s`, `F = 0.22s`) instead of defaulting to `0.25s`.

### Phase 2: Server-Authoritative Sword Intent
- [ ] Implement server-side Intent number in `CombatStateManager.luau` / `HitboxManager.luau`.
- [ ] Increment +25 Intent on server-confirmed landed strikes (`HitboxManager`).
- [ ] Implement server decay: -8.0/s starting 2.5s after last landed hit.
- [ ] Replicate via character attribute `SwordIntent` to drive `SkillBarController.luau`'s existing `IntentBarFrame`.
- [ ] Purge client-side prediction in `SkillBarController.luau` to eliminate desync.
- [ ] Resolve Open Decision: Option A (holds at 100%, no trigger) vs Option B (universal bonus damage).

### Phase 3: Architecture Dao-Shaping
- [ ] Wrap `FlyingSwordConfig.Skills` into `FlyingSwordConfig.Daos.Thunder.Skills` with empty placeholders for `VFXPalette`, `IntentPayoff`, and `BaseAttributes`.
- [ ] Update confirmed call sites across `CombatStateManager.luau`, `FlyingSwordServer.luau`, and `InputController.luau`.
- [ ] Add generic `ActiveStatusEffects` table and runner skeleton to `HitboxManager.luau` (no active status effects in V1).
- [ ] Set `DEFAULT_PLAYER_DATA.Cultivation.SwordDao = "Thunder"` in `PlayerDataManager.luau`.

### Phase 4: VFX Dispatch Refactor
- [ ] Refactor `CombatVFXController.luau` skill branching to a `SkillVFXHandlers` lookup table.
- [ ] Keep `ItemConfig.GetWeaponPalette` color sourcing intact (flag for post-V1 Dao color decision).

### Phase 5: Posture Wiring & Local Bar
- [ ] 5a: Verify and ensure `character:SetAttribute("Posture", ...)` is written in `HitboxManager.luau` on hit/regen, and `MaxPosture = 100` on spawn.
- [ ] 5b: Add local `PostureBarFrame` to `MasterHUDGui.VitalsContainer` and bind in `SkillBarController.luau`.
- [ ] 5c: QA parry window (0.22s), guard-break stun (2.0s), and posture regen delay (1.25s).

### Phase 6: Horizontal Depth Pass
- [ ] 6a: Add flat `Passive` modifiers to 8 sword tiers in `ItemConfig.luau`, render in `InventoryController.luau`, and hook into `FlyingSwordServer.luau`.
- [ ] 6b: Add `SkillUnlock_Pill` to `AscensionModal` in `CultivationController.luau` and wire milestone stat/cooldown bumps upon breakthrough.

### Phase 7 & 8: QA, Tuning & Documentation
- [ ] TTK sanity testing on single kit with corrected timing.
- [ ] Update `COMBAT_SPEC.md` with true code values (2,800x cap, 36/30 sprint, Q/E/F timings).
- [ ] Author `DAO_SYSTEM.md` as an architecture interface contract for future Daos.

---

## 🚫 Explicit Constraints
1. **No Fire Content in V1:** Do not add Fire skills, Blazeburn status effects, or Fire BaseAttributes.
2. **No Selection or Respec UI:** Do not build Dao selection modals or consumable tokens.
3. **No Talent Trees:** Prohibit node-graph or point-allocation UI.
4. **Codebase is Truth:** Never trust outdated docs over live Luau scripts.