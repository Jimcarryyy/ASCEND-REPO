--!strict
--[[
    ClientMain.client.luau
    Location: src/StarterPlayer/StarterPlayerScripts/ClientMain.client.luau
    Master client-side initialization script for ASCEND.
]]

local Players = game:GetService("Players")
local StarterPlayerScripts = script.Parent
local Controllers = StarterPlayerScripts:WaitForChild("Controllers")

local localPlayer = Players.LocalPlayer

-- Camera Limits
localPlayer.CameraMinZoomDistance = 0.5
localPlayer.CameraMaxZoomDistance = 30

-- Core Controllers
local HUDController = require(Controllers:WaitForChild("HUDController"))
local InputController = require(Controllers:WaitForChild("InputController"))
local CombatVFXController = require(Controllers:WaitForChild("CombatVFXController"))
local AnimationController = require(Controllers:WaitForChild("AnimationController"))
local InventoryController = require(Controllers:WaitForChild("InventoryController"))
local AlchemyController = require(Controllers:WaitForChild("AlchemyController"))
local GatheringController = require(Controllers:WaitForChild("GatheringController"))
local WindEnvironmentController = require(Controllers:WaitForChild("WindEnvironmentController"))
local MarketController = require(Controllers:WaitForChild("MarketController"))
local QuestTrackerController = require(Controllers:WaitForChild("QuestTrackerController"))
local ArenaController = require(Controllers:WaitForChild("ArenaController"))

-- Overhead UI Controller
local ClientFolder = StarterPlayerScripts:WaitForChild("Client")
local UIFolder = ClientFolder:WaitForChild("UI")
local OverheadUIController = require(UIFolder:WaitForChild("OverheadUIController"))

-- Initialize All Client Controllers
HUDController.Init()
InputController.Init()
CombatVFXController.Init()
AnimationController.Init()
InventoryController.Init()
AlchemyController.Init()
OverheadUIController.Init()
GatheringController.Init()
WindEnvironmentController.Init()
MarketController.Init()
QuestTrackerController.Init()
ArenaController.Init()

print("[ASCEND] All Client Controllers Initialized Successfully with Quest Tracker & Sparring Arena HUD!")