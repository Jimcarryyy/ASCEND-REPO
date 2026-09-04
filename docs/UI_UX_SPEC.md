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

### Official Dark Obsidian & Antique Gold Design Tokens (Updated 2026-08-20)

- **Deep UI Background:** `#111827` (Dark Navy Charcoal)
- **Secondary Surface:** `#1C2638` (Dark Blue-Gray)
- **Raised Surface:** `#273246` (Card/Slot Background)
- **Main Border:** `#8B6B32` (Antique Bronze-Gold, 1.5px to 2px stroke)
- **Highlight Border:** `#C49A4A` (Warm Celestial Gold)
- **Primary Text:** `#F1E8D2` (Warm Ivory, `Enum.Font.FredokaOne` / `GothamBold`)
- **Secondary Text:** `#A9A99F` (Muted Gray-Beige)
- **Jade Accent:** `#10B981` (HP / Vitality / Success)
- **Spirit Blue:** `#3B82F6` (Qi Energy / Info)
- **Vermilion:** `#E63946` (Danger / Close / Drop)
- **DisplayOrder Hierarchy:**
  - `DisplayOrder = 99`: Top-Level Toasts (`AscendToastGui`)
  - `DisplayOrder = 25`: Modals (`SpiritPouchGui`, `SectMarketGui`, `SpiritCauldronGui`)
  - `DisplayOrder = 18`: Arena In-Match HUD (`ArenaHUDGui`)
  - `DisplayOrder = 10`: Persistent Trackers (`QuestTrackerGui`)
  - `DisplayOrder = 5`: Main HUD & Top Menu (`VitalHUDGui`, `TopMenuGUI`, `SkillsGUI`)

  ## Additive UI/UX Specification (2026-08-27) — Studio Hierarchy Bindings & 3D Viewports

### 1. Studio-Authoritative UI Binding Paradigm
* Replaced programmatic `Instance.new` modal creation with direct bindings to Studio `StarterGui` instances (`SpiritPouchInventoryGui`, `SectPavilionGui`, `ArenaGUI`, `TopMenuGUI`).

### 2. Spirit Pouch 3D Viewport Engine (`InventoryController.luau`)
* **3D Sword & Herb Rendering:** Dynamically queries `ReplicatedStorage.Weapons` and `ReplicatedStorage.Herbs` to render a $35^\circ$ martial diagonal in grid slots and a live-spinning 3D mesh in the large inspection window.
* **Adaptive Grid Sizing:** Dynamically scales from 6 columns on desktop ($100\times 100\text{px}$) down to 4 columns on mobile ($56\times 56\text{px}$).

### 3. 5-Gate Loading Screen Engine (`LoadingScreen.client.luau`)
* Executes at $t=0$ in `ReplicatedFirst`, synchronizing (1) Engine load, (2) 3D Model/Audio preloading, (3) Character & Sword Rig Mount, (4) DataStore V2 Sync, and (5) Smooth multi-element fade-out.


# ASCEND — UI / UX Specification & Interface Architecture

> Studio Hierarchy Bindings, Responsive Viewport Adaptation & Design Tokens

---

## 1. Studio ScreenGui Hierarchy Mappings

| ScreenGui Name | Root Frame | Controller | Function & Bound Components |
| :--- | :--- | :--- | :--- |
| **`SkillsGUI`** | `BottomCenterFrame` | `SkillBarController` | Desktop action HUD: `IntentBarFrame`, `HPBarFrame`, `QIBarFrame`, `M1_SKILL`, `R_SKILL`, `B_SKILL`, `V_SKILL`, `C_SKILL`. |
| **`LowViewPortSkillsGUI`** | `BottomCenterFrame` | `SkillBarController` | Mobile/Tablet bottom-center HUD: `IntentBarFrame`, `HPBarFrame`, `QIBarFrame` (3 clean bars only). |
| **`MobileCombatHUD`** | `MobileCombatCluster` | `SkillBarController` | Dynamic mobile right-side 2×3 touch cluster (`M1`, `R`, `V`, `B`, `C` around native Jump). |
| **`CurrencyGUI`** | `CurrencyFrame` | `SkillBarController` | Top-right live currency counters: `CPFrame` (Contribution Points) & `SpiritStoneFrame` (Spirit Stones). |
| **`BottomMenuGui`** | `MenuFrame` | `SkillBarController` | Bottom-left modal toggles: `BagImageButton` (Pouch) & `ArenaImageButton` (1v1 Arena). |
| **`GlobalToastNotifGui`** | `ToastFrame` | `HUDController` | Top-center notification text with generation-ID anti-spam transitions. |
| **`SectMissionGui`** | `MissionFrame` | `QuestTrackerController` | Top-left 3-tier quest tracking cards (`Frame1`, `Frame2`, `Frame3`). |
| **`QIZoneNotifGui`** | `ZoneFrame` | `CultivationController` | Top-left Qi zone speed multiplier banner (e.g. `EMERALD MIST CAVERNS - 5.0X SPEED`). |
| **`SectMerchantMarketGui`** | `MainFrame` | `MarketController` | Sect Exchange Pavilion: auto-populating swords, exact CP (`1,970 CP`), buy/sell loot. |
| **`SpiritPouchInventoryGui`** | `MainFrame` | `InventoryController` | 60-slot spirit pouch with 2D high-res weapon icons, sorting, and item inspection. |

---

## 2. Responsive Viewport Switching Rules

```text
Viewport / Device Check (Camera.ViewportSize & UserInputService)
       │
       ├── Desktop (Keyboard / Viewport Width >= 950px):
       │   ├── SkillsGUI.Enabled = true (BottomCenterFrame.Visible = true)
       │   ├── LowViewPortSkillsGUI.Enabled = false (Visible = false)
       │   └── MobileCombatHUD.Enabled = false (Visible = false)
       │
       └── Mobile / Tablet (Touch / Viewport Width < 950px):
           ├── SkillsGUI.Enabled = false (BottomCenterFrame.Visible = false)
           ├── LowViewPortSkillsGUI.Enabled = true (BottomCenterFrame.Visible = true)
           ├── MobileCombatHUD.Enabled = true (MobileCombatCluster.Visible = true)
           └── Native Roblox JumpButton in TouchGui remains active & untouched