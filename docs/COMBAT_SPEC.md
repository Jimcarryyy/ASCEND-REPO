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

### Flying Sword Skill Set & Cooldown Timings (Added 2026-08-20)

- **M1 — Celestial Sword Slash:** 4-hit combo chain ($0.4\text{s}, 0.4\text{s}, 0.5\text{s}, 1.0\text{s}$ cooldowns).
- **Q — Sword Tempest:** 360° blade vortex ($3.0\text{s}$ cooldown).
- **E — Telekinesis Thrust:** Piercing long-range sword beam ($5.0\text{s}$ cooldown).
- **F — Heavy Slam:** Heavenly blade poise-break slam ($1.5\text{s}$ cooldown).
- **Shift / Q — Flash Step:** Evasive dash with I-frames ($2.0\text{s}$ cooldown).

### Combat Movement, Combo String & Qi Dash Specifications

#### 1. 5-Hit Heavy Broadsword Combo (`MouseButton1`)
* **Timing & Pacing:**
  * Attack 1: `rbxassetid://129254042886405` (`0.44s`, `0.85x speed`)
  * Attack 2: `rbxassetid://78342794513338` (`0.40s`, `0.85x speed`)
  * Attack 3: `rbxassetid://133701354257850` (`0.44s`, `0.85x speed`)
  * Attack 4: `rbxassetid://140582503077234` (`0.46s`, `0.80x speed`)
  * Attack 5: `rbxassetid://111677132360566` (`0.54s`, `0.75x speed` Heavy Finisher)
* **Combat Footwork Commitment:** During any M1 swing, `WalkSpeed` is dampened to `8` studs/sec to ground the martial attack and ensure clean hitbox registration in PvP.
* **Anti-Spam Duration Lockout:** Swings cannot be interrupted mid-arc by spam-clicking. Pausing for `> 1.3s` resets the combo back to Attack 1.
* **Audio & Trail Sync:** Authentic slash sound `rbxassetid://79218449800283` and tier-colored trail ribbons activate strictly during slash execution.

#### 2. Repeatable 2-Stage Qi Dash (`LeftShift`)
* **Sequence:** Dash 1 (`rbxassetid://118004062849712`) ──> Dash 2 (`rbxassetid://87494050060721`).
* **Cooldown:** 3.0s.
* **Burst Velocity:** 88 studs/sec for 0.20s (~18 studs distance) with smooth 0.08s deceleration decay.
* **Lockout:** Complete input/attack lockout during the 0.20s dash window.
* **Sprint Continuity:** Automatically resumes full sprinting if `W` is held when dash completes.

#### 3. Arena vs Open-World Speed Scaling
* **In Arena (`Character:GetAttribute("InArena") == true`):** Walk: `16` | Sprint: `28` (Deepwoken-style balanced combat).
* **Outside Arena (Open World):** Walk: `18` | Sprint: `52` (High-speed exploration).