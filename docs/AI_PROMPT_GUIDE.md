---

# 6. `docs/AI_PROMPT_GUIDE.md`

```markdown
# 📄 `docs/AI_PROMPT_GUIDE.md`

# 🎨 ASCEND — AI Prompt Guide & Asset Generation Specifications

> **Source of Truth for 2D UI & 3D Asset Generation**  
> This guide defines the exact prompt structures, style guidelines, and post-processing steps used to generate all 2D UI assets and 3D game models for **ASCEND**.

## Purpose
This document provides the AI asset generation workflow, style rules, and prompt reference for visual production.

## Document Connectivity
- Use this guide when generating or reviewing art assets, 2D UI templates, and 3D mesh concepts.
- Pair it with `docs/ASSET_MANIFEST.md` to ensure generated assets match the approved item catalog and quality requirements.
- This file does not define gameplay systems; it defines visual and asset production rules only.

---

## 🏛️ Core Design Principles

### 1. The Empty Shell Rule (2D UI Containers)
* All UI frames, slots, bars, buttons, and modal panels MUST be generated as **pure blank templates/shells**.
* **STRICT NEGATIVES:** Never bake in static text, numbers, digits, gear icons, dishware/plates, or skill icons.
* Luau client scripts in Roblox Studio handle dynamic text (`TextLabel`), progress bar fills (`Frame`), and icon overlays (`ImageLabel`).

### 2. Dark Obsidian & FredokaOne Aesthetic (UI/UX)
* **Palette:** `#0C0E14` (Main Window), `#121520` (Sub-Panels/Cards), `#1E2330` (1.5px Sharp Border Stroke).
* **Typography:** `Enum.Font.FredokaOne` across all HUD meters, modal titles, and item cards.
* **Corners:** Sharp 90° corners (0px border-radius) matching Spirit Pouch and Alchemy Cauldron panels.

### 3. Vibrant Xianxia Roblox Style (3D Assets)
* **Style:** Bold anime-fantasy Xianxia silhouettes, clean polished materials (Translucent Jade, Volcanic Magma Glass, Dark Obsidian, Gold Trim), engraved glowing Dao runes, and 3D-sculpted mythical creature guards.
* **STRICT NEGATIVES:** Avoid gritty photorealism, dirty/weathered leather, scratched steel, dangling tassels/cloth, or swirling ring helixes.

### 4. Image-to-3D Meshy Pro Pipeline
1. Generate clean 2D concept art in Gemini / Recraft.ai (isolated on pure white background, studio key lighting, 3D volume).
2. Upload 2D concept into Meshy AI **Quick Generate** (Image-to-3D, Standard Mode = 20 Credits).
3. Export `.FBX` with **Target Polycount: ~3,000 Triangles** (ensuring 60 FPS mobile performance).
4. Import into Roblox Studio and configure `SurfaceAppearance` (`ColorMap`, `NormalMap`, `EmissiveMap` with `EmissiveStrength = 10`).

---

## 🗡️ Category 1: Mythic Paired 3D Sword & Back-Crest Prompts

