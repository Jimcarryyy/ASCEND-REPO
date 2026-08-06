# 🧹 CODEBASE CLEANUP & REFACTORING GUIDE (ASCEND V1)

## 📌 OVERVIEW
Following our strategic pivot to a **Pure Sword Cultivator (100% Flying Swords + Floating Back Armors)** paradigm, normalized RPG stat curves, and a Unified Open World, legacy weapon implementations and inflated configuration scales MUST be pruned and refactored to maintain a clean architecture.

---

## ❌ 1. FILES TO BE REMOVED (REDUNDANCY PRUNING)

The following 4 legacy weapon files conflict with the Pure Sword Cultivator paradigm and must be deleted from the repository:

1. `src/ServerScriptService/Server/Combat/Weapons/GauntletServer.luau`
2. `src/ServerScriptService/Server/Combat/Weapons/SpearServer.luau`
3. `src/ReplicatedStorage/Shared/Configs/Weapons/GauntletConfig.luau`
4. `src/ReplicatedStorage/Shared/Configs/Weapons/SpearConfig.luau`

---

## ⚠️ 2. REFACTORING INSTRUCTIONS BY SCRIPT

### 1️⃣ `CultivationConfig.luau`
* **Change**: Replace astronomical 50B Qi / 5M HP scale with the **Normalized RPG Scale**:
  * Qi Condensation: Max HP 100 – 300 | Max Qi 100 – 300
  * Foundation Establishment: Max HP 300 – 800 | Max Qi 300 – 800
  * Golden Core: Max HP 800 – 2,000 | Max Qi 800 – 2,000
  * Nascent Soul: Max HP 2,000 – 5,000 | Max Qi 2,000 – 5,000
  * Spirit Severing: Max HP 5,000 – 10,000 | Max Qi 5,000 – 10,000

### 2️⃣ `WeaponManager.luau`
* **Change**: Remove all `Spear` and `Gauntlet` logic. Expand weapon binding to handle:
  1. Hand Weapon attachment (`RightGripAttachment`) for Flying Swords.
  2. Floating Back Armor attachment (`BodyBackAttachment`) for 3D Back-Crest Arrays.
  3. Stat application for Equipped Back Armors (+HP, +DEF %, +Qi Regen/sec).

### 3️⃣ `CombatStateManager.luau`
* **Change**: Remove requires for `SpearServer` and `GauntletServer`. Route all attack skill triggers exclusively through `FlyingSwordServer.ExecuteAttack()`.

### 4️⃣ `ItemConfig.luau`
* **Change**: Remove `GauntletItem` and `SpearItem`. Register all 13 Flying Swords & 13 Floating Back Armors (Mythic to Common), herbs, beast cores, and potions.

### 5️⃣ `UIAssets.luau` & Client HUD Controllers
* **Change**: Replace Dark Obsidian palette (`#0C0E14`) with **Light-Mode Flat 2D Palette**:
  * Main Panel: `#F8FAF9` / `#FFFFFF`
  * Card Background: `#F1F5F9`
  * 1px Border Stroke: `#CBD5E1`
  * Text Color: `#0F172A` Deep Charcoal
  * Meters: `#10B981` Emerald Jade & `#3B82F6` Sapphire Blue

### 6️⃣ `QiZoneManager.luau`
* **Change**: Update environmental Qi multipliers from $150\times$ down to normalized **$1.0\times \rightarrow 3.0\times$** multiplier scaling across the single continent map.