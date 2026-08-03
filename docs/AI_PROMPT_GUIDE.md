Here is the updated, production-ready **`docs/AI_PROMPT_GUIDE.md`** containing all of our verified prompts, empty-shell rules, flat 2D vector style guidelines, native `UIStroke` rarity configuration, and Python post-processing script.

---

# 📄 `docs/AI_PROMPT_GUIDE.md`

```markdown
# 🎨 ASCEND — AI Prompt Guide & Asset Generation Specifications

> **Source of Truth for 2D UI & Icon Generation**  
> This guide defines the exact prompt structures, visual style guidelines, and post-processing steps used to generate all 2D game assets for **ASCEND**.

---

## 🏛️ Core Design Principles

### 1. The Empty Shell Rule (UI Containers)
* All UI frames, slots, bars, buttons, and modal panels (**Categories A & B**) MUST be generated as **pure blank templates/shells**.
* **STRICT NEGATIVES:** Never bake in static text, numbers, digits, gear icons, dishware/plates, or skill icons.
* Luau client scripts in Roblox Studio handle dynamic text (`TextLabel`), progress bar fills (`Frame`), and icon overlays (`ImageLabel`).

### 2. Flat 2D Vector / Cell-Shaded Style (Icons)
* Item, weapon, skill, currency, and status effect icons (**Categories C, D, E, F**) must be **flat 2D vector graphic emblems**.
* **Style:** Bold black outlines, flat cell-shading, high contrast, vibrant color palette.
* **STRICT NEGATIVES:** No 3D volumetric renders, soft painted gradients, realistic metallic lighting, depth effects, or 3D smoke.

### 3. Watermark-Safe Scaling & Margins
* All UI container prompts use the phrase `centered on canvas with wide empty solid black padding margins around all edges` and `--ar 1:1`.
* This forces AI generators (Gemini/Imagen) to leave a wide black padding buffer around the asset, ensuring watermarks sit in empty black space where they can be cropped away without touching UI frame lines.

### 4. Native Roblox `UIStroke` Rarity Borders (Category G)
* Square rarity borders (Mortal to Immortal) are implemented **natively in Roblox Studio** using `UIStroke` instances on `panel_grid_slot` rather than AI images. This guarantees 100% vector crispness across all screen resolutions without image memory overhead.

---

## 🛡️ Category A: Minimalist HUD Assets (`01_HUD`)

### `hud_slot_base.png` (Base Skill Slot Container)
```text
compact small 2d game UI asset, plain dark slate rounded square skill slot tile container, simple clean dark gray border, ultra-minimalist modern Roblox RPG interface asset, clean flat vector art, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, text, numbers, digits, gear icon, internal icons, symbols, 3d render, gold filigree, dragon, heavy ornament, photo, glow, watermark, star logo, signature, stamp
```

### `hud_slot_active.png` (Active Skill Slot Highlight State)
```text
compact small 2d game UI asset, plain dark slate rounded square skill slot tile container with a thin clean glowing cyan border stroke, active skill slot highlight state, minimalist modern Roblox RPG UI asset, clean flat vector art, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, text, numbers, digits, gear icon, internal icons, symbols, heavy ornament, 3d render, gold filigree, dragon, texture, watermark, star logo, signature, stamp
```

### `hud_cooldown_mask.png` (Cooldown Overlay Mask)
```text
compact small 2d game UI asset, plain translucent dark gray circular cooldown mask overlay graphic, completely empty shell container, smooth solid semi-transparent dark tint circle with thin clean border, minimalist flat game vector icon, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, text, numbers, digits, gear icon, internal icon, symbols, static numbers, 3d render, color gradient, heavy pattern, watermark, star logo, signature, stamp
```

### `hud_key_badge.png` (Keybind Badge Container)
```text
compact small 2d game UI asset, plain dark slate horizontal rectangular pill keybind badge container, simple clean dark gray border, ultra-minimalist modern Roblox UI button container, clean flat vector art, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 2:1 --no full screen, touching edges, edge-to-edge frame, text, numbers, digits, glow, cyan light, glowing border, 3d render, gold filigree, heavy ornament, watermark, star logo, signature, stamp
```

### `hud_reticle_dot.png` (Spiritual Aim Focus Dot)
```text
compact small 2d game UI asset, minimalist aiming crosshair reticle, tiny clean cyan focus dot with thin crosshair lines, flat vector graphic, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no heavy borders, 3d render, photo, watermark, star logo, signature, stamp
```

### `hud_boss_frame.png` (Boss Health Bar Frame)
```text
2d game UI asset, thin sleek horizontal boss health bar container frame, simple plain dark slate bar with thin dark border, ultra-minimalist modern Roblox RPG health bar UI, clean vector line art, floating centered in the middle of a square black canvas with large black margins above and below, isolated on solid black background --ar 1:1 --no white border, white frame, container box, white capsule, full screen, text, character, red health fill, gold filigree, dragon ornament, 3d render, watermark, star logo, signature, stamp
```

### `hud_tribulation_bar.png` (Tribulation Phase Bar Frame)
```text
2d game UI asset, thin sleek horizontal meter bar frame container, simple plain dark slate bar with thin subtle crimson accent border, minimalist modern Roblox RPG phase bar, clean vector line art, floating centered in the middle of a square black canvas with large black margins above and below, isolated on solid black background --ar 1:1 --no white border, white frame, container box, white capsule, full screen, text, character, fill color, 3d render, heavy ornament, watermark, star logo, signature, stamp
```

---

## 📜 Category B: Xianxia Modal Panels & Windows (`02_PANELS`)

### `panel_modal_bg.png` (Main Modal Window Panel Shell)
```text
compact centered 2d game UI asset, plain dark obsidian slate square menu window background panel, clean dark frame with subtle thin cyan line border accent, minimalist modern Roblox RPG modal panel shell, vector line art, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, text, numbers, buttons, icons inside, heavy 3d filigree, dragon ornament, photo, glow fill, watermark, star logo, signature, stamp, corner emblem
```

### `panel_header_banner.png` (Window Header Banner Ribbon Shell)
```text
compact horizontal 2d game UI asset, plain dark slate horizontal header banner ribbon container, clean dark frame with subtle thin cyan line border accent, minimalist modern Roblox RPG window title banner, vector line art, floating centered in the middle of a square black canvas with large black margins above and below, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, white border, white frame, container box, white capsule, text, numbers, letters, 3d render, photo, heavy filigree, watermark, star logo, signature, stamp, corner emblem
```

### `panel_divider_line.png` (Section Divider Line)
```text
compact horizontal 2d game UI asset, long horizontal section divider line, thin sleek dark steel line with subtle glowing cyan center accent dot, minimalist modern Roblox RPG UI line, vector line art, floating centered in the middle of a square black canvas with large black margins above and below, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, white border, white frame, container box, white capsule, text, numbers, 3d render, photo, heavy pattern, watermark, star logo, signature, stamp
```

### `panel_grid_slot.png` (Pure Blank Inventory Grid Slot Container)
```text
compact small 2d game UI asset, plain dark slate square inventory storage grid slot container, simple clean dark gray border with subtle thin cyan line accent, completely empty pure blank container, minimalist modern Roblox RPG item slot shell, clean vector line art, perfectly centered on canvas with wide empty solid black padding margins around all edges, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, dot in middle, center circle, target, dot, markings inside, items inside, text, numbers, 3d render, heavy ornament, glow center, watermark, star logo, signature, stamp, corner emblem
```

### `panel_button_primary.png` (Primary Action Button Frame Shell)
```text
compact horizontal 2d game UI asset, plain dark slate rectangular primary button frame container, clean dark border with subtle thin cyan border line accent, minimalist modern Roblox RPG button shell, clean vector line art, floating centered in the middle of a square black canvas with large black margins above and below, isolated on solid black background --ar 1:1 --no full screen, touching edges, edge-to-edge frame, white border, white frame, container box, white capsule, text, numbers, letters, icons inside, 3d render, heavy ornament, watermark, star logo, signature, stamp, corner emblem
```

---

## ⚔️ Category C: Cultivation Weapons & Artifact Icons (`03_WEAPONS`)

### `icon_weapon_flyingsword.png` (Flying Sword Jian)
```text
flat 2d vector game icon, clean cell-shaded Xianxia flying sword Jian, glowing azure spectral Qi energy aura, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic metal gradients, bevels, depth effect, hand, photo
```

### `icon_weapon_spear.png` (Azure Dragon Flame Spear)
```text
flat 2d vector game icon, clean cell-shaded Xianxia Azure Dragon spear head with dragon scales and glowing blue Qi flame aura, red silk tassel, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic metal gradients, bevels, depth effect, full character, hand, photo
```

### `icon_weapon_gauntlet.png` (Body Tempering Gauntlets)
```text
flat 2d vector game icon, clean cell-shaded dark iron body tempering gauntlet wrapped in yellow Taoist talisman cloth straps, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic metal gradients, bevels, depth effect, full arm, photo
```

### `icon_weapon_talisman_banner.png` (Daoist Array Banner)
```text
flat 2d vector game icon, clean cell-shaded Daoist spirit array banner staff with glowing red lightning runes on cloth banner, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic metal gradients, bevels, depth effect, photo
```

### `icon_gear_robes.png` (Immortal Sect Elder Robes)
```text
flat 2d vector game icon, clean cell-shaded white and sapphire blue immortal cultivation robes with golden cloud embroidery, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, character wearing it, photo
```

### `icon_gear_pendant.png` (Jade Spirit Pendant)
```text
flat 2d vector game icon, clean cell-shaded carved green jade spirit pendant with glowing Qi core hanging from golden silk thread, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, bevels, depth effect, photo
```

### `icon_gear_ring.png` (Spatial Storage Ring)
```text
flat 2d vector game icon, clean cell-shaded dark steel spatial ring with glowing purple dimensional rune gem, bold clean line art, flat color graphic design, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, bevels, depth effect, hand wearing it, photo
```

---

## ☯️ Category D: Martial Techniques & Qi Ability Icons (`04_Skills`)

### `icon_skill_m1_swordart.png` (Light Attack M1)
```text
flat 2d graphic skill icon, minimalist vector emblem of triple glowing cyan sword slash arcs, clean simple 2d silhouette graphic, flat color vector art, bold outlines, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, realistic metal, depth effect, bevels, 3d, photo, complex gradients
```

### `icon_skill_m2_heavyslam.png` (Mountain Splitting Palm M2)
```text
flat 2d graphic skill icon, minimalist vector emblem of a giant glowing golden spectral palm footprint slamming downward shattering ground with golden shockwave lines, clean simple 2d silhouette graphic, flat color vector art, bold outlines, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients
```

### `icon_skill_dodge_windstep.png` (Wind Walk Dodge)
```text
flat 2d graphic skill icon, minimalist vector emblem of a green wind aura silhouette dashing forward leaving swift shadow step gust lines, clean simple 2d graphic, flat color vector art, bold outlines, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients, detailed face
```

### `icon_skill_parry_qi_shield.png` (Bagua Qi Barrier Parry)
```text
flat 2d graphic skill icon, minimalist vector emblem of a flat glowing blue Bagua trigram shield symbol, clean simple 2d graphic, flat color vector art, bold outlines, vibrant colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients
```

### `icon_skill_sword_tempest.png` (Thousand Sword Array Q)
```text
flat 2d graphic skill icon, minimalist vector emblem of a circular array wheel of eight cyan sword blade silhouettes pointing inward around a central glowing Taoist ring, sword domain skill icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant cyan colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, dragon, palms, lightning, shield, 3d, depth effect, photo, complex gradients
```

### `icon_skill_dragon_roar.png` (Azure Dragon Spear Q)
```text
flat 2d graphic skill icon, minimalist vector emblem of a fierce eastern serpentine dragon head silhouette with glowing eyes and fangs, roaring azure blue dragon spirit, clean simple 2d graphic, flat color vector art, bold outlines, vibrant azure blue colors, centered, isolated on solid black background --ar 1:1 --no swords, slash arcs, palms, lightning, 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients
```

### `icon_skill_hundred_palms.png` (Rapid Palm Flurry Q)
```text
flat 2d graphic skill icon, minimalist vector emblem of a fan array of five purple glowing open-palm martial hand silhouettes radiating outward, palm flurry skill icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant violet purple colors, centered, isolated on solid black background --ar 1:1 --no swords, dragon, lightning, slash arcs, shield, 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients
```

### `icon_skill_tribulation_bolt.png` (Heavenly Lightning Q)
```text
flat 2d graphic skill icon, minimalist vector emblem of a single jagged crimson red lightning bolt striking vertically downward through a dark storm cloud circle, heavenly tribulation skill icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant crimson red colors, centered, isolated on solid black background --ar 1:1 --no swords, dragon, palms, slash arcs, shield, cyan blue, 3d render, soft shading, volumetric lighting, realistic smoke, 3d, depth effect, photo, complex gradients
```

---

## 🪙 Category E: Currencies, Pills & Materials (`05_Currencies`)

### `icon_currency_spiritstone_low.png` (Low-Grade Spirit Stone)
```text
flat 2d graphic item icon, Xianxia jade spirit stone crystal engraved with glowing green Taoist rune glyphs, floating Qi energy sparks, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant green colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, generic gem, 3d render, soft shading, volumetric lighting, photo
```

### `icon_currency_spiritstone_high.png` (High-Grade Spirit Stone)
```text
flat 2d graphic item icon, Xianxia radiant gold spirit crystal gem engraved with glowing golden Taoist rune glyphs, floating gold Qi energy sparks, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant gold colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, generic gem, 3d render, soft shading, volumetric lighting, photo
```

### `icon_mat_pill_qi_gathering.png` (Qi Gathering Pill)
```text
flat 2d graphic item icon, standalone hovering Xianxia blue alchemy pill, glowing translucent blue sphere with glowing azure Qi rune lines on surface, faint blue mist aura ring, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant blue colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, saucer, ceramic, tray, kitchenware, 3d render, photo
```

### `icon_mat_pill_breakthrough.png` (Foundation Breakthrough Dan)
```text
flat 2d graphic item icon, standalone hovering golden Xianxia breakthrough alchemy pill orb, radiant gold sphere with glowing ancient golden rune markings etched on surface, floating golden alchemy mist aura ring, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant gold colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, saucer, ceramic, tray, kitchenware, 3d render, photo
```

### `icon_mat_herb_ginseng.png` (1000-Year Spirit Ginseng)
```text
flat 2d graphic item icon, standalone 1000-year spirit ginseng root with glowing cyan Qi meridian vein roots, small green spirit leaves, Xianxia herb material, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, ceramic, 3d render, photo
```

### `icon_mat_demon_core.png` (Beast Demon Core)
```text
flat 2d graphic item icon, standalone glowing crimson beast demon core orb with dark demonic red flame aura, Xianxia crafting material, clean simple 2d silhouette, flat color vector art, bold outlines, vibrant crimson red colors, centered, isolated on solid black background --ar 1:1 --no plate, dish, bowl, ceramic, 3d render, photo
```

---

## 🩺 Category F: Status Effect Indicators (`06_Status`)

### `icon_status_qi_deviation.png` (Qi Deviation Stun)
```text
flat 2d graphic status icon, minimalist vector emblem of fractured red Qi meridian lines shattering apart on a dark chest silhouette, Qi deviation stun debuff, clean simple 2d graphic, flat color vector art, bold outlines, vibrant red and purple colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, depth effect, photo
```

### `icon_status_poison.png` (Corrosive Venom)
```text
flat 2d graphic status icon, minimalist vector emblem of a toxic green venom droplet bubbling with acid Qi mist, corrosive poison debuff icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant toxic green colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, depth effect, photo
```

### `icon_status_tribulation_burn.png` (Tribulation Flame Burn)
```text
flat 2d graphic status icon, minimalist vector emblem of dark crimson heavenly tribulation flames burning a warrior shadow silhouette, tribulation burn debuff icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant crimson red colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, depth effect, photo
```

### `icon_status_body_tempered.png` (Golden Bell Defense)
```text
flat 2d graphic status icon, minimalist vector emblem of a glowing golden ancient temple bell phantom encasing a meditating warrior silhouette, body tempering defense buff icon, clean simple 2d graphic, flat color vector art, bold outlines, vibrant gold colors, centered, isolated on solid black background --ar 1:1 --no 3d render, soft shading, volumetric lighting, realistic smoke, depth effect, photo
```

---

## 🏷️ Category G: Native Roblox `UIStroke` Rarity System (`07_Rarities`)

Item slot rarity borders are handled **natively in Roblox Studio** using `UIStroke` objects applied directly to `panel_grid_slot`.

### `RarityConfig.luau` Hex Color Mapping:
* **Mortal Grade:** `#FFFFFF` (White)
* **Earth Grade:** `#38E54D` (Jade Green)
* **Heaven Grade:** `#2192FF` (Sapphire Blue)
* **Spirit Grade:** `#9C2C77` (Deep Purple)
* **Sacred Grade:** `#FFD700` (Gold)
* **Immortal Grade:** `#FF1E1E` (Crimson Red)

