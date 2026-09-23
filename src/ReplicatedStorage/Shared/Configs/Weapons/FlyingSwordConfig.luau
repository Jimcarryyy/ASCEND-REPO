--!strict
--[[
    FlyingSwordConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
    Balance & Kinematic Configuration for Pure Sword Cultivator.
    Updates:
      - Phase 5.4: Pacing & Cooldown Rebalance:
        Q (Sword Tempest): 6.5s
        E (Piercing Void Thrust): 7.5s
        F (100-Slash Domain): 14.0s
      - Phase 4: Unified client/server M1 timing via GetM1Timing.
      - Q Skill Knockback: Set to Vector3.zero (no enemy displacement).
]]

export type ComboStep = {
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
	Range: Vector3,
	Offset: Vector3,
	Cooldown: number,
	QiCostPercent: number,
	Knockback: Vector3,
	Windup: number,
	ActiveDuration: number,
	Recovery: number,
	DashDistance: number?,
}

export type StepTiming = {
	ActiveTime: number,
	RecoveryTime: number,
	TotalLockout: number,
}

local FlyingSwordConfig = {
	M1Combo = {
		[1] = {
			Damage = 26,
			ArenaDamage = 18,
			PostureDamage = 14,
			Range = Vector3.new(5.4, 4.5, 6.2),
			Offset = Vector3.new(0, 0, -3.2),
			Knockback = Vector3.new(0, 0, -4),
			Windup = 0.18,
			ActiveDuration = 0.18,
			Recovery = 0.22,
			Cooldown = 0.58,
		},
		[2] = {
			Damage = 28,
			ArenaDamage = 20,
			PostureDamage = 16,
			Range = Vector3.new(5.6, 4.5, 6.4),
			Offset = Vector3.new(0, 0, -3.2),
			Knockback = Vector3.new(0, 0, -5),
			Windup = 0.18,
			ActiveDuration = 0.18,
			Recovery = 0.20,
			Cooldown = 0.56,
		},
		[3] = {
			Damage = 32,
			ArenaDamage = 22,
			PostureDamage = 18,
			Range = Vector3.new(6.0, 5.0, 6.6),
			Offset = Vector3.new(0, 0, -3.4),
			Knockback = Vector3.new(0, 0, -6),
			Windup = 0.20,
			ActiveDuration = 0.20,
			Recovery = 0.20,
			Cooldown = 0.60,
		},
		[4] = {
			Damage = 36,
			ArenaDamage = 26,
			PostureDamage = 22,
			Range = Vector3.new(6.4, 5.0, 7.0),
			Offset = Vector3.new(0, 0, -3.5),
			Knockback = Vector3.new(0, 0, -8),
			Windup = 0.20,
			ActiveDuration = 0.22,
			Recovery = 0.20,
			Cooldown = 0.62,
		},
		[5] = {
			Damage = 52,
			ArenaDamage = 38,
			PostureDamage = 40,
			Range = Vector3.new(7.5, 6.0, 8.5),
			Offset = Vector3.new(0, 0, -4.0),
			Knockback = Vector3.new(0, 0, -18),
			Windup = 0.26,
			ActiveDuration = 0.26,
			Recovery = 0.30,
			Cooldown = 0.82,
		},
	},

	Skills = {
		Q = {
			Name = "Sword Tempest",
			Damage = 60,
			ArenaDamage = 40,
			PostureDamage = 30,
			Range = Vector3.new(12, 5, 8),
			Offset = Vector3.new(0, 0, -4),
			Cooldown = 6.5,
			QiCostPercent = 0.12,
			Knockback = Vector3.zero,
			Windup = 0.10,
			ActiveDuration = 0.35,
			Recovery = 0.15,
		},
		E = {
			Name = "Piercing Void Thrust",
			Damage = 75,
			ArenaDamage = 50,
			PostureDamage = 45,
			Range = Vector3.new(5, 5, 12),
			Offset = Vector3.new(0, 0, -5),
			Cooldown = 7.5,
			QiCostPercent = 0.15,
			Knockback = Vector3.new(0, 0, -14),
			Windup = 0.06,
			ActiveDuration = 0.14,
			Recovery = 0.20,
		},
		F = {
			Name = "100-Slash Domain",
			Damage = 135,
			ArenaDamage = 85,
			PostureDamage = 70,
			Range = Vector3.new(24, 12, 24),
			Offset = Vector3.new(0, 0, 0),
			Cooldown = 14.0,
			QiCostPercent = 0.20,
			Knockback = Vector3.new(0, 0, -22),
			Windup = 0.12,
			ActiveDuration = 0.22,
			Recovery = 0.30,
			DashDistance = 32.0,
		},
		Shift = {
			Name = "Qi Dash",
			Cooldown = 2.2,
		},
	},

	Posture = {
		MaxPosture = 100,
		RegenRate = 22,
		RegenDelay = 1.25,
		ParryWindow = 0.22,
		ParryStunDuration = 1.20,
		GuardBreakStunDuration = 2.0,
		BlockDamageReduction = 0.70,
		GuardBreakBonusDamagePercent = 0.35,
		ParryQiRestorePercent = 0.08,
	},

	CC = {
		IFrameDuration = 0.24,
		StunImmunityDuration = 1.0,
		InCombatDuration = 4.0,
		ClashWindow = 0.18,
		MaxPingTolerance = 0.18,
	},

	Flight = {
		Realms = {
			QiCondensation = { Velocity = 45.0, QiDrainPercent = 0.012, FlatDrain = 8 },
			FoundationEstablishment = { Velocity = 55.0, QiDrainPercent = 0.010, FlatDrain = 10 },
			GoldenCore = { Velocity = 68.0, QiDrainPercent = 0.008, FlatDrain = 12 },
			NascentSoul = { Velocity = 82.0, QiDrainPercent = 0.006, FlatDrain = 14 },
			SpiritSevering = { Velocity = 96.0, QiDrainPercent = 0.005, FlatDrain = 16 },
			VoidRefining = { Velocity = 110.0, QiDrainPercent = 0.004, FlatDrain = 18 },
			BodyIntegration = { Velocity = 125.0, QiDrainPercent = 0.003, FlatDrain = 20 },
			Mahayana = { Velocity = 142.0, QiDrainPercent = 0.002, FlatDrain = 22 },
			TribulationTranscending = { Velocity = 160.0, QiDrainPercent = 0.001, FlatDrain = 24 },
			ImmortalAscension = { Velocity = 185.0, QiDrainPercent = 0.0005, FlatDrain = 26 },
		},
	},
}

function FlyingSwordConfig.GetM1Timing(stepIndex: number): StepTiming
	local stepData = FlyingSwordConfig.M1Combo[stepIndex] or FlyingSwordConfig.M1Combo[1]
	local duration = stepData.Cooldown or 0.58
	local windupRatio = 0.45

	local activeTime = duration * windupRatio
	local recoveryTime = duration * (1.0 - windupRatio)
	return {
		ActiveTime = activeTime,
		RecoveryTime = recoveryTime,
		TotalLockout = activeTime + recoveryTime,
	}
end

return FlyingSwordConfig