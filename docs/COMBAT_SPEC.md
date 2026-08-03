# ASCEND-V1 — CULTIVATION COMBAT SYSTEM SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md
> **Scope:** Server-Authoritative Combat Engine, Hitbox Pipelines, Combos, Defensive Mechanics, & Qi Formulas.

---

## 1. Security Architecture & Server Intent Pipeline

Combat operates on an Intent-Execution Pipeline to prevent exploit manipulation:

[CLIENT]                                    [SERVER]
  |                                            |
  +--- 1. Press M1 (Fire AttackIntent) ------->|
  |                                            |-- 2. Validate Cooldowns (os.clock())
  |                                            |-- 3. Validate Qi Reserves & Stun State
  |                                            |-- 4. Execute Shapecast / Spatial Query
  |                                            |-- 5. Apply Damage & Qi Status Effects
  |<-- 6. Replicate Visual Effects / Hits -----|

---

## 2. Server Hitbox Detection Pipeline

Hitboxes are computed strictly on the server during the active damage frame window using WorldRoot:Blockcast or WorldRoot:Shapecast.

* Shapecast Type: CFrame-oriented Caster (WorldRoot:Blockcast or WorldRoot:Spherecast).
* CollisionGroup: "CombatEntities"
* Hit Register Prevention: Each attack swing maintains a HitTable dictionary on the server. An enemy entity can only be damaged once per swing iteration.

---

## 3. Combo Mechanics & Timelines

### Light Attack String (M1 Flying Sword / Martial Chain)
A standard weapon features a 4-hit light combo sequence:

| Combo Step | Windup (Prep) | Damage Window | Recovery Window | Combo Buffer Window | Damage Multiplier | Impact Effect |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| M1_1 | 0.15s | 0.10s | 0.20s | 0.15s – 0.35s | 1.0x Base | Light Flinch |
| M1_2 | 0.12s | 0.10s | 0.20s | 0.15s – 0.35s | 1.0x Base | Light Flinch |
| M1_3 | 0.14s | 0.10s | 0.22s | 0.15s – 0.38s | 1.2x Base | Medium Flinch |
| M1_4 (Finisher) | 0.25s | 0.15s | 0.45s | None (Resets) | 1.8x Base | Knockback + Stun (0.8s) |

### Heavy Attack (M2 Mountain Splitting Attack)
* Windup Time: 0.45 seconds (Telegraphed windup animation).
* Qi Cost: 25 Qi Points.
* Special Attribute: Guard Break. Deals 2.5x damage against blocking targets and breaks guard state.

---

## 4. Defensive & Reaction Mechanics

                       [INCOMING ATTACK HITBOX]
                                  |
        +-------------------------+-------------------------+
        |                         |                         |
        v                         v                         v
 [TARGET WIND STEP]       [TARGET BAGUA SHIELD]      [TARGET QI BLOCK]
 (i-Frame Active)          (In Parry Window)          (Holding Block)
        |                         |                         |
        v                         v                         v
  0 Damage Taken            0 Damage Taken            70% Damage Reduction
Attacker Continues        Attacker Stunned (1.2s)     Qi Drained
                          Defender +10 Qi Points

### A. Wind Step / Flash Step (Dodge)
* Activation: Keypress (Shift / Space).
* i-Frame Duration: 0.25 seconds starting immediately at activation frame.
* Cooldown: 1.2 seconds | Cost: 20 Qi Points.

### B. Bagua Shield (Parry)
* Activation Window: First 0.18 seconds of pressing Block (F).
* Success Outcome: Attacker suffers Qi Deviation Stun for 1.2 seconds; defender receives 0 damage and recovers +10 Qi Points.

---

## 5. Damage & Stat Calculations

- RawDamage = BaseWeaponDamage * (1 + (Physique * 0.025))
- CritRoll = math.random() <= (SoulForce * 0.003)
- FinalDamage = CritRoll ? (RawDamage * (1.5 + (SoulForce * 0.005))) : RawDamage
- DamageTaken = FinalDamage * (100 / (100 + TargetArmor))


# Combat Specification — ASCEND

Technical specification for ASCEND's server-authoritative combat engine, keybind mappings, multi-weapon systems, and visual feedback pipeline.

---

## 🎮 Classical ARPG Control Mappings

* **LMB**: Light Attack M1 Combo String (Steps 1 → 2 → 3 → Finisher 4).
* **F**: Heavy Attack / Parry / Heavy Slam.
* **Q**: Special Technique 1 (*Sword Tempest / Parry Qi Shield / Hundred Palms 360*).
* **E**: Special Technique 2 (*Telekinesis Thrust / Whirlwind Sweep / Mountain Palm*).
* **R**: Ultimate Technique (*Sword Barrage / Dragon Charge / Earth Shattering Ground Slam*).
* **Shift**: Directional Physical Dodge / Windstep Dash (`AssemblyLinearVelocity` impulse).
* **RMB**: Reserved 100% for free Camera Rotation (zero attack firing conflict).
* **1, 2, 3**: Live Weapon Swapping (*1 = Flying Sword, 2 = Spear, 3 = Gauntlet*).
* **G, B**: Qi Meditation Toggle and Realm Breakthrough.

---

## ⚔️ Weapon Combat Systems

### 1. Flying Sword
* **M1 Combo**: 4-step telekinesis slash string (15 → 15 → 20 → 35 damage).
* **F Heavy Slam**: Downward heavy shockwave (40 damage).
* **Q Sword Tempest**: 360° swirling blade vortex (60 damage).
* **E Telekinesis Thrust**: Forward piercing lunge (80 damage).
* **R Sword Barrage**: Multi-blade rain strike (120 damage).

### 2. Spear
* **M1 Combo**: 4-step thrust string with forward lunge physics (18 → 18 → 24 → 42 damage 360° sweep).
* **F Vaulting Slam**: Airborne impact slam (45 damage).
* **Q Serpent Thrust**: High-speed forward lunge (65 damage).
* **E Whirlwind Sweep**: Wide 360° clearing sweep (85 damage).
* **R Dragon Spirit Charge**: Piercing dragon charge (135 damage).

### 3. Gauntlets (Martial Arts)
* **M1 Combo**: 4-step rapid punch string (14 → 14 → 22 → 38 damage uppercut).
* **F Qi Shield Parry**: Defensive stance / block.
* **Q Hundred Palms**: 360° rapid palm barrage (75 damage).
* **E Mountain Palm**: Heavy forward shockwave thrust (90 damage).
* **R Ground Slam**: Earth shattering slam with vertical launch knockback (140 damage).

---

## 🛡️ Hitbox Engine & Attachment Architecture

* **Server Hitboxes** (`HitboxManager.luau`): Server-authoritative `Workspace:GetPartBoundsInBox` spatial queries. Applies server damage and linear velocity physics knockbacks.
* **Motor6D Attachment** (`WeaponManager.luau`): Attaches custom `MeshPart` / `Model` / `Tool` handles directly to `RightHand.RightGripAttachment` via `Motor6D`. Supports custom `Grip` attachments, native `Tool.Grip`, and procedural Qi energy placeholders.
* **Client Juice & VFX** (`CombatVFXController.luau`):
  * **Floating Damage Numbers**: Animated 3D BillboardGuis over damaged enemies.
  * **Camera Shake**: Impulse-driven camera shake on heavy attacks.
  * **White Slash Trails**: Native Roblox `Trail` drawing crisp white 3D slash arcs during swings.