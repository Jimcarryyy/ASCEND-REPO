--!strict
--[[
    AnimationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/AnimationConfig.luau
    Central animation registry for ASCEND (Pure Sword Cultivator R6).
    Includes 2-Stage Qi Dash loop, 5-Hit M1 Broadsword Combo, and Block/Parry/Stun poses.
]]

export type AnimDef = {
	AnimationId: string,
	Speed: number,
	FadeTime: number,
	CastDuration: number,
	WalkSpeedDampen: number?,
}

local AnimationConfig = {
	Movement = {
		Idle = "rbxassetid://98257310687211",
		Walk = "rbxassetid://114762664703275",
		Run = "rbxassetid://133708659027167",
		Jump = "rbxassetid://115002701112708",
		Fall = "rbxassetid://105371732122929",
		Land = "rbxassetid://127232864368618",
		Climb = "rbxassetid://92318229141460",
		Swim = "rbxassetid://125750702",
		CrouchIdle = "rbxassetid://121105579761179",
		CrouchWalk = "rbxassetid://139963626951619",
		Meditation = "rbxassetid://129333803961409",

		-- 2-Stage Repeatable Qi Dash Animations
		Dash_1 = "rbxassetid://118004062849712",
		Dash_2 = "rbxassetid://87494050060721",
	},

	FlyingSword = {
		M1_1 = { AnimationId = "rbxassetid://129254042886405", Speed = 0.85, FadeTime = 0.08, CastDuration = 0.44, WalkSpeedDampen = 8 },
		M1_2 = { AnimationId = "rbxassetid://78342794513338",  Speed = 0.85, FadeTime = 0.08, CastDuration = 0.40, WalkSpeedDampen = 8 },
		M1_3 = { AnimationId = "rbxassetid://133701354257850", Speed = 0.85, FadeTime = 0.08, CastDuration = 0.44, WalkSpeedDampen = 8 },
		M1_4 = { AnimationId = "rbxassetid://140582503077234", Speed = 0.80, FadeTime = 0.08, CastDuration = 0.46, WalkSpeedDampen = 8 },
		M1_5 = { AnimationId = "rbxassetid://111677132360566", Speed = 0.75, FadeTime = 0.10, CastDuration = 0.54, WalkSpeedDampen = 4 },

		Block = { AnimationId = "rbxassetid://112773782841691", Speed = 1.0, FadeTime = 0.05, CastDuration = 9999, WalkSpeedDampen = 6 },
		Parry = { AnimationId = "rbxassetid://5763723309", Speed = 1.6, FadeTime = 0.02, CastDuration = 0.28 },
		Stun  = { AnimationId = "rbxassetid://", Speed = 1.0, FadeTime = 0.05, CastDuration = 0.50 },

		Q = { AnimationId = "rbxassetid://132236998171530", Speed = 1.0, FadeTime = 0.02, CastDuration = 0.43 },
		E = { AnimationId = "rbxassetid://93342220169849", Speed = 1.0, FadeTime = 0.03, CastDuration = 0.25 },
		F = { AnimationId = "rbxassetid://93342220169849", Speed = 1.0, FadeTime = 0.03, CastDuration = 0.25 },
	},
}

return AnimationConfig