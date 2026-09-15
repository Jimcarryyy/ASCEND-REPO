
---

### Step 6: Pristine, Codebase-Aligned `docs/GAME_DESIGN.md`

Replace the entirety of `docs/GAME_DESIGN.md` with the following document:

```markdown
# ASCEND — Authoritative Game Design Document (GDD)

> **Core Game Design Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. High-Concept & Core Game Loop

**ASCEND** is a high-performance Xianxia Action RPG built on the Roblox R6 avatar rig. Players step into the shoes of an aspiring immortal within the **Jade Pure Sect**, progressing from a fragile mortal in the Qi Condensation realm to a world-shattering Dao Sovereign in the Immortal Ascension realm.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            THE ASCEND CORE LOOP                             │
│                                                                             │
│                   ┌───────────────────────────────┐                         │
│                   │  1. GATHER, CRAFT & DUTIES    │                         │
│                   │  - Harvest herbs & ores       │                         │
│                   │  - Brew tea & forge blades    │                         │
│                   │  - Complete sect duties (Tab) │                         │
│                   └───────────────┬───────────────┘                         │
│                                   │                                         │
│                                   ▼                                         │
│                   ┌───────────────────────────────┐                         │
│                   │  2. CULTIVATE & BREAKTHROUGH  │                         │
│                   │  - Channel Qi meditation ('C')│                         │
│                   │  - Absorb Sakura Grove Qi     │                         │
│                   │  - Face Tribulation Lightning │                         │
│                   └───────────────┬───────────────┘                         │
│                                   │                                         │
│                                   ▼                                         │
│                   ┌───────────────────────────────┐                         │
│                   │  3. MARTIAL COMBAT & MASTERY  │                         │
│                   │  - 5-Hit Broadsword Combos    │                         │
│                   │  - Sword Intent Criticals     │                         │
│                   │  - Perfect Parries & Flight   │                         │
│                   └───────────────┬───────────────┘                         │
│                                   │                                         │
│                                   ▼                                         │
│                   ┌───────────────────────────────┐                         │
│                   │  4. WORLD COMBAT & CONQUEST   │                         │
│                   │  - Slay wilderness beasts     │                         │
│                   │  - Conquer World Boss Mo Chen │                         │
│                   │  - Compete in PvP Arena Duels │                         │
│                   └───────────────┬───────────────┘                         │
│                                   │                                         │
│                                   └───────── (Cycle repeats at higher realm)│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. World Layout: Zone 1 — Jade Pure Sect (ADR-044)

The Jade Pure Sect world hub is designed as a **3-Tier Stepped Mountain Citadel**, ensuring intuitive player flow from basic disciple services up to the sovereign seat:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 3: UPPER SOVEREIGN PALACE                                              │
│ - Grand Sect Palace Hall: Traditional black roof-tile Xianxia architecture  │
│ - Sovereign NPC: Supreme Sect Leader & Grand Sword Elder Liang              │
│ - Guard Force: Elite Palace Protectors & 7 Grand Lore Pillars               │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 2: MIDDLE SPIRITUAL DAO SANCTUARY                                      │
│ - Elevated Sword Altar: Central monument exhibiting ancient flying swords   │
│ - Disciple Pavilions: Inner disciple courtyards & spirit meditation pads    │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 1: LOWER SERVICE & TRAINING GROUNDS                                    │
│ - Blacksmith Forge: Madame Tie (+10 Blade Refinement)                       │
│ - Spirit Tea Pavilion: Xiao Ling (3 Cultivation Brews & Timed Buffs)        │
│ - Sect Training Grounds: Instructor Wu, 3 Immortal Dummies, DPS Meters      │
│ - Starter Guide Pavilion: Elder Qing (Interactive 4-Tab Codex UI)           │
│ - Alchemy Cauldron: Master Shen (Herb slotting & pill crafting)             │
│ - Sect Notice Board: Deacon Zhao (Daily Duties: D, C, B, A Rank Bounties)   │
│ - Treasury & Market: Steward Jin (Blade Purchasing & Spirit Stone Trading)  │
│ - Sacred Sakura Grove: +100% Qi Accumulation Zone (2.0x Meditation Speed)   │
│ - Wilderness Portal: Southern Gate leading into the Mistveil Forest         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Sect NPC Roster & Functionality

Every major NPC is tied to a dedicated server manager and client controller:

| NPC Name | Location | Role & System | Mechanical Interaction |
| :--- | :--- | :--- | :--- |
| **Grand Sword Elder Liang** | Tier 3 Palace | Sect Sovereign / Lore Master | High-realm dialogue, sect advancement ceremonies. |
| **Madame Tie** | Tier 1 Forge | Sect Blacksmith (`BlacksmithManager`) | Refines Flying Swords ($+1 \rightarrow +10$) using harvested ores. |
| **Master Shen** | Tier 1 Cauldron | Sect Alchemist (`AlchemyManager`) | Crafts Qi condensation pills and tribulation elixirs. |
| **Xiao Ling** | Tier 1 Pavilion | Spirit Tea Brewer (`TeaHouseManager`) | Sells teas granting $+25\%$ to $+100\%$ Qi gathering rate buffs. |
| **Deacon Zhao** | Tier 1 Notice Board | Duty Administrator (`NoticeBoardManager`) | Assigns daily sect duties and bounties across 4 rank tiers. |
| **Elder Qing** | Tier 1 Pavilion | Starter Guide (`StarterGuideController`) | Interactive 4-tab UI guiding novices through keybinds and systems. |
| **Instructor Wu** | Tier 1 Grounds | Sparring Instructor (`SparringController`) | Manages 3 Immortal Dummies with real-time combo DPS meters. |
| **Steward Jin** | Tier 1 Treasury | Sect Merchant (`MarketplaceManager`) | Exchanges Spirit Stones for weapons, reagents, and cosmetic skins. |

---

## 4. The Single-Weapon Philosophy: Flying Swords (ADR-038)

ASCEND eliminates fragmented weapon trees in favor of a deep, highly polished **Flying Sword Arsenal**. All 8 weapons utilize standardized martial animations while attuning their visual identity via `ItemConfig.GetWeaponPalette(weaponId)`:

```text
[Mortal Iron] ──> [Azure Cloud] ──> [Flowing Qi] ──> [Verdant Jade]
  (Common 15)       (Uncommon 25)      (Rare 40)        (Epic 60)
       │
       ▼
