---

# 8. `docs/ASSET_MANIFEST.md`

```markdown
# ASCEND-V1 — CULTIVATION 2D/3D ASSET MANIFEST & DESIGN PHILOSOPHY

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** 3D Sword Models, 3D Floating Back-Crests, 2D Skill Icons, UI Textures, & Audio SFX.

---

## 1. 3D Mythic Paired Assets Manifest

All 3D models are generated in Meshy AI (Standard Mode), reduced to ~3,000 triangles, and imported as `.FBX` packages into Roblox Studio:

| Set Name | Element / Path | 3D Sword Model | 3D Floating Back-Crest Model | Studio Location |
| :--- | :--- | :--- | :--- | :--- |
| **`Heavenly Void Set`** | Cosmic / Space | `HeavenlyVoidBlade.fbx` | `HeavenlyVoidBackCrest.fbx` | `ReplicatedStorage` ✅ |
| **`Sun-Slayer Crimson Set`** | Magma / Fire | `SunSlayerCrimsonBlade.fbx` | `CrimsonFlameBackCrest.fbx` | `ReplicatedStorage` 🚀 |
| **`Nine-Dragon Sovereign Set`** | Jade / Wind | `NineDragonSovereignBlade.fbx` | `AzureDragonBackCrest.fbx` | `ReplicatedStorage` 🚀 |
| **`Frost-Dragon Flared Set`** | Ice / Frost | `FrostDragonFlaredBlade.fbx` | `FrostDragonBackCrest.fbx` | `ReplicatedStorage` 🚀 |

---

## 2. Cultivation Rarity Tiering Pipeline

Items, Jade Scrolls, and Sword Skins scale across standardized **Cultivation Rarity Grades**:

| Rarity Grade | Hex Color Code | Spiritual Identity | Visual Attributes |
| :--- | :--- | :--- | :--- |
| **Common Grade** | `#FFFFFF` (White) | Base mortal steel / bamboo | Plain metal/wood, zero Qi glow |
| **Uncommon Grade** | `#38E54D` (Jade Green) | Refined spirit-steel | Smooth metallic sheen, faint green border |
| **Rare Grade** | `#2192FF` (Sapphire Blue) | Infused with Spirit Qi | Translucent jade blade, glowing edge line |
| **Epic Grade** | `#9C2C77` (Deep Purple) | Formed from Ancient Spirit Veins | Sculpted elemental guard, bright energy channels |
| **Legendary Grade** | `#FFD700` (Gold) | Ancient magma / dragon artifact | Flared wide blade throat, 3D creature guard |
| **Mythic Grade** | `#FF1E1E` (Crimson / Cosmic) | Born from Heavenly Tribulation | Engraved glowing Dao runes + 3D floating crystal shards |

---

## 3. UI Asset & Roblox Decal Mapping (`UIAssets.luau`)

### HUD & Panel UI Textures
* **Reticle Dot**: `rbxassetid://91967824711199`
* **Slot Base**: `rbxassetid://130801066203315`
* **Key Badge**: `rbxassetid://100047016230704`
* **Boss Frame**: `rbxassetid://135743022798866`
* **Slot Active**: `rbxassetid://101243757444363`
* **Tribulation Bar**: `rbxassetid://116053311300978`
* **Cooldown Mask**: `rbxassetid://122590929808037`
* **Modal Background**: `rbxassetid://107541216755976`
* **Header Banner**: `rbxassetid://98859547252438`
* **Divider Line**: `rbxassetid://84097505475730`
* **Button Primary**: `rbxassetid://85491533300951`

### Sword Art Skill Icons
* **M1 Sword Art**: `rbxassetid://105049604836680`
* **Heavy Slam / Parry**: `rbxassetid://112434505017874`
* **Sword Tempest**: `rbxassetid://78370022706412`
* **Dragon Roar / Thrust**: `rbxassetid://125652382062875`
* **Tribulation Bolt / Barrage**: `rbxassetid://128833809862475`
* **Dodge Windstep**: `rbxassetid://112980465072041`

---

## 4. Audio SFX Registry (`CombatVFXController.luau`)

* **Weapon Swing SFX**: `rbxassetid://1222216`
* **Impact Hit SFX**: `rbxassetid://5633903110`
* **Thunder Impact SFX**: `rbxassetid://13837931480`