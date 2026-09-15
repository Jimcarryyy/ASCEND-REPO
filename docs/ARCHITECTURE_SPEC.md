# ASCEND — Authoritative Technical Architecture Specification

> **System Architecture & Technical Topology Document**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 8.5 — Combat Engine Standardization & Defensive VFX Integration

---

## 1. System Topology & Architectural Philosophy

ASCEND utilizes a strict client-server separation model designed for deterministic execution, high responsiveness, and complete protection against client-side exploitation.

```text
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                                   CLIENT TOPOLOGY                                       │
│                                                                                         │
│  StarterPlayerScripts/ClientMain.client.luau (Client Lifecycle Coordinator)             │
│  ├── InputController ──> Buffers inputs, predicts local animations & dashes             │
│  ├── HUDController & Controllers (24 total) ──> Manages Studio-authoritative GUIs       │
│  ├── CombatVFXController ──> Handles visual fx, sounds, camera shake, hitstop           │
│  └── ModalWindowManager ──> Enforces mutually exclusive modal dialogues (ADR-043)        │
└─────────────────────────────────────────┬───────────────────────────────────────────────┘
                                          │  Network Boundary
                                          │  (22 RemoteEvents in ReplicatedStorage)
┌─────────────────────────────────────────┴───────────────────────────────────────────────┐
│                                   SERVER TOPOLOGY                                       │
│                                                                                         │
│  ServerScriptService/ServerMain.server.luau (Server Lifecycle Coordinator)              │
│  ├── PlayerDataManager ──> Manages ASCEND_PlayerData_V3 persistence                     │
│  ├── CombatStateManager ──> Posture, Guard, Parry, and Stagger states                   │
│  ├── FlyingSwordServer & WeaponManager ──> Authoritative combo/skill validation         │
│  ├── HitboxManager ──> Compensated spatial spatial queries & damage application         │
│  ├── CultivationManager ──> Qi generation, breakthroughs, and Tribulation lightning     │
│  └── World Managers (Gathering, Blacksmith, Alchemy, TeaHouse, MobAI, Arena, etc.)      │
└─────────────────────────────────────────────────────────────────────────────────────────┘
Foundational Principles
Server Authority Over Stats & Combat: The client is purely an input sensor and visual rendering engine. All cooldown verification, Qi resource checks, hitbox spatial sweeps, damage math, and posture breaks are executed and validated strictly on the server.
Single-Weapon Architecture (ADR-038): The combat pipeline is built specifically around Flying Swords, eliminating multi-weapon branch bloat while delivering deep mechanical nuance through dynamic weapon palettes and intent mechanics.
Studio-Authoritative UI (ADR-041): All user interfaces exist natively as Studio instances within StarterGui. Luau controllers never construct UI hierarchies via Instance.new; they only query, bind listeners, and tween properties.
Modal Window Exclusivity (ADR-043): Every fullscreen/dialogue interface registers with ModalWindowManager.luau to prevent UI overlaps, lock movement, and cleanly release mouse control.
2. Server Infrastructure (src/ServerScriptService/Server/)
Initialized sequentially by ServerMain.server.luau:
Combat Subsystem
Manager	Path	Architectural Responsibilities
FlyingSwordServer	Combat/Weapons/FlyingSwordServer.luau	Executes M1 combo sequence, Q Tempest, E Thrust, and F 100-Slash Domain. Calculates raw damage and consumes Sword Intent.
HitboxManager	Combat/HitboxManager.luau	Latency-compensated spatial queries using WorldRoot:GetPartBoundsInBox. Handles friendly-fire rules and Mob/Player target normalization.
WeaponManager	Combat/WeaponManager.luau	Manages weapon equipping, sheathing (R), welding between RightGripAttachment and BackSwordMount, and sheath states.
MobAIManager	Combat/MobAIManager.luau	R6 mob state machines (Patrol, Alert, Chase, Flocking/Boids, Attack combos, Reset). Spawns and manages world enemies.
ArenaManager	Combat/ArenaManager.luau	Manages 1v1 and Free-for-All arena instances, round states, normalized competitive damage scaling, and match boundaries.
Cultivation Subsystem
Manager	Path	Architectural Responsibilities
CultivationManager	Cultivation/CultivationManager.luau	Validates seated meditation (C), applies environmental Qi multipliers, schedules Tribulation strikes, and executes major/minor breakthroughs.
AlchemyManager	Cultivation/AlchemyManager.luau	Validates herb inputs at Master Shen's Cauldron, runs mini-game logic, and crafts cultivation pills.
SectManager	Cultivation/SectManager.luau	Handles sect ranks, disciple duty boards, daily bounties, and Sect Contribution currency.
State & Persistence Subsystem
Manager	Path	Architectural Responsibilities
PlayerDataManager	State/PlayerDataManager.luau	Manages ASCEND_PlayerData_V3 DataStore. Handles schema migration from V2, 300s auto-saves, and shutdown flushes via BindToClose.
CombatStateManager	State/CombatStateManager.luau	Tracks guard states, parry windows (
0.22
s
0.22s
), posture points (
100
 base
100 base
), posture regen, and guard break staggers (
1.8
s
1.8s
).
InventoryManager	State/InventoryManager.luau	Server inventory management, consumable usage, and equipment ownership records.
MarketplaceManager	State/MarketplaceManager.luau	Manages currency transactions, vendor exchanges, and developer product/gamepass processing.
World & Environment Subsystem
Manager	Path	Architectural Responsibilities
BlacksmithManager	World/BlacksmithManager.luau	Handles Madame Tie's Forge. Processes weapon refinement (
+
1
→
+
10
+1→+10
) and consumes ores.
TeaHouseManager	World/TeaHouseManager.luau	Manages Xiao Ling's Spirit Tea Pavilion. Validates tea purchases and applies timed Qi/damage buff timers.
GatheringManager	World/GatheringManager.luau	Manages world resource nodes (Ghost Grass, Golden Ginseng, Mortal Iron Ore, etc.) and harvesting timers.
EnvironmentTimeManager	World/EnvironmentTimeManager.luau	Drives atmospheric day/night cycles and dims skies during Tribulation events.
TreeCollisionManager	World/TreeCollisionManager.luau	Optimizes world geometry collision physics, disabling complex mesh hulls for high performance.
VendorManager	World/VendorManager.luau	Manages generic world ProximityPrompts and dialogue interactions for utility NPCs.
3. Client Infrastructure (src/StarterPlayer/StarterPlayerScripts/)
Bootstrapped by ClientMain.client.luau following completion of LoadingScreen.client.luau:
Client Controllers
Controller	Primary Function
InputController	Binds user inputs (M1, Shift, Ctrl, T, C, R, V, B, Q, E, F, P, Tab).
AnimationController	Preloads, caches, and plays sword combo, dash, meditation, and skill animation tracks.
CombatVFXController	Spawns damage numbers, slash ribbons, camera shake, hitstop, parry clash sparks, and aura effects.
HUDController	Drives MasterHUD: dynamic Health bar, Qi gauge, Posture meter, and bottom-left 340px column stack.
ModalWindowManager	Central stack controller managing mutually exclusive full-screen UI views (ADR-043).
CharacterStatsController	Controls the CharacterStatsGui (P key) displaying Realm, Order, Attributes, and Stats.
CultivationController	Handles local meditation visual states, breakthrough prompts (B), and tribulation telegraph circles.
SkillBarController	Renders skill slot icons, cooldown sweeps, key labels, and activation flashes.
ArenaController	Manages arena matchmaking prompts, countdown overlays, and match result screens.
FocusTargetController	Provides soft-lock targeting indicators and camera aim-assist on nearby hostiles.
OverheadUIController	Renders R6 billboard names, realm titles, sect affiliations, and mob health bars.
InventoryController	Manages the grid inventory UI, item tooltips, and weapon equipping.
BlacksmithController	Drives the weapon refinement UI at Madame Tie's Forge.
AlchemyController	Drives the herb selection and cauldron minigame UI at Master Shen's station.
TeaHouseController	Drives the Spirit Tea selection UI and active tea buff icons.
MarketController	Manages vendor shop interfaces and item purchasing.
QuestTrackerController	Displays active Sect Notice Board bounties and duty completion toasts.
SectController	Displays sect rankings, elder dialogues, and contribution redemption menus.
StarterGuideController	Drives Elder Qing's 4-tab interactive codex interface.
SparringGuidanceController	Displays training dummy DPS meters and combo tutorials at the Sect Training Grounds.
WeaponCodexController	Displays 3D previews and lore descriptions for unlocked Flying Swords.
GatheringController	Displays harvesting progress bars and interaction prompts on world resource nodes.
MusicController	Manages dynamic background music transitions between Sect, Wilds, and Combat states.
WindEnvironmentController	Drives ambient wind trails, cherry blossom petal drifts, and atmospheric particles.
4. Centralized Network Architecture (RemoteEvents.luau)
All 22 RemoteEvent instances are instantiated once by RemoteEvents.luau inside ReplicatedStorage.Shared.Network:
code
Lua
-- Authoritative RemoteEvent Directory
local RemoteEvents = {
    -- Combat & Movement Pipeline
    CombatActionRemote     = Instance.new("RemoteEvent"),
    CombatVFXRemote        = Instance.new("RemoteEvent"),
    SwordFlightRemote      = Instance.new("RemoteEvent"),
    BossEncounterRemote    = Instance.new("RemoteEvent"),

    -- Cultivation & Progression Pipeline
    CultivationActionRemote = Instance.new("RemoteEvent"),
    CultivationStateRemote  = Instance.new("RemoteEvent"),
    BreakthroughRemote      = Instance.new("RemoteEvent"),
    TribulationRemote       = Instance.new("RemoteEvent"),
    CharacterStatsRemote    = Instance.new("RemoteEvent"),

    -- Inventory & Economy Pipeline
    InventoryActionRemote   = Instance.new("RemoteEvent"),
    InventoryUpdateRemote   = Instance.new("RemoteEvent"),
    MarketplaceActionRemote = Instance.new("RemoteEvent"),

    -- Sect & Questing Pipeline
    SectActionRemote        = Instance.new("RemoteEvent"),
    SectUpdateRemote        = Instance.new("RemoteEvent"),
    NoticeBoardRemote       = Instance.new("RemoteEvent"),

    -- Professions & Gathering Pipeline
    GatheringActionRemote   = Instance.new("RemoteEvent"),
    AlchemyActionRemote     = Instance.new("RemoteEvent"),
    BlacksmithActionRemote  = Instance.new("RemoteEvent"),
    TeaHouseActionRemote    = Instance.new("RemoteEvent"),

    -- Arena & Environment Pipeline
    ArenaActionRemote       = Instance.new("RemoteEvent"),
    ArenaStateRemote        = Instance.new("RemoteEvent"),
    EnvironmentSyncRemote   = Instance.new("RemoteEvent"),
}
Remote Invocation Matrix
code
Text
[Client] ──CombatActionRemote:FireServer({Action="Attack", SkillKey="M1", AimCFrame=...})──> [Server]
                                                                                                 │
                                                                         Validate State, Cooldown, Hitbox
                                                                                                 │
[Client] <──CombatActionRemote:FireAllClients(attacker, "Attack", {SkillKey="M1"})───────────────┤
                                                                                                 │
                                                                                      If Target Hit:
[Client] <──CombatVFXRemote:FireAllClients({EffectType="DamageNumber", Damage=125, ...})─────────┘
5. Boot Sequence & Initialization Order
Server Initialization Sequence (ServerMain.server.luau)
Shared Singletons: Initialize RemoteEvents.luau and verify all 22 remotes are parented under ReplicatedStorage.
State & DataStores: Initialize PlayerDataManager.luau (ASCEND_PlayerData_V3). Connect player join (PlayerAdded), player leave (PlayerRemoving), and game shutdown (BindToClose).
Core State Managers: Initialize CombatStateManager and InventoryManager.
Combat Engines: Initialize HitboxManager, WeaponManager, FlyingSwordServer, and MobAIManager.
Cultivation & World Services: Initialize CultivationManager, SectManager, GatheringManager, BlacksmithManager, AlchemyManager, TeaHouseManager, ArenaManager, and EnvironmentTimeManager.
Client Initialization Sequence (ClientMain.client.luau)
ReplicatedFirst Screen: LoadingScreen.client.luau displays loading bar while critical assets, UI fonts, and animations preload via ContentProvider:PreloadAsync.
Core System Services: ModalWindowManager and InputController initialize and lock input routing.
Audio & VFX Engines: MusicController and CombatVFXController initialize.
HUD & ScreenGuis: HUDController scans StarterGui.MasterHUDGui, establishes value observers, and binds the bottom-left 340px column stack.
Interactive Controllers: Domain controllers (CultivationController, InventoryController, CharacterStatsController, etc.) connect to their respective remotes and Studio UI components.