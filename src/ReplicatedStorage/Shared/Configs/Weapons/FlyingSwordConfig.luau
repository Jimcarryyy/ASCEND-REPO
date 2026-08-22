--!strict
--[[
    FlyingSwordConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/Weapons/FlyingSwordConfig.luau
    Configuration data for Flying Sword weapon mechanics, damage values,
    5-Hit M1 Combo, Skills, and Block/Parry deflection mechanics.
]]

export type ComboStep = {
	Step: number,
	Damage: number,
	Range: Vector3,
	Offset: Vector3,
	Knockback: Vector3,
	Cooldown: number,
	ComboResetTime: number,
}

export type SkillDef = {
	Name: string,
	Damage: number,
	Cooldown: number,
	Range: Vector3,
	Offset: Vector3,
	Knockback: Vector3,
	ProjectileSpeed: number?,
	ProjectileCount: number?,
}

export type BlockDef = {
	DamageReduction: number,       -- 80% damage reduction on standard block
	ParryWindow: number,           -- 0.22s timing window from block start for perfect parry
	ParryStunDuration: number,     -- 0.5s posture stagger on attacker
	ParryQiRestorePercent: number, -- 5% Cultivated Qi restored on parry
	BlockAngle: number,            -- Front 180-degree blocking arc
}

local FlyingSwordConfig = {
	M1Combo = {
		[1] = { Step = 1, Damage = 15, Range = Vector3.new(6.5, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 3, -6), Cooldown = 0.38, ComboResetTime = 1.3 },
		[2] = { Step = 2, Damage = 15, Range = Vector3.new(6.5, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 3, -6), Cooldown = 0.38, ComboResetTime = 1.3 },
		[3] = { Step = 3, Damage = 20, Range = Vector3.new(7.5, 7, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 6, -10), Cooldown = 0.42, ComboResetTime = 1.3 },
		[4] = { Step = 4, Damage = 25, Range = Vector3.new(7.5, 7, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 8, -15), Cooldown = 0.44, ComboResetTime = 1.3 },
		[5] = { Step = 5, Damage = 45, Range = Vector3.new(9.5, 8, 11), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 20, -32), Cooldown = 0.65, ComboResetTime = 1.3 }, -- Heavy Finisher
	},

	Block = {
		DamageReduction = 0.80,
		ParryWindow = 0.22,
		ParryStunDuration = 0.5,
		ParryQiRestorePercent = 0.05,
		BlockAngle = 180,
	} :: BlockDef,

	Skills = {
		F = { Name = "Heavy Slam", Damage = 40, Cooldown = 1.5, Range = Vector3.new(10, 8, 10), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 25, -20) },
		Q = { Name = "Sword Tempest", Damage = 60, Cooldown = 3.0, Range = Vector3.new(14, 10, 14), Offset = Vector3.new(0, 0, -6), Knockback = Vector3.new(0, 15, -25) },
		E = { Name = "Telekinesis Thrust", Damage = 80, Cooldown = 5.0, Range = Vector3.new(8, 8, 25), Offset = Vector3.new(0, 0, -12), Knockback = Vector3.new(0, 10, -40), ProjectileSpeed = 120 },
		R = { Name = "Sword Barrage", Damage = 120, Cooldown = 8.0, Range = Vector3.new(16, 12, 30), Offset = Vector3.new(0, 0, -15), Knockback = Vector3.new(0, 30, -50), ProjectileCount = 8 },
		Shift = { Name = "Windstep Dash", Damage = 0, Cooldown = 3.0, Range = Vector3.zero, Offset = Vector3.zero, Knockback = Vector3.zero },
	},
}

return FlyingSwordConfig