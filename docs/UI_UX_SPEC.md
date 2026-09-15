# ASCEND — Authoritative UI/UX Design & Implementation Specification

> **Interface Design & Visual Standard Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/StarterGui/` & `src/StarterPlayer/StarterPlayerScripts/Controllers/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. UI Architectural Foundations (ADR-041)

ASCEND enforces a strict **Studio-Authoritative Interface Architecture**:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             STARTERGUI INSTANCE                             │
│       (Authored natively in Roblox Studio — Layout, Sizing, Anchors)        │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼  Scanned & Bound by
┌─────────────────────────────────────────────────────────────────────────────┐
│                          CLIENT CONTROLLER ENGINE                           │
│        (HUDController, ModalWindowManager, CharacterStatsController)        │
│                                                                             │
│  - Never constructs UI hierarchies via Instance.new                         │
│  - Binds UI event listeners (Activated, MouseEnter, MouseLeave)             │
│  - Manages TweenService animations and property transitions                 │
│  - Observes network remotes and syncs visual meters                         │
└─────────────────────────────────────────────────────────────────────────────┘
Core UI Development Rules
Zero Programmatic Construction for Static UI: All frames, labels, buttons, image panels, and viewports must be created and styled natively within Roblox Studio under StarterGui. Luau scripts are strictly forbidden from building static window layouts with Instance.new.
Controller Separation: Controllers only acquire references via :WaitForChild(), bind interactions, and execute dynamic state updates (e.g., width tweening, visibility toggles, text formatting).
Strict Resolution Independence: All sizing must utilize a hybrid approach: Scale for responsiveness across Mobile/PC, coupled with UIAspectRatioConstraint and UISizeConstraint to prevent distortion on ultrawide monitors (governed by DeWidth.client.luau).
2. Typography Standard (ADR-042)
ASCEND enforces a strict two-tier typography rule across all user interfaces, world billboards, and dialogs:
code
Text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       TIER 1: HEADERS & ACTION TEXT                         │
│  Font: Enum.Font.Bangers                                                    │
│  Stroke: Mandatory UIStroke (Thickness: 1.5 - 2.0, Color: Color3(0, 0, 0))  │
│  Usage: Window Titles, Skill Labels, Overhead Names, Damage Numbers,       │
│         Station Prompts, Boss Banners                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                         TIER 2: BODY & LORE TEXT                            │
│  Font: Enum.Font.Fundamento                                                 │
│  Stroke: Optional subtle stroke (Thickness: 1.0, Transparency: 0.4)         │
│  Usage: Item Descriptions, Cultivation Lore, NPC Dialogues, Quest Log,      │
│         Detailed Attribute Breakdowns                                       │
└─────────────────────────────────────────────────────────────────────────────┘
Font Pairing Specifications
Category	Primary Font	Size Range	Stroke Requirement	Usage Context
Window Titles	Enum.Font.Bangers	
22
−
32
 pt
22−32 pt
Solid Black (1.5 - 2.0\text{ px})	Forge, Alchemy, Sect Codex titles.
Action & Numbers	Enum.Font.Bangers	
16
−
28
 pt
16−28 pt
Solid Black (1.5 - 2.0\text{ px})	Combat damage, cooldown counters, keybind hints.
Overhead Billboard	Enum.Font.Bangers	
14
−
18
 pt
14−18 pt
Solid Black (1.5\text{ px})	Cultivator nameplates and realm title tags.
Dialogues & Lore	Enum.Font.Fundamento	
14
−
18
 pt
14−18 pt
None or Muted Shadow	Elder dialogues, quest briefs, item flavor text.
Data Attributes	Enum.Font.Fundamento	
13
−
16
 pt
