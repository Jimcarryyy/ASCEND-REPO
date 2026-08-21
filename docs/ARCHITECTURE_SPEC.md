# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Directory Hierarchy, Service-Controller Framework, DataStore Schemas, & Lifecycle Hooks.

---\n
## 1. Roblox Studio Project Directory Structure

```text
src/
├── ReplicatedStorage/
│   └── Shared/
│       ├── Configs/
│       │   ├── AlchemyConfig.luau          (Recipe formulas, age success math, pill effects)
│       │   ├── CultivationConfig.luau      (45 Tiers, normalized 100 - 10,000 HP/Qi scale)
│       │   ├── GatheringConfig.luau          (Node harvest times, respawn delays, age drops)
│       │   ├── ItemConfig.luau             (Master item registry for equipment, herbs, pills)
│       │   ├── UIAssets.luau               (Light-Mode Palette & FredokaOne typography)
│       │   └── Weapons/
│       │       └── FlyingSwordConfig.luau  (Flying Sword M1 combo steps, skill damage, ranges)
│       └── Network/
│           └── RemoteEvents.luau           (RemoteEvent factory pre-creating all network remotes)
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau          (Server initialization entry point)
│       ├── Combat/
│       │   ├── HitboxManager.luau          (Spatial box query engine & knockback physics)
│       │   └── WeaponManager.luau          (Equipped 3D sword model tracker & bounds scaler)
│       ├── Cultivation/
│       │   ├── AlchemyManager.luau         (Server manual combination alchemy engine)
│       │   └── CultivationManager.luau     (Qi meditation F, breakthroughs B, health scaling)
│       ├── World/
│       │   └── GatheringManager.luau       (Server harvesting engine & workspace node tracker)
│       └── State/
│           ├── CombatStateManager.luau     (Server combat state tracker & cooldown validator)
│           ├── InventoryManager.luau       (60-slot server inventory engine, on-demand RequestSync)
│           └── PlayerDataManager.luau      (DataStoreService persistence engine & 5-min auto-save)
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          (Client initialization entry point)
        └── Controllers/
            ├── AlchemyController.luau      (Light-Mode manual 3-slot cauldron combination UI)
            ├── CombatVFXController.luau    (3-wave magma crescent cleaves, sunfalls, camera shake, damage text)
            ├── GatheringController.luau     (Client prompt interaction & GatherHerbsSound)
            ├── HUDController.luau           (Light-Mode HUD dock, HP/Qi meters, hotbar)
            ├── InputController.luau         (Keybind inputs LMB, F, Q, E, R, Shift, G, B, K)
            └── InventoryController.luau     (Spirit Pouch 60-slot storage, rarity-tinted borders)

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