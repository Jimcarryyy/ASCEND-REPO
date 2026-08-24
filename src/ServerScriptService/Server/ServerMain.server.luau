--!strict
--[[
    ServerMain.server.luau
    Location: src/ServerScriptService/Server/ServerMain.server.luau
    Master server bootstrap for ASCEND. Initializes the centralized remote network
    and all core cultivation, combat, world, and state management engines.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local GatheringManager = require(ServerScriptService.Server.World.GatheringManager)
local AlchemyManager = require(ServerScriptService.Server.Cultivation.AlchemyManager)
local EnvironmentTimeManager = require(ServerScriptService.Server.World.EnvironmentTimeManager)
local TreeCollisionManager = require(ServerScriptService.Server.World.TreeCollisionManager)
local VendorManager = require(ServerScriptService.Server.World.VendorManager)
local SectManager = require(ServerScriptService.Server.Cultivation.SectManager)
local MobAIManager = require(ServerScriptService.Server.Combat.MobAIManager)
local ArenaManager = require(ServerScriptService.Server.Combat.ArenaManager)
local MarketplaceManager = require(ServerScriptService.Server.State.MarketplaceManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)

local function InitializeServer()
	-- 1. Initialize Network Remotes First
	RemoteEvents.Init()

	-- 2. Initialize Core State & Combat Engines
	CombatStateManager.Init()
	WeaponManager.Init()
	CultivationManager.Init()
	InventoryManager.Init()
	PlayerDataManager.Init()
	GatheringManager.Init()
	AlchemyManager.Init()
	EnvironmentTimeManager.Init()
	TreeCollisionManager.Init()
	VendorManager.Init()
	SectManager.Init()
	MobAIManager.Init()
	ArenaManager.Init()
	MarketplaceManager.Init()

	print("[ASCEND] Master Server Engine Initialized Successfully! (All 15 Network Remotes Active)")
end

InitializeServer()