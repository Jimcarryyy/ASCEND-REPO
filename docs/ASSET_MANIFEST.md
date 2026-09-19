---

### 4. Complete Replacement: `docs/ASSET_MANIFEST.md`

```markdown
# ASCEND — Master 2D/3D Asset Manifest

> **Canonical Technical Asset Manifest**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Roblox Asset Registry  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge

---

## 1. Master Flying Sword Arsenal (8 Canonical Tiers)

All 8 sword tiers are registered in `ItemConfig.luau` and utilize standard R6 weapon welds (`RightGripAttachment` in hand, `BackSwordMount` on upper back):

| Tier | Weapon ID | Name | Rarity | Base Dmg | VFX Palette Theme | Primary Hex | Model Location |
| :---: | :--- | :--- | :---: | :---: | :--- | :---: | :--- |
| **1** | `MortalIronJian` | Mortal Iron Jian | Common | 15 | Cold Silver-White | `#DCE1EB` | `ReplicatedStorage.Assets.Swords.MortalIronJian` |
| **2** | `AzureCloudDiscipleJian` | Azure Cloud Disciple Jian | Uncommon | 25 | Celestial Sky Cyan | `#38BDF8` | `ReplicatedStorage.Assets.Swords.AzureCloudDiscipleJian` |
| **3** | `FlowingQiSpiritSword` | Flowing Qi Spirit Sword | Rare | 40 | Electric Ocean Sapphire| `#0EA5E9` | `ReplicatedStorage.Assets.Swords.FlowingQiSpiritSword` |
| **4** | `VerdantJadeFlyingSword` | Verdant Jade Flying Sword | Epic | 60 | Imperial Emerald Jade | `#34D399` | `ReplicatedStorage.Assets.Swords.VerdantJadeFlyingSword` |
| **5** | `VioletSoulSovereignJian`| Violet Soul Sovereign Jian| Legendary | 120 | Royal Amethyst Violet | `#C084FC` | `ReplicatedStorage.Assets.Swords.VioletSoulSovereignJian` |
| **6** | `VoidStarCleaverDao` | Void Star Cleaver Dao | Mythic | 220 | Cosmic Void Purple | `#A855F7` | `ReplicatedStorage.Assets.Swords.VoidStarCleaverDao` |
| **7** | `AzurePatriarchHeritageJian`| Azure Patriarch Heritage Jian| Divine | 450 | Luminescent Divine Cyan| `#22D3EE`| `ReplicatedStorage.Assets.Swords.AzurePatriarchHeritageJian`|
| **8** | `RadiantImmortalSovereignJian`| Radiant Immortal Sovereign Jian| Immortal| 1000 | Blinding Solar Dao Gold| `#FACC15`| `ReplicatedStorage.Assets.Swords.RadiantImmortalSovereignJian`|

---

## 2. 3D Bloodline Companion Relics (12 Canonical Lineages)

In accordance with ADR-068, all body-clinging relic armor meshes are purged in favor of floating companion spirit orbs/halos orbiting the character (`ARTIFACT_OFFSETS`):

| Bloodline Lineage Key | Tier | Companion Relic Name | Floating Position Offset | Hex Tint / Elemental Theme |
| :--- | :---: | :--- | :--- | :--- |
| **`MortalSwordBone`** | Common | `SteelSwordOrb` | Left Shoulder $( -1.8, 1.6, 0.4 )$ | `#BDD2E1` (Silver Tempered Steel) |
| **`IronMeridianRoot`** | Common | `IronRootOrb` | Right Shoulder $( 1.8, 1.5, 0.4 )$ | `#A0785A` (Bronze Earth Root) |
| **`BreezeSpiritVein`** | Common | `WindGaleOrb` | Left Shoulder $( -1.7, 1.7, 0.5 )$ | `#96EBC8` (Mint Seafoam Wind) |
| **`AzureDragonMeridian`** | Rare | `AzureDragonOrb` | Right Shoulder $( 1.9, 1.8, 0.5 )$ | `#22D3EE` (Electric Cyan Dragon) |
| **`JadeLotusHeart`** | Rare | `JadeLotusOrb` | Above Head $( 0.0, 2.8, -0.2 )$ | `#34D399` (Purifying Jade Lotus) |
| **`CrimsonFlameCore`** | Rare | `CrimsonFlameOrb` | Right Shoulder $( 1.8, 1.6, 0.4 )$ | `#EF4444` (True Fire Vermilion) |
| **`GoldenThunderBone`** | Epic | `ThunderCoreOrb` | Floating Back $( 0.0, 1.5, 1.8 )$ | `#FACC15` (Solar Heavenly Thunder) |
| **`ShadowVoidVein`** | Epic | `CosmicVoidSphere`| Left Shoulder $( -1.8, 1.8, 0.4 )$ | `#8B5CF6` (Abyssal Shadow Void) |
| **`SolarCrowMeridian`** | Legendary | `SolarCrowHalo` | Upper Torso Halo $( 0.0, 1.9, 0.0 )$ | `#F97316` (Sun Divine Crow Gold) |
| **`GlacialPhoenixMeridian`**| Legendary | `GlacialPhoenixOrb`| Left Shoulder $( -1.9, 1.8, 0.5 )$ | `#38BDF8` (Nine-Frost Glacial Cyan) |
| **`CosmicVoidSovereign`** | Mythic | `SingularityOrb` | Floating Crown $( 0.0, 2.9, 0.0 )$ | `#6B21A8` (Deep Space Singularity) |
| **`NineNetherSovereign`** | Mythic | `NineNetherCrown` | Floating Crown $( 0.0, 3.1, 0.0 )$ | `#1E1B4B` (Nether Soul Obsidian) |

