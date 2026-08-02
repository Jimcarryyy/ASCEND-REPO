# ASCEND — Next Steps

## 🚀 Immediate Next Steps (Task 2.2)

1. **Set Up Central Registry Configurations in Roblox Studio**:
   - Create `ReplicatedStorage/Shared/Configs/UIAssets.luau` to map all `rbxassetid://` references.
   - Create `ReplicatedStorage/Shared/Configs/RarityConfig.luau` mapping Mortal to Immortal grade hex colors.

2. **Construct `StarterGui/HUDGui`**:
   - Layout action skill bar (Slots M1, M2, Q, E, R, Shift) using `hud_slot_base.png`, `hud_slot_active.png`, and `hud_key_badge.png`.
   - Layout top boss health bar (`hud_boss_frame.png`) with dynamic inner fill frame.
   - Set up aim focus reticle (`hud_reticle_dot.png`).

3. **Construct `StarterGui/InventoryGui`**:
   - Build main modal panel (`panel_modal_bg.png`) with header banner (`panel_header_banner.png`) and section dividers (`panel_divider_line.png`).
   - Create item grid container using `panel_grid_slot.png` with dynamic `UIStroke` rarity borders.
   - Add primary action button (`panel_button_primary.png`).

4. **Implement Client UI Scripts**:
   - Create client-side UI controller to handle slot keybind labels, active skill highlights, cooldown masks, and inventory item rendering.