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


## 3. Master Desktop & Mobile HUD Layout (`StarterGui.MasterHUDGui`)

### DisplayOrder Standard: `MasterHUDGui.DisplayOrder = 10` (Modals = 50)

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [TOP-LEFT]                          [TOP-CENTER]               [TOP-RIGHT]  │
│ TopLeftDutyTracker (Y = +56px)    ToastContainer            TopRightCurrency│
│ \"Herbal Foraging Duty  0/5\"     \"Discovered 100-Yr Ginseng\"  SPIRIT STONES  │
│ \"Alchemy Refine        0/1\"                                  48,285       │
│ \"Sparring Discipline   0/3\"                               SECT CONTRIBUTION│
│                                                               1,910 CP      │
│ ZoneFrame                                                                   │
│ \"Qi Condensation - 2.0x SPEED\"                                             │
│                                                                             │
│                                                                             │
│                                                                             │
│                                     [BOTTOM-CENTER]                         │
│                           VitalsContainer                                   │
│                           HP  [████████████████████████] 637.9K / 637.9K    │
│                           QI  [████████████████████████] 479.1K / 479.1K    │
│                           INT [████████████████████████] SWORD INTENT 100%  │
│                                                                             │
│                           BottomCenterFrame.HotbarContainer (10 Slots)      │
│                           ┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐          │
│                           │ B │ C │ E │ F │ M1│ Q │ R │SHF│ T │ V │          │
│                           └───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘          │
│                           BottomNavTray                                     │
│                           [Arena]   [Bag]   [Guide]   [Meditate]   [Sect]   │
└─────────────────────────────────────────────────────────────────────────────┘
Complete 12-Modal Registry in StarterGui (DisplayOrder = 50, 
Y
=
0.38
Y=0.38
):
BlacksmithGui — Equipped blade preview, refinement up to +10, and blade sharpening buff.
TeaHouseGui — Jade Dew (+250 Qi), Crimson Ginseng (+500 HP), and Dragon Well (+15% Intent rate).
StarterGuideGui — 4-tab interactive guide (Controls, Realms & Qi, Sword Intent, Sect Duties).
SparringGuidanceGui — Combat fundamentals, combo trial progress (0/3), and dummy DPS reset.
AlchemyGui — 12-slot herb pouch grid, 3 cauldron combination slots, metrics preview, and formula guide.
SwordAltarGachaGui — 1x/10x Flying sword awakening, pity counter (50-pull guarantee), and drop rates.
ContributionShopGui — CP exchange store for flight manuals, breakthrough dans, and scabbards.
BankVaultGui — 2-panel inventory transfer (Pouch vs. Vault Stash) + vault expansion.
WildernessPortalGui — Zone 2 Beast Domain gate requirements, monster warnings, and teleport confirmation.
PatriarchAudienceGui — Major realm breakthrough ceremonies, power multiplier previews, and 9-fold lightning warnings.
CouncilElderDiscussionGui — 3-tab discourse hub for Elders Mu (Pills), Ba (Formations), and Ling (Scriptures).
AncestorSeclusionGui — Seclusion tracker with 
+
5.0
×
+5.0×
 Qi multiplier and low-key cultivation wisdom.

 ## Section 9: Universal 9-Slice Textured Panel Standard (Phase 8.4)

### 9.1 Background Panel Asset Token
All major facility modals and character windows have been standardized to the custom Chinese bamboo & antique gold textured frame asset:
* **Asset ID:** `rbxassetid://115367926298823`
* **ScaleType:** `Enum.ScaleType.Slice`
* **SliceCenter:** `Rect.new(146, 120, 878, 120)`
* **SliceScale:** `1.0`
* **BackgroundTransparency:** `1.0`
* **BorderSizePixel:** `0`

### 9.2 Layering & Alignment Standard
* **Full-Screen Coverage:** All modal ScreenGuis must set `IgnoreGuiInset = true` so the dark backdrop (`ModalBackdrop`, `#000000` with $0.50\text{--}0.55$ transparency) covers 100% of the screen under CoreGui topbars.
* **True Middle-Center Placement:** Modal main windows must be strictly positioned at:
  * `AnchorPoint = Vector2.new(0.5, 0.5)`
  * `Position = UDim2.new(0.5, 0, 0.5, 0)`
* **DisplayOrder Hierarchy:**
  * `MasterHUDGui`: `10`
  * All Facility Modals (`BlacksmithGui`, `TeaHouseGui`, `SectPavilionGui`, `AlchemyGui`, `StarterGuideGui`, `CharacterStatsGui`): `50`
  * Toast Notifications: `70`
  * Loading Screen: `100`

### 9.3 Inner Sub-Panel Styling
To match the obsidian bamboo texture:
* `BackgroundColor3`: `#0E1016` (Deep Warm Obsidian) with `0.20` transparency.
* `UIStroke`: `#B4914B` (Antique Gold, $1.5\text{px}$) matching the corner sword medallions.
* `UICorner`: `8px` radius.

### 9.4 High-Contrast Action Buttons
All modal confirmation and action buttons must feature high-contrast pure white text:
* **Celestial Azure Actions (Sharpening / Stipends / Guide Enter):** `#0096BE` fill, `#00DCFF` ($2.0\text{px}$) outline, `#FFFFFF` Bangers text with $1.5\text{px}$ black stroke.
* **Forged Amber Actions (Refinement / Promotions):** `#B45309` fill, `#FDE047` ($2.0\text{px}$) outline, `#FFFFFF` Bangers text with $1.5\text{px}$ black stroke.
* **Radiant Jade Actions (Tea Brewing / Quest Claims):** `#10B981` fill, `#34D399` ($2.0\text{px}$) outline, `#FFFFFF` Bangers text with $1.5\text{px}$ black stroke.