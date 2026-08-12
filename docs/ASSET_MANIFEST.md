# ASCEND-V1 — CULTIVATION 2D/3D ASSET MANIFEST & DESIGN PHILOSOPHY

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** 3D Sword Models, 3D Back-Crests, 2D Skill Icons, UI Textures, & Audio SFX.

---

## 1. 3D Master Equipment Manifest (16 Sets / 32 Total Items)

All 16 Equipment Sets are registered in `ItemConfig.luau` and powered by 5 Master Base Models in `ReplicatedStorage`:

| Set Name | Rarity Tier | 3D Sword Model Name | 3D Back Armor Model Name |
| :--- | :--- | :--- | :--- |
| **Mortal Iron** | Common | `Mortal Iron Sword` | `Mortal Iron Crest Array` |
| **Refined Spirit-Steel** | Uncommon | `Refined Spirit-Steel Sword` | `Refined Spirit-Steel Crest Array` |
| **Azure Spirit-Jade** | Rare | `Azure Spirit-Jade Sword` | `Azure Spirit-Jade Crest Array` |
| **Crimson Flame Spirit** | Rare | `Crimson Flame Spirit Sword` | `Crimson Flame Spirit Crest Array` |
| **Glacial Frost Spirit** | Rare | `Glacial Frost Spirit Sword` | `Glacial Frost Spirit Crest Array` |
| **Golden Thunder Spirit** | Rare | `Golden Thunder Spirit Sword` | `Golden Thunder Spirit Crest Array` |
| **Shadow Slate Spirit** | Rare | `Shadow Slate Spirit Sword` | `Shadow Slate Spirit Crest Array` |
| **Sakura Blossom** | Epic | `Sakura Blossom Blade` | `Sakura Blossom Crest Array` |
| **Radiant Light** | Epic | `Radiant Light Blade` | `Radiant Light Crest Array` |
| **Shadow Void** | Epic | `Shadow Void Blade` | `Shadow Void Crest Array` |
| **Sovereign Gold Dragon** | Legendary | `Sovereign Gold Dragon Sword` | `Sovereign Gold Dragon Crest Array` |
| **Celestial Thunder** | Legendary | `Celestial Thunder Sovereign Sword` | `Celestial Thunder Sovereign Crest Array` |
| **Heavenly Void** | Mythic | `Heavenly Void Sword` | `Heavenly Void Crest Array` |
| **Sun-Slayer Crimson** | Mythic | `Sun-Slayer Crimson Sword` | `Sun-Slayer Crimson Crest Array` |
| **Nine-Dragon Sovereign** | Mythic | `Nine-Dragon Sovereign Sword` | `Nine-Dragon Sovereign Crest Array` |
| **Frost-Dragon Flared** | Mythic | `Frost-Dragon Flared Sword` | `Frost-Dragon Flared Crest Array` |


---\n
## 2. 2D Master Icon Asset Manifest (12 Transparent PNG Assets)

All 12 2D icons are uploaded to Roblox Studio and registered in `UIAssets.luau` and `ItemConfig.luau`:

| Asset Name | Config Item ID | Roblox Asset ID | UI Usage / Category |
| :--- | :--- | :--- | :--- |
| **FlameIcon** | `FlameIcon` | `rbxassetid://98860036623590` | Qi Flame Control Gauge Header |
| **GaleWindLotus** | `GaleWindLotus_1Yr`, `100Yr` | `rbxassetid://97399822723211` | Ingredient Herb Icon |
| **GaleWindDan** | `GaleWindDan` | `rbxassetid://108842260002164` | Consumable Speed Pill Icon |
| **QiGatheringDan** | `QiGatheringDan` | `rbxassetid://136942657595135` | Consumable Qi Pill Icon |
| **PhysiqueTemperingDan** | `PhysiqueTemperingDan` | `rbxassetid://127548831742229` | Consumable Strength Pill Icon |
| **DemonBeastCore** | `DemonBeastCore` | `rbxassetid://127840279619766` | Ingredient Monster Core Icon |
| **CelestialDew** | `CelestialDew` | `rbxassetid://131403489720983` | Ingredient Water Dew Icon |
| **FoundationGatheringDan** | `FoundationGatheringDan` | `rbxassetid://135779673578731` | Consumable Breakthrough Pill Icon |
| **SpiritAsh** | `SpiritAsh` / `Slag` | `rbxassetid://128820714120893` | Failed Refinement Ash Icon |
| **DragonBloodVine** | `DragonBloodVine_1Yr`, `100Yr` | `rbxassetid://87215598829275` | Ingredient Crimson Vine Icon |
| **SpiritGrass** | `SpiritGrass_1Yr`, `10Yr`, `100Yr`, `1000Yr` | `rbxassetid://112390155425328` | Ingredient Spirit Grass Icon |
| **SpiritHealingDan** | `SpiritHealingDan` | `rbxassetid://72471225624084` | Consumable Health Pill Icon |

---

## 3. HUD Template & Monetized HUD Skin Manifest

| Skin ID | Skin Name | Roblox Asset ID | Price (Robux) | Rarity |
| :--- | :--- | :--- | :--- | :--- |
| **`DefaultBronze`** | Immortal Bronze HUD | `rbxassetid://107254331482831` | 0 (Default) | Common |
| **`SakuraImmortal`** | Sakura Immortal HUD | `rbxassetid://107254331482831` | 250 Robux | Legendary |
| **`AzureDragon`** | Azure Cloud Realm HUD | `rbxassetid://107254331482831` | 500 Robux | Mythic |
| **`SkillBoxHUD`** | Skill Box Background | `rbxassetid://97080305696865` | N/A (HUD Slot) | Common |