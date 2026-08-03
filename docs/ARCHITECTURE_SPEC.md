---

# File 7: `docs/ARCHITECTURE_SPEC.md`

```markdown
# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Directory Hierarchy, Service-Controller Framework, Network Pipeline, DataStore Schemas, & Lifecycle Hooks.

---

## 1. Roblox Studio Project Directory Structure

ASCEND-V1 uses a modular, single-script entry point architecture for both server and client execution contexts:

```text
src/
├── ReplicatedFirst/
├── ReplicatedStorage/
│   └── Shared/
│       ├── Configs/
│       │   ├── AlchemyConfig.luau          (Recipe definitions, ingredients, spirit pill consumable effects)
│       │   ├── AnimationConfig.luau        (R15 Animation IDs, speeds, cast durations, WalkSpeed dampening)
│       │   ├── CultivationConfig.luau      (5 Realms, Qi capacity, gather rates, health multipliers, aura colors)
│       │   ├── InventoryConfig.luau        (Item metadata schema, 3D ViewportFrame placeholders)
│       │   ├── RarityConfig.luau           (Rarity tiers Mortal to Immortal, rankings & Hex colors)
│       │   ├── UIAssets.luau               (Central Asset Registry for image/decal IDs)
│       │   └── Weapons/
│       │       ├── FlyingSwordConfig.luau  (Flying Sword M1 combo steps, skill damage, ranges, knockbacks)
│       │       ├── GauntletConfig.luau     (Gauntlet punch combo steps, 360° palms, ground slam stats)
│       │       └── SpearConfig.luau        (Spear thrust combo steps, lunge physics, skill stats)
│       └── Network/
│           └── RemoteEvents.luau           (RemoteEvent factory pre-creating all network remotes)
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau          (Server initialization entry point)
│       ├── Combat/
│       │   ├── HitboxManager.luau          (Spatial box query engine GetPartBoundsInBox & knockback physics)
│       │   ├── WeaponManager.luau          (Equipped weapon tracker, Motor6D attachments, Qi placeholders)
│       │   └── Weapons/
│       │       ├── FlyingSwordServer.luau  (Flying Sword server attack/combo handler)
│       │       ├── GauntletServer.luau     (Gauntlet server attack/combo handler)
│       │       └── SpearServer.luau        (Spear server attack/combo handler)
│       ├── Cultivation/
│       │   ├── AlchemyManager.luau         (Furnace crafting validation, ingredient inventories, pill consumption)
│       │   └── CultivationManager.luau     (Qi meditation G, breakthroughs B, health scaling, body wrap)
│       └── State/
│           └── CombatStateManager.luau     (Server combat state tracker, cooldown validator, & network broadcaster)
├── ServerStorage/
├── StarterGui/
│   ├── HUDGui/                             (ScreenGui for HUD: ActionSkillBar, BossHealthBar, Reticle, TribulationBar)
│   └── InventoryGui/                       (ScreenGui for Modal Inventory window)
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          (Client initialization entry point)
        ├── Client/
        │   └── UI/
        │       └── OverheadUIController.luau(Dynamic overhead BillboardGui HP bars, name tags, cultivation titles)
        └── Controllers/
            ├── AnimationController.luau   (R15 keyframe attack animations, priority layering, meditation camera)
            ├── CombatVFXController.luau   (3D damage numbers, camera shake, slash trails, Shift Dash trail, SFX)
            ├── CultivationController.luau (Meditation calm floating motion and wide camera offset framing)
            ├── HUDController.luau          (Skill slot rendering, sweeping cooldown masks with live decimal timers)
            ├── InputController.luau        (Keybind inputs LMB, F, Q, E, R, Shift, 1, 2, 3, G, B, mouse hit vector payloads)
            └── InventoryController.luau    (Inventory grid population, 3D ViewportFrame rendering, UIStroke borders)

# 🔗 System Wiring & Execution Map

---

# 1. Client Initialization (`ClientMain.client.luau`)

### `HUDController.Init()`

- Builds the skill bar.
- Binds `SyncCooldown` to start cooldown mask sweeps and live timer text.
- Binds `UpdateSkillState` to dynamically update skill icons when swapping weapons.
- Disables Roblox's default Backpack CoreGui.

---

