---

# 3. `docs/UI_UX_SPEC.md`

```markdown
# ASCEND — UI/UX Design System & Layout Specification

## 1. Core Engineering Principles

### 1.1 Studio-Authoritative Hierarchy (Strict Rule — ADR-041)
**Runtime programmatic UI generation via `Instance.new` inside Lua scripts is strictly prohibited.**
All GUI layouts, frames, buttons, gradients, text labels, and UIStrokes must be constructed inside Studio within `StarterGui`. Client controllers are strictly restricted to:
- Listening to UI events (`Activated`, `MouseEnter`, `MouseLeave`).
- Populating dynamic text, progress bar scales, and list templates.
- Executing visual tweens (opacity fades, positional slides).
- Toggling canvas visibility (`Enabled = true / false`).

### 1.2 Standardized Typography System (ADR-042)
- **Titles, Headers, Station Billboards & NPC Names:** `Enum.Font.Bangers`
  - All Bangers text must include a solid black `UIStroke`:
    - `UIStroke.Color = Color3.fromRGB(0, 0, 0)`
    - `UIStroke.Thickness = 1.5` (Labels < 24pt) / `2.0` (Labels >= 24pt)
- **Body Copy, Descriptions, Stats & Dialogue:** `Enum.Font.Fundamento`
  - Clean, elegant readability tailored for Eastern Xianxia prose.

### 1.3 DisplayOrder Layering Hierarchy (ADR-043)
To eliminate overlapping modals and render priority conflicts, every ScreenGui in `StarterGui` must have an assigned `DisplayOrder`:

| DisplayOrder | ScreenGui Name | Functional Purpose |
| :---: | :--- | :--- |
| **1** | `MasterHUDGui` | Persistent desktop/mobile gameplay HUD (Vitals, Skills, Currencies). |
| **2** | `LowViewPortSkillsGUI` | Fallback skill cluster for compact mobile viewports. |
| **5** | `OverheadUI` | World BillboardGuis for player, mob, and dummy vitals. |
| **10** | `BlacksmithGui` | Weapon refinement (+10) and blade sharpening forge modal. |
| **10** | `TeaHouseGui` | Spirit tea ordering and buff catalog modal. |
| **10** | `SparringGuidanceGui` | Training dummy DPS tracking and sparring trial modal. |
| **10** | `StarterGuideGui` | 4-tab interactive player onboarding guide modal. |
| **10** | `SpiritPouchInventoryGui` | 60-slot storage, 2D weapon previews, and inspection window. |
| **10** | `SectPavilionGui` | Sect duties, disciple rank promotions, and daily stipend modal. |
| **10** | `AlchemyCauldronGui` | 3-slot herb combination and temperature minigame modal. |
| **12** | `ArenaGUI` | Matchmaking status, countdown banners, and match resolution. |
| **20** | `GlobalToastNotifGui` | Floating status messages and harvest notifications. |
| **100** | `LoadingScreen` | ReplicatedFirst initial gate and asset preloader canvas. |

---

## 2. Color Token System (Dark Obsidian & Antique Gold — ADR-015)

| Token | Hex Value | RGB Value | Application |
| :--- | :--- | :--- | :--- |
| `DarkObsidian` | `#111827` | `17, 24, 39` | Master modal background, deep canvas fill. |
| `MidnightSteel` | `#1C2638` | `28, 38, 56` | Item slot cards, panel surfaces, inner frames. |
| `AntiqueGold` | `#C49A4A` | `196, 154, 74` | Modal borders, title underlines, primary buttons. |
| `BronzeGold` | `#8B6B32` | `139, 107, 50` | Inactive button borders, secondary separators. |
| `WarmIvory` | `#F1E8D2` | `241, 232, 210` | Primary header text, button labels, key stats. |
| `MutedSilver` | `#9CA3AF` | `156, 163, 175` | Description copy, cooldown counters, subtitles. |
| `JadeGreen` | `#10B981` | `16, 185, 129` | Health bar fill, positive buffs, successful forge. |
| `AzureBlue` | `#3B82F6` | `59, 130, 246` | Qi bar fill, telekinesis accents, meditation motes. |
| `AmberGold` | `#F59E0B` | `245, 158, 11` | Sword Intent bar fill, empowered strikes, criticals. |
| `CrimsonRed` | `#EF4444` | `239, 68, 68` | Guard-break warning, damage taken, failed forge. |

