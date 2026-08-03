--!strict
--[[
    GauntletConfig.luau
    Configuration data for Gauntlet martial arts weapon mechanics,
    close-quarters Qi punches, shockwaves, and skill definitions.
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

local GauntletConfig = {
	M1Combo = {
		[1] = { Step = 1, Damage = 14, Range = Vector3.new(5, 5, 6), Offset = Vector3.new(0, 0, -3), Knockback = Vector3.new(0, 3, -8), Cooldown = 0.35, ForwardLunge = 6 },
		[2] = { Step = 2, Damage = 14, Range = Vector3.new(5, 5, 6), Offset = Vector3.new(0, 0, -3), Knockback = Vector3.new(0, 3, -8), Cooldown = 0.35, ForwardLunge = 6 },
		[3] = { Step = 3, Damage = 22, Range = Vector3.new(6, 6, 7), Offset = Vector3.new(0, 0, -3.5), Knockback = Vector3.new(0, 5, -14), Cooldown = 0.4, ForwardLunge = 10 },
		[4] = { Step = 4, Damage = 38, Range = Vector3.new(7, 7, 8), Offset = Vector3.new(0, 0, -4), Knockback = Vector3.new(0, 28, -25), Cooldown = 0.9, ForwardLunge = 14 }, -- Uppercut Finisher
	},
	Skills = {
		F = { Name = "Qi Shield Parry", Damage = 0, Cooldown = 2.0, Range = Vector3.zero, Offset = Vector3.zero, Knockback = Vector3.zero, IFrameDuration = 1.0 },
		Q = { Name = "Hundred Palms 360", Damage = 75, Cooldown = 3.5, Range = Vector3.new(14, 8, 14), Offset = Vector3.new(0, 0, 0), Knockback = Vector3.new(0, 12, -20) }, -- 360 AoE
		E = { Name = "Mountain Shattering Palm", Damage = 90, Cooldown = 5.0, Range = Vector3.new(8, 8, 20), Offset = Vector3.new(0, 0, -10), Knockback = Vector3.new(0, 15, -45) },
		R = { Name = "Earth Shattering Ground Slam", Damage = 140, Cooldown = 8.0, Range = Vector3.new(20, 10, 20), Offset = Vector3.new(0, 0, 0), Knockback = Vector3.new(0, 40, 0) }, -- Vertical Launch AoE
		Shift = { Name = "Windstep Dash", Damage = 0, Cooldown = 2.0, Range = Vector3.zero, Offset = Vector3.zero, Knockback = Vector3.zero },
	},
}

return GauntletConfig