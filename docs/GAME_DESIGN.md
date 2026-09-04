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

## Additive Game Design Update (2026-08-27) — 3-Tiered Sect Duties & Physical Arena

### 1. 3-Tiered Daily Sect Duties (Easy $\rightarrow$ Medium $\rightarrow$ Hard)
* **Sect Mission Progression:** Daily duties progress through 3 difficulty tiers with scaling targets and rewards:
  * **Herbal Foraging Duty:** Tier 1 ($5\text{ stalks}$) $\rightarrow$ Tier 2 ($10\text{ stalks}$) $\rightarrow$ Tier 3 ($20\text{ stalks}$).
  * **Alchemy Refinement Duty:** Tier 1 ($1\text{ Dan}$) $\rightarrow$ Tier 2 ($3\text{ Dans}$) $\rightarrow$ Tier 3 ($5\text{ Dans}$).
  * **Sparring Discipline Duty:** Tier 1 ($3\text{ Mobs}$) $\rightarrow$ Tier 2 ($6\text{ Mobs}$) $\rightarrow$ Tier 3 ($10\text{ Mobs}$).
* **Permanent Daily Lockout:** Completing Tier 3 marks the duty as `AllTiersCompleted = true`, locking the card until the daily reset.

### 2. Sector 3 Physical Duel Platform System
* Replaced background auto-queue with **Physical Standby Pads (`DuelPad1` & `DuelPad2`)**:
  * Stepping onto both pads triggers a 3-second countdown.
  * Stepping off immediately cancels the match countdown.
  * Completing the countdown teleports both fighters into the battle ring with $1{,}000\text{ HP}$.

---

# 4. `docs/GAME_DESIGN.md`

```markdown
# ASCEND — Master Game Design Document

## 1. Vision & Core Philosophy
**ASCEND** is an Eastern Xianxia (Immortal Hero) Action RPG. Disciples begin as mortal aspirants in the Jade Pure Sect, train in sword arts, gather spiritual herbs, brew pills and spirit teas, refine divine blades, spar in dueling rings, and overcome celestial tribulations to ascend through 10 realms of immortality.

---

## 2. Master Gameplay Loop

```text
               ┌──────────────────────────────────────────────┐
               │              GATHER & EXPLORE                │
               │  - Harvest Vintage Herbs (1-Yr to 1,000-Yr)  │
               │  - Mine Mountain Iron Ingot                  │
               │  - Draw Celestial Dew Springs                │
               └──────────────────────┬───────────────────────┘
                                      │
                                      ▼
               ┌──────────────────────────────────────────────┐
               │             CRAFT & CULTIVATE                │
               │  - Refine Pills in Bronze Alchemy Cauldron   │
               │  - Order Timed Buffs at Spirit Tea Pavilion  │
               │  - Forge & Sharpen Blades at Blacksmith      │
               │  - Meditate in 2.0x Qi Sakura Nodes          │
               └──────────────────────┬───────────────────────┘
                                      │
                                      ▼
               ┌──────────────────────────────────────────────┐
               │              MARTIAL ENGAGEMENT              │
               │  - Test DPS on Ironwood Training Dummies     │
               │  - Execute 3-Tier Daily Sect Duties (CP)     │
               │  - 1v1 Sparring Arena Matches                │
               │  - Hunt Beasts in Wilderness (Zone 2)        │
               └──────────────────────┬───────────────────────┘
                                      │
                                      ▼
               ┌──────────────────────────────────────────────┐
               │              REALM ASCENSION                 │
               │  - Channel Cultivated Qi to 100%             │
               │  - Endure Heavenly Tribulation Lightning     │
               │  - Promote Disciple Rank (Outer -> Elder)    │
               └──────────────────────┴───────────────────────┘
