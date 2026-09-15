# ASCEND — Authoritative Combat Specification

> **Technical Specification Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. Combat Engine Overview

ASCEND features a high-fidelity, server-authoritative martial sword combat system built exclusively on the Roblox R6 avatar standard. The combat philosophy emphasizes rapid reaction times, fluid chaining, directional precision, and dynamic visual feedback.

### Core Architectural Pillars
- **Single-Weapon Paradigm (ADR-038):** All martial combat is executed through **Flying Swords**. All 8 weapon tiers share standardized R6 animations while dynamically attuning visual effects, trails, slash arcs, and damage numbers via `ItemConfig.GetWeaponPalette(weaponId)`.
- **Authoritative Hit Validation:** Hitboxes are cast and validated strictly on the server (`HitboxManager.luau`) using spatial box/sphere overlap queries (`WorldRoot:GetPartBoundsInBox`). Latency compensation verifies attacker position against network ping buffers.
- **Unified Defense Matrix:** Seamless transitions between free movement, sprinting, high-velocity flash-stepping, directional guarding, and frame-perfect parrying.
- **Sword Intent Gauge:** A four-tiered kinetic momentum system that rewards continuous offensive pressure with an empowered, armor-cleaving critical strike at 100% gauge.

---

## 2. Complete Keybind & Input Architecture

Governed by `InputController.luau`, `WeaponManager.luau`, and `FlyingSwordServer.luau`:

| Input Key | Combat Action | Mechanical Execution | Resource Cost | Cooldown |
| :---: | :--- | :--- | :---: | :---: |
| **`M1`** | **5-Hit Broadsword Combo** | Sequential light/heavy sword chain. Dampens speed to `WalkSpeed = 8`. | None | $0.20\text{s} - 0.35\text{s}$ |
| **`Left Control`** | **Sprint Toggle** | Toggles Walk $\leftrightarrow$ Sprint with dynamic FOV ($70^\circ \rightarrow 76^\circ$). | None | None |
| **`Left Shift`** | **Qi Flash-Step Dash** | 150 studs/s directional burst over 0.16s with +1.2 stud elevation lift. | 3% Qi | $3.0\text{s}$ |
| **`T` (Hold)** | **Guard (Block)** | Frontal 180° arc reducing damage by 80% and knockback by 70%. | Posture | None |
| **`T` (Tap $<0.22\text{s}$)** | **Perfect Parry** | 100% damage negation, 0.5s attacker stagger, +5% Qi restoration. | None | None |
| **`C`** | **Qi Meditation** | Seated cultivation. Restores 10.0% Qi/sec. Locks all combat inputs. | None | None |
| **`R`** | **Draw / Sheathe Weapon** | Toggles weapon weld between Hand Grip and Back Sheath Mount. | None | $0.5\text{s}$ |
| **`V`** | **Sword Flight Mode** | Mounts flying sword for 3D aerial navigation (75 studs/s). | None | None |
| **`B`** | **Realm Breakthrough** | Attempts cultivation breakthrough when Cultivated Qi is 100%. | All Qi | Variable |
| **`Q`** | **Skill: Sword Tempest** | 360° melee cleave + 3 traveling sawblade projectiles. | 15% Qi | $3.5\text{s}$ |
| **`E`** | **Skill: Piercing Void Thrust** | High-velocity penetrating sword thrust beam (80 base dmg). | 12% Qi | $5.0\text{s}$ |
| **`F`** | **Ultimate: 100-Slash Domain** | Forward flash + mid-air slash + 36-stud 100-slash sphere detonation. | 20% Qi | $5.5\text{s}$ |

---

## 3. Basic Attack Combo (5-Hit Chain)

Configured in `FlyingSwordConfig.luau`, the M1 chain progresses through 5 sequential sword swings. Pausing longer than **1.3 seconds** between hits resets the sequence to Hit 1.

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
Movement & Mechanics During Swings
Speed Dampening: The player's Humanoid.WalkSpeed is clamped to 8 studs/s during the windup and active window of every swing to prevent glide-attacking. Normal speed restores upon entering the recovery phase.
Combo Memory Window: If the player attacks again during the recovery window, the next swing is buffered and fires immediately upon recovery completion.
4. Sword Intent Momentum System
The Sword Intent system measures offensive martial rhythm.
code
Text
[0% Intent] ──(+25% per M1 Hit)──> [100% FULL INTENT]
                                            │
                             Next landed strike consumes bar:
                             - 1.75× Damage Multiplier
                             - Golden Critical Floating Damage Text
                             - Hitstop: 0.08s (Target) / 0.04s (Self)
                             - Screen Shake: 0.45 intensity
