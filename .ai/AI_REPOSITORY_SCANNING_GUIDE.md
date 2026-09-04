# AI Repository Scanning Guide — ASCEND

## Purpose
Guidelines for navigating the ASCEND repository efficiently with zero hallucinations, minimal token consumption, and accurate cross-system tracing.

---

## Core Rules

1. **Verify Before You Speak (Rule 1):** Always inspect live repository files in the current session before proposing code edits, diagnosing bugs, or updating specifications.
2. **Repository Is Sole Source of Truth (Rule 3):** The live GitHub codebase outranks previous conversational summaries, local notes, or historical document snapshots.
3. **Targeted Subsystem Scans (Rule 7):** Do not scan unrelated files. Route tasks directly to their respective architectural layer:

```text
Task Request
     │
     ▼
.ai/CURRENT_TASK.md & Specific docs/ Spec
     │
     ▼
Shared Configs (src/ReplicatedStorage/Shared/Configs/)
     │
     ▼
Server Managers (src/ServerScriptService/Server/)
     │
     ▼
Client Controllers (src/StarterPlayer/StarterPlayerScripts/Controllers/)
Subsystem Navigation Map
1. Combat, Sword Arts & Posture
Spec: docs/COMBAT_SPEC.md
Config: src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
Server:
src/ServerScriptService/Server/Combat/HitboxManager.luau
src/ServerScriptService/Server/Combat/WeaponManager.luau
src/ServerScriptService/Server/Combat/Weapons/FlyingSwordServer.luau
src/ServerScriptService/Server/State/CombatStateManager.luau
Client:
src/StarterPlayer/StarterPlayerScripts/Controllers/InputController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/CombatVFXController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/FocusTargetController.luau
2. Cultivation, Dantian & Breakthroughs
Spec: docs/PROGRESSION_SPEC.md
Config: src/ReplicatedStorage/Shared/Configs/CultivationConfig.luau
Server: src/ServerScriptService/Server/Cultivation/CultivationManager.luau
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/CultivationController.luau
3. Sect Hub Facilities & World Stations (Lower Tier)
Spec: docs/GAME_DESIGN.md
Configs: SectConfig.luau, ItemConfig.luau
Blacksmithing:
Server: src/ServerScriptService/Server/World/BlacksmithManager.luau
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/BlacksmithController.luau
Spirit Tea Pavilion:
Server: src/ServerScriptService/Server/World/TeaHouseManager.luau
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/TeaHouseController.luau
Training Grounds & Sparring:
Workspace: Workspace/Functional_Stations/Sect_TrainingGround/TrainingDummy_*/ImmortalDummyHandler.server.luau
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/SparringGuidanceController.luau
Starter Guidance:
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/StarterGuideController.luau
Market & Vendors:
Server: src/ServerScriptService/Server/World/VendorManager.luau
Client: src/StarterPlayer/StarterPlayerScripts/Controllers/MarketController.luau
4. Alchemy & World Gathering
Configs: AlchemyConfig.luau, GatheringConfig.luau, ItemConfig.luau
Server:
src/ServerScriptService/Server/Cultivation/AlchemyManager.luau
src/ServerScriptService/Server/World/GatheringManager.luau
Client:
src/StarterPlayer/StarterPlayerScripts/Controllers/AlchemyController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/GatheringController.luau
5. UI, HUD & Studio Hierarchy
Spec: docs/UI_UX_SPEC.md
Configs: UIAssets.luau, HUDSkinConfig.luau
Client:
src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/SkillBarController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/OverheadUIController.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/QuestTrackerController.luau
src/StarterPlayer/StarterPlayerScripts/DeWidth.client.luau
Rule Enforcement:
Runtime Instance.new UI creation in client scripts is prohibited (ADR-041).
Typography must use Bangers with black UIStroke for headers and Fundamento for body copy (ADR-042).
DisplayOrder hierarchy must be respected (ADR-043).
code
Code
---

### Confirmation of Repository-Wide Alignment

The `.ai/` suite is now fully synchronized with:
1. **The live code:** 16 managers, 20 controllers, 22 remotes, and `ImmortalDummyHandler.server.luau`.
2. **The 183 session logs:** The active Desktop HUD rebuild milestone, the resolved server crashes (`TeaHouseManager`, `BlacksmithManager`), the 3-tier Sect world architecture, and the mandatory `Bangers` / `Fundamento` typography standards.