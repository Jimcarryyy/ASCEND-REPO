--!strict
--[[
    RemoteEvents.luau
    Location: src/ReplicatedStorage/Shared/Network/RemoteEvents.luau
    Centralized network remote management for ASCEND.
    Instantiates the 16 active game remotes under ReplicatedStorage.Remotes.
    Pruned: 16 legacy unused prototype remotes purged.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteName = 
	"CombatAction"
	| "CombatVFX"
	| "SyncCooldown"
	| "UpdateSkillState"
	| "UpdateCultivation"
	| "CultivationAction"
	| "HeavenlyAnnouncement"
	| "InventoryAction"
	| "UpdateInventory"
	| "MarketAction"
	| "AlchemyAction"
	| "GatheringAction"
	| "AltarAction"
	| "SectAction"
	| "ArenaAction"
	| "BloodlineAction"

local ALL_REMOTES: { RemoteName } = {
	"CombatAction",
	"CombatVFX",
	"SyncCooldown",
	"UpdateSkillState",
	"UpdateCultivation",
	"CultivationAction",
	"HeavenlyAnnouncement",
	"InventoryAction",
	"UpdateInventory",
	"MarketAction",
	"AlchemyAction",
	"GatheringAction",
	"AltarAction",
	"SectAction",
	"ArenaAction",
	"BloodlineAction",
}

local RemoteEvents = {}
local remotesFolder: Folder?

function RemoteEvents.Init(): Folder
	if remotesFolder then
		return remotesFolder
	end

	local found = ReplicatedStorage:FindFirstChild("Remotes") :: Folder?
	if found then
		remotesFolder = found
		return found
	end

	if RunService:IsServer() then
		local newFolder = Instance.new("Folder")
		newFolder.Name = "Remotes"
		newFolder.Parent = ReplicatedStorage
		remotesFolder = newFolder

		for _, name in ipairs(ALL_REMOTES) do
			if not newFolder:FindFirstChild(name) then
				local newRemote = Instance.new("RemoteEvent")
				newRemote.Name = name
				newRemote.Parent = newFolder
			end
		end

		print(string.format("[RemoteEvents] Initialized %d Active Server RemoteEvents under ReplicatedStorage.Remotes.", #ALL_REMOTES))
		return newFolder
	else
		local waitedFolder = ReplicatedStorage:WaitForChild("Remotes", 15) :: Folder?
		if not waitedFolder then
			error("[RemoteEvents] Client timed out waiting for 'Remotes' folder in ReplicatedStorage!")
		end
		remotesFolder = waitedFolder
		return waitedFolder
	end
end

function RemoteEvents.GetRemote(name: string): RemoteEvent
	local folder = RemoteEvents.Init()

	local remote = folder:FindFirstChild(name) :: RemoteEvent?
	if not remote then
		if RunService:IsServer() then
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = name
			newRemote.Parent = folder
			return newRemote
		else
			local found = folder:WaitForChild(name, 10) :: RemoteEvent?
			if not found then
				warn("[RemoteEvents] Client timed out waiting for remote: " .. tostring(name))
				local fallback = Instance.new("RemoteEvent")
				fallback.Name = name
				return fallback
			end
			return found
		end
	end

	return remote
end

RemoteEvents.Init()

return RemoteEvents