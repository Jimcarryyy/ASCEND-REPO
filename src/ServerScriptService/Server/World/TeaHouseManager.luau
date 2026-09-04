--!strict
--[[
    TeaHouseManager.luau
    Location: src/ServerScriptService/Server/World/TeaHouseManager.luau
    Server-authoritative Spirit Tea Pavilion Manager.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

local TeaHouseManager = {}
local teaRemote: RemoteEvent

local TEA_CATALOG = {
	[1] = { Name = "Jade Dew Spirit Tea", Cost = 100, Duration = 10 * 60, QiInstant = 250, MeditationBonus = 0.10 },
	[2] = { Name = "Crimson Ginseng Brew", Cost = 150, Duration = 10 * 60, HPInstant = 500, HealthRegenBonus = 0.15 },
	[3] = { Name = "Dragon Well Sword Tea", Cost = 250, Duration = 15 * 60, SwordIntentGainBonus = 0.15 },
}

function TeaHouseManager.Init()
	teaRemote = RemoteEvents.GetRemote("TeaHouseAction")

	teaRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		if payload.Action == "BrewAndDrink" and type(payload.TeaIndex) == "number" then
			TeaHouseManager.ProcessTeaOrder(player, payload.TeaIndex)
		elseif payload.Action == "RequestSync" then
			local stones = PlayerDataManager.GetSpiritStones(player)
			teaRemote:FireClient(player, { Action = "SyncBalance", SpiritStones = stones })
		end
	end)

	task.spawn(TeaHouseManager.SetupPrompts)
	print("[ASCEND] TeaHouseManager Initialized.")
end

function TeaHouseManager.SetupPrompts()
	local function BindPrompt(prompt: ProximityPrompt)
		local act = prompt.ActionText:lower()
		if act == "order spirit tea" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_XiaoLing") then
			prompt.Triggered:Connect(function(player: Player)
				local stones = PlayerDataManager.GetSpiritStones(player)
				teaRemote:FireClient(player, { Action = "OpenTeaHouse", SpiritStones = stones })
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

function TeaHouseManager.ProcessTeaOrder(player: Player, teaIndex: number)
	local teaDef = TEA_CATALOG[teaIndex]
	if not teaDef then return end

	local currentStones = PlayerDataManager.GetSpiritStones(player)
	if currentStones < teaDef.Cost then
		teaRemote:FireClient(player, { Action = "Result", Success = false, Message = "Insufficient Spirit Stones for tea!" })
		return
	end

	PlayerDataManager.RemoveSpiritStones(player, teaDef.Cost)

	-- Apply Instant HP Recovery
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum and teaDef.HPInstant then
			hum.Health = math.min(hum.MaxHealth, hum.Health + teaDef.HPInstant)
		end
	end

	-- Apply Instant Qi Recovery via CultivationManager safely
	if teaDef.QiInstant then
		CultivationManager.AddInternalQi(player, teaDef.QiInstant)
	end

	-- Apply Timed Status Buff Attributes
	local expireTime = os.clock() + teaDef.Duration
	if teaDef.MeditationBonus then
		player:SetAttribute("TeaMeditationBuffUntil", expireTime)
		player:SetAttribute("TeaMeditationMultiplier", 1.0 + teaDef.MeditationBonus)
	end
	if teaDef.SwordIntentGainBonus then
		player:SetAttribute("TeaSwordIntentBuffUntil", expireTime)
		player:SetAttribute("TeaSwordIntentMultiplier", 1.0 + teaDef.SwordIntentGainBonus)
	end

	teaRemote:FireClient(player, {
		Action = "Result",
		Success = true,
		Message = string.format("Drank %s!\nBuff active for %d minutes.", teaDef.Name, math.floor(teaDef.Duration / 60)),
		NewBalance = PlayerDataManager.GetSpiritStones(player),
	})

	print(string.format("[TeaHouse] %s drank %s.", player.Name, teaDef.Name))
end

return TeaHouseManager