# ASCEND — Combat System Specification (Authoritative V1)

> **Document Classification:** Core Gameplay Specification  
> **Source of Truth:** Live Luau Codebase (`src/`) & ADR Decisions Log  
> **System Architecture:** Pure Sword Cultivation, R6 Kinematics, Server-Authoritative Combat  
> **Reconciliation Status:** Fully synchronized with live codebase implementations (Phases 0–3 Overhaul, ADR-065 through ADR-068).

---

## 1. Overview & Martial Design Pillars

ASCEND delivers fast-paced, high-skill pure sword cultivation combat built around traditional Chinese swordsmanship (**Jian**). Combat eliminates elemental magic tropes in favor of cold steel, refined sword intent, posture pressure, and decisive martial footwork.

### Core Tenets:
1. **Pure Sword Cultivation:** Weapons are exclusively straight, double-edged **Jian** with matching scabbards. Weapon tiers are capped at **Legendary (Divine Grade)**.
2. **Fluid Martial Chain:** A continuous 5-hit basic combo with controlled movement, agile circle-strafing, and a distinct recovery cooldown loop.
3. **Decisive Defense (Posture & Parry):** Defense relies on high-risk, high-reward Perfect Parries (0.22s) and posture management. Holding block is punished by rapid posture break.
4. **Authoritative Anti-Exploit Security:** Hitbox verification, active strike frames, combo sequences, and cooldown gates are calculated authoritatively on the server.

---

## 2. Core Keybinds & Control Scheme

| Keybind | Input Type | Action | Resource Cost | Base Cooldown | Description |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **`M1`** | MouseButton1 | Basic Sword Chain | 0 Qi | 0.30s (1–4) / 2.20s (5) | 5-hit sequential slash chain ending in a 2.20s recovery lockout. |
| **`T`** | Held KeyCode | Guard / Perfect Parry | Posture drain | 1.2s (UI sweep) | 70% damage reduction on block; 0 damage + 1.2s stun on parry (0.22s). |
| **`Shift`** | KeyCode | Qi Dash / Leap | 0 Qi | 2.2s | Directional movement with 0.24s–0.30s i-frame invulnerability. |
| **`Q`** | KeyCode | Sword Tempest | 12% Max Qi | 6.5s | Point-blank slash releasing 3 piercing blade waves (70 studs/s). |
| **`E`** | KeyCode | Piercing Void Thrust | 15% Max Qi | 7.5s | High-penetration linear thrust inflicting -14 knockback. |
| **`F`** | KeyCode | 100-Slash Domain | 20% Max Qi | 14.0s | 32-stud flash-step blink into an 18-stud spherical slash domain. |
| **`Left/Right Alt`** | KeyCode | Focus Lock-On | 0 Qi | None | Locks target reticle and Card HUD to nearest enemy within 65 studs. |
| **`V`** | KeyCode | Flight Mode Toggle | 25 Qi/s (scaled) | 0.5s | 3D telekinetic sword surfing with realm velocity scaling (45–185 studs/s). |
| **`R`** | KeyCode | Toggle Sheath | 0 | 0.4s | Switches weapon between right hand and upper back sheath mount. |
| **`Left/Right Ctrl`**| KeyCode | Sprint Toggle | 0 | None | Toggles between Walk (16 studs/s) and Sprint (36 studs/s). |
| **`C`** | KeyCode | Meditate | 0 | 0.8s | Freezes character to accelerate internal Qi cultivation rate. |
| **`B`** | KeyCode | Realm Breakthrough | Dan Pill | None | Triggers ascension check or Heavenly Tribulation lightning strikes. |

---

## 3. M1 Basic Attack Combo (Continuous Sword Chain)

The basic attack chain executes as a continuous 5-hit martial flurry governed by strict client-server synchronization:

### 3.1 Timing & Recovery Loop (ADR-066)
* **Hits 1 through 4:** Execute at a rapid ~0.30s cadence (0.34s animation duration with 0.05s cross-fading).
* **Hit 5 (Finisher):** Executes with an emphatic 0.50s slash and enters a **2.20s recovery lockout**. During these 2.20s, all M1 clicks are ignored and the M1 HUD displays a recovery sweep.
* **Combo Reset Loop:** After the 2.20s recovery elapses, clicking M1 restarts the combo at **Hit 1**.
* **Mid-Combo Timeout:** If the attacker pauses for $> 1.2\text{s}$ before Hit 5, the combo sequence automatically resets to Hit 1.

### 3.2 Step Data & Hitbox Specifications

