# ASCEND-V1 — CULTIVATION PROGRESSION & LOOT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Normalized 45-Stage Realm Engine, Sword Mastery Ranks, & Floating Back-Swords.

---

## 1. Normalized 45-Stage Cultivation Realm Engine

Progression spans 5 Major Realms with 9 Sub-Stage Orders each (45 Tiers total), normalized to a clean $100 \rightarrow 10,000$ HP/Qi scale:

| Major Realm Name | Orders | Max Qi Capacity | Gather Rate | Base Health | Aura Color |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Qi Condensation** | Order 1–9 | $100 \rightarrow 300$ Qi | 2 Qi/s | 100 HP | Cyan (`#00DCFF`) |
| **Foundation Establishment** | Order 1–9 | $300 \rightarrow 800$ Qi | 5 Qi/s | 300 HP | Emerald (`#32FF78`) |
| **Golden Core** | Order 1–9 | $800 \rightarrow 2,000$ Qi | 12 Qi/s | 800 HP | Gold (`#FFD700`) |
| **Nascent Soul** | Order 1–9 | $2,000 \rightarrow 5,000$ Qi | 25 Qi/s | 2,000 HP | Purple (`#B432FF`) |
| **Spirit Severing** | Order 1–9 | $5,000 \rightarrow 10,000$ Qi | 50 Qi/s | 5,000 HP | Crimson (`#FF1E1E`) |

---

## 🧘 Qi Meditation Mechanics (`Hotkey G`)

* **Stance**: Seated posture (`Humanoid.Sit = true`) with steady hover.
* **Auto-Unequip**: Weapons automatically hide when entering meditation and restore upon exiting (`WeaponManager.SetWeaponVisibility`).
* **Fast Recovery**: Restores depleted Qi $3.5\times$ faster than passive standing absorption.

---

## ⚡ Breakthrough Mechanics (`Hotkey B`)

1. **Minor Breakthrough (Orders 1–8)**: Advances player to Order $N+1$, raising Qi cap and MaxHealth.
2. **Major Breakthrough (Order 9)**: Triggers the server-authoritative **Heavenly Tribulation Lightning Event**. Surviving advances player to Order 1 of the next Major Realm!