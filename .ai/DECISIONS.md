# Architecture Decision Log

This document records key architectural decisions made during the development of ASCEND.

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

## ADR-004: Pure "Sword Cultivator" (剑修) Paradigm
* **Status:** Accepted (Updated 2026-08-06)
* **Context:** Multi-weapon class locks (swords, gauntlets, spears) create rigid, repetitive gameplay and complicate animation/asset pipelines.
* **Decision:** Pivot 100% to **Pure Sword Cultivation**. All equipped weapons are **Flying Swords (飞剑)**. Skills (`Q`, `E`, `R`, `Shift`, `F`) are driven by freely collectible, upgradeable **Sword Art Jade Scrolls**. Players customize their builds by equipping different skill scrolls and prestige 3D Sword Skins.

## ADR-005: Multi-File Specification Engine (docs/)
* **Status:** Accepted
* **Context:** A single giant GDD file becomes unmaintainable for AI context resolution.
* **Decision:** Separate game design into specialized markdown files in `docs/` (`GAME_DESIGN`, `COMBAT_SPEC`, `PROGRESSION_SPEC`, `UI_UX_SPEC`, `ARCHITECTURE_SPEC`, `SWORD_MASTERY_SPEC`).

## ADR-006: DataStore Persistence Engine
* **Status:** Accepted (Updated 2026-08-06)
* **Context:** Player cultivation realm, Qi, inventory slots, equipped sword skin, and sect must persist reliably across server sessions.
* **Decision:** Implemented `PlayerDataManager.luau` using `DataStoreService` with 3-attempt `pcall` retry wrappers, 5-minute background auto-saving, and `game:BindToClose()` emergency shutdown execution.

## ADR-007: Intent-Execution Network Architecture
* **Status:** Accepted
* **Context:** Clients should never dictate game state to the server.
* **Decision:** Client sends intent signals (`AttackIntent`, `DodgeIntent`). The server validates state and executes spatial Shapecasts.

## ADR-008: Janitor Lifecycle Management
* **Status:** Accepted
* **Context:** Transient listeners and connections cause memory leaks in Roblox games.
* **Decision:** Use Janitor utility class across all Services and Controllers to handle garbage collection on cleanup.

## ADR-009: 2D/3D Asset Pipeline & AI Generation Engine
* **Status:** Accepted (Updated 2026-08-06)
* **Context:** Creating high-quality Xianxia 3D models and UI icons required a fast, cost-effective pipeline.
* **Decision:** Use Gemini/Recraft for isolated 2D concept art $\rightarrow$ convert to 3D via Meshy AI (Standard Mode, 20 Credits) $\rightarrow$ reduce polycount to ~3,000 triangles $\rightarrow$ import `.FBX` to Roblox Studio.

## ADR-010: Server-Authoritative Alchemy & Crafting Engine
* **Status:** Accepted
* **Decision:** Implement `AlchemyManager.luau` strictly on the server. The client sends `AlchemyAction` intents. The server verifies ingredients, processes timed crafting loops, rolls success probabilities, and applies consumable stat buffs.

## ADR-011: Pre-Created Network Remote Registry
* **Status:** Accepted
* **Decision:** Update `RemoteEvents.luau` to pre-create all registered `RemoteEvent` instances automatically during `RemoteEvents.Init()` on server boot.

## [020] - 2026-08-06: 45-Stage High-Number Scale (50 Billion Qi Cap)
* **Context:** Cultivation progression felt too fast with small numbers.
* **Decision:** Re-architected `CultivationConfig.luau` into 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*), each with 9 Orders (45 Tiers total). Max Qi scales to 50 Billion, and MaxHealth scales proportionally ($500 \rightarrow 25,000,000$ HP).

## [021] - 2026-08-06: 3D Floating Back-Crest Array & Cosmetic Pair System
* **Context:** Players need visual prestige indicators reflecting their cultivation rank.
* **Decision:** Paired each Mythic 3D Sword with a matching **3D Floating 5-Blade Back-Crest Array** hovering behind `UpperTorso` (`BodyBackAttachment`). As player level/mastery increases, `WeaponManager.luau` dynamically attaches 1, 3, 5, or 7 hovering back-blades!