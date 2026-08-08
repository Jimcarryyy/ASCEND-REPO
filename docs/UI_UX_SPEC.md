# ASCEND-V1 — UI/UX SPECIFICATION & WIREFRAME MAP

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Traditional Xianxia Palette, Sharp 90° Corners, `FredokaOne` Typography, HUD & Spirit Pouch.

---

## 1. Traditional Xianxia Palette System

All HUD components, Spirit Pouch modals, and Alchemy Cauldrons enforce the traditional Xianxia color system:

* **Main Panel**: `#F7EAE0` (`Color3.fromRGB(247, 234, 224)` Warm Cream White)
* **Sub-Panels / Cards**: `#F9D2BA` (`Color3.fromRGB(249, 210, 186)` Soft Peach Accent)
* **Border Stroke**: `#1D4533` (`Color3.fromRGB(29, 69, 51)` Deep Jade Green, `Thickness = 1.5`)
* **Primary Text & Headers**: `#1D4533` (`Color3.fromRGB(29, 69, 51)` Deep Jade Green)
* **Subtext & Buttons**: `#5E3122` (`Color3.fromRGB(94, 49, 34)` Rich Mahogany Wood)
* **Corners**: **100% Sharp 90° Corners** (0px border-radius).

---

## 2. Rarity-Tinted Item Slot Backgrounds

Item grid slots in the Spirit Pouch (`InventoryController.luau`) enforce soft tinted background colors by rarity:

* **Mythic / Immortal**: `#FEE2E2` (Soft Crimson Tint)
* **Legendary**: `#FEF3C7` (Soft Amber Gold Tint)
* **Epic**: `#F3E8FF` (Soft Purple Tint)
* **Rare**: `#E0F2FE` (Soft Sapphire Blue Tint)
* **Uncommon**: `#DCFCE7` (Soft Emerald Green Tint)
* **Common**: `#F1F5F9` (Soft Slate Gray Tint)