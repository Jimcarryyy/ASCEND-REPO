# ASCEND — Authoritative Progression & Cultivation Specification

> **Technical Specification Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau` & `src/ServerScriptService/Server/Cultivation/CultivationManager.luau`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. Cultivation Progression Overview

Progression in ASCEND is governed by the ancient Daoist ascension ladder, modeled in `CultivationConfig.luau`. The journey spans **10 Major Realms**, with each realm subdivided into **9 Orders** (a total of **90 discrete stages of progression**).

Progression directly dictates:
1. **Maximum Health Pool:** Exponentially scales from $1,000\text{ HP}$ (Mortal Qi Condensation) to over $100,000,000\text{ HP}$ (Immortal Ascension).
2. **Cultivated Qi Capacity:** The total pool of spiritual energy required to cultivate before attempting the next breakthrough.
3. **Power Multiplier:** A universal damage scalar applied to all basic attacks, weapon damage, and martial skills in open-world combat.
4. **Heavenly Tribulation Intensity:** The number and ferocity of celestial lightning strikes summoned during major realm breakthrough trials.

---

## 2. Core Mathematical Scaling Formulas

All progression math is server-authoritative and calculated via deterministic formulas in `CultivationConfig.luau`:

### 1. Health Scaling Formula
$$\text{MaxHealth}(\text{Realm}, \text{Order}) = \lfloor \text{BaseMaxHealth}_{\text{Realm}} \times 1.35^{(\text{Order} - 1)} \rfloor$$

### 2. Required Qi Capacity Formula
$$\text{TargetQi}(\text{Realm}, \text{Order}) = \lfloor \text{BaseTargetQi}_{\text{Realm}} \times 1.45^{(\text{Order} - 1)} \rfloor$$

### 3. Open-World Power Multiplier Formula
$$\text{PowerMultiplier}(\text{Realm}, \text{Order}) = \text{HealthMultiplier}_{\text{Realm}} \times [1 + (\text{Order} - 1) \times 0.15]$$

*Note:* Each individual Order advancement within a realm grants a flat $+15\%$ additive bonus to that realm's base power multiplier. By Order 9, the cultivator wields **$2.20\times$** the realm's baseline power.

---

## 3. The 10 Major Realms Matrix

| Tier | Realm Name | Internal ID | Base Max HP | Base Target Qi | Base Power Scalar | Order 9 Max HP | Order 9 Power Mult | Tribulation Strikes | Realm Aesthetic Color |
| :---: | :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **1** | Qi Condensation | `QiCondensation` | 1,000 | 1,000 | $1.0\times$ | 11,032 | $2.20\times$ | 0 (Safe) | Silver-White (`#DCE1EB`) |
| **2** | Foundation Establishment | `FoundationEstablishment` | 15,000 | 15,000 | $15.0\times$ | 165,492 | $33.00\times$ | 2 Strikes | Sky Cyan (`#38BDF8`) |
| **3** | Golden Core | `GoldenCore` | 75,000 | 75,000 | $75.0\times$ | 827,460 | $165.00\times$ | 3 Strikes | Ocean Sapphire (`#0EA5E9`) |
| **4** | Nascent Soul | `NascentSoul` | 350,000 | 350,000 | $350.0\times$ | 3,861,480 | $770.00\times$ | 4 Strikes | Emerald Jade (`#34D399`) |
| **5** | Spirit Severing | `SpiritSevering` | 1,500,000 | 1,500,000 | $1,500.0\times$ | 16,549,200 | $3,300.00\times$ | 5 Strikes | Amethyst Violet (`#C084FC`) |
| **6** | Void Refining | `VoidRefining` | 7,500,000 | 7,500,000 | $7,500.0\times$ | 82,746,000 | $16,500.00\times$ | 5 Strikes | Void Purple (`#A855F7`) |
| **7** | Body Integration | `BodyIntegration` | 25,000,000 | 25,000,000 | $25,000.0\times$ | 275,820,000 | $55,000.00\times$ | 6 Strikes | Divine Cyan (`#22D3EE`) |
| **8** | Mahayana | `Mahayana` | 55,000,000 | 55,000,000 | $55,000.0\times$ | 606,804,000 | $121,000.00\times$ | 7 Strikes | Crimson Dao (`#F43F5E`) |
| **9** | Tribulation Transcending | `TribulationTranscending` | 80,000,000 | 80,000,000 | $80,000.0\times$ | 882,624,000 | $176,000.00\times$ | 9 Strikes | Solar Orange (`#FB923C`) |
| **10** | Immortal Ascension | `ImmortalAscension` | 100,000,000 | 100,000,000 | $100,000.0\times$ | 1,103,280,000 | $220,000.00\times$ | 0 (Dao Sovereign) | Solar Dao Gold (`#FACC15`) |

