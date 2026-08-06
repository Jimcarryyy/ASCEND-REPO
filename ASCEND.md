# ASCEND-REPO — MASTER PROJECT DOCUMENTATION

> **Project Entry Point & Single Source of Truth**  
> Every new AI session MUST begin by reading this document. This file is the master index for the entire project and defines where all project knowledge and technical specifications are located.

---

# 1. Project Overview

**ASCEND** is a lightweight, combat-focused, reward-driven **Roblox Xianxia / Wuxia Sword Cultivator Action RPG** built for mobile and PC high performance.

The project is intentionally designed to:
- **Focus on Pure Sword Cultivation (飞剑 / 剑修)**: All weapons are Flying Swords. Players collect, equip, and upgrade **Sword Art Jade Scrolls** into `Q`, `E`, `R`, `Shift`, and `F` skill slots for total sandbox build freedom.
- **Visual Prestige & 3D Floating Back-Sword Arrays**: As player level and Sword Art Mastery increase (Rank 1 $\rightarrow$ 10), the server automatically spawns 1, 3, 5, or 7 hovering back-swords behind the player's back.
- **45-Stage High-Number Dopamine Curve**: Features 5 Major Realms (*Qi Condensation, Foundation Establishment, Golden Core, Nascent Soul, Spirit Severing*), each containing 9 Sub-Stage Orders (45 Tiers total). Qi capacity scales up to **$50,000,000,000$ (50 Billion)** with proportional Health scaling ($500 \rightarrow 25,000,000$ HP).
- **Server-Authoritative Gameplay**: All hitboxes, cooldowns, state changes, alchemy brewing, and data saving (`DataStoreService`) are strictly validated on the server.
- **Sharp Dark Obsidian UI/UX**: In-combat HUD (`#0C0E14` background, `#121520` cards, `#1E2330` sharp 1.5px border stroke, `FredokaOne` font, pure white text) and out-of-combat modals with 3D character viewport dolls.

### Core Pillars
- Roblox-First Performance & Mobile 60 FPS Optimization
- Server-Authoritative Zero-Trust Combat Engine
- Pure Sword Cultivation & Flexible Jade Scroll Builds
- High-Dopamine 45-Stage Progression & 50B Qi Scale
- 3D Floating Back-Sword Arrays & Mythic Weapon Skins
- Dark Obsidian & FredokaOne Aesthetic System
- Long-Term AI-Assisted Architecture

---

# 2. AI Startup Procedure (MANDATORY)

Every NEW chat session MUST execute the following workflow BEFORE answering any project-related question or writing code.

## STEP 1 — Read this file completely
This document is always the project entry point. Do not skip it.

---

## STEP 2 — Read every project tracking document
These files define the current state of development. Read them IN THIS ORDER:

### 1. Project Status
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/PROJECT_STATUS.md  
*Determines current phase, completed milestones, and subsystem health.*

---

### 2. Current Task
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CURRENT_TASK.md  
*This is the MOST IMPORTANT tracking file. It defines active objectives and what should NOT be worked on.*

---

### 3. Architectural Decisions
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/DECISIONS.md  
*Contains architecture decisions, conventions, coding standards, and technical agreements.*

---

### 4. Next Planned Work
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/NEXT_STEPS.md  
*Used only after CURRENT_TASK has been completed.*

---

### 5. Project Changelog
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CHANGELOG.md  
*Contains latest updates, completed work, and recent changes.*

---

# 3. Documentation Index & Specifications Lookup

Only read the documentation relevant to the user's request. Never scan unnecessary files.
## 📘 Docs Folder Entry Point
`docs/README.md` — Use this file first when navigating the documentation directory.

---
## 📖 Game Design
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/GAME_DESIGN.md  
*Executive vision, core pillars, gameplay loop, and high-level design.*

---

## 🗡️ Sword Mastery & Jade Scriptures (NEW)
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/SWORD_MASTERY_SPEC.md  
*Pure Sword Cultivator paradigm, Jade Scroll skills, Sword Mastery levels, 3D Floating Back-Sword Arrays, and 4 Paired Mythic Sets.*

---

## ⚔️ Combat Specification
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/COMBAT_SPEC.md  
*Server-authoritative combat engine, flexible skill hotbar (`Q`, `E`, `R`, `Shift`, `F`), hitboxes, and defensive mechanics.*

