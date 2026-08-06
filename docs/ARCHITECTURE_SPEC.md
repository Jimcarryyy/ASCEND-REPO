---

# 7. `docs/ARCHITECTURE_SPEC.md`

```markdown
# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Directory Hierarchy, Pure Sword Cultivator Service-Controller Framework, Network Pipeline, DataStore Schemas, & Lifecycle Hooks.

---

## Purpose
This document defines the ASCEND code architecture, data flow, network remote mapping, and service/controller separation.

## Document Connectivity
- Use this doc for code structure and system architecture decisions.
- Pair with `docs/CODE_DEPENDENCY_GUIDE.md` when tracing actual script relationships.
- Pair with `.ai` tracking docs to link architecture with current active tasks and project status.

---

## 1. Roblox Studio Project Directory Structure

ASCEND-V1 uses a modular, single-script entry point architecture for both server and client execution contexts, tailored for the **Pure Sword Cultivator Paradigm**:

```text
src/
├── ReplicatedFirst/
├── ReplicatedStorage/
│   └── Shared/
│       ├── Configs/
│       │   ├── AlchemyConfig.luau          (Recipe definitions, ingredients, spirit pill consumable effects)
│       │   ├── AnimationConfig.luau        (R15 Sword Animation IDs, speeds, cast durations, WalkSpeed dampening)
│       │   ├── CultivationConfig.luau      (45 Tiers, 50B Qi capacity, gather rates, health scaling, aura colors)
│       │   ├── InventoryConfig.luau        (Item metadata schema, 3D ViewportFrame placeholders)
│       │   ├── ItemConfig.luau             (Master item registry, Sword Art Scrolls, Mythic Sword Skins)
│       │   ├── RarityConfig.luau           (Rarity tiers Common to Mythic, Rankings & Hex colors)
│       │   ├── UIAssets.luau               (Central Asset Registry for image/decal IDs)
│       │   └── Weapons/
│       │       └── FlyingSwordConfig.luau  (Flying Sword M1 combo steps, skill damage, ranges, knockbacks)
│       └── Network/
│           └── RemoteEvents.luau           (RemoteEvent factory pre-creating all network remotes)
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau          (Server initialization entry point)
│       ├── Combat/
│       │   ├── HitboxManager.luau          (Spatial box query engine GetPartBoundsInBox & knockback physics)
│       │   ├── WeaponManager.luau          (Equipped 3D sword model tracker, Motor6D hand/back attachments, Floating Back-Sword Array)
│       │   └── Weapons/
│       │       └── FlyingSwordServer.luau  (Master Flying Sword server attack/combo handler)
│       ├── Cultivation/
│       │   ├── AlchemyManager.luau         (Furnace crafting validation, ingredient inventories, pill consumption)
│       │   ├── CultivationManager.luau     (Qi meditation G, breakthroughs B, health scaling, body wrap)
│       │   └── QiZoneManager.luau          (Spatial region tracker for Spirit Vein meditation multipliers)
│       └── State/
│           ├── CombatStateManager.luau     (Server combat state tracker, cooldown validator, & network broadcaster)
│           ├── InventoryManager.luau       (30-slot server inventory engine, pill consumption, equips)
│           └── PlayerDataManager.luau      (DataStoreService persistence engine, 5-min auto-save, BindToClose)
├── ServerStorage/
├── StarterGui/
│   └── HUDGui/                             (ScreenGui for HUD: MainHUDPanel, ActionSkillBar, BossHealthBar)
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          (Client initialization entry point)
        ├── Client/
        │   └── UI/
        │       └── OverheadUIController.luau(Dynamic overhead BillboardGui HP bars, name tags, cultivation titles)
        └── Controllers/
            ├── AlchemyController.luau      (Dark Obsidian furnace crafting workspace & outcome card)
            ├── AnimationController.luau    (R15 keyframe attack animations, priority layering, native sit pose)
            ├── CombatVFXController.luau    (3D damage numbers, camera shake, slash trails, Shift Dash trail, SFX)
            ├── CultivationController.luau  (Meditation calm floating motion and wide camera offset framing)
            ├── HUDController.luau           (Dark Obsidian HUD panel, sharp 90° corners, white realm text, hotbar)
            ├── InputController.luau         (Keybind inputs LMB, F, Q, E, R, Shift, G, B, I, C, mouse hit vector payloads)
            └── InventoryController.luau     (Spirit Pouch 3D character doll, fitted grid, search/sort filters)

2. Network Communication Layer (Remote Event Mapping)
Communication uses a unified RemoteEvents.luau wrapper around RemoteEvents pre-created on server startup.
Remote Name	Direction	Payload Parameters	Description
CombatAction	Client → Server	(skillKey: string, payload: table)	Client requests light attack, block/parry, or Sword Art execution
CombatAction	Server → Client	(attacker: Player, skillKey: string, payload: table)	Broadcast combat action to all clients for rendering VFX/SFX
UpdateSkillState	Server → Client	(weaponType: string, skillData: table)	Dynamic HUD skill icon swap and cooldown sync
SyncCooldown	Server → Client	(skillKey: string, cooldownDuration: number)	Command client HUD to trigger dark sweeping cooldown mask
UpdateCultivation	Client → Server	{ ToggleMeditation: boolean } or { RequestBreakthrough: boolean }	Request meditation toggle or realm breakthrough
UpdateCultivation	Server → Client	{ RealmName: string, Order: number, CurrentQi: number, MaxQi: number, IsMeditating: boolean }	Broadcast cultivation status updates
AlchemyAction	Client → Server	(actionType: "CraftPill" | "ConsumePill", recipeId: string)	Client requests alchemy crafting or pill consumption
AlchemyAction	Server → Client	(responseType: string, data: table)	Server syncs craft/consume result and inventory update
InventoryAction	Server → Client	(actionType: "SyncInventory", inventoryData: table)	Server replicates updated player inventory table
3. DataStore Schema (PlayerDataManager.luau)
Player data is persisted using DataStoreService with pcall retry wrappers, 5-minute auto-saves, and BindToClose server shutdown handlers.
code
Luau
export type SavedPlayerData = {
	Version: number,
	Cultivation: {
		Realm: string,      -- e.g. "GoldenCore"
		Order: number,      -- 1 through 9
		CurrentQi: number,  -- e.g. 19010000
	},
	EquippedWeaponSkin: string, -- e.g. "HeavenlyVoidBlade"
	EquippedSkills: {
		Q: string,          -- e.g. "VoidSlashScroll"
		E: string,          -- e.g. "FlameCleaveScroll"
		R: string,          -- e.g. "DragonRoarScroll"
		F: string,          -- e.g. "ParryQiShield"
		Shift: string,      -- e.g. "WindstepDash"
	},
	SwordMastery: {
		[string]: number,   -- e.g. VoidSlash = Rank 5
	},
	Inventory: {
		[number]: {
			ItemId: string,
			Count: number,
		}
	},
	Sect: string?,         -- e.g. "Azure Cloud Sect"
}