### `Heavenly Void Set` (Cosmic / Space / Telekinesis) — *Mythic Tier*
```text
High-resolution 3D-rendered game concept art of a mythic xianxia celestial sword. Sleek dark obsidian and purple steel blade with ancient glowing white heavenly runes engraved along the center, 3D floating purple crystal shards hovering along the blade spine, and a grand ornate gold celestial wing crossguard. Vibrant anime fantasy RPG style, bold eye-catching silhouette, glowing cosmic energy effects, studio key lighting, isolated on a pure white background, clean 3D game asset, 4k resolution.
Sun-Slayer Crimson Set (Magma / Fire) — Mythic Tier
code
Text
High-resolution 3D-rendered game concept art of a mythic xianxia flame greatsword. A broad double-edged sword made of dark volcanic magma glass with jagged flame-shaped blade edges and glowing orange lava runes engraved along the center spine. An ornate 3D sculpted golden Vermilion Phoenix bird guard with spreading wings and a glowing fiery red orb at the hilt center. Rigid solid 3D prop design, no lion heads, no hanging tassels or cloth. Vibrant anime fantasy RPG style, powerful broadsword silhouette, glowing orange flame and magma energy, studio key lighting, isolated on a pure white background, clean 3D game asset, 4k resolution.
Nine-Dragon Sovereign Set (Jade / Wind) — Mythic Tier
code
Text
High-resolution 3D-rendered game concept art of a mythic xianxia dragon sword. An elongated slender Chinese flying sword blade made of glowing translucent cyan-emerald jade with glowing golden dragon runes along the center. An ornate 3D sculpted golden dragon coiled around a circular ring guard holding a glowing golden dragon pearl. Hovering near the guard are solid 3D sharp faceted cyan jade crystal shards with crisp 3D geometry and studio lighting. Rigid solid 3D prop design with solid hovering crystal shards, no soft feathers, no cloth, no particle effects. Vibrant anime fantasy RPG style, majestic eye-catching silhouette, glowing cyan and gold energy, studio key lighting, isolated on a pure white background, clean 3D game asset, 4k resolution.
Frost-Dragon Flared Set (Ice / Frost) — Legendary Tier
code
Text
High-resolution 3D-rendered game concept art of a legendary xianxia frost-jade sword. An elongated double-edged blade made of translucent ice-cyan crystal jade with a wide flared blade base near the handle and deep glowing golden frost runes engraved along the center channel. An ornate 3D sculpted silver and gold frost-dragon head guard with wide flared side wings and glowing blue eyes, a silver-wrapped handle, and a silver dragon-claw pommel holding an icy cyan gem. Flared wide ricasso blade throat near the hilt, rigid solid 3D prop design, no hanging tassels or cloth. Vibrant anime fantasy RPG style, majestic aggressive sword silhouette, glowing cyan and gold energy, studio key lighting, isolated on a pure white background, clean 3D game asset, 4k resolution.
🔮 Category 2: 3D Floating Back-Crest Array Prompts
Void Floating Back-Crest (Pairs with Heavenly Void Blade)
code
Text
High-resolution 3D-rendered game concept art of a 5-blade spirit sword array back attachment. 5 identical xianxia flying swords arranged symmetrically in a wide fan-shaped semi-circular arc. Each sword is made of translucent purple obsidian with glowing white runes along the center spine and an ornate golden wing guard. The 5 hilts are connected at the center by a subtle glowing purple spirit energy ring. Symmetrical 3D prop asset design, no character, no text panels, isolated on a pure white background, studio key lighting, clean 3D game asset, 4k resolution.
Crimson Flame Back-Crest (Pairs with Sun-Slayer Crimson Blade)
code
Text
High-resolution 3D-rendered game concept art of a xianxia flame back-crest accessory. A central vertical broadsword-crest made of dark volcanic obsidian glass with glowing orange lava veins along the center, flanked symmetrically by 4 floating jagged magma blade-shards (2 left, 2 right) in a tight wing formation. Bottom hilt connector features an ornate 3D golden roaring lion-head guard with glowing red eyes. Symmetrical 3D prop asset design, no character, isolated on a pure white background, studio key lighting, clean 3D game asset, 4k resolution.
Azure Dragon Back-Crest (Pairs with Nine-Dragon Sovereign Blade)
code
Text
High-resolution 3D-rendered game concept art of a xianxia dragon back-crest accessory. A central vertical sword-crest made of translucent dark emerald-green jade with glowing golden dragon runes, flanked symmetrically by 4 floating emerald jade blade-shards (2 left, 2 right) in a tight wing formation. Bottom hilt connector features an ornate 3D golden dragon coiled around a glowing gold dragon-eye gem core. Symmetrical 3D prop asset design, no character, isolated on a pure white background, studio key lighting, clean 3D game asset, 4k resolution.
Frost Dragon Back-Crest (Pairs with Frost-Dragon Flared Blade)
code
Text
High-resolution 3D-rendered game concept art of a xianxia frost-dragon back-crest accessory. A central vertical sword-crest made of translucent ice-cyan crystal jade with glowing golden frost runes, flanked symmetrically by 4 floating ice-crystal blade-shards (2 left, 2 right) in a tight wing formation. Bottom hilt connector features an ornate 3D silver and gold frost-dragon guard with glowing blue eyes. Symmetrical 3D prop asset design, no character, isolated on a pure white background, studio key lighting, clean 3D game asset, 4k resolution.
📜 Category 3: 2D UI & Item Icon Prompts
icon_scroll_void_slash.png (Jade Scripture Scroll)
code
Text
flat 2d vector game icon, clean cel-shaded Xianxia jade scripture scroll with glowing purple spatial runes, gold ribbon ties, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, photo
icon_scroll_flame_cleave.png (Flame Scripture Scroll)
code
Text
flat 2d vector game icon, clean cel-shaded Xianxia lava scripture scroll with glowing orange fire runes, gold dragon ribbon ties, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, photo
🏷️ Category 4: Native Roblox UIStroke Rarity System
Applied natively in Roblox Studio using UIStroke objects on panel_grid_slot:
Common Grade: #FFFFFF (White)
Uncommon Grade: #38E54D (Jade Green)
Rare Grade: #2192FF (Sapphire Blue)
Epic Grade: #9C2C77 (Deep Purple)
Legendary Grade: #FFD700 (Gold)
Mythic Grade: #FF1E1E (Crimson / Radiant Gold-Purple)