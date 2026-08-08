# ASCEND-REPO — MASTER PROJECT DOCUMENTATION

> **Project Entry Point & Single Source of Truth**  
> Every new AI session MUST begin by reading this document. This file is the master index for the entire project and defines where all project knowledge and technical specifications are located.

---

# 1. Project Overview

**ASCEND** is a lightweight, high-performance, reward-driven **Roblox Xianxia / Wuxia Sword Cultivator Action RPG** built for mobile and PC high FPS.

### Core Pillars
- **Pure Sword Cultivation (飞剑 / 剑修)**: All weapons are Flying Swords.
- **Ultra-Scaled Down MVP Architecture**: 5 Master 3D Base Sword Models (*Mortal Iron*, *Jade Dragon*, *Sun Slayer*, *Thunder Frost*, *Heavenly Void*) in `ReplicatedStorage` dynamically re-colored/tinted via `ItemConfig.luau` (`PrimaryColor`).
- **1 Master Sect Island Map ($500 \times 500$ studs max)**: Stylized Painted Low-Poly aesthetic with a 15-second walk loop connecting Spawn, Practice Dummies, Herb Gathering Meadows, Bronze Alchemy Cauldron, and Sect Sword Altar.
- **Normalized $100 \rightarrow 10,000$ HP/Qi Scale**: 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*) across 45 Sub-Stage Orders.
- **Traditional Xianxia Light-Mode UI Palette**: `#1D4533` Jade Green, `#F7EAE0` Warm Cream, `#F9D2BA` Peach Accent, and `#5E3122` Mahogany Wood.
- **Server-Authoritative Engine**: All hitboxes, state queries, alchemy brewing, and DataStore persistence (`DataStoreService`) are validated strictly on the server.

---

# 2. AI Startup Procedure (MANDATORY)

Every NEW chat session MUST execute the following workflow BEFORE answering any project-related question or writing code:

## STEP 1 — Read this file completely
This document is always the project entry point. Do not skip it.

## STEP 2 — Read every project tracking document in order
1. https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/PROJECT_STATUS.md
2. https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CURRENT_TASK.md
3. https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/DECISIONS.md

---

# 3. Development Roadmap

- ✅ **Phase 1** — Documentation, Architecture & Specifications
- ✅ **Phase 2** — UI/UX Assets, Light-Mode Xianxia Palette & Studio Layout
- ✅ **Phase 3** — Core Framework & Server-Authoritative Networking
- ✅ **Phase 4** — Combat System & Hitbox Query Engine
- ✅ **Phase 5** — Cultivation Engine, Qi Meditation, Alchemy & Heavenly Tribulation
- ✅ **Phase 6** — Codebase Refactoring, DataStore Persistence, Normalized Stat Scale & Studio 3D Attachment Engine
- ⏳ **Phase 7** — Core Gameplay Loop, World Gathering & Monetization Integration `(In Progress ~15%)`
  - ⏳ Task 7.1A: Zone 1 Herb Gathering Node System (`Nine-Leaf Grass` & `Dragon Lotus`)
  - ⏳ Task 7.1B: Sect Sword Altar Gacha Engine (Spirit Stone rolling for Flying Swords)
  - ⏳ Task 7.1C: Zone Boundary Teleportation Portal & Boat System