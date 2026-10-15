# CURRENT TASK: Non-Humanoid Monster Stabilization & Combat V1 Resumption

> **Status:** Active Engineering & In-Game Verification [ACTIVE]  
> **Target Date:** 2026-10-15  
> **Governing Decisions:** ADR-073 through ADR-075  

---

## 🎯 Active Focus: Non-Humanoid Monster Locomotion & Combat Polish

1. **Terrain Incline & Lookahead Suspension Verification:**
   - [ ] Verify monsters (`Wilderness Spirit Wolf`, `Iron-Tusk Spirit Boar`) traverse upward grass inclines and curbs without sticking [UNCERTAIN].
   - [ ] Verify automatic obstacle vaulting triggers when encountering ledges $> 1.8$ studs [PROPOSED].
   - [ ] Confirm `Iron-Tusk Spirit Boar` strolls calmly while unaggroed (`WalkSpeed = 12`) and charges aggressively (`RunSpeed = 38`) upon player glimpse [PROPOSED].

2. **Wolf Airborne Leap Attack Verification:**
   - [ ] Verify wolf pounce launches physically 5 studs into the air ($Y = 46$ studs/s) toward the player [UNCERTAIN].
   - [ ] Confirm jump pounce animation matches physical airtime and lands cleanly with a bite strike [PROPOSED].

3. **Hit Feedback & Stagger Lockout:**
   - [ ] Verify monsters exhibit prominent 1.0-stud kinetic hit flinch and red body flash when damaged [PROPOSED].
   - [ ] Verify monsters cannot attack while taking damage (0.65s stagger lockout enforced) [PROPOSED].
   - [ ] Verify defeated monsters collapse flush to the terrain in a resting pose and dissolve smoothly over 2.0s [PROPOSED].
   - [ ] Verify floating damage numbers appear over player whenever struck by mobs or monsters [PROPOSED].

---

## 📋 V1 Combat Overhaul Implementation Checklist

### Phase 0: Verification & Baseline Audit [COMPLETE]
- [x] Full audit of combat files against raw GitHub links [DEV-CONFIRMED].
- [x] Identified `DeWidth.client.luau` R6 failure and resolved with `ScaleTo(1.15)` in `AntiTripServer.server.luau` [DEV-CONFIRMED].
- [x] Discovered server `IsAttacking = false` replication conflict on `RecoveryEndTime` [DEV-CONFIRMED].

### Phase 1: M1 Timing & Server-Authoritative Combo [COMPLETE]
- [x] Server-authoritative `M1Step` and `LastM1Time` tracking in `CombatStateManager.luau` [DEV-CONFIRMED].
- [x] Enforced 2.20s finisher lockout on Step 5 on server and client [DEV-CONFIRMED].

### Phase 2: M1 Animation, Lunge Removal & Input Buffering [COMPLETE]
- [x] Deleted `M1StepVelocity` forward physics lunge [DEV-CONFIRMED].
- [x] Implemented swing token architecture and input buffering [PROPOSED].

### Phase 3: Movement Governor & Hybrid Facing [COMPLETE]
- [x] Decoupled client movement governor from server `IsAttacking` attribute [DEV-CONFIRMED].
- [x] Enforced attack movement speed dampening at `11.5 studs/s` [DEV-CONFIRMED].

### Phase 4: Dash as a Leap (ACTIVE NEXT STEP AFTER MONSTER VERIFICATION)
- [ ] Replace 125 studs/s linear burst with a 4-way aerial leap arc (~55 horizontal, ~35 vertical, ~0.36s airtime) [PROPOSED].
- [ ] Implement ground raycast/state landing detection to end dash state cleanly [PROPOSED].
- [ ] Sync server i-frame duration from 0.24s to ~0.30s to match leap airtime [PROPOSED].
- [ ] Enforce `DASH_CANCELS_M1 = true` to abort active swings and reset combo sequence [PROPOSED].

### Phase 5: Server Hardening & Defense Tuning
- [ ] Add `CLASH_COOLDOWN_PER_PLAYER = 0.6s` to prevent clash loops [PROPOSED].
- [ ] Scale M1 posture damage by `0.5` to preserve guard pacing [PROPOSED].
- [ ] Add `BLOCK_REPRESS_COOLDOWN = 0.45s` to prevent perfect parry spam [PROPOSED].

### Phase 6: Balance Metrics & Documentation Parity
- [ ] Bring `docs/COMBAT_SPEC.md` into 100% parity with live code constants [PROPOSED].
- [ ] Update `docs/Temporary.md` to reflect voided boss scope [PROPOSED].