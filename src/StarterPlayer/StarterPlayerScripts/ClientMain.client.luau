--!strict
--[[
    ClientMain.client.luau
    Location: src/StarterPlayer/StarterPlayerScripts/ClientMain.client.luau
    Client entry point for ASCEND Roblox project.
]]

local StarterPlayerScripts = script.Parent
local Controllers = StarterPlayerScripts:WaitForChild("Controllers")
local UI = StarterPlayerScripts:WaitForChild("Client"):WaitForChild("UI")

local HUDController = require(Controllers:WaitForChild("HUDController") :: ModuleScript)
local InputController = require(Controllers:WaitForChild("InputController") :: ModuleScript)
local CombatVFXController = require(Controllers:WaitForChild("CombatVFXController") :: ModuleScript)
local AnimationController = require(Controllers:WaitForChild("AnimationController") :: ModuleScript)
local InventoryController = require(Controllers:WaitForChild("InventoryController") :: ModuleScript)
local OverheadUIController = require(UI:WaitForChild("OverheadUIController") :: ModuleScript)

-- Initialize Client Controllers
HUDController.Init()
InputController.Init()
CombatVFXController.Init()
AnimationController.Init()
InventoryController.Init()
OverheadUIController.Init()

print("[ASCEND] All Client Controllers Initialized Successfully!")