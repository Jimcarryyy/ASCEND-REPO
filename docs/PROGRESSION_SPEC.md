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

## 2. Cultivation Hierarchy (10 Major Realms, 90 Orders)

### Historical Baseline
Originally documented as 5 Major Realms (*Qi Condensation* $\rightarrow$ *Spirit Severing*) spanning 45 sub-stage orders on a $100 \rightarrow 10,000$ stat scale.

### Current 10-Realm Progression Scale (Version 1 Cap)
Expanded to **10 Major Realms with 9 Orders each (90 total sub-stage orders)** capping at **$100\text{M} - 150\text{M}$ HP/Qi** for Version 1:

| Tier | Realm Name | Order Range | Max HP & Qi Range (V1) | Progression Vibe & Features |
|---|---|---|---|---|
| **1** | **Qi Condensation** | Order 1–9 | $1,000 \rightarrow 12,000$ | Introductory realm; manual meditation & basic gathering. |
| **2** | **Foundation Establishment** | Order 1–9 | $15,000 \rightarrow 120,000$ | Unlocks 1-Slot Alchemy Dan crafting. |
| **3** | **Golden Core** | Order 1–9 | $75,000 \rightarrow 850,000$ | Unlocks 3-Wave Heavenly Lightning Tribulations. |
| **4** | **Nascent Soul** | Order 1–9 | $350,000 \rightarrow 4.5\text{ Million}$ | Medium Qi Node Fields required for fast regen. |
| **5** | **Spirit Severing** | Order 1–9 | $1.5\text{M} \rightarrow 22\text{ Million}$ | Beast core alchemy required for breakthroughs. |
| **6** | **Void Refining** | Order 1–9 | $7.5\text{M} \rightarrow 90\text{ Million}$ | 5-Wave Lightning Tribulations. |
| **7** | **Body Integration** | Order 1–9 | $25\text{M} \rightarrow 280\text{ Million}$ | High-yield Qi Node Fields. |
| **8** | **Mahayana (Great Vehicle)** | Order 1–9 | $55\text{M} \rightarrow 650\text{ Million}$ | Advanced Alchemy Pills required. |
| **9** | **Tribulation Transcending**| Order 1–9 | $80\text{M} \rightarrow 950\text{ Million}$ | 9-Wave Severe Lightning Tribulations. |
| **10** | **Immortal Ascension** | Order 1–9 | $100\text{M} \rightarrow 1.5\text{ Billion}$ | **Version 1 Absolute Peak** |

---

## 3. Dantian Capacity & Qi Recovery Rules

### Invariant Equation
$$\mathbf{CurrentQi \le CultivatedQi \le MaxQiGoal}$$

1. **`CurrentQi` (Active Energy):**
   * Usable energy consumed when executing skills ($F, Q, E, R, Shift$).
   * Drains on skill cast, recovers via standing/combat or active meditation recovery.
   * **STRICTLY CAPPED AT `CultivatedQi`**.
2. **`CultivatedQi` (Current Cultivated Capacity):**
   * The player's reached Dantian energy storage capacity limit.
   * In-combat passive recovery (standing) and active ground meditation **strictly stop recovering at `CultivatedQi`** (e.g. $76.0\text{k}$). Standard recovery **never** exceeds `CultivatedQi`.
   * Expands toward `MaxQiGoal` ($76.0\text{k} \rightarrow 120.0\text{k}$) ONLY during active meditation inside **Qi Nodes** or by consuming **Alchemy Dan Pills / Beast Cores**.
   * **Persistent Data:** Saved in DataStore V2 profile (`PlayerDataManager.luau`). Survives player disconnects, server shutdowns, deaths/respawns, and pre-breakthrough states.
3. **`MaxQiGoal` (Internal Breakthrough Goal):**
   * The required energy threshold to trigger a Breakthrough to the next Order/Realm (`CultivationConfig.GetOrderTargetQi`).
   * Used behind the scenes for progression logic; **NEVER displayed on the main combat HUD**.

---

## 4. Breakthrough Mechanics & Guidance

* **Breakthrough Requirement:** Allowed ONLY when $\text{CultivatedQi} \ge \text{MaxQiGoal}$ ($120.0\text{k} / 120.0\text{k}$).
* **Qi Preservation on Breakthrough:**
  * When a player presses **[B]** to break through:
    * `Order` increments by 1 (or Realm advances).
    * `MaxQiGoal` expands to the new target (e.g., $120.0\text{k} \rightarrow 150.0\text{k}$).
    * **`CultivatedQi` and `CurrentQi` ARE PRESERVED** (e.g. $120.0\text{k}$ remains $120.0\text{k}$).
    * Display after breakthrough: **`120.0k / 120.0k`**. Player continues cultivating toward $150.0\text{k}$.
* **Encouraging Rejection Guidance:** If a player attempts a breakthrough before reaching `MaxQiGoal`, the server rejects the request and displays a lower-center toast: **`"Keep cultivating! Your Qi isn't ready for breakthrough yet."`**