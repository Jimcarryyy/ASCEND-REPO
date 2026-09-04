--!strict
--[[
    ArenaManager.luau
    Location: src/ServerScriptService/Server/Combat/ArenaManager.luau
    Server-authoritative 1v1 Sparring Arena Manager:
    - Production StreamingEnabled protection (RequestStreamAroundAsync prevents void-falling)
    - Zeroed physics velocities on teleport
    - Physical Dual-Pad Standing Detection (DuelPad1 & DuelPad2)
    - 3-Second Visual Countdown with Instant Step-off Cancellation
    - 1,000 HP Normalized Combat with clean non-lethal defeat resolution
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local PlayerDataManager = require(ServerScriptService.Server.State.PlayerDataManager)
local CultivationManager = require(ServerScriptService.Server.Cultivation.CultivationManager)

type ActiveDuel = {
	Player1: Player,
	Player2: Player,
	StartTime: number,
	Duration: number,
	P1Spawn: CFrame,
	P2Spawn: CFrame,
	SpectatorSpawn: CFrame,
	IsActive: boolean,
}

local ArenaManager = {}
local arenaRemote: RemoteEvent
local activeDuels: { [Player]: ActiveDuel } = {}

-- Pad Standby & Countdown State
local pad1Player: Player? = nil
local pad2Player: Player? = nil
local countdownActive: boolean = false
local countdownTask: thread? = nil

local ARENA_TIME_LIMIT = 90

function ArenaManager.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	ArenaManager.EnsureAnchoredArenaParts()

	arenaRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) ~= "table" or type(payload.Action) ~= "string" then return end

		if payload.Action == "TeleportToLobby" then
			ArenaManager.TeleportToLobby(player)
		end
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		if pad1Player == player then pad1Player = nil end
		if pad2Player == player then pad2Player = nil end
		if countdownActive then ArenaManager.CancelCountdown() end

		local duel = activeDuels[player]
		if duel and duel.IsActive then
			local winner = (duel.Player1 == player) and duel.Player2 or duel.Player1
			ArenaManager.EndDuel(duel, winner, "Opponent Disconnected")
		end
	end)

	-- 10Hz Monitor Loop
	task.spawn(function()
		while true do
			task.wait(0.2)
			ArenaManager.CheckDuelPads()
			ArenaManager.MonitorDuels()
		end
	end)

	print("[ASCEND] ArenaManager Initialized (Live Streaming Protection Active).")
end

function ArenaManager.GetArenaFolder(): Folder?
	return (Workspace:FindFirstChild("SparringArena", true) or Workspace:FindFirstChild("Arena", true)) :: Folder?
end

function ArenaManager.EnsureAnchoredArenaParts()
	local folder = ArenaManager.GetArenaFolder()
	if not folder then return end

	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("BasePart") then
			child.Anchored = true
		elseif child:IsA("Model") then
			for _, part in ipairs(child:GetDescendants()) do
				if part:IsA("BasePart") then part.Anchored = true end
			end
		end
	end
end

function ArenaManager.GetTargetCFrame(partName: string, fallbackCFrame: CFrame): CFrame
	local folder = ArenaManager.GetArenaFolder()
	if folder then
		local part = folder:FindFirstChild(partName, true) :: BasePart?
		if part then
			return part.CFrame + Vector3.new(0, 3.5, 0)
		end
	end
	return fallbackCFrame
end

function ArenaManager.TeleportToLobby(player: Player)
	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and hum.Health > 0 then
		local folder = ArenaManager.GetArenaFolder()
		local lobbyPart = folder and folder:FindFirstChild("LobbySpawn", true) :: BasePart?

		local targetCFrame = if lobbyPart 
			then lobbyPart.CFrame + Vector3.new(0, 3.5, 0) 
			else hrp.CFrame + Vector3.new(0, 5, 0)

		-- Production Streaming Protection
		pcall(function()
			player:RequestStreamAroundAsync(targetCFrame.Position, 2)
		end)

		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		char:PivotTo(targetCFrame)

		print(string.format("[ArenaManager] Teleported %s safely to LobbySpawn.", player.Name))
	end
end

