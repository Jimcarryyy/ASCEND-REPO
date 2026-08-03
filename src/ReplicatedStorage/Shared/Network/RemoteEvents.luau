--!strict
--[[
    RemoteEvents.luau
    Centralized network remote management for ASCEND.
    Dynamically creates and exposes typed RemoteEvents and RemoteFunctions.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteName = 
	"CombatAction" 
	| "UpdateSkillState" 
	| "SyncCooldown" 
	| "InventoryAction" 
	| "BossStateUpdate"
	| "UpdateCultivation"
	| "AlchemyAction"

local ALL_REMOTES: { RemoteName } = {
	"CombatAction",
	"UpdateSkillState",
	"SyncCooldown",
	"InventoryAction",
	"BossStateUpdate",
	"UpdateCultivation",
	"AlchemyAction",
}

local RemoteEvents = {}
local remotesFolder: Folder

function RemoteEvents.Init(): Folder
	remotesFolder = ReplicatedStorage:FindFirstChild("Remotes") :: Folder
	if not remotesFolder then
		if RunService:IsServer() then
			remotesFolder = Instance.new("Folder")
			remotesFolder.Name = "Remotes"
			remotesFolder.Parent = ReplicatedStorage

			-- Pre-create all registered remote events on server start
			for _, name in ipairs(ALL_REMOTES) do
				if not remotesFolder:FindFirstChild(name) then
					local newRemote = Instance.new("RemoteEvent")
					newRemote.Name = name
					newRemote.Parent = remotesFolder
				end
			end
		else
			remotesFolder = ReplicatedStorage:WaitForChild("Remotes", 10) :: Folder
		end
	end

	return remotesFolder
end

function RemoteEvents.GetRemote(name: RemoteName): RemoteEvent
	if not remotesFolder then
		RemoteEvents.Init()
	end

	local remote = remotesFolder:FindFirstChild(name) :: RemoteEvent?
	if not remote then
		if RunService:IsServer() then
			local newRemote = Instance.new("RemoteEvent")
			newRemote.Name = name
			newRemote.Parent = remotesFolder
			return newRemote
		else
			local found = remotesFolder:WaitForChild(name, 10) :: RemoteEvent?
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

-- Auto-initialize remote folder on load
RemoteEvents.Init()

return RemoteEvents