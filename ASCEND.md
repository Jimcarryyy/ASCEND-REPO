# ASCEND-REPO — MASTER PROJECT DOCUMENTATION

> **Project Entry Point & Single Source of Truth**
>
> Every new AI session MUST begin by reading this document. This file is the master index for the entire project and defines where all project knowledge is located.

---

# 1. Project Overview

**ASCEND** is a lightweight, combat-focused, reward-driven Roblox action RPG that emphasizes satisfying gameplay over visual complexity.

The project is intentionally designed to:

- prioritize combat feel over excessive VFX
- use minimalist UI/HUD
- rely heavily on 2D assets
- remain highly scalable
- follow Roblox security best practices
- maintain clean software architecture
- support long-term AI-assisted development

Core Pillars

- Roblox-first performance
- Server-authoritative gameplay
- Skill-based combat
- High-dopamine progression
- Rare loot & equipment
- Minimalist UI/UX
- Long-term scalability

---

# 2. AI Startup Procedure (MANDATORY)

Every NEW chat session MUST execute the following workflow BEFORE answering any project-related question.

## STEP 1 — Read this file completely

This document is always the project entry point.

Do not skip it.

---

## STEP 2 — Read every project tracking document

These files define the current state of development.

Read them IN THIS ORDER.

### Project Status

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/PROJECT_STATUS.md

Determines:

- current phase
- completed milestones
- active development stage

---

### Current Task

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CURRENT_TASK.md

This is the MOST IMPORTANT tracking file

It defines:

- what feature is currently being built
- what the AI should focus on
- what should NOT be worked on

Always prioritize CURRENT_TASK.md over assumptions.

---

### Architectural Decisions

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/DECISIONS.md

Contains:

- architecture decisions
- conventions
- coding standards
- technical agreements

Never contradict these decisions.

---

### Next Planned Work

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/NEXT_STEPS.md

Used only after CURRENT_TASK has been completed.

Never jump ahead unless requested.

---

### Project Changelog

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/.ai/CHANGELOG.md

Read this last.

Contains:

- latest updates
- completed work
- recent changes

---

# 3. Documentation Lookup

Only read the documentation relevant to the user's request.

Never scan unnecessary files.

## Game Design

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/GAME_DESIGN.md

---

## Combat

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/COMBAT_SPEC.md

---

## Progression

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/PROGRESSION_SPEC.md

---

## UI / UX

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/UI_UX_SPEC.md

---

## Architecture

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ARCHITECTURE_SPEC.md

---

## Asset Manifest

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/ASSET_MANIFEST.md

---

## AI Prompt Guide

https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/docs/AI_PROMPT_GUIDE.md

---

# 4. AI Development Rules

The AI must NEVER:

- invent documentation
- invent folder names
- invent file names
- invent project phases
- invent architecture
- assume implementation details

If information is missing:

Say exactly which document is required.

Do not guess.

---

# 5. Coding Rules

Before writing code:

1. Read CURRENT_TASK.md.
2. Read the relevant specification.
3. Reuse existing architecture.
4. Never duplicate systems.
5. Follow Roblox best practices.
6. Keep the server authoritative.
7. Never trust the client.

When modifying existing code:

Only output the affected sections unless explicitly asked for the full file.

When creating a new file:

Output the complete file.

---

# 6. Documentation Update Rules

When the user says:

**Generate new updates**

The AI must:

1. Determine which documentation files were affected.
2. Update ONLY those files.
3. Leave unrelated documentation untouched.
4. Produce GitHub-ready Markdown.
5. Ensure the documentation matches the final agreed implementation exactly.
6. Update CHANGELOG.md if development progress changed.
7. Update CURRENT_TASK.md if the active task changed.
8. Update PROJECT_STATUS.md if a milestone was completed.
9. Update NEXT_STEPS.md if the roadmap changed.

Never rewrite every document unnecessarily.

---

# 7. Development Roadmap

Current development is intentionally incremental.

- ✅ Phase 0 — Repository Initialization
- ✅ Phase 1 — Documentation & Planning
- ⏳ Phase 2 — UI/UX Assets & Roblox Studio Layout
- ⏳ Phase 3 — Core Framework & Networking
- ⏳ Phase 4 — Combat System
- ⏳ Phase 5 — Inventory & Loot
- ⏳ Phase 6 — Gameplay Loop
- ⏳ Phase 7 — Optimization & Release

The AI should always work on the CURRENT_TASK before moving to the next phase.

---

# 8. Context Drift Prevention

The AI must treat the `.ai` folder as the project's memory.

Never rely on previous chat history.

Always rebuild context from:

1. ASCEND.md
2. PROJECT_STATUS.md
3. CURRENT_TASK.md
4. DECISIONS.md
5. NEXT_STEPS.md
6. CHANGELOG.md

Documentation is always the source of truth.

Conversation history is secondary.