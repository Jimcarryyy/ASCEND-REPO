---

### 8. `docs/ARCHITECTURE_SPEC.md`

```markdown
# ASCEND-V1 — TECHNICAL ARCHITECTURE SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Directory Hierarchy, Service-Controller Framework, DataStore Schemas, & Lifecycle Hooks.

---

## 1. Roblox Studio Project Directory Structure

```text
src/
├── ReplicatedStorage/
│   └── Shared/
│       ├── Configs/
│       │   ├── AlchemyConfig.luau          (Recipe definitions & spirit pill effects)
│       │   ├── CultivationConfig.luau      (45 Tiers, normalized 100 - 10,000 HP/Qi scale)
│       │   ├── ItemConfig.luau             (Master item registry for all 16 Sets / 32 Items)
│       │   ├── UIAssets.luau               (Xianxia Jade/Cream/Mahogany Palette & Asset IDs)
│       │   └── Weapons/
│       │       └── FlyingSwordConfig.luau  (Flying Sword M1 combo steps, skill damage, ranges)
│       └── Network/
│           └── RemoteEvents.luau           (RemoteEvent factory pre-creating all network remotes)
├── ServerScriptService/
│   └── Server/
│       ├── ServerMain.server.luau          (Server initialization entry point)
│       ├── Combat/
│       │   ├── HitboxManager.luau          (Spatial box query engine & knockback physics)
│       │   └── WeaponManager.luau          (Equipped 3D sword model tracker, Studio attachment reader, bounds scaler)
│       ├── Cultivation/
│       │   ├── AlchemyManager.luau         (Furnace crafting validation & ingredient inventories)
│       │   └── CultivationManager.luau     (Qi meditation G, breakthroughs B, health scaling)
│       └── State/
│           ├── CombatStateManager.luau     (Server combat state tracker & cooldown validator)
│           ├── InventoryManager.luau       (60-slot server inventory engine, on-demand RequestSync)
│           └── PlayerDataManager.luau      (DataStoreService persistence engine & 5-min auto-save)
└── StarterPlayer/
    └── StarterPlayerScripts/
        ├── ClientMain.client.luau          (Client initialization entry point)
        └── Controllers/
            ├── AlchemyController.luau      (Spirit Cauldron UI, recipe book, crafting bar)
            ├── CombatVFXController.luau    (3-wave magma crescent cleaves, sunfalls, camera shake, damage numbers)
            ├── HUDController.luau           (Light-mode Xianxia HUD dock, HP/Qi meters, hotbar)
            ├── InputController.luau         (Keybind inputs LMB, F, Q, E, R, Shift, G, B, K, L)
            └── InventoryController.luau     (Spirit Pouch 60-slot storage, rarity tinted slots, 3D viewport doll)