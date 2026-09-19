# ASCEND — Xianxia Pure Sword Cultivator Action RPG

> **High-Performance Roblox Xianxia Action RPG**  
> **Repository:** `Jimcarryyy/ASCEND-REPO` | **Branch:** `main`  
> **Avatar Rig:** Roblox R6 Standard  
> **Active Roadmap Phase:** Phase 2 — Architecture Cleanup & Anti-Pattern Purge  
> **Production Status:** Phase 1 Complete & Verified (9/9 Monkey Verify Checks Passed)

---

## 🗡️ Project Overview

**ASCEND** is an authentic Eastern Immortal Cultivation (Xianxia) Action RPG engineered strictly on the standardized Roblox R6 avatar rig. The experience merges high-cadence martial sword combat, an exponential 10-realm internal cultivation curve, daily sect life, crafting professions (Alchemy, Refinement, Tea Brewing), and strict server-authoritative state synchronization.

### Technical Baseline
- **Avatar Hierarchy:** Roblox Standard R6. Rigid joint hierarchy, responsive martial arts keyframing, deterministic raycast hitboxes, and a stable 60 FPS mobile performance envelope.
- **Persistence Engine:** `ASCEND_PlayerData_V3` running server-authoritative DataStores with backward-compatible schema migration, Bloodline Meridian Vault pity tracking, Samsara cycle records, and authoritative `RouteToSpawnDais` positioning.
- **Network Pipeline:** 16 centralized, strictly typed (`--!strict`) `RemoteEvent` instances in `src/ReplicatedStorage/Shared/Network/RemoteEvents.luau`.
- **UI Architecture:** Studio-authoritative `StarterGui` hierarchies constructed via Edit Mode scripts. Programmatic `Instance.new` GUI generation in client runtime scripts is prohibited.
- **Visual Identity:** Traditional Xianxia martial aesthetic with sharp rectangular plaques, dark celestial slate containers, multi-stop gradients, and an absolute **Zero UICorner** mandate.

---

## 🗺️ Master Production Roadmap (Phases 1 – 11)

