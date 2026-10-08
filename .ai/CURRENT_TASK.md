# CURRENT TASK: Multi-System Sync Verification & Combat V1 Phase 4 Resumption

> **Status:** Verification & Testing [ACTIVE]  
> **Target Date:** 2026-10-08  
> **Governing Decisions:** ADR-065 through ADR-072  

---

## 🎯 Active Focus: Live Verification of Overhauled Systems

1. **Sect Exchange Pavilion (`SectMerchantMarketGui` & `VendorManager.luau`):**
   - [x] Verify bulk selling exceeding 100 items (e.g. 700+ herbs) processes completely in one transaction. [PROPOSED]
   - [x] Verify purchased goods (Dans, Cores, Herbs) immediately appear in player inventory and Sell Loot tab. [PROPOSED]
   - [x] Verify mobile viewport renders 2 to 3 columns per row with zero single-slot overflow. [PROPOSED]
   - [x] Verify empty inventory and empty category fallback notices display cleanly. [PROPOSED]

2. **Master HUD Polish & Cooldown Popups:**
   - [x] Verify active cooldown status boxes appear above 1–5 hotbar for Dash, Block, Q, E, F, B, and Finisher lockout. [PROPOSED]
   - [x] Verify live countdown timers and sweep masks smoothly drain and auto-destroy on completion. [PROPOSED]
   - [x] Verify `[⌨ KEYS]` button expands and collapses the bottom-right action guide smoothly. [PROPOSED]
   - [x] Verify <kbd>M</kbd> key and minimap click toggle the `FullWorldMapFrame` modal without key conflicts. [PROPOSED]

3. **Autonomous Left-Shoulder Bloodline Orbs:**
   - [x] Verify world-space damped floating smoothly follows character locomotion without clipping. [PROPOSED]
   - [x] Verify PointLight illumination remains active with zero particle emitter VFX on the orb. [PROPOSED]
   - [x] Verify meditation VFX remains pure `Tier1_Common` tinted to orb palette with no skull/face VFX. [PROPOSED]||

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

## ⏭️ Immediate Next Priority: Resume Combat V1 Phase 4

* **Phase 4: Dash as a Leap (Kinematics & Landing Detection):**
  - Replace 125 studs/s horizontal burst with aerial martial leap (~55 studs/s horizontal, ~35 studs/s vertical, ~0.36s airtime).
  - Ground raycast landing detection to exit dash state cleanly without air/floor jamming.
  - Sync server i-frames from 0.24s to ~0.30s to match leap airtime.
  - Enforce `DASH_CANCELS_M1 = true` to abort active M1 swings and reset combo sequence.