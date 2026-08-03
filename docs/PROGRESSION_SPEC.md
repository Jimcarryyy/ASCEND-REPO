---

# File 11: `docs/PROGRESSION_SPEC.md`

```markdown
# ASCEND-V1 — CULTIVATION PROGRESSION & LOOT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Cultivation Realm Engine, Alchemy Recipes, Stat Allocation, Grade Rarity Budgeting, & Spirit Stone Drop Tables.

---

## 1. Cultivation Realm Hierarchy

| Realm Name | Tier | Max Qi Reservoir | Gather Rate (Qi/sec) | Health Multiplier | Aura Color |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Qi Condensation** | 1 | 100 Qi | 15 Qi/s | 1.0x (100 HP) | Cyan (`#00DCFF`) |
| **Foundation Establishment** | 2 | 250 Qi | 30 Qi/s | 1.5x (150 HP) | Emerald Jade (`#32FF78`) |
| **Golden Core** | 3 | 500 Qi | 50 Qi/s | 2.2x (220 HP) | Imperial Gold (`#FFD700`) |
| **Nascent Soul** | 4 | 1,000 Qi | 85 Qi/s | 3.5x (350 HP) | Spirit Purple (`#B432FF`) |
| **Heavenly Tribulation** | 5 | 2,500 Qi | 120 Qi/s | 5.0x (500 HP) | Crimson Tribulation (`#FF1E1E`) |

---

## 🧘 Qi Meditation Mechanics (`Hotkey G`)

* **Stance**: Avatar plays custom floating cultivation pose (`rbxassetid://116333173300889`).
* **Hovering**: Anchored steadily in the air with calm float height offset (`0.5` studs).
* **Aura Wrap**: Lightweight `Highlight` instance (95% fill transparency, 25% outline transparency) wrapping character body in realm aura color.
* **Cinematic Camera**: Client camera zooms to a steady, front-facing close-up (`-13.5` studs view distance, elevated `1.8` studs).
* **Control Lock**: Movement keys are locked during meditation—only **Hotkey `G`** exits meditation.

---

## ⚡ Breakthrough Mechanics (`Hotkey B`)

1. **Validation**: Player must absorb Qi until `CurrentQi >= MaxQi`.
2. **Execution**: Pressing **`B`** advances player to the next Realm tier.
3. **Stat Scaling**: Instantly resets `CurrentQi` to 0, applies the new realm's `HealthMultiplier` to `Humanoid.MaxHealth` and `Health`, and unlocks the new realm's Qi aura color.

---

## 🧪 Spirit Pill Alchemy Recipes (`AlchemyConfig.luau`)

| Pill Name | Recipe ID | Rarity | Ingredients Required | Craft Time | Success Rate | Consumable Effects |
| :--- | :--- | :--- | :--- | :---: | :---: | :--- |
| **Qi Gathering Pill** | `pill_qi_gathering` | Earth | 3x `mat_spirit_herb`, 1x `mat_spirit_water` | 2.0s | 95% | +50 Qi instantly; +50% meditation gather rate for 30s. |
| **Spirit Healing Dan** | `pill_healing_dan` | Earth | 2x `mat_spirit_herb`, 2x `mat_spirit_water` | 1.5s | 90% | Restores 40% Max HP over 5 seconds. |
| **Physique Tempering Pill** | `pill_physique_tempering` | Heaven | 4x `mat_spirit_herb`, 1x `mat_demon_core` | 3.0s | 85% | Increases Physique damage by +20% for 60 seconds. |
| **Foundation Gathering Dan**| `pill_breakthrough` | Spirit | 8x `mat_spirit_herb`, 3x `mat_demon_core`, 5x `mat_spirit_water` | 5.0s | 75% | +250 Qi instantly; grants breakthrough success boost. |

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

## 3. Server-Authoritative Loot Engine & Pity Counter

Loot generation occurs strictly on the server when a mob or Demon Boss entity dies:

1. Mob Death Trigger: Server verifies mob hit history and tags participating players who dealt >= 5% total damage.
2. Roll Currency: Award Spirit Stones scaled by mob level.
3. Roll Drop Table: Iterate through the entity's Drop Table array using weighted random selection:
   `TotalWeight = Sum of all Item Weights`
   `Roll = math.random(1, TotalWeight)`
4. Boss Pity Counter: Every Demon Boss kill increments the player's PityCounter by +1. At 50 kills without a Sacred/Immortal drop, the next kill forcefully awards a Sacred Grade artifact and resets PityCounter = 0.