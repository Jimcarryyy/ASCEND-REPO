# ASCEND-V1 — UI/UX SPECIFICATION & WIREFRAME MAP

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md  
> **Scope:** ScreenGui Hierarchy, In-Combat HUD Layout, Out-of-Combat Fantasy Modals, Cross-Platform Responsive Rules, & Floating Combat Text.

---

## 1. UI Architecture & Dual Visual Philosophy

ASCEND-V1 enforces a strict visual separation between active combat gameplay and out-of-combat menu management:

* **In-Combat HUD:** Minimalist, unobtrusive, clean geometric progress bars (Health, Stamina, Energy). Zero screen-covering text or bloat. Over-the-head indicators for mob health and stun state.
* **Menu Modals:** Handcrafted fantasy artwork frames with heavy stone/parchment textures and gold trim highlights. Full-screen or centered modal overlays opened via explicit user keybinds or menu buttons.

---

## 2. Complete Roblox Studio Screen Hierarchy

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
      - Slot_M2 (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_Q (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_E (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_R (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
      - Slot_Dodge (Frame) -> Icon (ImageLabel) -> CooldownOverlay (Frame)
    - TopCenter_BossHUD (Frame, AnchorPoint: 0.5, 0, Position: {0.5, 0}, {0.03, 0})
      - BossHealthBar_BG -> Fill -> PhaseIndicatorText
    - Overhead_Container (Folder for BillboardGuis projected on mob heads)

### B. MenuModals (ScreenGui)
* ResetOnSpawn: false
* IgnoreGuiInset: true
* DisplayOrder: 20
* Hierarchy Layout:
  - BackgroundDim (Frame, Size: {1, 0}, {1, 0}, BackgroundColor3: #000000, Transparency: 0.5)
  - InventoryModal (Frame, AnchorPoint: 0.5, 0.5, Size: {0.7, 0}, {0.75, 0})
    - FantasyFrame_BG (ImageLabel - Handcrafted Art Asset)
    - ItemGridContainer (ScrollingFrame + UIGridLayout)
    - EquipmentSlots (Frame - Armor, Weapon, Accessory slots)
    - ItemTooltip (Frame - Dynamic stat hover panel)
  - CharacterStatsModal (Frame, AnchorPoint: 0.5, 0.5, Size: {0.6, 0}, {0.7, 0})
    - StatAllocationList (STR, DEX, INT, VIT, END rows with [+] buttons)

---

## 3. HUD Color Palette & Indicator Standards

To maximize legibility during intense action combat:

| Element | Background Color | Fill Color | Accent / Glow |
| :--- | :--- | :--- | :--- |
| Health Bar | #1E1E23 (Dark Charcoal) | #D73737 (Clean Crimson) | #FF6B6B |
| Stamina Bar | #1E1E23 (Dark Charcoal) | #2DB978 (Emerald Green) | #51E5A5 |
| Energy / Mana Bar | #1E1E23 (Dark Charcoal) | #2192FF (Celestial Blue) | #74B9FF |
| Cooldown Active | #000000 (80% Alpha) | N/A (Vertical Sweep) | #FFFFFF (Timer Text) |
| Boss Health Bar | #141418 (Deep Black) | #9C2C77 (Royal Violet) | #FFD700 (Gold Border) |

---

## 4. Cross-Platform Responsiveness & Mobile Rules

### Scale Units
All frame positions and sizes must strictly use relative Scale units ({X_Scale, 0}, {Y_Scale, 0}). Fixed pixel Offset is strictly forbidden except for thin 1px/2px borders.

### Touch Target Minimums
For mobile usability, all interactive buttons must maintain a minimum physical screen footprint equivalent to 44x44 dp.

### Mobile Action Layout
When UserInputService.TouchEnabled is true, the BottomCenter_Abilities container converts automatically into an arc-like thumb layout in the bottom-right quadrant:

* Top Layer: Skill R
* Upper Middle Layer: Skill E | Dodge
* Lower Middle Layer: Skill Q | Heavy M2
* Bottom Main Target: Light M1 (Largest Target)

---

## 5. Floating Combat Text (FCT) Specification

When a hit is registered on the server, a client event fires to spawn Floating Combat Text in world space:

* Normal Hit: White text (#FFFFFF), Size 18pt, floats upward 3 studs over 0.5 seconds and fades out.
* Critical Hit: Yellow text (#FFD700), Size 26pt bold, scale bounce animation (1.0x -> 1.3x -> 1.0x), floats upward 4 studs.
* Blocked Hit: Blue text (#74B9FF), Size 16pt, text displays "BLOCKED".
* Status Debuff: Purple/Red text (#9C2C77), displays debuff name (e.g., "STUNNED", "BLEED").