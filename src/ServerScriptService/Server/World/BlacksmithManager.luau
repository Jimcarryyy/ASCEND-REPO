--!strict
--[[
    BlacksmithManager.luau
    Location: src/ServerScriptService/Server/World/BlacksmithManager.luau
    Server-authoritative Blacksmith Manager for weapon refinement and blade sharpening.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local InventoryManager = require(ServerScriptService.Server.State.InventoryManager)

local BlacksmithManager = {}
local blacksmithRemote: RemoteEvent

local function CountPlayerItem(player: Player, itemId: string): number
	local inv = InventoryManager.GetInventory(player)
	if not inv then return 0 end
	local total = 0
	for _, slot in pairs(inv) do
		if slot and slot.ItemId == itemId then
			total += (slot.Count or 1)
		end
	end
	return total
end

function BlacksmithManager.Init()
	blacksmithRemote = RemoteEvents.GetRemote("BlacksmithAction")

	blacksmithRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "RefineWeapon" then
			BlacksmithManager.ProcessRefine(player)
		elseif action == "SharpenBlade" then
			BlacksmithManager.ProcessSharpen(player)
		elseif action == "RequestSync" then
			BlacksmithManager.SyncPlayerData(player)
		end
	end)

	task.spawn(BlacksmithManager.SetupPrompts)
	print("[ASCEND] BlacksmithManager Initialized.")
end

function BlacksmithManager.SetupPrompts()
	local function BindPrompt(prompt: ProximityPrompt)
		local act = prompt.ActionText:lower()
		if act == "refine & sharpen weapons" or prompt.ObjectText == "Master Blacksmith Anvil" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_MadameTie") then
			prompt.Triggered:Connect(function(player: Player)
				BlacksmithManager.OpenForgeForPlayer(player)
			end)
		end
	end

	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("ProximityPrompt") then BindPrompt(desc) end
	end

	Workspace.DescendantAdded:Connect(function(desc)
		if desc:IsA("ProximityPrompt") then BindPrompt(desc) end
	end)
end

function BlacksmithManager.OpenForgeForPlayer(player: Player)
	local stones = PlayerDataManager.GetSpiritStones(player) or 0
	local ingots = CountPlayerItem(player, "MountainIronIngot")
	local currentRefine = player:GetAttribute("WeaponRefinement") or 3
	local isSharpened = (player:GetAttribute("BladeSharpenedUntil") or 0) > os.clock()

	blacksmithRemote:FireClient(player, {
		Action = "OpenForge",
		SpiritStones = stones,
		IronIngots = ingots,
		RefinementLevel = currentRefine,
		IsSharpened = isSharpened,
	})
end

function BlacksmithManager.SyncPlayerData(player: Player)
	local stones = PlayerDataManager.GetSpiritStones(player) or 0
	local ingots = CountPlayerItem(player, "MountainIronIngot")
	local currentRefine = player:GetAttribute("WeaponRefinement") or 3

	blacksmithRemote:FireClient(player, {
		Action = "SyncData",
		SpiritStones = stones,
		IronIngots = ingots,
		RefinementLevel = currentRefine,
	})
end

function BlacksmithManager.ProcessRefine(player: Player)
	local currentRefine = player:GetAttribute("WeaponRefinement") or 3
	if currentRefine >= 10 then
		blacksmithRemote:FireClient(player, { Action = "Result", Success = false, Message = "Weapon is already at Maximum Refinement (+10)!" })
		return
	end

	local stoneCost = 150 + (currentRefine * 75)
	local currentStones = PlayerDataManager.GetSpiritStones(player) or 0

	if currentStones < stoneCost then
		blacksmithRemote:FireClient(player, { Action = "Result", Success = false, Message = "Insufficient Spirit Stones for refinement!" })
		return
	end

	PlayerDataManager.RemoveSpiritStones(player, stoneCost)

	local successChance = math.max(0.35, 0.95 - (currentRefine * 0.08))
	local roll = math.random()

	if roll <= successChance then
		local newRefine = currentRefine + 1
		player:SetAttribute("WeaponRefinement", newRefine)
		local baseBonus = newRefine * 0.05
		player:SetAttribute("RefinementDamageMultiplier", 1.0 + baseBonus)

		blacksmithRemote:FireClient(player, {
			Action = "Result",
			Success = true,
			Message = string.format("Refinement Successful! Flying Sword is now +%d (+%d%% ATK)!", newRefine, math.floor(baseBonus * 100)),
			NewRefinement = newRefine,
			NewBalance = PlayerDataManager.GetSpiritStones(player) or 0,
		})
		print(string.format("[Blacksmith] %s refined weapon to +%d!", player.Name, newRefine))
	else
		blacksmithRemote:FireClient(player, {
			Action = "Result",
			Success = false,
			Message = "Refinement Failed! Materials consumed by forge heat.",
			NewBalance = PlayerDataManager.GetSpiritStones(player) or 0,
		})
	end
end

function BlacksmithManager.ProcessSharpen(player: Player)
	local SHARPEN_COST = 100
	local currentStones = PlayerDataManager.GetSpiritStones(player) or 0

	if currentStones < SHARPEN_COST then
		blacksmithRemote:FireClient(player, { Action = "Result", Success = false, Message = "Insufficient Spirit Stones to sharpen blade!" })
		return
	end

	PlayerDataManager.RemoveSpiritStones(player, SHARPEN_COST)

	local buffDuration = 15 * 60
	player:SetAttribute("BladeSharpenedUntil", os.clock() + buffDuration)
	player:SetAttribute("SharpnessCritBonus", 0.10)

	blacksmithRemote:FireClient(player, {
		Action = "Result",
		Success = true,
		Message = "Blade Sharpened! +10% Critical Strike chance for 15 minutes.",
		NewBalance = PlayerDataManager.GetSpiritStones(player) or 0,
		IsSharpened = true,
	})

	print(string.format("[Blacksmith] %s sharpened blade for 15 minutes.", player.Name))
end

return BlacksmithManager