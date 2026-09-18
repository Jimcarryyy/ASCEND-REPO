--!strict
--[[
    FlyingSwordConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
    Defines 5-Hit M1 combo, Skills (Q, E, F Ultimate Domain), Block/Parry (T), and Dash.
    - M1 Hits 1-4 Knockback normalized to micro-stagger (prevents knocking targets out of combo)
    - F Ultimate buffed to 260 Base Damage with 2-Stage Lightning Shred + Shatter Finisher
    - Phase 4: Dynamic Realm-Scaled 3D Flight Physics & Qi Drain Table
]]

export type ComboStep = {
	Step: number,
	Damage: number,
	ArenaDamage: number,
	PostureDamage: number,
	Range: Vector3,
	Offset: Vector3,
	Knockback: Vector3,
	Windup: number,
	ActiveDuration: number,
	Recovery: number,
	Cooldown: number,
}

export type SkillDef = {
	Name: string,
	Damage: number,
	ArenaDamage: number,
	PostureDamage: number,
	Cooldown: number,
	QiCostPercent: number,
	Range: Vector3,
	Offset: Vector3,
	Knockback: Vector3,
	Windup: number,
	ActiveDuration: number,
	Recovery: number,
	ProjectileSpeed: number?,
	DashSpeed: number?,
	DashDistance: number?,
}

export type PostureConfig = {
	MaxPosture: number,
	RegenDelay: number,
	RegenRate: number,
	GuardBreakStunDuration: number,
	GuardBreakBonusDamagePercent: number,
	ParryWindow: number,
	ParryStunDuration: number,
	ParryQiRestorePercent: number,
	BlockDamageReduction: number,
	BlockAngle: number,
}

export type CCConfig = {
	StunImmunityDuration: number,
	IFrameDuration: number,
	InCombatDuration: number,
	MaxPingTolerance: number,
	ClashWindow: number,
}

export type FlightRealmTier = {
	Velocity: number,
	QiDrainPercent: number,
	FlatDrain: number,
}

export type FlightConfig = {
	Realms: { [string]: FlightRealmTier },
}

