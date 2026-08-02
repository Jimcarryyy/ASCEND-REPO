# ASCEND-V1 — CULTIVATION 2D ASSET MANIFEST & DESIGN PHILOSOPHY

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-V1/main/ASCEND.md  
> **Game Identity:** Martial Cultivation / Xianxia / Qi Ascension RPG  
> **Scope:** Cultivation Item Inventory, Martial Asset Identity, Realm Indicators, & Color Grading.

---

## 1. Cultivation Visual Identity & Theme Philosophy

ASCEND-V1 embraces an authentic **Xianxia / Martial Cultivation** aesthetic:

* **In-Combat HUD Identity:** Clean, ethereal, lightweight indicators. Soft Qi aura flows, acupuncture/meridian status points, and floating flying sword cooldown slots.
* **Out-of-Combat Menu Panels:** Handcrafted ancient Chinese scroll & jade parchment aesthetics, dark bamboo slate textures, carved dragon/phoenix gold borders, and glowing Qi trigram emblems.

---

## 2. Cultivation Realm & Rarity Tiering Pipeline

Instead of generic Western rarities, items and weapons scale across authentic **Cultivation Grades**:

| Cultivation Grade | Hex Color Code | Spiritual Identity | Visual Attributes |
| :--- | :--- | :--- | :--- |
| **Mortal Grade** | #FFFFFF (White) | Base mortal forged steel / wood | Plain iron/wooden finish, zero Qi glow |
| **Earth Grade** | #38E54D (Green) | Infused with Earth Qi / Jade | Jade green border with faint leaf motif |
| **Heaven Grade** | #2192FF (Blue) | Tempered with Heavenly Spirit Qi | Sapphire blue border with flowing wind aura |
| **Spirit Grade** | #9C2C77 (Purple) | Formed from Ancient Spirit Veins | Deep purple frame with pulsing meridian runes |
| **Sacred Grade** | #FFD700 (Gold) | Blessed by Sacred Beings / Ancestors | Intricate gold dragon filigree with glowing core |
| **Immortal Grade** | #FF1E1E (Crimson) | Born from Heavenly Tribulation Lightning | Dark crimson frame with crackling lightning aura |

---

## 3. Comprehensive Cultivation 2D Asset Inventory

### Category A: Cultivation HUD & Meridian Indicators

| Asset Name | Target Specs | Primary Palette | Xianxia Function / Identity |
| :--- | :--- | :--- | :--- |
| hud_slot_base | 128x128 PNG | #1E1E23 (Slate) | Taoist Bagua / Trigram action skill slot container |
| hud_slot_active | 128x128 PNG | #2192FF (Qi Blue) | Active Spiritual Qi resonance outline glow |
| hud_cooldown_mask | 128x128 PNG | #000000 (80% Alpha) | Ink wash / Qi dissipation cooldown mask |
| hud_key_badge | 64x64 PNG | #2A2A30 (Dark Stone) | Engraved stone rune keybind badge (M1, M2, Q, E, R, Shift) |
| hud_reticle_dot | 32x32 PNG | #FFFFFF (Pure Qi) | Spiritual consciousness aim focus dot |
| hud_boss_frame | 512x64 PNG | #141418, #FFD700 | Ancient Dragon-carved Demon Boss health bar frame |
| hud_tribulation_bar | 512x32 PNG | #FF1E1E (Crimson) | Heavenly Tribulation meter bar for Boss Phase transitions |

---

### Category B: Xianxia Scrolls & Jade Modal Panels

| Asset Name | Target Specs | Primary Palette | Xianxia Function / Identity |
| :--- | :--- | :--- | :--- |
| panel_modal_bg | 1024x1024 PNG | #121216, #FFD700 | Carved dark jade scroll panel background with dragon trim |
| panel_header_banner | 512x128 PNG | #8B0000, #FFD700 | Silk sect banner ribbon for window headers |
| panel_divider_line | 512x32 PNG | #FFD700 (Gold) | Cloud & Dragon filigree section divider line |
| panel_grid_slot | 128x128 PNG | #1A1A20 (Dark Jade) | Recessed spatial ring storage slot frame |
| panel_button_primary | 256x64 PNG | #2A2A35, #FFD700 | Carved stone talismans button frame |

