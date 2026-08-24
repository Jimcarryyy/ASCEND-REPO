--!strict
--[[
    FlyingSwordConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
    Defines 5-Hit M1 combo, Skills (Q, E, F Heavy Slam), Block/Parry (T), and Dash.
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

local FlyingSwordConfig = {
	M1Combo = {
		[1] = { Step = 1, Damage = 15, ArenaDamage = 45, PostureDamage = 15, Range = Vector3.new(6.5, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 3, -6), Windup = 0.08, ActiveDuration = 0.14, Recovery = 0.16, Cooldown = 0.38 },
		[2] = { Step = 2, Damage = 15, ArenaDamage = 45, PostureDamage = 15, Range = Vector3.new(6.5, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 3, -6), Windup = 0.08, ActiveDuration = 0.14, Recovery = 0.16, Cooldown = 0.38 },
		[3] = { Step = 3, Damage = 20, ArenaDamage = 60, PostureDamage = 20, Range = Vector3.new(7.5, 7, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 6, -10), Windup = 0.09, ActiveDuration = 0.15, Recovery = 0.18, Cooldown = 0.42 },
		[4] = { Step = 4, Damage = 25, ArenaDamage = 75, PostureDamage = 20, Range = Vector3.new(7.5, 7, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 8, -15), Windup = 0.09, ActiveDuration = 0.15, Recovery = 0.20, Cooldown = 0.44 },
		[5] = { Step = 5, Damage = 45, ArenaDamage = 130, PostureDamage = 40, Range = Vector3.new(9.5, 8, 11), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 20, -32), Windup = 0.14, ActiveDuration = 0.18, Recovery = 0.33, Cooldown = 0.65 },
	} :: { [number]: ComboStep },

	Skills = {
		Q = {
			Name = "Sword Tempest",
			Damage = 60,
			ArenaDamage = 160,
			PostureDamage = 50,
			Cooldown = 3.0,
			QiCostPercent = 0.15,
			Range = Vector3.new(14, 10, 14),
			Offset = Vector3.new(0, 0, 0),
			Knockback = Vector3.new(0, 15, -25),
			Windup = 0.10,
			ActiveDuration = 0.25,
			Recovery = 0.20,
		},
		E = {
			Name = "Telekinesis Thrust",
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
			Name = "Falling Sky Slam",
			Damage = 50,
			ArenaDamage = 140,
			PostureDamage = 45,
			Cooldown = 2.5,
			QiCostPercent = 0.10,
			Range = Vector3.new(10, 8, 10),
			Offset = Vector3.new(0, 0, -5),
			Knockback = Vector3.new(0, 22, -18),
			Windup = 0.10,
			ActiveDuration = 0.18,
			Recovery = 0.22,
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
}

return FlyingSwordConfig