-- =============================================================================
-- DUAL-PAD DETECTION & COUNTDOWN
-- =============================================================================
local function IsPlayerOnPad(player: Player, padPart: BasePart): boolean
	local char = player.Character
	local hrp = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then return false end

	local padPos = padPart.Position
	local padSize = padPart.Size
	local playerPos = hrp.Position

	local xDiff = math.abs(playerPos.X - padPos.X)
	local zDiff = math.abs(playerPos.Z - padPos.Z)
	local yDiff = math.abs(playerPos.Y - padPos.Y)

	return (xDiff <= (padSize.X / 2 + 1.5)) and (zDiff <= (padSize.Z / 2 + 1.5)) and (yDiff <= 8)
end

function ArenaManager.CheckDuelPads()
	-- Recursively find DuelPad1 and DuelPad2 across Functional_Stations and Workspace
	local pad1 = Workspace:FindFirstChild("DuelPad1", true) or (Workspace.Functional_Stations and Workspace.Functional_Stations:FindFirstChild("DuelPad1", true))
	local pad2 = Workspace:FindFirstChild("DuelPad2", true) or (Workspace.Functional_Stations and Workspace.Functional_Stations:FindFirstChild("DuelPad2", true))
	
	if not pad1 or not pad2 then return end

	local p1Part = if pad1:IsA("Model") then (pad1:FindFirstChild("DuelPad", true) or pad1.PrimaryPart or pad1:FindFirstChildWhichIsA("BasePart")) else pad1 :: BasePart
	local p2Part = if pad2:IsA("Model") then (pad2:FindFirstChild("DuelPad", true) or pad2.PrimaryPart or pad2:FindFirstChildWhichIsA("BasePart")) else pad2 :: BasePart

	if not p1Part or not p2Part then return end

	local currentP1: Player? = nil
	local currentP2: Player? = nil

	for _, player in ipairs(Players:GetPlayers()) do
		if not activeDuels[player] then
			if IsPlayerOnPad(player, p1Part :: BasePart) then
				currentP1 = player
			elseif IsPlayerOnPad(player, p2Part :: BasePart) then
				currentP2 = player
			end
		end
	end

	pad1Player = currentP1
	pad2Player = currentP2

	if currentP1 and currentP2 and currentP1 ~= currentP2 then
		if not countdownActive then
			ArenaManager.StartCountdown(currentP1, currentP2)
		end
	else
		if countdownActive then
			ArenaManager.CancelCountdown()
		end
	end
end

function ArenaManager.StartCountdown(p1: Player, p2: Player)
	countdownActive = true

	countdownTask = task.spawn(function()
		for sec = 3, 1, -1 do
			if not countdownActive then return end
			arenaRemote:FireClient(p1, { Action = "CountdownTick", Seconds = sec })
			arenaRemote:FireClient(p2, { Action = "CountdownTick", Seconds = sec })
			task.wait(1.0)
		end

		if countdownActive and pad1Player == p1 and pad2Player == p2 then
			countdownActive = false
			ArenaManager.StartDuel(p1, p2)
		else
			ArenaManager.CancelCountdown()
		end
	end)
end

function ArenaManager.CancelCountdown()
	countdownActive = false
	if countdownTask then
		task.cancel(countdownTask)
		countdownTask = nil
	end

	if pad1Player then
		arenaRemote:FireClient(pad1Player, { Action = "CountdownCancelled" })
	end
	if pad2Player then
		arenaRemote:FireClient(pad2Player, { Action = "CountdownCancelled" })
	end
end

