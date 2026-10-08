---

### Dropped Content Report — `.ai/PROJECT_STATUS.md`
* **Carried Over:** All verified subsystems in the matrix.
* **Updated:**
  * `Weapon Progression`: Updated from 8 legacy tiers to 10 canonical weapons from `NewWeapons` (Dao, Cutlass, Jian).
  * `Bloodline Altar & Gacha`: Updated from 7-tier back-mount relics to 10 autonomous left-shoulder spiritual orbs.
  * `Cultivation & Breakthrough`: Recorded unified `Tier1_Common` meditation aura.
  * `UI Architecture`: Recorded the new Master HUD structure (1–5 Hotbar, Cooldown Popups, Integrated Map, Collapsible Action Guide) and `SectMerchantMarketGui`.
  * `Sect Exchange Pavilion (Market)`: Documented live `MarketAction` wiring, unlimited stock, and 9,999-unit bulk transactions.
* **Dropped:** No completion percentages added per standard prompt rules.

```markdown
# ASCEND — Subsystem Health & Implementation Matrix

> **Factual Subsystem Status**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** ASCEND Combat V1 — Kinematic Overhaul & Architecture Hardening

---

## 📊 Subsystem Verification Matrix

| Subsystem | Core Script(s) | Status | Factual Implementation State |
| :--- | :--- | :---: | :--- |
| **DataStore & Persistence** | `PlayerDataManager.luau` | **Verified Stable** | Running `ASCEND_PlayerData_V3` with Samsara tracking, 5-slot Meridian Vault persistence, Bloodline pity/spins, 24h stipend timestamp, 100-slot inventory capacity, and authoritative `RouteToSpawnDais`. `Cultivation.SwordDao` default set to `"Thunder"`. Starter weapon set to `IronReed`. |
| **Network Infrastructure** | `RemoteEvents.luau` | **Verified Stable** | Exactly 16 active remotes instantiated with `--!strict` Luau typing. |
| **Basic Combat Chain (M1)** | `FlyingSwordServer.luau`<br>`InputController.luau`<br>`CombatStateManager.luau`<br>`AnimationController.luau` | **Overhaul (Phases 1-3)** | 5-hit combo operational: 0.30s cadence for hits 1–4, 2.20s finisher lockout loop, 11.5 studs/s attack speed dampening, lunge deleted, input buffering (0.35 fraction), swing tokens, planar sword trails, and client-only speed governor. |
| **Weapon Progression** | `ItemConfig.luau`<br>`WeaponManager.luau`<br>`SwordAltarManager.luau` | **Verified Stable** | 10 canonical weapons from `ReplicatedStorage.Weapons.NewWeapons` (Common to Legendary; Dao, Cutlass, Jian) with dedicated VFX palettes and universal placeholder icon. |
| **Avatar Scale & Anti-Trip** | `AntiTripServer.server.luau` | **Verified Stable** | Scaled to `BODY_SCALE = 1.15` (15% larger) and `HEAD_REDUCTION = 0.90` with neck offset alignment. `FallingDown` and `Ragdoll` disabled. |
| **Combat Timing Engine** | `CombatStateManager.luau`<br>`FlyingSwordConfig.luau` | **Overhaul (Phase 1)** | Server-authoritative `M1Step` and `LastM1Time` sequence tracking with 2.20s finisher recovery gate and timing derived from `FlyingSwordConfig.GetM1Timing`. |
| **Sword Intent Gauge** | `CombatStateManager.luau`<br>`SkillBarController.luau` | **Pending Server Sync** | Client UI (`IntentBarFrame`) functional; server-authoritative tracking (+25/hit, 8%/s decay after 2.5s) and attribute replication scheduled. |
| **Guarding & Parrying** | `CombatStateManager.luau`<br>`HitboxManager.luau`<br>`FlyingSwordConfig.luau` | **Verified Stable** | 70% guard mitigation (`T`), 100% perfect parry (0.22s) with `Workspace:GetServerTimeNow()` synchronization, 1.2s stun, +8% Qi restore, posture drain, and guard break. |
| **Focus Target Aim Lock** | `FocusTargetController.luau`<br>`InputController.luau` | **Verified Stable** | Azure Qi reticle with upper-body aim lock bound to `ALT` and `FocusTargetController` getters. Target HUD tracks enemy Name, Realm, HP%, and Posture bar. |
| **Skill Q (Tempest)** | `FlyingSwordServer.luau`<br>`CombatVFXController.luau` | **Verified Stable** | Dual hitbox (point-blank cleave + 3 traveling sawblades @ 70 studs/s); knockback zeroed to slice in place. Cooldown = 6.5s, Qi cost = 12%. |
| **Skill E (Void Thrust)** | `FlyingSwordServer.luau`<br>`InputController.luau` | **Verified Stable** | Fast piercing thrust beam (5x5x12 box, -14 knockback). Cooldown = 7.5s, Qi cost = 15%. |
| **Ultimate F (Flash-Step)** | `FlyingSwordServer.luau`<br>`AnimationController.luau` | **Verified Stable** | 32-stud instant Celestial Flash-Step / Blink slash with mid-air slice and 100-slash domain detonation; anti-trip physics enforced. Cooldown = 14.0s, Qi cost = 20%. |
| **Flight Mode (V / Slot 2)** | `WeaponManager.luau`<br>`FlyingSwordServer.luau`<br>`InputController.luau` | **Verified Stable** | 3D flight with dynamic realm speed scaling (48+ studs/s), 25 Qi/s drain, 0-Qi auto-dismount, and ground/obstacle cushions. Bound to keybind `2`, hotbar slot 2, and `V`. |
| **Cultivation & Breakthrough** | `CultivationConfig.luau`<br>`CultivationManager.luau`<br>`CultivationController.luau` | **Verified Stable** | 10 Realms × 9 Orders (90 stages), pure per-order reset loop restored, Tier 1 BaseTargetQi = 500, hard-cap at 100% TargetQi, 10 realm Qi nodes deployed. Grounded meditation unified to `Tier1_Common` particle template with dynamic orb color tinting. |
| **Bloodline Altar & Gacha** | `BloodlineController.luau`<br>`BloodlineManager.luau`<br>`BloodlineConfig.luau` | **Verified Stable** | 10 spiritual orbs from `NewBloodlines` (Common to Legendary) hovering above the left shoulder with autonomous world-space damped follow, PointLight illumination, and zero particle VFX. 30-pull bad-luck pity. |
| **Alchemy Cauldron System** | `AlchemyConfig.luau`<br>`AlchemyController.luau`<br>`AlchemyManager.luau` | **Verified Stable** | 4-slot combination cauldron (`SlotsContainer`), all 13 formulas overhauled to 4-slot recipes, auto-scrolling catalog, stack consolidation, and flame-timing minigame. |
| **World Resource Gathering** | `GatheringManager.luau`<br>`GatheringConfig.luau`<br>`GatheringController.luau` | **Verified Stable** | 57 nodes in `Workspace.GatheringNodes` with `NodeType` attributes, `RollHarvestResult` drop chance calculation, deep prompt disable/respawn lifecycle. |
| **Sect Exchange Pavilion (Market)** | `VendorManager.luau`<br>`MarketController.luau` | **Verified Stable** | Direct Studio binding to `SectMerchantMarketGui`, `MarketAction` remote gateway, unlimited Buy stock, bulk sales up to 9,999 units, live inventory delivery on purchase, and responsive mobile grid scaling. |
| **UI Architecture** | `StarterGui.MasterHUDGui`<br>`SkillBarController.luau`<br>`HUDController.luau` | **Verified Stable** | Bottom-center 1–5 item hotbar, dynamic active cooldown status row, collapsible bottom-right action guide (`[⌨ KEYS]` / <kbd>H</kbd>), integrated top-right map/compass, and full world map modal. Standardized on `FredokaOne` font, 0 `UICorner`, solid opacity, and steel-grey borders. |
| **Bestiary & Mob AI** | `MobAIManager.luau`<br>`MobConfig.luau` | **Verified Stable** | 10 Humanoid R6 Cultivators with `SPAWNER_ALIAS_MAP`, unanchoring loop, and Boids flocking separation. Corpses retain terrain collision on death. |
| **Martial Arena (PvP)** | `ArenaManager.luau`<br>`ArenaController.luau` | **Verified Stable** | On-demand proximity challenge within 35 studs, 50-stud circular Qi Ring, timer HUD, 1-HP non-lethal concession, and capped decaying `LinearVelocity` rebound. |

---

## 🔍 Active Watchpoints
1. **Phase 4 Dash Leap:** Implement aerial leap physics, ground landing detection, and 0.30s i-frame sync.
2. **Phase 5 Defense Tuning:** Add `CLASH_COOLDOWN_PER_PLAYER = 0.6s`, scale M1 posture damage by 0.5×, and enforce `BLOCK_REPRESS_COOLDOWN = 0.45s`.
3. **World Map Capture:** Generate and upload high-resolution top-down terrain orthographic image for `FullWorldMapFrame`.