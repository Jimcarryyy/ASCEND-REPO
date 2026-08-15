---

### 9. `docs/COMBAT_SPEC.md`

```markdown
# ASCEND-V1 — PURE SWORD CULTIVATOR COMBAT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Server-Authoritative Sword Engine, Universal Skillset, Hitboxes, & Magma Cleaves.

---

## 1. Universal 1-Pack Skillset (Low-Friction, High-Impact)

All Flying Swords use the same universal 6-slot input layout with high-impact visual feedback:

| Input | Action / Skill Name | Combat Identity & Visual Render |
| :---: | :--- | :--- |
| **`LMB`** | **Light Sword Slashes** | 3-step wide arc slashes with floating damage numbers and gold/red sparks. |
| **`Shift`**| **Windstep Dash** | Fast, invincible directional travel dash with a motion blur trail. |
| **`F`** | **Magma Cleave** | Launches **3 consecutive sharp molten crescent moon waves** forward (Right Arc $\rightarrow$ Left Arc $\rightarrow$ Heavy Central Moon)! |
| **`Q`** | **Volcanic Tempest** | $360^\circ$ radial magma eruption pushing mobs back and auto-sucking nearby herb drops. |
| **`E`** | **Homing Telekinesis Thrust**| Fires a long-range flying sword projectile that homes in on the target. |
| **`R`** | **Celestial Sunfall (Ultimate)**| A giant 25-stud molten magma crescent moon blade drops from the sky with camera shake! |

## 3. Dynamic Skill Qi Costs & Damage Power Scaling

### A. Dynamic Skill Qi Consumption (% of CultivatedQi)
Skills no longer consume static flat Qi amounts. Skill Qi consumption scales dynamically as a percentage of the player's current `CultivatedQi`:

| Input | Skill Name | Qi Consumption (% of CultivatedQi) | Cooldown | Base Damage |
|---|---|---|---|---|
| **LMB** | Telekinetic Slash Combo | **0%** | 0.6s | 15 / 15 / 20 / 35 |
| **Shift** | Windstep Dash | **3%** | 2.0s | 0 (Velocity Impulse 75) |
| **F** | Magma Cleave | **8%** | 1.5s | 35 |
| **E** | Homing Thrust | **12%** | 5.0s | 30 |
| **Q** | Volcanic Tempest | **15%** | 3.0s | 45 |
| **R** | Celestial Sunfall | **30%** | 8.0s | 80 |

### B. Dynamic Realm Power Multipliers
Skill damage scales dynamically with the cultivator's Realm and Order (`CultivationConfig.GetPowerMultiplier(Realm, Order)`):
$$\text{Final Damage} = \text{Skill Base Damage} \times \text{Cultivator Power Multiplier}$$

* **Power Multiplier Scale:**
  * Qi Condensation Order 1 = $1.0\times$
  * Golden Core Order 1 = $75.0\times$
  * Golden Core Order 9 = $165.0\times$
  * Immortal Ascension Order 9 = $100,000.0\times$
* **TTK & One-Shot Mechanics:**
  * Equal-tier fights (Golden Core vs Golden Core) maintain standard skill-based TTK (~35% HP per Ultimate).
  * High-realm vs Low-realm fights (Golden Core vs Qi Condensation) result in **instant one-shots** due to power multiplier scaling ($165.0\times$ vs $1.0\times$).

### C. In-Combat Qi Recovery Rates
* **Standing / Fighting (Passive):** Restores `CurrentQi` up to `CultivatedQi` in **60 seconds** ($1.66\%$ per second).
* **Active Meditation ([G] Key):** Restores `CurrentQi` up to `CultivatedQi` in **10 seconds** ($10.0\%$ per second).
* **Qi Lock During Meditation:** Pressing **[G]** blocks all combat attacks (`LMB`, `F`, `Q`, `E`, `R`, `Shift`) on both client and server.