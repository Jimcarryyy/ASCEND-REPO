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

## Additive Combat Update (2026-08-27) — Parrying, Posture & Duel Normalization

### 1. Block & Perfect Parry Deflection Engine (`T` Key)
* **Standard Guard (Hold `T`):** Blocks incoming attacks within the front $180^\circ$ arc, reducing damage by **$80\%$** and knockback by **$70\%$**. Drains Posture based on attack weight ($15\text{ pts}$ for M1 1–4, $40\text{ pts}$ for Finisher, $50\text{ pts}$ for Skills).
* **Perfect Parry (Tap `T` within $0.22\text{s}$):** **$100\%$ Damage Negation**, breaks attacker's posture with a **$0.5\text{s}$ stun**, restores **$+5\%$ Dantian Qi**, triggers golden deflection sparks, and plays metal clash audio (`rbxassetid://9114223175`). Costs $0$ Posture.

### 2. Posture & Guard-Break Mechanics
* **Max Posture Pool:** $100\text{ Points}$.
* **Posture Recovery:** Recovers at $25\text{ pts/s}$ after $1.5\text{s}$ of releasing block.
* **Guard-Break Penalty:** Hitting $0\text{ Posture}$ inflicts a **$1.2\text{s}$ vulnerability stun** ($+25\%$ bonus damage taken) and shield-shatter visual feedback.

### 3. Anti-Stunlock Hyperarmor Buffer
* **$0.6\text{s}$ CC-Immunity Window:** Players receive $0.6\text{s}$ of hard hyperarmor immediately upon recovering from any stun (Parry Stun, Guard-Break, or Wall-Splat), preventing infinite stunlock chains.

### 4. Arena Stat Normalization & Clashes
* **1,000 HP Fair Duels:** Inside the Sector 3 Arena (`InArena == true`), all cultivators receive flat $1{,}000\text{ HP}$ and normalized damage curves for $100\%$ skill parity.
* **Simultaneous Sword Clashes:** Attacks landing within $\pm 0.08\text{s}$ trigger a Sword Clash ($0\text{ damage}$, spark blast, mutual pushback).

---

### 3. `docs/COMBAT_SPEC.md`

```markdown
# ASCEND — Pure Sword Cultivator Combat Specification

> Server-Authoritative Combat, Looping Sword Intent, Parrying & Combo Mechanics

---

## 1. Looping Sword Intent Combat Engine

The Sword Intent engine provides a continuous reward loop for sustained melee aggression:

$$\mathbf{IntentGain = +25\% \text{ per landed M1 hit}} \quad \longrightarrow \quad \mathbf{100\% \text{ Intent} = 1.75\times \text{ Empowered Strike}}$$

1. **Accumulation:** Each confirmed M1 hit that damages a target adds $+25\%$ Intent ($4$ hits to reach $100\%$).
2. **Empowered Strike:** Upon reaching $100\%$ Intent, the bar turns gold (`SWORD INTENT 100%`). The next M1 strike consumes the entire gauge to deal **$1.75\times$ base damage**, triggering golden critical slash VFX, camera impact shake, and floating text (`SWORD INTENT UNLEASHED (1.75X)`).
3. **Loop Reset:** The gauge resets to $0\%$ immediately after the empowered strike connects, starting the loop over.
4. **Combat Inactivity Decay:** If no hits connect for $>2.5$ seconds, Intent continuously decays at **$8.0\%/\text{s}$** down to $0\%$.

---

## 2. 5-Hit M1 Broadsword Combo Chain (`MouseButton1`)

| Step | Animation Asset ID | Duration | Speed | Base Damage | Posture Damage |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **Hit 1** | `rbxassetid://129254042886405` | 0.44s | 0.85x | 18 | 12 |
| **Hit 2** | `rbxassetid://78342794513338` | 0.40s | 0.85x | 19 | 14 |
| **Hit 3** | `rbxassetid://133701354257850` | 0.44s | 0.85x | 21 | 16 |
| **Hit 4** | `rbxassetid://140582503077234` | 0.46s | 0.80x | 23 | 18 |
| **Hit 5** | `rbxassetid://111677132360566` | 0.54s | 0.75x | 28 (Finisher) | 28 |

* **Combat Footwork Commitment:** Movement speed dampens to `WalkSpeed = 8` during M1 swings to ensure clean hitbox registration in PvP.
* **Combo Timeout:** Pausing for $>1.3\text{s}$ between swings resets the combo chain back to Hit 1.

---

## 3. Defense, Parrying & Posture System

* **Standard Guard (Hold `T`):** Blocks incoming attacks within the front $180^\circ$ arc, reducing damage by **$70\%$**. Drains posture based on attack weight ($12 \rightarrow 28\text{ pts}$).
* **Perfect Parry (Tap `T` within $0.22\text{s}$):** **$100\%$ Damage Negation**, breaks attacker's posture with a **$0.5\text{s}$ stagger**, restores $+10\text{ Posture}$, triggers parry spark VFX, and plays clash audio (`rbxassetid://9114223175`). Costs $0$ Posture.
* **Guard-Break Penalty:** Reaching $0\text{ Posture}$ inflicts a **$2.0\text{s}$ vulnerability stun** ($+25\%$ bonus damage taken) with shield-shatter audio.
* **Anti-Stunlock Buffer:** Players receive **$0.6\text{s}$ of hard hyperarmor (`CCImmune`)** upon recovering from any stun.