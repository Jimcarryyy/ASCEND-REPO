Here is the finalized **Master Production Roadmap (Phases 1 – 11)**, restructured by strict technical dependency and priority order to deliver a complete, commercially launchable Version 1.

---

### Architectural Dependency Flow

```
[Phase 1: Server Core & Remotes]          --> Eliminates server boot crashes & missing remotes
         │
[Phase 2: Architecture & Code Cleanup]    --> Purges memory leaks, circular requires & race conditions (PRIORITY)
         │
[Phase 3: Combat Kinematics & Physics]   --> Heavy M1 cadence, step-in lunges, audio/run sync, ribbons, T & E skills
         │
[Phase 4: 3D Flying Sword Flight Engine]  --> Full 3D flight locomotion, steering, speed scaling & Qi drain (V)
         │
[Phase 5: Client GUIs & Full Handshakes]  --> Spirit Pouch inventory screen, BloodlineGui, Alchemy & Boss HUD
         │
[Phase 6: Beginner Practical Walkthrough] --> Action tutorial, 3D navigation arrow lines & checkpoint HUD
         │
[Phase 7: World Economy & NPC Stations]   --> HerbNodes in world, Sword Altar Blacksmith, Vendors & Death loop
         │
[Phase 8: Weapons & 3D Asset Pipeline]    --> Arsenal expansion beyond 8 swords, 2D prompt-to-3D asset pipeline
         │
[Phase 9: Engine & Memory Optimization]   --> StreamingEnabled, 3.6 GB memory reduction to <800 MB, Mobile UI
         │
[Phase 10: Balance & Anti-Exploit]        --> Math calibration across 10 realms, economy sinks & anti-cheat
         │
[Phase 11: Master UI/UX & V1 Launch]      --> Spring tweens, audio suite, typography & release gateway
```

---

### Phase 1: Server Core Stabilization & Remote Handshake Bedrock *(Immediate)*
* **Register Missing Network Remotes (`RemoteEvents.luau`)**:
  * Register `UpdateAlchemy` (resolves client alchemy data synchronization failure).
  * Register `UpdateMobState` (resolves boss HUD posture and target synchronization failure).
  * Register `BloodlineAction` (handles client-to-server spin requests).
* **Cultivation Session Cache Hardening (`CultivationManager.luau`)**:
  * Eliminate the player lifecycle race condition so `playerData[player]` initializes synchronously on join and never returns `nil`.
* **Mob Spawner Naming & Data Resolution (`MobConfig.luau` & `MobAIManager.luau`)**:
  * Permanently inject `SPAWNER_ALIAS_MAP` in `MobAIManager.luau` so `Spawner_RogueDisciples` and `Spawner_BossFallenSwordGenius` resolve cleanly across all 79 spawners.
  * Add both `Name` and `DisplayName` properties to all mob definitions so `CreateHealthUI` never encounters `nil` text.
  * Enforce automatic unanchoring of all body parts upon mob spawn so Humanoid pathfinding and joint movement are never paralyzed.

---

### Phase 2: Architecture Hardening, Code Cleanup & Anti-Pattern Purge *(Priority)*
* **Memory Leak & Connection Audit**:
  * Implement strict connection lifecycle management (`Maid` / `Janitor` pattern or explicit `:Disconnect()` tracking) on every `RBXScriptConnection` across character spawns, combat states, and UI loops.
  * Guarantee zero dangling event listeners on player death and respawn.
* **Circular Dependency Decoupling**:
  * Eliminate all inline/circular `require()` workarounds across server managers and client controllers.
  * Enforce a clean, unidirectional 3-layer architecture:
    $$\text{Shared Configs} \longrightarrow \text{State \& Data Managers} \longrightarrow \text{Network Remotes \& Controllers}$$
* **Lifecycle Race Condition Elimination**:
  * Standardize `OnPlayerAdded` and `CharacterAdded` across `PlayerDataManager`, `CultivationManager`, and `CombatStateManager` to guarantee 100% synchronous data availability without arbitrary `task.wait()` delays.
* **Magic Number & Config Centralization**:
  * Extract all hardcoded combat speeds, damage values, offsets, and multipliers into authoritative files in `Shared/Configs/`.
  * Replace direct `Workspace` dot-indexing with streaming-safe recursive finders and timeouts.
* **Strict Typing & Network Schema Validation**:
  * Enforce `--!strict` Luau typing across all core modules.
  * Define strict exported type contracts for every RemoteEvent packet to prevent untyped table crashes.
