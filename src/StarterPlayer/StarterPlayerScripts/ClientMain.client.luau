--!strict
--[[
    ClientMain.client.luau
    Location: src/StarterPlayer/StarterPlayerScripts/ClientMain.client.luau
    Master client bootstrap for ASCEND.
]]

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local controllersFolder = player:WaitForChild("PlayerScripts"):WaitForChild("Controllers") :: Folder

local CONTROLLER_NAMES = {
	"ModalWindowManager",
	"AnimationController",
	"InputController",
	"CombatVFXController",
	"HUDController",
	"InventoryController",
	"AlchemyController",
	"OverheadUIController",
	"CultivationController",
	"GatheringController",
	"WindEnvironmentController",
	"MarketController",
	"QuestTrackerController",
	"ArenaController",
	"SparringGuidanceController",
	"BossHUDController",
	"DeathReincarnationController",
	"SwordAltarController",
	"BloodlineController",
	"SettingsController", 
	"SkillBarController",
	"FocusTargetController",
	"SectController",
	"StarterGuideController",
	"CharacterStatsController",
	"MusicController",
}

local function InitializeClient()
	for _, name in ipairs(CONTROLLER_NAMES) do
		local moduleScript = controllersFolder:FindFirstChild(name) :: ModuleScript?
		if moduleScript then
			task.spawn(function()
				local success, controller = pcall(require, moduleScript)
				if success and type(controller) == "table" and type(controller.Init) == "function" then
					local initSuccess, initErr = pcall(controller.Init)
					if not initSuccess then
						warn(string.format("[ClientMain] Controller '%s' Init error: %s", name, tostring(initErr)))
					end
				else
					warn(string.format("[ClientMain] Failed to require controller '%s'", name))
				end
			end)
		end
	end

	print("[ASCEND] Client Initialized (Sect Shop & MarketController Active).")
end

InitializeClient()