### ADR-065: R6 Avatar Proportional Scaling & Head Reduction Standard
* **Date:** 2026-10-04 (backfilled from Session Digest #N)
* **Status:** Accepted & Implemented [DEV-CONFIRMED]
* **Context:** Default R6 avatars (5.0 studs tall) felt like miniature figurines in tall grass, while uniform scaling to 1.28x produced an oversized bobblehead look due to classic 1:4 R6 head ratios. `DeWidth.client.luau` failed because `BodyWidthScale` does not affect R6 rigs.
* **Decision:**
  1. Standardized server-authoritative scaling in `AntiTripServer.server.luau` to `BODY_SCALE = 1.15` (5.75 studs tall).
  2. Scaled the Head `SpecialMesh` and all head accessories/hair by `HEAD_REDUCTION = 0.90` (10% smaller relative to the body).
  3. Re-aligned the neck joint offset to `neck.C1 = CFrame.new(0, -0.45 * BODY_SCALE, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)` to eliminate collar floating gaps.
* **Consequences:** Delivers heroic anime proportions without visual distortion or collision clipping.

### ADR-066: M1 5-Hit Cadence, Finisher Recovery Lockout (2.20s), and Continuous Loop
* **Date:** 2026-10-04 (backfilled from Session Digest #N)
* **Status:** Accepted [DEV-CONFIRMED]
* **Context:** Unlimited M1 attack spamming created zero defensive counterplay in PvP and felt exploitative/glitchy ("cheater speed").
* **Decision:**
  1. Structured M1 into a strict 5-hit sequence: Hits 1–4 execute at ~0.30s cadence; Hit 5 (finisher) executes at ~0.50s.
  2. Implemented a mandatory **2.20s recovery lockout cooldown** after Hit 5 during which clicks are ignored and the M1 HUD displays a recovery sweep.
  3. Clicking after the 2.20s window restarts the combo loop at **Hit 1**.
  4. If an attacker pauses mid-combo for $> 1.2\text{s}$ before Hit 5, the sequence automatically resets to Hit 1.
* **Consequences:** Establishes predictable martial cadence, defensive counter-attack windows, and prevents continuous M1 spam.

### ADR-067: Attack Locomotion Dampening (11.5 studs/s) & Client-Only Governor Decoupling
* **Date:** 2026-10-04 (backfilled from Session Digest #N)
* **Status:** Accepted [DEV-CONFIRMED]
* **Context:** The server replicating `IsAttacking = false` on `RecoveryEndTime` was overwriting the client's local `IsAttacking = true` mid-combo, causing WalkSpeed to jerk abruptly between 6.0 and 36.0 studs/s. Attacking while running also completely stopped or sprint-glitched players.
* **Decision:**
  1. Decoupled client locomotion from the server `IsAttacking` attribute. WalkSpeed during attacks is governed strictly by an internal client state variable (`isAttackingLocally`).
  2. Attacking clamps movement speed to `math.min(baseSpeed, 11.5 studs/s)`. Players moving at sprint (36) or walk (16) are noticeably slowed, but **never stop moving**.
  3. Ending an attack sequence smoothly ramps speed back up to sprint/walk over `SPEED_RAMP_DURATION = 0.18s` instead of snapping in 1 frame.
* **Consequences:** Smooth, continuous martial footwork with zero replication stutter or network fighting.

### ADR-068: 10-Jian Sword Weapon Progression & Roster Cap at Legendary
* **Date:** 2026-10-04 (backfilled from Session Digest #N)
* **Status:** Accepted [DEV-CONFIRMED]
* **Context:** The weapon roster had 8 mixed weapon archetypes (Jian straight swords, Dao sabers) with inconsistent elemental themes.
* **Decision:**
  1. Standardized all 10 V1 weapons strictly as traditional Chinese **Jian** (straight, double-edged swords) with matching scabbards.
  2. Prohibited elemental themes (no Fire, Ice, Lightning, Poison). Weapons embody pure martial craftsmanship, cold steel, jade, and sword intent.
  3. Capped the progression roster strictly at **Legendary (Divine Grade)**, omitting Mythic, Immortal, and Celestial tiers from the 10-sword list (2 swords per tier across Common, Uncommon, Rare, Epic, Legendary).
* **Consequences:** Creates a pure, unified Xianxia sword cultivator aesthetic with balanced itemization.