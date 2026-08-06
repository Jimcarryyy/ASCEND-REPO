# ASCEND-V1 — UI/UX SPECIFICATION & WIREFRAME MAP

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Dark Obsidian Palette, Sharp 90° Corners, `FredokaOne` Typography, Bottom HUD Panel, & Spirit Pouch.

---

## 1. Dark Obsidian Design System ("Same Skin, Different Body")

All HUD components and out-of-combat modals enforce the exact same design language:

* **Main Background**: `#0C0E14` (`Color3.fromRGB(12, 14, 20)`)
* **Sub-Panels / Cards**: `#121520` (`Color3.fromRGB(18, 21, 32)`)
* **Border Stroke**: `#1E2330` (`Color3.fromRGB(30, 35, 48)`), `Thickness = 1.5`
* **Typography**: `Enum.Font.FredokaOne` across all headers, meters, and item cards.
* **Corners**: **100% Sharp 90° Corners** (0px border-radius, no `UICorner`).
* **Text Colors**: `#F1F5F9` (Crisp Pure White for titles & numbers), `#94A3B8` (Muted Grey), `#EAB308` (Gold Prompts), `#38BDF8` (Cyan Qi), `#22C55E` (Green HP).

---

## 2. Bottom-Center HUD Panel (`HUDController.luau`)

Single enclosed dark obsidian window (`500x185` px) positioned at `UDim2.new(0.5, -250, 1, -200)`:

1. **HP Bar Box (Height: 28px)**: Dark `#121520` container with `#22C55E` green fill + bold white text (`50.0K / 50.0K HP`).
2. **Qi Bar Box (Height: 28px)**: Dark `#121520` container with `#38BDF8` cyan fill + **pure white text ALWAYS** (`Golden Core — Order 1` on left, `19.01M / 19.01M (100.0%)` on right).
3. **Action Prompt Line (Height: 22px)**: Clean text line (`[G] HOLD TO MEDITATE` / `PRESS 'B' FOR MINOR BREAKTHROUGH`), **100% free of icon emojis (`✨`, `⚡`, `🧘`)**.
4. **Skill Hotbar Slots (58x58px Sharp Square Cards)**:
   * 6 slots: `LMB`, `F`, `Q`, `E`, `R`, `Shift`.
   * Skill artwork image centered inside.
   * Keybind badge at bottom-right corner (`24x14` px, `#0C0E14` background).
   * Cooldown mask overlay + centered decimal timer text (`2.5s`).