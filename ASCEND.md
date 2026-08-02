# ASCEND-REPO V1 — MASTER PROJECT DOCUMENTATION

> **Project Entry Point & Source of Truth**  
> All project architecture, design goals, status, and AI session workflows strictly originate from this document.

---

## 1. Executive Summary

**ASCEND-V1** is a lightweight, combat-focused, reward-driven Roblox action-progression game. The game prioritizes high-frequency replayability, smooth fluid movement, strict combat mechanics, rare equipment drops, and deep weapon progression over complex visual effects or heavy graphical environments.

### Core Project Pillars
* **Roblox-First Performance:** Optimized for high FPS on low-end and mobile devices. Minimalist VFX and low visual clutter.
* **Combat & Skill Mastery:** Responsive action combat where player skill, timing, and weapon loadouts drive success.
* **Loot & Progression System:** High-dopamine rare drops, stat scaling, weapon collection, and equipment enhancements.
* **Server-Authoritative Design:** Zero trust in the client. All combat calculations, damage, loot drops, cooldowns, and inventory state are validated exclusively on the server.
* **Distinct Visual Philosophy:** Ultra-minimalist, lightweight HUD during active gameplay combined with handcrafted fantasy artwork panels for menus and inventory.

---

## 2. Documentation Architecture

Every development session must query these raw links sequentially to rebuild project context:

### System Tracking (.ai/)
1. **Master Entry Point:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md
2. **Current Active Task:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/.ai/CURRENT_TASK.md
3. **Project Status & Lifecycle Phase:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/.ai/PROJECT_STATUS.md
4. **Architectural Decision Records:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/.ai/DECISIONS.md
5. **Project Changelog:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/.ai/CHANGELOG.md
6. **Next Milestones & Step Roadmap:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/.ai/NEXT_STEPS.md

### Game Specifications & Master Plan (docs/)
1. **Master Game Design Document (GDD):**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/GAME_DESIGN.md
2. **Combat System Specification:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/COMBAT_SPEC.md
3. **Progression & Loot Specification:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/PROGRESSION_SPEC.md
4. **UI/UX Wireframe & Flow Specification:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/UI_UX_SPEC.md
5. **Technical Architecture & Data Schemas:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/ARCHITECTURE_SPEC.md
6. **Master 2D Asset Manifest:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/ASSET_MANIFEST.md
7. **Complete AI Asset Prompt Guide:**  
   https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/docs/AI_PROMPT_GUIDE.md

---

## 3. Development Phase Roadmap

* [x] **Phase 0: Repository Initialization & Master Documentation**
* [x] **Phase 1: Master Game Plan & System Specifications (docs/)**
* [ ] **Phase 2: Minimalist HUD & UI/UX Hierarchy in Roblox Studio**
* [ ] **Phase 3: Core Luau Framework, Network Pipeline & DataSync**
* [ ] **Phase 4: Server-Authoritative Combat Engine & Hitbox Pipeline**
* [ ] **Phase 5: Inventory, Equipment, & Drop Tables**
* [ ] **Phase 6: Prototype Arena, Enemy AI, & Gameplay Loop**
* [ ] **Phase 7: Optimization, Security Audit, & Public Release**
