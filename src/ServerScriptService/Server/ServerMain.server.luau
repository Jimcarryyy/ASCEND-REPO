--!strict
--[[
    ServerMain.server.luau
    Location: src/ServerScriptService/Server/ServerMain.server.luau
    Master server-side initialization script for ASCEND.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
local AlchemyManager = require(ServerScriptService.Server.Cultivation.AlchemyManager)

-- World Systems
local GatheringManager = require(ServerScriptService.Server.World.GatheringManager)
local EnvironmentTimeManager = require(ServerScriptService.Server.World.EnvironmentTimeManager)
local TreeCollisionManager = require(ServerScriptService.Server.World.TreeCollisionManager)

-- Initialize Server Core Subsystems
CombatStateManager.Init()
WeaponManager.Init()
CultivationManager.Init()
InventoryManager.Init()
PlayerDataManager.Init()
GatheringManager.Init()
AlchemyManager.Init()
EnvironmentTimeManager.Init()
TreeCollisionManager.Init()

print("[ASCEND] Server Main Engine Initialized Successfully!")