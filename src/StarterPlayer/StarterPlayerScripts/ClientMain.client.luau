--!strict
--[[
    ClientMain.client.luau
    Location: src/StarterPlayer/StarterPlayerScripts/ClientMain.client.luau
    Master client-side initialization script for ASCEND.
]]

local StarterPlayerScripts = script.Parent
local Controllers = StarterPlayerScripts:WaitForChild("Controllers")

-- Standard Controllers
local HUDController = require(Controllers:WaitForChild("HUDController"))
local InputController = require(Controllers:WaitForChild("InputController"))
local CombatVFXController = require(Controllers:WaitForChild("CombatVFXController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
local AlchemyController = require(Controllers:WaitForChild("AlchemyController"))
local GatheringController = require(Controllers:WaitForChild("GatheringController"))

-- Overhead UI Controller (Located in StarterPlayerScripts.Client.UI)
local ClientFolder = StarterPlayerScripts:WaitForChild("Client")
local UIFolder = ClientFolder:WaitForChild("UI")
local OverheadUIController = require(UIFolder:WaitForChild("OverheadUIController"))

-- Initialize Client Controllers
HUDController.Init()
InputController.Init()
CombatVFXController.Init()
AnimationController.Init()
InventoryController.Init()
AlchemyController.Init()
OverheadUIController.Init()
GatheringController.Init()

print("[ASCEND] All Client Controllers Initialized Successfully!")