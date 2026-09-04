# ASCEND — Technical Architecture Specification

> Directory Hierarchy, Service-Controller Framework, Networking & Lifecycle Hooks

---

## 1. Directory Structure

```text
src/
├── ReplicatedFirst/
│   └── LoadingScreen.client.luau          (5-gate preload and server sync loading screen)
├── ReplicatedStorage/
│   └── Shared/
│       ├── Configs/
│       │   ├── AlchemyConfig.luau          (Formulas, flame minigame, quality multipliers)
│       │   ├── AnimationConfig.luau        (R6 animation asset registry & timings)
│       │   ├── CultivationConfig.luau      (10 Major Realms x 9 Orders, stat curves)
│       │   ├── GatheringConfig.luau        (Harvest timers, respawns, weighted herb ages)
│       │   ├── HUDSkinConfig.luau          (HUD skins and offset mappings)
│       │   ├── ItemConfig.luau             (Master item registry for 8 sword tiers, pills, herbs)
│       │   ├── MobConfig.luau              (R6 zone mob stats, AI attributes, drop tables)
│       │   ├── MonetizationConfig.luau     (Gamepasses, DevProducts, receipt definitions)
│       │   ├── SectConfig.luau             (6 Disciple ranks, 3-tier daily duties, catalog)
│       │   ├── UIAssets.luau               (Audio IDs, 2D sword icons, design tokens)
│       │   └── Weapons/
│       │       └── FlyingSwordConfig.luau  (M1 chains, posture damage, parry timings)
│       └── Network/
│           └── RemoteEvents.luau           (Central RemoteEvent factory)
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau          (Master server bootstrap)
│       ├── Combat/
│       │   ├── ArenaManager.luau           (1v1 Sparring arena matchmaking & normalization)
│       │   ├── HitboxManager.luau          (Spatial box hitboxes, parry resolution, intent loop)
│       │   ├── MobAIManager.luau           (Pathfinding AI, aggro, leash state machine)
│       │   ├── WeaponManager.luau          (3D sword model mounting & draw/sheath tracker)
│       │   └── Weapons/
│       │       └── FlyingSwordServer.luau  (Server attack execution pipeline)
│       ├── Cultivation/
│       │   ├── AlchemyManager.luau         (Server manual combination alchemy engine)
│       │   ├── CultivationManager.luau     (Dantian Qi expansion, meditation, breakthroughs)
│       │   └── SectManager.luau            (Quest lifecycle, promotions, stipends)
│       ├── State/
│       │   ├── CombatStateManager.luau     (ActionState, CCState, hyperarmor buffer)
│       │   ├── InventoryManager.luau       (60-slot storage, stack validation)
│       │   ├── MarketplaceManager.luau     (ProcessReceipt & gamepass perk verification)
│       │   └── PlayerDataManager.luau      (DataStore V3 persistence & developer injection)
│       └── World/
│           ├── EnvironmentTimeManager.luau (12-min 4-phase day/night lighting engine)
│           ├── GatheringManager.luau       (Server harvesting & weighted RNG rolls)
│           ├── TreeCollisionManager.luau   (Trunk-only collision cleaner)
│           └── VendorManager.luau          (Sect market transactions)
└── StarterPlayer/
    ├── StarterCharacterScripts/
    │   └── Animate.client.luau             (Dedicated R6 locomotion engine & yaw pinning)
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          (Concurrent task.spawn client bootstrap)
        └── Controllers/
            ├── AlchemyController.luau      (Cauldron combination & flame minigame UI)
            ├── AnimationController.luau    (R6 attack keyframing & dash anim playback)
            ├── ArenaController.luau        (1v1 Arena registration modal binding)
            ├── CombatVFXController.luau    (Floating damage, intent popups, parry sparks)
            ├── CultivationController.luau  (3D Bangers QiNode billboards & QIZoneNotifGui)
            ├── FocusTargetController.luau  (Top-center target lock-on & posture gauge)
            ├── GatheringController.luau    (World prompt interaction & audio sync)
            ├── HUDController.luau          (GlobalToastNotifGui anti-spam toast engine)
            ├── InputController.luau        (CTRL run, T block, Shift dash, C cultivate, M1)
            ├── InventoryController.luau    (Spirit Pouch 60-slot 2D sword showcase)
            ├── MarketController.luau       (Sect Pavilion auto-catalog & exact CP sync)
            ├── OverheadUIController.luau   (FredokaOne overheads, emerald HP bar)
            ├── QuestTrackerController.luau (SectMissionGui 3-tier duty cards)
            ├── SectController.luau         (Sect Pavilion disciple promotion modal)
            ├── SkillBarController.luau     (SkillsGUI, LowViewPortSkillsGUI, CurrencyGUI)
            └── WindEnvironmentController.luau (Spatial culling organic wind sway physics)

## 5. R6 Character Locomotion & Animation Architecture

### A. Dedicated Locomotion Engine (`src/StarterPlayer/StarterCharacterScripts/Animate.client.luau`)
* **Roblox Standard Overriding:** Placed in `StarterCharacterScripts` as a LocalScript named `Animate`. Roblox's character engine automatically suppresses its default built-in movement script on spawn and executes `Animate.client.luau` for all spawned characters.
* **On-Demand Dynamic Binding (`GetLocomotionTrack`):** Locomotion tracks are bound dynamically on the live `Animator` instance when state changes occur, preventing orphaned track bugs caused by server-side character loading.
* **State Machine & Velocity Sync:** Listens to `Humanoid.Running` and `Humanoid.StateChanged`:
  * **Idle:** Plays `trackIdle`. Includes a 100% Y-axis rotation lock (`rootJoint.Transform = CFrame.Angles(x, 0, z)`) to erase asset-baked Y-rotation drift that previously caused characters to spin 360° like a clock hand.
  * **Walk V1 vs Run V1:** Moves at `WalkSpeed = 16` (Walk V1) or `WalkSpeed = 28` when holding LeftShift (Run V1). Syncs audio `PlaybackSpeed` 1:1 with movement velocity.
  * **Jump $\rightarrow$ Land:** On normal jumps, transitions directly **Jump $\rightarrow$ Land $\rightarrow$ Idle/Walk** (skips `Fall`).
  * **Height-Filtered Fall:** Only triggers `Fall` (`105371732122929`) if in freefall for $>0.35$ seconds (cliff drops).
  * **0.3s Jump Recovery Debounce:** Prevents robotic jump spamming.
  * **Tripping Fix:** Disables `FallingDown` and `Ragdoll` humanoid states (`Humanoid:SetStateEnabled(...)`) to prevent characters from flopping on slopes.

### B. Technical Diagnostic Clues & Discoveries
1. **Experience Asset Ownership Protection:** If an animation asset ID was published under a personal account or group that does not match the experience place owner, Roblox blocks the track on live player avatars while allowing it on Studio local viewport rigs. Granting access via Studio Output (`Click to share access`) resolves the block.
2. **R15 Mesh Package Conflict on R6 Rigs:** If a player's Roblox.com web avatar wears R15 3D Layered Clothing or mesh packages, forcing R6 inserts MeshPart limbs that Roblox's R6 C++ Animator cannot animate with standard R6 KeyframeSequences.
3. **`ApplyDescription()` Animator Invalidation:** Executing `humanoid:ApplyDescription()` on the server re-creates the `Animator` instance at runtime, invalidating any animation tracks previously loaded before `ApplyDescription()` completed.

### Sect Economy, Arena & Monetization Subsystems (Added 2026-08-20)

- **`SectManager.luau` (Server):** Manages quest lifecycle (`Gather`, `CraftDan`, `DefeatMob`), daily stipends, and rank promotions verified against `CultivationConfig.RealmTier`.
- **`VendorManager.luau` (Server):** Validates inventory transactions and Spirit Stone balances for buying/selling ingredients.
- **`MobAIManager.luau` (Server):** Manages R6 humanoid mob lifecycle and dynamically scales Spirit Stone and Qi rewards based on player realm tier.
- **`ArenaManager.luau` (Server):** Matchmaking engine pairing duelists in identical cultivation realm brackets for 90-second non-lethal combat.
- **`MarketplaceManager.luau` (Server):** Processes `MarketplaceService.ProcessReceipt` and verifies persistent gamepass perks.
- **`SkillBarController.luau` (Client):** Drives cooldown overlay frames and countdown text on `StarterGui.SkillsGUI`.
- **`QuestTrackerController.luau` (Client):** Hooks `StarterGui.QuestTrackerGUI` and formats dynamic duty cards.

### Weapon Sheath & Locomotion Architecture

#### 1. Dual-Attachment Weapon Mounting (`WeaponManager.luau`)
* Swords are stored as single-mesh templates in `ReplicatedStorage.Weapons`.
* **Hand Attachment:** `Right Arm.RightGripAttachment` connected to `Sword.SwordAttachment`.
* **Back Sheath Attachment:** `Torso.BackSwordMount` (`CFrame.new(0, 0.35, 0.68) * CFrame.Angles(0, 0, math.rad(135))`) connected to `Sword.BackSwordAttachment`.
* **State Switching:** Controlled via `WeaponManager.SetWeaponState(player, "Hand" | "Back" | "Hidden")`.

#### 2. Locomotion Anti-Drift & Physics Hardening (`Animate.client.luau`)
* **Idle Yaw Pinning:** When `Humanoid.MoveDirection.Magnitude == 0`, `targetIdleYaw` captures the stopping orientation and pins `HumanoidRootPart.CFrame` with `AssemblyAngularVelocity = Vector3.zero`.
* **Anti-Ragdoll Physics:** Permanently disables `FallingDown`, `Ragdoll`, `PlatformStanding`, and `GettingUp`, enforcing `MaxSlopeAngle = 89` for smooth stair/terrain traversal.
* **UI Input Sinks:** `InputController.luau` checks `IsAnyMenuOpen()` and `UserInputService:GetFocusedTextBox()` to prevent input bleed into attacks/jumping while interacting with interfaces.

## Additive Architecture Update (2026-08-27) — Unified Combat State & Production Streaming

### 1. Unified Server Combat & CC State Machine (`CombatStateManager.luau`)
* Centralized player state: `ActionState` (`Idle`, `Windup`, `Active`, `Recovery`, `Blocking`, `Dashing`) and `CCState` (`None`, `Staggered`, `Stunned`, `GuardBroken`, `CCImmune`).
* **$0.6\text{s}$ Anti-Stunlock Buffer:** Applies hard hyperarmor upon recovering from any stun to prevent infinite stunlock chains.
* **$100\text{-Point}$ Posture Engine:** Blocking attacks drains posture; reaching $0\text{ Posture}$ inflicts a $1.2\text{s}$ Guard-Break vulnerability stun ($+25\%$ bonus damage).
* **Anti-Animation Canceling:** Enforces server-side `RecoveryEndTime` lockouts to prevent skipping attack recovery frames with skills.

### 2. Live Production Streaming & Arena Architecture (`ArenaManager.luau`)
* **Streaming Protection:** Calls `player:RequestStreamAroundAsync()` before teleporting, ensuring terrain and floor colliders load on the client before touchdown (eliminating void-falling).
* **Physical Dual-Pad Standby:** Monitors `DuelPad1` and `DuelPad2` presence to drive a 3-second match countdown that auto-cancels if either fighter steps off.
* **Non-Lethal Concession Engine:** Reaching $\le 1\text{ HP}$ in the arena terminates the match cleanly, resetting health without triggering dead-state character respawn corruptions.

### 3. Asynchronous Client Bootstrap (`ClientMain.client.luau`)
* Initializes all 15 client controllers concurrently via `task.spawn()`, preventing missing/redesigned UI elements from blocking other controllers.