---

### Category C: Cultivation Weapons & Spiritual Artifact Icons (128x128 PNG)

| Asset Name | Cultivation Category | Spiritual Description |
| :--- | :--- | :--- |
| icon_weapon_flyingsword | Spiritual Weapon | Floating Qi Flying Sword (Jian) with glowing edge aura |
| icon_weapon_spear | Spiritual Weapon | Azure Dragon Flame Spear with tasselled handle |
| icon_weapon_gauntlet | Martial Weapon | Iron Body Tempering Gauntlets wrapped in talisman cloth |
| icon_weapon_talisman_banner | Spiritual Artifact | Daoist Spirit Array Banner for elemental channeling |
| icon_gear_robes | Cultivation Attire | Immortal Sect Elder Robes embroidered with gold clouds |
| icon_gear_pendant | Spiritual Accessory | Jade Spirit Pendant for Qi gathering boost |
| icon_gear_ring | Spatial Artifact | Spatial Storage Ring with glowing dimensional rune |

---

### Category D: Martial Techniques & Qi Ability Icons (128x128 PNG)

| Asset Name | Skill Keybind | Cultivation Skill Identity |
| :--- | :--- | :--- |
| icon_skill_m1_swordart | Light Attack (M1) | Triple Qi Sword Slash art (3-hit sword light) |
| icon_skill_m2_heavyslam | Heavy Attack (M2) | Mountain Splitting Palm (Ground shattering energy slam) |
| icon_skill_dodge_windstep | Dodge / Roll | Wind Walk / Flash Step shadow blur silhouette |
| icon_skill_parry_qi_shield | Parry / Deflect | Bagua Qi Barrier deflecting incoming spiritual hit |
| icon_skill_sword_tempest | Flying Sword Q | Thousand Sword Formation flying in spinning circle |
| icon_skill_dragon_roar | Spear Archetype Q | Flaming Azure Dragon phantom thrusting forward |
| icon_skill_hundred_palms | Gauntlet Archetype Q | Rapid shadow palm strike flurry |
| icon_skill_tribulation_bolt | Talisman Archetype Q | Heavenly Lightning Bolt strike from sky |

---

### Category E: Cultivation Currencies, Pills & Materials (128x128 PNG)

| Asset Name | Item Type | Cultivation Identity |
| :--- | :--- | :--- |
| icon_currency_spiritstone_low | Currency | Low-Grade Spirit Stone (Polished Jade Crystal) |
| icon_currency_spiritstone_high | Currency | High-Grade Spirit Stone (Radiant Gold Qi Gem) |
| icon_mat_pill_qi_gathering | Consumable | Qi Gathering Pill (Glowing blue elixir sphere) |
| icon_mat_pill_breakthrough | Consumable | Foundation Breakthrough Dan (Gold pill in porcelain dish) |
| icon_mat_herb_ginseng | Crafting Material | 1000-Year Spirit Ginseng root with glowing veins |
| icon_mat_demon_core | Crafting Material | Beast Demon Core (Glowing crimson sphere) |

---

### Category F: Meridian & Qi Status Effect Indicators

| Asset Name | Status Effect | Cultivation Identity |
| :--- | :--- | :--- |
| icon_status_qi_deviation | Stun / Backfire | Fractured Qi Meridian network in chest (Dazed) |
| icon_status_poison | Corrosive Debuff | Green Toxic Venom Qi droplet |
| icon_status_tribulation_burn | Fire Debuff | Heavenly Crimson Flame aura burning character |
| icon_status_body_tempered | Defense Buff | Golden Bell Shield aura covering character |