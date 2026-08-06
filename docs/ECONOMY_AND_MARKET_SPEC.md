# 🪙 DUAL PLAYSTYLE ECONOMY & MARKET SPECIFICATION (ASCEND V1)

## 📌 OVERVIEW
ASCEND V1 implements a balanced, goal-driven economy that accommodates two distinct player playstyles:
1. **The PVE Combat Hunter**: Focuses on mob farming, boss bounties, and dungeon runs. Sells excess dropped loot (common/uncommon weapons, monster cores) for Spirit Stones to purchase ready-made Breakthrough Pills and potions directly from the Market Shop.
2. **The Alchemist Gatherer**: Focuses on exploring the continent, gathering rare herbs/ores, and refining pills at Alchemy Cauldrons. Sells excess high-tier pills to the Market Shop or other players for massive Spirit Stone profit.

---

## 💰 1. CURRENCY & FINANCIAL SINKS/FAUCETS

* **Primary Currency**: **Spirit Stones (灵石)**
* **Faucets (Earning Currency)**:
  * Selling excess drops (Common/Uncommon swords, beast cores, plant matter) to NPC Market Merchants.
  * Completing Sect Bounty Board Quests.
  * Opening hidden World Loot Chests.
* **Sinks (Spending Currency)**:
  * Buying ready-made Breakthrough Pills and Health/Qi Elixirs at the Market Shop.
  * Purchasing Gathering Tool Upgrades (Spirit Sickles, Qi Pickaxes).
  * Paying Realm Breakthrough ritual fees.

---

## 🏪 2. NPC MARKET SHOP SYSTEM

NPC Market Merchants located at the main Town Hub (Mortal Grounds) buy and sell goods dynamically:

### 🛍️ Market Item Catalog & Pricing

| Item Name | Category | Base Sell Price (Player $\rightarrow$ Shop) | Base Buy Price (Shop $\rightarrow$ Player) |
| :--- | :--- | :--- | :--- |
| **Common Iron Sword** | Equipment Drop | 25 Spirit Stones | N/A (Drop Only) |
| **Uncommon Steel Sword**| Equipment Drop | 75 Spirit Stones | N/A (Drop Only) |
| **Beast Core (Tier 1-5)**| Monster Reagent| 15 – 250 Spirit Stones | 50 – 500 Spirit Stones |
| **Spirit Grass / Herbs**| Gathering Node | 10 – 100 Spirit Stones | 30 – 300 Spirit Stones |
| **Foundation Pill** | Breakthrough Pill| 150 Spirit Stones | 300 Spirit Stones |
| **Core Formation Pill**| Breakthrough Pill| 500 Spirit Stones | 1,000 Spirit Stones |
| **Health Elixir** | Potion Consumable| 20 Spirit Stones | 50 Spirit Stones |

---

## 🎯 3. PITY & GOAL-DRIVEN BOSS DROP SYSTEM

To reward active, goal-driven combat without frustrating players with low drop rates, bosses utilize an **Accumulated Defeat Counter (Pity System)**:

1. **Standard Mob Drops**: Mobs drop high volumes of Common/Uncommon items and Spirit Stones (dopamine loot explosions!).
2. **Boss Drop Rates**:
   * Base Epic Gear Drop Chance: **10%** per boss defeat.
   * **Pity Milestone**: Every boss defeat grants +1 Accumulated Boss Clear point for that specific boss.
   * **Guaranteed Pity**: Reaching **10 Accumulated Defeats** guarantees an Epic Sword or Epic Back-Armor drop on the 10th kill.