# Current Task Specification — ASCEND

## Purpose
This document defines the single active operational focus of development for ASCEND. Historical task threads are permanently archived in `CHANGELOG.md`.

**Current Milestone:** Phase 8.5 — Combat Engine Hardening & Skills Overhaul  
**Active Timestamp:** September 2026  
**Active Role Context:** Systems Architect, Combat & Progression Designer, VFX & Visual Polish Expert  

---

## 🎯 ACTIVE TASK: Combat Skills Integration & Physics Stabilization

Following the successful implementation and testing of the `Q` Skill (Purple Sword Tempest) and `F` Skill (100-Slash Flash Domain):

### Active Verification & Acceptance Checklist
- [x] Fix `GatheringManager.luau` nil index crash using universal `GetNodeConfig` resolver.
- [x] Fix `GatheringController.luau` client startup crash (remove server `State` require, resolve `RemoteEvents` module).
- [x] Initialize `MobAIManager` in `ServerMain.server.luau` and resolve `MobConfig.GetMob` lookup for `RogueDisciple`.
- [x] Implement server-authoritative `Q` Skill: 3x purple traveling sawblade waves ($36\text{ studs}$, $70\text{ studs/s}$), dual hitbox, release sound (`109735549169421`), and hit sound (`135448977656112`).
- [x] Implement `F` Ultimate Skill: Stance charge lock (`84905841522350`), 28-stud flash-step dash phasing through enemies while respecting terrain/trees, mid-dash slash (`111677132360566`), 36-stud purple 100-slash sphere (`UltimateSkill`), and dedicated sound (`18781431019`).
- [x] Fix character tripping/ragdoll bugs on high-speed dashes (permanent `FallingDown` lock, zero-torque braking, automatic sprint resumption).
- [ ] Patch `ServerScriptService.Server.Combat.HitboxManager.luau` line 228 nil call bug when attacks hit Mob/NPC targets.
- [ ] Implement remaining VFX suite skills from `ReplicatedStorage.VFX` (`ActiveShield` on `T`, `ShieldBreakEffects` on GuardBreak, `SwordIntentAnim`, `FireSlashSkill`).
- [ ] Reconcile `R` keybind between Sheath/Draw and Ultimate `Celestial Sunfall`.

---

## 🚀 QUEUED NEXT: Defensive Combat Suite & Shield VFX
1. Wire `ActiveShield` and `ShieldBreakEffects` to `T` Block / Guard-Break mechanics.
2. Complete `HitboxManager.luau` server audit for NPC/Mob hit resolution.
3. Wire `FireSlashSkill` and `SwordIntentAnim` into weapon combo / skill variants.