### `InventoryController.Init()`

- Sets up tab/hotkey opening for the inventory modal.
- Renders 3D `ViewportFrame` placeholders (`Render3DPlaceholder`).
- Handles `UIStroke` rarity borders.

---

### `InputController.Init()`

Listens for player inputs.

#### Weapon Swapping

| Key | Action |
|------|--------|
| `1` | Sends `{ RequestWeaponSwap = "FlyingSword" }` |
| `2` | Sends `{ RequestWeaponSwap = "Spear" }` |
| `3` | Sends `{ RequestWeaponSwap = "Gauntlet" }` |

#### Cultivation

| Key | Action |
|------|--------|
| `G` | Sends `{ ToggleMeditation = true }` |
| `B` | Sends `{ RequestBreakthrough = true }` |

#### Combat

| Input | Action |
|--------|--------|
| `LMB` | Sends CombatAction payload |
| `F` | Sends CombatAction payload |
| `Q` | Sends CombatAction payload |
| `E` | Sends CombatAction payload |
| `R` | Sends CombatAction payload |
| `Shift` | Sends CombatAction payload |

Captured payload:

- `mouse.Hit.Position`
- `AimDirection`

---

### `CombatVFXController.Init()`

Listens to `CombatAction` broadcasts from the server.

Features:

- Spawns 3D floating damage numbers over hit targets (`payload.Damage`).
- Plays impact particle burst at `payload.TargetPosition`.
- Plays:
  - Swing SFX (`1222216`)
  - Hit SFX (`5633903110`)
  - Camera shake
- Triggers:
  - Existing 3D slash trails
  - Dynamic fallback slash trails
  - Shift Windstep Dash trails

---

### `AnimationController.Init()`

- Listens to `CombatAction`.
- Plays keyframe attack tracks on the character's `Animator`.
- Animation Priority = `Action`
- `Looped = false`
- Handles Shift physical dodge dash (`AssemblyLinearVelocity` impulse).
- Listens to `UpdateCultivation`.
- Handles:
  - Meditation camera setup (`-13.5` studs front view distance)
  - Floating meditation animation playback

---

### `OverheadUIController.Init()`

Monitors workspace character additions.

Creates dynamic `BillboardGui` displaying:

- Real-time health bar fill
- Green / Yellow / Red color transitions
- Realm rank titles

---

### `CultivationController.Init()`

Controls:

- Slow floating motion
  - `0.5` stud sine wave height
- Wide camera offset framing

---

# 2. Server Initialization (`ServerMain.server.luau`)

---

### `CombatStateManager.Init()`

Listens to:

- `CombatAction` RemoteEvent

Validation sequence:

1. Checks player health.
2. Verifies player is **not**:
   - Stunned
   - QiDeviation
3. Checks `SKILL_COOLDOWNS`.

If valid:

- Records cooldown timestamp.
- Fires `SyncCooldown` back to client.
- Delegates attack execution to:
  - `WeaponManager`
  - `FlyingSwordServer`
  - `SpearServer`
  - `GauntletServer`
- Broadcasts `CombatAction` payload to all clients for VFX/SFX.

---

### `WeaponManager.Init()`

Tracks equipped weapon:

- FlyingSword
- Spear
- Gauntlet

Processes weapon swap requests from:

- `1`
- `2`
- `3`

#### `AttachWeaponModel()`

Attaches:

- Custom MeshPart
- Model
- Tool
- Procedural Qi energy placeholders

Attachment target:

- `RightHand.RightGripAttachment`

Attachment type:

- `Motor6D`
- `WeaponGrip`

Also fires:

- `UpdateSkillState`

Purpose:

- Update client HUD skill slot icons.

---

### `CultivationManager.Init()`

Tracks cultivation realms:

1. Qi Condensation
2. Foundation Establishment
3. Golden Core
4. Nascent Soul
5. Heavenly Tribulation

#### Handles `ToggleMeditation (G)`

- Anchors player steadily.
- Wraps body in lightweight ethereal Highlight aura.
- Runs Qi absorption loop.

#### Handles `RequestBreakthrough (B)`

- Validates max Qi.
- Advances realm.
- Scales player `Humanoid.MaxHealth`.

Example:

- Foundation Establishment
  - `1.5x`

