# Next Steps & Immediate Priorities

## Immediate Tasks

1. **Task 5.3: Heavenly Tribulation Lightning Boss Event**:
   - Build server-authoritative Tribulation Lightning Strike event triggered during Golden Core, Nascent Soul, or major realm breakthroughs.
   - Implement dynamic weather transformation (dark skybox, thunder SFX) and targeted lightning strike telegraphs requiring dodge timing (Hotkey `Shift`).
   - Spawn a Tribulation Avatar boss encounter during major ascension trials.

2. **Refinement Queue (Registered Known Issues)**:
   - **Breakthrough Meditation Pose Transition**: Update breakthrough keybind (`B`) to transition the player out of regular meditation into a dedicated **Breakthrough Meditation Pose** prior to lightning strikes.
   - **Meditation Pose Floating Smoothing**: Replace or adjust animation keyframe speed for `rbxassetid://116333173300889` to eliminate rapid internal up/down bobbing.
   - **Combat Weapon Motion Synchronization**: Synchronize character animation keyframe events with `HitboxManager.luau` active damage frames for Flying Swords, Spears, and Gauntlets.

3. **Task 5.4: Sect / Faction System & Alignment Mechanics**:
   - Construct Orthodox vs. Unorthodox sect selection, sect contribution ranks, and reputation alignment meters.

4. **Task 5.5: World Zone Progression & Spirit Veins**:
   - Construct Spirit Vein zones (+100% to +300% Qi gather rates) and environmental domain hazards (Miasma, Frost, Fire).

5. **Phase 6: Data Persistence & Infrastructure**:
   - Integrate ProfileService / DataStore v2 for saving inventory, spirit pills, stats, and cultivation progress.