* **Extensibility Abstraction**:
  * Ensure adding new realms, weapons, skills, mobs, and map zones in V2+ requires zero modifications to core manager code (100% config-driven).

---

### Phase 3: Combat Kinematics, Martial Cadence & Physics Hardening
* **Heavy M1 Cadence & Step-In Footwork**:
  * Set swing playback speed to **0.32x** with **0.25s anticipation windup** and **1.10s lockout** per strike (eliminates rapid combo spamming).
  * Implement phased cubic ease-out footwork steps (4.5 to 7.5 studs) along camera aim vector.
  * Enforce anti-slide ground locking (`WalkSpeed = 0` during active swing) so forward momentum is driven purely by physical lunges.
  * Attach black-bordered white calligraphy blade arc from hilt to tip on `MortalIronJian`.
* **Locomotion & Audio Synchronization**:
  * Reduce base `WalkSpeed` from 18 to **13.5 studs/s** to eliminate sliding/moonwalking.
  * Dynamically throttle `HumanoidRootPart.Running` footstep sound playback speed to **0.65x** to match boot thuds 1:1 with ground contact.
  * Scale running animation track speed to **0.65x** for long, composed strides.
* **Coated Calligraphy Ribbon Trails**:
  * Integrate layered dual-shell trails (outer black ink border + inner radiant white core) on torso attachments.
  * Clamp lifetime to **0.22s** (snappy, tight, never drags across the terrain).
  * Configure activation exclusively for **Jumps (double-helix corkscrew)**, **Dash `Shift`**, and **Attacks/Skills** (disabled while running; zero box particles).
* **Defensive Mechanics Overhaul (`T` Skill)**:
  * Rotating celestial Qi Barrier disc while holding `T` (`BlockStart`).
  * Metallic blade deflect sound (`Clang!`) and directional friction sparks on Parry.
  * Heavy impact sound and barrier ripple on Block.
  * Crystal shatter sound and exploding neon shards on Guard Break (`WasGuardBroken == true`).
* **Heavy Skill Synthesis (`E` Skill - "Void Piercing Thrust")**:
  * Guard-piercing heavy linear thrust (Q vortex windup + F sonic spatial beam).
* **Locomotion Combat Lockouts (`V` & `C`)**:
  * Gate Flying Sword mount (`V`) and Meditation (`C`) behind `InCombat == false` with immediate force-dismount and forced meditation exit if damaged.
* **Physics & State Machine Hardening**:
  * Replace dynamic HipHeight hardcoding during meditation with raycast leg measurement to prevent ground clipping across all avatar proportions.
  * Add anti-bounce vertical velocity clamp on ground landing to prevent ragdoll rebound spikes.
  * Harden ragdoll recovery state machine to guarantee players never get stuck in `PlatformStand`.

---

### Phase 4: Signature Locomotion — 3D Flying Sword Flight Engine (`V` Key)
* **Flight Configuration (`FlyingSwordConfig.luau`)**:
  * Define 3D flight physics parameters: Max Pitch, Yaw, Roll angles, Acceleration, and Realm-scaled flight velocities.
  * Define continuous internal Qi consumption rate while airborne.
* **Flight Locomotion Controller**:
  * Sword mounting animation and positioning underneath character feet with trailing Qi airflow VFX.
  * Mouse-directed 3D flight steering with smooth banking and camera tilt.
  * Qi exhaustion auto-dismount when internal Qi reaches 0.

---

### Phase 5: Client GUI Construction & Full-Stack Handshakes
* **Inventory "Spirit Pouch" GUI (`Tab` / `I`)**:
  * Build the missing **Spirit Pouch Grid ScreenGui** in `StarterGui`: Item slot grid, item inspection modal, weapon equip/unequip, and pill consumption.
  * Wire complete handshake to `InventoryController.luau` and `UpdateInventory`.
* **Bloodline Gacha Screen (`BloodlineGui` & `BloodlineController.luau`)**:
  * Build the summoning altar interface: 1x Spin, 10x Spin, rarity cards, and Buy Spins modal (500 Spirit Stones / Robux).
  * Wire client-server handshake to `BloodlineAction`.
* **Alchemy Cauldron Handshake (`AlchemyController.luau`)**:
  * Connect `AlchemyController` to the new `UpdateAlchemy` remote.
  * Full inventory herb selection into the 3 cauldron slots, real-time formula matching %, and pill condensation feedback.
