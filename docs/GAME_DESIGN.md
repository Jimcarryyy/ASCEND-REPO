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