[Violet Soul] ──> [Void Star]   ──> [Azure Patriarch] ──> [Radiant Immortal]
 (Legendary 120)    (Mythic 220)       (Divine 450)        (Immortal 1000)
```

### Dynamic Visual Attunement
When a blade is equipped, all combat effects immediately shift to its native palette:
- **Silver-White (`#DCE1EB`):** Standard mortal iron trails.
- **Celestial Cyan (`#38BDF8`):** Azure Cloud crisp qi ripples.
- **Ocean Sapphire (`#0EA5E9`):** Flowing Qi fluid trails and water slashes.
- **Emerald Jade (`#34D399`):** Verdant Jade vibrant spirit blades.
- **Amethyst Violet (`#C084FC`):** Violet Soul sovereign purple arcs.
- **Void Purple (`#A855F7`):** Void Star cosmic particle distortions.
- **Divine Cyan (`#22D3EE`):** Azure Patriarch luminescent celestial rays.
- **Solar Gold (`#FACC15`):** Radiant Immortal blinding solar sword beams.

---

## 5. Profession & Gathering Ecosystem

### 1. Resource Harvesting (`GatheringManager.luau`)
Interactive world nodes scattered through the Jade Pure perimeter and Mistveil Forest:
- **Spirit Herbs:**
  - *Ghost Grass:* Abundant along riverbanks; basic alchemy reagent.
  - *Golden Ginseng:* Grows near high-altitude tree roots; vital for Qi pills.
  - *Star Dew Lily:* Rare nocturnal flora; essential for Tribulation shielding elixirs.
