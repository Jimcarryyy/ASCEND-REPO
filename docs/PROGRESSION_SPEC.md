# ASCEND-V1 — CULTIVATION PROGRESSION & LOOT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md  
> **Scope:** Cultivation Realm Engine, Stat Allocation, Grade Rarity Budgeting, & Spirit Stone Drop Tables.

---

## 1. Cultivation Realm Engine & Experience Formula

Character progression is structured around Cultivation Realms instead of generic level numbers:

| Realm Tier | Level Range | Breakthrough Requirement | Unlocked Features (V1 Scope) |
| :--- | :--- | :--- | :--- |
| Mortal Body Tempering | Levels 1 – 10 | Base Meridian Awakening | Flying Sword basic attacks (M1/M2) |
| Qi Condensation | Levels 11 – 20 | Gathering Qi Pill + Tribulation Trial | Skill Slot Q (Wind Step Dodge + Qi Skill) |
| Foundation Establishment | Levels 21 – 40 (V2 Scope) | Foundation Pill + Heavenly Lightning | Skill Slot E (Archetype Skill) |
| Golden Core | Levels 41 – 60 (V2 Scope) | Core Formation Dan + Boss Trial | Skill Slot R (Ultimate Skill) |

### Experience Formula
Required Experience to reach Level N from Level N-1 is calculated on the server:

  RequiredXP(N) = math.floor(100 * ((N - 1) ^ 1.85) + 50)

Each level up awards +3 Unallocated Stat Points.

---

## 2. Cultivation Primary Stat Attributes

Players manually allocate stat points into 4 primary attributes via the Character Modal:

| Stat Name | Primary Effect | Secondary Effect | Scaling Formula |
| :--- | :--- | :--- | :--- |
| Physique (Body Tempering) | Physical Damage & Health | Heavy Attack Impact | +2.5% Damage, +10 Max Health per point |
| Qi Capacity (Spiritual Energy) | Qi Reserve Size & Skill Damage | Qi Recovery Rate | +15 Qi Points, +3.0% Skill Damage per point |
| Agility (Wind Walk) | Attack Speed & Movement | Dodge i-Frame Window | +0.4% Attack Speed, +0.2% Move Speed per point |
| Soul Force (Consciousness) | Critical Hit Rate | Critical Damage Multiplier | +0.3% Crit Rate, +0.5% Crit Damage per point |

---

## 3. Cultivation Grade Rarity Pipeline

All items scale their stats using a base budget multiplied by a Cultivation Grade Factor:

| Cultivation Grade | Hex Color Code | Stat Budget Multiplier | Base Drop Rate Weight |
| :--- | :--- | :--- | :--- |
| Mortal Grade | #FFFFFF (White) | 1.00x | 60.0% (6000) |
| Earth Grade | #38E54D (Green) | 1.25x | 25.0% (2500) |
| Heaven Grade | #2192FF (Blue) | 1.60x | 10.0% (1000) |
| Spirit Grade | #9C2C77 (Purple) | 2.10x | 4.0% (400) |
| Sacred Grade | #FFD700 (Gold) | 2.80x | 0.9% (90) |
| Immortal Grade | #FF1E1E (Crimson) | 3.80x | 0.1% (10) |

---

## 4. Server-Authoritative Loot Engine & Pity Counter

Loot generation occurs strictly on the server when a mob or Demon Boss entity dies:

1. Mob Death Trigger: Server verifies mob hit history and tags participating players who dealt >= 5% total damage.
2. Roll Currency: Award Spirit Stones scaled by mob level.
3. Roll Drop Table: Iterate through the entity's Drop Table array using weighted random selection:
   TotalWeight = Sum of all Item Weights
   Roll = math.random(1, TotalWeight)
4. Boss Pity Counter: Every Demon Boss kill increments the player's PityCounter by +1. At 50 kills without a Sacred/Immortal drop, the next kill forcefully awards a Sacred Grade artifact and resets PityCounter = 0.