# ASCEND-V1 — CODEBASE PRUNING & CLEANUP GUIDE

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Codebase Pruning, Dead Code Removal, Legacy File Purging, & Architecture Normalization.

---

# 1. Overview & Pruning Strategy

To maintain a zero-bug, high-performance, mobile-friendly codebase, **ASCEND** enforces strict codebase pruning rules. Unused scripts, legacy weapon logic, astronomical stat scaling, and dark-mode UI constants must be systematically purged.

---

# 2. Complete Codebase Pruning Audit

### 🗑️ 2.1 Deleted Legacy Files
The following 4 non-sword legacy files were permanently deleted from the repository during Subtask 6.2C:
* `src/ServerScriptService/Server/Combat/Weapons/GauntletServer.luau`
* `src/ServerScriptService/Server/Combat/Weapons/SpearServer.luau`
* `src/ReplicatedStorage/Shared/Configs/Weapons/GauntletConfig.luau`
* `src/ReplicatedStorage/Shared/Configs/Weapons/SpearConfig.luau`

---

### 🧹 2.2 Purged Legacy Logic & Code Branches

1. **`CombatStateManager.luau`**:
   * **Removed:** `require(SpearServer)` and `require(GauntletServer)`.
   * **Removed:** Conditional `if equippedWeapon == "Spear"` and `elseif equippedWeapon == "Gauntlet"` branches.
   * **Added:** 100% of attack requests are routed directly to `FlyingSwordServer.ExecuteAttack()`.

2. **`WeaponManager.luau`**:
   * **Removed:** Left-hand gauntlet model cloning, dual-glove welds (`Equipped3DGauntlet_Left`), and procedural spear scaling.
   * **Removed:** Complex per-item particle generation code (replaced by direct model cloning & `EnableModelEffects()`).
   * **Added:** Studio-Authoritative `RightGripAttachment` and `BodyBackAttachment` direct Motor6D binding with bounds scale normalization ($4.5$-stud sword bounds).

3. **`CultivationConfig.luau`**:
   * **Removed:** Legacy $50\text{ Billion Qi}$ and $5\text{ Million HP}$ astronomical stat tables.
   * **Added:** Normalized $100 \rightarrow 10,000$ HP / Qi progression curve across 5 Major Realms and 45 Orders.

4. **`ItemConfig.luau`**:
   * **Removed:** Legacy `GauntletItem` and `SpearItem` item table definitions.
   * **Standardized:** All 16 floating back armors renamed to end strictly with **`Crest Array`**.
   * **Added:** Registered all 16 Cultivation Equipment Sets (32 Items) with `Archetype` and `PrimaryColor` attributes.

5. **`UIAssets.luau` & HUD Controllers**:
   * **Removed:** Obsolete `#0C0E14` dark mode obsidian UI constants.
   * **Added:** Traditional Xianxia Palette (`#1D4533` Jade, `#F7EAE0` Cream, `#F9D2BA` Peach, `#5E3122` Mahogany) with rarity-tinted slot backgrounds and non-overlapping title headers.

6. **`InventoryManager.luau` & `InventoryController.luau`**:
   * **Removed:** 30-slot storage cap cutting off equipment items.
   * **Added:** Expanded 60-slot Spirit Pouch inventory grid with client `RequestSync` and server `EnsureTestItems` testing hooks.

---

# 3. Ongoing Codebase Clean-Up Rules

To prevent code clutter in future updates:

1. **Zero Dead Require Statements:** Never leave a `require()` statement referencing a file or folder that does not exist in `src/`.
2. **Zero Unused If-Else Weapon Branches:** Never branch on non-sword weapon types (`Spear`, `Gauntlet`, `Hammer`). All weapons in ASCEND are Flying Swords (`FlyingSword`).
3. **Data-Driven Configuration First:** Never hardcode item stats, colors, or offsets inside manager scripts. Store all item attributes inside `ItemConfig.luau`.
4. **Single Universal Animation Pack:** Do not create separate animation tracks for individual swords. All swords share 1 universal R15 animation set (`M1`, `Shift` Windstep, `G` Meditation, `B` Breakthrough).