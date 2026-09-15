# ASCEND — Technical Documentation & Architecture Index

> **Authoritative Technical Index**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. Project Overview

**ASCEND** is a high-performance Roblox Xianxia (Eastern Immortal Hero) Action RPG built on the standardized Roblox R6 avatar rig. The game features fast-paced martial sword combat, an exponential 10-realm internal cultivation system, daily sect life, deep crafting professions (Alchemy, Blacksmithing, Tea Brewing, Gathering), and strict server-authoritative state synchronization.

### Technical Baseline
- **Avatar Rig:** Standard Roblox R6 (Rigid joint hierarchy, snappier martial arts keyframing, deterministic physics, zero ragdoll jitter, 60 FPS mobile budget).
- **Persistence Engine:** `ASCEND_PlayerData_V3` (Server-authoritative DataStore with automatic V2-to-V3 schema migration, 300s auto-saves, shutdown flushes via `BindToClose`, and strict starter weapon isolation).
- **Network Architecture:** 22 centralized `RemoteEvent` instances initialized in `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`.
- **UI Architecture (ADR-041):** Studio-Authoritative `StarterGui` instances. Client controllers strictly wire events, tween properties, and bind logic. Programmatic UI construction via `Instance.new` is strictly forbidden for static layouts.
- **Typography Standard (ADR-042):**
  - **Headers, Titles, World Billboards, Station Overhead:** `Enum.Font.Bangers` with a mandatory solid black `UIStroke` (`Thickness = 1.5 - 2.0`, `Color = Color3.fromRGB(0, 0, 0)`).
  - **Body Text, Lore, Descriptions, Dialogue:** `Enum.Font.Fundamento`.
- **Modal Window Management (ADR-043):** Centralized modal stack handled by `ModalWindowManager.luau` to prevent UI overlaps and manage camera locks.

---

## 2. Canonical Master Keybind Map

This table reflects the actual, live keybindings wired in `InputController.luau`, `WeaponManager.luau`, and `FlyingSwordServer.luau`:

| Keybind | Action | Description & Mechanical Rules |
| :---: | :--- | :--- |
| **`M1`** | **5-Hit Broadsword Combo** | Heavy sword chain (`Hit 1` to `Hit 5`). Movement dampened to `WalkSpeed = 8` during swings. Landed hits generate **+25% Sword Intent**. At **100% Intent**, the next strike consumes the bar to deal **1.75× Empowered Damage** with golden critical VFX. Pausing $>1.3\text{s}$ resets the chain. |
| **`Left Control`** | **Sprint Toggle** | Toggles movement between Walk and Sprint (Open World: 18 / 44 studs/s; Arena: 16 / 34 studs/s). Features harmonic head-bobbing and dynamic FOV expansion ($70^\circ \rightarrow 76^\circ$). |
| **`Left Shift`** | **Qi Flash-Step Dash** | Explosive 150 studs/s burst over 0.16s (~20 studs distance). Lifts character +1.2 studs with temporary `Freefall` state and anti-trip `AlignOrientation`. 3.0s cooldown, costs 3% Qi. Automatically resumes sprint if movement keys are held. |
| **`T`** | **Block / Perfect Parry** | **Hold:** Frontal 180° guard arc reducing damage by 80% and knockback by 70%, consuming Posture. <br>**Tap within 0.22s:** Perfect Parry negating 100% damage, inflicting 0.5s stagger on the attacker, restoring +5% Qi, and detonating golden deflection sparks. |
| **`C`** | **Qi Meditation** | Toggles seated cultivation. Restores Qi at 10.0%/s (full pool in 10s). Completely locks combat actions while active. |
| **`R`** | **Draw / Sheathe Weapon** | Toggles Flying Sword between combat hand grip (`RightGripAttachment`) and resting back sheath (`BackSwordMount`). |
| **`V`** | **Flying Sword Flight Mode** | Mounts flying sword under feet for 3D aerial navigation (75 studs/s). Features ground cushion ($6.5\text{ studs}$ altitude maintenance) and obstacle buffer ($8.5\text{ studs}$). Ascend with `Spacebar`, descend with `C` or `LeftControl`. |
| **`B`** | **Realm Breakthrough** | Attempts realm breakthrough when Cultivated Qi reaches 100% capacity. Triggers heavenly lightning tribulation strikes for major realms. |
| **`Q`** | **Skill: Sword Tempest** | Dual-hitbox skill: point-blank 360° melee cleave (25 damage) + 3 forward-traveling purple sawblades (54 damage across waves). Costs 15% Qi, 3.5s cooldown. |
| **`E`** | **Skill: Piercing Void Thrust** | High-velocity penetrating sword thrust beam (80 base damage, 40-stud knockback). Costs 12% Qi, 5.0s cooldown. |
| **`F`** | **Ultimate: 100-Slash Flash Domain** | Single-click ultimate. Lifts cultivator +2.2 studs into Freefall, dashes forward at 145 studs/s phasing through targets, mid-air slashes, and detonates a 36-stud 100-slash sphere (5 hits × 20 damage). Costs 20% Qi, 5.5s cooldown. |
| **`P`** | **Character Stats Sheet** | Toggles the dedicated `CharacterStatsGui` overview showing Realm, Order, Attributes, and Stats. |
| **`Tab`** | **Notice Board / Quests** | Opens sect daily duty tracking and active bounties. |