-- =============================================================================
-- IN-RING 1v1 DUEL EXECUTION (STREAMING SAFE)
-- =============================================================================
function ArenaManager.StartDuel(p1: Player, p2: Player)
	-- Automatically locate spawn nodes inside Sect_Solitary_SwordArena
	local arena = Workspace:FindFirstChild("Sect_Solitary_SwordArena", true)
	local p1Node = arena and arena:FindFirstChild("SpawnNode_Challenger_Cyan", true) :: BasePart?
	local p2Node = arena and arena:FindFirstChild("SpawnNode_Defender_Red", true) :: BasePart?

	local p1SpawnCF = if p1Node then p1Node.CFrame + Vector3.new(0, 3.5, 0) else CFrame.new(0, 15, 0)
	local p2SpawnCF = if p2Node then p2Node.CFrame + Vector3.new(0, 3.5, 0) else CFrame.new(0, 15, 40)
	local specSpawnCF = p1SpawnCF + Vector3.new(-30, 10, 0)

	local duel: ActiveDuel = {
		Player1 = p1,
		Player2 = p2,
		StartTime = os.clock(),
		Duration = ARENA_TIME_LIMIT,
		P1Spawn = p1SpawnCF,
		P2Spawn = p2SpawnCF,
		SpectatorSpawn = specSpawnCF,
		IsActive = true,
	}

	activeDuels[p1] = duel
	activeDuels[p2] = duel

	local function SetupFighter(p: Player, spawnCF: CFrame, oppCF: CFrame)
		local char = p.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hrp and hum and hum.Health > 0 then
				char:SetAttribute("InArena", true)

				pcall(function()
					p:RequestStreamAroundAsync(spawnCF.Position, 2)
				end)

				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero

				local lookAtCF = CFrame.lookAt(spawnCF.Position, Vector3.new(oppCF.Position.X, spawnCF.Position.Y, oppCF.Position.Z))
				char:PivotTo(lookAtCF)

				hum.MaxHealth = 1000
				hum.Health = 1000
				hum.WalkSpeed = 16
			end
		end

		arenaRemote:FireClient(p, {
			Action = "DuelStarting",
			Duration = ARENA_TIME_LIMIT,
		})
	end

	SetupFighter(p1, p1SpawnCF, p2SpawnCF)
	SetupFighter(p2, p2SpawnCF, p1SpawnCF)

	print(string.format("[ArenaManager] ⚔️ 1v1 Arena Duel Commenced: %s vs %s!", p1.Name, p2.Name))
end

function ArenaManager.MonitorDuels()
	local now = os.clock()
	local evaluated: { [ActiveDuel]: boolean } = {}

	for _, duel in pairs(activeDuels) do
		if evaluated[duel] or not duel.IsActive then continue end
		evaluated[duel] = true

		local p1Hum = duel.Player1.Character and duel.Player1.Character:FindFirstChildOfClass("Humanoid")
		local p2Hum = duel.Player2.Character and duel.Player2.Character:FindFirstChildOfClass("Humanoid")

		local p1Health = if p1Hum then p1Hum.Health else 0
		local p2Health = if p2Hum then p2Hum.Health else 0

		if p1Health <= 1 and p2Health <= 1 then
			ArenaManager.EndDuel(duel, nil, "Simultaneous Double Knockout")
		elseif p1Health <= 1 then
			ArenaManager.EndDuel(duel, duel.Player2, "Knockdown Victory")
		elseif p2Health <= 1 then
			ArenaManager.EndDuel(duel, duel.Player1, "Knockdown Victory")
		elseif (now - duel.StartTime) >= duel.Duration then
			if p1Health > p2Health then
				ArenaManager.EndDuel(duel, duel.Player1, "Time Limit Exceeded (Higher HP)")
			elseif p2Health > p1Health then
				ArenaManager.EndDuel(duel, duel.Player2, "Time Limit Exceeded (Higher HP)")
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

	local function ResetFighter(p: Player, isWinner: boolean, isDraw: boolean)
		local char = p.Character
		if char then
			char:SetAttribute("InArena", false)
			local hum = char:FindFirstChildOfClass("Humanoid")
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?

			if hum and hum.Health > 0 and hrp then
				pcall(function()
					p:RequestStreamAroundAsync(duel.SpectatorSpawn.Position, 2)
				end)

				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.AssemblyAngularVelocity = Vector3.zero
				char:PivotTo(duel.SpectatorSpawn)

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
		ResetFighter(winner, true, false)
		ResetFighter(loser, false, false)
		print(string.format("[ArenaManager] 🏆 %s defeated %s (%s).", winner.Name, loser.Name, reason))
	else
		ResetFighter(duel.Player1, false, true)
		ResetFighter(duel.Player2, false, true)
		print(string.format("[ArenaManager] 🤝 Duel between %s and %s resulted in a Draw (%s).", duel.Player1.Name, duel.Player2.Name, reason))
	end
end

return ArenaManager