---

## 📈 Cultivation & Progression
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/PROGRESSION_SPEC.md  
*45-Stage Realm engine, 50B Qi cap, Qi Meditation (`Hotkey G`), Heavenly Tribulation (`Hotkey B`), and Alchemy recipes.*

---

## 🖥️ UI / UX Specification
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/UI_UX_SPEC.md  
*Dark Obsidian design system, sharp 90° corners, `FredokaOne` typography, bottom HUD panel, and Spirit Pouch modal.*

---

## 🏗️ Architecture Specification
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ARCHITECTURE_SPEC.md  
*Directory structure (`src/`), Service-Controller framework, network remotes, and `PlayerDataManager.luau` DataStore schema.*

---

## 📦 Asset Manifest
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ASSET_MANIFEST.md  
*3D Paired Mythic Sets manifest, Roblox decal IDs, Rarity color tiers, and Audio SFX registry.*

---

## 🎨 AI Prompt Guide
https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/AI_PROMPT_GUIDE.md  
*Prompts and instructions for Gemini concept art generation and Meshy AI 3D model conversion.*

---

# 4. AI Development Rules

The AI must NEVER:
- invent documentation or specification rules
- invent folder or file paths outside the repository structure
- invent project phases or contradict `CURRENT_TASK.md`
- rewrite historical completion records in `CHANGELOG.md`
- assume implementation details without reading relevant source files

If information is missing:
- Say exactly which document or source file is required. Do not guess.

---

# 5. Coding Rules

Before writing code:
1. Read `CURRENT_TASK.md`.
2. Read the relevant specification in `docs/`.
3. Reuse existing architecture (`RemoteEvents.luau`, `WeaponManager.luau`, `CombatStateManager.luau`).
4. Maintain strict server authority—never trust the client.
5. Follow Roblox software engineering best practices.

When modifying existing code:
- Only output the affected sections unless explicitly asked for the full file.

When creating a new file:
- Output the complete, production-grade file in a single copyable block.

---

# 6. Documentation Update Rules

When the user requests **"Generate new updates"**:
1. Determine which documentation files were affected by recent progress or design shifts.
2. Update ONLY those affected files.
3. Preserve all historical completion logs—never overwrite completed milestones.
4. Produce complete, 100% copyable GitHub-ready Markdown blocks.
5. Ensure exact alignment across `.ai/` tracking files and `docs/` specifications.

---

# 7. Development Roadmap

- ✅ **Phase 0** — Repository Initialization & Infrastructure
- ✅ **Phase 1** — Documentation, Architecture & Specifications
- ✅ **Phase 2** — UI/UX Assets, Dark Obsidian Palette & Studio Layout
- ✅ **Phase 3** — Core Framework & Server-Authoritative Networking
- ✅ **Phase 4** — Combat System & Hitbox Query Engine
- ✅ **Phase 5** — Cultivation Engine, Qi Meditation, Alchemy & Heavenly Tribulation
- ⏳ **Phase 6** — Infrastructure, DataStore Persistence, World Zones & Pure Sword Cultivator System `(In Progress ~82%)`
  - ✅ Task 6.1A: `DataStoreService` Player Data Persistence (`PlayerDataManager.luau`)
  - ✅ Task 6.1B: 45-Stage High-Number Scale (50B Qi Cap) & Natural Carryover
  - ✅ Task 6.1C: Sharp Dark Obsidian HUD Overhaul & Local Overhead Cleanup
  - ✅ Task 6.1D: 3D Asset Production (4 Paired Mythic Sets & 3D Floating Back-Crests)
  - ⏳ Task 6.2: World Qi Zones, Sect Affiliation & Master NPCs (`Pending`)
- ⏳ **Phase 7** — Open World, Beast AI & Public Release

---

# 8. Context Drift Prevention

The AI must treat the `.ai` folder and `ASCEND.md` as the project's single source of truth. Never rely on previous chat memory when documentation can answer the question.

Always build context from:
1. `ASCEND.md` (Master Entry Point)
2. `.ai/PROJECT_STATUS.md`
3. `.ai/CURRENT_TASK.md`
4. `.ai/DECISIONS.md`
5. `.ai/NEXT_STEPS.md`
6. `.ai/CHANGELOG.md`

Documentation is the authoritative source of truth. Conversation history is secondary.