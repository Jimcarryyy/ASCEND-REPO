# 2. `docs/ARCHITECTURE_SPEC.md`

```markdown
# ASCEND — Master Architecture Specification

## 1. Core Engineering Principles

### 1.1 Client-Server Authoritative Boundary
- **Server Authority:** All combat damage verification, posture deduction, inventory mutations, cultivation breakthroughs, pill brewing outcomes, weapon refinements, and data persistence are strictly server-authoritative. The client functions purely as a prediction, input, audio, and display layer.
- **Client Prediction:** M1 combo swings and dash animations trigger immediate local visual feedback. Hit registration, damage application, and CC states are validated and broadcast exclusively by the server via `CombatAction` and `CombatVFX`.

### 1.2 Studio-Authoritative UI Standard (Strict Rule — ADR-041)
**Runtime programmatic UI generation via `Instance.new` inside client controllers is strictly prohibited.**
All GUI layouts, frames, buttons, text labels, and UIStrokes must reside natively within `StarterGui`. Client controllers are strictly restricted to:
1. Acquiring references to existing UI instances in `PlayerGui`.
2. Binding user interactions (`Activated`, `MouseButton1Click`, `MouseEnter`).
3. Updating dynamic labels, health/Qi fill bars, and item card templates.
4. Executing UI tweens (fades, slides, pulses).
5. Toggling container visibility (`Enabled = true / false`).

### 1.3 Strict DisplayOrder Layering Hierarchy (ADR-043)
To eliminate overlapping modals and render priority conflicts, every ScreenGui in `StarterGui` must have an assigned `DisplayOrder`:

| DisplayOrder | ScreenGui Name | Functional Purpose |
| :---: | :--- | :--- |
| **1** | `MasterHUDGui` | Persistent desktop & mobile HUD (Vitals, Skill Bar, Intent, Currencies). |
| **2** | `LowViewPortSkillsGUI` | Compact mobile viewport skill cluster fallback. |
| **5** | `OverheadUI` | BillboardGuis for player nameplates, mob health bars, and dummy DPS text. |
| **10** | `BlacksmithGui` | Weapon refinement (+10) and blade sharpening forge interface. |
| **10** | `TeaHouseGui` | Spirit tea ordering and timed buff catalog interface. |
| **10** | `SparringGuidanceGui` | Training dummy DPS tracking and sparring trial interface. |
| **10** | `StarterGuideGui` | 4-tab interactive player onboarding guide modal. |
| **10** | `SpiritPouchInventoryGui` | 60-slot storage, 2D weapon showcase, and item inspection modal. |
| **10** | `SectPavilionGui` | Sect daily duties, disciple rank promotions, and daily stipend modal. |
| **10** | `AlchemyCauldronGui` | 3-slot herb combination and temperature needle minigame modal. |
| **12** | `ArenaGUI` | 1v1 matchmaking banners, countdown timers, and match resolution. |
| **20** | `GlobalToastNotifGui` | Center-top floating harvest and action status banners. |
| **100** | `LoadingScreen` | ReplicatedFirst preloader canvas and initialization gate. |

### 1.4 Centralized Network Architecture
All client-server network traffic routes through the 22 centralized `RemoteEvent` instances instantiated and managed by `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`. Ad-hoc remote creation is strictly prohibited.

---

## 2. Complete Repository File Structure

```text
ASCEND/
├── src/
│   ├── ReplicatedFirst/
│   │   └── LoadingScreen.client.luau
│   ├── ReplicatedStorage/
│   │   └── Shared/
│   │       ├── Configs/
│   │       │   ├── AlchemyConfig.luau
│   │       │   ├── AnimationConfig.luau
│   │       │   ├── CultivationConfig.luau
│   │       │   ├── GatheringConfig.luau
│   │       │   ├── HUDSkinConfig.luau
│   │       │   ├── InventoryConfig.luau
│   │       │   ├── ItemConfig.luau
│   │       │   ├── MobConfig.luau
│   │       │   ├── MonetizationConfig.luau
│   │       │   ├── RarityConfig.luau
│   │       │   ├── SectConfig.luau
│   │       │   ├── UIAssets.luau
│   │       │   └── Weapons/
│   │       │       └── FlyingSwordConfig.luau
│   │       └── Network/
│   │           └── RemoteEvents.luau
│   ├── ServerScriptService/
│   │   └── Server/
│   │       ├── ServerMain.server.luau
│   │       ├── Combat/
│   │       │   ├── ArenaManager.luau
│   │       │   ├── HitboxManager.luau
│   │       │   ├── MobAIManager.luau
│   │       │   ├── WeaponManager.luau
│   │       │   └── Weapons/
│   │       │       └── FlyingSwordServer.luau
│   │       ├── Cultivation/
│   │       │   ├── AlchemyManager.luau
│   │       │   ├── CultivationManager.luau
│   │       │   └── SectManager.luau
│   │       ├── State/
│   │       │   ├── CombatStateManager.luau
│   │       │   ├── InventoryManager.luau
│   │       │   ├── MarketplaceManager.luau
│   │       │   └── PlayerDataManager.luau
│   │       └── World/
│   │           ├── BlacksmithManager.luau
│   │           ├── EnvironmentTimeManager.luau
│   │           ├── GatheringManager.luau
│   │           ├── TeaHouseManager.luau
│   │           ├── TreeCollisionManager.luau
│   │           └── VendorManager.luau
│   ├── StarterPlayer/
│   │   ├── StarterCharacterScripts/
│   │   │   └── Animate.client.luau
│   │   └── StarterPlayerScripts/
│   │       ├── ClientMain.client.luau
│   │       ├── DeWidth.client.luau
│   │       └── Controllers/
│   │           ├── AlchemyController.luau
│   │           ├── AnimationController.luau
│   │           ├── ArenaController.luau
│   │           ├── BlacksmithController.luau
│   │           ├── CombatVFXController.luau
│   │           ├── CultivationController.luau
│   │           ├── FocusTargetController.luau
│   │           ├── GatheringController.luau
│   │           ├── HUDController.luau
│   │           ├── InputController.luau
│   │           ├── InventoryController.luau
│   │           ├── MarketController.luau
│   │           ├── OverheadUIController.luau
│   │           ├── QuestTrackerController.luau
│   │           ├── SectController.luau
│   │           ├── SkillBarController.luau
│   │           ├── SparringGuidanceController.luau
│   │           ├── StarterGuideController.luau
│   │           ├── TeaHouseController.luau
│   │           └── WindEnvironmentController.luau
│   └── Workspace/
│       └── Functional_Stations/
│           └── Sect_TrainingGround/
│               ├── TrainingDummy_1/
│               │   └── ImmortalDummyHandler.server.luau
│               ├── TrainingDummy_2/
│               │   └── ImmortalDummyHandler.server.luau
│               └── TrainingDummy_3/
│                   └── ImmortalDummyHandler.server.luau
3. Server-Side Execution Model
3.1 Server Lifecycle (ServerMain.server.luau)
Upon server startup, ServerMain executes sequential initialization across all 16 server managers:
Network Initialization: Invokes RemoteEvents.Init() to construct and register the 22 centralized remotes.
Combat & Locomotion Managers:
CombatStateManager.Init() — Posture, CC state machine, hyperarmor buffer.
WeaponManager.Init() — Attachment rigging, 3D equip/unequip sound and sheathing.
Cultivation & Core State:
CultivationManager.Init() — Dantian tracking, realm multipliers, aura lifecycles.
InventoryManager.Init() — 60-slot storage, item validation, stack calculations.
PlayerDataManager.Init() — Connects to DataStoreService under key ASCEND_PlayerData_V2. Starts 5-minute auto-save loop and developer item injection hooks (Han_jueee).
World & Profession Managers:
GatheringManager.Init() — Vintage herb spawn nodes, harvest timers, toast broadcasting.
AlchemyManager.Init() — Cauldron temperature minigame and pill crafting logic.
EnvironmentTimeManager.Init() — 12-minute 4-phase day/night lighting cycle.
TreeCollisionManager.Init() — Sets foliage CanCollide = false while maintaining solid trunks.
VendorManager.Init() — Sect market buying/selling and dynamic catalog sync.
BlacksmithManager.Init() — Weapon refinement (+10) and blade sharpening forge hooks.
TeaHouseManager.Init() — Spirit tea brewing orders and timed buff attributes.
Sect, AI & Arena Engagement:
SectManager.Init() — 3-tier daily duties, CP sync, daily stipend claims.
MobAIManager.Init() — Pathfinding state machine, leash boundaries, kill attribution.
ArenaManager.Init() — Standby pads (DuelPad1/DuelPad2), 3s countdown, 1,000 HP normalization.
MarketplaceManager.Init() — Gamepass perks and Developer Product receipt ledger.
4. Client-Side Execution Model
4.1 Client Lifecycle (ClientMain.client.luau)
Client initialization executes concurrently via task.spawn(), preventing any single slow controller from blocking the client initialization pipeline:
Concurrently boots all 20 controllers in StarterPlayer/StarterPlayerScripts/Controllers/.
Initializes DeWidth.client.luau to manage mobile camera field-of-view and viewport adjustments.
Bridges all controllers directly to pre-existing UI instances in PlayerGui.
4.2 Custom R6 Locomotion Pipeline (Animate.client.luau)
Permanently overrides Roblox's default character script inside StarterPlayer.StarterCharacterScripts:
Idle Yaw Pinning: Locks character torso rotation to camera yaw when stationary or meditating.
Velocity-Synced Audio: Dynamically plays footstep SFX synchronized to actual root velocity.
Fall Height Filter: Eliminates false landing audio on small terrain undulations (<3 studs).
Anti-Ragdoll State Locking: Prevents characters from entering falling ragdoll states upon dashing into obstacles or terrain walls.
5. Lower Sect Hub Facilities Architecture
5.1 Blacksmithing Refinement & Sharpening
Server: BlacksmithManager.luau | Client: BlacksmithController.luau
Network Remote: BlacksmithAction
World Target: ProximityPrompt on Sect_NPC_MadameTie or Master Blacksmith Anvil.
Refinement Execution:
Upgrades equipped Flying Sword base attack power up to +10.
Upgrades grant +5% base ATK per level:
RefinementDamageMultiplier
=
1.0
+
(
RefineLevel
×
0.05
)
RefinementDamageMultiplier=1.0+(RefineLevel×0.05)
Deducts 150 + (RefineLevel * 75) Spirit Stones and MountainIronIngot from inventory.
Dynamically calculates success chance:
SuccessRate
=
max
⁡
(
0.35
,
0.95
−
RefineLevel
×
0.08
)
SuccessRate=max(0.35,0.95−RefineLevel×0.08)
Failure consumes materials but preserves refinement level.
Blade Sharpening Execution:
Deducts 100 Spirit Stones.
Assigns player:SetAttribute("BladeSharpenedUntil", os.clock() + 900).
Assigns player:SetAttribute("SharpnessCritBonus", 0.10) (+10% Critical Strike Chance).
5.2 Spirit Tea Pavilion
Server: TeaHouseManager.luau | Client: TeaHouseController.luau
Network Remote: TeaHouseAction
World Target: ProximityPrompt on Sect_NPC_XiaoLing ("Order Spirit Tea").
Catalog Execution:
Jade Dew Spirit Tea (100 Stones): Calls CultivationManager.AddInternalQi(player, 250). Sets TeaMeditationBuffUntil (+10% meditation speed for 10 min).
Crimson Ginseng Brew (150 Stones): Heals 500 HP immediately. Sets HealthRegenBonus = 0.15 for 10 min.
Dragon Well Sword Tea (250 Stones): Sets TeaSwordIntentBuffUntil and TeaSwordIntentMultiplier = 1.15 (+15% Intent gain for 15 min).
5.3 Training Grounds & Ironwood Dummies
Dummy Script: ImmortalDummyHandler.server.luau (Runs on TrainingDummy_1, 2, 3 in Workspace.Functional_Stations.Sect_TrainingGround).
Client Controller: SparringGuidanceController.luau (Bound to Sect_NPC_InstructorWu).
Mechanics:
Dummies have 10,000,000 HP with instant server-authoritative regeneration.
Logs all incoming hit damage into a rolling 5-second circular timestamp buffer.
Displays damage numbers and rolling DPS overhead via BillboardGui using Enum.Font.Bangers.
Dialogue with Instructor Wu can trigger full DPS counter resets across all dummies.
5.4 Sect Starter Guide
Client Controller: StarterGuideController.luau
World Target: ProximityPrompt on Sect_NPC_ElderQing ("Seek Guidance").
GUI: Opens StarterGui.StarterGuideGui featuring 4 tabbed interactive frames: Controls, Cultivation, Sword Intent, and Sect Duties.