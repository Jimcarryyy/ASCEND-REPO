---

# 10. `docs/GAME_DESIGN.md`

```markdown
# ASCEND-V1 — MASTER GAME DESIGN DOCUMENT (GDD)

> **Source of Truth for Game Design, Sword Cultivator Logic, Progression, & UI Principles**  
> **Master Documentation Link:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md

---

## Purpose
This document captures the high-level game vision, player-facing experience, core gameplay loop, and design pillars for the ASCEND project.

## Document Connectivity
- Use this doc first for overall game direction and player experience.
- Pair with `docs/ARCHITECTURE_SPEC.md` for technical architecture mapping.
- Pair with `docs/COMBAT_SPEC.md` for server-authoritative combat rules.
- Pair with `docs/PROGRESSION_SPEC.md` for cultivation progression and reward design.
- Pair with `docs/UI_UX_SPEC.md` for HUD and modal UI styling.

---

# 1. Executive Vision & Core Pillars

## Overview
**ASCEND-V1** is a lightweight, combat-focused, reward-driven **Xianxia Sword Cultivator Action RPG** built for the Roblox platform.

The project emphasizes:
- Pure Sword Cultivation (飞剑 / 剑修)
- Flexible Sandbox Skill Building (Jade Scrolls)
- High-dopamine progression (45-Stage High-Number Scale up to 50 Billion Qi)
- 3D Floating Back-Sword Arrays & Prestige Mythic Skins
- Server-authoritative systems & zero-trust security

---

# 2. Core Design Pillars

## 2.1 Pure Sword Cultivation & Sandbox Build Freedom
Players master the Dao of the Sword. Every weapon is a **Flying Sword (飞剑)**. Players collect, trade, and equip **Sword Art Jade Scrolls** to customize their active skill slots (`Q`, `E`, `R`), creating endless build variety without rigid class locks.

## 2.2 Visual Prestige & Floating Back-Sword Arrays
As players increase their Cultivation Realm and Sword Mastery (Rank 1 $\rightarrow$ 10), the server automatically spawns **3D Floating Back-Sword Arrays** hovering behind their back (1, 3, 5, or 7 hovering swords). Equipping Mythic Sword Skins (*Heavenly Void*, *Sun-Slayer Crimson*, *Nine-Dragon Sovereign*, *Frost-Dragon*) transforms the active blade and back-sword array!

## 2.3 45-Stage High-Number Dopamine Curve
Cultivation spans 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*), each containing 9 Sub-Stage Orders (45 Tiers total). Qi capacity scales from $10,000$ to **$50,000,000,000$ (50 Billion)**, with proportional Health scaling ($500 \rightarrow 25,000,000$ HP).

## 2.4 Dual UI Philosophy
- **In-Combat HUD**: Minimalist, unobtrusive, sharp 90° dark obsidian dock (`#0C0E14`), thick HP/Qi meters, pure white realm text, zero emojis.
- **Out-of-Combat Modals**: Dark Obsidian parchment panels (`InventoryController.luau`, `AlchemyController.luau`) featuring 3D character viewport dolls and fitted grid slots.

---

# 3. Core Gameplay Loop

```text
┌─────────────────────────┐
│   1. MORTAL VILLAGE HUB │
└────────────┬────────────┘
             │ Select Expedition Area / Harvest Herbs
             ▼
┌─────────────────────────┐
│  2. EXPLORATION & COMBAT│
└────────────┬────────────┘
             │ Fight Mobs & Bosses with Sword Arts
             ▼
┌─────────────────────────┐
│ 3. REWARD & SCROLL DROPS│
└────────────┬────────────┘
             │ Collect Spirit Stones, Jade Scrolls & Sword Skins
             ▼
┌─────────────────────────┐
│  4. ALCHEMY & ASCEND    │
└────────────┬────────────┘
             │ Refine Dan Pills, Meditate (G) & Conquer Tribulation (B)
             ▼
          Repeat Loop