13−16 pt
None	Stat values, item requirements, inventory counts.
3. Visual Framing Standard (9-Slice Panels)
All window containers, dialogue backdrops, tooltips, and modal panels must use the standardized Xianxia ornamental 9-slice texture:
Asset ID: rbxassetid://115367926298823
ScaleType: Enum.ScaleType.Slice
SliceCenter: Rect.new(30, 30, 70, 70)
Standard Background Fill: Color3.fromRGB(18, 20, 26) (Dark Obsidian/Charcoal) with BackgroundTransparency = 0.15
Accent Border Color: Color3.fromRGB(212, 175, 55) (Antique Gold) or Color3.fromRGB(56, 189, 248) (Jade Cyan)
4. Color Palette & Token System
code
Text
┌─────────────────────────────────────────────────────────────────────────────┐
│                             CORE COLOR TOKENS                               │
│                                                                             │
│  Emerald Health      : #10B981 (Active)  / #064E3B (Backdrop)               │
│  Ocean Qi            : #0EA5E9 (Active)  / #0C4A6E (Backdrop)               │
│  Posture Amber       : #F59E0B (Guarding)/ #EF4444 (Critical Break)          │
│  Sword Intent Gold   : #FACC15 (100% Empowered) / #713F12 (Charging)        │
│  Obsidian Charcoal   : #12141A (Container Background)                       │
│  Antique Dao Gold    : #D4AF37 (Ornamental Borders & Accents)               │
└─────────────────────────────────────────────────────────────────────────────┘
5. Master HUD Architecture (MasterHUDGui)
Governed by HUDController.luau, the HUD provides real-time combat status anchored cleanly in the viewport.
code
Text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [Top Left]                                                   [Top Center]   │
│ - Disciple Status Icon                                    BossHealthHUD     │
│                                                       (Active in Encounters)│
│                                                                             │
│                                                                             │
│                                                                             │
│ [Bottom Left: 340px Column Stack]                        [Bottom Center]    │
│ ┌───────────────────────────────┐                       ┌─────────────────┐ │
│ │ Cultivator Name & Realm Badge │                       │ Active Skillbar │ │
│ ├───────────────────────────────┤                       │ [Q] [E] [F]     │ │
│ │ Health Bar (Emerald Green)    │                       │ [Dash] [Guard]  │ │
│ ├───────────────────────────────┤                       └─────────────────┘ │
│ │ Qi Gauge (Celestial Cyan)     │                                           │
│ ├───────────────────────────────┤                                           │
│ │ Posture Meter (Amber Warning) │                                           │
│ ├───────────────────────────────┤                                           │
│ │ Sword Intent (4-Tier Gold)    │                                           │
│ ├───────────────────────────────┤                                           │
│ │ Cultivation Exp Progress Bar  │                                           │
│ └───────────────────────────────┘                                           │
└─────────────────────────────────────────────────────────────────────────────┘
1. Bottom-Left 340px Column Stack Details
The core vitals stack is anchored to the bottom-left corner with a standardized width of 340 pixels:
Realm Header: Displays avatar icon, player username, and current Realm/Order badge (e.g., Foundation Establishment - Order 3).
Health Meter: Smoothly tweens using TweenService (Quad out, 0.25s). Features a secondary white "lag bar" that displays received damage chunks.
Qi Gauge: Renders available spiritual energy for skills and dashing. Flashes subtle cyan upon skill casting.
Posture Meter: Visible while guarding or when posture is 
<
100
%
<100%
. Transitions from Amber (#F59E0B) to Bright Crimson (#EF4444) when posture falls below 20%.
Sword Intent Bar: Divided into 4 segments (
25
%
25%
 per segment). Flashes bright Solar Gold (#FACC15) with an active particle glow when fully charged (
100
%
100%
).
Cultivation Progress Bar: Slim bottom track tracking current progress toward the next breakthrough.
2. Skill Bar (SkillBarController.luau)
Anchored bottom-center.
Displays slots: Q (Tempest), E (Thrust), F (100-Slash Domain), Shift (Dash), T (Guard/Parry), C (Meditation), R (Draw/Sheath), V (Flight).
Cooldowns render as a radial dark overlay with a centered countdown text in Bangers font.
Flashes white for 0.15s upon becoming ready.
6. Modal Window Stack Management (ADR-043)
Managed centrally by ModalWindowManager.luau to eliminate overlapping interfaces and conflicting control states:
code
Text
[Player Triggers UI View]
                                  │
                  ModalWindowManager.Open(viewName)
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
[Close Any Currently Open Modal]            [Configure Game State]
- Tween Old View Off-Screen                 - Set UserInputService.MouseBehavior = Default
- Unbind Old Dialog Listeners               - Lock Character Movement (WalkSpeed = 0)
                                            - Blur Background Lighting (DepthOfField)
                                                           │
                                                           ▼
                                              [Tween In New Modal View]
Governed Modals
CharacterStatsGui (P key)
InventoryGui (B prompt or Bag icon)
NoticeBoardGui (Tab or Deacon Zhao station)
AlchemyGui (Master Shen cauldron)
BlacksmithGui (Madame Tie forge)
TeaHouseGui (Xiao Ling tea pavilion)
StarterGuideGui (Elder Qing pavilion)
ArenaGui (Arena master station)
7. Floating Combat Text & Visual Feedback
Rendered client-side via CombatVFXController.luau:
code
Text
┌─────────────────────────────────────────────────────────────────────────────┐
│                           FLOATING COMBAT TEXT MATRIX                       │
│                                                                             │
│  Standard Hit : White #FFFFFF | Size 20 | Bangers | Black Stroke (1.5px)    │
│  Crit / Intent: Gold  #FACC15 | Size 28 | Bangers | "SWORD INTENT! (1.75X)" │
│  Blocked Hit  : Slate #94A3B8 | Size 18 | Bangers | "BLOCKED" (Muted)       │
│  Parry Clash  : Gold  #FDE047 | Size 24 | Bangers | "PARRY!" + Gold Sparks  │
│  Guard Broken : Red   #EF4444 | Size 30 | Bangers | "GUARD BROKEN!" (Shake) │
└─────────────────────────────────────────────────────────────────────────────┘
Animation & Physics
Spawning: Spawns at hit location with a random horizontal offset (
±
1.2
 studs
±1.2 studs
).
Motion: Ascends 
+
3.5
 studs
+3.5 studs
 vertically over 
0.75
 seconds
0.75 seconds
 with Quad-Out easing.
Fade: Linearly fades TextTransparency and TextStrokeTransparency from 
0
→
1
0→1
 over the final 
0.3
 seconds
0.3 seconds
 before calling :Destroy().
Hitstop: Applied to the local attacker on critical hits (
0.04
s
0.04s
) to deliver satisfying tactile impact.
8. Master ScreenGui Registry (StarterGui)
All 10 authoritative ScreenGuis residing in StarterGui:
ScreenGui Name	Core Controller	Primary Responsibilities
MasterHUDGui	HUDController.luau	Vitals stack, skill bar, intent gauge, dash indicator, flight state.
CharacterStatsGui	CharacterStatsController.luau	Full-page cultivation sheet, attributes, title tags, realm progression details.
InventoryGui	InventoryController.luau	30-slot grid inventory, weapon slotting, refinement display, item tooltips.
AlchemyGui	AlchemyController.luau	Cauldron temperature needle, herb slotting, pill crafting animation.
BlacksmithGui	BlacksmithController.luau	Madame Tie's blade upgrade UI, ore requirements, success rate preview.
TeaHouseGui	TeaHouseController.luau	Xiao Ling's tea menu, spirit stone payment, active buff timer overlays.
NoticeBoardGui	QuestTrackerController.luau	Sect daily duties, rank tiers (D, C, B, A), bounty claiming.
StarterGuideGui	StarterGuideController.luau	Elder Qing's 4-tab interactive beginner codex and sect orientation.
ArenaGui	ArenaController.luau	Competitive matchmaking queues, 1v1 duel countdowns, match results.
BossHealthHUD	HUDController.luau	Top-center health bar, phased boss title, enrage timer, armor breaks.