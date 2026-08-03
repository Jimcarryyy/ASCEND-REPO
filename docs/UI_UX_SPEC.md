# ASCEND-V1 — UI/UX SPECIFICATION & WIREFRAME MAP

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** ScreenGui Hierarchy, In-Combat HUD Layout, Overhead Health Display, Out-of-Combat Modals, & Floating Combat Text.

---

## 1. UI Architecture & Dual Visual Philosophy

ASCEND-V1 enforces a strict visual separation between active combat gameplay and out-of-combat menu management:

* **In-Combat HUD:** Minimalist, unobtrusive, clean geometric progress bars (Health, Stamina, Energy). Dynamic overhead HP bars above player and mob heads. Zero screen-covering text or bloat.
* **Menu Modals:** Handcrafted fantasy artwork frames with heavy stone/parchment textures, 3D ViewportFrame item slot placeholders, and gold trim highlights. Full-screen or centered modal overlays opened via keybinds.

---

## 2. Dynamic Overhead Health & Cultivation Bar (`OverheadUIController.luau`)

Every player, NPC, and dummy in Workspace receives a server-synced floating BillboardGui:

* **Attachment:** Attached to `Head` part (`StudsOffset = Vector3.new(0, 2.5, 0)`, `MaxDistance = 80`).
* **Title Label:** Displays Character Name and Cultivation Realm Title (e.g. `[Qi Condensation - Tier 1]`).
* **Health Fill Transitions:**
  * `> 50% HP`: Emerald Green (`#2ECC71`)
  * `25% - 50% HP`: Gold Yellow (`#F1C40F`)
  * `< 25% HP`: Crimson Red (`#E74C3C`)

---

## 3. Meditation Camera & Visual Wrap

* **Front-View Cinematic Camera**: When meditating (**`G`**), client camera switches to `Scriptable` and positions at `{0, 1.8, -13.5}` facing the character's front.
* **Calm Floating Motion**: Character hovers with a slow, serene `0.5` stud height sine wave (`floatSpeed = 1.6`).
* **Lightweight Body Highlight**: Ethereal `Highlight` wrapper (`FillTransparency = 0.95`, `OutlineTransparency = 0.25`) wrapping player clothing, face, and body in cultivation realm aura.

---

## 4. Complete Roblox Studio Screen Hierarchy

All UI elements reside in StarterGui under two primary master ScreenGui containers:

### A. MainHUD (ScreenGui)
* ResetOnSpawn: false
* IgnoreGuiInset: true
* DisplayOrder: 10
* Hierarchy Layout:
  - SafeArea (Frame, Size: {1, 0}, {1, 0}, BackgroundTransparency: 1)
    - BottomLeft_Status (Frame, AnchorPoint: 0, 1, Position: {0.02, 0}, {0.96, 0})
      - HealthBar_BG (Frame) -> Fill (Frame) -> HealthText (TextLabel)
      - StaminaBar_BG (Frame) -> Fill (Frame)
      - LevelBadge (Frame) -> LevelText (TextLabel)
    - BottomCenter_Abilities (Frame, AnchorPoint: 0.5, 1, Position: {0.5, 0}, {0.96, 0})
      - UIListLayout (FillDirection: Horizontal, Padding: UDim.new(0.02, 0))
      - Slot_M1 (Frame) -> Icon (ImageLabel) -> KeybindHint (TextLabel)
      - Slot_F (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_Q (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_E (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_R (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_Dodge (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
    - TopCenter_BossHUD (Frame, AnchorPoint: 0.5, 0, Position: {0.5, 0}, {0.03, 0})
      - BossHealthBar_BG -> Fill -> PhaseIndicatorText

### B. MenuModals (ScreenGui)
* ResetOnSpawn: false
* IgnoreGuiInset: true
* DisplayOrder: 20
* Hierarchy Layout:
  - BackgroundDim (Frame, Size: {1, 0}, {1, 0}, BackgroundColor3: #000000, Transparency: 0.5)
  - InventoryModal (Frame, AnchorPoint: 0.5, 0.5, Size: {0.7, 0}, {0.75, 0})
    - FantasyFrame_BG (ImageLabel)
    - ItemGridContainer (ScrollingFrame + UIGridLayout)
    - ViewportFrame (3D Placeholder Item Preview)
  - AlchemyModal (Frame)
    - FurnaceRefinementGrid
    - CraftButton

---

## 5. Floating Combat Text (FCT) Specification

When a hit is registered on the server, a client event fires to spawn Floating Combat Text in world space:

* Normal Hit: White text (`#FFFFFF`), Size 18pt, floats upward 3 studs over 0.5 seconds and fades out.
* Critical Hit: Yellow text (`#FFD700`), Size 26pt bold, scale bounce animation (1.0x -> 1.3x -> 1.0x), floats upward 4 studs.
* Blocked Hit: Blue text (`#74B9FF`), Size 16pt, text displays "BLOCKED".
* Status Debuff: Purple/Red text (`#9C2C77`), displays debuff name (e.g., "STUNNED", "QI DEVIATION").