---

## 3. Bestiary: Pure Humanoid R6 Cultivators (`ReplicatedStorage.MobModels`)

In accordance with ADR-076, all quadruped beast models (`DemonWolf`, `IronhideBoar`, `SilverbackFrostApe`, `VoidChasmChimera`, `AbyssalDemonSovereign`) are purged. 100% of zone enemies are Humanoid R6 Cultivators:

| Mob Model Key | Spawner Alias Key | Role / Danger Tier | Scale | Key Visuals |
| :--- | :--- | :--- | :---: | :--- |
| **`RogueDisciple`** | `Spawner_RogueDisciples` | Common Swarm (Tier 1) | `1.00x` | Ash-grey robes, white blindfold, Mortal Iron Jian. |
| **`BanditCultivator`** | `Spawner_Bandits` | Wilderness Roamer (Tier 1) | `1.00x` | Coarse leather robes, straw sandals, Mortal Iron Jian. |
| **`GhostBladeMarauder`**| `Spawner_GhostBlades` | Skirmisher (Tier 2) | `1.05x` | Torn midnight garb, rusted faceplate, Azure Disciple Jian. |
| **`BloodShadowAssassin`**| `Spawner_BloodShadows` | Agility Flanker (Tier 2) | `0.95x` | Stealth black robes, straw hat, Azure Disciple Jian. |
| **`CorruptedIronGuard`** | `Spawner_CorruptedGuards` | Heavy Brute (Tier 3) | `1.30x` | Dark iron demon mask, spiked bracers, Flowing Qi Sword. |
| **`FrostPeakApostle`** | `Spawner_FrostApostles` | Elementalist (Tier 3) | `1.05x` | Frost-bitten white furs, ice talisman, Flowing Qi Sword. |
| **`FallenInnerProdigy`** | `Spawner_FallenProdigies` | Mini-Boss (Tier 4) | `1.20x` | Midnight-blue robes, flowing white hair, Verdant Jade Sword. |
| **`VoidPhantomSwordmaster`**| `Spawner_VoidPhantoms`| Elite Duelist (Tier 4) | `1.15x` | Phasing purple mist, cracked mask, Verdant Jade Sword. |
| **`Boss_FallenSwordGenius`**| `Spawner_BossFallenSwordGenius`| World Boss (Mo Chen) | `1.28x` | Ink-and-blood robes, single horn, Violet Sovereign Jian. |
| **`AsuraSwordSovereign`**| `Spawner_AsuraSovereign` | Calamity World Boss | `1.40x` | Obsidian demon armor, six phantom arms, Radiant Sovereign Jian. |

---

## 4. Custom R6 Movement & Combat Animation Suite

All animations are R6 rigs registered in `AnimationConfig.luau`:

| Action / State | Roblox Asset ID | Rig | Priority | Notes / Execution |
| :--- | :--- | :---: | :---: | :--- |
| **Idle Stance** | `rbxassetid://98257310687211` | R6 | `Idle` | Grounded breathing martial posture. |
| **Walk Stride** | `rbxassetid://92949542384678` | R6 | `Action2` | Walking locomotion (13.5 studs/s). |
| **Run Stride** | `rbxassetid://106115576089829` | R6 | `Action3` | Weighted glide run (0.70x playback speed). |
| **Dash W (Forward)** | `rbxassetid://118004062849712` | R6 | `Action4` | Forward Shunpo vanish burst. |
| **Dash S (Backward)** | `rbxassetid://87494050060721` | R6 | `Action4` | Backward evasive retreat step. |
| **Dash A (Left)** | `rbxassetid://118004062849712` | R6 | `Action4` | Left lateral evasive slip. |
| **Dash D (Right)** | `rbxassetid://87494050060721` | R6 | `Action4` | Right lateral evasive slip. |
| **Jump Takeoff** | `rbxassetid://115002701112708` | R6 | `Action4` | Vertical jump takeoff pose. |
| **Freefall** | `rbxassetid://105371732122929` | R6 | `Action4` | High-cliff falling posture (>0.35s airborne). |
| **Landed Recovery** | `rbxassetid://127232864368618` | R6 | `Action4` | Ground impact absorption recovery. |
| **Meditation Form** | `rbxassetid://129333803961409` | R6 | `Action4` | Grounded cross-legged cultivation sitting posture. |
| **Sword Equip (Draw)** | `rbxassetid://114060318185092` | R6 | `Action3` | Draws sword from back sheath to hand grip. |
| **Sword Unequip (Sheath)**| `rbxassetid://97568182472477` | R6 | `Action3` | Returns sword from hand to upper back sheath. |
| **M1 Slash 1** | `rbxassetid://129254042886405` | R6 | `Action4` | Horizontal opening slash. |
| **M1 Slash 2** | `rbxassetid://78342794513338` | R6 | `Action4` | Diagonal downward cut. |
| **M1 Slash 3** | `rbxassetid://133701354257850` | R6 | `Action4` | Wide sweeping cross-cleave. |
| **M1 Slash 4** | `rbxassetid://140582503077234` | R6 | `Action4` | Penetrating body-thrust. |
| **M1 Finisher 5** | `rbxassetid://111677132360566` | R6 | `Action4` | Overhead finisher slam. |
| **Hit Reaction 1** | `rbxassetid://129254042886405` | R6 | `Action4` | Light recoil flinch on sword hit. |
| **Hit Reaction 2** | `rbxassetid://78342794513338` | R6 | `Action4` | Heavy stumble recoil. |
| **Parryed Deflection**| `rbxassetid://133701354257850` | R6 | `Action4` | Blade deflection knockback pose. |
| **Stun / GuardBroken** | `rbxassetid://121973766317438` | R6 | `Action4` | Staggered stunned posture on parry or guard break. |

