--!strict
--[[
    ServerMain.server.luau
    Location: src/ServerScriptService/Server/ServerMain.server.luau
    Master server bootstrap for ASCEND.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local BloodlineManager = require(ServerScriptService.Server.State.BloodlineManager)
local GatheringManager = require(ServerScriptService.Server.World.GatheringManager)
local AlchemyManager = require(ServerScriptService.Server.Cultivation.AlchemyManager)
local EnvironmentTimeManager = require(ServerScriptService.Server.World.EnvironmentTimeManager)
local TreeCollisionManager = require(ServerScriptService.Server.World.TreeCollisionManager)
local VendorManager = require(ServerScriptService.Server.World.VendorManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)
local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)
local ArenaManager = require(ServerScriptService.Server.Combat.ArenaManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local SwordAltarManager = require(ServerScriptService.Server.World.SwordAltarManager)

local function InitializeServer()
	-- 1. Initialize Network Remotes First
	RemoteEvents.Init()

	-- 2. Initialize Core State & Combat Engines
	CombatStateManager.Init()
	WeaponManager.Init()
	CultivationManager.Init()
	InventoryManager.Init()
	PlayerDataManager.Init()

	-- 3. World & Cultivation Facilities
	GatheringManager.Init()
	AlchemyManager.Init()
	EnvironmentTimeManager.Init()
	TreeCollisionManager.Init()
	VendorManager.Init()
	SectManager.Init()
	SwordAltarManager.Init()
	BloodlineManager.Init()

	-- 4. Combat Encounters & Arena
	ArenaManager.Init()
	MobAIManager.Init() -- Single initialization for Mob Spawners & AI Loop

	print("[ASCEND] Master Server Engine Initialized Successfully! (Core, Gathering, Alchemy, Bloodline, Arena & Mob AI Active)")
end

InitializeServer()