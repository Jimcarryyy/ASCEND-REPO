# ASCEND — Asset Integration & System Implementation Plan

## Feature Track Overview
- [ ] **MON: Monster Core** (Humanoid Decoupling & MonsterUtil Architecture)
- [ ] **ANIM: Monster Animations** (Animation Loader & Procedural Fallbacks)
- [ ] **MOB: The 5 Mobs** (Beast AI Patterns, Posture, and Spawners)
- [ ] **BOSS: Bosses & World Chest** (Boss Ability Framework, 3 Boss Encounters, Loot Chest)
- [ ] **NPC: NPCs & Bounties** (Sect Dispatchers, Zone Bounties, Hub Facility Prompts)
- [ ] **PROP: World Facilities & Fast Travel** (Cauldron, Anvil, Waypoint Pillars)
- [ ] **BLD: Bloodline Orbs** (Sword Bloodline Overhaul, 9 Floating Relics, Combat Passives)

---

## Feature MON: Monster Core (Humanoid Decoupling)

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [x] | **`MON-0`** | **Decision Gate:** CLOSED. Monsters are Humanoid-free. AnimationController hosts Animator; state/health stored via attributes. | *None (Architectural Decision)* |
| [ ] | **`MON-1`** | Fix quest kill-tracking bug: replace hardcoded `"RogueDisciple"` with dynamic `mob.Id`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-2`** | Create `MonsterUtil.luau` standalone foundation module (attribute-first reading, damage, death, state). | `src/ReplicatedStorage/Shared/Utils/MonsterUtil.luau` *(New)* |
| [ ] | **`MON-3`** | Route player hit detection, damage application, and parry stun through `MonsterUtil`. Notify mob on hit. | `src/ServerScriptService/Server/Combat/HitboxManager.luau` |
| [ ] | **`MON-4`** | `MobAIManager` spawn contract: validate `char1` PrimaryPart and `AnimationController`, get-or-create `Animator`, dynamic spawn height from extents, missing `Head` fallback, move models from staging to `ReplicatedStorage.MobModels`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-5`** | **Locomotion Layer & Facing Offset:** Implement Option A (unanchored + `SetNetworkOwner(nil)` + `LinearVelocity`/`AlignOrientation`), verify mesh facing axis, and implement `FacingOffset`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-6`** | Update client consumers: ALT lock-on reticle, screen boss health bar, overhead billboard bar using model attributes, dynamic height offsets for health UI and telegraph glints. | `src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau`<br>`src/StarterPlayer/StarterPlayerScripts/Controllers/BossHUDController.luau`<br>`src/ServerScriptService/Server/Combat/MobAIManager.luau` |

---

## Feature ANIM: Monster Animations

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`ANIM-0`** | Investigation & Asset Audit: Locate/confirm animation asset IDs for quadrupeds. | *None (Audit / Asset Sourcing)* |
| [ ] | **`ANIM-1`** | Create `MonsterAnimLoader.luau`: get-or-create Animator under AnimationController, play by name, sync walk speed, provide procedural body motion fallback when animations are missing. | `src/ReplicatedStorage/Shared/Utils/MonsterAnimLoader.luau` *(New)* |
| [ ] | **`ANIM-2`** | Developer Authoring: Author/test one shared quadruped animation set (idle, walk, run, hit, stagger, death, attack windup) across the shared 24-bone rigs. | *Studio Animation Track Task* |

---

## Feature MOB: The 5 Mobs

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`MOB-1`** | Extend `MobConfig.luau` schema (`AIPattern`, `Animations`, `BodyRadius`, `FacingOffset`) without altering existing 10 mobs. | `src/ReplicatedStorage/Shared/Configs/MobConfig.luau` |
| [ ] | **`MOB-2`** | Implement mob posture/poise damage deduction and guard break in combat resolution. | `src/ServerScriptService/Server/Combat/HitboxManager.luau`<br>`src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MOB-3`** | AI pattern framework: build behavior dispatcher inside `StepAI` with attack/reaction helpers (windup, flinch, stagger, death collapse). | `src/ServerScriptService/Server/Combat/MobAIManager.luau`<br>`src/ServerScriptService/Server/Combat/MobPatterns/` *(New)* |
| [ ] | **`MOB-4a`** | **Iron-Tusk Spirit Boar:** Config entry, linear charge brute pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4b`** | **Wilderness Spirit Wolf:** Config entry, orbiting pack hunter / pounce pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4c`** | **Magma Hound:** Config entry, fast flanking zig-zag pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4d`** | **Obsidian Lava-Boar:** Config entry, armored charge, poise immunity, and ground hazard pattern. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4e`** | **Frost-Fang Wolf:** Config entry, frost pounce pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-5`** | Implement Frost-Fang Wolf player debuffs (stamina drain and posture recovery delay). | `src/ServerScriptService/Server/State/CombatStateManager.luau` |

