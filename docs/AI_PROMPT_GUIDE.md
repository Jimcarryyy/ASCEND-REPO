# ASCEND — AI PROMPT GUIDE & ASSET GENERATION SPECIFICATIONS

> **Source of Truth for 2D UI & 3D Asset Generation**  
> This guide defines the exact prompt structures, style guidelines, and post-processing steps used to generate all 3D game models for **ASCEND**.

---

## 🏛️ Core Design Principles

### 1. Stylized-Realism / Painted Low-Poly Aesthetic (3D Assets)
* **Geometry:** Clean, optimized low-polygon geometry (**Target Polycount: ~3,000 Triangles** for 60 FPS mobile performance).
* **Textures:** Smooth hand-painted gradient textures with vibrant colors and high-contrast accents.
* **PBR Workflow:** Uses clean Albedo/Color maps with optional normal/roughness maps for metallic weapon highlights.

---

## 🗡️ Master 3D Generation Prompts for 5 Base Sword Models

1. **Jade / Dragon Master Sword (Nine-Dragon & Azure Jade):**
   ```text
   Stylized Xianxia dragon flying sword, translucent jade green double-edged blade with gold filigree, ornate gold coiled dragon guard with glowing emerald dragon pearl, high quality hand painted gradient texture, clean low poly 3D model, 3k polys, game ready

Flame / Magma Master Sword (Sun-Slayer & Crimson Flame):
code
Text
Stylized Xianxia flame greatsword, dark volcanic magma glass blade with glowing orange lava veins, golden phoenix wing guard, smooth hand painted gradient texture, low poly 3k polys, game ready
Void / Cosmic Master Sword (Heavenly Void & Shadow Void):
code
Text
Stylized Xianxia cosmic sword, sleek dark obsidian and purple steel blade with glowing white spatial runes, floating amethyst crystal shards near hilt, gold wing guard, low poly 3k polys
Thunder / Frost Master Sword (Frost-Dragon & Celestial Thunder):
code
Text
Stylized Xianxia frost dragon sword, translucent ice-cyan crystal jade blade, silver dragon claw guard with glowing blue eyes, crackling lightning aura, low poly 3k polys
Mortal / Physical Starter Sword (Mortal Iron & Spirit Steel):
code
Text
Stylized Xianxia cultivator iron sword, clean polished steel blade, simple bronze ring pommel, brown leather wrapped grip, low poly 2k polys