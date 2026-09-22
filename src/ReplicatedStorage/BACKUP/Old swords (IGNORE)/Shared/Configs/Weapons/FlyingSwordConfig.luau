--!strict
--[[
    FlyingSwordConfig.luau
    Configuration data for Flying Sword weapon mechanics, damage values,
    combo timings, ranges, and skill definitions.
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

local FlyingSwordConfig = {
	M1Combo = {
		[1] = { Step = 1, Damage = 15, Range = Vector3.new(6, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 5, -10), Cooldown = 0.4, ComboResetTime = 1.2 },
		[2] = { Step = 2, Damage = 15, Range = Vector3.new(6, 6, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 5, -10), Cooldown = 0.4, ComboResetTime = 1.2 },
		[3] = { Step = 3, Damage = 20, Range = Vector3.new(7, 7, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 8, -15), Cooldown = 0.5, ComboResetTime = 1.2 },
		[4] = { Step = 4, Damage = 35, Range = Vector3.new(8, 8, 10), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 20, -35), Cooldown = 1.0, ComboResetTime = 1.2 }, -- Finisher
	},
    Skills = {
		F = { Name = "Heavy Slam", Damage = 40, Cooldown = 1.5, Range = Vector3.new(10, 8, 10), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 25, -20) },
		Q = { Name = "Sword Tempest", Damage = 60, Cooldown = 3.0, Range = Vector3.new(14, 10, 14), Offset = Vector3.new(0, 0, -6), Knockback = Vector3.new(0, 15, -25) },
		E = { Name = "Telekinesis Thrust", Damage = 80, Cooldown = 5.0, Range = Vector3.new(8, 8, 25), Offset = Vector3.new(0, 0, -12), Knockback = Vector3.new(0, 10, -40), ProjectileSpeed = 120 },
		R = { Name = "Sword Barrage", Damage = 120, Cooldown = 8.0, Range = Vector3.new(16, 12, 30), Offset = Vector3.new(0, 0, -15), Knockback = Vector3.new(0, 30, -50), ProjectileCount = 8 },
		Shift = { Name = "Windstep Dash", Damage = 0, Cooldown = 2.0, Range = Vector3.zero, Offset = Vector3.zero, Knockback = Vector3.zero },
	},
}

return FlyingSwordConfig