---

## Feature BOSS: Bosses & Loot Chest

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`BOSS-0`** | **Decision Gate:** Register dedicated `LootRewardRemote` vs route chest rewards through `InventoryAction`. | *None (Design Decision)* |
| [ ] | **`BOSS-1`** | Boss ability framework (cooldown-driven abilities, invulnerability flag, radial stagger). | `src/ServerScriptService/Server/Combat/MobAIManager.luau`<br>`src/ServerScriptService/Server/Combat/BossAbilities.luau` *(New)* |
| [ ] | **`BOSS-2a`** | **Corrupted Alpha Wolf:** Config entry, Roar Buff (invulnerability + radial stagger), Corruption Slam. | `MobConfig.luau`<br>`BossAbilities.luau` |
| [ ] | **`BOSS-2b`** | **Molten Hell-Lion Sovereign:** Config entry, Tectonic Stomp (lava bursts), Blazing Rush (damaging trail). | `MobConfig.luau`<br>`BossAbilities.luau` |
| [ ] | **`BOSS-2c`** | **Frost-Saber Sovereign:** Config entry, Glacial Swipe (180° sweep), Blizzard Leap (leap + ground shatter). | `MobConfig.luau`<br>`BossAbilities.luau` |
| [ ] | **`BOSS-3`** | **Boss Loot Chest:** Dynamic spawn on boss death, proximity prompt interaction, loot roll, and dissolve. | `src/ServerScriptService/Server/Combat/MobAIManager.luau`<br>`src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`<br>`src/ServerScriptService/Server/World/LootChestManager.luau` *(New)* |
| [ ] | **`BOSS-4`** | Boss HUD polish, nameplate formatting, and dynamic multi-phase health bar handling. | `src/StarterPlayer/StarterPlayerScripts/Controllers/BossHUDController.luau` |

---

## Feature NPC: NPCs & Bounties

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`NPC-0`** | **Decision Gate:** Master Tie weapon forging vs `VendorManager` weapon trading ban. | *None (Design Decision)* |
| [ ] | **`NPC-1`** | Zone bounty endpoint in `SectManager.luau` (dynamic kill bounties for 3 zones). | `src/ServerScriptService/Server/Cultivation/SectManager.luau` |
| [ ] | **`NPC-2`** | Bounty display in quest tracker UI + proximity interaction for the 3 zone dispatchers. | `src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau` |
| [ ] | **`NPC-3`** | Connect Senior Brother Chen (Tutorial), Madam Qing (Alchemy), and Master Tie (Blacksmith) prompts. | `src/StarterPlayer/StarterPlayerScripts/Controllers/StarterGuideController.luau`<br>`src/ServerScriptService/Server/Cultivation/AlchemyManager.luau`<br>`src/ServerScriptService/Server/Combat/WeaponManager.luau` |

---

## Feature PROP: World Facilities & Fast Travel

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`PROP-1`** | Alchemy Cauldron and Blacksmith Anvil station models, collision settings, and proximity triggers. | `src/ServerScriptService/Server/Cultivation/AlchemyManager.luau`<br>`src/ServerScriptService/Server/Combat/WeaponManager.luau` |
| [ ] | **`PROP-2`** | Spirit Resonance Waypoint Pillar (discovery unlock, zone map fog reveal, fast-travel teleport). | `src/ServerScriptService/Server/World/WaypointManager.luau` *(New)*<br>`src/ServerScriptService/Server/State/PlayerDataManager.luau`<br>`src/StarterPlayer/StarterPlayerScripts/Controllers/WaypointController.luau` *(New)* |

---

## Feature BLD: Bloodline Orbs

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`BLD-0`** | **Decision Gate:** Overhaul existing 7-tier gacha to 5-tier sword bloodlines vs mapping existing saves. | *None (Design Decision)* |
| [ ] | **`BLD-1`** | Config schema update and 3D visual attachment (offset `CFrame.new(-1.5, 2.2, 0.2)` on torso). | `src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau`<br>`src/ServerScriptService/Server/State/BloodlineManager.luau` |
| [ ] | **`BLD-2`** | Passive stat wiring (posture recovery rate, dash leap distance, maximum posture gauge). | `src/ServerScriptService/Server/State/CombatStateManager.luau`<br>`src/ServerScriptService/Server/State/PlayerDataManager.luau` |
| [ ] | **`BLD-3`** | Combat resolution passives (critical damage, bonus damage vs guard-broken, i-frame extensions, void echoes). | `src/ServerScriptService/Server/Combat/HitboxManager.luau` |

