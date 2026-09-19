# ASCEND — Prioritized Technical Roadmap

> **Engineering Roadmap & Next Steps**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge

---

## 🗺️ 11-Phase Production Roadmap

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [CLOSED] PHASE 1: CORE FOUNDATIONS & VERIFICATION PASS                      │
│ - Studio Monkey Verify 9/9 checks, DataStore V3, Murim spawn dais,         │
│   16 typed remotes, 10 Humanoid R6 mob models and spawners.                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ [ACTIVE] PHASE 2: ARCHITECTURE CLEANUP & ANTI-PATTERN PURGE                 │
│ - Memory leak audit (characterConnections & event listeners)                │
│ - Circular dependency decoupling (cached getters across managers)           │
│ - Strict typing (--!strict) across configs and remote handlers              │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PENDING] PHASE 3: COMBAT KINEMATICS, MARTIAL CADENCE & TUNING             │
│ - Heavy M1 slashes (0.50x / 0.32x playback, committed footwork)            │
│ - Skill E overhaul (traveling projectile beam, weapon palette attunement)   │
│ - Defensive VFX wiring (ActiveShield on T, ShieldBreakEffects on break)     │
│ - Black-bordered white ribbon sword trails & Shunpo dash polish             │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 4: FLYING SWORD 3D FLIGHT ENGINE (CLIENT REFINEMENT)                  │
│ - Server handover complete (realm speed scaling, 25 Qi/s drain)             │
│ - Client flight smoothing, camera pitch roll, and dismount transition       │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 5: MISSING GUI SCREENS & INTERFACES                                   │
│ - Complete AlchemyCauldronGui, BossHealthHUD, CharacterStatsGui             │
│ - Build SpiritPouchGui Studio hierarchy; connect live inventory             │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 6: BEGINNER WALKTHROUGH & GUIDING SYSTEMS                             │
│ - 3D guide lines and progressive quest markers                              │
│ - Elder Qing introductory walkthrough flow                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 7: SECT DUTIES, PROFESSIONS & ECONOMY EXPANSION                       │
│ - Dynamic notice board duties (D, C, B, A ranks)                            │
│ - Blacksmith +10 weapon visual auras & interactive alchemy minigame        │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 8: COMPETITIVE SPARRING ARENA & LEADERBOARDS                          │
│ - Ranked matchmaking queue and competitive honor exchange                   │
│ - Sector 3 Elo rating persistence and spectator podium                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 9: MULTI-ZONE EXPANSION (ZONE 2 VERDANT BAMBOO VALLEY)               │
│ - Zone 2 terrain integration, gathering nodes, and higher-order mobs        │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 10: SAMSARA REBIRTH LOOP & ENDGAME ASCENSION                          │
│ - Immortal Ascension Order 9 reset gate to QC Order 1                       │
│ - Permanent perks: +30% Qi refining, +5% sword damage cap, [Samsara I] title│
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 11: PRODUCTION PROFILING & LAUNCH HARDENING                           │
│ - Memory profiling under docs/ROBLOX_PERFORMANCE_RULES.md                   │
│ - Mobile touch layout ergonomics and low-end device optimization            │
└─────────────────────────────────────────────────────────────────────────────┘