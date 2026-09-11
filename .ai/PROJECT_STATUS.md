# ASCEND — Project Status Overview

## Status Summary
* **Current Milestone:** Phase 8.5 — Combat Engine Hardening & Skills Overhaul
* **Sect Architecture:** Jade Pure Sword Sect (3-Tier Stepped Mountain Fortress)
* **Master Persistence Key:** `ASCEND_PlayerData_V3`
* **Avatar Rig Standard:** Roblox R6 Standard Rig (All Native Attachments Active)
* **Palette Standard:** Dark Obsidian (`#10141C`) + Antique Gold (`#C3A55F` / `#F5AF2D`) + Celestial Azure (`#38BDF8`)
* **Typography Standard:** `Bangers` (Titles/Headers/Badges) & `Fondamento` (Body/Descriptions/Values)
* **Active Operational Focus:** Combat Skills Integration (Q & F Skills) & Hitbox Manager Hardening

---

## Subsystem Health & Operational Readiness

| Subsystem | Status | Core Script / Module Architecture | Implementation Details & Live Capabilities |
| :--- | :---: | :--- | :--- |
| **Combat Engine (Skills)** | 🟢 Operational | `FlyingSwordConfig`, `AnimationConfig`, `InputController`, `FlyingSwordServer`, `CombatVFXController` | **Q Skill (Purple Tempest):** Dual hitbox (point-blank melee + 3x traveling sawblades @ 70 studs/s, 36-stud reach), 15% Qi cost, auto-sprint resumption.<br>**F Skill (100-Slash Domain):** Hold F charge lock (`84905841522350`), 28-stud flash-step dash @ 150 studs/s phasing through enemies, midpoint slash (`111677132360566`), 36-stud purple 100-slash sphere (`UltimateSkill`), audio (`18781431019`), anti-trip ground physics lock. |
| **Sword Combat (M1/Defense)**| 🟢 Operational | `CombatStateManager`, `HitboxManager`, `WeaponManager` | 5-hit broadsword M1 chain with footwork damping (`WalkSpeed = 8`). Looping Sword Intent (+25%/hit, 1.75× empowered strike at 100%). `T` Guard (70% mitigation) & Perfect Parry (0.22s window, 100% negation, +5% Qi). 100-pt Posture & Guard-Break (1.2s stun, +25% vulnerability). 0.6s hyperarmor buffer. |
| **Locomotion & Qi Dash** | 🟢 Operational | `Animate.client.luau`, `AnimationController`, `InputController` | 44 studs/s high-impact sprint, harmonic step-synced head-bobbing, dynamic speed-tunnel FOV (70° -> 76°). 150 studs/s anti-trip Qi Dash (`LeftShift`). Permanent anti-trip protection (`FallingDown` & `Ragdoll` disabled). |
| **Flying Sword Flight Mode** | 🟢 Operational | `WeaponManager`, `InputController`, `ReplicatedStorage.FlyingSword` | Server-authoritative `V`-key flight toggle. Horizontal foot mount via `RigidConstraint` & `AnimationConstraint`. 3D omnidirectional flight at 75 studs/s, ground clearance cushion (6.5 studs), obstacle deflector (8.5 studs), Spacebar ascend, Ctrl descend, and slow idle drift (-2.5 studs/s). |
| **World Gathering** | 🟢 Operational | `GatheringConfig`, `GatheringManager`, `GatheringController`, `StarterGui.GatheringHUD` | 5 configured nodes (`SpiritGrass`, `DragonBloodVine`, `GaleWindLotus`, `CelestialSpring`, `JadeOre`). 1-Click channeled harvest bar via `GatheringHUD`, custom floating billboard prompt, suppressed default Roblox prompt bubble. Elemental PointLights attached. |
| **Zone Mobs & AI Engine** | 🟢 Operational | `MobConfig`, `MobAIManager`, `workspace.MobSpawns` | R6 `RogueDisciple` with standard joints, 19 attachments, and geometric clothing. Server spawner anchors in `workspace.MobSpawns`. Real data resolution via `MobConfig.GetMob(mobId)`. Pathfinding state machine, leashing, and realm-scaled rewards. |
| **Environment & World Physics**| 🟢 Operational | `EnvironmentTimeManager`, `TreeCollisionManager`, `WindEnvironmentController` | 12-minute 4-phase day/night lighting cycle. Tree canopy collision set to `CanCollide = false`, trunks to `Hull`. Wind sway bypass on gathering nodes (`HerbMesh`). |
| **Master HUD Suite** | 🟢 Operational | `StarterGui.MasterHUDGui`, `SkillBarController`, `HUDController`, `QuestTrackerController` | Unified 5-cluster HUD. Live HP/Qi/Intent bars, 10-slot desktop skill bar, full 10-button `MobileScatterCluster`, live CP & Spirit Stones, Sect Duty tracker, and bottom nav buttons. `DisplayOrder = 10`. |
| **Data Persistence** | 🟢 Operational | `PlayerDataManager` | Server-authoritative `DataStoreService` under key `ASCEND_PlayerData_V3`. Cloud DataStore sanitization (purges corrupted FlyingSword entries). Developer arsenal injection (`Han_jueee`). |
| **Sect Facilities Suite** | 🟢 Operational | `BlacksmithManager`, `TeaHouseManager`, `SectManager`, `VendorManager`, `ArenaManager`, `AlchemyManager` | 16 functional stations in `Workspace.Functional_Stations`. Weapon refinement (+10), blade sharpening, 3 spirit teas, daily duties, dynamic market catalog, 1v1 sparring arena, and 3-slot cauldron alchemy. |