---

## Scope Amendment & Architecture Addendum — 2026-10-15 (ADR-073, ADR-074, ADR-075)

### 1. Scope Decisions & Reductions
* **Feature Track BOSS (BOSS-1 through BOSS-4) VOIDED:**
  * The 3 Sovereign Boss encounters (`Corrupted Alpha Wolf`, `Molten Hell-Lion Sovereign`, `Frost-Saber Sovereign`) and their telegraphed AoE ability suites have been completely removed from project scope per developer directive [DEV-CONFIRMED, ADR-074].
  * `BossHUDController.luau` is decoupled from non-humanoid monsters and restricted exclusively to Humanoid World Bosses (`Boss_FallenSwordGenius`) [DEV-CONFIRMED].
* **Finalized 5-Beast Monster Roster (MON & MOB Tracks):**
  * Total monster entity count reduced from 8 to strictly the 5 standard non-humanoid beasts [DEV-CONFIRMED]:
    1. `Iron-Tusk Spirit Boar` (Wilderness Zone — High-speed armored tank)
    2. `Wilderness Spirit Wolf` (Wilderness Zone — Agile pack hunter)
    3. `Magma Hound` (Magma Zone — Flanking predator)
    4. `Obsidian Lava-Boar` (Magma Zone — Heavy lava brute)
    5. `Frost-Fang Wolf` (Ice Zone — Frost pouncer)
* **Monster Skills Streamlined:**
  * Removed all complex AoE shockwave projectiles and ground indicators from beasts; all 5 monsters now strictly execute basic melee attacks (bites, tusks, and paw strikes) with a clean stagger recovery window [DEV-CONFIRMED].

### 2. Locomotion & Spawner Infrastructure (Implemented & Verified)
* **Option B Spawner Architecture:**
  * Master monster templates live in `ReplicatedStorage.Assets.Monsters` [DEV-CONFIRMED].
  * World spawning is driven by dedicated spawner parts placed in `Workspace.MobSpawns.MonsterSpawners` [DEV-CONFIRMED, ADR-073].
  * Multi-spawn enabled: Every placed or duplicated spawner part spawns its own independent beast runtime and maintains its own respawn timer [DEV-CONFIRMED].
* **Spawner Tooling Visibility Policy (ADR-075):**
  * In Studio Edit Mode: All `Spawner_*` pads remain visible (`Transparency = 0.5`, Neon) so developers can easily view and position spawn anchors [DEV-CONFIRMED].
  * At Runtime In-Game: `MonsterAIManager.Init()` automatically sets `Transparency = 1`, `CanCollide = false`, and `CastShadow = false` exclusively on unmodeled `Spawner_*` pads [DEV-CONFIRMED].
* **Terrain Locomotion & Raycast Suspension:**
  * Upright Physics: `AlignOrientation.PrimaryAxisOnly = false` locks Pitch and Roll to 0, ensuring beasts never flip upside down or pitch onto their noses [VERIFIED].
  * Lookahead Suspension: Dual-raycast ground height sensing dynamically lifts paws over terrain lips, grass curbs, and ledges [PROPOSED].
  * Speed Calibration: Distinct strolling (`WalkSpeed = 12–14`, `ActionState = "Walking"`) and aggro charging (`RunSpeed = 35–38`, `ActionState = "Running"`) [VERIFIED].

### 3. Combat & Visual Integration
* **Universal Red Body Hit Indicator:** All damaged entities (players, humanoids, monsters) flash semi-transparent red (`Highlight`, `0.18s`) on damage [VERIFIED].
* **VFX Integration:** Player sword strikes trigger `ReplicatedStorage.VFX.SlashHitAnimation` with snappy 0.25s crimson particle bursts and randomized 360° slice angles [VERIFIED].
* **Stagger & Hitstun:** Damaging a monster halts active attack windups and enforces a 0.65s attack lockout window during which the beast cannot strike [PROPOSED].
* **Grounded Fallen Carcass:** Defeated monsters sink flush to the terrain floor and smoothly fade out over 2.0s before despawning [PROPOSED].