---

## 3. Weapon Arsenal & Dynamic VFX Palettes

All weapons in ASCEND are Flying Swords governed by `ItemConfig.luau` and dynamically attune visual effects via `ItemConfig.GetWeaponPalette(weaponId)`:

| Tier | Weapon ID | Name | Rarity | Base Dmg | VFX Palette Theme | Primary Hex |
| :---: | :--- | :--- | :---: | :---: | :--- | :---: |
| **1** | `MortalIronJian` | Mortal Iron Jian | Common | 15 | Cold Silver-White | `#DCE1EB` |
| **2** | `AzureCloudDiscipleJian` | Azure Cloud Disciple Jian | Uncommon | 25 | Celestial Sky Cyan | `#38BDF8` |
| **3** | `FlowingQiSpiritSword` | Flowing Qi Spirit Sword | Rare | 40 | Electric Ocean Sapphire | `#0EA5E9` |
| **4** | `VerdantJadeFlyingSword` | Verdant Jade Flying Sword | Epic | 60 | Imperial Emerald Jade | `#34D399` |
| **5** | `VioletSoulSovereignJian` | Violet Soul Sovereign Jian | Legendary | 120 | Royal Amethyst Violet | `#C084FC` |
| **6** | `VoidStarCleaverDao` | Void Star Cleaver Dao | Mythic | 220 | Cosmic Void Purple | `#A855F7` |
| **7** | `AzurePatriarchHeritageJian` | Azure Patriarch Heritage Jian | Divine | 450 | Luminescent Divine Cyan | `#22D3EE` |
| **8** | `RadiantImmortalSovereignJian` | Radiant Immortal Sovereign Jian | Immortal | 1000 | Blinding Solar Dao Gold | `#FACC15` |

---

## 4. Cultivation Progression Matrix

Cultivation is configured in `CultivationConfig.luau` across **10 Major Realms**, each containing **9 Orders** (90 total stages):

$$\text{Order Health} = \lfloor \text{BaseMaxHealth} \times 1.35^{(\text{Order}-1)} \rfloor$$
$$\text{Order Target Qi} = \lfloor \text{BaseTargetQi} \times 1.45^{(\text{Order}-1)} \rfloor$$
$$\text{Power Multiplier} = \text{HealthMultiplier} \times [1 + (\text{Order}-1) \times 0.15]$$

| Realm Tier | Realm Name | Base Max HP | Base Target Qi | Tribulation Strikes | Power Mult (Order 1 $\rightarrow$ 9) |
| :---: | :--- | :---: | :---: | :---: | :---: |
| **1** | Qi Condensation | 1,000 | 1,000 | 0 (Safe) | $1.0\times \rightarrow 2.2\times$ |
| **2** | Foundation Establishment | 15,000 | 15,000 | 2 Strikes | $15.0\times \rightarrow 33.0\times$ |
| **3** | Golden Core | 75,000 | 75,000 | 3 Strikes | $75.0\times \rightarrow 165.0\times$ |
| **4** | Nascent Soul | 350,000 | 350,000 | 4 Strikes | $350.0\times \rightarrow 770.0\times$ |
| **5** | Spirit Severing | 1,500,000 | 1,500,000 | 5 Strikes | $1,500.0\times \rightarrow 3,300.0\times$ |
| **6** | Void Refining | 7,500,000 | 7,500,000 | 5 Strikes | $7,500.0\times \rightarrow 16,500.0\times$ |
| **7** | Body Integration | 25,000,000 | 25,000,000 | 6 Strikes | $25,000.0\times \rightarrow 55,000.0\times$ |
| **8** | Mahayana | 55,000,000 | 55,000,000 | 7 Strikes | $55,000.0\times \rightarrow 121,000.0\times$ |
| **9** | Tribulation Transcending | 80,000,000 | 80,000,000 | 9 Strikes | $80,000.0\times \rightarrow 176,000.0\times$ |
| **10** | Immortal Ascension | 100,000,000 | 100,000,000 | 0 (Dao Master) | $100,000.0\times \rightarrow 220,000.0\times$ |

