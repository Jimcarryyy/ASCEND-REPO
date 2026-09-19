--!strict
--[[
    ServerMain.server.luau
    Location: src/ServerScriptService/Server/ServerMain.server.luau
    Master server bootstrap for ASCEND.
    Fixes:
      - A4: Configures 'Characters' CollisionGroup (Characters vs Characters non-collidable)
        to eliminate avatar pushing, bumping, and tripping glitches.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

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

local function SetupCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Characters")
		PhysicsService:CollisionGroupSetCollidable("Characters", "Characters", false)
	end)

	local function AssignCharacterCollisionGroup(character: Model)
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CollisionGroup = "Characters"
			end
		end
		character.DescendantAdded:Connect(function(desc)
			if desc:IsA("BasePart") then
				desc.CollisionGroup = "Characters"
			end
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(AssignCharacterCollisionGroup)
		if player.Character then
			AssignCharacterCollisionGroup(player.Character)
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			AssignCharacterCollisionGroup(player.Character)
		end
	end
end

local function InitializeServer()
	-- 0. Setup Collision Groups first
	SetupCollisionGroups()

	-- 1. Initialize Network Remotes
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
	MobAIManager.Init()

	print("[ASCEND] Master Server Engine Initialized Successfully! (A4 Collision Group & Core Services Active)")
end

InitializeServer()