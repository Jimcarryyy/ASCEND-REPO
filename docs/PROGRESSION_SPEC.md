---

# 11. `docs/PROGRESSION_SPEC.md`

```markdown
# ASCEND-V1 — CULTIVATION PROGRESSION & LOOT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** 45-Stage Realm Engine, Sword Mastery Ranks, Floating Back-Swords, & Alchemy Recipes.

## Purpose
This document defines progression mechanics, cultivation realms, breakthrough behavior, and reward systems for ASCEND.

## Document Connectivity
- Use this doc when designing or modifying cultivation balance, Qi scaling, breakthrough behavior, and floating back-sword progression.
- Pair it with `docs/COMBAT_SPEC.md` for combat scaling and with `docs/ARCHITECTURE_SPEC.md` for the data and service boundaries.
- It is not a market or economy document; use `docs/ECONOMY_AND_MARKET_SPEC.md` for financial systems.

---

## 1. 45-Stage Cultivation Realm Engine

Progression spans 5 Major Realms with 9 Sub-Stage Orders each (45 Tiers total):

| Major Realm Name | Orders | Max Qi Capacity | Gather Rate | Base Health | Aura Color |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Qi Condensation** | Order 1–9 | $10,000 \rightarrow 100,000$ Qi | 120 Qi/s | 500 HP | Cyan (`#00DCFF`) |
| **Foundation Establishment** | Order 1–9 | $250,000 \rightarrow 5,000,000$ Qi | 1,500 Qi/s | 5,000 HP | Emerald (`#32FF78`) |
| **Golden Core** | Order 1–9 | $12,000,000 \rightarrow 250,000,000$ Qi | 45,000 Qi/s | 50,000 HP | Gold (`#FFD700`) |
| **Nascent Soul** | Order 1–9 | $600,000,000 \rightarrow 8,000,000,000$ Qi | 1,200,000 Qi/s | 500,000 HP | Purple (`#B432FF`) |
| **Spirit Severing** | Order 1–9 | $15,000,000,000 \rightarrow 50,000,000,000$ Qi | 80,000,000 Qi/s | 5,000,000 HP | Crimson (`#FF1E1E`) |

---

## 🧘 Qi Meditation Mechanics (`Hotkey G`)

* **Stance**: Native sitting posture (`Humanoid.Sit = true`) with steady hover.
* **Auto-Unequip**: Weapons automatically hide when entering meditation and restore upon exiting (`WeaponManager.SetWeaponVisibility`).
* **Slow Celestial Float**: 3.0-second Sine wave levitation loop ($0.5$ studs up and down) without physics jitter.
* **Fast Recovery**: Restores depleted Qi $3.5\times$ faster than deep breakthrough cultivation.

---

## ⚡ Breakthrough Mechanics (`Hotkey B`)

1. **Minor Breakthrough (Orders 1–8)**: Auto-advances player to Order $N+1$, raising Qi cap and MaxHealth.
2. **Major Breakthrough (Order 9)**: Triggers the server-authoritative **Heavenly Tribulation Lightning Event**. Surviving advances player to Order 1 of the next Major Realm!

---

## 🛸 Floating Back-Sword Array Progression

| Level / Mastery Rank | Floating Back-Sword Visual Display |
| :--- | :--- |
| **Novice (Level 1–10)** | 0 Back-Swords (Hand weapon only) |
| **Apprentice (Level 11–25)** | 1 Floating Sword sheathed vertically on back |
| **Adept (Level 26–50)** | 3 Floating Swords hovering in a tri-fan wing formation on back |
| **Master (Level 51–80)** | 5 Floating Swords hovering in a circular array on back |
| **Sovereign (Level 81–100)** | 7 Radiant Sovereign Swords hovering in a floating cosmic ring on back! |