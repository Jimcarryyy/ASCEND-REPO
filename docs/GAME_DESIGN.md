# ASCEND-V1 — MASTER GAME DESIGN DOCUMENT (GDD)

> **Source of Truth for Game Design, Sword Cultivator Logic, Progression, & UI Principles**  
> **Master Documentation Link:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md

---

# 1. Executive Vision & Core Pillars

**ASCEND-V1** is a lightweight, combat-focused, reward-driven **Xianxia Sword Cultivator Action RPG** built for mobile and PC high FPS.

### Core Pillars
- **Pure Sword Cultivation (飞剑 / 剑修)**: Every weapon is a Flying Sword.
- **Ultra-Scaled Down MVP Architecture**: 5 Master 3D Base Sword Models (*Mortal Iron*, *Jade Dragon*, *Sun Slayer*, *Thunder Frost*, *Heavenly Void*) re-colored dynamically via `ItemConfig.luau`.
- **1 Master Sect Island Map ($500 \times 500$ studs)**: Stylized Painted Low-Poly aesthetic with a 15-second walk loop connecting Spawn, Practice Dummies, Herb Gathering Meadows, Bronze Alchemy Cauldron, and Sect Sword Altar.
- **Normalized $100 \rightarrow 10,000$ HP/Qi Scale**: 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*) across 45 Sub-Stage Orders.
- **Traditional Xianxia Light-Mode UI Palette**: `#1D4533` Jade Green, `#F7EAE0` Warm Cream, `#F9D2BA` Peach Accent, and `#5E3122` Mahogany Wood.

---

# 2. V1 World Map Strategy: The 1 Master Sect Island

To prevent developer burnout and ensure 60 FPS mobile performance, V1 launches on **1 Compact Master Sect Island ($500 \times 500$ studs max)**. All core gameplay loops sit within a 15-second walk:

```text
                      [ ⛩️ Central Sect Altar ]
                      (Spawn & Sword Gacha Roll)
                                  |
              (10-second walk down cobblestone path)
                                  |
        +-------------------------+-------------------------+
        |                                                   |
[ 🍃 Herb Meadow ]                                [ 🥋 Practice Courtyard ]
(Gather Spirit Grass & Ginseng)                   (Test Damage on Dummies)
        |                                                   |
        +-------------------------+-------------------------+
                                  |
                   [ 🔮 Bronze Alchemy Cauldron ]
                   (Refine Pills for Stat Boosts)
                                  |
                   [ 🌀 Dimensional Boundary Portal ]
                   (Locked for Future Zone 2 Updates!)


---\n
# 6. Low-Cortisol Profession Mechanics & Monetization Strategy

### Low-Cortisol Crafting & Gathering Loop
To serve players who prefer peaceful gathering and crafting over combat:
1. **World Harvesting**: Gathering spirit herbs, dew springs, and beast cores yields randomized herb ages ($1\text{-Yr}$ to $1,000\text{-Yr}$). Water springs remain visible during cooldown.
2. **Qi Flame Temperature Minigame**: Refinement features an interactive needle slider. Locking the needle in the Optimal Qi Flame zone grants a $+15\%$ success rate bonus and $+25\%$ Alchemy EXP!
3. **Pill Quality Grades**: Herb ages determine pill quality (*Standard*, *Refined Medium*, *Century Superior*, *Sovereign Immortal*), increasing buff duration up to $+50\%$. High-grade pills store in separate inventory stacks.
4. **Alchemy Mastery Progression**: Crafting grants Alchemy EXP across 4 Alchemist Ranks (*Apprentice Alchemist* $\rightarrow$ *Spirit Herb Master* $\rightarrow$ *Grand Cauldron Scholar* $\rightarrow$ *Pill Emperor*).

### Monetized HUD Cosmetics
* **HUD Skin Customization**: Players can purchase or unlock custom vital HUD skins (*Sakura Immortal*, *Azure Dragon*) via Robux or Realm milestones.

## 4. World & Map Architecture — The Azure Cloud Realm

### Historical Baseline (MVP Map Concept)
Originally designed as a single compact $500 \times 500$ stud Master Sect Island containing the Sect Altar, Practice Courtyard, Herb Meadows, Cauldron, and Portal.

### Current Expanded Map Vision (5 Connected Zones & Custom Biomes)
Recreated and expanded into a wide open-world Xianxia landscape with 5 core functional zones and distinct biome regions:
code
Code
┌──────────────────────────────────────┐
                  │ ZONE 5: Sovereign Sword Peak (Apex)  │
                  └──────────────────┬───────────────────┘
                                     │
   ┌─────────────────────────────────┴─────────────────────────────────┐
   │                                                                   │
┌──────┴─────────────────────────────────┐ ┌─────────────────┴──────────────────┐
│ ZONE 1: Azure Cloud Sect Sanctuary │ │ ZONE 4: Qi Cascades & Magma Ridge │
│ (Central Hub & Cauldron) │ │ (Qi Nodes & Breakthroughs) │
└──────┬─────────────────────────────────┘ └─────────────────┬──────────────────┘
│ │
┌──────┴─────────────────────────────────┐ ┌─────────────────┴──────────────────┐
│ ZONE 2: Verdant Bamboo & Sakura Valley │───────────────┤ ZONE 3: Crystal Caverns & Frost │
│ (Herbs, Springs & Starter Area) │ (River Pass) │ (Mining & Frost Crags) │
└────────────────────────────────────────┘ └────────────────────────────────────┘
code
Code
1. **ZONE 1 — Azure Cloud Sect Sanctuary (Central Hub):** Multi-tiered blue-tiled temple, central bronze Alchemy Cauldron, vendor shops, spawn plaza, and marble staircases.
2. **ZONE 2 — Verdant Bamboo & Sakura Blossom Valley (Expanded Lowlands):** Towering green bamboo thickets, pink cherry blossom groves, turquoise rivers with wooden arch bridges, and starter herb gathering meadows.
3. **ZONE 3 — Crystal Caverns & Frost Glacier Crags (East Mining & Ice Zone):** Caverns embedded with glowing purple/blue Spirit Jade ore, snow-dusted pine trees, frozen waterfalls, and mine cart tracks.
4. **ZONE 4 — Qi Cascades & Volcanic Magma Ridge (Northeast Cultivation & Fire Zone):** Cascading waterfalls flowing into a Qi shrine lake, contrasted against a dark basalt magma ridge with lava fissures and *Flame Fruit*.
5. **ZONE 5 — Sovereign Sword Peak & Celestial Arena (North Apex):** Circular stone arena with giant ancient Flying Swords (30+ studs tall) plunged into the peak, floating cloud islands, and world boss arenas.

### Environment & Collision Rules
- **Tree & Bamboo Collision:** Leaves/canopies have `CanCollide = false`. Physical collision is strictly enforced on tree trunks and individual bamboo stalks (`TreeCollisionManager.luau`).
- **Stylized Wind Physics:** Vegetation sways dynamically with an organic gusting wind envelope (`REST -> GUST -> SWAY -> SETTLE`) with spatial distance culling (<160 studs) and object-specific flexibility (large trees $3.7^\circ$, small trees $5.5^\circ$, bamboo $8.0^\circ$).
- **Lighting & Night Readability:** 12-minute 4-phase day/night lighting cycle with soft moonlit ambient (`OutdoorAmbient = #415073`) so trees retain visual presence at night without becoming pitch-black silhouettes. PointLights are strictly limited to spirit herbs, Qi nodes, and cauldrons.