---

## 3. Master Desktop HUD Layout (`StarterGui.MasterHUDGui`)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [TOP-LEFT]                          [TOP-CENTER]               [TOP-RIGHT]  │
│ Sect Duty Tracker               Global Toast Banners          Spirit Stones │
│ "Refine 3 Herbs (2/3)"         "Discovered 100-Yr Ginseng"         48,285   │
│                                                               Contribution  │
│                                                                 1,970 CP    │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│ [BOTTOM-LEFT]                       [BOTTOM-CENTER]                         │
│ Navigation Tray            HP  [████████████████████████] 1,500/1,500       │
│ [Bag] [Sect] [Map]         QI  [████████████████████████]   850/850         │
│ [Meditate] [Settings]      INT [██████████░░░░░░░░░░░░░░]   60% (3/5)       │
│                            ┌───┬───┬───┬───┬───┬───┐                        │
│                            │ M1│ Q │ E │ F │ T │Shift                       │
│                            └───┴───┴───┴───┴───┴───┘                        │
└─────────────────────────────────────────────────────────────────────────────┘

3.1 Cluster Breakdown
Top-Center (Global Toast Notifications):
Renders animated status toasts (vintage herb discoveries, pill refinement grade, tea drinking confirmation).
Managed by HUDController.luau.
Bottom-Center (Vitals & Action Hotbar):
HP Bar: Dual-gradient jade fill (#10B981) with white text (CurrentHP / MaxHP).
Qi Bar: Azure blue fill (#3B82F6) displaying internal energy.
Sword Intent Bar: Segmented amber bar filling in 25% increments (4 hits = 100% discharge flash).
Action Hotbar: 6 slots displaying keybinds (M1, Q, E, F, T, Shift) with radial cooldown sweeps.
Managed by SkillBarController.luau.
Top-Left (Sect Duty Tracker):
Shows active daily duties from Deacon Zhao with real-time numeric tracking ((2/3)).
Managed by QuestTrackerController.luau.
Top-Right (Currencies & Identity):
Displays Spirit Stones and Sect Contribution Points (CP) with gold/jade currency icons.
Managed by SkillBarController.luau / SectController.luau.
Bottom-Left (Navigation Menu Tray):
Interactive button tray toggling modals: [Bag], [Sect], [Map], [Meditate], and [Settings].
Managed by HUDController.luau.
4. Lower Sect Facility Modals
4.1 Blacksmithing Forge (StarterGui.BlacksmithGui)
Station Target: Master Blacksmith Anvil / Sect_NPC_MadameTie.
Panels:
Equipped Weapon Card: Displays equipped sword name, rarity border, refinement level (+0 to +10), and base ATK bonus.
Refine Action Panel: Displays material requirements (MountainIronIngot, Spirit Stones), success percentage chance, and "Refine Blade" action button.
Blade Sharpening Panel: Displays 100 Spirit Stone cost, +10% Crit Chance description, and "Sharpen Blade" action button with active countdown timer.
4.2 Spirit Tea Pavilion (StarterGui.TeaHouseGui)
Station Target: Sect_NPC_XiaoLing.
Panels:
Tea Selection Grid: 3 interactive cards displaying Jade Dew, Crimson Ginseng, and Dragon Well.
Details Panel: Outlines instant recovery values, timed buff duration (10–15 min), Spirit Stone price, and "Brew & Drink" action button.
4.3 Training Grounds & Sparring Guidance (StarterGui.SparringGuidanceGui)
Station Target: Sect_NPC_InstructorWu.
Panels:
Performance Tracker: Displays real-time and peak DPS recorded across the 3 Ironwood Dummies.
Action Controls: "Start Sparring Trial" button (prompts 3-dummy combo challenge) and "Reset DPS" button (clears combat accumulators).
4.4 Sect Starter Guide (StarterGui.StarterGuideGui)
Station Target: Sect_NPC_ElderQing.
Tabs (Bangers headers with black UIStroke):
Controls & Movement: Keybind table (M1, CTRL, Shift, T, C, R, B, V, Q, E, F).
Cultivation & Breakthroughs: Explains Dantian Qi accumulation, 2.0x Qi nodes, and heavenly tribulations.
Sword Intent & Blades: Details the 5-hit combo, Sword Intent empowerment, and the 5 sword families.
Sect Duties & Arena: Details daily duties, CP ranks, and the 1v1 Sparring Arena rules.