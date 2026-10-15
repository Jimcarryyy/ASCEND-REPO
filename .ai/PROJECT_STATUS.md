---

### Dropped Content Report — `.ai/PROJECT_STATUS.md`
* **Carried Over:** All verified subsystem rows in the matrix.
* **Updated:** 
  * Added **Non-Humanoid Monster Engine** row covering `MonsterConfig`, `MonsterUtil`, `MonsterAIManager`, `MonsterVisualController`.
  * Updated **Bestiary & Mob AI** row to clarify dual ecosystem: 10 Humanoid Cultivators + 5 Quadruped Beasts.
  * Updated **Guarding & Parrying** and **Basic Combat Chain** rows to reflect non-humanoid hit routing.
* **Dropped:** No completion percentages added.

#### Replacement: `.ai/PROJECT_STATUS.md`
```markdown
# ASCEND — Subsystem Health & Implementation Matrix

> **Factual Subsystem Status**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** Monster Core Locomotion Polish & Combat V1 Phase 4 Resumption  

---

## 📊 Subsystem Verification Matrix

| Subsystem | Core Script(s) | Status | Factual Implementation State |
| :--- | :--- | :---: | :--- |
| **DataStore & Persistence** | `PlayerDataManager.luau` | **Verified Stable** | Running `ASCEND_PlayerData_V3` with Samsara tracking, 5-slot Meridian Vault persistence, Bloodline pity/spins, 24h stipend timestamp, 100-slot inventory capacity, and authoritative `RouteToSpawnDais`. `Cultivation.SwordDao` default set to `"Thunder"`. Starter weapon set to `IronReed`. |
| **Network Infrastructure** | `RemoteEvents.luau` | **Verified Stable** | Exactly 16 active remotes instantiated with `--!strict` Luau typing. |
| **Basic Combat Chain (M1)** | `FlyingSwordServer.luau`<br>`InputController.luau`<br>`CombatStateManager.luau`<br>`AnimationController.luau` | **Overhaul (Phases 1-3)** | 5-hit combo operational: 0.30s cadence for hits 1–4, 2.20s finisher lockout loop, 11.5 studs/s attack speed dampening, lunge deleted, input buffering (0.35 fraction), swing tokens, planar sword trails, and client-only speed governor. Dual routing supports both Humanoids and Monsters. |
| **Weapon Progression** | `ItemConfig.luau`<br>`WeaponManager.luau`<br>`SwordAltarManager.luau` | **Verified Stable** | 10 canonical weapons from `ReplicatedStorage.Weapons.NewWeapons` (Common to Legendary; Dao, Cutlass, Jian) with dedicated VFX palettes and universal placeholder icon. |
| **Avatar Scale & Anti-Trip** | `AntiTripServer.server.luau` | **Verified Stable** | Scaled to `BODY_SCALE = 1.15` (15% larger) and `HEAD_REDUCTION = 0.90` with neck offset alignment. `FallingDown` and `Ragdoll` disabled. |
| **Non-Humanoid Monster Engine** | `MonsterConfig.luau`<br>`MonsterUtil.luau`<br>`MonsterAIManager.luau`<br>`MonsterVisualController.luau` | **Active Engineering** | Decoupled attribute-driven monster architecture (ADR-073). 5 standard beasts (`Iron-Tusk Spirit Boar`, `Wilderness Spirit Wolf`, `Magma Hound`, `Obsidian Lava-Boar`, `Frost-Fang Wolf`). Bosses voided (ADR-074). Slope-adaptive lookahead suspension, 46-stud wolf leap attack, 1.0-stud hit flinch, 0.65s stagger lockout, and Option B spawner replication. |
| **Guarding & Parrying** | `CombatStateManager.luau`<br>`HitboxManager.luau`<br>`FlyingSwordConfig.luau` | **Verified Stable** | 70% guard mitigation (`T`), 100% perfect parry (0.22s) with `Workspace:GetServerTimeNow()` synchronization, 1.2s stun, +8% Qi restore, posture drain, and guard break. Parrying monsters stuns beasts for 1.2s. |
| **Focus Target Aim Lock** | `FocusTargetController.luau`<br>`InputController.luau` | **Verified Stable** | Azure Qi reticle with upper-body aim lock bound to `ALT` and `FocusTargetController` getters. Target HUD tracks enemy Name, Realm, HP%, and Posture bar for both Humanoids and Monsters. |
| **Skill Q (Tempest)** | `FlyingSwordServer.luau`<br>`CombatVFXController.luau` | **Verified Stable** | Dual hitbox (point-blank cleave + 3 traveling sawblades @ 70 studs/s); knockback zeroed to slice in place. Cooldown = 6.5s, Qi cost = 12%. Routes damage to both Humanoids and Monsters. |
| **Skill E (Void Thrust)** | `FlyingSwordServer.luau`<br>`InputController.luau` | **Verified Stable** | Fast piercing thrust beam (5x5x12 box, -14 knockback). Cooldown = 7.5s, Qi cost = 15%. Routes damage to both Humanoids and Monsters. |
| **Ultimate F (Flash-Step)** | `FlyingSwordServer.luau`<br>`AnimationController.luau` | **Verified Stable** | 32-stud instant Celestial Flash-Step / Blink slash with mid-air slice and 100-slash domain detonation; anti-trip physics enforced. Cooldown = 14.0s, Qi cost = 20%. |
| **Flight Mode (V / Slot 2)** | `WeaponManager.luau`<br>`FlyingSwordServer.luau`<br>`InputController.luau` | **Verified Stable** | 3D flight with dynamic realm speed scaling (48+ studs/s), 25 Qi/s drain, 0-Qi auto-dismount, and ground/obstacle cushions. Bound to keybind `2`, hotbar slot 2, and `V`. |
| **Cultivation & Breakthrough** | `CultivationConfig.luau`<br>`CultivationManager.luau`<br>`CultivationController.luau` | **Verified Stable** | 10 Realms × 9 Orders (90 stages), pure per-order reset loop restored, Tier 1 BaseTargetQi = 500, hard-cap at 100% TargetQi, 10 realm Qi nodes deployed. Grounded meditation unified to `Tier1_Common` particle template with dynamic orb color tinting. |
| **Bloodline Altar & Gacha** | `BloodlineController.luau`<br>`BloodlineManager.luau`<br>`BloodlineConfig.luau` | **Verified Stable** | 10 spiritual orbs from `NewBloodlines` (Common to Legendary) hovering above the left shoulder with autonomous world-space damped follow, PointLight illumination, and zero particle VFX. 30-pull bad-luck pity. |
| **Alchemy Cauldron System** | `AlchemyConfig.luau`<br>`AlchemyController.luau`<br>`AlchemyManager.luau` | **Verified Stable** | 4-slot combination cauldron (`SlotsContainer`), all 13 formulas overhauled to 4-slot recipes, auto-scrolling catalog, stack consolidation, and flame-timing minigame. |
| **World Resource Gathering** | `GatheringManager.luau`<br>`GatheringConfig.luau`<br>`GatheringController.luau` | **Verified Stable** | 57 nodes in `Workspace.GatheringNodes` with `NodeType` attributes, `RollHarvestResult` drop chance calculation, deep prompt disable/respawn lifecycle. |
| **Sect Exchange Pavilion (Market)** | `VendorManager.luau`<br>`MarketController.luau` | **Verified Stable** | Direct Studio binding to `SectMerchantMarketGui`, `MarketAction` remote gateway, unlimited Buy stock, bulk sales up to 9,999 units, live inventory delivery on purchase, and responsive mobile grid scaling. |
| **UI Architecture** | `StarterGui.MasterHUDGui`<br>`SkillBarController.luau`<br>`HUDController.luau` | **Verified Stable** | Bottom-center 1–5 item hotbar, dynamic active cooldown status row, collapsible bottom-right action guide (`[⌨ KEYS]` / <kbd>H</kbd>), integrated top-right map/compass, and full world map modal. Standardized on `FredokaOne` font, 0 `UICorner`, solid opacity, and steel-grey borders. |
| **Bestiary & Mob AI** | `MobAIManager.luau`<br>`MobConfig.luau` | **Verified Stable** | 10 Humanoid R6 Cultivators with `SPAWNER_ALIAS_MAP`, unanchoring loop, and Boids flocking separation. Operating concurrently with non-humanoid monster spawner network. |
| **Martial Arena (PvP)** | `ArenaManager.luau`<br>`ArenaController.luau` | **Verified Stable** | On-demand proximity challenge within 35 studs, 50-stud circular Qi Ring, timer HUD, 1-HP non-lethal concession, and capped decaying `LinearVelocity` rebound. |

---

## 🔍 Active Watchpoints
1. **Lookahead Suspension Traversal:** Verify beasts smoothly navigate uphill grass transitions in `input_file_11.png` without curb-locking.
2. **Wolf Airborne Leap Trajectory:** Confirm 46-stud/s vertical burst delivers a physical 5-stud-high jump arc toward the player.
3. **Phase 4 Dash Leap Resumption:** Transition to Combat V1 Phase 4 (kinematic jump leap and 0.30s i-frame sync) once beast navigation is confirmed.