* **PvP Duel Challenge Handshake (`ArenaController.luau`, `FocusTargetController.luau`)**:
  * Add client challenge interaction prompt on target focus (`Z/MMB`) to send `ChallengePlayer`.
  * Wire recipient's `SparringDuelHUD` invite modal (`[ACCEPT]` / `[DECLINE]`).
  * Add overhead visual status indicator for Karmic Retribution debuffs.
* **Master HUD & Character Sheet (`P` Key) Sync**:
  * Display Samsara Cycle prestige perks (+30% refining speed, +5% sword damage) and bloodline modifiers in `CharacterStatsController.luau` (`P` menu) and `HUDController.luau`.
* **Boss Health HUD Sync (`BossHUDController.luau`)**:
  * Wire `BossHUDController` to `UpdateMobState` for `Boss_FallenSwordGenius` and `AsuraSwordSovereign`.

---

### Phase 6: Practical Beginner Cultivator Walkthrough & Visual Guide Lines
* **Visual 3D Navigation Path**:
  * Render an undulating calligraphy guide beam on the ground leading directly to each objective.
* **Practical Action Checkpoints (`StarterGuideController.luau`)**:
  1. Awakening on `Murim_SpawnDais` $\rightarrow$ Meditate with `C` to reach 100% Qi.
  2. Footwork trial $\rightarrow$ Perform 2-stage Qi Dash with `Shift`.
  3. Martial dummy strike $\rightarrow$ Land a 5-hit M1 combo on a wooden training puppet.
  4. Gathering trial $\rightarrow$ Follow guide line to gather first 1-Yr Spirit Herb.
  5. Cauldron refinement $\rightarrow$ Craft first Breakthrough Dan at Alchemy Cauldron.
  6. Ascension $\rightarrow$ Execute first breakthrough to Foundation Establishment.
* Minimalist top-center Task Banner with automatic step progression.

---

### Phase 7: World Economy, Gathering Nodes & NPC World Stations
* **Physical Herb Gathering Nodes (`Workspace.HerbNodes`)**:
  * Populate anchored 1-Yr, 10-Yr, 100-Yr, and 1000-Yr herb nodes with ProximityPrompts for `GatheringManager`.
* **Physical Sword Altar & Blacksmith (`Workspace.SwordAltar`)**:
  * Place the physical Sword Altar station in Workspace.
  * Connect `SwordAltarManager` for weapon refinement (+1 to +10 enhancement).
* **World Vendors (`Workspace.NPCs`)**:
  * Connect `VendorManager` to NPCs for selling monster cores and herbs for Spirit Stones.
* **Cultivation Death & Reincarnation Pipeline**:
  * Set `BreakJointsOnDeath = false` to eliminate limb fragmentation.
  * Connect `DeathReincarnationController.luau` to handle non-lethal wilderness defeat, unrefined Qi penalty, and respawn at `Murim_SpawnDais`.
* **Atmospheric Visual Polish**:
  * Volumetric lightning strikes for Tribulation waves, dark Qi deviation smoke, 3D bloodline artifact prefabs in `ReplicatedStorage.Assets.Bloodlines`.

---

### Phase 8: Weapons Arsenal Overhaul & 3D Asset Pipeline
* **Arsenal Expansion Beyond 8 Swords**:
  * Expand the arsenal to 12–15 distinct cultivation blades (Heavy Dao Sabres, Sovereign Jians, Astral Rapiers) mapped across all 10 realms.
  * Unique combat passives per weapon tier (Frost Slow, Bleed, Void Blink extension).
* **2D-to-3D AI Generation Pipeline**:
  * Target text prompts for 2D concept generation to 3D meshes (Meshy AI / Blender budget $<1500$ tris).
  * Finished 3D bloodline artifacts in `ReplicatedStorage.Assets.Bloodlines`.
  * Physical 3D models for all 4 herb ages and Samsara celestial pedestals.

---

### Phase 9: Engine Optimization, Streaming & Mobile Ergonomics
* **StreamingEnabled Migration**:
  * Enable `Workspace.StreamingEnabled` (`MinRadius = 128`, `TargetRadius = 512`, `ClientPhysicsPause`).
  * Set `ModelStreamingMode = Persistent` on all critical landmarks (`Murim_SpawnDais`, `NPCs`, `MobSpawns`).
