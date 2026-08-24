--!strict
--[[
    ArenaManager.luau
    Location: src/ServerScriptService/Server/Combat/ArenaManager.luau
    Server-authoritative 1v1 Balanced Sparring Arena for the Azure Cloud Sect.
    Features: Unified Instant Matchmaking, 1,000 HP Stat Normalization, 90s countdown,
    Non-Lethal Concessions, and Top Duel HUD replication.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local CultivationConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

type ActiveDuel = {
	Player1: Player,
	Player2: Player,
	Realm: string,
	StartTime: number,
	Duration: number,
	P1Spawn: Vector3,
	P2Spawn: Vector3,
	SpectatorSpawn: Vector3,
	IsActive: boolean,
}

local ArenaManager = {}

local arenaRemote: RemoteEvent
local unifiedQueue: { Player } = {}
local activeDuels: { [Player]: ActiveDuel } = {}

local ARENA_TIME_LIMIT = 90 -- seconds

function ArenaManager.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	arenaRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		local action = payload.Action
		if action == "JoinQueue" then
			ArenaManager.AddToQueue(player)
		elseif action == "LeaveQueue" then
			ArenaManager.RemoveFromQueue(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		ArenaManager.RemoveFromQueue(player)
		local duel = activeDuels[player]
		if duel and duel.IsActive then
			local winner = (duel.Player1 == player) and duel.Player2 or duel.Player1
			ArenaManager.EndDuel(duel, winner, "Opponent Disconnected")
		end
	end)

	task.spawn(ArenaManager.SetupArenaPrompt)

	-- Heartbeat monitor for HP <= 1 and 90s timer
	task.spawn(function()
		while true do
			task.wait(0.5)
			ArenaManager.MonitorDuels()
		end
	end)

	print("[ASCEND] ArenaManager Initialized (Unified Instant Queue & 1,000 HP Normalization Active).")
end

function ArenaManager.SetupArenaPrompt()
	local arena = Workspace:FindFirstChild("SparringArena", true) or Workspace:FindFirstChild("ArenaRing", true)
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = "SparringArena"
		arena.Parent = Workspace
	end

	local function BindPrompt(part: Instance)
		if not (part:IsA("BasePart") or part:IsA("Model")) then return end
		local targetPart = if part:IsA("Model") then (part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart")) else (part :: BasePart)
		if not targetPart or targetPart:FindFirstChild("ArenaPrompt") then return end

		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "ArenaPrompt"
		prompt.ObjectText = "Elder Wu — Sparring Master"
		prompt.ActionText = "Register for 1v1 Sparring"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = targetPart

		prompt.Triggered:Connect(function(player: Player)
			arenaRemote:FireClient(player, { Action = "OpenArenaMenu" })
		end)
	end

	for _, child in ipairs(arena:GetChildren()) do
		BindPrompt(child)
	end

	arena.ChildAdded:Connect(BindPrompt)
end

function ArenaManager.GetArenaSpawns(): (Vector3, Vector3, Vector3)
	local arena = Workspace:FindFirstChild("SparringArena", true) or Workspace:FindFirstChild("ArenaRing", true)
	if arena then
		local s1 = arena:FindFirstChild("Spawn1", true) :: BasePart?
		local s2 = arena:FindFirstChild("Spawn2", true) :: BasePart?
		local spec = arena:FindFirstChild("SpectatorSpawn", true) :: BasePart?

		if s1 and s2 and spec then
			return s1.Position + Vector3.new(0, 3, 0), s2.Position + Vector3.new(0, 3, 0), spec.Position + Vector3.new(0, 3, 0)
		end
	end

	-- Default Sector 3 Arena Coordinates
	return Vector3.new(-120, 14, 280), Vector3.new(-120, 14, 340), Vector3.new(-160, 14, 310)
end

function ArenaManager.AddToQueue(player: Player)
	if activeDuels[player] then return end

	for _, p in ipairs(unifiedQueue) do
		if p == player then return end
	end

	local cultivation = CultivationManager.GetPlayerData(player)
	local realmName = if cultivation then tostring(cultivation.Realm) else "Qi Condensation"

	table.insert(unifiedQueue, player)
	arenaRemote:FireClient(player, { Action = "QueueJoined", Realm = realmName })
	print(string.format("[ArenaManager] %s joined the 1v1 Sparring Queue.", player.Name))

	-- Match as soon as 2 players are in queue
	if #unifiedQueue >= 2 then
		local p1 = table.remove(unifiedQueue, 1) :: Player
		local p2 = table.remove(unifiedQueue, 1) :: Player
		ArenaManager.StartDuel(p1, p2, realmName)
	end
end

function ArenaManager.RemoveFromQueue(player: Player)
	for i, p in ipairs(unifiedQueue) do
		if p == player then
			table.remove(unifiedQueue, i)
			arenaRemote:FireClient(player, { Action = "QueueLeft" })
			print(string.format("[ArenaManager] %s left the Sparring Queue.", player.Name))
			return
		end
	end
end

function ArenaManager.StartDuel(p1: Player, p2: Player, realm: string)
	local p1Spawn, p2Spawn, specSpawn = ArenaManager.GetArenaSpawns()

	local duel: ActiveDuel = {
		Player1 = p1,
		Player2 = p2,
		Realm = realm,
		StartTime = os.clock(),
		Duration = ARENA_TIME_LIMIT,
		P1Spawn = p1Spawn,
		P2Spawn = p2Spawn,
		SpectatorSpawn = specSpawn,
		IsActive = true,
	}

	activeDuels[p1] = duel
	activeDuels[p2] = duel

	local function PreparePlayer(p: Player, spawnPos: Vector3, opponent: Player)
		local char = p.Character
		if char then
			char:SetAttribute("InArena", true)
			char:PivotTo(CFrame.new(spawnPos, opponent.Character and opponent.Character:GetPivot().Position or spawnPos))

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 1000
				hum.Health = 1000
				hum.WalkSpeed = 16
			end
		end

		arenaRemote:FireClient(p, {
			Action = "DuelStarting",
			OpponentName = opponent.Name,
			Realm = realm,
			Duration = ARENA_TIME_LIMIT,
		})
	end

	PreparePlayer(p1, p1Spawn, p2)
	PreparePlayer(p2, p2Spawn, p1)

	print(string.format("[ArenaManager] ⚔️ 1v1 Duel Commenced: %s vs %s!", p1.Name, p2.Name))
end

function ArenaManager.MonitorDuels()
	local now = os.clock()
	local evaluated: { [ActiveDuel]: boolean } = {}

	for _, duel in pairs(activeDuels) do
		if evaluated[duel] or not duel.IsActive then continue end
		evaluated[duel] = true

		local p1 = duel.Player1
		local p2 = duel.Player2
		local p1Hum = p1.Character and p1.Character:FindFirstChildOfClass("Humanoid")
		local p2Hum = p2.Character and p2.Character:FindFirstChildOfClass("Humanoid")

		local p1Health = if p1Hum then p1Hum.Health else 0
		local p2Health = if p2Hum then p2Hum.Health else 0

		-- Simultaneous zero HP -> Draw
		if p1Health <= 1 and p2Health <= 1 then
			ArenaManager.EndDuel(duel, nil, "Simultaneous Double Knockout")
		elseif p1Health <= 1 then
			ArenaManager.EndDuel(duel, p2, "Knockdown Victory")
		elseif p2Health <= 1 then
			ArenaManager.EndDuel(duel, p1, "Knockdown Victory")
		elseif (now - duel.StartTime) >= duel.Duration then
			if p1Health > p2Health then
				ArenaManager.EndDuel(duel, p1, "Time Limit Exceeded (Higher HP)")
			elseif p2Health > p1Health then
				ArenaManager.EndDuel(duel, p2, "Time Limit Exceeded (Higher HP)")
			else
				ArenaManager.EndDuel(duel, nil, "Time Limit Draw")
			end
		end
	end
end

function ArenaManager.EndDuel(duel: ActiveDuel, winner: Player?, reason: string)
	if not duel.IsActive then return end
	duel.IsActive = false

	activeDuels[duel.Player1] = nil
	activeDuels[duel.Player2] = nil

	local function ResolveFighter(p: Player, isWinner: boolean, isDraw: boolean)
		local char = p.Character
		if char then
			char:SetAttribute("InArena", false)
			char:PivotTo(CFrame.new(duel.SpectatorSpawn))

			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.MaxHealth = 100
				hum.Health = 100
				hum.WalkSpeed = 18
			end
		end

		local contrib = if isWinner then 100 else (if isDraw then 50 else 25)
		local stones = if isWinner then 150 else (if isDraw then 75 else 50)

		PlayerDataManager.AddContributionPoints(p, contrib)
		PlayerDataManager.AddSpiritStones(p, stones)

		arenaRemote:FireClient(p, {
			Action = "DuelEnded",
			IsWinner = isWinner,
			IsDraw = isDraw,
			Reason = reason,
			RewardContribution = contrib,
			RewardStones = stones,
		})
	end

	if winner then
		local loser = (duel.Player1 == winner) and duel.Player2 or duel.Player1
		ResolveFighter(winner, true, false)
		ResolveFighter(loser, false, false)
		print(string.format("[ArenaManager] 🏆 %s defeated %s in Sparring Arena (%s).", winner.Name, loser.Name, reason))
	else
		ResolveFighter(duel.Player1, false, true)
		ResolveFighter(duel.Player2, false, true)
		print(string.format("[ArenaManager] 🤝 Duel between %s and %s resulted in a Draw (%s).", duel.Player1.Name, duel.Player2.Name, reason))
	end
end

return ArenaManager