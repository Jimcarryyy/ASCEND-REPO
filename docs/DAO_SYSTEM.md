# ASCEND — Sword Dao System Architecture Specification

> **Interface Contract & Extensibility Blueprint**  
> **Target Version:** Combat V1 Baseline & Post-V1 Multi-Dao Expansion  
> **Status:** Architecture Locked (Single-Kit V1 Baseline per ADR-082)

---

## 1. Architectural Overview & V1 Governing Principles
In Combat V1, the game ships exactly **ONE** fully balanced, polished martial combat kit (**Thunder**, unnamed to the player). To prevent technical debt when adding future Sword Daos (e.g. Fire, Wind, or Water Dao), the underlying architecture is shaped to be data-driven and extensible.

All combat skills adhere to a shared functional slot contract:
- **`Q`:** AoE Zone Control & Melee Disruption
- **`E`:** Single-Target Piercing Pressure
- **`F`:** High-Velocity Mobility & Finisher
- **`Shift`:** Directional Qi Dash

---

## 2. Dao Registry Contract (`FlyingSwordConfig.Daos`)
Future Daos must be declared as standalone modules or tables within `FlyingSwordConfig.Daos`. Core scripts (`CombatStateManager.luau`, `FlyingSwordServer.luau`, `InputController.luau`) must query the player's active Dao dynamically.

```luau
export type DaoDefinition = {
    Name: string,
    Skills: {
        Q: SkillDef,
        E: SkillDef,
        F: SkillDef,
        Shift: SkillDef,
    },
    VFXPalette: {
        SlashColor: ColorSequence?,
        ScreenTint: Color3?,
        ImpactParticleId: string?,
    },
    IntentPayoff: {
        PayoffType: string,
        Value: number?,
        Radius: number?,
    },
    BaseAttributes: {
        WalkSpeed: number,
        ArenaWalkSpeed: number,
        SprintSpeed: number,
        ArenaSprintSpeed: number,
        DashDistance: number?,
        DashType: "IFrameBlink" | "HyperArmor",
        MaxPosture: number,
        BlockDamageReduction: number,
        PostureRegenDelay: number,
    },
}

3. Generic Status Effect Engine Contract (HitboxManager.luau)
To support status effects (such as Fire's future Blazeburn or Ice's Chill) without hardcoded branching, HitboxManager.luau maintains a centralized status runner:
code
Luau
HitboxManager.ActiveStatusEffects: {
    [Model]: {
        [string]: {
            StartTime: number,
            Duration: number,
            TickInterval: number,
            LastTick: number,
            Stacks: number,
            MaxStacks: number,
            DamagePerTick: number,
            OnTick: ((target: Model) -> ())?,
            OnExpire: ((target: Model) -> ())?,
        }
    }
}

Note: In Combat V1, this table exists as an architectural skeleton; no status effects are applied by the base kit.
4. Visual Layering Separation Rules
To prevent asset clipping and aesthetic clashes, visual effects are strictly isolated across three distinct layers:
Weapon Layer: Model mesh and physical material finish (element-neutral cold iron, nephrite jade, or obsidian per ADR-083).
Combat Skill Layer: Dao-driven particle effects, sawblade trails, and screen flash tints (controlled by CombatVFXController.luau).
Spiritual / Meditation Layer: Bloodline-driven character highlights, pillar beams, and back artifacts (controlled by CultivationManager.luau and BloodlineManager.luau). The combat skill layer must never overwrite the meditation aura.
5. Checklist for Adding a Future Dao (Post-V1)
When implementing a new Dao (e.g. Fire Sword Dao):
Register Configuration: Add a new key under FlyingSwordConfig.Daos (e.g. FlyingSwordConfig.Daos.Fire) containing Skills, VFXPalette, IntentPayoff, and BaseAttributes.
Register Status Effects: If the Dao inflicts a status effect (e.g. Blazeburn), register its tick and expiry callbacks in HitboxManager.luau.
Register VFX Handlers: Add dedicated visual effects into CombatVFXController.SkillVFXHandlers.
Zero Core Logic Rewrite: Ensure no changes are required to CombatStateManager.luau or InputController.luau beyond reading the registered Dao data.