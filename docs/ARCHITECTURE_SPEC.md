# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md
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

# Architecture Specification — ASCEND

Master system architecture, project directory tree, file responsibilities, and system wiring map for ASCEND.

---

## 📁 Complete Project Directory Tree

```text
ASCEND/
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Configs/
│   │   │   ├── UIAssets.luau             -- Central Asset Registry (Image/Decal IDs for HUD, Panels, Skills)
│   │   │   ├── RarityConfig.luau         -- Rarity tiers (Mortal to Immortal), rankings & Hex colors
│   │   │   ├── AnimationConfig.luau      -- R15 Animation IDs, speeds, cast durations, WalkSpeed dampening
│   │   │   ├── CultivationConfig.luau    -- 5 Realms, Qi capacity, gather rates, health multipliers, aura colors
│   │   │   └── Weapons/
│   │   │       ├── FlyingSwordConfig.luau-- Flying Sword M1 combo steps, skill damage, ranges, knockbacks
│   │   │       ├── SpearConfig.luau      -- Spear thrust combo steps, lunge physics, skill stats
│   │   │       └── GauntletConfig.luau   -- Gauntlet punch combo steps, 360° palms, ground slam stats
│   │   └── Network/
│   │       └── RemoteEvents.luau         -- RemoteEvent Factory (CombatAction, SyncCooldown, UpdateSkillState, UpdateCultivation)
│   └── Weapons/                          -- Folder for custom 3D MeshPart / Model weapon assets
│
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau        -- Server entry point script initializing all server managers
│       ├── State/
│       │   └── CombatStateManager.luau   -- Server combat state tracker, cooldown validator, & network broadcaster
│       ├── Cultivation/
│       │   └── CultivationManager.luau   -- Qi meditation (G), breakthroughs (B), health scaling, body wrap
│       └── Combat/
│           ├── HitboxManager.luau        -- Spatial box query engine (GetPartBoundsInBox) & knockback physics
│           ├── WeaponManager.luau        -- Equipped weapon tracker, Motor6D attachments, Qi placeholders
│           └── Weapons/
│               ├── FlyingSwordServer.luau-- Flying Sword server attack/combo handler
│               ├── SpearServer.luau      -- Spear server attack/combo handler
│               └── GauntletServer.luau   -- Gauntlet server attack/combo handler
│
├── StarterGui/
│   ├── HUDGui/                            -- ScreenGui for HUD (ActionSkillBar, BossHealthBar, Reticle, TribulationBar)
│   └── InventoryGui/                      -- ScreenGui for Modal Inventory window
│
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          -- Client entry point script initializing all client controllers
        └── Controllers/
            ├── HUDController.luau         -- Skill slot rendering, sweeping cooldown masks with live decimal timers
            ├── InventoryController.luau   -- Inventory grid population & UIStroke rarity borders
            ├── InputController.luau       -- Keybind inputs (LMB, F, Q, E, R, Shift, 1, 2, 3, G, B), mouse hit vector payloads
            ├── CombatVFXController.luau   -- 3D damage numbers, camera shake, white slash trails, swing & hit SFX
            └── AnimationController.luau   -- R15 keyframe attack animations, action priority, speed dampening, meditation camera

🔗 System Wiring & Execution Map
1. Client Initialization (ClientMain.client.luau)
HUDController.Init(): Builds the skill bar, binds SyncCooldown to start mask sweeps and live timer text, and binds UpdateSkillState to dynamically update skill icons when swapping weapons. Disables Roblox's default Backpack CoreGui.
InventoryController.Init(): Sets up tab/hotkey opening for the inventory modal and handles UIStroke rarity borders.
InputController.Init(): Listens for player inputs:
1, 2, 3: Sends { RequestWeaponSwap = "FlyingSword" | "Spear" | "Gauntlet" } to server.
G, B: Sends { ToggleMeditation = true } or { RequestBreakthrough = true } to server.
LMB, F, Q, E, R, Shift: Captures mouse.Hit.Position & AimDirection and fires CombatAction payload to server.
CombatVFXController.Init(): Listens to CombatAction broadcasts from server:
Spawns 3D floating damage numbers over hit targets (payload.Damage).
Plays impact particle burst at payload.TargetPosition.
Plays swing SFX (1222216), hit SFX (5633903110), and camera shake.
Enables white 3D WeaponTrail on equipped weapon for 0.25s.
AnimationController.Init():
Listens to CombatAction to play keyframe attack tracks on character's Animator (Priority = Action, Looped = false).
Handles Shift physical dodge dash (AssemblyLinearVelocity impulse).
Listens to UpdateCultivation to play floating meditation pose (rbxassetid://116333173300889), locks movement keys, and sets front-facing steady cinematic camera view.
2. Server Initialization (ServerMain.server.luau)
CombatStateManager.Init():
Listens to CombatAction RemoteEvent.
Checks player health, verifies state is not Stunned or QiDeviation, and checks SKILL_COOLDOWNS.
If valid, records cooldown timestamp, fires SyncCooldown back to client, delegates attack execution to WeaponManager / FlyingSwordServer / SpearServer / GauntletServer, and broadcasts CombatAction payload to all clients for VFX/SFX.
WeaponManager.Init():
Tracks player equipped weapon type (FlyingSword, Spear, Gauntlet).
Processes weapon swap requests from clients (1, 2, 3).
AttachWeaponModel(): Attaches custom MeshPart/Model/Tool or procedural Qi energy placeholders to RightHand.RightGripAttachment via Motor6D (WeaponGrip).
Fires UpdateSkillState to update client HUD skill slot icons.
CultivationManager.Init():
Tracks player cultivation realm (Qi Condensation → Foundation Establishment → Golden Core → Nascent Soul → Heavenly Tribulation).
Handles ToggleMeditation (G): Anchors player 2.2 studs in the air, wraps body in lightweight ethereal Highlight aura, and runs Qi absorption loop.
Handles RequestBreakthrough (B): Validates max Qi, advances realm, and scales player Humanoid.MaxHealth (e.g. 1.5x at Foundation Establishment).
Fires UpdateCultivation remote event to sync client.


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