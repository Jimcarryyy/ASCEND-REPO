# ASCEND — Technical Documentation & Architecture Index

## 1. Project Overview
**ASCEND** is a high-performance Roblox Xianxia (Eastern Immortal Hero) Action RPG built on the Roblox R6 avatar rig. The game features pure martial sword combat, exponential 10-realm internal cultivation, authentic sect daily life, deep profession systems (Alchemy, Blacksmithing, Tea Brewing, Gathering), and clean network synchronization.

- **Avatar Baseline:** Roblox R6 Standard Rig (Rigid joint hierarchy, snappier martial arts keyframing, zero ragdoll jitter, 60 FPS mobile performance).
- **Master DataStore Key:** `ASCEND_PlayerData_V2` (Session-locked with 5-minute auto-save and disconnect flushes).
- **Network Core:** 22 centralized `RemoteEvent` instances managed via `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`.
- **UI Architecture:** Studio-Authoritative `StarterGui` instances. Scripting controllers strictly connect logic, state, and tweens; runtime programmatic UI creation via `Instance.new` is strictly prohibited.
- **Active Development Phase:** Phase 8.2 — Studio Desktop HUD Overhaul & UI Connection.

---

## 2. Core Visual & Typography Standards

### 2.1 Standardized Typography (ADR-042)
All user interfaces, billboards, and world signs strictly adhere to the two-font project typography system:
- **Headers, Titles, Station Billboards, and NPC Names:** `Enum.Font.Bangers` with a mandatory solid black `UIStroke` (`Thickness = 1.5 - 2.0`, `Color = Color3.fromRGB(0, 0, 0)`).
- **Body Copy, Descriptions, Quest Details, and Dialogue:** `Enum.Font.Fundamento`.

### 2.2 UI Palette System (Dark Obsidian & Antique Gold)
- **Master Modal Canvas:** `#111827` (`Color3.fromRGB(17, 24, 39)`)
- **Card / Surface Canvas:** `#1C2638` (`Color3.fromRGB(28, 38, 56)`)
- **Primary Borders & Trims:** `#C49A4A` (`Color3.fromRGB(196, 154, 74)`) / `#8B6B32` (`Color3.fromRGB(139, 107, 50)`)
- **Primary Header Text (Warm Ivory):** `#F1E8D2` (`Color3.fromRGB(241, 232, 210)`)
- **Muted Subtitle Text:** `#9CA3AF` (`Color3.fromRGB(156, 163, 175)`)
- **Health / Vitality Accent:** `#10B981` (`Color3.fromRGB(16, 185, 129)`)
- **Qi / Spiritual Energy Accent:** `#3B82F6` (`Color3.fromRGB(59, 130, 246)`)
- **Sword Intent Accent:** `#F59E0B` (`Color3.fromRGB(245, 158, 11)`)
- **Danger / Guard-Break Accent:** `#EF4444` (`Color3.fromRGB(239, 68, 68)`)

---

## 3. World Layout: 3-Tier Sect Architecture (ADR-044)

