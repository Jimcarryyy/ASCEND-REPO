# ASCEND — Active Task: Combat Kinematics Hardening & Server Remote Verification

> **Operational Task Tracker**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Source of Truth:** Live Luau Codebase (`src/`) & Live Studio Place File  
> **Active Priority:** Option A — Combat Kinematics, Network Contract & Bug Polish  
> **Roadmap Status:** Phase 1 Closed | Option A Active (In Progress) | Phase 2 Cultivation Gate (Deferred)

---\n\n## 🎯 Active Focus

Execute critical bug fixes and combat kinematics hardening across client and server:
1. **Server Remote Hookup (`CombatStateManager.luau` & `CultivationManager.luau`):** Wire `ToggleMeditation` and `RequestBreakthrough` server listeners so client inputs on `C` and `B` are not silently dropped.
2. **Hitbox Parameter Alignment (`HitboxManager.luau` & `FlyingSwordServer.luau`):** Align `CastCompensatedBox` signature to resolve `Unable to cast Vector3 to CoordinateFrame` errors.
3. **Safe-Zone Radius Tuning (`ArenaManager.luau`):** Reduce 350-stud safe-zone radius that currently engulfs mob spawners and zeroes out combat damage.
4. **Mob Combat Feedback (`MobAIManager.luau`):** Dispatch hit events to victim client on mob attacks to restore camera shake, red flash, and audio impact.
5. **HUD Qi Gauge Restoration (`SkillBarController.luau`):** Correct Qi fill calculation from `qMax / targetQiVal` to `qCur / qMax`.
6. **Master Drawer Docking:** Complete docked integration for `CharacterStatsController` (`Page_Stats`) and Codex (`Page_Archives`).

---

## 📋 Task Verification & Acceptance Checklist

### Core Bug Polish & Kinematics (ACTIVE)
- [x] Restore stable Studio baseline into VS Code via Argon [DEV-CONFIRMED].
- [x] Fix unbalanced `end` statements in `InputController.luau` [DEV-CONFIRMED].
- [x] Implement two-phase M1 speed curve and timing derivation from `FlyingSwordConfig.GetM1Timing` [DEV-CONFIRMED].
- [x] Add grounded forward lunge on M1 swings at `windupDuration` in `AnimationController.luau` [DEV-CONFIRMED].
- [x] Capped decaying `LinearVelocity` rebound force in `ArenaManager.luau` [DEV-CONFIRMED].
- [x] Completely purge avatar hit reaction animations to eliminate floor-flopping [DEV-CONFIRMED].
- [x] Re-bind focus lock to `ALT` (`LeftAlt` / `RightAlt`) [DEV-CONFIRMED].
- [x] Remove combat engagement music and proximity threat volume swelling from `MusicController.luau` [DEV-CONFIRMED].
- [x] Clean out dead `CultivationConfig.FormatNumber` call in `CharacterStatsController.luau` [DEV-CONFIRMED].
- [x] Deploy 10 realm Qi nodes in `Workspace.QiNodes` with `Fondamento` typography [DEV-CONFIRMED].
- [ ] Connect `ToggleMeditation` and `RequestBreakthrough` in `CombatStateManager.luau` and `CultivationManager.luau`.
- [ ] Fix `HitboxManager.CastCompensatedBox` parameter mismatch against `FlyingSwordServer.luau`.
- [ ] Shrink `IsInSafeZone` radius in `ArenaManager.luau` to prevent mob spawner interference.
- [ ] Dispatch victim hit feedback (camera shake, flash, SFX) in `MobAIManager.luau`.
- [ ] Fix syntax errors caused by literal `\n` in `MobAIManager.luau:245` and `CombatVFXController.luau:628`.
- [ ] Fix `SkillBarController.luau` Qi bar fill ratio (`qCur / qMax`).
- [ ] Fix `CultivationFeedbackGui.RejectionToast` missing `MainFrame` container lookup.
- [ ] Fix `SectManager.luau` line 88 crash (`SectConfig.Quests` -> `SectConfig.GetAllQuests()`) and define `GetContributionMultiplier`.
- [ ] Fix `PlayerDataManager.luau:661` nil `Cultivation.Realm` crash.
- [ ] Purge non-existent weapon IDs from `SwordAltarManager.luau` drop pool.

### Master Drawer & UI Architecture (PENDING)
- [ ] Finalize `Page_Archives` topic switching and purge legacy `CodexGui` infinite yield.
- [ ] Dock `Page_Stats` into master drawer without standalone hotkey conflicts.
- [ ] Memory leak audit: disconnect `characterConnections` on character despawn.
- [ ] Enforce `--!strict` typing across shared configs in `src/ReplicatedStorage/Shared/Configs/`.

---

## 🚫 Explicit Constraints (Ground Rules)
1. **Full Source Files Only (ADR-079):** Never use partial string-replacement CMD snippets; supply full files for VS Code synchronization.
2. **The Codebase is the Only Truth:** Never trust numbers in outdated design documents over live scripts.
3. **No Avatar Hit Reactions (ADR-081):** Avatar hit-reactions must remain completely disabled across animation controllers.
4. **On-Demand Sparring Only (ADR-080):** Prohibit reliance on legacy physical dual-pad arena geometry.
5. **No Dynamic UI via Code (ADR-041):** All UI hierarchies must reside natively in `StarterGui`.