# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md  
> **Scope:** Directory Hierarchy, Service-Controller Framework, Network Pipeline, DataStore Schemas, & Lifecycle Hooks.

---

## 1. Roblox Studio Project Directory Structure

ASCEND-V1 uses a modular, single-script entry point architecture for both server and client execution contexts:

[ServerScriptService]
└── Server
    ├── Bootstrap.server.luau               (Server initialization entry point)
    └── Services                            (Server-authoritative game logic)
        ├── DataService.luau                (DataStore & profile persistence)
        ├── CombatService.luau              (Hitbox execution, damage, cooldowns)
        ├── StateService.luau               (Combat state transitions: Stun, iFrame)
        ├── InventoryService.luau           (Equipment, drops, item management)
        ├── StatService.luau                (Character leveling, stat allocation)
        └── MobService.luau                 (Enemy AI spawning, aggro, loot drops)

[ReplicatedStorage]
└── Shared
    ├── Network                             (Client-Server communication)
    │   └── NetworkManager.luau             (Wrapped RemoteEvent/Function handler)
    ├── Configs                             (Data definitions & game balance)
    │   ├── WeaponData.luau                 (Damage, windup, cooldown configs)
    │   ├── DropTables.luau                 (Weighted loot tables)
    │   └── StatConfigs.luau                (Scaling formulas & level curves)
    └── Util                                (Shared helper libraries)
        ├── Signal.luau                     (Custom Lua event signal engine)
        ├── Janitor.luau                    (Object cleanup & memory management)
        └── TypeDefinitions.luau            (Luau strict type definitions)

[StarterPlayer.StarterPlayerScripts]
└── Client
    ├── Bootstrap.client.luau               (Client initialization entry point)
    └── Controllers                         (Client rendering & input handling)
        ├── CombatController.luau           (User input captures: M1, M2, Dodge)
        ├── HUDController.luau              (Bar animations, cooldown overlays)
        ├── MenuController.luau             (Fantasy modal toggles & inventory GUI)
        └── FCTController.luau              (Floating combat text visual spawner)

---

## 2. Service-Controller Lifecycle Architecture

Services and Controllers follow a predictable two-phase initialization sequence managed by their respective Bootstrap scripts:

1. Phase 1: OnInit()
   - Instantiates internal variables, DataStores, and local signals.
   - Modules MUST NOT call functions from other Services/Controllers during OnInit().

2. Phase 2: OnStart()
   - Executes after all modules have completed OnInit().
   - Connects RemoteEvents, begins background loops, and cross-references external Services.

---

## 3. Network Communication Layer (Remote Event Mapping)

Communication uses a unified NetworkManager wrapper around RemoteEvents to prevent memory leaks and sanitize payloads:

| Remote Name | Direction | Payload Parameters | Description |
| :--- | :--- | :--- | :--- |
| AttackIntent | Client -> Server | (AttackType: string, Timestamp: number) | Client requests an M1/M2 attack swing |
| DodgeIntent | Client -> Server | (DirectionVector: Vector3) | Client requests a dodge / roll action |
| AllocateStat | Client -> Server | (StatName: string, Amount: number) | Client requests spending stat points |
| EquipItem | Client -> Server | (ItemUUID: string) | Client requests equipping inventory item |
| SyncData | Server -> Client | (PlayerData: table) | Server replicates full profile updates |
| ReplicateHit | Server -> Client | (TargetChar: Instance, Damage: number, IsCrit: boolean) | Server commands client to render hit VFX/FCT |
| UpdateState | Server -> Client | (NewState: string) | Server updates client state (e.g. Stunned) |

### Network Security Guarantee
* All client-to-server remotes pass through strict type checking (TypeDefinitions.luau).
* Payloads containing position, damage values, or currency amounts sent from the client are discarded immediately.

---

## 4. DataStore Schema (ProfileService)

Player data is persisted using ProfileService to ensure atomic writes, session locking, and data loss prevention.

Default Player Profile Table Structure:

ProfileData = {
    ProfileVersion = 1,
    Data = {
        Level = 1,
        Experience = 0,
        Gold = 0,
        AscensionShards = 0,
        
        Stats = {
            AllocatedSTR = 0,
            AllocatedDEX = 0,
            AllocatedINT = 0,
            AllocatedVIT = 0,
            AllocatedEND = 0,
            UnallocatedPoints = 0
        },

        Equipped = {
            WeaponUUID = nil,
            ArmorUUID = nil,
            AccessoryUUID = nil
        },

        Inventory = {
            -- Array of Item Objects
            -- Example: { UUID = "8f3d-...", ItemId = "Katana_Iron", Rarity = "Uncommon", EnhancementLevel = 0 }
        },

        Mastery = {
            Blade = 0,      -- Mastery XP
            Greatsword = 0,
            Daggers = 0,
            Staff = 0
        }
    }
}

---

## 5. Performance, Memory & Garbage Collection Rules

1. Event Disconnection: All transient event listeners (e.g. Touch triggers, temporary animation tracks) must be managed using Janitor.luau to prevent memory leaks.
2. Spatial Query Optimization: Server Shapecast operations use a shared pre-allocated RaycastParams instance with a static CollisionGroup.
3. ReplicatedStorage Rules: Clients are never permitted to read/write directly to ServerStorage. Only shared configs and utility modules reside in ReplicatedStorage.