Generation: Every landed M1 strike generates +25% Sword Intent (4 landed strikes achieve maximum 100% Intent). Whiffed attacks do not generate intent.
Empowered Strike: Upon reaching 100% Intent, the next landed attack (M1 or Skill) consumes the entire gauge, amplifying final damage by 
1.75
×
1.75×
.
Decay: If no attacks land for 6.0 seconds, the Sword Intent gauge decays linearly at 
20
%
/
sec
20%/sec
.
5. Defensive Mechanics: Guard, Posture, and Parry
The defensive system uses a dedicated Posture Bar (Base: 100 Posture points, regens at 
15
 pts/sec
15 pts/sec
 after 2.0s of non-guarding).
1. Guarding (Holding T)
Damage Mitigation: Incoming damage through the 180° frontal arc is reduced by 80% (the player takes only 20% chip damage).
Knockback Mitigation: Knockback velocity is reduced by 70%.
Posture Depletion: Blocking an attack drains Posture points equal to the incoming attack's PostureDamage.
Visuals: Attaches the defensive ActiveShield VFX to the character model and spawns muted silver impact sparks (BlockSparks).
2. Perfect Parry (Tapping T within 0.22s)
Execution: Pressing T opens a strict 0.22-second parry window. If hit within this window:
Damage Negation: 100% damage negated (0 damage taken).
Attacker Stagger: The attacking player or mob is stunned for 0.50 seconds, interrupting their combo chain.
Qi Surge: Restores +5% Maximum Qi to the defender.
Visuals & Audio: Plays PARRY_CLASH_SOUND_ID (rbxassetid://5649495764), triggers gold particle clash (ParryClash), and applies hitstop (
0.08
s
0.08s
).
3. Guard Break (Posture Depletion)
When Posture reaches 0 while holding block, the guard is broken.
Penalty: The player is locked into a 1.80-second stagger (GuardBroken state), completely disabling movement, attacks, and defense.
Critical Vulnerability: All attacks received during guard break bypass damage mitigation and deal full unmitigated damage.
Visuals: Triggers ShieldBreakEffects at the character's root and renders crimson "GUARD BROKEN!" floating combat text.
6. Martial Skills Architecture
All skills are balanced for both Open World (PvE / Cultivation scaling) and Arena (PvP / Normalized competitive scaling).
Skill Q — Sword Tempest (Purple Sawblade Cleave)
Concept: Close-quarters area sweep that erupts into three traveling slicing discs.
Resource & Cooldown: 15% Max Qi | 3.5s Cooldown.
Hitbox 1 (Point-Blank Sweep): 360° sphere around caster, 
12
×
6
×
12
 studs
12×6×12 studs
. Deals 25 base damage (18 posture damage).
Hitbox 2 (Traveling Blades): 3 forward sawblades traveling 65 studs/s over 30 studs. Deals 18 damage per blade (up to 54 additional damage).
Knockback: 
(
0
,
8
,
−
18
)
(0,8,−18)
.
Skill E — Piercing Void Thrust
Concept: High-velocity linear sword thrust beam that pierces through enemy formations.
Resource & Cooldown: 12% Max Qi | 5.0s Cooldown.
Hitbox: Elongated forward box, 
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
Damage: 80 base damage (220 Arena damage), 50 posture damage.
Knockback: Strong directional displacement: 
(
0
,
10
,
−
40
)
(0,10,−40)
.
Projectile Velocity: 120 studs/s beam cast with weapon-attuned color palette trails.
Skill F — 100-Slash Flash Domain (Ultimate)
Concept: Single-click execution ultimate. The cultivator lifts into the air, flashes forward through targets, and detonates a 36-stud sphere of 100 mid-air sword slashes.
Resource & Cooldown: 20% Max Qi | 5.5s Cooldown.
Phase 1 (The Flash): Caster elevates +2.2 studs into Freefall, disables character collision, and dashes forward at 145 studs/s over 0.22s.
Phase 2 (The Domain Detonation): Spawns a 
36
×
36
×
36
 stud
