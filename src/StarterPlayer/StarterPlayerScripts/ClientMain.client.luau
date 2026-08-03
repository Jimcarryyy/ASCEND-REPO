--!strict
--[[
    ClientMain.client.luau
    Entry point for client-side controllers.
]]

local Controllers = script.Parent:WaitForChild("Controllers")

local HUDController = require(Controllers:WaitForChild("HUDController") :: ModuleScript)
local InventoryController = require(Controllers:WaitForChild("InventoryController") :: ModuleScript)
local InputController = require(Controllers:WaitForChild("InputController") :: ModuleScript)
local CombatVFXController = require(Controllers:WaitForChild("CombatVFXController") :: ModuleScript)
local AnimationController = require(Controllers:WaitForChild("AnimationController") :: ModuleScript)

HUDController.Init()
InventoryController.Init()
InputController.Init()
CombatVFXController.Init()
AnimationController.Init()

print("[ASCEND] All Client Controllers Initialized Successfully!")