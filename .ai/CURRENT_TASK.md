# Current Task Specification — ASCEND

## Purpose
This document defines the single active operational focus of development for ASCEND. Historical task threads are permanently archived in `CHANGELOG.md`.

**Current Milestone:** Phase 8.3 — MasterHUDGui Live Integration & Flying Sword Flight Mode  
**Active Timestamp:** September 2026  
**Active Role Context:** Systems Architect & UI/UX Designer  

---

## 🎯 ACTIVE TASK: MasterHUDGui Live Binding & Controller Consolidation

The full 16-station `Workspace.Functional_Stations` suite, the 19-character `Workspace.NPCs` roster (including the 7 Sword Pillars), and all 12 facility/status ScreenGuis in `StarterGui` have been generated and debugged. 

The immediate active priority is verifying and finalizing the live event bindings on **`MasterHUDGui`**:

### Active Verification & Acceptance Checklist
- [x] Consolidate `VitalsContainer` (HP, Qi, Intent) into `SkillBarController.luau`.
- [x] Connect `BottomCenterFrame.HotbarContainer` (10 skill slots) with live cooldown sweeps and keybind triggers.
- [x] Connect `TopRightCurrencyFrame` to live Spirit Stones and Contribution Points ($CP$).
- [x] Connect `TopLeftDutyTracker` (`Frame1`, `Frame2`, `Frame3`) to `QuestTrackerController.luau`.
- [x] Shift `TopLeftDutyTracker` by $+56\text{px}$ down to clear Roblox CoreGui topbar buttons.
- [x] Disable legacy standalone HUDs (`CurrencyGUI`, `SkillsGUI`, `BottomMenuGui`, `SectMissionGui`, `QIZoneNotifGui`, `GlobalToastNotifGui`).
- [x] Verify all 12 modals (`DisplayOrder = 50`, $Y = 0.38$) render cleanly above the bottom HUD without overlap.

---

## 🚀 QUEUED NEXT: Flying Sword Flight Mode (御剑飞行)
Following HUD sign-off:
1. Wire `V` key toggle in `InputController.luau` and `SkillBarController.luau`.
2. Attach flying sword horizontally beneath character feet using `HumanoidRootPart.BodyBackAttachment` / `FlightSwordMount`.
3. Implement 3D omnidirectional flight physics with banking turns and realm-scaled speed ($65 \rightarrow 140+\text{ studs/s}$).