Fires:

- `UpdateCultivation`

---

### `AlchemyManager.Init()`

Listens to:

- `AlchemyAction`

Supported actions:

- `CraftPill`
- `ConsumePill`

Performs:

- Material validation
- Furnace refining delays (`CraftTime`)
- Success rate rolls (`SuccessRate`)

Processes pill consumption:

- Health
- Qi
- Temporary stat buffs

Entirely server-authoritative.

---

# 3. Service-Controller Lifecycle Architecture

Services and Controllers follow a predictable two-phase initialization sequence managed by their respective Bootstrap scripts.

---

## Phase 1 — `OnInit()`

- Instantiates internal variables.
- Instantiates DataStores.
- Instantiates local signals.

**Rule**

Modules **MUST NOT** call functions from other Services or Controllers during `OnInit()`.

---

## Phase 2 — `OnStart()`

Executes after all modules have completed `OnInit()`.

Responsibilities:

- Connect RemoteEvents.
- Begin background loops.
- Cross-reference external Services.

---

# 4. Network Communication Layer (Remote Event Mapping)

Communication uses a unified `RemoteEvents.luau` wrapper around RemoteEvents pre-created on server startup.

| Remote Name | Direction | Payload Parameters | Description |
|-------------|-----------|--------------------|-------------|
| `CombatAction` | Client → Server | `(skillKey: string, payload: table)` | Client requests light/heavy attack or skill execution |
| `CombatAction` | Server → Client | `(attacker: Player, skillKey: string, payload: table)` | Broadcast combat action to all clients for rendering VFX/SFX |
| `UpdateSkillState` | Server → Client | `(weaponType: string, skillData: table)` | Dynamic HUD skill icon swap and cooldown sync |
| `SyncCooldown` | Server → Client | `(skillKey: string, cooldownDuration: number)` | Command client HUD to trigger dark sweeping cooldown mask |
| `UpdateCultivation` | Client → Server | `{ ToggleMeditation: boolean }` or `{ RequestBreakthrough: boolean }` | Request meditation toggle or realm breakthrough |
| `UpdateCultivation` | Server → Client | `{ IsMeditating: boolean, Qi: number, MaxQi: number, Realm: string }` | Broadcast cultivation status updates |
| `AlchemyAction` | Client → Server | `(actionType: "CraftPill" \| "ConsumePill", recipeId: string)` | Client requests alchemy crafting or pill consumption |
| `AlchemyAction` | Server → Client | `(responseType: string, data: table)` | Server syncs craft/consume result and inventory update |
| `InventoryAction` | Server → Client | `(actionType: "SyncInventory", inventoryData: table)` | Server replicates updated player inventory table |

---

## Network Security Guarantee

- All client-to-server remotes pass through strict server-side validation.
- Payloads containing position, damage values, or currency amounts sent from the client are discarded or recalculated on the server.

---

# 5. DataStore Schema (ProfileService)

Player data is persisted using **ProfileService** to ensure:

- Atomic writes
- Session locking
- Data loss prevention

## Default Player Profile Table Structure

```luau
ProfileData = {
    ProfileVersion = 1,
    Data = {
        Level = 1,
        Experience = 0,
        Gold = 0,
        AscensionShards = 0,
        CultivationRealm = "QiCondensation",
        CurrentQi = 0,

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
            mat_spirit_herb = 15,
            mat_demon_core = 5,
            mat_spirit_water = 10,
            pill_qi_gathering = 2,
            pill_healing_dan = 2,
        },

        Mastery = {
            FlyingSword = 0,
            Spear = 0,
            Gauntlet = 0,
        }
    }
}
```

---

# 6. Performance, Memory & Garbage Collection Rules

### Event Disconnection

All transient event listeners (e.g., Touch triggers, temporary animation tracks, particle emitters) must be managed using:

- `Janitor.luau`
- `Debris`

to prevent memory leaks.

---

### Spatial Query Optimization

Server shapecast operations use:

- `Workspace:GetPartBoundsInBox`

with a shared pre-allocated `OverlapParams` instance.

---

### ReplicatedStorage Rules

Clients are never permitted to read or write directly to `ServerStorage`.

Only the following belong inside `ReplicatedStorage`:

- Shared configs
- Utility modules