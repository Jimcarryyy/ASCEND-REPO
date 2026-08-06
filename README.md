# ASCEND-V1

## Unified Game Plan

This repository contains the Roblox Xianxia Sword Cultivator Action RPG.
The project is built around the **Pure Sword Cultivator Paradigm** and the current active work is governed by `.ai/CURRENT_TASK.md`.

### Core Focus
- All weapons are **Flying Swords (飞剑)**.
- Players customize combat through **Sword Art Jade Scrolls** in flexible slots: `Q`, `E`, `R`, `Shift`, `F`.
- Progression is a **45-stage cultivation curve** across five realms.
- Combat and persistence are **server-authoritative**.
- Current active phase is **Phase 6.2: Sect Affiliation, Master NPCs & World Zone Binding**.

## Current Workflow
1. Read `ASCEND.md` first.
2. Read `.ai/CURRENT_TASK.md` next.
3. Check `.ai/PROJECT_STATUS.md` for subsystem health.
4. Use `docs/` for technical specifications and implementation guidance.

## Active Phase Summary
- **Phase 6: Infrastructure, Persistence & Pure Sword Cultivator Expansion**
- **Active objective**: `.ai/CURRENT_TASK.md`
- **Key goals**:
  - Bind `Workspace.QiZones` to `QiZoneManager.luau`.
  - Build Sect selection and Master NPC systems.
  - Register all 4 Mythic Paired Sets in item and weapon config.
  - Maintain a server-authoritative combat pipeline.

## Documentation Map
### Master Project Documents
- `ASCEND.md` — Master project entry point and AI workflow.
- `.ai/CURRENT_TASK.md` — Active development task and approved scope.
- `.ai/PROJECT_STATUS.md` — Progress status and subsystem readiness.
- `.ai/DECISIONS.md` — Architecture decisions and technical agreements.
- `.ai/NEXT_STEPS.md` — Future roadmap after current task.
- `.ai/CHANGELOG.md` — Revision history.

### Core Technical Specifications
- `docs/GAME_DESIGN.md` — Vision, core gameplay, and design pillars.
- `docs/ARCHITECTURE_SPEC.md` — Project architecture, service-controller framework, and data flow.
- `docs/COMBAT_SPEC.md` — Combat rules, hitboxes, skill execution, and zero-trust server intent.
- `docs/PROGRESSION_SPEC.md` — Cultivation scaling, Qi meditation, breakthroughs, and reward pacing.
- `docs/SWORD_MASTERY_SPEC.md` — Jade Scroll system, mastery progression, and back-sword arrays.
- `docs/UI_UX_SPEC.md` — HUD and UI styling rules.
- `docs/ASSET_MANIFEST.md` — Asset catalog and model mapping.
- `docs/ROBLOX_PERFORMANCE_RULES.md` — Performance budgets and optimization rules.
- `docs/ECONOMY_AND_MARKET_SPEC.md` — Economy, market pricing, and reward sinks.
- `docs/AI_PROMPT_GUIDE.md` — AI asset generation workflow and prompt rules.
- `docs/CODEBASE_CLEANUP_GUIDE.md` — Cleanup and refactor guidance for Phase 6.2.

## How to use this README
- Use this file as the GitHub landing page.
- Use `ASCEND.md` as the authoritative master index.
- Use `.ai` documents for active phase tracking.
- Use `docs/README.md` as the docs folder entry point.

## Notes
- This project is deliberately documentation-first. Do not implement features without reading the active task and relevant spec files.
- The cleanup plan exists in `docs/CODEBASE_CLEANUP_GUIDE.md`, but active work should stay focused on the current game-plan docs and Phase 6.2 objectives.
