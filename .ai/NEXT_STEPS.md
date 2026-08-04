# Next Steps & Project Roadmap

This document outlines the upcoming development tasks for ASCEND.

---

## 🚀 Immediate Next Steps (Phase 6)

### 1. DataStore Data Persistence (Task 6.1)
- [ ] Implement `DataStoreService` wrapper module in `src/ServerScriptService/Server/State/` to save player profile data upon leaving and load upon joining.
- [ ] Save fields: `Realm`, `CurrentQi`, `InventorySlots`, `EquippedWeapon`, `Sect`.
- [ ] Add auto-save background loop (every 5 minutes) and emergency save on server shutdown (`BindToClose`).

### 2. Sect Affiliation & Master NPC System (Task 6.2)
- [ ] Create `SectConfig.luau` defining Xianxia Sects (*Azure Cloud Sect*, *Crimson Flame Sect*, *Shadow Void Sect*) and passive faction buffs.
- [ ] Build Master NPC interaction prompts in the world for realm breakthrough guidance and sect skill learning.
- [ ] Implement Sect Duty & Daily Quest log (`Hotkey J`).

### 3. Equipment Forging & Spirit Refining Panel (Task 6.3)
- [ ] Create `ForgingController.luau` UI for weapon enhancement (+1 to +10) using Spirit Stones and Demon Cores.
- [ ] Add Talisman and Gem socketing for bonus attributes (+Atk, +Crit Rate).

---

## 🔮 Future Roadmap (Phase 7 & Beyond)

### Phase 7: Open World & Beast AI
- [ ] **Wilderness Spirit Beasts**: Server-authoritative monster AI with aggro radius, attack combos, loot drops (*Demon Cores*), and respawn timers.
- [ ] **World Boss Encounters**: Multi-player team boss encounters with telegraphed AOE attacks.

### Phase 8: Xianxia Visual Polish
- [ ] Replace temporary placeholder sounds with final audio assets from Audio Search Manifest.
- [ ] Add post-processing bloom and depth-of-field atmospheric effects in `Lighting`.