--!strict
--[[
    ArenaManager.luau
    Location: src/ServerScriptService/Server/Combat/ArenaManager.luau
    Server-authoritative 1v1 Balanced Sparring Arena for the Azure Cloud Sect.
    Features: Same-realm matchmaking queue, in-world ProximityPrompt, 90s duel countdown, non-lethal HP resolution, and contribution rewards.
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
	Realm: CultivationConfig.RealmTier,
	StartTime: number,
	Duration: number,
	P1Spawn: Vector3,
	P2Spawn: Vector3,
	SpectatorSpawn: Vector3,
	IsActive: boolean,
}

local ArenaManager = {}

local arenaRemote: RemoteEvent
local queueByRealm: { [CultivationConfig.RealmTier]: { Player } } = {}
local activeDuels: { [Player]: ActiveDuel } = {}

local ARENA_TIME_LIMIT = 90 -- seconds

local ALL_REALMS: { CultivationConfig.RealmTier } = {
	"QiCondensation",
	"FoundationEstablishment",
	"GoldenCore",
	"NascentSoul",
	"SpiritSevering",
	"VoidRefining",
	"BodyIntegration",
	"Mahayana",
	"TribulationTranscending",
	"ImmortalAscension",
}

function ArenaManager.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	for _, realm in ipairs(ALL_REALMS) do
		queueByRealm[realm] = {}
	end

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
			local winner = duel.Player1 == player and duel.Player2 or duel.Player1
			ArenaManager.EndDuel(duel, winner, "Opponent disconnected")
		end
	end)

	-- Scan Workspace for physical arena prompt
	task.spawn(ArenaManager.SetupArenaPrompt)

	-- Heartbeat duel monitor
	task.spawn(function()
		while true do
			task.wait(1)
			ArenaManager.MonitorDuels()
		end
	end)

	print("[ASCEND] ArenaManager Initialized (Realm-Matched 1v1 Sparring & ProximityPrompt Active).")
end

function ArenaManager.SetupArenaPrompt()
	local arena = Workspace:FindFirstChild("SparringArena") or Workspace:FindFirstChild("ArenaRing")
	if not arena then
		arena = Instance.new("Folder")
		arena.Name = "SparringArena"
		arena.Parent = Workspace
	end

	local function BindPrompt(part: Instance)
		if not (part:IsA("BasePart") or part:IsA("Model")) then return end
		local targetPart = part:IsA("Model") and (part.PrimaryPart or part:FindFirstChildWhichIsA("BasePart")) or part :: BasePart
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
	local arena = Workspace:FindFirstChild("SparringArena") or Workspace:FindFirstChild("ArenaRing")
	if arena then
		local s1 = arena:FindFirstChild("Spawn1") :: BasePart?
		local s2 = arena:FindFirstChild("Spawn2") :: BasePart?
		local spec = arena:FindFirstChild("SpectatorSpawn") :: BasePart?

		if s1 and s2 and spec then
			return s1.Position + Vector3.new(0, 3, 0), s2.Position + Vector3.new(0, 3, 0), spec.Position + Vector3.new(0, 3, 0)
		end
	end

	-- Fallback Sector 3 sparring ground defaults
	return Vector3.new(300, 25, -200), Vector3.new(340, 25, -200), Vector3.new(320, 25, -230)
end

function ArenaManager.AddToQueue(player: Player)
	if activeDuels[player] then return end

	local cultivation = CultivationManager.GetPlayerData(player)
	if not cultivation then return end

	local realm = cultivation.Realm
	local queue = queueByRealm[realm]
	if not queue then
		queue = {}
		queueByRealm[realm] = queue
	end

	for _, p in ipairs(queue) do
		if p == player then return end
	end

	table.insert(queue, player)
	arenaRemote:FireClient(player, { Action = "QueueJoined", Realm = realm })
	print(string.format("[ArenaManager] %s joined the %s Sparring Queue.", player.Name, realm))

	if #queue >= 2 then
		local p1 = table.remove(queue, 1) :: Player
		local p2 = table.remove(queue, 1) :: Player
		ArenaManager.StartDuel(p1, p2, realm)
	end
