# AI Repository Scanning Guide — ASCEND

## Purpose
Guidelines for navigating the ASCEND repository efficiently with zero hallucinations and minimal token consumption.

---

## Core Rules

1. **Verify Before You Speak (Rule 1):** Always fetch raw file contents in the current session before proposing edits or diagnosing bugs. Never rely on training memory or assumed patterns.
2. **Repository Is Sole Source of Truth (Rule 3):** The live GitHub repository overrides previous summaries or conversation turns.
3. **Targeted Subsystem Scans:** Never scan the entire repository by default. Identify the specific subsystem and fetch only the relevant modules:

```text
Task Request
     │
     ▼
.ai/CURRENT_TASK.md & docs/ Spec
     │
     ▼
Shared Config (ReplicatedStorage/Shared/Configs/)
     │
     ▼
Server Manager (ServerScriptService/Server/)
     │
     ▼
Client Controller (StarterPlayer/StarterPlayerScripts/Controllers/)
Subsystem Navigation Map
Combat & Sword Mechanics
docs/COMBAT_SPEC.md
src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
src/ServerScriptService/Server/Combat/HitboxManager.luau
src/ServerScriptService/Server/Combat/WeaponManager.luau
src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
src/ServerScriptService/Server/State/CombatStateManager.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
Cultivation & Qi Progression
docs/PROGRESSION_SPEC.md
src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
src/ServerScriptService/Server/Cultivation/CultivationManager.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
UI, HUD & Studio Hierarchy
docs/UI_UX_SPEC.md
src/ReplicatedStorage/Shared/Configs/UIAssets.luau
src/ReplicatedStorage/Shared/Configs/HUDSkinConfig.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau
Inventory & Sect Market
src/ReplicatedStorage/Shared/Configs/ItemConfig.luau
src/ReplicatedStorage/Shared/Configs/SectConfig.luau
src/ServerScriptService/Server/State/InventoryManager.luau
src/ServerScriptService/Server/World/VendorManager.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau