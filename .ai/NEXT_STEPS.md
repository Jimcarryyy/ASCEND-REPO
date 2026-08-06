# Next Steps & Project Roadmap — ASCEND

## 🚀 Immediate Next Steps (Phase 6)

### 1. World Zone & Qi Multiplier Binding (Task 6.2A)
- [ ] Place physical `Workspace.QiZones` parts (*MortalGrounds*, *SpiritSpring*, *AzurePeak*, *DragonCavern*, *CelestialVoid*) with attributes (`ZoneId`, `Multiplier`).
- [ ] Connect `QiZoneManager.luau` to `CultivationManager.luau` to apply spatial meditation multipliers ($1\times \rightarrow 150\times$).

### 2. Sect Affiliation & Master NPC System (Task 6.2B)
- [ ] Create `SectConfig.luau` defining Xianxia Sects (*Azure Cloud Sect*, *Crimson Flame Sect*, *Shadow Void Sect*) and passive faction perks.
- [ ] Place 3 Master NPCs in world pavilions with ProximityPrompts for dialogue, sect joining, and breakthrough guidance.
- [ ] Save player Sect choice in `PlayerDataManager.luau`.

### 3. Studio Import of 3D Mythic Paired Sets (Task 6.3)
- [ ] Download `.FBX` files for **Sun-Slayer Crimson Set**, **Nine-Dragon Sovereign Set**, and **Frost-Dragon Flared Set**.
- [ ] Set up `SurfaceAppearance` PBR maps (`ColorMap`, `EmissiveMap`, `NormalMap`) and `EmissiveStrength = 10`.
- [ ] Register all 4 Paired Sets in `ItemConfig.luau` and `WeaponManager.luau`.

### 4. Dynamic Sword Art Jade Scroll System (Task 6.4)
- [ ] Register Sword Art Skill Scrolls in `ItemConfig.luau` (`VoidSlashScroll`, `FlameCleaveScroll`, `DragonParryScroll`).
- [ ] Update `CombatStateManager.luau` to execute active skills based on player's equipped Jade Scrolls in `Q`, `E`, `R` slots.
- [ ] Implement Sword Art Mastery XP tracking (Rank 1 $\rightarrow$ Rank 10).

---

## 🔮 Future Roadmap (Phase 7 & Beyond)

### Phase 7: Open World & Beast AI
- [ ] **Wilderness Spirit Beasts**: Server-authoritative monster AI with aggro radius, attack combos, loot drops (*Demon Cores*), and respawn timers.
- [ ] **Herb Gathering Nodes**: Interactive 3D harvest nodes (*Spirit Grass*, *Flaming Lotus*) spawning in world zones.

### Phase 8: Xianxia Visual Polish
- [ ] Add post-processing bloom and depth-of-field atmospheric effects in `Lighting`.
- [ ] Add dynamic camera impulse shake on heavy Sword Art hits.