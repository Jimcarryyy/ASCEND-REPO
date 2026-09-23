# ASCEND — Prioritized Technical Roadmap

> **Engineering Roadmap & Next Steps**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** Option A — Combat Kinematics & Codebase Polish

---\n\n## 🗺️ 11-Phase Production Roadmap

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ [CLOSED] PHASE 1: CORE FOUNDATIONS & VERIFICATION PASS                      │
│ - Studio Monkey Verify 9/9 checks, DataStore V3, Murim spawn dais,         │
│   16 typed remotes, 10 Humanoid R6 mob models and spawners.                 │
├─────────────────────────────────────────────────────────────────────────────┤
│ [ACTIVE] OPTION A: COMBAT KINEMATICS, REBOUND & BUG POLISH                  │
│ - [x] InputController tail replacement & end-statement balance              │
│ - [x] ArenaManager LinearVelocity capped decay rebound                      │
│ - [x] M1 two-phase slash speed curve & FlyingSwordConfig.GetM1Timing        │
│ - [x] AnimationController grounded forward attack lunge                     │
│ - [x] Avatar hit reaction animations completely purged                      │
│ - [x] ALT focus keybind re-map & MusicController combat threat purge        │
│ - [ ] Server remote listeners for C meditation & B breakthrough             │
│ - [ ] HitboxManager CastCompensatedBox parameter alignment                  │
│ - [ ] ArenaManager safe-zone radius fix to unblock mob spawners             │
│ - [ ] MobAIManager hit event dispatch to victim client                      │
│ - [ ] SkillBarController Qi bar fill ratio (qCur / qMax) fix                │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PENDING] PHASE 2 (CULTIVATION): ORDER 9 GATE & TRIBULATION (DEFERRED)      │
│ - Order 9 breakthrough gate enforcement & Tribulation lightning waves       │
│ - Breakthrough Dan preservation on tribulation failure with 50% Qi penalty  │
│ - Interactive flame-timing slider minigame (Option B)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ [PENDING] PHASE 3: COMBAT CADENCE, BALANCING & DEFENSIVE TUNING             │
│ - Skill cooldown rebalance (Q: 6.5s, E: 7.5s, F: 14.0s) verification       │
│ - Skill E overhaul (traveling projectile beam, weapon palette attunement)   │
│ - Defensive VFX wiring (ActiveShield on T, ShieldBreakEffects on break)     │
│ - Black-bordered white ribbon sword trails & Shunpo dash polish             │
├─────────────────────────────────────────────────────────────────────────────┤
│ [CLOSED] PHASE 4: FLYING SWORD 3D FLIGHT ENGINE                             │
│ - 3D flight, realm speed scaling, 25 Qi/s drain, clearance cushions.       │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 5: UNIFIED GUI SYSTEMS & MASTER DRAWER DOCKING                        │
│ - Complete CharacterStats (Page_Stats) & Codex (Page_Archives) docking      │
│ - Purge legacy CodexGui infinite yield                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 6: BEGINNER WALKTHROUGH & GUIDING SYSTEMS                             │
│ - 3D guide lines and Elder Qing introductory walkthrough flow               │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 7: SECT DUTIES & ECONOMY EXPANSION                                    │
│ - Sword Altar Communion gacha integration (Madame Tie forge purged)         │
│ - Dynamic notice board duties (D, C, B, A ranks)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│ PHASE 8: ON-DEMAND SPARRING ARENA & LEADERBOARDS                            │
│ - 35-stud proximity sparring challenge & 50-stud dynamic Qi ring            │
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