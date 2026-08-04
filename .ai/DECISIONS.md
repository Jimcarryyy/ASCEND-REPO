# Architectural Decision Records (ADR)

> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md

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

## ADR-010: Server-Authoritative Alchemy & Crafting Engine
* **Status:** Accepted
* **Context:** Alchemy pill crafting and consumption impact player health, Qi, and damage stats. Client-side crafting calculations would allow item duplication and stat spoofing.
* **Decision:** Implement `AlchemyManager.luau` strictly on the server. The client sends `AlchemyAction` intents (`CraftPill`, `ConsumePill`). The server verifies ingredient quantities, processes timed crafting loops, rolls success probabilities, and applies consumable stat buffs.

## ADR-011: Pre-Created Network Remote Registry
* **Status:** Accepted
* **Context:** Clients timing out while waiting for server managers to initialize remote event instances.
* **Decision:** Update `RemoteEvents.luau` to pre-create all registered `RemoteEvent` instances automatically during `RemoteEvents.Init()` on server startup, guaranteeing remotes exist before any client script connects.


# Architecture Decision Log

This document records key architectural decisions made during the development of ASCEND.

---

## [015] - 2026-08-04: Heavenly Tribulation Lightning Event Loop Architecture
* **Context**: Realm breakthroughs required a Xianxia tribulation test rather than instant realm advancement.
* **Decision**: Implemented `StartTribulationSequence` inside `CultivationManager.luau`. When a player presses `B` at `CurrentQi >= MaxQi`, movement is locked, a dedicated floating pose is played, and an overhead storm cloud is spawned. The server executes a multi-wave lightning loop with telegraphed ground warning rings before firing server-authoritative damage. Surviving all waves grants the new realm tier and resets Qi.
* **Consequences**: Ensures breakthroughs are server-authoritative, dramatic, and skill/item dependent.

## [016] - 2026-08-04: 100% Code-Driven Dark Obsidian UI Architecture
* **Context**: UI panels required high usability, clean typography, responsive layout, and a modern game interface feel without relying on external image assets or textures.
* **Decision**: Built `InventoryController.luau` and `AlchemyController.luau` entirely programmatically using Luau UI primitives (`Frame`, `TextLabel`, `TextButton`, `UIStroke`, `UIPadding`, `UIListLayout`, `UIGridLayout`). Enforced a Dark Obsidian color palette (`#0C0E14` main window, `#121520` panels/cards, `#1E2330` borders), `Enum.Font.FredokaOne` font styling, sharp 90° corners (0px border-radius), and zero text emojis.
* **Consequences**: Complete independence from external image assets, zero texture loading delay, clean responsive scaling, and instant styling customizability through code variables.

## [017] - 2026-08-04: Server-Authoritative Inventory & Item System
* **Context**: Consumable Spirit Pills, crafting herbs, currencies, and weapons required server-backed storage and validation.
* **Decision**: Created `ItemConfig.luau` (Master item registry) and `InventoryManager.luau` (30-slot server inventory engine). Item consumption (Pills healing HP / restoring Qi), weapon equips, slot swapping, and item dropping are validated and executed on the server before syncing to clients via `UpdateInventory` remote.
* **Consequences**: Prevents client-side item duplication or stat spoofing.

## [018] - 2026-08-04: Attachment-Based Weapon Grip Alignment
* **Context**: 3D weapons (*FlyingSword*, *Gauntlet*, *Spear*) needed to attach cleanly to player character hands without hardcoded offsets.
* **Decision**: `WeaponManager.luau` uses `RightGripAttachment` CFrame alignment (`motor.C0 = armAtt.CFrame` and `motor.C1 = weaponAtt.CFrame`). If an asset or procedural placeholder lacks an attachment, the server automatically inserts `RightGripAttachment` with `Position(0, 0, -2)` and `Orientation(0, 90, 90)`.
* **Consequences**: Guarantees perfect hand grip alignment for any 3D model or placeholder object.

## [019] - 2026-08-04: Real-Time ViewportFrame Character Doll Sync
* **Context**: The Character Hub panel required displaying the player's 3D avatar and active equipment.
* **Decision**: `InventoryController.luau` uses a `ViewportFrame` containing a cloned `WorldModel` of the player's character. Heavy scripts and sounds are stripped from the clone for performance. When weapons or gear are equipped, `Update3DDoll()` re-clones the character, instantly reflecting the equipped 3D weapon in the UI.
* **Consequences**: Provides real-time visual feedback of player avatar customization.