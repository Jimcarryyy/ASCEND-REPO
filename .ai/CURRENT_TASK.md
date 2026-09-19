# ASCEND — Active Task: Phase 2 Codebase Hardening & Architecture Cleanup

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`)  
> **Active Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Roadmap Status:** Phase 1 Verified Closed (5/5) | Phase 2 Active

---

## 🎯 Active Focus

Execute **Phase 2: Codebase Cleanup, Memory Leak Audit & Circular Dependency Decoupling** across all 18 server managers and 24 client controllers, enforcing strict typing (`--!strict`) and eliminating runtime cyclical requires before executing Phase 3 combat tuning.

---

## 📋 Task Verification & Acceptance Checklist

### Phase 1: Core Foundation & Verification (COMPLETED & CLOSED)
- [x] DataVersion 3 persistence with Samsara cycle tracking and Roman numeral title generator.
- [x] Studio Monkey Verification: 9/9 server checks passed (collision groups, network ownership, anti-ragdoll states).
- [x] Murim Spawn Dais pad fix (`CanCollide = true`, `Anchored = true`, `Neutral = true`).
- [x] Network remote pruning: 16 legacy unused remotes purged; 16 active remotes typed with `--!strict`.
- [x] Mob roster standardization: 10 Humanoid R6 Cultivators configured with `SPAWNER_ALIAS_MAP`.

### Phase 2: Architecture Cleanup & Anti-Pattern Purge (ACTIVE)
- [ ] **Memory Leak & Connection Lifecycle Audit:**
  - Audit all `characterConnections` across `CombatStateManager.luau`, `CultivationManager.luau`, and `SkillBarController.luau` to guarantee zero zombie listeners on respawn.
  - Audit `Maid` / `Janitor` / cleanup routines on ProximityPrompts and temporary spatial queries.
- [ ] **Decouple Circular Dependencies:**
  - Eliminate runtime dynamic inline `require()` workarounds between `CombatStateManager`, `CultivationManager`, and `WeaponManager` via cached getters or state signals.
- [ ] **Strict Typing & Schema Safety:**
  - Apply `--!strict` typing to all configs in `src/ReplicatedStorage/Shared/Configs/`.
  - Validate all data payloads across the 16 active `RemoteEvents`.
- [ ] **Live Monkey Verify Confirmation:**
  - Run Studio Command Bar verification suite to confirm 0 client/server runtime warnings or errors.

---

## 🚫 Explicit Constraints (Ground Rules)
1. **The Codebase is the Only Truth:** Never trust numbers in unverified documents over live scripts. If code and docs disagree, code wins.
2. **Strict Verification Protocol (ADR-065):** Fetch raw URLs, test via live Command Bar hot-patch, and obtain dev confirmation before closing tasks.
3. **No Dynamic UI via Code (ADR-041, ADR-069):** Never create UI frames using `Instance.new`. All UI hierarchies must reside natively in `StarterGui` with zero `UICorner`.
4. **Single-Weapon Purity (ADR-012, ADR-074):** Combat logic belongs exclusively to Flying Swords. Swords are sacred spiritual artifacts and cannot be sold in the general merchant market.
5. **Humanoid R6 Integrity (ADR-062, ADR-076):** 100% of characters and enemies use standard Roblox R6 rigs. Beast mob rigs are permanently prohibited.