end

function ArenaManager.RemoveFromQueue(player: Player)
	for _, queue in pairs(queueByRealm) do
		for i, p in ipairs(queue) do
			if p == player then
				table.remove(queue, i)
				arenaRemote:FireClient(player, { Action = "QueueLeft" })
				print(string.format("[ArenaManager] %s left the Sparring Queue.", player.Name))
				return
			end
		end
	end
end

function ArenaManager.StartDuel(p1: Player, p2: Player, realm: CultivationConfig.RealmTier)
	local p1Spawn, p2Spawn, specSpawn = ArenaManager.GetArenaSpawns()

	local duel: ActiveDuel = {
		Player1 = p1,
		Player2 = p2,
		Realm = realm,
		StartTime = os.time(),
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
			char:PivotTo(CFrame.new(spawnPos, opponent.Character and opponent.Character:GetPivot().Position or spawnPos))
			local hum = char:FindFirstChild("Humanoid") :: Humanoid?
			if hum then
				hum.Health = hum.MaxHealth
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

	print(string.format("[ArenaManager] ⚔️ Duel Started: %s vs %s (Realm: %s)!", p1.Name, p2.Name, realm))
end

function ArenaManager.MonitorDuels()
	local now = os.time()
	local evaluated: { [ActiveDuel]: boolean } = {}

	for _, duel in pairs(activeDuels) do
		if evaluated[duel] or not duel.IsActive then continue end
		evaluated[duel] = true

		local p1 = duel.Player1
		local p2 = duel.Player2
		local p1Hum = p1.Character and p1.Character:FindFirstChild("Humanoid") :: Humanoid?
		local p2Hum = p2.Character and p2.Character:FindFirstChild("Humanoid") :: Humanoid?

		if p1Hum and p1Hum.Health <= 1 then
			ArenaManager.EndDuel(duel, p2, "Knockdown Victory")
		elseif p2Hum and p2Hum.Health <= 1 then
			ArenaManager.EndDuel(duel, p1, "Knockdown Victory")
		elseif now - duel.StartTime >= duel.Duration then
			local p1Pct = p1Hum and (p1Hum.Health / p1Hum.MaxHealth) or 0
			local p2Pct = p2Hum and (p2Hum.Health / p2Hum.MaxHealth) or 0

			if p1Pct > p2Pct then
				ArenaManager.EndDuel(duel, p1, "Time Limit Exceeded (Higher HP)")
			elseif p2Pct > p1Pct then
				ArenaManager.EndDuel(duel, p2, "Time Limit Exceeded (Higher HP)")
			else
				ArenaManager.EndDuel(duel, nil, "Draw Match")
			end
		end
	end
end

function ArenaManager.EndDuel(duel: ActiveDuel, winner: Player?, reason: string)
	duel.IsActive = false
	activeDuels[duel.Player1] = nil
	activeDuels[duel.Player2] = nil

	local function ResolveFighter(p: Player, isWinner: boolean, isDraw: boolean)
		local char = p.Character
		if char then
			char:PivotTo(CFrame.new(duel.SpectatorSpawn))
			local hum = char:FindFirstChild("Humanoid") :: Humanoid?
			if hum then hum.Health = hum.MaxHealth end
		end

		local contrib = isWinner and 100 or (isDraw and 50 or 25)
		local stones = isWinner and 150 or (isDraw and 75 or 50)

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
		local loser = duel.Player1 == winner and duel.Player2 or duel.Player1
		ResolveFighter(winner, true, false)
		ResolveFighter(loser, false, false)
		print(string.format("[ArenaManager] 🏆 %s defeated %s in Sparring Arena (%s).", winner.Name, loser.Name, reason))
	else
		ResolveFighter(duel.Player1, false, true)
		ResolveFighter(duel.Player2, false, true)
		print(string.format("[ArenaManager] 🤝 Sparring duel between %s and %s ended in a Draw (%s).", 
			duel.Player1.Name, duel.Player2.Name, reason))
	end
end

return ArenaManager