* **Memory Reduction (3.6 GB $\rightarrow$ $<800$ MB)**:
  * Audit and clean up unused meshes, textures, and unanchored geometry to prevent mobile crash-on-join.
  * Disable shadows on non-essential minor decorative lights out of the 183 lights to preserve a stable 60 FPS.
* **Mobile Cross-Platform Controls**:
  * Dedicated on-screen touch buttons in `MasterHUDGui` (Attack `M1`, Dash, Guard `T`, Skills `Q/E/F`, Flight `V`).
  * Responsive DPI scaling via `UIStrokeResponsiveScaler` and `DeWidth`.

---

### Phase 10: Global Mathematical Balance & Anti-Exploit Security
* **Mathematical Balancing**:
  * Full balance pass across all 10 realms: Damage formulas, posture pools, health scaling, Spirit Stone sinks, breakthrough Dan costs.
* **Anti-Exploit Security**:
  * Server-authoritative velocity & noclip sanity clamps.
  * Raycast line-of-sight and reach validation on combat hitboxes.
  * Transaction-safe inventory operations to prevent item duplication.

---

### Phase 11: Master UI/UX Polish & V1 Production Launch
* **Motion & Spring Tweens**:
  * Fluid UI transitions and open/close springs across all menus.
* **Sound Design & Typography**:
  * Complete UI sound suite (parchment unrolls, sword sheath clicks, gong rings).
  * Harmonized typography (Bangers headers, Fondamento lore text).
* **Production Launch Gateway**:
  * Final smoke test, analytics hooks, and server lifecycle verification.

---

### Plan Locked
This 11-phase master plan covers every server, client, kinematic, economic, architectural, and visual requirement for Version 1.

Whenever you are ready, confirm and we will begin **Phase 1: Server Core Stabilization & Remote Handshake Bedrock**.


Here are the 4 new floating orb relics, completely purging the old bracers,
anklets, and chestplates.

Every relic is now designed as a stylized floating spirit orb/sphere (matching
the exact aesthetic and shoulder orbit of JadeLotusOrb and CosmicVoidSphere).

1. SteelSwordOrb (Replaces SteelMeridianGlow)

  - Bloodline: Mortal Sword Bone · Tier: COMMON
  - Theme: Tempered Steel & Sword Intent · Aura Tint: 190, 210, 225 (Steel
    Silver)

Stylized low-poly Xianxia cultivation game asset. Chunky readable polygonal forms, clean flat-shaded faceted planes, visible crisp polygon edges, simplified geometric shape language with bold primary masses and no fussy micro-detail. Hand-painted vibrant saturated colors, punchy high-chroma color blocking, clean two-tone shading ramps, strong value separation between adjacent surfaces. Stylized anime cultivation-game aesthetic in the vein of high-quality mobile RPG hero equipment. Bold silhouette, exaggerated proportions, confident sharp bevels, decorative carved detail expressed as simple chiseled planes rather than fine engraving. A single floating sword-intent spirit orb relic presented dead-on in perfect vertical symmetry, floating alone with no body, no stand, no pedestal. In the center sits a perfectly smooth rounded metallic steel orb in bright polished silver-white with an ice-blue core sheen. Encircling the sphere is a chunky faceted white-iron sword-guard ring with four short stylized blade-tip spurs extending outward at 90-degree angles, each cut with clean flat bevels. Fastened to the ring are simple cobalt-blue geometric gem insets with cool steel-blue chiseled grooves. Symmetrical, upright, solid single object. Palette: bright silver-white steel, luminous ice blue, vivid cobalt accents, mid slate-grey ring bracket. Single isolated object, one object only, centered in frame with even 12% empty margin on all sides, complete object fully visible, nothing cropped or cut off. Solid pure black background, flat #000000, completely empty void, no floor, no ground plane, no cast shadow, no contact shadow, no reflection, no pedestal, no backdrop gradient, no environment of any kind. The object never blends into the background: every silhouette edge stays clearly lighter than pure black, darkest materials rendered as charcoal and slate rather than true black, crisp clean cutout-ready outer edge. Straight-on orthographic front view. Object perfectly upright. Vertical symmetry axis dead center. Camera level with the object's mid-height. Zero perspective distortion, zero camera tilt, zero roll, zero dutch angle. Even bright soft studio lighting from the front, flat diffuse illumination, every surface clearly readable, no unlit black areas, no blown-out white highlights, no rim light, no backlight, no colored light spill. Matte to semi-matte surfaces, color produced by pigment and material only. Clean crisp product-style 3D render, sharp focus, high clarity, full object edge to edge.

