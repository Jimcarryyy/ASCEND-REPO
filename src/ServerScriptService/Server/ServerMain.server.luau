--!strict
--[[
    ServerMain.server.luau
    Main server entry point for initializing core framework and state engines.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Server = ServerScriptService:WaitForChild("Server")

local CombatStateManager = require(Server:WaitForChild("State"):WaitForChild("CombatStateManager") :: ModuleScript)
local WeaponManager = require(Server:WaitForChild("Combat"):WaitForChild("WeaponManager") :: ModuleScript)
local CultivationManager = require(Server:WaitForChild("Cultivation"):WaitForChild("CultivationManager") :: ModuleScript)

-- Initialize Server Engines
if CombatStateManager and type(CombatStateManager) == "table" then
	CombatStateManager.Init()
end

if WeaponManager and type(WeaponManager) == "table" then
	WeaponManager.Init()
end

if CultivationManager and type(CultivationManager) == "table" then
	CultivationManager.Init()
end

print("[ASCEND] Server Main Engine Initialized Successfully!")