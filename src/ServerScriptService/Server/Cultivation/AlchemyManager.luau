--!strict
-- AlchemyManager.luau
-- Server-authoritative alchemy crafting, material validation, and spirit pill consumption engine.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local AlchemyConfig = require(ReplicatedStorage.Shared.Configs.AlchemyConfig)
local CultivationManager = require(script.Parent.CultivationManager)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local AlchemyManager = {}
AlchemyManager.__index = AlchemyManager

local ActiveCrafting: { [Player]: boolean } = {}
local ActiveBuffs: { [Player]: { [string]: thread } } = {}
local PlayerInventories: { [Player]: { [string]: number } } = {}
local isInitialized = false

local function EnsurePlayerData(player: Player)
	if not ActiveBuffs[player] then
		ActiveBuffs[player] = {}
	end
	if not PlayerInventories[player] then
		PlayerInventories[player] = {
			mat_spirit_herb = 15,
			mat_demon_core = 5,
			mat_spirit_water = 10,
			pill_qi_gathering = 2,
			pill_healing_dan = 2,
		}
	end
end

function AlchemyManager.Init()
	if isInitialized then return end
	isInitialized = true

	-- Pre-create remote event on server start
	local alchemyRemote = RemoteEvents.GetRemote("AlchemyAction")

	-- Wire players already in server
	for _, player in ipairs(Players:GetPlayers()) do
		EnsurePlayerData(player)
	end

	-- Connect join/leave handlers
	Players.PlayerAdded:Connect(EnsurePlayerData)

	Players.PlayerRemoving:Connect(function(player)
		ActiveCrafting[player] = nil
		if ActiveBuffs[player] then
			for _, threadTask in pairs(ActiveBuffs[player]) do
				task.cancel(threadTask)
			end
			ActiveBuffs[player] = nil
		end
		PlayerInventories[player] = nil
	end)

	-- Network Remote Handler
	alchemyRemote.OnServerEvent:Connect(function(player: Player, actionType: string, payload: string)
		EnsurePlayerData(player)
		if actionType == "CraftPill" then
			local success, message = AlchemyManager.CraftPill(player, payload)
			print(string.format("[Alchemy Server] %s crafted '%s': %s (%s)", player.Name, payload, tostring(success), message))
			alchemyRemote:FireClient(player, "CraftResult", { Success = success, Message = message, Inventory = AlchemyManager.GetPlayerInventory(player) })

		elseif actionType == "ConsumePill" then
			local success, message = AlchemyManager.ConsumePill(player, payload)
			print(string.format("[Alchemy Server] %s consumed '%s': %s (%s)", player.Name, payload, tostring(success), message))
			alchemyRemote:FireClient(player, "ConsumeResult", { Success = success, Message = message, Inventory = AlchemyManager.GetPlayerInventory(player) })
		end
	end)
end

-- Validate if player has required ingredient counts
local function HasIngredients(player: Player, recipe: AlchemyConfig.PillRecipe): boolean
	EnsurePlayerData(player)
	local inventory = PlayerInventories[player]
	if not inventory then return false end

	for _, ingredient in ipairs(recipe.Ingredients) do
		local owned = inventory[ingredient.MaterialId] or 0
		if owned < ingredient.Amount then
			return false
		end
	end
	return true
end

-- Deduct ingredients upon crafting attempt
local function ConsumeIngredients(player: Player, recipe: AlchemyConfig.PillRecipe)
	EnsurePlayerData(player)
	local inventory = PlayerInventories[player]
	if not inventory then return end

	for _, ingredient in ipairs(recipe.Ingredients) do
		inventory[ingredient.MaterialId] = (inventory[ingredient.MaterialId] or 0) - ingredient.Amount
	end
end

-- Attempt crafting a spirit pill
function AlchemyManager.CraftPill(player: Player, recipeId: string): (boolean, string)
	EnsurePlayerData(player)
	if ActiveCrafting[player] then
		return false, "Alchemy furnace is currently active."
	end

	local recipe = AlchemyConfig.GetRecipe(recipeId)
	if not recipe then
		return false, "Invalid alchemy recipe."
	end

	if not HasIngredients(player, recipe) then
		return false, "Insufficient spiritual materials."
	end

	ActiveCrafting[player] = true
	ConsumeIngredients(player, recipe)

	-- Wait for crafting duration delay on server
	task.wait(recipe.CraftTime)
	ActiveCrafting[player] = nil

	-- Roll for success rate
	local roll = math.random()
	if roll <= recipe.SuccessRate then
		local inventory = PlayerInventories[player]
		if inventory then
			inventory[recipe.RecipeId] = (inventory[recipe.RecipeId] or 0) + 1
		end
		return true, "Successfully refined " .. recipe.DisplayName .. "!"
	else
		return false, "Furnace fire flickered! Alchemy attempt failed."
	end
end

-- Consume a spirit pill and apply high-dopamine effects
function AlchemyManager.ConsumePill(player: Player, pillId: string): (boolean, string)
	EnsurePlayerData(player)
	local inventory = PlayerInventories[player]
	if not inventory or (inventory[pillId] or 0) <= 0 then
		return false, "Pill not available in inventory."
	end

	local recipe = AlchemyConfig.GetRecipe(pillId)
	if not recipe then
		return false, "Unknown spirit pill."
	end

	-- Deduct 1 pill
	inventory[pillId] = inventory[pillId] - 1

	-- Apply Pill Effects
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	for _, effect in ipairs(recipe.Effects) do
		if effect.Type == "InstantQi" then
			CultivationManager.AddQi(player, effect.Value)

		elseif effect.Type == "HealOverTime" and humanoid then
			local duration = effect.Duration or 5
			local healPerSec = (humanoid.MaxHealth * effect.Value) / duration
			
			task.spawn(function()
				local elapsed = 0
				while elapsed < duration and humanoid and humanoid.Health > 0 do
					humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + (healPerSec * 0.5))
					task.wait(0.5)
					elapsed += 0.5
				end
			end)

		elseif effect.Type == "QiGatherBoost" then
			CultivationManager.ApplyQiBoost(player, effect.Value, effect.Duration or 30)

		elseif effect.Type == "StatBuff" then
			if ActiveBuffs[player] and effect.StatName then
				if ActiveBuffs[player][effect.StatName] then
					task.cancel(ActiveBuffs[player][effect.StatName])
				end
				
				ActiveBuffs[player][effect.StatName] = task.spawn(function()
					task.wait(effect.Duration or 60)
					if ActiveBuffs[player] then
						ActiveBuffs[player][effect.StatName] = nil
					end
				end)
			end
		end
	end

	return true, "Consumed " .. recipe.DisplayName
end

function AlchemyManager.GetPlayerInventory(player: Player)
	EnsurePlayerData(player)
	return PlayerInventories[player] or {}
end

-- Auto-initialize on server load
AlchemyManager.Init()

return AlchemyManager