```text
[PHASE 1: Core Foundations & Verification]        --> [CLOSED] DataStore V3, Murim Dais, 16 Typed Remotes, 10 R6 Mobs
         │
[PHASE 2: Architecture & Codebase Cleanup]        --> [ACTIVE] Connection lifecycles, circular require decoupling, --!strict
         │
[PHASE 3: Combat Kinematics & Martial Cadence]    --> [PENDING] Heavy M1 slashes, step-in lunges, ribbon trails, T & E skills
         │
[PHASE 4: 3D Flying Sword Flight Engine]          --> Dynamic realm speed scaling (48+ studs/s), 25 Qi/s drain, camera bank
         │
[PHASE 5: Client GUIs & Subsystem Handshakes]     --> Spirit Pouch inventory grid, BloodlineGui, Alchemy Cauldron, Boss HUD
         │
[PHASE 6: Beginner Practical Walkthrough]         --> Action tutorial, calligraphy 3D guide lines & progressive task HUD
         │
[PHASE 7: World Economy & NPC Stations]           --> Anchored herb gathering nodes, Blacksmith forge, Tea House buffs
         │
[PHASE 8: Competitive Sparring Arena]             --> Ranked duel queue, Sector 3 Elo rating, spectating & honor market
         │
[PHASE 9: Multi-Zone Expansion (Zone 2)]          --> Verdant Bamboo Valley terrain, higher-tier herbs, and advanced sects
         │
[PHASE 10: Samsara Rebirth & Endgame Loop]        --> Immortal Ascension Order 9 reset cycle, celestial titles & permanent perks
         │
[PHASE 11: Production Profiling & Launch Hardening]--> StreamingEnabled audit, <800 MB memory ceiling, cross-platform mobile
🎮 Canonical Master Keybind Map
Keybind	Combat / World Action	Mechanical Execution	Resource / Cooldown
M1	5-Hit Flying Sword Chain	Heavy sword chain. WalkSpeed dampened to 8 studs/s; AutoRotate locked against RootJoint twist. Hits grant +25% Intent.	None / 
0.20
s
−
0.35
s
0.20s−0.35s
Left Control	Sprint Toggle	Toggles Walk (13.5 studs/s) 
↔
↔
 Sprint (36 studs/s open world / 30 arena).	None / None
Left Shift	Qi Flash-Step Dash	4-way camera-relative burst over 0.16s with Shunpo vanish/reappear VFX and anti-trip AlignOrientation.	3% Qi / 
3.0
s
3.0s
T (Hold)	Guard (Posture Block)	Frontal 180° guard arc absorbing 80% damage and 70% knockback via Posture.	Posture / None
T (Tap 
<
0.22
s
<0.22s
)	Perfect Parry	100% damage negation via Workspace:GetServerTimeNow(), 0.5s attacker stagger, +5% Qi restoration.	None / None
C	Qi Meditation	Grounded cultivation. Restores 10.0% Qi/s. Gated behind InCombat == false.	None / None
R	Draw / Sheathe Sword	Toggles Flying Sword between RightGripAttachment (hand) and upper back torso mount.	None / 
0.5
s
0.5s
V	Flying Sword Flight Mode	Mounts sword under feet for 3D flight. Velocity scales with realm (48+ studs/s). Auto-dismounts at 0 Qi or on hit.	25 Qi/s / None
B	Realm Breakthrough	Initiates Dantian breakthrough when Cultivated Qi is 100%. Triggers Inner Demon QTE or Tribulation Lightning.	100% Qi / Variable
Q	Skill: Sword Tempest	Point-blank 360° cleave + 3 forward sawblades. Vector3.zero knockback slices targets in place.	15% Qi / 
3.5
s
3.5s
E	World Interact / Skill E	Primary world interaction (ProximityPrompts, Bloodline Altar). When drawn: Piercing Void Thrust beam.	12% Qi / 
5.0
s
5.0s
F	Ultimate: Flash Domain	28-stud instant Celestial Flash-Step through enemies + mid-air slice + 36-stud domain detonation.	20% Qi / 
5.5
s
5.5s
H	Heavenly Codex	Opens the in-game feature manual and sect guidebook (CodexGui).	None / None
P	Character Stats Sheet	Toggles character overview: Realm, Order, Attributes, Samsara rank, and active Bloodline.	None / None
Tab / I	Spirit Pouch (Inventory)	Opens spatial inventory pouch for pills, herbs, beast cores, and artifacts.	None / None
🏛️ Core Subsystem Architecture
1. Cultivation & Breakthrough Engine
10 Major Realms × 9 Orders (90 Stages): Calibrated progression curve spanning from Qi Condensation to Immortal Ascension.
Starting Qi Clamp: Players initialize with a 20% starting Qi pool; full capacity requires active meditation.
Inner Demon & Tribulation Trials: Breakthroughs require exact multiset Breakthrough Dan recipes and passing client QTE focus trials. Major realms summon volumetric Tribulation Lightning.
2. Bloodline Meridian Vault
12 Canonical Lineages: Ranging across Common (Mortal Sword Bone, Iron Meridian Root, Breeze Spirit Vein), Uncommon, Rare, Epic, Legendary (including Glacial Phoenix), and Mythic (Void Sovereign, Nine Nether Sovereign).
Pity Engine: Authoritative DataStore tracking with guaranteed Legendary at 30 pulls and Mythic at 100 pulls.
Floating Companion Relics: Body-clinging armor meshes are completely replaced with floating companion spirit orbs and halos (ARTIFACT_OFFSETS).
3. Bestiary & Mob AI Engine
100% Pure Humanoid R6 Cultivators: All quadruped beast rigs are purged. Zone encounters consist of 10 Humanoid R6 Cultivators utilizing SPAWNER_ALIAS_MAP, unanchored joint articulation, and Boids flocking separation. Graded beast cores remain as item tokens for alchemy.
4. Sacred Weaponry & Economy
Sacred Weapon Policy: Flying swords are holy artifacts and cannot be sold in the general merchant shop. Weapons are obtained exclusively through Sect advancement, boss drops, and the Sword Altar.
📂 Repository Directory Guide
code
Text
ASCEND-REPO/
├── .ai/                    # Development state tracking (CURRENT_TASK, DECISIONS, CHANGELOG)
├── docs/                   # Authoritative technical specifications and manifests
├── src/
│   ├── ReplicatedFirst/    # Client pre-load scripts (LoadingScreen)
│   ├── ReplicatedStorage/  # Shared configs, network remotes, and client assets
│   ├── ServerScriptService/# Server managers (Combat, Cultivation, State, World)
│   ├── StarterGui/         # Studio-authoritative GUI hierarchies (Zero UICorner)
│   └── StarterPlayer/      # Client controllers, camera modules, and input binders
└── raw_links.txt           # Live repository file index