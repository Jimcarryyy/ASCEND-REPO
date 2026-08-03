--!strict
--[[
    SpearConfig.luau
    Configuration data for Spear weapon mechanics, damage values,
    combo timings, thrust ranges, and skill definitions.
]]

export type ComboStep = {
	Step: number,
	Damage: number,
	Range: Vector3,
	Offset: Vector3,
	Knockback: Vector3,
	Cooldown: number,
	ForwardLunge: number?,
}

local SpearConfig = {
	M1Combo = {
		[1] = { Step = 1, Damage = 18, Range = Vector3.new(5, 5, 10), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 4, -12), Cooldown = 0.45, ForwardLunge = 8 },
		[2] = { Step = 2, Damage = 18, Range = Vector3.new(6, 5, 9), Offset = Vector3.new(0, 0, -4.5), Knockback = Vector3.new(0, 4, -12), Cooldown = 0.45, ForwardLunge = 8 },
		[3] = { Step = 3, Damage = 24, Range = Vector3.new(5, 5, 11), Offset = Vector3.new(0, 0, -5.5), Knockback = Vector3.new(0, 6, -18), Cooldown = 0.5, ForwardLunge = 12 },
		[4] = { Step = 4, Damage = 42, Range = Vector3.new(12, 6, 12), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 22, -40), Cooldown = 1.1, ForwardLunge = 16 }, -- 360° Sweep Finisher
	},
	Skills = {
		F = { Name = "Vaulting Slam", Damage = 45, Cooldown = 1.5, Range = Vector3.new(12, 8, 12), Offset = Vector3.new(0, 0, -6), Knockback = Vector3.new(0, 30, -20) },
		Q = { Name = "Serpent Piercing Thrust", Damage = 65, Cooldown = 3.0, Range = Vector3.new(6, 6, 18), Offset = Vector3.new(0, 0, -9), Knockback = Vector3.new(0, 10, -30) },
		E = { Name = "Whirlwind Sweep", Damage = 85, Cooldown = 5.0, Range = Vector3.new(16, 8, 16), Offset = Vector3.new(0, 0, -5), Knockback = Vector3.new(0, 15, -35) },
		R = { Name = "Dragon Spirit Charge", Damage = 135, Cooldown = 8.0, Range = Vector3.new(10, 8, 30), Offset = Vector3.new(0, 0, -15), Knockback = Vector3.new(0, 35, -60) },
		Shift = { Name = "Windstep Dash", Damage = 0, Cooldown = 2.0, Range = Vector3.zero, Offset = Vector3.zero, Knockback = Vector3.zero },
	},
}

return SpearConfig