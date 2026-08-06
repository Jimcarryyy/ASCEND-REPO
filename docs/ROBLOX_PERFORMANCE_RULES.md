# ⚡ ROBLOX PERFORMANCE RULES & OPTIMIZATION SPEC (ASCEND V1)

## Purpose
This document defines performance budgets, optimization rules, and anti-patterns for all ASCEND assets and code.

## Document Connectivity
- Use this guide when importing assets, writing combat loops, or optimising Studio content.
- Pair it with `docs/ASSET_MANIFEST.md` for asset budget validation and `docs/ARCHITECTURE_SPEC.md` for performance-sensitive code architecture.
- It does not define game mechanics or economy rules.

## 📌 OVERVIEW & CORE PHILOSOPHY
This document serves as the mandatory technical performance guide for ASCEND. Over 60% of Roblox players access games via mobile devices (iOS/Android) and low-end hardware. To prevent client memory crashes, thermal throttling, and frame drops, all 3D assets, UI panels, combat scripts, and world structures MUST strictly adhere to these performance budgets.

---

## 📐 1. POLYGON & MESH BUDGETS

To ensure smooth 60 FPS rendering across all client platforms, all imported 3D `.fbx` meshes must observe the following hard triangle caps:

| Asset Category | Max Triangle Budget | Material & Shading Style | Optimization Target |
| :--- | :--- | :--- | :--- |
| **Player Avatar + Sword + Back Armor** | **< 8,000 tris total** | Smooth/Flat-Shaded Stylized | 🟢 Ultra-Fast |
| **World Props (Trees, Rocks, Fences)** | **200 – 1,500 tris each** | Flat-Shaded Faceted Low-Poly | 🟢 Low Memory |
| **World Structures (Pavilions, Altars)** | **1,000 – 3,000 tris** | Medium-Poly Clean Geometry | 🟢 Fast Stream |
| **World Bosses (Magma Dragon, etc.)** | **3,000 – 6,000 tris** | Faceted Low-Poly Monster Mesh | 🟢 Smooth Combat |
| **Gatherable Nodes (Herbs, Minerals)** | **100 – 400 tris** | Flat-Shaded Low-Poly | 🟢 Zero-Lag Spawns |

---

## 🖼️ 2. TEXTURE & MEMORY BUDGETS

High-resolution textures are the #1 cause of mobile app force-closes (Out-Of-Memory crashes).

1. **Texture Resolution Caps**:
   * **Character Gear & Weapons**: Maximum $1024 \times 1024$ resolution.
   * **World Environment Props & Trees**: Maximum $512 \times 512$ resolution OR single color palette texture atlases.
   * **UI Icons & Badges**: Maximum $256 \times 256$ PNG textures.
2. **Material Restrictions**:
   * **DO NOT USE** 4K PBR textures (Normal, Roughness, Displacement maps) for world terrain.
   * Use Roblox `SmoothPlastic` or `Neon` (for emissive Qi glow) with Vertex Colors / Texture Atlases.
3. **Target RAM Memory Footprint**:
   * Total game client RAM allocation MUST remain **< 500 MB** at all times.

---

## 🛠️ 3. SCRIPTING & CODEBASE PERFORMANCE RULES

1. **Zero Allocation in Combat Loops**:
   * NEVER use `Instance.new()` inside `Heartbeat`, `RenderStepped`, or high-frequency hitboxes. Pre-create object pools for hitboxes, damage numbers, and particle effects.
2. **Server-Authoritative Hitboxes**:
   * Utilize `HitboxManager.luau` using spatial overlap queries (`Workspace:GetPartsInPart()` or `GetPartBoundsInBox()`). Never trust client hit detection.
3. **Workspace Streaming**:
   * Enable `Workspace.StreamingEnabled` in Roblox Studio to dynamically stream low-poly world chunks based on player proximity.

---

## 🚫 4. DEVELOPMENT ANTI-PATTERNS (WHAT NOT TO DO)

* ❌ **DO NOT** import raw, unoptimized 3D models from external stores exceeding 10,000 triangles.
* ❌ **DO NOT** use Roblox high-density smooth terrain tools; use medium-poly custom mesh terrain blocks.
* ❌ **DO NOT** attach unpooled Light objects or dynamic shadow casters to small particles.