---

## 5. Zone 1: Jade Pure Sect World Hub (ADR-044)

The primary world hub is arranged in a 3-tier stepped elevation layout:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 3: UPPER SOVEREIGN PALACE                                              │
│ - Grand Sect Palace Hall (Black Roof Tile Aesthetic)                        │
│ - Supreme Sect Leader, Grand Sword Elder Liang                              │
│ - Top 7 Pillars of the Sect (Lore Masters) & Elite Sect Guards              │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 2: MIDDLE SPIRITUAL DAO SANCTUARY                                      │
│ - Elevated Sword Altar (Weapon Attunement & Pedestal Display)               │
│ - Inner Disciple Courtyards & Spirit Qi Meditation Pavements                │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 1: LOWER SERVICE & TRAINING GROUNDS                                    │
│ - Blacksmith Forge (Madame Tie: +10 Blade Refinement)                       │
│ - Spirit Tea Pavilion (Xiao Ling: 3 Brews, Timed Cultivation Buffs)         │
│ - Sect Training Grounds (Instructor Wu, 3 Immortal Dummies, DPS Meters)     │
│ - Sect Starter Guide Pavilion (Elder Qing: Interactive 4-Tab Codex)         │
│ - Bronze Alchemy Cauldron (Master Shen: 3-Slot Herb Minigame)               │
│ - Notice Board (Deacon Zhao: 3-Tier Daily Duties & Bounty Submissions)       │
│ - Sect Treasury & Market (Steward Jin: Weapon Catalog & Trading)            │
│ - Sakura Grove (2.0x Qi Buff), Training Disciples, Wilderness Portal        │
└─────────────────────────────────────────────────────────────────────────────┘
6. Documentation Directory
Document	Path	Scope & Ground Truth Content
Architecture Specification	docs/ARCHITECTURE_SPEC.md	Complete map of 16 Server Managers, 22 Client Controllers, 22 Remotes, and network data flow.
Combat Specification	docs/COMBAT_SPEC.md	Pure sword combat engine: 5-hit combo, Sword Intent, Parrying/Posture, skills (Q, E, F), and flight.
Progression Specification	docs/PROGRESSION_SPEC.md	10 Major Realms × 9 Orders cultivation math, breakthroughs, Tribulation Lightning, and Spirit Tea buffs.
UI/UX Specification	docs/UI_UX_SPEC.md	Studio-authoritative GUI standards, Bangers/Fundamento typography, color tokens, and Master HUD layouts.
Game Design Document	docs/GAME_DESIGN.md	Core game loop, world geography, NPC roster, sect duties, economy, and gathering/crafting systems.
Asset Manifest	docs/ASSET_MANIFEST.md	Canonical index of weapon models, audio IDs, animations, and particle VFX references.
Code Dependency Guide	docs/CODE_DEPENDENCY_GUIDE.md	Require hierarchy, remote event bindings, circular dependency safeguards, and boot sequences.
Codebase Cleanup Guide	docs/CODEBASE_CLEANUP_GUIDE.md	Strict pruning policies, single-weapon architecture enforcement, and dead-code prevention rules.
Roblox Performance Rules	docs/ROBLOX_PERFORMANCE_RULES.md	60 FPS mobile budgets, memory limits, raycast culling, foliage collision pruning, and network limits.
7. Operational State Tracking (.ai/)
File	Purpose	Rule
.ai/CURRENT_TASK.md	Active single task focus	Only 1 active task at a time. Verified against live code before execution.
.ai/NEXT_STEPS.md	Prioritized technical roadmap	Queued engineering milestones in logical dependency order.
.ai/PROJECT_STATUS.md	Subsystem health matrix	Factual audit of system status; no inflated completion percentages.
.ai/DECISIONS.md	Architecture Decision Records	Formal log of decisions (ADR-001 through ADR-044). Consult before making architectural shifts.
.ai/CHANGELOG.md	Verifiable development history