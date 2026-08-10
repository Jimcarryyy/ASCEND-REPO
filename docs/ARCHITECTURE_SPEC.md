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