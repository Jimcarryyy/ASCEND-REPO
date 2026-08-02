# ASCEND-V1 — CULTIVATION COMBAT SYSTEM SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md  
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