# ASCEND-REPO — DOCUMENTATION INDEX

> Technical Specifications Directory
> Master Entry Point: `ASCEND.md`

## Technical Specification Index

| Document | Purpose & Scope | Status |
| :--- | :--- | :--- |
| `ASCEND.md` | Master Project Entry Point & Startup Workflow | 🟢 Active |
| `GAME_DESIGN.md` | Azure Cloud Realm Map, Low-Cortisol Loop & Monetization Strategy | 🟢 Active |
| `ARCHITECTURE_SPEC.md` | Directory Hierarchy, Services & Remote Network Graph | 🟢 Active |
| `COMBAT_SPEC.md` | Universal 1-Pack Skillset, Hitboxes & Magma Cleaves | 🟢 Active |
| `PROGRESSION_SPEC.md` | Normalized 45-Stage Realm Progression (100–10,000 HP/Qi) | 🟢 Active |
| `UI_UX_SPEC.md` | Light-Mode Palette, Custom Xianxia HUD, Azure Cloud Panels | 🟢 Active |
| `ASSET_MANIFEST.md` | 32 Equipment Items, 12 2D PNG Icons, Vintage Herbs & HUD Skins | 🟢 Active |
| `CODEBASE_CLEANUP_GUIDE.md` | Codebase Pruning Audit & Dead Code Guidelines | 🟢 Active |
| `AI_PROMPT_GUIDE.md` | Stylized Low-Poly 3D Generation & 2D Icon Prompts | 🟢 Active |
| `ROBLOX_PERFORMANCE_RULES.md` | 60 FPS Mobile Performance & Memory Limits | 🟢 Active |
| `CODE_DEPENDENCY_GUIDE.md` | Full Require Graph & Cross-Module References | 🟢 Active |
| ~~`SWORD_MASTERY_SPEC.md`~~ | Deprecated for V1 MVP (replaced by Realm Engine) | 🔴 Deprecated |
| ~~`ECONOMY_AND_MARKET_SPEC.md`~~ | Deprecated for V1 MVP (replaced by Gacha & Spirit Stones) | 🔴 Deprecated |

## Version 1 Architecture Summary
*(Updated 2026-08-20)*

1. **Server Core:** DataStore V2 persistence, 10-Realm / 90-Order progression, 3-slot manual alchemy, gathering RNG, Sect economy, R6 zone mob AI, 1v1 same-realm sparring arena.
2. **Client Hybrid UI:** Studio Explorer frames driven by dedicated Luau controllers — responsive scaling, unified Dark Obsidian/Gold aesthetics, cross-platform touch support.