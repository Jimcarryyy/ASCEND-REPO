# ASCEND — Authoritative Combat Specification

> **Technical Specification Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Engine State:** Verified Stable (5-Hit Combo, Posture/Parry, 0-Knockback Q, Flash-Step F)

---

## 1. Combat Engine Architecture

ASCEND features a high-fidelity, server-authoritative martial sword combat system built exclusively on the Roblox R6 avatar standard. The combat design prioritizes reactive martial pacing, directional precision, frame-accurate parrying, and visual readability.

### Core Architectural Pillars
- **Single-Weapon Paradigm (ADR-038):** All martial combat is executed through **Flying Swords**. All 8 weapon tiers share standardized R6 animations while dynamically attuning visual effects, trails, slash arcs, and damage numbers via `ItemConfig.GetWeaponPalette(weaponId)`.
- **Authoritative Hit Validation (`HitboxManager.luau`):** Hitboxes are cast and validated strictly on the server using spatial overlap queries (`WorldRoot:GetPartBoundsInBox`). Latency compensation calculates position buffering to prevent phantom hits.
- **Unified Defense Matrix:** Seamless transitions between sprinting, high-velocity directional flash-stepping, directional guarding, and frame-perfect parrying.
- **Sword Intent Momentum:** A kinetic meter rewarding continuous offensive pressure, culminating in an armor-cleaving critical strike at 100% Intent.
- **Clutter-Free Visuals (ADR-072):** Combat text displays pure numeric damage in `Enum.Font.Arcade` ("Press Start 2P"). All text badges ("CRIT!", "PARRY!", Intent labels) are purged.

---

## 2. Complete Keybind & Input Architecture

Governed by `InputController.luau`, `WeaponManager.luau`, and `FlyingSwordServer.luau`:

| Input Key | Combat Action | Mechanical Execution | Resource Cost | Cooldown |
| :---: | :--- | :--- | :---: | :---: |
| **`M1`** | **5-Hit Broadsword Combo** | Sequential light/heavy sword chain. Dampens speed to `WalkSpeed = 8`. Locks `AutoRotate`. | None | $0.20\text{s} - 0.35\text{s}$ |
| **`Left Control`** | **Sprint Toggle** | Toggles Walk (13.5 studs/s) $\leftrightarrow$ Sprint (36 studs/s open world / 30 arena). | None | None |
| **`Left Shift`** | **Qi Flash-Step Dash** | 4-way camera-relative burst over 0.16s with Shunpo vanish/reappear VFX. | 3% Qi | $3.0\text{s}$ |
| **`T` (Hold)** | **Guard (Block)** | Frontal 180° arc reducing damage by 80% and knockback by 70%. | Posture | None |
| **`T` (Tap $<0.22\text{s}$)** | **Perfect Parry** | 100% damage negation via `Workspace:GetServerTimeNow()`, 0.5s stagger, +5% Qi. | None | None |
| **`C`** | **Qi Meditation** | Seated cultivation restoring 10.0% Qi/s. Gated behind `InCombat == false`. | None | None |
| **`R`** | **Draw / Sheathe Sword** | Toggles weapon weld between Hand Grip and upper back Torso Sheath. | None | $0.5\text{s}$ |
| **`V`** | **Sword Flight Mode** | Mounts flying sword for 3D aerial navigation (48+ studs/s realm-scaled). | 25 Qi/s | None |
| **`B`** | **Realm Breakthrough** | Attempts cultivation breakthrough when Cultivated Qi reaches 100%. | All Qi | Variable |
| **`Q`** | **Skill: Sword Tempest** | 360° cleave + 3 sawblades. Knockback zeroed (`Vector3.zero`) to slice in place. | 15% Qi | $3.5\text{s}$ |
| **`E`** | **World Interact / Thrust** | World interactions (Altar, NPCs). When drawn: Piercing Void Thrust beam. | 12% Qi | $5.0\text{s}$ |
| **`F`** | **Ultimate: Flash Domain** | 28-stud instant Celestial Flash-Step + mid-air slice + 36-stud 100-slash sphere. | 20% Qi | $5.5\text{s}$ |
| **`H`** | **Heavenly Codex** | Opens feature guide and sect guidebook (`CodexGui`). | None | None |
| **`P`** | **Character Stats Sheet** | Toggles character stats modal (`CharacterStatsGui`). | None | None |

---

## 3. Basic Attack Combo (5-Hit Chain)

Configured in `FlyingSwordConfig.luau`, the M1 chain progresses through 5 sequential sword swings. Pausing longer than **1.3 seconds** resets the sequence to Hit 1:

