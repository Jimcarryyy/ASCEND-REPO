# Current Task Specification — ASCEND

## Purpose
This file defines the **single active task**. When a task completes or changes, replace this file's content — do not append a new block underneath the old one. Completed work moves to `CHANGELOG.md`.

**Last consolidated:** 2026-09-02, from the most recent dated source (`CHANGELOG.md`, 2026-08-27 entry: "Combat Overhaul, 3D Inventory Viewports & 1v1 Arena Polish").

---

## 🎯 ACTIVE TASK: Flying Sword Flight Mode (御剑飞行)

Per the most recent "Next Immediate Tasks" note (2026-08-27), this is the last confirmed active thread. **Confirm with the developer this is still accurate before resuming work** — several other candidate "next tasks" exist in the file history and it's unclear which was actually picked up (see Open Questions below).

### Checklist
- [ ] Dedicated `V`-key flight toggle (add mobile flight button too).
- [ ] Sword mounts horizontally beneath feet (`HumanoidRootPart.FlightSwordMount`).
- [ ] True 3D omnidirectional flight physics: `W`/`S` pitch & thrust, `A`/`D` strafe, `Space` ascend, descend key **TBD — conflicts with existing bindings, see below**.
- [ ] Dynamic aerodynamic banking into turns.
- [ ] Realm-scaled flight velocity (Base 65 → Peak 140+ studs/s).

### ⚠️ Blocking issue before implementation
Historical notes propose `CTRL`/`C` for flight descend, but live code (`InputController.luau`) already binds:
- `CTRL` → Sprint toggle
- `C` → Meditation toggle

Flight descend needs a different key, or flight mode needs to temporarily override those bindings while `IsFlying == true`. Decide before wiring input.

---

## Also flagged as "next" in recent history — needs prioritization call
- **Bottom-Center Vital & Sword Intent HUD:** redesign HP/Qi/Sword Intent gauge layout in Studio.
- **Tier 5–8 Sword Model Integration:** `VioletSoulSovereignJian`, `VoidStarCleaverDao`, `AzurePatriarchHeritageJian`, `RadiantImmortalSovereignJian` — import, pivot, attach `SwordAttachment`/`BackSwordAttachment`.
- **Center-Reticle Skill Aim Trajectory:** wire `E`/`Q`/`F` to fire along the camera-center reticle raycast.

## Open questions (surface to developer, don't guess)
1. Was **Spirit Beast AI / Hunting Engine** (Task 7.1D in older notes) ever started? It's absent from the most recent next-steps list.
2. Is **Sect Leaderboards** (`LeaderboardManager.luau`) actually merged, or still just designed on paper?
3. Which of the three "next task" candidates above should actually be worked next — Flight Mode, HUD redesign, or sword assets?