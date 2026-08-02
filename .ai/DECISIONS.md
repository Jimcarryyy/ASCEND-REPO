# Architectural Decision Records (ADR)

> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md

---

## ADR-001: Strict Server Authority
* **Status:** Accepted
* **Context:** Exploiting is prevalent in Roblox action games.
* **Decision:** The server executes all hitbox queries, damage calculations, cooldown verifications, and stat updates. The client only sends input intents.

## ADR-002: Modular Service-Controller Pattern
* **Status:** Accepted
* **Context:** Need a scalable, maintainable codebase without tight module coupling.
* **Decision:** Implement single-responsibility Service scripts on the Server and Controller scripts on the Client using custom Signal events.

## ADR-003: Distinct HUD vs. Modal UI Design
* **Status:** Accepted
* **Context:** Heavy UI clutter ruins combat focus.
* **Decision:** In-combat HUD will remain clean, minimal, and lightweight. Handcrafted fantasy art will be reserved exclusively for full-screen menu modals.

## ADR-004: Weapon Archetype System
* **Status:** Accepted
* **Context:** Combat needs varied playstyles without duplicating code.
* **Decision:** Base weapon logic will be handled by a unified combat service, reading individual weapon profile configurations (Katana, Greatsword, Daggers, Staff).

## ADR-005: Multi-File Specification Engine (docs/)
* **Status:** Accepted
* **Context:** A single giant GDD file becomes unmaintainable for AI context resolution.
* **Decision:** Separate game design into specialized markdown files in `docs/` (`GAME_DESIGN`, `COMBAT_SPEC`, `PROGRESSION_SPEC`, `UI_UX_SPEC`, `ARCHITECTURE_SPEC`).

## ADR-006: ProfileService for Data Persistence
* **Status:** Accepted
* **Context:** Data corruption and session duplication must be prevented.
* **Decision:** Use ProfileService for atomic player data writes, session locking, and automatic retry management.

## ADR-007: Intent-Execution Network Architecture
* **Status:** Accepted
* **Context:** Clients should never dictate game state to the server.
* **Decision:** Client sends intent signals (`AttackIntent`, `DodgeIntent`). The server validates state and executes spatial Shapecasts.

## ADR-008: Janitor Lifecycle Management
* **Status:** Accepted
* **Context:** Transient listeners and connections cause memory leaks in Roblox games.
* **Decision:** Use Janitor utility class across all Services and Controllers to handle garbage collection on cleanup.

## ADR-009: 2D Asset Pipeline & AI Prompt Engine
* **Status:** Accepted
* **Context:** UI assembly requires standardized 2D assets before Studio layout construction.
* **Decision:** Establish `docs/ASSET_MANIFEST.md` for complete asset inventory and `docs/AI_PROMPT_GUIDE.md` for exact copy-paste AI prompt generation.