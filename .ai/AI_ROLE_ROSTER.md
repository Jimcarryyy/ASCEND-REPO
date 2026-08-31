# AI Role Roster — ASCEND

## Purpose
Single reference for every active AI Project/tool used on ASCEND, its role, and what it should never be asked to do. Check here before deciding "which AI handles this?" instead of re-deriving it each time.

## Active Claude Projects

| Role | Handles | Never Ask It To |
| :--- | :--- | :--- |
| **Systems Architect** | Code review, integration, bug flagging, Roblox-standard compliance | Track project-wide doc state, make balance calls |
| **Docs & Project Manager** (this project) | `.ai/` file accuracy, cross-project decision logging, status tracking | Assert code correctness, judge game balance |
| **Combat & Progression Designer** *(planned/discussed)* | Balance numbers, skill costs, TTK, reward curves | Touch `.ai/` docs or code implementation directly |

## Planned / Discussed (not yet standing up)
- **World & Terrain Builder** — terrain, zone layout, environment systems
- **VFX & Visual Polish Expert** — particles/VFX/camera feel
- **UI/UX Designer** — HUD/menu layout and flow
- **Art & Asset Prompt Director** (Claude) — generates ChatGPT/Meshy prompts for 2D/3D assets
- **Economy & Monetization Designer** *(possibly)*

## Non-Claude Tools
| Tool | Role | Notes |
| :--- | :--- | :--- |
| ChatGPT | 2D image / UI asset generation | |
| Meshy AI Pro | 3D asset generation | |
| Google AI Studio / Gemini | Bulk/volume tasks | Fallback, not a decision-maker |

## Maintenance
This file is owned by the Docs & Project Manager project. Update it when a new role/tool is added, retired, or its scope changes.