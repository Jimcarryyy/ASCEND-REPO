### 2. Complete Replacement: `docs/README.md`

```markdown
# ASCEND — Technical Documentation & Architecture Index

> **Authoritative Technical Index**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Baseline Engine Status:** Phase 1 Complete & Verified (DataStore V3, 16 Typed Remotes)

---

## 1. Architectural Baseline & Standards

**ASCEND** is a high-performance Roblox Xianxia Action RPG built on the Roblox R6 avatar rig. The architecture enforces strict server authority, deterministic combat hitboxes, zero dynamic runtime UI instantiation, and strict type safety.

### Technical Baseline
- **Avatar Hierarchy:** Standard Roblox R6. Rigid joint hierarchy, predictable physics replication, zero ragdoll twitching, and mobile performance optimization.
- **Persistence Engine:** `ASCEND_PlayerData_V3` (`PlayerDataManager.luau`). Authoritative DataStore with automatic schema migration, Samsara cycle tracking, Roman numeral prestige titles, Bloodline pity tracking, and authoritative `RouteToSpawnDais` spawn fallback.
- **Network Pipeline:** Exactly 16 centralized, strictly typed (`--!strict`) `RemoteEvent` instances in `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`. 16 legacy unused remotes have been pruned.
- **UI Architecture (ADR-041, ADR-069):** Studio-authoritative `StarterGui` instances built via Edit Mode scripts. Programmatic `Instance.new` GUI generation in client scripts is prohibited. All frames, buttons, and slots strictly enforce a **Zero UICorner** mandate with dark celestial slate containers.
- **Typography Standards (ADR-042, ADR-072):**
  - **Headers & Titles:** `Enum.Font.Bangers` with solid black `UIStroke` (`Thickness = 1.5 - 2.0`).
  - **Body Text & Lore:** `Enum.Font.Fondamento`.
  - **Combat Damage Numbers:** `Font.fromName("Press Start 2P")` / `Enum.Font.Arcade` displaying pure numeric values only (no words or intent badges).

---

## 2. Canonical Master Keybind Map

| Keybind | Action | Description & Mechanical Rules |
| :---: | :--- | :--- |
| **`M1`** | **5-Hit Sword Combo** | Heavy sword chain (`Hit 1` to `Hit 5`). Movement dampened to `WalkSpeed = 8` during swings. AutoRotate locked against RootJoint twisting. Hits grant **+25% Sword Intent**. At **100% Intent**, the next hit delivers **1.75× Damage** with golden VFX. |
| **`Left Control`** | **Sprint Toggle** | Toggles movement between Walk (13.5 studs/s) and Sprint (36 studs/s open world / 30 arena) with dynamic FOV expansion ($70^\circ \rightarrow 76^\circ$). |
| **`Left Shift`** | **Qi Flash-Step Dash** | 4-way camera-relative directional burst over 0.16s with Shunpo vanish/reappear VFX and anti-trip `AlignOrientation`. 3.0s cooldown, costs 3% Qi. |
| **`T`** | **Guard / Perfect Parry** | **Hold:** Frontal 180° guard reducing damage by 80% and knockback by 70%, consuming Posture.<br>**Tap within 0.22s:** Perfect Parry via `Workspace:GetServerTimeNow()`, negating 100% damage, staggering attacker for 0.5s, and restoring +5% Qi. |
| **`C`** | **Qi Meditation** | Seated cultivation restoring 10.0% Qi/s. Gated behind `InCombat == false`; combat actions lock during meditation. |
| **`R`** | **Draw / Sheathe Sword** | Toggles weapon weld between Hand Grip (`RightGripAttachment`) and upper back torso sheath. |
| **`V`** | **Flying Sword Flight Mode** | Mounts sword under feet for 3D aerial navigation. Flight velocity scales dynamically by cultivation realm (48+ studs/s). Pauses passive recovery, drains 25 Qi/s, and auto-dismounts at 0 Qi or when struck in combat. |
| **`B`** | **Realm Breakthrough** | Attempts realm breakthrough when Cultivated Qi is at 100%. Gated behind Breakthrough Dan validation, Inner Demon QTE, or Tribulation Lightning. |
| **`Q`** | **Skill: Sword Tempest** | Point-blank 360° melee cleave (25 dmg) + 3 traveling sawblades (54 total dmg). Zero knockback (`Vector3.zero`) slices targets in place. Costs 15% Qi, 3.5s cooldown. |
| **`E`** | **Interact / Piercing Thrust** | Primary world interaction (Bloodline Altar, Merchant Qian, Dialogue). When weapon is drawn: Piercing Void Thrust beam (80 dmg). |
| **`F`** | **Ultimate: Flash Domain** | 28-stud instant Celestial Flash-Step slash phasing through enemies + mid-air slice + 36-stud domain detonation (5 hits × 20 dmg). Costs 20% Qi, 5.5s cooldown. |
| **`H`** | **Heavenly Codex** | Opens the comprehensive in-game cultivation guidebook (`CodexGui`). |
| **`P`** | **Character Stats Sheet** | Toggles `CharacterStatsGui` displaying Realm, Order, Attributes, and active Bloodline. |
| **`Tab` / `I`** | **Spirit Pouch (Inventory)** | Opens spatial inventory pouch for pills, herbs, and materials. |

---

## 3. Weapon Arsenal & Dynamic VFX Palettes

All weapons in ASCEND are Flying Swords governed by `ItemConfig.luau` and dynamically attuned via `ItemConfig.GetWeaponPalette(weaponId)`:

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

*Note: In accordance with ADR-074, swords cannot be bought or sold in the Sect Merchant Market.*

---

## 4. Cultivation Progression Matrix

Configured in `CultivationConfig.luau` across **10 Major Realms**, each with **9 Orders** (90 total stages):

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

## 5. Bestiary Architecture: Pure Humanoid R6 Cultivators

In accordance with ADR-076, all quadruped beast models have been permanently purged from the engine. All zone enemies are standard Roblox Humanoid R6 Cultivators powered by `MobAIManager.luau` and `SPAWNER_ALIAS_MAP`:

| Index | Mob Model Key | Display Name | Role / Danger Tier | Weapon Equipped |
| :---: | :--- | :--- | :--- | :--- |
| **1** | `RogueDisciple` | Rogue Disciple | Tier 1 Swarm (Qi Condensation) | Mortal Iron Jian |
| **2** | `BanditCultivator` | Bandit Cultivator | Tier 1 Roamer (Qi Condensation) | Mortal Iron Jian |
| **3** | `GhostBladeMarauder`| Ghost Blade Marauder | Tier 2 Skirmisher (Foundation) | Azure Cloud Disciple Jian |
| **4** | `BloodShadowAssassin`| Blood Shadow Assassin | Tier 2 Agility Flanker (Foundation)| Azure Cloud Disciple Jian |
| **5** | `CorruptedIronGuard` | Corrupted Iron Guard | Tier 3 Heavy Brute (Golden Core) | Flowing Qi Spirit Sword |
| **6** | `FrostPeakApostle` | Frost Peak Apostle | Tier 3 Elementalist (Golden Core) | Flowing Qi Spirit Sword |
| **7** | `FallenInnerProdigy` | Fallen Inner Prodigy | Tier 4 Mini-Boss (Nascent Soul) | Verdant Jade Flying Sword |
| **8** | `VoidPhantomSwordmaster`| Void Phantom Swordmaster| Tier 4 Elite Duelist (Nascent Soul)| Verdant Jade Flying Sword |
| **9** | `Boss_FallenSwordGenius`| Mo Chen (Fallen Genius)| Zone 1 World Boss (Nascent Soul) | Violet Soul Sovereign Jian |
| **10**| `AsuraSwordSovereign`| Asura Sword Sovereign | Calamity World Boss (Immortal) | Radiant Immortal Sovereign Jian |

---

## 6. Documentation Directory & Tracking

| Document | Path | Scope & Ground Truth Content |
| :--- | :--- | :--- |
| **Architecture Specification** | `docs/ARCHITECTURE_SPEC.md` | Maps Server Managers, Client Controllers, 16 Typed Remotes, and lifecycle pipelines. |
| **Combat Specification** | `docs/COMBAT_SPEC.md` | Authoritative sword combat: 5-hit chain, Sword Intent, Posture/Parry, Skills (Q, E, F), and Flight. |
| **Progression Specification** | `docs/PROGRESSION_SPEC.md` | Cultivation formulas, Breakthrough Dan recipes, Tribulation Lightning, and Samsara Rebirth. |
| **Asset Manifest** | `docs/ASSET_MANIFEST.md` | Canonical index of sword models, 12 bloodline floating relics, 10 R6 mobs, audio, and animations. |
| **UI/UX Specification** | `docs/UI_UX_SPEC.md` | Studio-authoritative GUI layouts, Bangers/Fondamento typography, Arcade damage numbers, Zero UICorner rule. |
| **Roblox Performance Rules** | `docs/ROBLOX_PERFORMANCE_RULES.md`| 60 FPS mobile budgets, raycast spatial queries, memory ceilings (<800 MB), and cleanup rules. |
| **Operational Tracking** | `.ai/` | Single-task tracker (`CURRENT_TASK.md`), technical roadmap (`NEXT_STEPS.md`), health matrix (`PROJECT_STATUS.md`), and ADR log (`DECISIONS.md`). |