2. IronRootOrb (Replaces IronRootCore)

  - Bloodline: Iron Meridian Root · Tier: COMMON
  - Theme: Forged Iron & Earth Roots · Aura Tint: 160, 120, 90 (Warm
    Copper/Bronze)

Stylized low-poly Xianxia cultivation game asset. Chunky readable polygonal forms, clean flat-shaded faceted planes, visible crisp polygon edges, simplified geometric shape language with bold primary masses and no fussy micro-detail. Hand-painted vibrant saturated colors, punchy high-chroma color blocking, clean two-tone shading ramps, strong value separation between adjacent surfaces. Stylized anime cultivation-game aesthetic in the vein of high-quality mobile RPG hero equipment. Bold silhouette, exaggerated proportions, confident sharp bevels, decorative carved detail expressed as simple chiseled planes rather than fine engraving. A single floating iron-root meridian spirit orb presented dead-on in perfect vertical symmetry, floating alone with no character, no pedestal, no mount. At the center sits a large, smooth rounded polished copper-orange metallic sphere. The orb is cradled from below by a chunky symmetrical cage of simplified tube-like root filigree in dark burnished bronze, with four thick beveled claw prongs curving upward around the sphere's sides, each prong capped with a flat gold bead. An outer octagonal bronze ring bracket with flat chamfered edges frames the lower half of the orb, inlaid with warm amber geometric seal notches. Palette: glowing copper-orange core sphere, vivid burnished bronze root cage, rich amber accents, mid charcoal-grey casing, bright gold highlight edges. Single isolated object, one object only, centered in frame with even 12% empty margin on all sides, complete object fully visible, nothing cropped or cut off. Solid pure black background, flat #000000, completely empty void, no floor, no ground plane, no cast shadow, no contact shadow, no reflection, no pedestal, no backdrop gradient, no environment of any kind. The object never blends into the background: every silhouette edge stays clearly lighter than pure black, darkest materials rendered as charcoal and slate rather than true black, crisp clean cutout-ready outer edge. Straight-on orthographic front view. Object perfectly upright. Vertical symmetry axis dead center. Camera level with the object's mid-height. Zero perspective distortion, zero camera tilt, zero roll, zero dutch angle. Even bright soft studio lighting from the front, flat diffuse illumination, every surface clearly readable, no unlit black areas, no blown-out white highlights, no rim light, no backlight, no colored light spill. Matte to semi-matte surfaces, color produced by pigment and material only. Clean crisp product-style 3D render, sharp focus, high clarity, full object edge to edge.

3. WindGaleOrb (Replaces WindGaleAnklets)

  - Bloodline: Breeze Spirit Vein · Tier: COMMON
  - Theme: Wind Spirit & Mint Jade · Aura Tint: 150, 235, 200 (Pale Mint &
    Seafoam)

Stylized low-poly Xianxia cultivation game asset. Chunky readable polygonal forms, clean flat-shaded faceted planes, visible crisp polygon edges, simplified geometric shape language with bold primary masses and no fussy micro-detail. Hand-painted vibrant saturated colors, punchy high-chroma color blocking, clean two-tone shading ramps, strong value separation between adjacent surfaces. Stylized anime cultivation-game aesthetic in the vein of high-quality mobile RPG hero equipment. Bold silhouette, exaggerated proportions, confident sharp bevels, decorative carved detail expressed as simple chiseled planes rather than fine engraving. A single floating wind spirit orb presented dead-on in perfect vertical symmetry, floating alone with no character, no body, no pedestal. In the center sits a smooth rounded sphere of luminous seafoam-turquoise jade. Encircling the orb is a chunky, faceted circular ring in pale mint-jade green, adorned with twin symmetrical stylized cloud-scroll brackets on the left and right, sculpted with bold flat stepped planes and sharp inward-curling tips. Two short sculptural faceted silk ribbon curls in warm cream and turquoise wrap symmetrically around the bottom of the jade ring like a cradle. Palette: vivid seafoam-turquoise core sphere, bright mint-jade ring, warm cream silk curls, saturated gold ring-accent studs. Single isolated object, one object only, centered in frame with even 12% empty margin on all sides, complete object fully visible, nothing cropped or cut off. Solid pure black background, flat #000000, completely empty void, no floor, no ground plane, no cast shadow, no contact shadow, no reflection, no pedestal, no backdrop gradient, no environment of any kind. The object never blends into the background: every silhouette edge stays clearly lighter than pure black, darkest materials rendered as charcoal and slate rather than true black, crisp clean cutout-ready outer edge. Straight-on orthographic front view. Object perfectly upright. Vertical symmetry axis dead center. Camera level with the object's mid-height. Zero perspective distortion, zero camera tilt, zero roll, zero dutch angle. Even bright soft studio lighting from the front, flat diffuse illumination, every surface clearly readable, no unlit black areas, no blown-out white highlights, no rim light, no backlight, no colored light spill. Matte to semi-matte surfaces, color produced by pigment and material only. Clean crisp product-style 3D render, sharp focus, high clarity, full object edge to edge.

