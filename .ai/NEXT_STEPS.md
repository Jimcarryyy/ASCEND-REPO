# Next Steps & Project Roadmap — ASCEND

## Purpose
This file lays out the next planned development milestones and future roadmap. Use it after completing current objectives or when planning upcoming phases.

## Connectivity
- Follows `.ai/CURRENT_TASK.md` and `.ai/PROJECT_STATUS.md`.
- Points to active Phase 7 and future Phase 8 work.

---

## 🚀 Immediate Next Steps (Phase 7: Core Loop & World Gathering)

### 1. Zone 1 & Zone 2 Herb Gathering Node System (Task 7.1A) — [COMPLETED]
- [x] Place physical 3D harvestable herb nodes in `workspace.GatheringNodes` (`SpiritGrass`, `DragonBloodVine`, `GaleWindLotus`, `CelestialSpring`, `JadeOre`).
- [x] Add `ProximityPrompt` `[E]` interaction to harvest herbs directly into the player's Spirit Pouch (`K`).
- [x] Implement node respawn timers (12-to-30-second cooldown) and weighted random herb age rolls (1-Yr to 1,000-Yr).
- [x] Connect audio playback for `SoundService.GatherHerbsSound` on harvest.

### 2. Upgraded Manual 3-Slot Spirit Cauldron Alchemy Engine (Task 7.1B) — [COMPLETED]
- [x] Refactor `AlchemyConfig.luau`, `AlchemyManager.luau`, and `AlchemyController.luau` for manual 3-slot herb selection.
- [x] Add dynamic age-based success calculations (higher herb ages boost success rate up to 100% and potency up to 3.0x).
- [x] Add craftable buff pills: *Spirit Healing Dan*, *Qi Gathering Dan* (2x Meditation Speed), *Physique Tempering Dan* (+35% Damage), *Gale Wind Dan* (+40% Flight Speed), and *Foundation Gathering Dan*.

### 3. Environmental Qi Meditation Pads & Realm Breakthroughs (Task 7.1C) — [ACTIVE NEXT TASK]
- [ ] Place interactive **Meditation Stone Pads** (`workspace.MeditationPads`) in Zone 4 / Zone 2 streams.
- [ ] Implement meditation channeling (**[F]** key / ProximityPrompt) with `Celestial Float System` pose to fill the `800 / 800` Qi bar $3.5\times$ faster than passive absorption.
- [ ] Implement **Realm Breakthrough Trials**: consuming a *Foundation Gathering Dan* when Qi is full triggers celestial golden aura particles, advances cultivator tiers (*Qi Condensation* $\rightarrow$ *Foundation Establishment*), increases permanent stats, and updates HUD titles.

### 4. Spirit Beast AI Spawning & Flying Sword Combat (Task 7.1D)
- [ ] Spawn wild spirit beasts in Zone 2 to fight with Flying Swords.
- [ ] Implement beast loot drops (`DemonBeastCore`) on death.

### 5. Sect Market Vendors & Monetization Integration (Task 7.1E)
- [ ] Set up shop vendor NPCs in Zone 1 (Azure Sect Hub) to trade Spirit Stones and process Roblox Developer Products / GamePasses.

---

## 🔮 Future Roadmap (Phase 8 & Beyond)

### Phase 8: Xianxia World Expansion & Monetization
- [ ] Add Gamepass Store (Auto-Meditate, $2\times$ Qi Speed, Tribulation Protection Pills).
- [ ] Add Leaderboards (Highest Realm Rank, Top Sword Mastery).