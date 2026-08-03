# AI Repository Scanning Guide

> **Purpose**
>
> This document exists to help AI assistants efficiently navigate the ASCEND repository.
>
> **Do NOT scan the entire repository by default.**
>
> Instead, identify the current task, determine which files are relevant, and only read the minimum number of files required to complete the request.
>
> This keeps context focused, reduces unnecessary token usage, prevents outdated assumptions, and improves response quality.

---

# Core Principles

## 1. Never Scan Everything

Unless explicitly instructed by the user:

❌ Do NOT read every documentation file.

❌ Do NOT read every Luau source file.

❌ Do NOT recursively scan the repository.

Instead:

1. Understand the user's request.
2. Determine which subsystem it belongs to.
3. Read only the documentation and source files related to that subsystem.
4. Complete the task.
5. Stop scanning once sufficient context has been gathered.

---

## 2. Documentation First

Documentation always has higher priority than source code.

Before reading implementation files, always check whether a documentation file already explains the subsystem.

Preferred order:

```
Documentation
        ↓
Architecture
        ↓
Configuration
        ↓
Implementation
```

---

## 3. Follow the Current Task

Always begin with:

```
.ai/CURRENT_TASK.md
```

This file describes the current development objective.

Use it to determine which subsystem requires investigation.

---

## 4. Read the Smallest Possible Context

Only open files directly related to the user's request.

Avoid unrelated systems.

Example:

If fixing Flying Sword combat:

Read:

- FlyingSwordServer.luau
- FlyingSwordConfig.luau
- HitboxManager.luau

Do NOT read:

- AlchemyManager
- InventoryController
- UIAssets
- HUDController

unless they become necessary.

---

# Recommended Scan Order

Every investigation should roughly follow this workflow.

```
CURRENT_TASK
      │
      ▼
Relevant Documentation
      │
      ▼
Configuration Files
      │
      ▼
Implementation Files
      │
      ▼
Related Dependencies (Only if Needed)
```

---

# Repository Map

---

## Project Status

Read first when understanding the project's current state.

```
.ai/PROJECT_STATUS.md
```

Raw:

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/PROJECT_STATUS.md
```

---

## Current Development Task

Read first before performing implementation work.

```
.ai/CURRENT_TASK.md
```

Raw:

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CURRENT_TASK.md
```

---

## Previous Decisions

Read when architectural decisions need clarification.

```
.ai/DECISIONS.md
```

Raw:

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/DECISIONS.md
```

---

## Next Planned Work

Read when planning future implementation.

```
.ai/NEXT_STEPS.md
```

Raw:

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/NEXT_STEPS.md
```

---

## Changelog

Read when historical implementation tracking is needed.

```
.ai/CHANGELOG.md
```

Raw:

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CHANGELOG.md
```

---

# Documentation Index

Documentation should always be consulted before implementation files whenever possible.

---

## AI Prompt Guide

Purpose

- AI workflow
- Documentation conventions
- Repository workflow

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/AI_PROMPT_GUIDE.md
```

---

## Architecture Specification

Purpose

- Project architecture
- Service lifecycle
- Networking
- Module interactions

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ARCHITECTURE_SPEC.md
```

---

## Asset Manifest

Purpose

- UI assets
- Icons
- Uploaded assets
- Asset IDs
- Rarity assets

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ASSET_MANIFEST.md
```

---

## Combat Specification

Purpose

- Combat rules
- Weapon systems
- Hitboxes
- Damage
- Skills
- Cooldowns
- Networking

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/COMBAT_SPEC.md
```

---

## Game Design Document

Purpose

- Vision
- Core gameplay
- Progression philosophy
- Design pillars

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/GAME_DESIGN.md
```

---

## Progression Specification

Purpose

- Leveling
- Cultivation
- Stats
- Equipment
- Loot
- Alchemy

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/PROGRESSION_SPEC.md
```

---

## UI / UX Specification

Purpose

- HUD
- Inventory
- Menu layouts
- UI rules
- Design language

```
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/UI_UX_SPEC.md
```

---

# Roblox Source Code Index

Only read implementation files after documentation.

---

# Shared Configurations

Read when investigating gameplay data.

### Alchemy

```
ReplicatedStorage/Shared/Configs/AlchemyConfig.luau
```

### Animation

```
ReplicatedStorage/Shared/Configs/AnimationConfig.luau
```

### Cultivation

```
ReplicatedStorage/Shared/Configs/CultivationConfig.luau
```

### Rarity

```
ReplicatedStorage/Shared/Configs/RarityConfig.luau
```

### UI Assets

```
ReplicatedStorage/Shared/Configs/UIAssets.luau
```

### Weapon Configurations

```
FlyingSwordConfig.luau
GauntletConfig.luau
SpearConfig.luau
```

---

# Networking

Read when debugging RemoteEvents.

```
ReplicatedStorage/Shared/Network/RemoteEvents.luau
```

---

# Combat System

Read only the relevant weapon implementation.

General:

- HitboxManager.luau
- WeaponManager.luau

Flying Sword:

- FlyingSwordServer.luau
- FlyingSwordConfig.luau

Spear:

- SpearServer.luau
- SpearConfig.luau

Gauntlets:

- GauntletServer.luau
- GauntletConfig.luau

Combat State:

- CombatStateManager.luau

---

# Cultivation

Read when working on:

- Meditation
- Breakthroughs
- Qi
- Alchemy

Files:

- CultivationManager.luau
- AlchemyManager.luau
- CultivationConfig.luau
- AlchemyConfig.luau

---

# Client Controllers

Read only controllers relevant to the task.

Combat

- InputController
- AnimationController
- CombatVFXController

UI

- HUDController
- InventoryController
- OverheadUIController

Bootstrap

- ClientMain.client.luau

---

# Task-Based Scan Examples

---

## Example — Combat Bug

Read:

1. CURRENT_TASK.md
2. COMBAT_SPEC.md
3. FlyingSwordConfig
4. FlyingSwordServer
5. HitboxManager
6. WeaponManager

Stop.

---

## Example — UI Bug

Read:

1. CURRENT_TASK.md
2. UI_UX_SPEC.md
3. HUDController

Only continue if necessary.

---

## Example — Alchemy Feature

Read:

1. CURRENT_TASK.md
2. PROGRESSION_SPEC.md
3. AlchemyConfig
4. AlchemyManager

Stop.

---

## Example — Cultivation Feature

Read:

1. CURRENT_TASK.md
2. PROGRESSION_SPEC.md
3. CultivationConfig
4. CultivationManager

Stop.

---

## Example — Asset Issue

Read:

1. CURRENT_TASK.md
2. ASSET_MANIFEST.md
3. UIAssets.luau

Stop.

---

# AI Workflow

For every user request:

1. Determine the subsystem.
2. Read `CURRENT_TASK.md`.
3. Read only the documentation for that subsystem.
4. Read only the required implementation files.
5. Make the requested changes.
6. Update documentation if requested.
7. Preserve historical information—never overwrite completed logs or decisions.
8. Do not continue scanning unrelated files once enough context has been gathered.

---

# Final Rule

> **Scan with intent, not completeness.**

The repository is intentionally modular.

Your objective is **not** to understand the entire project every time.

Your objective is to understand **only the portion necessary to accurately complete the current task**, minimizing unnecessary context while maximizing accuracy and consistency.