```text
[Hit 1] ──(0.26s)──> [Hit 2] ──(0.26s)──> [Hit 3] ──(0.29s)──> [Hit 4] ──(0.31s)──> [Hit 5] (Finisher)
  18 Dmg               19 Dmg               21 Dmg               23 Dmg               28 Dmg + Knockback
Frame Data & Hitbox Dimensions
Combo Step	Base Dmg	Posture Dmg	Windup	Active Window	Recovery	Total Time	Hitbox Size (
W
×
H
×
D
W×H×D
)	Offset (
X
,
Y
,
Z
X,Y,Z
)	Knockback Vector
Hit 1	18	12	0.08s	0.14s	0.18s	0.40s	
6.5
×
6.0
×
7.5
 studs
6.5×6.0×7.5 studs
(
0
,
0
,
−
3.8
)
(0,0,−3.8)
None
Hit 2	19	14	0.08s	0.14s	0.18s	0.40s	
6.5
×
6.0
×
7.5
 studs
6.5×6.0×7.5 studs
(
0
,
0
,
−
3.8
)
(0,0,−3.8)
None
Hit 3	21	16	0.09s	0.15s	0.20s	0.44s	
7.0
×
6.0
×
8.0
 studs
7.0×6.0×8.0 studs
(
0
,
0
,
−
4.0
)
(0,0,−4.0)
None
Hit 4	23	18	0.09s	0.15s	0.22s	0.46s	
7.0
×
6.0
×
8.0
 studs
7.0×6.0×8.0 studs
(
0
,
0
,
−
4.0
)
(0,0,−4.0)
None
Hit 5	28	25	0.12s	0.18s	0.35s	0.65s	
8.0
×
6.5
×
9.0
 studs
8.0×6.5×9.0 studs
(
0
,
0
,
−
4.5
)
(0,0,−4.5)
(
0
,
12
,
−
28
)
(0,12,−28)
Combo Mechanics & Kinematics
Speed Dampening: Humanoid.WalkSpeed is clamped to 8 studs/s during the windup and active swing to prevent glide-attacking. Normal locomotion restores upon entering recovery.
AutoRotate Locking: Humanoid.AutoRotate is temporarily disabled during swings to prevent character twitching caused by RootJoint keyframe rotation.
Combo Memory Window: Inputs buffered during the recovery window fire automatically upon recovery completion.
4. Sword Intent Momentum System
The Sword Intent system measures martial flow:
code
Text
[0% Intent] ──(+25% per Landed M1)──> [100% FULL INTENT]
                                              │
                              Next landed strike consumes bar:
                              - 1.75× Damage Multiplier
                              - Golden Critical Number Popup (Arcade Font)
                              - Hitstop: 0.08s (Target) / 0.04s (Self)
                              - Subtle Screen Shake (0.45 intensity)
Generation: Landed M1 hits grant +25% Sword Intent (4 strikes to fill). Whiffs grant 0 Intent.
Empowered Strike: At 100% Intent, the next landed attack (M1 or Skill) consumes the entire gauge, multiplying total damage by 1.75×.
Decay: After 2.5s of inactivity, Intent decays linearly at 20%/s.
5. Defensive Mechanics: Guard, Posture, and Parry
The defensive system uses a dedicated Posture Bar (Base: 100 Posture points, regens at 15 pts/s after 2.0s of non-guarding).
1. Guarding (Holding T)
Damage Mitigation: Incoming attacks inside the 180° frontal arc deal only 20% chip damage (80% mitigation).
Knockback Mitigation: Knockback velocity is reduced by 70%.
Posture Depletion: Blocking drains Posture equal to the attack's PostureDamage.
2. Perfect Parry (Tapping T within 0.22s)
Execution: Opening guard creates a strict 0.22s parry window calculated using server time synchronization (Workspace:GetServerTimeNow()).
Damage Negation: 100% damage negated.
Attacker Stagger: Attacker is stunned for 0.50 seconds (FlyingSword.Stun animation rbxassetid://121973766317438).
Qi Surge: Defender restores +5% Maximum Qi.
Visuals & Audio: Detonates deflection sparks and plays parry clash audio (rbxassetid://9114223175).
3. Guard Break (Posture Depleted)
Stagger Penalty: When Posture reaches 0 while guarding, the player is locked into a 1.80-second GuardBroken state.
Full Vulnerability: All attacks received during guard break deal 100% unmitigated damage.
6. Martial Skills Architecture
Skill Q — Sword Tempest (Sawblade Cleave)
Concept: Point-blank area sweep that fires three traveling razor sawblades.
Resource & Cooldown: 15% Max Qi | 3.5s Cooldown.
Hitbox 1 (Point-Blank Sweep): 360° sphere, 
12
×
6
×
12
 studs
12×6×12 studs
. Deals 25 base damage.
Hitbox 2 (Traveling Blades): 3 forward sawblades traveling 65 studs/s over 30 studs. Deals 18 damage per blade (up to 54 total).
Knockback: Zeroed (Vector3.zero) to slice enemies in place without knocking them away.
Skill E — Piercing Void Thrust
Concept: High-velocity linear sword thrust beam piercing enemy ranks.
Resource & Cooldown: 12% Max Qi | 5.0s Cooldown.
Hitbox: Forward box 
8
×
8
×
25
 studs
8×8×25 studs
 centered at 
(
0
,
0
,
−
12.5
)
(0,0,−12.5)
 relative to aim direction.
Damage: 80 base damage, 50 posture damage, 
(
0
,
10
,
−
40
)
(0,10,−40)
 knockback.
Skill F — 100-Slash Flash Domain (Ultimate)
Concept: Instant spatial blink execution ultimate.
Resource & Cooldown: 20% Max Qi | 5.5s Cooldown.
Phase 1 (Celestial Flash-Step): 28-stud instant blink slash phasing through targets without physics tripping.
Phase 2 (Domain Detonation): Detonates a 
36
×
36
×
36
 stud
36×36×36 stud
 spherical domain at the blink destination.
Damage: 5 hit intervals × 20 base damage = 100 total base damage (scales with Realm and Sword), 15 posture damage per interval.
7. Traversal & Mobility Systems
1. Qi Flash-Step Dash (Left Shift)
Mechanics: 4-way camera-relative directional impulse of 150 studs/s lasting 0.16 seconds (~20 studs distance) with Shunpo vanish/reappear VFX.
Anti-Trip Technology: Elevates the character +1.2 studs, briefly triggers Freefall, and attaches an upright AlignOrientation constraint to eliminate ragdoll tripping on uneven terrain.
Resource & Cooldown: 3% Max Qi | 3.0s Cooldown.
2. Flying Sword Flight Mode (V)
Mounting: Mounts the flying sword under the cultivator's feet for 3D aerial flight.
Dynamic Velocity Scaling: Flight speed scales with Cultivation Realm (48 studs/s at Foundation Establishment).
Energy Drain & Safety: Imposes a continuous 25 Qi/s drain and pauses passive Qi recovery. Reaching 0 Qi or receiving combat damage forces an immediate dismount.
8. Damage Calculation & Scaling
Calculated server-side in FlyingSwordServer.luau:
Raw Damage
=
round
(
(
Skill Base Damage
+
Weapon Base Damage
)
×
Cultivation Power Multiplier
)
Raw Damage=round((Skill Base Damage+Weapon Base Damage)×Cultivation Power Multiplier)
Weapon Base Damage: Retrieved from ItemConfig.Items[weaponId].Damage (15 to 1,000).
Cultivation Power Multiplier: Retrieved from CultivationConfig.GetPowerMultiplier(player):
Multiplier
=
HealthMultiplier
Realm
×
[
1
+
(
Order
−
1
)
×
0.15
]
Multiplier=HealthMultiplier 
Realm
​
 ×[1+(Order−1)×0.15]
Mitigation Rules
Target Parried: Final Damage = 0.
Target Guarding: Final Damage = 
Raw Damage
×
0.20
Raw Damage×0.20
 (Posture damage applied).
Intent Critical (100% Intent): Final Damage = 
Raw Damage
×
1.75
Raw Damage×1.75
.
Sect Safe Zone: Final Damage = 0 (Peace Zone enforced).
Wilderness Karmic Retribution: Attackers of lower-realm peaceful cultivators suffer 75% damage penalty and 50% damage reflection.
9. Network Remote Architecture (RemoteEvents.luau)
Combat networking uses strictly typed --!strict remotes:
Remote Name	Direction	Payload Structure	Purpose
CombatActionRemote	Client 
→
→
 Server	{ Action = "Attack" | "Skill" | "BlockStart" | "BlockEnd" | "Dash", SkillKey = string?, AimCFrame = CFrame? }	Primary combat input dispatch.
CombatActionRemote	Server 
→
→
 Client	(attackerPlayer, actionType, payloadTable)	Replicates animations, sounds, and particle cues to nearby clients.
CombatVFXRemote	Server 
→
→
 Client	{ EffectType = "DamageNumber" | "ParryClash" | "BlockSparks", Position = Vector3, Damage = number?, IsCrit = boolean? }	Spawns arcade damage popups and parry sparks.
SwordFlightRemote	Client 
↔
↔
 Server	{ Action = "Mount" | "Dismount", Velocity = Vector3? }	Synchronizes flight mount transitions and velocity.