36×36×36 stud
 spherical domain at the flash terminus.
Damage: 5 rapid hit intervals × 20 base damage = 100 total base damage (350 Arena damage), 15 posture damage per interval.
Camera & Hitstop: Heavy screen shake (0.65 intensity), 0.06s hitstop per tick, and radial chromatic aberration.
7. Traversal & Mobility Systems
1. Qi Flash-Step Dash (Left Shift)
Mechanics: Directional impulse of 150 studs/s lasting 0.16 seconds (~20 studs of ground coverage).
Anti-Trip Technology: Elevates the character +1.2 studs vertically, briefly forces Enum.HumanoidStateType.Freefall, and attaches an upright AlignOrientation constraint to prevent ragdoll tripping on uneven terrain.
Resource & Cooldown: 3% Max Qi | 3.0s Cooldown.
State Preservation: If W, A, S, or D are held at the end of the dash, the character immediately returns to Sprinting without stutter.
2. Flying Sword Flight Mount (V)
Mounting: Toggles a flying sword under the player's feet, switching to 3D aerial navigation mode.
Flight Speed: 75 studs/s in the camera look vector.
Altitude Stabilizer: Automatic downward raycasting maintains a minimum 6.5 stud ground cushion.
Obstacle Buffer: Forward raycasting applies reverse impulse if the player approaches terrain or obstacles closer than 8.5 studs.
Controls: Spacebar to ascend, C or Left Control to descend, direction keys to steer.
8. Damage & Scaling Mathematical Formulas
Final damage dealt in open-world combat is calculated server-side in FlyingSwordServer.luau:
Raw Damage
=
(
Skill Base Damage
+
Weapon Base Damage
)
×
Cultivation Power Multiplier
Raw Damage=(Skill Base Damage+Weapon Base Damage)×Cultivation Power Multiplier
Where:
Skill Base Damage
Skill Base Damage
 comes from FlyingSwordConfig.Skills[skillKey].Damage (or Combo step damage).
Weapon Base Damage
Weapon Base Damage
 comes from ItemConfig.Items[weaponId].Damage (
15
→
1
,
000
15→1,000
).
Cultivation Power Multiplier
Cultivation Power Multiplier
 is retrieved from CultivationConfig.GetPowerMultiplier(player):
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
Mitigation Modifiers Applied at Target
code
Text
If Target Parried:
    Final Damage = 0

Else If Target Guarding (Frontal 180°):
    Final Damage = Raw Damage × 0.20
    Posture Damage Applied = Skill.PostureDamage

Else:
    If Attacker Intent == 100%:
        Final Damage = Raw Damage × 1.75
    Else:
        Final Damage = Raw Damage
9. Network Remote Architecture (RemoteEvents.luau)
Combat communication is routed through central RemoteEvents:
Remote Name	Direction	Payload Structure	Trigger Scenario
CombatActionRemote	Client 
→
→
 Server	{ Action = "Attack" | "Skill" | "BlockStart" | "BlockEnd" | "Dash" | "DrawToggle", SkillKey = string, AimCFrame = CFrame, TargetPosition = Vector3 }	Fired when local player inputs an action.
CombatActionRemote	Server 
→
→
 Client	(attackerPlayer, actionType, payloadTable)	Replicated to nearby clients to render animations, sounds, and particle trails.
CombatVFXRemote	Server 
→
→
 Client	{ EffectType = "DamageNumber" | "ParryClash" | "BlockSparks" | "HitVFX", Position = Vector3, Damage = number, IsCrit = boolean, WasBlocked = boolean, WasGuardBroken = boolean }	Fired to render combat VFX and floating text.
SwordFlightRemote	Client 
↔
↔
 Server	{ Action = "Mount" | "Dismount" | "UpdateFlightState", Velocity = Vector3 }	Synchronizes sword mounting and aerial velocity.