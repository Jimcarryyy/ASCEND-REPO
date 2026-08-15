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

## 4. Main Vital HUD & Unit Formatting (`HUDController.luau`)

### A. Simple Clean Qi Display
* Main HUD Qi bar text strictly renders:
  $$\mathbf{CurrentQi \:/\: CultivatedQi} \quad (\text{e.g., } \mathbf{43.3k \:/\: 75.0k})$$
* **Rule:** The `MaxQiGoal` text is **COMPLETELY REMOVED** from the main HUD. No `[Goal: ...]` wording is displayed on the combat HUD bar.

### B. Universal Short Unit Formatting (`CultivationConfig.FormatNumber`)
All numerical HP and Qi text across HUDs, Overheads, and Damage Numbers format using short unit suffixes:
* $< 1,000$: Integer (e.g. `200`)
* $\ge 1,000$: Thousands (e.g. `1.0k`, `84.0k`)
* $\ge 1,000,000$: Millions (e.g. `1.50M`, `95.0M`)
* $\ge 1,000,000,000$: Billions (e.g. `1.20B`)

### C. Dynamic Level Diamond
* Level diamond calculates total Cultivation Level (1 to 90) across the 10 Realms:
  $$\text{Level} = ((\text{RealmTier} - 1) \times 9) + \text{Order}$$
* **Fix:** `HUDController` checks `payload.Tier ~= nil` before updating the level diamond, preventing level snapping to 1 during resource harvesting or inventory sync events.

---

## 5. 3D Overhead Badges (`OverheadUIController.luau`)

* **2-Line Format:** Player Name, HP Bar, and Qi Bar are removed from the 3D overhead to eliminate redundancy with the Vital HUD.
  * **Line 1 (Gold Accent `#FFD700`):** `REALM NAME and RANK` (e.g., `Golden Core — Order 1`)
  * **Line 2 (Jade Green Accent `#50DC78`):** `ALCHEMY NAME and RANK` (e.g., `Mortal Alchemist — Rank 1`)
* **Typography & Outline:** Rendered in **`Enum.Font.LuckiestGuy`** with **thick black letter outlines** (`TextStrokeColor3 = Color3.fromRGB(0,0,0)`, `TextStrokeTransparency = 0`).
* **Fixed Pixel Sizing:** Uses fixed BillboardGui pixel dimensions (`UDim2.new(0, 260, 0, 52)`) with `TextSize = 18` / `15`, preventing text from collapsing to 0 height in Studio.

---

## 6. Custom Xianxia Loading Screen (`src/ReplicatedFirst/LoadingScreen.client.luau`)

* **ReplicatedFirst:** Executes before game assets load, calling `ReplicatedFirst:RemoveDefaultLoadingScreen()`.
* **Fullscreen Background:** Custom Xianxia artwork (`BACKGROUND_IMAGE_ID`) with dark overlay (`#000000`, 0.45 transparency).
* **Dynamic Preloading:** Scans `ReplicatedStorage` and `SoundService` for renderable instances (`MeshPart`, `Sound`, `Decal`, `ImageLabel`) and tracks `ContentProvider:PreloadAsync()`.
* **Server Sync Gate:** Holds progress bar at 95% until server fires `UpdateCultivation`, confirming player profile DataStore load.
* **Skip Button:** `"SKIP [SPACE / CLICK]"` button appears after 1.5 seconds.