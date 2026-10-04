# ASCEND — Active Task: Combat V1 Implementation & Kinematic Overhaul

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** ASCEND Combat V1 — Continuous Sword Chain, Locomotion Dampening & Kinematic Leap  
> **Governing Decisions:** ADR-065 (Avatar Scale 1.15/0.90), ADR-066 (2.20s Finisher Lockout Loop), ADR-067 (11.5 studs/s Dampened WalkSpeed), ADR-068 (10-Jian Non-Elemental Roster).

---

## 🎯 Active Focus: Phase 4 — Dash as a Leap (Kinematics & Landing Detection)
Replace the 125 studs/s horizontal burst with an aerial martial leap (~55 studs/s horizontal, ~35 studs/s vertical, ~0.36s airtime), sync server i-frames to 0.30s, and ensure dash cancels M1 attacks cleanly.

---

## 📋 V1 Combat Overhaul Implementation Checklist

### Phase 0: Verification & Baseline Audit [COMPLETE]
- [x] Full audit of combat files against raw GitHub links [DEV-CONFIRMED].
- [x] Identified `DeWidth.client.luau` R6 failure and resolved with `ScaleTo(1.15)` in `AntiTripServer.server.luau` [DEV-CONFIRMED].
- [x] Discovered server `IsAttacking = false` replication conflict on `RecoveryEndTime` [DEV-CONFIRMED].
- [x] Verified `FlyingSwordServer.luau` crits are random math rolls and Sword Intent is client-only [DEV-CONFIRMED].

### Phase 1: M1 Timing & Server-Authoritative Combo [COMPLETE / PENDING FULL-FILE COMMIT]
- [x] Replace broken `CastDuration * 0.5` fallback with live `ActiveDuration` in `CombatStateManager.luau` [DEV-CONFIRMED].
- [x] Implement server-authoritative `M1Step` and `LastM1Time` tracking in `CombatStateManager.luau` [PROPOSED].
- [x] Reset M1 combo sequence on Death, CC, Sheath, and Dash [PROPOSED].
- [x] Enforce 2.20s finisher lockout on Step 5 on server and client [DEV-CONFIRMED].

### Phase 2: M1 Animation, Lunge Removal, Swing Token & Input Buffering [COMPLETE / PENDING FULL-FILE COMMIT]
- [x] Remove 0.55× windup speed curve; play at dynamic `track.Length / CastDuration` clamped to `[0.6, 2.5]` [PROPOSED].
- [x] Standardize 0.06s cross-fading between swings [PROPOSED].
- [x] Completely delete `M1StepVelocity` forward physics lunge [PROPOSED].
- [x] Implement single-buffered input queuing via `BUFFER_FRACTION = 0.35` [PROPOSED].
- [x] Implement swing token architecture (`currentSwingToken`) to eliminate stale `task.delay` race conditions [PROPOSED].
- [x] Implement `CancelCurrentSwing()` for instant interruption on Block, Dash, Stun, Sheath, and Death [PROPOSED].

### Phase 3: Movement Governor & Hybrid Facing [COMPLETE / PENDING FULL-FILE COMMIT]
- [x] Decouple client movement governor from server `IsAttacking` attribute [DEV-CONFIRMED].
- [x] Enforce controlled attack movement speed at `11.5 studs/s` (`math.min(baseSpeed, 11.5)`) [DEV-CONFIRMED].
- [x] Implement post-chain smooth speed ramp up over `0.18s` (`SPEED_RAMP_DURATION`) [PROPOSED].
- [x] Implement 0.05s hybrid facing turn (`M1_TURN_TIME`) and lock `AutoRotate = false` during swings for circle-strafing [PROPOSED].
- [x] Integrate `Alt` target focus lock-on aim vectors via `FocusTargetController` getters [PROPOSED].

### Phase 4: Dash as a Leap (ACTIVE NEXT STEP)
- [ ] Replace 125 studs/s linear burst with a 4-way aerial leap arc (~55 horizontal, ~35 vertical, ~0.36s airtime) [PROPOSED].
- [ ] Implement ground raycast/state landing detection to end dash state cleanly without air/floor jamming [PROPOSED].
- [ ] Sync server i-frame duration from 0.24s to ~0.30s to match leap airtime [PROPOSED].
- [ ] Connect `DASH_CANCELS_M1 = true` to abort active M1 swings and reset combo on dash [PROPOSED].
- [ ] Ensure server transitions `ActionState` from `"Dashing"` to `"Idle"` cleanly upon landing [PROPOSED].

### Phase 5: Server Hardening & Defense Tuning
- [ ] Reduce `ClashWindow` from 0.18s to 0.10s and add `CLASH_COOLDOWN_PER_PLAYER = 0.6s` to prevent clash loops [PROPOSED].
- [ ] Scale M1 posture damage by `M1_POSTURE_SCALE = 0.5` to preserve guard pacing against faster combo [PROPOSED].
- [ ] Add `BLOCK_REPRESS_COOLDOWN = 0.45s` for Perfect Parry window to prevent block spam [PROPOSED].
- [ ] Add log-only aim deviation checks (`AIM_MAX_DEVIATION_DEG = 100`) and packet rate sanity [PROPOSED].

### Phase 6: Balance Metrics & Documentation Parity
- [ ] Compute Before vs. After balance metrics (hits/sec, DPS, mob TTK) and add `M1_DAMAGE_SCALE = 1.0` multiplier [PROPOSED].
- [ ] Bring `docs/COMBAT_SPEC.md` into 100% parity with live code constants [PROPOSED].
- [ ] Finalize `.ai/CHANGELOG.md` and `.ai/DECISIONS.md` [PROPOSED].

---

## 🚫 Explicit Constraints
1. **No Fire Content in V1:** Do not add Fire skills, Blazeburn status effects, or Fire BaseAttributes.
2. **No Selection or Respec UI:** Do not build Dao selection modals or consumable tokens.
3. **No Talent Trees:** Prohibit node-graph or point-allocation UI.
4. **Codebase is Truth:** Never trust outdated docs over live Luau scripts.