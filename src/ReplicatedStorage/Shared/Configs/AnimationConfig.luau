--!strict
--[[
    AnimationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/AnimationConfig.luau
    Updates:
      - Heavy M1 Cadence: Playback speed slowed to 0.50x with 0.60s cast duration for weighted impacts.
      - 4-Way Directional Dash IDs registered.
]]

export type AnimDef = {
	AnimationId: string,
	Speed: number,
	FadeTime: number,
	CastDuration: number,
	WalkSpeedDampen: number?,
	ChargeAnimationId: string?,
}

local AnimationConfig = {
	Movement = {
		Idle = "rbxassetid://133864540288517",
		Walk = "rbxassetid://74349935296328",
		Run = "rbxassetid://75558265748203",
		Land = "rbxassetid://86689000393753",
		Jump = "rbxassetid://115002701112708",
		Fall = "rbxassetid://105371732122929",
		Climb = "rbxassetid://92318229141460",
		Swim = "rbxassetid://125750702",
		CrouchIdle = "rbxassetid://121105579761179",
		CrouchWalk = "rbxassetid://139963626951619",

		Equip = "rbxassetid://102430137097013",
		Unequip = "rbxassetid://96702609673197",

		Dash_W = "rbxassetid://137006811308011",
		Dash_S = "rbxassetid://108645166188876",
		Dash_A = "rbxassetid://73026743327917",
		Dash_D = "rbxassetid://128283257723015",

		HitReaction1 = "rbxassetid://114532369819775",
		HitReaction2 = "rbxassetid://127536591441002",
		Parryed = "rbxassetid://121973766317438",

		Meditation = "rbxassetid://129333803961409",
		Flight = "rbxassetid://81098622855235",
	},

	FlyingSword = {
		-- Heavy Weighted 5-Hit M1 Combo (0.50x speed, 0.60s duration)
		M1_1 = { AnimationId = "rbxassetid://129254042886405", Speed = 0.50, FadeTime = 0.08, CastDuration = 0.58, WalkSpeedDampen = 6 },
		M1_2 = { AnimationId = "rbxassetid://78342794513338",  Speed = 0.50, FadeTime = 0.08, CastDuration = 0.56, WalkSpeedDampen = 6 },
		M1_3 = { AnimationId = "rbxassetid://133701354257850", Speed = 0.48, FadeTime = 0.08, CastDuration = 0.60, WalkSpeedDampen = 6 },
		M1_4 = { AnimationId = "rbxassetid://140582503077234", Speed = 0.48, FadeTime = 0.08, CastDuration = 0.62, WalkSpeedDampen = 6 },
		M1_5 = { AnimationId = "rbxassetid://111677132360566", Speed = 0.42, FadeTime = 0.10, CastDuration = 0.82, WalkSpeedDampen = 4 },

		Block = { AnimationId = "rbxassetid://112773782841691", Speed = 1.0, FadeTime = 0.05, CastDuration = 9999, WalkSpeedDampen = 6 },
		Parry = { AnimationId = "rbxassetid://5763723309", Speed = 1.6, FadeTime = 0.02, CastDuration = 0.28 },
		Stun  = { AnimationId = "rbxassetid://121973766317438", Speed = 1.0, FadeTime = 0.05, CastDuration = 0.50 },

		Q = { AnimationId = "rbxassetid://111677132360566", Speed = 1.0, FadeTime = 0.06, CastDuration = 0.55, WalkSpeedDampen = 5 },
		E = { AnimationId = "rbxassetid://93342220169849", Speed = 1.0, FadeTime = 0.03, CastDuration = 0.25 },
		F = {
			AnimationId = "rbxassetid://111677132360566",
			ChargeAnimationId = "rbxassetid://84905841522350",
			Speed = 1.0,
			FadeTime = 0.04,
			CastDuration = 0.70,
			WalkSpeedDampen = 0,
		},
	},
}

return AnimationConfig