# ASCEND — Asset Integration & System Implementation Plan

## Feature Track Overview
- [ ] **MON: Monster Core** (Humanoid Decoupling & MonsterUtil Architecture)
- [ ] **MOB: The 5 Mobs** (Beast AI Patterns, Posture, and Spawners)
- [ ] **BOSS: Bosses & World Chest** (Boss Ability Framework, 3 Boss Encounters, Loot Chest)
- [ ] **NPC: NPCs & Bounties** (Sect Dispatchers, Zone Bounties, Hub Facility Prompts)
- [ ] **PROP: World Facilities & Fast Travel** (Cauldron, Anvil, Waypoint Pillars)
- [ ] **BLD: Bloodline Orbs** (Sword Bloodline Overhaul, 9 Floating Relics, Combat Passives)

---

## Feature MON: Monster Core (Humanoid Decoupling)

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`MON-0`** | **Decision Gate:** MonsterUtil abstraction strategy (Attribute-first, optional Humanoid fallback). | *None (Design Decision)* |
| [ ] | **`MON-1`** | Fix quest kill-tracking bug: replace hardcoded `"RogueDisciple"` with dynamic `mob.Id`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-2`** | Create `MonsterUtil.luau` standalone utility module. | `src/ReplicatedStorage/Shared/Utils/MonsterUtil.luau` *(New)* |
| [ ] | **`MON-3`** | Route player hit detection, damage application, and parry stun through `MonsterUtil`. | `src/ServerScriptService/Server/Combat/HitboxManager.luau` |
| [ ] | **`MON-4`** | Route spawning, health tracking, death events, and loot drops through `MonsterUtil`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-5`** | Abstract locomotion layer (`MoveTo` and `WalkSpeed` behind a generic driver interface). | `src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MON-6`** | Update client consumers: ALT lock-on reticle, screen boss health bar, overhead billboard bar. | `src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau`<br>`src/StarterPlayer/StarterPlayerScripts/Controllers/BossHUDController.luau`<br>`src/ServerScriptService/Server/Combat/MobAIManager.luau` |

---

## Feature MOB: The 5 Mobs

| Status | Phase ID | Goal | Files Touched |
| :---: | :--- | :--- | :--- |
| [ ] | **`MOB-1`** | Extend `MobConfig.luau` schema (`AIPattern`, model key, optional fields) without breaking 10 existing mobs. | `src/ReplicatedStorage/Shared/Configs/MobConfig.luau` |
| [ ] | **`MOB-2`** | Implement mob posture/poise damage deduction in combat resolution. | `src/ServerScriptService/Server/Combat/HitboxManager.luau`<br>`src/ServerScriptService/Server/Combat/MobAIManager.luau` |
| [ ] | **`MOB-3`** | AI pattern framework: build behavior dispatcher inside `StepAI`. | `src/ServerScriptService/Server/Combat/MobAIManager.luau`<br>`src/ServerScriptService/Server/Combat/MobPatterns/` *(New)* |
| [ ] | **`MOB-4a`** | **Iron-Tusk Spirit Boar:** Config entry, linear charge brute pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4b`** | **Wilderness Spirit Wolf:** Config entry, orbiting pack hunter / pounce pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4c`** | **Magma Hound:** Config entry, fast flanking zig-zag pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4d`** | **Obsidian Lava-Boar:** Config entry, armored charge, poise immunity, and ground hazard pattern. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-4e`** | **Frost-Fang Wolf:** Config entry, frost pounce pattern, and spawner alias. | `MobConfig.luau`<br>`MobAIManager.luau` |
| [ ] | **`MOB-5`** | Implement Frost-Fang Wolf combat debuffs (stamina drain and posture recovery delay on players). | `src/ServerScriptService/Server/State/CombatStateManager.luau` |

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
| [ ] | **`BLD-0`** | **Decision Gate:** Replace legacy 7-tier gacha with 5-tier sword bloodlines vs mapping existing saves. | *None (Design Decision)* |
| [ ] | **`BLD-1`** | Config schema update and 3D visual attachment (offset `CFrame.new(-1.5, 2.2, 0.2)` on torso). | `src/ReplicatedStorage/Shared/Configs/BloodlineConfig.luau`<br>`src/ServerScriptService/Server/State/BloodlineManager.luau` |
| [ ] | **`BLD-2`** | Passive stat wiring (posture recovery rate, dash leap distance, maximum posture gauge). | `src/ServerScriptService/Server/State/CombatStateManager.luau`<br>`src/ServerScriptService/Server/State/PlayerDataManager.luau` |
| [ ] | **`BLD-3`** | Combat resolution passives (critical damage, bonus damage vs guard-broken, i-frame extensions, void echoes). | `src/ServerScriptService/Server/Combat/HitboxManager.luau` |