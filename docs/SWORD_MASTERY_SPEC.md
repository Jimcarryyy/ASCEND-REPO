# ASCEND-V1 — SWORD MASTERY & JADE SCRIPTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Pure Sword Cultivator Paradigm, Dynamic Jade Scroll Skills, Floating Back-Sword Array, & 4 Paired Mythic Sets.

## Purpose
This document defines the Sword Art Jade Scroll system, mastery progression, and floating back-sword cosmetic progression for ASCEND.

## Document Connectivity
- Use this doc when designing or implementing skill slot behavior, mastery XP, and floating back-sword visuals.
- Pair it with `docs/PROGRESSION_SPEC.md` for progression thresholds and `docs/ARCHITECTURE_SPEC.md` for the underlying module structure.
- This file is not a UI spec; use `docs/UI_UX_SPEC.md` for presentation details.

---

## 1. Pure Sword Cultivator Paradigm (剑修)

ASCEND-V1 operates exclusively on the **Pure Sword Cultivator** archetype:

- All equipped weapons are **Flying Swords (飞剑)**.
- Weapons attach to `RightGripAttachment` (hand in combat) and `BodyBackAttachment` (sheathed/floating array on back).
- Players do not pick a rigid class—they collect, equip, and master **Sword Art Jade Scrolls** into `Q`, `E`, `R`, `Shift`, and `F` skill slots.

---

## 2. Dynamic Jade Scripture Skill Engine

Players equip collectible/craftable **Jade Scrolls** in the Spirit Pouch Inventory:

```text
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        DYNAMIC JADE SCROLL COMBAT SLOTS                                │
├────────────────────────────────────────────────────────────────────────────────────────┤
│ • SLOT Q: Equipped Sword Art Scroll 1 (e.g. Void Slash / Flame Cleave)                 │
│ • SLOT E: Equipped Sword Art Scroll 2 (e.g. Telekinesis Thrust / Dragon Roar)          │
│ • SLOT R: Equipped Ultimate Scripture (e.g. Sword Barrage / Sun-Slayer Eruption)       │
│ • SLOT SHIFT: Equipped Movement Art (e.g. Windstep Dash / Shadow Teleport)             │
│ • SLOT F: Equipped Parry/Guard Art (e.g. Bagua Qi Shield / Dragon Parry)               │
└────────────────────────────────────────────────────────────────────────────────────────┘

3. Sword Art Mastery Levels (Rank 1 ──► Rank 10)
Using a Sword Art in combat earns Mastery XP:
Rank 1–3: Base damage and standard cooldown.
Rank 4–7: 
+
25
%
+25%
 Damage, 
−
15
%
−15%
 Cooldown, enlarged particle aura size.
Rank 8–10 (MAX): Unlocks new Floating Back-Sword Slots & Master Titles.
4. 3D Floating Back-Sword Array Progression
As player level and Sword Mastery increase, WeaponManager.luau automatically attaches floating 3D swords hovering behind the player's UpperTorso:
Novice (Level 1–10): 0 Back-Swords (Hand weapon only).
Apprentice (Level 11–25): 1 Floating Sword sheathed on back.
Adept (Level 26–50): 3 Floating Swords in a tri-fan wing formation on back.
Master (Level 51–80): 5 Floating Swords in a circular array on back.
Sovereign (Level 81–100): 7 Radiant Sovereign Swords hovering in a floating cosmic ring!
5. 4 Paired Mythic Sets Catalog
All 4 sets feature a 3D Sword Model + a matching 3D Floating 5-Blade Back-Crest Array:
Set Name	Path / Element	3D Sword Model	3D Back-Crest Model	Studio Status
Heavenly Void Set	Cosmic / Space	HeavenlyVoidBlade.fbx	HeavenlyVoidBackCrest.fbx	Imported in Studio ✅
Sun-Slayer Crimson Set	Magma / Fire	SunSlayerCrimsonBlade.fbx	CrimsonFlameBackCrest.fbx	3D Generated in Meshy 🚀
Nine-Dragon Sovereign Set	Jade / Wind	NineDragonSovereignBlade.fbx	AzureDragonBackCrest.fbx	3D Generated in Meshy 🚀
Frost-Dragon Flared Set	Ice / Frost	FrostDragonFlaredBlade.fbx	FrostDragonBackCrest.fbx	3D Generated in Meshy 🚀