### Azure Cloud Sect Progression Loop (Added 2026-08-20)

- **Disciple Promotion Ladder:**
  - *Outer Disciple:* Qi Condensation (Tier 1) | 0 Contribution
  - *Inner Disciple:* Foundation Establishment (Tier 2) | 500 Contribution
  - *Core Disciple:* Golden Core (Tier 3) | 2,500 Contribution
  - *Direct Disciple:* Nascent Soul (Tier 4) | 10,000 Contribution
  - *Sect Elder:* Spirit Severing (Tier 5) | 50,000 Contribution
  - *Grand Elder:* Tribulation Transcending (Tier 9) | 150,000 Contribution
- **Balanced Sparring Arena:** 1v1 equalized combat matching disciples in the exact same realm bracket for contribution points and stones.


### V1 Pure Sword Lineup & Standardized Keybind Schema

#### V1 Pure Sword Arsenal (8 Total Swords)
1. **Mortal Iron Jian (凡铁剑):** Tier 1 (Common) — Starter Forged Steel.
2. **Azure Cloud Disciple Jian (青云剑):** Tier 2 (Uncommon) — Sect Initiate Cyan Cloud Sword.
3. **Flowing Qi Spirit Sword (流气灵剑):** Tier 3 (Rare) — Luminous Sapphire Crystal Spirit Blade.
4. **Verdant Jade Flying Sword (青玉飞剑):** Tier 4 (Epic) — Imperial Emerald Jade Flying Blade.
5. **Violet Soul Sovereign Jian (紫魄灵剑):** Tier 5 (Legendary) — Nascent Soul Purple Lightning Sword.
6. **Void Star Cleaver Dao (裂虚天刃):** Tier 6 (Mythic) — Single-Edged Curved Void Saber.
7. **Azure Patriarch Heritage Jian (青云祖师剑):** Sect Prestige (Legendary) — Elder Sovereign Ancient Bronze Jian.
8. **Radiant Immortal Sovereign Jian (天尊飞仙剑):** VIP / Monetization (Celestial) — Divine White-Gold Deity Flying Sword.

#### Unified Keybind Schema
| Action | Keybind | Description |
| :--- | :--- | :--- |
| **Sprint** | **Double-Tap `W`** | High-speed sprint (52 Open World / 28 Arena). |
| **Basic Attack** | **`MouseButton1`** | 5-hit heavy broadsword combo string. |
| **Qi Dash** | **`LeftShift`** | 2-stage flash-step dash (3.0s cooldown). |
| **Sword Tempest** | **`Q`** | Whirlwind Qi sword vortex. |
| **Telekinesis Thrust**| **`E`** | Telekinetic forward piercing thrust beam. |
| **Falling Sky Slam** | **`F`** | Aerial downward heavy sword cleave. |
| **Sheath / Draw** | **`R`** | Snaps sword between Hand and Diagonal Back Sheath. |
| **Meditation Form** | **`C`** | Toggles grounded cultivation sitting form & realm aura. |
| **Breakthrough** | **`B`** | Requests Major / Minor realm ascension trial. |
| **Spirit Pouch** | **`Tab` / `I`** | Opens 60-slot inventory modal. |
| **Sparring Arena** | **`P`** | Opens Sector 3 1v1 Sparring Arena registration. |
| **Focus Target Aim** | **`LeftControl` / `MMB`** | Toggles screen-center reticle and upper-body aim lock. |
| **Flight Mode** | **`V`** *(Upcoming)* | Mounts sword beneath feet for 3D flight. |