| Step | Animation Track | Cast Duration | Active Window | Cooldown | Open-World Damage | Arena Damage | Posture Damage | Hitbox Dimensions |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **M1_1** | `rbxassetid://129254042886405` | 0.34s | 0.24s | 0.30s | 26 | 18 | 14 | $5.4 \times 4.5 \times 6.2$ studs |
| **M1_2** | `rbxassetid://78342794513338` | 0.34s | 0.24s | 0.30s | 28 | 20 | 16 | $5.6 \times 4.5 \times 6.4$ studs |
| **M1_3** | `rbxassetid://133701354257850` | 0.34s | 0.24s | 0.30s | 32 | 22 | 18 | $6.0 \times 5.0 \times 6.6$ studs |
| **M1_4** | `rbxassetid://140582503077234` | 0.34s | 0.24s | 0.30s | 36 | 26 | 22 | $6.4 \times 5.0 \times 7.0$ studs |
| **M1_5** | `rbxassetid://111677132360566` | 0.50s | 0.40s | **2.20s** | 52 (Crit 100%) | 38 | 40 | $7.5 \times 6.0 \times 8.5$ studs |

### 3.3 Kinematic Footwork & Movement Dampening (ADR-067)
* **Speed Clamping:** While actively swinging, player movement speed is capped to **`11.5 studs/s`** (`math.min(baseSpeed, 11.5)`). Players moving at full sprint (36 studs/s) or walk (16 studs/s) are visibly slowed into a controlled sword stance, but **never stop moving**.
* **Smooth Speed Recovery:** Upon ending an attack sequence, WalkSpeed smoothly accelerates back to base/sprint speed over **`0.18s`** (`SPEED_RAMP_DURATION`) via an eased render transition.
* **Hybrid Facing:** Clicking M1 initiates an agile **`0.05s`** turn (`M1_TURN_TIME`) toward the camera aim direction. `AutoRotate` remains `false` across the chain, allowing players to circle-strafe enemies with WASD while keeping all sword slashes locked toward the target.
* **Physics Lunge Deletion:** Artificial forward impulses (`M1StepVelocity`) are completely removed; movement is 100% driven by player locomotion.

---

## 4. Active Skill Suite (Q, E, F)

### 4.1 Skill Q: Sword Tempest
* **Keybind:** `Q` | **Qi Cost:** 12% Max Qi | **Cooldown:** 6.5s
* **Cast Animation:** `rbxassetid://111677132360566` (0.35s duration, 0.30s windup delay).
* **Mechanics:** Dual-hitbox skill:
  1. Point-blank sweeping cleave ($12 \times 5 \times 8$ studs).
  2. Spawns 3 traveling crescent blade waves at 0.08s intervals traveling 70 studs/s over a 36-stud range.
* **Damage & Control:** Deals 60 open-world base damage (40 Arena), 30 Posture damage, and `Vector3.zero` knockback to shred targets in place.

### 4.2 Skill E: Piercing Void Thrust
* **Keybind:** `E` | **Qi Cost:** 15% Max Qi | **Cooldown:** 7.5s
* **Cast Animation:** `rbxassetid://93342220169849` (0.25s duration, 0.14s active duration).
* **Mechanics:** Fast, narrow piercing beam ($5 \times 5 \times 12$ studs) centered 6.5 studs in front of the cultivator.
* **Damage & Control:** Deals 75 open-world base damage (50 Arena), 45 Posture damage, and inflicts -14 studs linear knockback.

### 4.3 Ultimate F: 100-Slash Domain
* **Keybind:** `F` | **Qi Cost:** 20% Max Qi | **Cooldown:** 14.0s
* **Cast Animations:** Charge `rbxassetid://84905841522350` (0.12s), Slash `rbxassetid://111677132360566`.
* **Mechanics:** 
  1. Cultivator elevates +2.2 studs and flash-steps forward 32 studs at 145 studs/s.
  2. Detonates an 18-stud radius spherical cutting domain at the arrival point.
  3. Domain executes 5 slice ticks (every 0.08s, 12% damage / 15% posture each) followed by a finisher burst (40% damage / 50% posture with -22 studs knockback).
* **Damage & Control:** Deals 135 open-world base damage (85 Arena), 70 Posture damage, and locks the victim in hitstop.

---

## 5. Defense, Posture & Parry System

Combat features an authoritative defense engine managed by `CombatStateManager.luau` and `HitboxManager.luau`:

```text
Incoming Attack
    │
    ├── Attacker/Target in Safe Zone (55 studs)? ──> Negate Damage (0)
    │
    ├── Victim in Active I-Frames (Dash)? ─────────> Negate Damage (WasIframeDodged)
    │
    ├── Active Sword Clash (0.18s window, dot < -0.3)? ──> Negate Damage, Spawn Clash VFX
    │
    └── Victim Blocking (T key held, facing dot >= -0.25)?
            │
            ├── Elapsed Block Time <= 0.22s? ──────> [PERFECT PARRY]
            │                                        • 0 Damage
            │                                        • Attacker Stunned 1.20s
            │                                        • Defender Restores +8% Qi
            │                                        • Spawn Parry Clash VFX
            │
            └── Elapsed Block Time > 0.22s? ───────> [NORMAL BLOCK]
                    │                                • Drain Victim Posture (-PostureDmg)
                    │                                • Mitigate 70% Damage (30% Chip)
                    │                                • Mitigate 70% Knockback
                    │
                    └── Posture <= 0? ─────────────> [GUARD BROKEN]
                                                     • Stun Victim 2.0s
                                                     • +35% Damage Vulnerability
                                                     • Reset Posture to 30

Posture Regeneration: Posture regens at 22 pts/s after a 1.25s delay post-engagement when not blocking and not in CC.
Server Time Synchronization: Parry window checks evaluate Workspace:GetServerTimeNow() against client ping clamped to MaxPingTolerance = 0.18s.
6. Locomotion, Kinematics & Avatar Proportions
6.1 Heroic Avatar Scaling (ADR-065)
To eliminate miniature R6 character models in dense grass while avoiding oversized chibi heads, avatars are scaled authoritatively via AntiTripServer.server.luau:
Body Scale: character:ScaleTo(1.15) (15% larger than default R6, ~5.75 studs tall).
Head Reduction: Head visual mesh and all attached accessories/hair scaled down to 0.90 (10% smaller relative to the body).
Neck Alignment: Motor6D offset aligned to neck.C1 = CFrame.new(0, -0.45 * BODY_SCALE, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0) to eliminate collar floating gaps.
Anti-Trip Enforcement: FallingDown and Ragdoll humanoid states are permanently disabled; StepHeight = 2.0.
6.2 Locomotion Speeds
Open World: Walk = 16.0 studs/s | Sprint = 36.0 studs/s.
Sparring Arena: Walk = 14.0 studs/s | Sprint = 30.0 studs/s.
Attacking Dampen: Clamped to 11.5 studs/s during M1 swings.
Flight Surfing (V): Scales across 10 cultivation realms from 45.0 studs/s (Qi Condensation) to 185.0 studs/s (Immortal Ascension).
7. Network Authority & Damage Pipeline
7.1 Server Damage Formula
Open-world damage is computed authoritatively in FlyingSwordServer.luau:
Damage
=
⌊
(
WeaponBaseDamage
+
SkillBaseDamage
)
×
PowerMultiplier
×
CritMultiplier
⌋
Damage=⌊(WeaponBaseDamage+SkillBaseDamage)×PowerMultiplier×CritMultiplier⌋
WeaponBaseDamage
WeaponBaseDamage
: Base damage of equipped Jian (ItemConfig) multiplied by Samsara bonus (1 + min(0.20, cycles * 0.05)).
PowerMultiplier
PowerMultiplier
: Cultivation realm and order multiplier (CultivationConfig.GetPowerMultiplier(Realm, Order)), scaling from 1.0× to 2,800×.
CritMultiplier
CritMultiplier
: 1.75× damage. Rolled via random chance (20% on M1_1–4, 25% on Q/E, 30% on F, 100% on M1_5).
Arena Normalization: In duels, realm multipliers are bypassed; damage uses normalized ArenaDamage values.
7.2 Sword Intent System
Client Gauge: Tracked in SkillBarController.luau via IntentBarFrame.
Accumulation: +25 Intent per landed strike; decays at -8%/s after 2.5s out of combat.
Current Authority: Server rolls crits mathematically; full server-authoritative Intent spending is scheduled in Combat V1 hardening.
8. Weapon Progression Roster (10 Jian Roster — ADR-068)
The weapon ladder consists strictly of 10 non-elemental Chinese Jian straight swords with dedicated scabbards, capped at Legendary (Divine Grade):
Tier	Item ID	Authentic Name	Xianxia Rank	Core Visual Theme	Scabbard Materials
1	MortalIronJian	Refined Iron Jian	Common (Mortal)	Forged mortal iron, plain steel guard	Ash wood, raw leather binding
1	HonedSteelJian	Cloud Tempered Jian	Common (Mortal)	Folded carbon steel, brass fittings	Lacquered rosewood, brass mouth
2	BreezeWillowJian	Willow Leaf Jian	Uncommon (Earth)	Slender flexible spring steel blade	Green-stained bamboo, linen cord
2	VerdantPeakJian	Jade Mountain Jian	Uncommon (Earth)	Cold mountain iron, jade pommel inlay	Polished cedar, copper bands
3	ClearSkyJian	Azure Firmament Jian	Rare (Heaven)	High-purity spirit ore, sky-blue sheen	Midnight lacquer, silver chape
3	SilentAbyssJian	Deep Chasm Jian	Rare (Heaven)	Matte obsidian finish, resonant fuller	Dark ebony, dampened silk cord
4	MoonlitFrostJian	Crescent Frost Jian	Epic (Spirit)	Translucent spirit jade core, silver trim	White birch, carved cloud jade
4	DragonResonanceJian	Roaring Dragon Jian	Epic (Spirit)	Ancient tempered meteoric iron	Walnut core, brass dragon filigree
5	RadiantSovereignJian	Pure Intent Sovereign Jian	Legendary (Divine)	Pure luminous gold blade, talisman script	Imperial gold leaf, ivory fittings
5	VoidStarCleaverJian	Void Starlight Jian	Legendary (Divine)	Star-forged black iron, violet intent edge	Astral lacquer, braided silk harness