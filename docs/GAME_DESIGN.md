# ASCEND-V1 — MASTER GAME DESIGN DOCUMENT (GDD)

> **Source of Truth for Game Design, Combat Logic, Progression, & UI Principles**  
> **Master Documentation Link:** `https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md`

---

## 1. Executive Vision & Core Pillars

**ASCEND-V1** is a lightweight, combat-focused, reward-driven action RPG on Roblox. The game is designed to prioritize gameplay feel, performance, combat depth, and progression satisfaction over graphical complexity or visual bloat.

### Core Design Pillars

1. **Lightweight & Roblox-First Design:**
   - Optimized for high FPS across low-end, desktop, and mobile devices.
   - Low visual clutter and restrained VFX. Visual effects exist solely to communicate hit feedback, attack ranges, and active status effects.

2. **Server-Authoritative Combat Depth:**
   - Zero-trust security model. All damage, cooldowns, movement mechanics, hit registration, and drops are calculated and validated exclusively on the server.
   - High skill ceiling based on timing, positioning, combos, parries, and dodges.

3. **High-Dopamine Progression & Loot Loop:**
   - Excitement driven by rare weapon drops, stat scaling, weapon collection, skill mastery, and equipment progression.
   - Long-term replayability through iterative updates and expandable endgame systems.

4. **Dual UI Philosophy:**
   - **In-Combat HUD:** Ultra-minimalist, clean, unobtrusive, highly readable, large touch targets, low clutter.
   - **Out-of-Combat Modals:** Handcrafted fantasy artwork panels for inventory, equipment, skill trees, and crafting.
   - Clear visual separation between active gameplay HUD and heavy menu panels.

---

## 2. Core Gameplay Loop

┌─────────────────────────┐
                    │   1. LOBBY / HUB AREA   │
                    └────────────┬────────────┘
                                 │ Select Stage / Area
                                 ▼
                    ┌─────────────────────────┐
                    │   2. FAST COMBAT ZONE   │
                    └────────────┬────────────┘
                                 │ Fight Enemies & Bosses
                                 ▼
                    ┌─────────────────────────┐
                    │  3. REWARD & RARE DROPS │
                    └────────────┬────────────┘
                                 │ Collect Gold, Gear & XP
                                 ▼
                    ┌─────────────────────────┐
                    │  4. UPGRADE & ASCEND    │
                    └────────────┬────────────┘
                                 │ Equip Weapons & Master Skills
                                 └────────────┘

### Detailed Loop Phases
1. **Prepare:** Player manages loadout, upgrades weapons, allocates stat points, and selects active skills in the Hub using handcrafted fantasy panels.
2. **Engage:** Player enters an arena or dungeon zone with minimalist UI. Engages in fast, fluid action combat against regular enemies and elite bosses.
3. **Reward:** Defeating enemies awards XP, currency, upgrade materials, and weighted rare drops (weapons, armor, skill scrolls).
4. **Ascend:** Player returns to the Hub to equip rare drops, level up weapon mastery, and unlock higher-tier combat zones.

---

## 3. Combat System Architecture

### Weapon Archetypes & Playstyles
Each weapon archetype features distinct light combo chains, heavy finishers, attack speeds, ranges, and resource costs:

| Weapon Archetype | Combat Role | Primary Stat | Mechanics |
| :--- | :--- | :--- | :--- |
| **Katana / Curved Blade** | Fast Combo / Counter | Dexterity | Rapid light strings, high critical multiplier, precise parry windows. |
| **Greatsword** | Heavy Crowd Control | Strength | High damage per hit, super armor on heavy attacks, hyper-impact knockback. |
| **Dual Daggers** | Mobility / Burst | Dexterity / Speed | High attack speed, short dash attacks, damage stacking bleed debuffs. |
| **Magic Staff / Wand** | Ranged Zoning | Intelligence | Projectile management, energy cost management, area-of-effect control. |

### Core Action Mechanics
* **Light Attack Combo (M1):** 4-hit auto-chain ending in a combo finisher. Validated server-side via time-since-last-attack checks.
* **Heavy / Charged Attack (M2):** Consumes stamina to break enemy block or deal heavy impact damage.
* **Dodge / Roll (Space / Shift):** Grants invulnerability frames (i-frames) for a brief duration. Consumes stamina.
* **Parry / Deflect (F Key / Tap):** Precision block. Successful parry stuns the attacker and restores stamina.
* **Skill Abilities (Q, E, R):** Weapon-specific active abilities managed by server cooldown timers.

---

## 4. Progression, Stats & Loot System

### Rarity Tiering Engine
Items follow a strict, color-coded rarity pipeline:
* **Common (White):** Base equipment with zero bonus attributes.
* **Uncommon (Green):** Minor stat bonuses (+Strength/Dexterity).
* **Rare (Blue):** Multi-stat bonuses + 1 passive slot.
* **Epic (Purple):** High stat scaling + unique weapon effect.
* **Legendary (Gold):** Signature boss drops with game-changing skill modifiers.
* **Mythic (Red):** Pinnacle endgame drops with ultra-rare drop weights.

### Stat Attributes
* **Strength (STR):** Increases base physical damage and heavy attack impact.
* **Dexterity (DEX):** Increases attack speed, critical hit chance, and movement speed.
* **Intelligence (INT):** Increases skill damage, energy reserves, and cooldown reduction.
* **Vitality (VIT):** Increases maximum health and health regeneration rate.
* **Endurance (END):** Increases maximum stamina and stamina recovery speed.

### Weapon Mastery System
* Using a weapon type gains **Mastery XP** for that weapon category.
* Higher mastery levels unlock passive talent nodes in the weapon's skill tree (e.g., +5% Katana speed, +10% Greatsword block resistance).

---

## 5. UI/UX Specification Guidelines

### In-Combat HUD Rules
* Must remain invisible or low-opacity until combat is initiated.
* Health and Stamina bars positioned at the bottom-left with dynamic fill transitions.
* Ability slots positioned at bottom-center with clear sweep cooldown overlays.
* Boss health bars displayed at the top-center with clear phase indicators.
* Over-the-head indicators for enemy health and stun state to prevent screen clutter.

### Fantasy Panel Rules (Out-of-Combat)
* Full-screen or modal overlays opened via keybinds (e.g., `I` for Inventory, `C` for Character Stats).
* Uses handcrafted fantasy border frames, textured backgrounds, and high-contrast typography.
* Large drag-and-drop slots for mobile and PC usability.

---

## 6. Security & Server Authority Rules

To ensure a fair and exploit-proof environment:
1. **Server Hitbox Generation:** The client sends an "intent to attack" signal. The server verifies cooldowns, checks player position, performs spatial hitbox queries, and applies damage.
2. **Server Cooldown Trackers:** All cooldowns are tracked on the server using `os.clock()`. Client-side cooldown visuals are purely predictive.
3. **Server Data Verification:** Currency, inventory updates, equipment toggles, and stat allocations are processed strictly through server Services.

---

## 7. Roadmap & Update Strategy

* **Version 1.0 (Core Release):** 3 Weapon Archetypes, 1 Hub, 2 Combat Zones, Core HUD, Inventory Panel.
* **Content Update 1:** New Weapon Archetype (Staff), Boss Raid Arena, Crafting System.
* **Content Update 2:** Ascension System (Prestige level reset with permanent stat buffs), Mythic Drop Tier.