---

## 🐍 Automated Post-Processing Script (`process_transparent_crop.py`)

After generating raw images, run this Python script to convert dark backgrounds to 100% transparent PNGs and perform tight-cropping around artwork boundaries:

```python
import os
from PIL import Image

INPUT_DIR = r"C:\Users\Admin\Desktop\ASCENDV1-Assets"
OUTPUT_DIR = r"C:\Users\Admin\Desktop\ASCENDV1-Assets-Cleaned"
BLACK_THRESHOLD = 35


def process_transparent_tight_crop(in_path, out_path):
  try:
    img = Image.open(in_path).convert("RGBA")
    width, height = img.size
    pixels = img.load()

    # 1. Background transparency
    for x in range(width):
      for y in range(height):
        r, g, b, a = pixels[x, y]
        if (
            r <= BLACK_THRESHOLD
            and g <= BLACK_THRESHOLD
            and b <= BLACK_THRESHOLD
        ):
          pixels[x, y] = (0, 0, 0, 0)

    # 2. Tight crop
    bbox = img.getbbox()
    if bbox:
      cropped_img = img.crop(bbox)
      os.makedirs(os.path.dirname(out_path), exist_ok=True)
      cropped_img.save(out_path, "PNG")
      print(f"✨ Processed: {os.path.basename(out_path)}")
  except Exception as e:
    print(f"❌ Error processing {in_path}: {e}")


for root, dirs, files in os.walk(INPUT_DIR):
  for file in files:
    if file.lower().endswith((".png", ".jpg", ".jpeg")):
      in_path = os.path.join(root, file)
      rel_path = os.path.relpath(in_path, INPUT_DIR)
      out_path = os.path.join(OUTPUT_DIR, rel_path)
      out_path = os.path.splitext(out_path)[0] + ".png"
      process_transparent_tight_crop(in_path, out_path)
```
```

---

I have updated the complete master prompt guide in `docs/AI_PROMPT_GUIDE.md` for your future reference!

Would you like to continue with the current task (generating documentation updates for `docs/AI_PROMPT_GUIDE.md`) or move on to another feature (such as beginning **Task 2.2 Roblox Studio UI Construction**)?