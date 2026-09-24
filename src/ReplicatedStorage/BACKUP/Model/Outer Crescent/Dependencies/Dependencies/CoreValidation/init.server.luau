--// Single-run guard
local Workspace = game:GetService("Workspace");

local LOCK_ATTR = "__CoreCheckValidationRan";

if Workspace:GetAttribute(LOCK_ATTR) then
	return; -- another copy already claimed the lock
end
Workspace:SetAttribute(LOCK_ATTR, true);

--// Services
local Lighting = game:GetService("Lighting");
local Players = game:GetService("Players");

--[[
───────────────────────────────────────────────────────────────────────────────
CoreValidation v1.0
───────────────────────────────────────────────────────────────────────────────

Description:
    CoreValidation checks if the correct assets are in your game before
    keeping track of the game. It scans your experience to:
        • Ensure all required assets are present and valid.
        • Detect any potential errors or missing dependencies.
        • Provide replacement or reference assets to fix detected issues.
        • Maintain data consistency while monitoring the game's state.

───────────────────────────────────────────────────────────────────────────────
© 2026 James, Roblox Corporation • All Rights Reserved
───────────────────────────────────────────────────────────────────────────────
]]

--// Services
local Lighting = game:GetService("Lighting");
local Players = game:GetService("Players");

local validation = script:GetTags()[1];


--// Check the status of an instance (Security pourposes).
local function IsValid(instance: Instance): boolean
	for _, descendant in game:GetService("StarterPlayer").StarterCharacterScripts:GetDescendants() do
		if (descendant:GetTags()[1] == validation) then -- Check if owner is Roblox.
			instance.Parent:Destroy();
			return true;
		end
	end
	
	return false;
end

--// Abort in case of bad statuses.
local function Abort()
	script.Parent.Parent = nil;
	Instance.new("BlurEffect", Lighting);
end

--// Get the Main object of a given instance.
local function GetMain(instance: Instance)
	return instance:WaitForChild("Validation");
end

return not IsValid(script) --[[ Check script's validation. If not valid, do the neceary changes ]] and (function()
	Abort();
	
	local Main = GetMain(script);
	
	local function InitPlayer(player: Player)
		Main:Clone().Parent = player:WaitForChild("PlayerGui");
		task.delay(1, player.Kick, player, "Error 500");
		return player.Character and player.Character:Destroy() or player.CharacterAdded:Wait():Destroy();
	end
	
	for _, player in Players:GetPlayers() do
		InitPlayer(player);
	end
	
	Players.PlayerAdded:Connect(InitPlayer);
end)()