3. World Architecture: Three-Tier Sect Layout (ADR-044)
The Sect Hub is laid out in three stepped elevation tiers, utilizing a slate, marble, dark wood, and black roof tile aesthetic:
3.1 Tier 1: Lower Service & Training Grounds
The foundational courtyard dedicated to daily disciple life, crafting, trade, and basic training:
Blacksmith Forge (Sect_NPC_MadameTie): Features the Master Blacksmith Anvil. Offers weapon refinement up to +10 (+5% base ATK per tier) and Blade Sharpening (+10% Crit Chance for 15 minutes).
Spirit Tea Pavilion (Sect_NPC_XiaoLing): Sells freshly brewed spirit teas providing instant recovery and 10–15 minute attribute buffs (Meditation speed, Health regen, Sword Intent gain).
Sect Training Grounds (Sect_NPC_InstructorWu): Features 3 Ironwood Dummies with ImmortalDummyHandler.server.luau tracking real-time damage, DPS, and floating combat text.
Sect Starter Guide Pavilion (Sect_NPC_ElderQing): An interactive 4-tab knowledge kiosk explaining Controls, Cultivation, Sword Intent, and Sect Duties.
Bronze Alchemy Cauldron (Sect_NPC_MasterShen): Interactive alchemy station featuring a manual 3-slot herb loader and needle-slider temperature minigame.
Sect Notice Board (Sect_NPC_DeaconZhao): Issues 3-tier daily duties (Gathering, Alchemy, Sparring) rewarding Contribution Points (CP) and Spirit Stones.
Sect Treasury & Market (Sect_NPC_StewardJin): Disciple store offering weapon purchases, pill sales, and material trading.
Spiritual Features: 2.0x Qi Sakura Meditation Grove, practicing Outer Disciples executing sword routines, and the Wilderness Gateway (Sect_NPC_DaoistFeng) leading to Zone 2.
3.2 Tier 2: Middle Spiritual Dao Sanctuary
The elevated plateau bridging disciple life and supreme governance:
Elevated Sword Altar (Dao Sanctuary): A monumental raised stone dais reached via R6-calibrated non-trip staircases. Features floating spirit swords used for blade attunement and the weapon gacha system.
Inner Disciple Courtyards: Paved stone gathering grounds with decorative lanterns and banners, where promoted Inner Disciples meditate and congregate.
3.3 Tier 3: Upper Sovereign Palace Hall
The summit of authority, overlooking the entire mountain valley:
Grand Palace Hall: Constructed with black roof tiles, brass ornaments, and crimson silk drapery.
Supreme Sect Leader: Presides in midnight-black Daoist robes upon the elevated Dragon Dais.
Grand Sword Elder Liang: Oversees advanced disciple promotions and martial examinations.
The Top 7 Pillars of the Sect: Seven elite lore NPCs representing mastery of the seven distinct paths of the blade.
Palace Retinue: Palace maids and heavily armored elite male and female sect guards stationed at fortress bastions.
4. Subsystem Specifications
4.1 Blacksmithing Refinement & Sharpening
Manager: BlacksmithManager.luau | Controller: BlacksmithController.luau
Refinement (+1 to +10):
Upgrades equipped Flying Sword base attack power.
Formula: DamageMultiplier = 1.0 + (RefineLevel * 0.05) (Maximum +50% at +10).
Cost: 150 + (RefineLevel * 75) Spirit Stones plus MountainIronIngot units.
Success Chance: math.max(0.35, 0.95 - (RefineLevel * 0.08)). Failure consumes materials without dropping refinement level.
Blade Sharpening:
Cost: 100 Spirit Stones.
Grants a temporary +10% Critical Strike Chance buff (SharpnessCritBonus = 0.10) for 15 minutes (os.clock() + 900).
4.2 Spirit Tea Pavilion
Manager: TeaHouseManager.luau | Controller: TeaHouseController.luau
Catalog:
Jade Dew Spirit Tea (100 Stones): +250 Instant Qi, +10% Meditation Speed for 10 min (TeaMeditationMultiplier = 1.10).
Crimson Ginseng Brew (150 Stones): +500 Instant HP, +15% Health Regen for 10 min (HealthRegenBonus = 0.15).
Dragon Well Sword Tea (250 Stones): +15% Sword Intent Gain Rate for 15 min (TeaSwordIntentMultiplier = 1.15).
4.3 Training Grounds & Ironwood Dummies
Server Handler: ImmortalDummyHandler.server.luau | Controller: SparringGuidanceController.luau
Three Ironwood Dummies (TrainingDummy_1, 2, 3) located in Workspace.Functional_Stations.Sect_TrainingGround.
Functionality: 10,000,000 HP pool with instant server-authoritative regeneration. Tracks total damage received over rolling 5-second windows to compute real-time DPS. Overhead BillboardGui renders hits and live DPS using Enum.Font.Bangers. DPS can be reset via instructor dialogue.
4.4 Sect Economy & Progression
Currency 1 — Spirit Stones: Universal trading currency earned from mob defeats, selling pills, completing quests, and daily stipends.
Currency 2 — Contribution Points (CP): Earned exclusively through daily Sect duties. Determines Disciple Rank promotions:
Mortal Aspirant (0 CP)
Outer Disciple (500 CP)
Inner Disciple (1,500 CP)
Core Disciple (3,500 CP)
Sect Elder (7,500 CP)
Grand Elder (15,000 CP)
4.5 1v1 Sparring Arena
Manager: ArenaManager.luau | Controller: ArenaController.luau
Physical circular arena walled to prevent walk-in access. Matchmaking initiated when two matched-realm players stand on DuelPad1 and DuelPad2.
3-second countdown with auto-abort if a player steps off. Teleports combatants to arena spawn foci, normalizes HP to 1,000, disables lethal damage, and teleports participants back upon concession/defeat.
code
Code
---

### Delivery Notice

Batch 1 (`README.md`, `ARCHITECTURE_SPEC.md`, `UI_UX_SPEC.md`, and `GAME_DESIGN.md`) is complete and ready to replace your existing files on GitHub.

Whenever you're ready, say **"proceed"** or **"next"**, and I will output **Batch 2** (`COMBAT_SPEC.md`, `PROGRESSION_SPEC.md`, `CODE_DEPENDENCY_GUIDE.md`, and `ASSET_MANIFEST.md`) in their entirety.