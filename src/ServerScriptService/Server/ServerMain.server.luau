--!strict
--[[
    ServerMain.server.luau
    Location: src/ServerScriptService/Server/ServerMain.server.luau
    Server entry point for ASCEND Roblox project.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(game:GetService("ReplicatedStorage").Shared.Network.RemoteEvents)
RemoteEvents.Init()

local CombatStateManager = require(ServerScriptService.Server.State.CombatStateManager)
local WeaponManager = require(ServerScriptService.Server.Combat.WeaponManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)

CombatStateManager.Init()
WeaponManager.Init()
CultivationManager.Init()
InventoryManager.Init()
PlayerDataManager.Init()

print("[ASCEND] Server Main Engine Initialized Successfully!")