4. AzureDragonOrb (Replaces AzureDragonBracer)

  - Bloodline: Azure Dragon Meridian · Tier: RARE
  - Theme: Draconic Spirit & Electric Cyan · Aura Tint: 34, 211, 238 (Cyan &
    Gold)

Stylized low-poly Xianxia cultivation game asset. Chunky readable polygonal forms, clean flat-shaded faceted planes, visible crisp polygon edges, simplified geometric shape language with bold primary masses and no fussy micro-detail. Hand-painted vibrant saturated colors, punchy high-chroma color blocking, clean two-tone shading ramps, strong value separation between adjacent surfaces. Stylized anime cultivation-game aesthetic in the vein of high-quality mobile RPG hero equipment. Bold silhouette, exaggerated proportions, confident sharp bevels, decorative carved detail expressed as simple chiseled planes rather than fine engraving. A single floating Eastern dragon spirit orb presented dead-on in perfect vertical symmetry, floating alone with no character, no shoulder, no pedestal. In the dead center sits a large, smooth rounded celestial dragon pearl sphere in brilliant electric cyan. Cradling the bottom half of the sphere is a chunky dragon-claw bracket in rich polished gold with three thick faceted ivory-bone talons curving upward to clasp the orb. Two swept-back golden dragon horns flare outward symmetrically from the upper sides of the bracket, and layered geometric dragon scales in deep teal and electric cyan form a neat triangular bottom base. Symmetrical, chunky low-poly facets, bold silhouette, clean single object. Palette: brilliant electric cyan core sphere, deep oceanic teal scales, rich polished gold cradle and horns, bright bone-ivory claws. Single isolated object, one object only, centered in frame with even 12% empty margin on all sides, complete object fully visible, nothing cropped or cut off. Solid pure black background, flat #000000, completely empty void, no floor, no ground plane, no cast shadow, no contact shadow, no reflection, no pedestal, no backdrop gradient, no environment of any kind. The object never blends into the background: every silhouette edge stays clearly lighter than pure black, darkest materials rendered as charcoal and slate rather than true black, crisp clean cutout-ready outer edge. Straight-on orthographic front view. Object perfectly upright. Vertical symmetry axis dead center. Camera level with the object's mid-height. Zero perspective distortion, zero camera tilt, zero roll, zero dutch angle. Even bright soft studio lighting from the front, flat diffuse illumination, every surface clearly readable, no unlit black areas, no blown-out white highlights, no rim light, no backlight, no colored light spill. Matte to semi-matte surfaces, color produced by pigment and material only. Clean crisp product-style 3D render, sharp focus, high clarity, full object edge to edge.

Universal Negative Prompt (One-Click Copy)

glow, glowing, emissive, bloom, light bleed, lens flare, god rays, aura, energy aura, halo of light, magic effect, spell effect, particles, sparks, embers, smoke, mist, fog, dust, trails, motion blur, speed lines, fire, electricity arcs, energy wisps, floating debris, background elements, environment, scenery, sky, stars, nebula, clouds, floor, ground, pedestal, base stand, shadow, drop shadow, reflection, mirror, water, dark silhouette, object blending into background, black on black, low contrast, underexposed, character, human, body, hand, arm, mannequin, torso, head, face, bust, multiple objects, duplicates, multiple views, turnaround sheet, reference sheet, grid, collage, split screen, text, letters, watermark, logo, signature, UI, frame, border, vignette, gradient background, busy background, photorealistic, realistic, hyperrealistic, high-poly, dense detail, noisy texture, cluttered greebles, perspective distortion, tilted, rotated, upside down, cropped, out of frame, blurry, low resolution, transparent, see-through, hollow, paper thin, wireframe, exploded view