---

## 5. Universal Audio Suite

Registered in `SoundService` and `UIAssets.Audio`:

| Asset Name | Asset ID | Volume | Trigger / Usage |
| :--- | :--- | :---: | :--- |
| **Exploration BGM** | `rbxassetid://137280276426447` | `0.35` | Ambient exploration music in `ReplicatedFirst`. |
| **Sword Slash Whoosh** | `rbxassetid://79218449800283` | `0.80` | Blade cutting air whoosh on M1 swings. |
| **Sword Hit Impact** | `rbxassetid://140462043853173` | `0.95` | Positional impact audio on confirmed sword strike. |
| **Parry Metal Clash** | `rbxassetid://9114223175` | `1.00` | Resonant metallic blade clash on Perfect Parry. |
| **Qi Dash Whoosh** | `rbxassetid://93272068959626` | `0.75` | Ethereal spirit burst dash sound (`Shift`). |
| **Ultimate Domain Roar** | `rbxassetid://18781431019` | `1.00` | 3D spatial detonation sound for 100-Slash Domain (`F`). |
| **Sword Draw SFX** | `rbxassetid://114060318185092` | `0.75` | Metallic draw sound when equipping sword (`R`). |
| **Sword Sheath SFX** | `rbxassetid://97568182472477` | `0.75` | Scabbard click when sheathing sword to back (`R`). |
| **Meditation Ambience** | `rbxassetid://103967342049425` | `0.50` | Looped resonant meditation drone (`C`). |
| **Panel Click SFX** | `rbxassetid://138567614125924` | `0.55` | UI buttons, slot clicks, and Altar interactions. |
| **Menu Select SFX** | `rbxassetid://101735926591481` | `0.65` | Navigation tabs and modal window confirmations. |

---

## 6. 2D Icon & Item Token Manifest

Registered in `UIAssets.luau` and `ItemConfig.luau`:

| Item ID | Display Name | Asset ID | Category / Usage |
| :--- | :--- | :--- | :--- |
| **`SpiritGrass`** | Spirit Grass (1Yr - 1000Yr) | `rbxassetid://112390155425328` | Herb Gathering Ingredient |
| **`GaleWindLotus`** | Gale Wind Lotus | `rbxassetid://97399822723211` | Herb Gathering Ingredient |
| **`DragonBloodVine`** | Dragon Blood Vine | `rbxassetid://87215598829275` | Herb Gathering Ingredient |
| **`CelestialDew`** | Celestial Morning Dew | `rbxassetid://131403489720983` | Cauldron Catalyzer |
| **`SpiritAsh`** | Spirit Ash (Slag) | `rbxassetid://128820714120893` | Failed Alchemy Product |
| **`DemonBeastCore`** | Demon Beast Core (Graded) | `rbxassetid://127840279619766` | Monster Drop / Alchemy Core |
| **`QiGatheringDan`** | Qi Gathering Dan | `rbxassetid://136942657595135` | Consumable Qi Restoration Pill |
| **`FoundationGatheringDan`**| Foundation Gathering Dan | `rbxassetid://135779673578731` | Breakthrough Pill (Realm 1 $\rightarrow$ 2) |
| **`PhysiqueTemperingDan`**| Physique Tempering Dan | `rbxassetid://127548831742229` | Permanent Health Pill |
| **`SpiritHealingDan`** | Spirit Healing Dan | `rbxassetid://72471225624084` | Health Restoration Consumable |
| **`SpiritStones`** | Spirit Stone Crystal | `rbxassetid://139743745524676` | Primary World Currency |
| **`ContributionPoints`**| Sect Merit Medallion | `rbxassetid://129257153774545` | Sect Contribution Currency |