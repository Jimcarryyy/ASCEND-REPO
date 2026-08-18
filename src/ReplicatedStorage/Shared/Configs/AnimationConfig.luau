--!strict
--[[
    AnimationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/AnimationConfig.luau
    Central registry mapping weapon skill keys and movement states to Roblox R6 Animation IDs.
]]

export type AnimDef = {
	AnimationId: string,
	Speed: number,
	FadeTime: number,
	CastDuration: number,
	WalkSpeedDampen: number,
}

local AnimationConfig = {
	Movement = {
		Idle = "rbxassetid://98257310687211",
		Walk = "rbxassetid://114762664703275",        -- Walk V1
		Run = "rbxassetid://133708659027167",        -- Run V1
		Jump = "rbxassetid://115002701112708",
		Fall = "rbxassetid://105371732122929",
		Land = "rbxassetid://127232864368618",
		Climb = "rbxassetid://92318229141460",
		Swim = "rbxassetid://125750702",
		CrouchIdle = "rbxassetid://121105579761179",
		CrouchWalk = "rbxassetid://139963626951619",
	},
	FlyingSword = {
		M1 = { AnimationId = "rbxassetid://93342220169849", Speed = 1.8, FadeTime = 0.02, CastDuration = 0.2, WalkSpeedDampen = 14 },
		F = { AnimationId = "rbxassetid://93342220169849", Speed = 1.6, FadeTime = 0.03, CastDuration = 0.25, WalkSpeedDampen = 12 },
		Q = { AnimationId = "rbxassetid://132236998171530", Speed = 1.0, FadeTime = 0.02, CastDuration = 0.43, WalkSpeedDampen = 36 }, -- Instant Long Dash (Q)
		E = { AnimationId = "rbxassetid://93342220169849", Speed = 1.6, FadeTime = 0.03, CastDuration = 0.25, WalkSpeedDampen = 12 },
		R = { AnimationId = "rbxassetid://93342220169849", Speed = 1.4, FadeTime = 0.05, CastDuration = 0.35, WalkSpeedDampen = 10 },
		Shift = { AnimationId = "", Speed = 1.0, FadeTime = 0.02, CastDuration = 0.2, WalkSpeedDampen = 28 },
	},
	Spear = {
		M1 = { AnimationId = "rbxassetid://507767714", Speed = 1.8, FadeTime = 0.02, CastDuration = 0.2, WalkSpeedDampen = 14 },
		F = { AnimationId = "rbxassetid://507765644", Speed = 1.5, FadeTime = 0.03, CastDuration = 0.28, WalkSpeedDampen = 10 },
		Q = { AnimationId = "rbxassetid://507767714", Speed = 1.7, FadeTime = 0.03, CastDuration = 0.25, WalkSpeedDampen = 12 },
		E = { AnimationId = "rbxassetid://507768375", Speed = 1.6, FadeTime = 0.03, CastDuration = 0.3, WalkSpeedDampen = 12 },
		R = { AnimationId = "rbxassetid://507765644", Speed = 1.4, FadeTime = 0.05, CastDuration = 0.35, WalkSpeedDampen = 10 },
		Shift = { AnimationId = "", Speed = 1.0, FadeTime = 0.02, CastDuration = 0.2, WalkSpeedDampen = 28 },
	},
	Gauntlet = {
		M1 = { AnimationId = "rbxassetid://507768375", Speed = 2.0, FadeTime = 0.02, CastDuration = 0.18, WalkSpeedDampen = 15 },
		F = { AnimationId = "rbxassetid://507765644", Speed = 1.5, FadeTime = 0.03, CastDuration = 0.3, WalkSpeedDampen = 10 },
		Q = { AnimationId = "rbxassetid://507768375", Speed = 1.8, FadeTime = 0.03, CastDuration = 0.35, WalkSpeedDampen = 12 },
		E = { AnimationId = "rbxassetid://507767714", Speed = 1.6, FadeTime = 0.03, CastDuration = 0.25, WalkSpeedDampen = 12 },
		R = { AnimationId = "rbxassetid://507765644", Speed = 1.4, FadeTime = 0.05, CastDuration = 0.4, WalkSpeedDampen = 8 },
		Shift = { AnimationId = "", Speed = 1.0, FadeTime = 0.02, CastDuration = 0.2, WalkSpeedDampen = 28 },
	},
}

return AnimationConfig