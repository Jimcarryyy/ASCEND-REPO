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

## 4. Custom R6 Movement Animation Suite (`AnimationConfig.luau`)

| State | Asset ID | Rig Type | Priority | Description |
|---|---|---|---|---|
| **Idle** | `rbxassetid://98257310687211` | R6 | `Idle` | Standing R6 cultivator breathing posture. |
| **Walk V1** | `rbxassetid://92949542384678` | R6 | `Action2` | Normal walking stride (`WalkSpeed = 16`). |
| **Walk V2** | `rbxassetid://114762664703275` | R6 | `Action2` | Alternate walking stride option. |
| **Run V1** | `rbxassetid://106115576089829` | R6 | `Action3` | LeftShift sprint stride (`WalkSpeed = 28`). |
| **Run V2** | `rbxassetid://137367224407424` | R6 | `Action3` | Alternate sprint stride option. |
| **Jump** | `rbxassetid://115002701112708` | R6 | `Action4` | Airborne jump takeoff pose. |
| **Fall** | `rbxassetid://105371732122929` | R6 | `Action4` | High-cliff freefall pose (triggered only on drops >0.35s). |
| **Land** | `rbxassetid://127232864368618` | R6 | `Action4` | Terrain impact landing recovery pose. |
| **Climb** | `rbxassetid://92318229141460` | R6 | `Action2` | Ladder / wall climbing pose. |
| **Swim** | `rbxassetid://232873130` | R6 | `Action2` | Native R6 water swimming posture. |
| **Crouch Idle** | `rbxassetid://121105579761179` | R6 | `Action2` | Low crouching idle pose. |
| **Crouch Walk** | `rbxassetid://139963626951619` | R6 | `Action2` | Low crouching walk stride. |
| **Meditation** | `rbxassetid://124985492575278` | R6/R15 | `Action4` | Grounded cross-legged cultivation sitting posture. |

---

## 5. Movement Audio Registry (`SoundService["Movement sounds"].Main.Character`)

* **Walk Audio:** `rbxassetid://4416041299` (5.851s looped audio, `PlaybackSpeed` synced 1:1 to `WalkSpeed / 16.0`).
* **Run Audio:** `rbxassetid://79250663775359` (4.284s looped audio, `PlaybackSpeed` synced 1:1 to `WalkSpeed / 28.0`).
* **Meditation Audio:** `rbxassetid://103967342049425` / `SoundService.MeditationSound` (Looped = `true`, Volume = `0.5`).
* **Jumping Audio:** `SoundService["Movement sounds"].Main.Character.Jumping`.
* **Landing Audio:** `SoundService["Movement sounds"].Main.Character.Landing`.
* **Default Footstep Muting:** `HumanoidRootPart.Running.Volume = 0` to prevent double audio playback.


### Updated Asset Manifest Entries

| Asset Name | Asset ID / Type | Classification | Notes / Settings |
| :--- | :--- | :--- | :--- |
| **R6 Meditation Form** | `rbxassetid://129333803961409` | Animation (R6) | Grounded cross-legged cultivation sitting posture. |
| **Sword Attack 1** | `rbxassetid://129254042886405` | Animation (R6) | Heavy horizontal opening slash (`0.44s`, `0.85x`). |
| **Sword Attack 2** | `rbxassetid://78342794513338` | Animation (R6) | Deep diagonal downward cut (`0.40s`, `0.85x`). |
| **Sword Attack 3** | `rbxassetid://133701354257850` | Animation (R6) | Wide sweeping cross-cleave (`0.44s`, `0.85x`). |
| **Sword Attack 4** | `rbxassetid://140582503077234` | Animation (R6) | Heavy forward body-thrust (`0.46s`, `0.80x`). |
| **Sword Attack 5** | `rbxassetid://111677132360566` | Animation (R6) | Overhead finisher slam (`0.54s`, `0.75x`). |
| **Qi Dash 1** | `rbxassetid://118004062849712` | Animation (R6) | Flash-step burst dash stage 1. |
| **Qi Dash 2** | `rbxassetid://87494050060721` | Animation (R6) | Flash-step burst dash stage 2. |
| **Sword Slash SFX** | `rbxassetid://79218449800283` | Sound (Audio) | Crisp, authentic heavy blade cutting whoosh. |
| **Qi Dash SFX** | `rbxassetid://93272068959626` | Sound (Audio) | Ethereal spirit burst dash sound. |


## Additive Asset Manifest (2026-08-27) — Audio & 2D Flat UI Tokens

### 1. Universal Audio Registry (`UIAssets.Audio`)
| Asset Name | Asset ID | Volume | Usage / Trigger |
| :--- | :--- | :--- | :--- |
| **Exploration BGM** | `rbxassetid://137280276426447` | `0.35` | Boot-up looping background music in `ReplicatedFirst`. |
| **Menu Select SFX** | `rbxassetid://101735926591481` | `0.65` | TopMenu navigation clicks (`BAG`, `MEDITATE`, `ARENA`, `SETTINGS`). |
| **Panel Click SFX** | `rbxassetid://138567614125924` | `0.55` | Internal panel tabs, slot selection, sorting, and action buttons. |
| **Sword Equip (Draw)** | `rbxassetid://114060318185092` | `0.75` | 3D audio when drawing sword to hand or equipping from bag. |
| **Sword Unequip (Sheath)** | `rbxassetid://97568182472477` | `0.75` | 3D audio when sheathing sword to back via `R` key. |
| **Parry Metal Clash** | `rbxassetid://9114223175` | `1.00` | 3D audio on Perfect Parry deflection or sword clashing. |
| **Hit Impact Sound** | `rbxassetid://140462043853173` | `0.95` | Positional impact audio on confirmed sword hit. |

### 2. 2D Rarity Color Palette (`UIAssets.RarityCardColors`)
* **Mortal / Common:** `#64748B` (Text: `#FFFFFF`)
* **Spiritual / Uncommon:** `#10B981` (Text: `#FFFFFF`)
* **Earth / Rare:** `#3B82F6` (Text: `#FFFFFF`)
* **Heaven / Epic:** `#A855F7` (Text: `#FFFFFF`)
* **Legendary:** `#F59E0B` (Text: `#FFFFFF`)
* **Mythic:** `#E11D48` (Text: `#FFFFFF`)
* **Sovereign:** `#22D3EE` (Text: `#FFFFFF`)
* **Celestial:** `#F8FAFC` (Text: `#1E232A` Charcoal Contrast)
