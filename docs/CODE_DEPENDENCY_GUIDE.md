# ASCEND Code Dependency Guide

## Purpose
This document explains the codebase dependency relationships for the ASCEND project. It is intended as a companion reference for tracking server/client architecture, shared configuration usage, and code connectivity.

## Scope
- Server scripts under `src/ServerScriptService/Server`
- Shared modules under `src/ReplicatedStorage/Shared`
- Client controllers under `src/StarterPlayer/StarterPlayerScripts`
- Excludes `Workspace/` content and generated Studio assets

## Document Connectivity
- Use this guide when tracing module dependencies and file connectivity.
- Pair with `docs/ARCHITECTURE_SPEC.md` for the intended architecture and system boundaries.
- Pair with `docs/CODEBASE_CLEANUP_GUIDE.md` when removing legacy or redundant weapon modules.

---

## High-Level Architecture

The ASCEND codebase follows a layered architecture:

1. **Server bootstrap**: `ServerMain.server.luau`
2. **Shared config and network layer**: `ReplicatedStorage/Shared`
3. **Server combat and cultivation core**: `WeaponManager`, `CultivationManager`, `AlchemyManager`
4. **Weapon implementations**: `FlyingSwordServer`, `GauntletServer`, `SpearServer`
5. **Server state orchestration**: `CombatStateManager`, `InventoryManager`, `PlayerDataManager`
6. **Client bootstrap and controllers**: `ClientMain.client.luau` and controllers

---

## Core Dependency Layers

### Layer 0: Server bootstrap
- `src/ServerScriptService/Server/ServerMain.server.luau`
  - Entry point on the server
  - Loads shared network, combat, cultivation, inventory, and persistence systems

### Layer 1: Shared config / network
- `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`
  - Shared network remote wrapper used widely by server and client logic
- `src/ReplicatedStorage/Shared/Configs/UIAssets.luau`
  - Central UI asset and decal registry
- `src/ReplicatedStorage/Shared/Configs/AlchemyConfig.luau`
  - Alchemy recipes, ingredients, pills, and icon lookup
- `src/ReplicatedStorage/Shared/Configs/ItemConfig.luau`
  - Item registry used by inventory and UI systems
- `src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau`
  - Cultivation progression and Qi-related values
- `src/ReplicatedStorage/Shared/Configs/AnimationConfig.luau`
  - Animation IDs and behavior settings for client attack animations
- `src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau`
- `src/ReplicatedStorage/Shared/Configs/Weapons/GauntletConfig.luau`
- `src/ReplicatedStorage/Shared/Configs/Weapons/SpearConfig.luau`
  - Weapon-specific data used by server weapon handlers

### Layer 2: Server combat & cultivation core
- `src/ServerScriptService/Server/Combat/WeaponManager.luau`
  - Central combat model manager
  - Uses `RemoteEvents` and `UIAssets`
- `src/ServerScriptService/Server/Combat/HitboxManager.luau`
  - Shared spatial hitbox query engine
- `src/ServerScriptService/Server/Cultivation/CultivationManager.luau`
  - Handles meditation, breakthroughs, health scaling, and state interactions
  - Uses `CultivationConfig`, `RemoteEvents`, and `WeaponManager`
- `src/ServerScriptService/Server/Cultivation/AlchemyManager.luau`
  - Server-only alchemy logic
  - Uses `AlchemyConfig`, `CultivationManager`, and `RemoteEvents`

### Layer 3: Weapon implementations
- `src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau`
  - Flying sword attack handler
  - Uses `FlyingSwordConfig` and `HitboxManager`
- `src/ServerScriptService/Server/Combat/Weapons/GauntletServer.luau`
  - Gauntlet combat handler
  - Uses `GauntletConfig` and `HitboxManager`
- `src/ServerScriptService/Server/Combat/Weapons/SpearServer.luau`
  - Spear combat handler
  - Uses `SpearConfig` and `HitboxManager`

### Layer 4: Server state orchestration
- `src/ServerScriptService/Server/State/CombatStateManager.luau`
  - Orchestrates combat state, cooldowns, and broadcast events
  - Uses `CultivationConfig`, `WeaponManager`, all weapon servers, `RemoteEvents`, and `CultivationManager`
- `src/ServerScriptService/Server/State/InventoryManager.luau`
  - Manages inventory data, equips, and item logic
  - Uses `ItemConfig`, `RemoteEvents`, `CultivationManager`, and `WeaponManager`
- `src/ServerScriptService/Server/State/PlayerDataManager.luau`
  - Persisted player data engine
  - Uses `CultivationConfig`, `WeaponManager`, `CultivationManager`, and `InventoryManager`

### Layer 5: Client bootstrap
- `src/StarterPlayer/StarterPlayerScripts/ClientMain.client.luau`
  - Client entry point
  - Instantiates UI and client controllers

### Layer 6: Client controllers
- `src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau`
  - Uses `UIAssets`, `CultivationConfig`, and `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau`
  - Uses `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau`
  - Uses `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/AnimationController.luau`
  - Uses `RemoteEvents`, `AnimationConfig`, and `InputController`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau`
  - Uses `ItemConfig` and `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/AlchemyController.luau`
  - Uses `AlchemyConfig`, `ItemConfig`, and `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau`
  - Uses `RemoteEvents`
- `src/StarterPlayer/StarterPlayerScripts/Client/UI/OverheadUIController.luau`
  - Overhead UI module loaded by `ClientMain`

---

---

### **`docs/CODE_DEPENDENCY_GUIDE.md`**

```markdown
# ASCEND Code Dependency Guide

## Purpose
This document maps cross-module require dependencies and RemoteEvent communication chains.

---\n
## Visual Dependency Tree

```text
ServerMain.server.luau
├─ RemoteEvents.luau
├─ CombatStateManager.luau
├─ WeaponManager.luau
├─ CultivationManager.luau
├─ InventoryManager.luau
├─ GatheringManager.luau
│  ├─ GatheringConfig.luau
│  ├─ InventoryManager.luau
│  └─ RemoteEvents.luau
├─ AlchemyManager.luau
│  ├─ AlchemyConfig.luau
│  ├─ ItemConfig.luau
│  ├─ InventoryManager.luau
│  ├─ CultivationManager.luau
│  └─ RemoteEvents.luau
└─ PlayerDataManager.luau

ClientMain.client.luau
├─ HUDController.luau
├─ InputController.luau
├─ CombatVFXController.luau
├─ AnimationController.luau
├─ InventoryController.luau
├─ AlchemyController.luau
│  ├─ AlchemyConfig.luau
│  ├─ ItemConfig.luau
│  └─ RemoteEvents.luau
├─ OverheadUIController.luau
└─ GatheringController.luau
   ├─ RemoteEvents.luau
   └─ SoundService.GatherHerbsSound

---

## How to use this guide

- Use this document when navigating the ASCEND codebase for bug fixes, feature work, or architecture updates.
- Start from the layer that matches the current task, then follow the dependency chain.
- Avoid scanning unrelated files unless the task requires cross-layer changes.
- Update this guide if new modules are added or dependencies change.
