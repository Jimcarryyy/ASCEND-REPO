# ASCEND — Current Active Task

## 🎯 Active Objective
**Task 2.2: Roblox Studio UI Construction & Client Layout Setup**

---

## 📋 Task Checklist

### Phase 2: UI/UX & Asset Pipeline
- [x] **Task 2.1: 2D Game Image Generation & Asset Audit**
  - [x] Complete Phase 1 Game Specifications in `docs/`
  - [x] Create `docs/ASSET_MANIFEST.md` and `docs/AI_PROMPT_GUIDE.md`
  - [x] Audit HUD assets (Category A) — Minimalist dark slate containers, empty shells, key badges, boss bar, reticle.
  - [x] Audit Modal Panels (Category B) — Dark obsidian modal background, banner, divider line, grid slot, primary button.
  - [x] Audit Weapons & Gear Icons (Category C) — Flying sword, spear, gauntlet, robes, pendant, ring (Flat 2D cell-shaded vector).
  - [x] Audit Martial Technique Skill Icons (Category D) — M1, M2, Dodge, Parry, Tempest, Dragon, Palms, Lightning (Flat 2D vector emblems).
  - [x] Refine Currencies & Pills (Category E) — Standalone spirit stones, alchemy pills, spirit herbs, demon cores (No plates/dishes).
  - [x] Audit Status Effect Indicators (Category F) — Qi deviation, poison, tribulation burn, golden body.
  - [x] Refine Rarity System (Category G) — Integrated native Roblox `UIStroke` color system (`#FFFFFF`, `#38E54D`, `#2192FF`, `#9C2C77`, `#FFD700`, `#FF1E1E`).

- [ ] **Task 2.2: Roblox Studio UI Construction & Layout**
  - [ ] Create central asset registry script `ReplicatedStorage/Shared/Configs/UIAssets.luau`
  - [ ] Create rarity color configuration `ReplicatedStorage/Shared/Configs/RarityConfig.luau`
  - [ ] Build Minimalist HUD Layout in `StarterGui/HUDGui`
  - [ ] Build Inventory & Stats Modal Window in `StarterGui/InventoryGui`
  - [ ] Set up client-side UI controller scripts for dynamic skill slot & inventory slot updates

---

## 📌 Notes & Technical Guidance
* **Empty Shell Rule:** All UI frames, containers, and slots in Studio are pure blank shells. All text, numbers, progress bars, and icon overlays are managed dynamically via Luau client scripts.
* **Rarity Styling:** Use native Roblox `UIStroke` on `panel_grid_slot` for 100% crisp vector rarity borders across all screen resolutions without image memory overhead.