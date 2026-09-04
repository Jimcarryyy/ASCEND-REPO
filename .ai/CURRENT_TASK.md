# Current Task Specification — ASCEND

## Purpose
This document defines the single active operational focus of development for ASCEND. When the milestone changes or is completed, this file is overhauled to reflect the new priority. Historical task threads are permanently archived in `CHANGELOG.md`.

**Current Milestone:** Phase 8.2 — Studio Desktop HUD Overhaul & UI Connection  
**Active Timestamp:** September 2026 (Post-Developer Message 183)  
**Active Role Context:** Systems Architect & UI/UX Designer

---

## 🎯 ACTIVE TASK: Clean Desktop HUD Replacement & Studio-Authoritative Wiring

The Lower Layer facilities (Blacksmith Forge, Spirit Tea Pavilion, Starter Guide, and Sparring Grounds) have been integrated and debugged. The legacy HUD has been hidden due to `DisplayOrder` conflicts and overlapping panels. The active priority is constructing and connecting a clean, comprehensive **Desktop HUD** directly within `StarterGui` that integrates all player vitals, trackers, currencies, and menu triggers.

### Engineering & Layout Requirements (Developer Message 183)
1. **ScreenGui Root Setup (`StarterGui.MasterHUDGui`):**
   - Must be authored natively in Studio (`StarterGui`), not generated via `Instance.new` in Lua.
   - `DisplayOrder = 1` (HUD level), ensuring facility modals (`DisplayOrder = 10`) open smoothly above it without occlusion.
   - `ResetOnSpawn = false`, `IgnoreGuiInset = true`.

2. **Anchor Cluster Architecture:**
   - **Top-Center (Global Toast Container):**
     - Houses dynamic floating status banners (herb collection, pill refinement quality, tea buffs).
     - Bound to `StarterPlayerScripts/Controllers/HUDController.luau`.
   - **Bottom-Center (Vitals & Combat Bar):**
     - **Health Bar:** Dual-gradient green fill (`#10B981`) with numeric readout (`CurrentHP / MaxHP`).
     - **Qi Bar:** Azure blue fill (`#3B82F6`) with numeric readout (`CurrentQi / MaxQiGoal`).
     - **Sword Intent Gauge:** Amber fill (`#F59E0B`) partitioned into 25% increments (+25%/hit, 100% discharge flash).
     - **Action Hotbar:** 6 skill slots displaying keybind prompts (`M1`, `Q`, `E`, `F`, `T`, `Shift`) with translucent radial cooldown sweeps.
     - Bound to `StarterPlayerScripts/Controllers/SkillBarController.luau`.
   - **Top-Left (Sect Duty Tracker):**
     - Displays active daily duties from Deacon Zhao with live fractional progress (`(2/3)`).
     - Bound to `StarterPlayerScripts/Controllers/QuestTrackerController.luau`.
   - **Top-Right (Currencies & Sect Identity):**
     - Displays live Spirit Stone count and Sect Contribution Points (CP) with gold/jade coin icons.
     - Bound to `StarterPlayerScripts/Controllers/SkillBarController.luau` / `SectController.luau`.
   - **Bottom-Left (Navigation Menu Tray):**
     - Interactive icon buttons to toggle player interfaces: `[Bag]` (Spirit Pouch), `[Sect]` (Duties/Ranks), `[Map]` (World Zones), `[Meditate]` (Sit Cultivation), and `[Settings]` (Sound/Graphics).

3. **Typography Enforcement (ADR-042):**
   - All headers, titles, currency numbers, and keybind badges must use **`Enum.Font.Bangers`** with a solid black `UIStroke` (`Thickness = 1.5 - 2.0`, `Color = Color3.fromRGB(0, 0, 0)`).
   - All duty descriptions, lore subtitles, and vital stat ratios must use **`Enum.Font.Fundamento`**.

---

## Active Verification & Acceptance Checklist
- [ ] Construct `MasterHUDGui` hierarchy in Studio `StarterGui` matching the 5-cluster layout.
- [ ] Connect `HUDController.luau` to top-center toast notifications and bottom-left modal toggles.
- [ ] Connect `SkillBarController.luau` to bottom-center HP, Qi, Sword Intent, and cooldown sweeps.
- [ ] Connect `QuestTrackerController.luau` to top-left duty frame via `UpdateQuestTracker` remote.
- [ ] Verify zero overlapping occurs when opening `BlacksmithGui`, `TeaHouseGui`, `StarterGuideGui`, or `SectPavilionGui`.

---

## Queued Next: Flying Sword Flight Mode (御剑飞行)
Following HUD connection and sign-off:
1. Wire `V` key toggle in `InputController.luau` (with corresponding mobile touch button).
2. Attach flying sword horizontally beneath feet via `HumanoidRootPart.FlightSwordMount`.
3. Implement 3D flight physics with banking turns and realm-scaled speed (65 -> 140+ studs/s).