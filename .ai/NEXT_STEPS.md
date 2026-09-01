# Next Steps & Project Roadmap — ASCEND

## Purpose
Planned upcoming work, ordered by priority. Replace/reorder sections as priorities shift — don't append duplicate roadmap blocks underneath old ones.

**Last consolidated:** 2026-09-02.

---

## Immediate (this task, see `CURRENT_TASK.md`)
1. Flying Sword Flight Mode — see blocking keybind issue noted in `CURRENT_TASK.md`.

## Near-term (queued, not yet started — confirm order with developer)
2. Bottom-Center Vital & Sword Intent HUD redesign.
3. Tier 5–8 sword model integration (4 remaining sword assets).
4. Center-reticle skill aim trajectory for `E`/`Q`/`F`.
5. Sect Market Vendor NPC placement verification in Zone 1 — confirm `workspace.MarketVendors`, `workspace.QuestNPCs`, `workspace.MobSpawns`, `workspace.SparringArena` are actually placed (this was an open item as of the last placement-focused session and was never re-confirmed).
6. Roblox Creator Dashboard: confirm live Gamepass IDs and Developer Product IDs are populated in `MonetizationConfig.luau` (not placeholders).

## Status unclear — confirm before scheduling
- **Spirit Beast AI / Hunting Engine** (Ironhide Boar, Spirit Deer, Demon Wolf — Pathfinding patrol/aggro/attack/flee, drop tables). Was in an earlier "active next" slot but doesn't appear in the latest dated changelog entry. Confirm status.
- **Sect Leaderboards** (`LeaderboardManager.luau`, `OrderedDataStore`-backed, auto-built `SurfaceGui` boards). Designed per `DECISIONS.md` history but not verified as merged into the live repo tree.

## Sect Zone (Zone 1) V1 world-dressing scope — agreed, not yet verified built
Existing: Alchemy shop, Sect shop, mission board, training dummy.
Agreed additions: Sword Altar/gacha, beginner tutorial, Sect Elder Pavilion clarification, Contribution Point display, confirmed spawn point, notice board/lore NPCs, meditation garden marker, Zone 2 portal tease, optional bank NPC.
**Explicitly deferred (do not resurface unless developer does):** 16 personal mini-houses per server.

## Future Roadmap (Phase 8+)
- Gamepass Store expansion (Auto-Meditate, 2× Qi Speed, Tribulation Protection Pills).
- Cultivation Realm Breakthrough Rewards System (Body Tempering, Golden Bones, Meridian Talent Nodes, Divine Spirit Consciousness).
- World Boss Battles & Sovereign Sword Peak Arena (Zone 5), multi-phase raid mechanics.
- Upper Realm / Divine Plane expansion beyond the 10 Major Realms (V1 caps around 1–2 Billion HP/Qi at Immortal Ascension Order 9 per the actual `CultivationConfig.luau` formula — see `PROGRESSION_SPEC.md`).