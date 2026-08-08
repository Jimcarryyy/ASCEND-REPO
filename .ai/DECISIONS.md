---

### 4. `.ai/DECISIONS.md`

```markdown
# Architecture Decision Log

## Purpose
This document records key architecture decisions for ASCEND, including accepted design patterns, security rules, and strategic pivots.

---

## ADR-012: Codebase Pruning & Legacy Non-Sword File Removal
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Legacy gauntlet and spear weapon scripts cluttered the codebase.
* **Decision:** Deleted `GauntletServer`, `SpearServer`, `GauntletConfig`, and `SpearConfig`. Routed 100% of attack requests strictly through `FlyingSwordServer.luau`.

## ADR-013: Stat Progression Curve Normalization ($100 \rightarrow 10,000$ HP/Qi)
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Astronomical 50B Qi numbers caused UI layout overflows and arithmetic issues.
* **Decision:** Normalized stat progression across all 5 Cultivation Realms (45 Orders) to a clean $100 \rightarrow 10,000$ HP/Qi RPG scale in `CultivationConfig.luau`.

## ADR-014: Studio-Authoritative 3D Attachment Workflow
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Pure CFrame offsets in code required tedious trial-and-error adjustments.
* **Decision:** Position `RightGripAttachment` and `BodyBackAttachment` visually inside 3D models in Studio + live CMD calibration. `WeaponManager.luau` reads model attachments directly on spawn.

## ADR-015: Traditional Xianxia Light-Mode Flat 2D UI Palette
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Needed a high-contrast, clean UI system suited for mobile & PC.
* **Decision:** Adopted the 4-color Traditional Xianxia Palette across all HUDs and Modals:
  - `#1D4533` (Deep Jade Green - Headers, Text, Borders, HP)
  - `#F7EAE0` (Warm Cream White - Main Modal Panel)
  - `#F9D2BA` (Soft Peach Accent - Sub-cards & Grid Slots)
  - `#5E3122` (Rich Mahogany Wood - Buttons, Subtext, Qi)

## ADR-016: Ultra-Scaled Down MVP Architecture (5 Master 3D Base Models & 1 Master Sect Island)
* **Status:** Accepted (Updated 2026-08-08)
* **Context:** Generating and calibrating 32 individual 3D models and massive continent maps creates severe developer burnout and mobile memory lag.
* **Decision:** 
  1. **Weapons = 100% Passive Stat Multipliers + Visual Prestige:** Launch V1 with 5 Master Base Sword Models (*Mortal Iron*, *Jade Dragon*, *Sun Slayer*, *Thunder Frost*, *Heavenly Void*) in `ReplicatedStorage` dynamically re-colored/tinted via `ItemConfig.luau` (`PrimaryColor`).
  2. **Universal 1-Pack Skillset:** All swords share 1 universal R15 animation pack and 6 hotbar skill keys (`M1` Slashes, `Shift` Windstep, `F` Magma 3-Wave Crescent Cleave, `Q` Area Blast, `E` Homing Sword, `R` Sunfall Ultimate).
  3. **1 Master Sect Island ($500 \times 500$ studs):** Launch V1 on a single, compact, high-density Stylized Painted Low-Poly island with a 15-second walk loop connecting Spawn, Practice Dummies, Herb Meadows, Bronze Cauldron, and Sword Gacha Altar. Future zones added via portals in post-launch updates.
  4. **Deprecated Obsolete Documents:** Marked `SWORD_MASTERY_SPEC.md` and `ECONOMY_AND_MARKET_SPEC.md` as deprecated for V1 MVP to streamline focus onto core player retention and gacha loops.