local FlyingSwordConfig = {
	-- M1 Hits 1-4 keep victims locked in blade range with micro-stagger; only Hit 5 launches
	M1Combo = {
		[1] = { Step = 1, Damage = 15, ArenaDamage = 45, PostureDamage = 15, Range = Vector3.new(7.0, 6, 8.5), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 0, -0.5), Windup = 0.08, ActiveDuration = 0.14, Recovery = 0.16, Cooldown = 0.38 },
		[2] = { Step = 2, Damage = 15, ArenaDamage = 45, PostureDamage = 15, Range = Vector3.new(7.0, 6, 8.5), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 0, -0.5), Windup = 0.08, ActiveDuration = 0.14, Recovery = 0.16, Cooldown = 0.38 },
		[3] = { Step = 3, Damage = 20, ArenaDamage = 60, PostureDamage = 20, Range = Vector3.new(8.0, 7, 9.5), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 0, -0.5), Windup = 0.09, ActiveDuration = 0.15, Recovery = 0.18, Cooldown = 0.42 },
		[4] = { Step = 4, Damage = 25, ArenaDamage = 75, PostureDamage = 20, Range = Vector3.new(8.0, 7, 9.5), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 0, -0.5), Windup = 0.09, ActiveDuration = 0.15, Recovery = 0.20, Cooldown = 0.44 },
		[5] = { Step = 5, Damage = 45, ArenaDamage = 130, PostureDamage = 40, Range = Vector3.new(10.0, 8, 12.0), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 18, -30), Windup = 0.14, ActiveDuration = 0.18, Recovery = 0.33, Cooldown = 0.65 },
	} :: { [number]: ComboStep },

	Skills = {
		Q = {
			Name = "Purple Sword Tempest",
			Damage = 60,
			ArenaDamage = 160,
			PostureDamage = 50,
			Cooldown = 3.5,
			QiCostPercent = 0.15,
			Range = Vector3.new(16, 8, 36),
			Offset = Vector3.new(0, 0, -18),
			Knockback = Vector3.new(0, 14, -22),
			Windup = 0.30,
			ActiveDuration = 0.55,
			Recovery = 0.20,
			ProjectileSpeed = 70,
		},
		E = {
			Name = "Piercing Void Thrust",
			Damage = 80,
			ArenaDamage = 220,
			PostureDamage = 50,
			Cooldown = 5.0,
			QiCostPercent = 0.12,
			Range = Vector3.new(8, 8, 25),
			Offset = Vector3.new(0, 0, -12.5),
			Knockback = Vector3.new(0, 10, -40),
			Windup = 0.08,
			ActiveDuration = 0.20,
			Recovery = 0.22,
			ProjectileSpeed = 120,
		},
		F = {
			Name = "100-Slash Flash Domain",
			Damage = 260,              -- 4 electric ticks x 39 + 156 final detonation
			ArenaDamage = 450,
			PostureDamage = 120,       -- High guard break threat
			Cooldown = 7.0,
			QiCostPercent = 0.25,
			Range = Vector3.new(36, 18, 36),
			Offset = Vector3.new(0, 0, -14),
			Knockback = Vector3.new(0, 20, -35),
			Windup = 0.20,
			ActiveDuration = 0.60,
			Recovery = 0.25,
			DashSpeed = 160,
			DashDistance = 32,
		},
		T = {
			Name = "Block & Parry",
			Damage = 0,
			ArenaDamage = 0,
			PostureDamage = 0,
			Cooldown = 0.5,
			QiCostPercent = 0,
			Range = Vector3.zero,
			Offset = Vector3.zero,
			Knockback = Vector3.zero,
			Windup = 0,
			ActiveDuration = 0,
			Recovery = 0,
		},
		Shift = {
			Name = "Windstep Dash",
			Damage = 0,
			ArenaDamage = 0,
			PostureDamage = 0,
			Cooldown = 3.0,
			QiCostPercent = 0,
			Range = Vector3.zero,
			Offset = Vector3.zero,
			Knockback = Vector3.zero,
			Windup = 0,
			ActiveDuration = 0.18,
			Recovery = 0.08,
		},
	} :: { [string]: SkillDef },

	Posture = {
		MaxPosture = 100,
		RegenDelay = 1.5,
		RegenRate = 25,
		GuardBreakStunDuration = 1.2,
		GuardBreakBonusDamagePercent = 0.25,
		ParryWindow = 0.22,
		ParryStunDuration = 0.5,
		ParryQiRestorePercent = 0.05,
		BlockDamageReduction = 0.80,
		BlockAngle = 180,
	} :: PostureConfig,

	CC = {
		StunImmunityDuration = 0.6,
		IFrameDuration = 0.12,
		InCombatDuration = 6.0,
		MaxPingTolerance = 0.18,
		ClashWindow = 0.08,
	} :: CCConfig,

	Flight = {
		Realms = {
			QiCondensation = { Velocity = 38.0, QiDrainPercent = 0.0200, FlatDrain = 5 },
			FoundationEstablishment = { Velocity = 48.0, QiDrainPercent = 0.0100, FlatDrain = 10 },
			GoldenCore = { Velocity = 58.0, QiDrainPercent = 0.0060, FlatDrain = 15 },
			NascentSoul = { Velocity = 70.0, QiDrainPercent = 0.0040, FlatDrain = 20 },
			SpiritSevering = { Velocity = 84.0, QiDrainPercent = 0.0025, FlatDrain = 25 },
			VoidRefining = { Velocity = 100.0, QiDrainPercent = 0.0018, FlatDrain = 30 },
			BodyIntegration = { Velocity = 115.0, QiDrainPercent = 0.0012, FlatDrain = 35 },
			Mahayana = { Velocity = 130.0, QiDrainPercent = 0.0008, FlatDrain = 40 },
			TribulationTranscending = { Velocity = 145.0, QiDrainPercent = 0.0005, FlatDrain = 45 },
			ImmortalAscension = { Velocity = 160.0, QiDrainPercent = 0.0003, FlatDrain = 50 },
		},
	} :: FlightConfig,
}

return FlyingSwordConfig