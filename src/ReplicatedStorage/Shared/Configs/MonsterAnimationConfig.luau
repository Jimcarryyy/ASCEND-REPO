--!strict
--[[
    MonsterAnimationConfig.luau
    Location: src/ReplicatedStorage/Shared/Configs/MonsterAnimationConfig.luau
    Animation ID registry for all 8 Non-Humanoid Monsters and Sovereign Bosses.
    Paste uploaded Roblox Animation asset IDs here.
    If an ID is blank (""), MonsterVisualController automatically uses procedural bone animation.
]]

export type MonsterAnimSet = {
	Idle: string,
	Run: string,
	Attack: string,
	Special: string?,
	Stun: string?,
	Death: string?,
	RunPlaybackSpeed: number?,
	AttackPlaybackSpeed: number?,
}

local MonsterAnimationConfig: { [string]: MonsterAnimSet } = {
	["Iron-Tusk Spirit Boar"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.0,
		AttackPlaybackSpeed = 1.0,
	},

	["Wilderness Spirit Wolf"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.1,
		AttackPlaybackSpeed = 1.2,
	},

	["Corrupted Alpha Wolf"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.0,
		AttackPlaybackSpeed = 1.1,
	},

	["Magma Hound"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.2,
		AttackPlaybackSpeed = 1.25,
	},

	["Obsidian Lava-Boar"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 0.9,
		AttackPlaybackSpeed = 0.95,
	},

	["Molten Hell-Lion Sovereign"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.0,
		AttackPlaybackSpeed = 1.05,
	},

	["Frost-Fang Wolf"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.15,
		AttackPlaybackSpeed = 1.2,
	},

	["Frost-Saber Sovereign"] = {
		Idle = "",
		Run = "",
		Attack = "",
		Special = "",
		Stun = "",
		Death = "",
		RunPlaybackSpeed = 1.0,
		AttackPlaybackSpeed = 1.1,
	},
}

return MonsterAnimationConfig