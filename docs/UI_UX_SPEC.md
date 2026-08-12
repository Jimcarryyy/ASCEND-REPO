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


---\n
## 3. Custom Xianxia Vital HUD & Monetized Skin Specification

* **Template Asset**: `rbxassetid://107254331482831` (`VitalHUDFrame`).
* **Portrait Ring**: Houses a 3D Avatar Headshot thumbnail (`rbxthumb://type=AvatarHeadShot&id=...`).
* **Diamond Level Badge**: Houses player level/breakthrough tier (`100`) rendered in `FredokaOne` bold RichText (`<b>100</b>`).
* **Display Name**: Rendered in `FredokaOne` bold RichText (`<b>HAN_JUEEE</b>`, `#38BDF8` Cyan).
* **HP Bar**: `#10B981` Emerald Green fill with `LuckiestGuy` font text (`389 / 800`) padded $14\text{px}$ left and $18\text{px}$ right.
* **QI Bar**: `#3B82F6` Azure Blue fill with `LuckiestGuy` font text (`800 / 800`) padded $14\text{px}$ left and $18\text{px}$ right.
* **Monetized HUD Skin Engine (`HUDSkinConfig.luau`)**: Supports equipping custom HUD skins (`DefaultBronze`, `SakuraImmortal`, `AzureDragon`). Equipping a skin updates `VitalHUDFrame.Image` AND auto-snaps slot offset positions (`HPSlotPosition`, `QISlotPosition`, `PortraitPosition`).
* **Action Skill Bar (`ActionSkillBar`)**: Binds `Slot_E`, `Slot_F`, `Slot_M1`, `Slot_Q`, `Slot_R`, `Slot_Shift` to background `rbxassetid://97080305696865`, attaching keybind badges and dark radial/vertical swipe cooldown overlays with countdown timers (`HUDController.TriggerSkillCooldown`).

---

## 4. Azure Cloud Realm Jade & Cloud Panel Design Identity (Approved)

* **Main Modal Fill**: Soft Pale Jade Celadon (`#E2F1ED`).
* **Watermark Art**: Subtle hand-painted Azure Cloud swirl watermarks (`#38BDF8`).
* **Borders**: Contoured, non-straight Xianxia cloud scroll contours with gold & azure jade accents.
* **Close Button Extension**: Top-right ornamental tab extending outside the main frame boundary designed as a custom circular close-button plaque slot.