The primary world hub (Zone 1: Jade Pure Sect) is organized into three stepped elevation layers:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ TIER 3: UPPER SOVEREIGN PALACE                                              │
│ - Grand Sect Palace Hall (Black Roof Tile Aesthetic)                        │
│ - Supreme Sect Leader, Grand Sword Elder Liang                              │
│ - Top 7 Pillars of the Sect (Elite Lore Masters)                            │
│ - Palace Maids, Elite Male & Female Armored Sect Guards                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 2: MIDDLE SPIRITUAL DAO SANCTUARY                                      │
│ - Elevated Sword Altar (Gacha & Blade Attunement, R6-Calibrated Stairs)     │
│ - Inner Disciple Courtyards & Cultivation Pavements                         │
├─────────────────────────────────────────────────────────────────────────────┤
│ TIER 1: LOWER SERVICE & TRAINING GROUNDS                                    │
│ - Blacksmith Forge (Madame Tie / Master Anvil: +10 Refinement & Sharpening) │
│ - Spirit Tea Pavilion (Xiao Ling: 3 Brews, Timed Buffs & Recovery)          │
│ - Sect Training Grounds (Instructor Wu, 3 Ironwood Dummies, DPS Tracking)   │
│ - Sect Starter Guide Pavilion (Elder Qing: 4-Tab Interactive Manual)        │
│ - Bronze Alchemy Cauldron (Master Shen: 3-Slot Herb Minigame)               │
│ - Notice Board (Deacon Zhao: 3-Tier Daily Duties & Bounty Submissions)       │
│ - Sect Treasury & Market (Steward Jin: Weapon Catalog & Trading)            │
│ - 2.0x Qi Sakura Grove, Practicing Outer Disciples, Wilderness Portal       │
└─────────────────────────────────────────────────────────────────────────────┘
4. Documentation Index
Document	Path	Scope & Focus
Architecture Specification	docs/ARCHITECTURE_SPEC.md	Full codebase architecture: 16 server managers, 20 client controllers, 22 remotes, folder topologies, and network synchronization rules.
Game Design Document	docs/GAME_DESIGN.md	Master game loop, 3-tier world layout, NPC roster, Sect duties, economy, and gathering/crafting systems.
UI/UX Specification	docs/UI_UX_SPEC.md	Studio-authoritative GUI standards, Bangers/Fundamento typography rules, DisplayOrder hierarchy, color tokens, and layout mapping for all 10 ScreenGuis.
Combat Specification	docs/COMBAT_SPEC.md	Pure sword combat engine: 5-hit combo, T Block/Parry, 100-pt Posture & Guard Break, Looping Sword Intent, weapon refinement (+10), and complete keybind map.
Progression Specification	docs/PROGRESSION_SPEC.md	10 Major Realm × 9 Order (90 stages) cultivation math, tripartite Dantian formula, 100% preserved Qi breakthroughs, and Spirit Tea buff integration.
Asset Manifest	docs/ASSET_MANIFEST.md	Canonical inventory of 2D weapon icons, 3D meshes, audio assets, and visual FX IDs.
Code Dependency Guide	docs/CODE_DEPENDENCY_GUIDE.md	Require hierarchy, remote event mappings, circular dependency protections, and manager/controller boot orders.
Roblox Performance Rules	docs/ROBLOX_PERFORMANCE_RULES.md	Mobile 60 FPS budgets, memory caps, raycast query culling, foliage collision pruning, and network optimization standards.
AI Scanning Guide	.ai/AI_REPOSITORY_SCANNING_GUIDE.md	Guidelines for AI collaborators to trace code without hallucinations or full-repo context bloat.
Decisions Log	.ai/DECISIONS.md	Formal Architecture Decision Records (ADR-001 through ADR-044).
Changelog	.ai/CHANGELOG.md	Chronological log of development milestones and system updates.
Project Status	.ai/PROJECT_STATUS.md	Authoritative single-state status overview across all game subsystems.
Current Task	.ai/CURRENT_TASK.md	The single active operational focus for development.
Next Steps	.ai/NEXT_STEPS.md	Prioritized roadmap for upcoming engineering milestones.
5. Master Keybind Mapping
Keybind	Function	Operational Details
M1	5-Hit Sword Combo	Heavy broadsword chain with footwork damping (WalkSpeed = 8). Generates +25% Sword Intent per landed hit.
Left Control	Toggle Sprint	Toggles movement speed between base WalkSpeed (16) and Sprint (26).
Left Shift	Qi Flash-Step Dash	2-stage burst evasion; costs 3% Qi with a 3.0-second cooldown.
T	Block / Perfect Parry	180° frontal guard arc (80% mitigation). 0.22s Parry window (100% mitigation, 0.5s stagger, +5% Qi).
C	Qi Meditation	Toggles sitting cultivation state. Channels passive Qi toward next Order threshold.
R	Draw / Sheathe Sword	Swaps Flying Sword between hand grip (RightGripAttachment) and back sheath mount (BackSwordMount).
B	Realm Breakthrough	Triggers breakthrough attempt when Cultivated Qi reaches 100% capacity.
V	Sword Flight Mode	Mounts flying sword horizontally beneath feet for 3D omnidirectional flight (Speed: 65 -> 140+ studs/s).
Q	Skill: Sword Tempest	Spawns a rotating blade vortex around the player (Costs 15% Qi).
E	Skill: Telekinesis Thrust	Fires a telekinetic flying sword projectile forward (Costs 12% Qi).
F	Skill: Falling Sky Slam	High vertical jump followed by an earth-shattering downward plunge (Costs 10% Qi).