---

## 4. Qi Accumulation & Meditation Mechanics

Qi is accumulated through active meditation, spirit nodes, consumable pills, and environmental zones.

```text
[Input 'C'] ──> Enter Seated Meditation ──> +10% TargetQi / sec
                     │
                     ├── Zone Bonus: Sakura Grove / Pavements (+100% Rate)
                     ├── Consumable Bonus: Spirit Tea (+25% to +100% Rate)
                     └── Combat Action / Movement ──> Cancels Meditation

1. Seated Meditation (C Keybind)

  - Base Rate: Channelling meditation recovers Qi at 10.0\% of the current
    stage's TargetQi per second (10 seconds of uninterrupted meditation fills an
    empty gauge).
  - Combat Restrictions: When meditating, all combat capabilities (attacking,
    sprinting, dashing, parrying) are locked. Any incoming damage or movement
    input breaks meditation immediately.

2. Environmental Qi Density Modifiers

Standing or meditating in spiritually dense sect locations multiplies Qi
absorption rates:

  - Wilderness / Standard Ground: 1.0\times baseline.
  - Sect Meditation Pavements: 1.5\times Qi accumulation.
  - Jade Pure Sakura Grove (ADR-044): 2.0\times Qi accumulation rate.
  - Spirit Spring / High Mountain Peaks: 2.5\times Qi accumulation rate.

3. Spirit Tea Buff System (TeaHouseManager.luau)

Brewed at the Spirit Tea Pavilion with Xiao Ling:

  - Green Cloud Tea: +25\% Qi gain rate for 300 seconds.
  - Misty Mountain Oolong: +50\% Qi gain rate for 600 seconds.
  - Dragon Well Imperial Brew: +100\% Qi gain rate and +10\% flat physical
    damage for 900 seconds.

5. Breakthrough System (B Keybind)

When a cultivator accumulates 100\% of their stage's TargetQi, the Breakthrough
prompt (B) activates.

               [100% Cultivated Qi Reached]
                            │
               Press 'B' (Initiate Breakthrough)
                            │
            ┌───────────────┴───────────────┐
            │                               │
    [Minor Breakthrough]            [Major Breakthrough]
    (Order N ──> Order N+1)         (Realm R ──> Realm R+1)
            │                               │
    - 100% Guaranteed               - Summons Heavenly Tribulation
    - Instant Stat Expansion        - Consecutive Lightning Strikes
    - Restorative Golden Pulse      - Must Survive or Perfect Parry
    - Qi Resets to 0                - Success: Ascension Burst + Title
                                    - Failure: 50% Qi Loss + Debuff

1. Minor Breakthroughs (Order N \rightarrow N+1)

  - Occurs between Order 1 and Order 8 within the same realm.
  - Success Rate: 100\% guaranteed.
  - Execution: Server validates 100\% Qi, awards the new Order, recalculates
    maximum health and damage, emits a restorative golden pulse, and resets
    current Qi to 0.

2. Major Breakthroughs (Crossing to the Next Realm)

  - Occurs at Order 9 when attempting to ascend to Order 1 of the next realm.
  - Heavenly Tribulation Event:
    1.  The sky darkens as celestial storm clouds gather
        (EnvironmentTimeManager.luau).
    2.  The server schedules N lightning strikes (dictated by TribulationStrikes
        in the table above).
    3.  Each strike displays a glowing red-and-gold ground telegraph circle for
        0.80 seconds before a lightning bolt strikes down from the sky.
    4.  Each unmitigated strike deals 30\% of the player's Max Health.
  - Survival Mechanics:
      - Tanking: A cultivator with sufficient health or defensive potions can
        endure the raw damage.
      - Perfect Parry (T): Timing a parry during the 0.22s impact window
        completely negates the lightning strike damage and inflicts an ascension
        resonance burst.
  - Resolution:
      - Ascension: If the player survives all strikes, the server triggers the
        AscensionBurst remote event, unleashes a massive shockwave, increments
        the realm tier, applies full restorative health, and announces the
        breakthrough to the sect server chat.
      - Tribulation Failure (Death): If health reaches 0, the player respawns at
        the sect infirmary, loses 50\% of their stored Qi, and suffers a
        temporary "Qi Deviation" penalty (-10\% damage for 60 seconds).

6. Profession Progression: Alchemy & Blacksmithing

1. Alchemy Cauldron (AlchemyManager.luau)

Located at Master Shen's Bronze Cauldron:

  - Requires harvested herbs: Ghost Grass, Golden Ginseng, and Star Dew Lily.
  - Pill Types:
      - Qi Condensation Pill: Instantly restores 25\% of current stage TargetQi.
      - Foundation Consolidation Pill: Grants +20\% damage resistance during
        Tribulation trials for 180 seconds.
      - Spirit Cleansing Elixir: Purges the "Qi Deviation" penalty immediately
        upon consumption.

2. Madame Tie's Forge (BlacksmithManager.luau)

Located at the lower service plaza:

  - Upgrades Flying Swords from +1 to +10 using gathered ores (Mortal Iron,
    Azure Cloud Ore, Star Void Shard).
  - Refinement Formula:
    \text{Upgraded Weapon Dmg} = \text{BaseWeaponDmg} \times [1 + (\text{Refinement Level} \times 0.05)]
  - At +10 refinement, the weapon gains an additional +50\% base damage and an
    enhanced particle aura trail.

7. Persistence Schema: ASCEND_PlayerData_V3

Governed by PlayerDataManager.luau, player progress is persisted in Roblox
DataStores under key ASCEND_PlayerData_V3:

-- Authoritative DataStore Schema
{
    SchemaVersion = 3,
    Cultivation = {
        Realm = "QiCondensation",    -- Major Realm ID string
        Order = 1,                   -- Integer: 1 to 9
        CurrentQi = 0,               -- Accumulated Qi towards next stage
        TotalCultivationXP = 0,      -- Lifetime historical cultivation earned
    },
    Combat = {
        EquippedWeapon = "MortalIronJian", -- Canonical Flying Sword ID
        RefinementLevel = 0,               -- Integer: 0 to 10
        UnlockedWeapons = { "MortalIronJian" },
    },
    Currencies = {
        SpiritStones = 100,          -- Primary trading and upgrading currency
        SectContribution = 0,        -- Earned via Notice Board duties
    },
    Inventory = {
        Herbs = { GhostGrass = 0, GoldenGinseng = 0, StarDewLily = 0 },
        Ores = { MortalIronOre = 0, AzureCloudOre = 0, StarVoidShard = 0 },
        Pills = {},
        Teas = {},
    },
    Settings = {
        MasterVolume = 1.0,
        CameraShakeEnabled = true,
        DamageNumbersEnabled = true,
    }
}

  - Auto-Save Interval: Every 300 seconds (5 minutes) per player.
  - Migration Pipeline: Automatically migrates legacy V2 keys upon player join,
    safely mapping obsolete item IDs to the V3 Flying Sword standard.


---