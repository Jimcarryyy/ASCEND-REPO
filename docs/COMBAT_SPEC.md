# ASCEND-V1 — PURE SWORD CULTIVATOR COMBAT SPECIFICATION

> **Technical Specification Document**  
> **Master Entry Point:** https://raw.githubusercontent.com/Jimcarryyy/ASCEND-REPO/main/ASCEND.md  
> **Scope:** Server-Authoritative Sword Engine, Flexible Jade Scrolls, Hitboxes, Defensive Mechanics, & Qi Formulas.

---

## 1. Security Architecture & Server Intent Pipeline

Combat operates strictly on a zero-trust Intent-Execution Pipeline:

```text
[CLIENT]                                    [SERVER]
  |                                            |
  +--- 1. Press Key (Fire CombatAction Payload)->|
  |                                            |-- 2. Validate Cooldowns (os.clock())
  |                                            |-- 3. Validate Qi Reserves & Stun State
  |                                            |-- 4. Check Equipped Jade Scroll in Slot
  |                                            |-- 5. Execute Shapecast / Spatial Query
  |                                            |-- 6. Apply Damage & Qi Status Effects
  |<-- 7. Replicate Visual Effects / Hits -----|

2. Classical ARPG Keybind Scheme & Hotbar Slots
Input	Action	Slot Function
LMB	Light Sword Combo String	4-step telekinesis slash string (Steps 1 
→
→
 2 
→
→
 3 
→
→
 Finisher 4)
F	Parry / Block Art	Bagua Qi Barrier / Sword Guard
Q	Sword Art Slot 1	Flexible Jade Scroll Skill 1 (e.g. Sword Tempest / Void Slash)
E	Sword Art Slot 2	Flexible Jade Scroll Skill 2 (e.g. Telekinesis Thrust / Flame Cleave)
R	Ultimate Sword Scripture	Flexible Jade Scroll Ultimate (e.g. Sword Barrage / Sun Eruption)
Shift	Windstep Dash	Directional Dodge (AssemblyLinearVelocity impulse + motion trail)
G	Qi Meditation Toggle	Floating levitating cultivation pose + fast Qi absorption loop
B	Realm Breakthrough	Heavenly Tribulation Lightning Event
I	Spirit Pouch Modal	Opens Character Hub, Inventory, and Viewport Doll
3. Dynamic Sword Art Jade Scrolls (Flexible Build Freedom)
Players do not pick a rigid class. They collect, equip, and upgrade Sword Art Jade Scrolls into Q, E, R, F, and Shift slots:
Sword Art Scroll	Element	Slot	Combat Identity	Damage Multiplier
VoidSlashScroll	Void / Space	Q	Launches 3D telekinetic crystal shards forward	
1.2
×
1.2×
 Base
FlameCleaveScroll	Magma / Fire	E	Heavy broadsword cleave igniting ground fissures	
1.8
×
1.8×
 Base (Guard Break)
DragonParryScroll	Wind / Jade	F	Coiled dragon aura deflecting hits & restoring Qi	0 Damage (Parry Stun)
SunEruptionScroll	Volcanic Heat	R	Massive fiery sword strike with AOE blast	
2.5
×
2.5×
 Base
4. Visual Interaction Modes (Skin vs. Skill VFX)
Players toggle between two visual modes in Character Settings:
Cross-Elemental Contrast (Default): Sword keeps its 3D cosmetic mesh (e.g. Magma Blade), while skill slashes retain their Jade Scroll color (e.g. Void Purple).
Elemental Resonance (Skin-Infused): CombatVFXController.luau automatically tints all equipped skill slash trails to match the equipped 3D Sword Skin's color theme!