- **Spirit Ores:**
  - *Mortal Iron Ore:* Found in rocky crevices; basic forge material.
  - *Azure Cloud Ore:* Found at waterfall bases; required for $+4 \rightarrow +7$ refinement.
  - *Star Void Shard:* Rare crystal clusters; required for $+8 \rightarrow +10$ refinement.

### 2. Alchemy Cauldron (`AlchemyManager.luau`)
- Players insert 3 harvested herbs into Master Shen's Bronze Cauldron.
- Timing mini-game: Keep the heat needle inside the green tolerance band to achieve high pill purity ($80\% - 100\%$).
- Higher purity grants greater instant Qi restoration or longer resistance buffs.

### 3. Spirit Tea Pavilion (`TeaHouseManager.luau`)
- Consumable teas bought from Xiao Ling that grant timed environmental Qi buffs:
  - *Green Cloud Tea:* $+25\%$ Qi gathering rate (300s).
  - *Misty Mountain Oolong:* $+50\%$ Qi gathering rate (600s).
  - *Dragon Well Imperial Brew:* $+100\%$ Qi gathering rate + $10\%$ physical damage (900s).

---

## 6. Enemy & Mob Hierarchy (`MobAIManager.luau`)

World enemies utilize full-body R6 rigs with deterministic state machines and flocking logic:

```text
       ┌───────────┐
       │  PATROL   │
       └─────┬─────┘
             │ Player detected within Alert Radius (45 studs)
             ▼
       ┌───────────┐
       │   ALERT   │ ──> (Draws weapon, plays battle roar)
       └─────┬─────┘
             │ Player remains in territory
             ▼
       ┌───────────┐
       │   CHASE   │ ──> (Flocks using Boids separation; 22 studs/s)
       └─────┬─────┘
             │ Within Attack Range (7.5 studs)
             ▼
       ┌───────────┐
       │  ATTACK   │ ──> (Executes combo chain; can be parried)
       └───────────┘
```

### Enemy Bestiary
1. **Mistveil Spirit Wolf (Tier 1):** Fast-moving pack hunter. Leaps at cultivators; low poise, easily staggered by M1 hits.
2. **Corrupted Rogue Cultivator (Tier 2):** Fallen disciple wielding a damaged flying sword. Uses 3-hit combos and will occasionally block incoming slashes.
3. **Mountain Bandit Enforcer (Tier 2):** High-poise brute. Swings heavy cleavers that deal significant posture damage. Vulnerable to Perfect Parries.
4. **World Boss: Fallen Sword Genius — Mo Chen (`Boss_FallenSwordGenius`):**
   - **Encounter Arena:** The Sword Tomb clearing south of the Sect gates.
   - **Phase 1 (Hundred Cuts):** Rapid teleport dashes, 5-hit combos, and projectile sweeps.
   - **Phase 2 (Desolate Sword Domain):** Enters at $50\%$ health. Summons floating phantom blades, casts an arena-wide sword rain, and gains $+30\%$ movement speed. Requires active parrying and coordination to defeat.

---

## 7. Player vs Player: The Martial Arena (`ArenaManager.luau`)

A dedicated competitive duel ground where cultivation power multipliers are normalized for fair, skill-based martial arts competition:
- **Queue System:** Managed via `ArenaController.luau` at the Sect Arena platform.
- **Match Types:** 1v1 Ranked Duels and 4-Player Free-for-All.
- **Stat Normalization:** Player health is clamped to a standardized competitive baseline ($1,000\text{ HP}$), and skill damages use calibrated Arena values (`ArenaDamage` in `FlyingSwordConfig.luau`).
- **Rewards:** Arena Honor Points exchanged at Steward Jin's shop for exclusive cosmetic sword auras and titles.
```

---