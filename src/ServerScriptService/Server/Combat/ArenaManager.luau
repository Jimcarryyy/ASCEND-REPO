--!strict
--[[
    ArenaManager.luau
    Location: src/ServerScriptService/Server/Combat/ArenaManager.luau
    Authoritative PvP manager for ASCEND:
    - Retired the 2-pad physical bottleneck in favor of On-Demand Sparring Challenges
    - Spawns dynamic 50-stud circular Qi Rings anywhere in the world
    - Non-lethal concession resolution (clamped at 1 HP, no deaths, full HP restoration)
    - Dynamic Sect Safe Zone Peace detection
    - Reward distribution (Contribution Points & Spirit Stones)
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

export type DuelSession = {
	Player1: Player,
	Player2: Player,
	Center: Vector3,
	Radius: number,
	StartTime: number,
	Duration: number,
	IsActive: boolean,
	Ring: Instance?,
}

local ArenaManager = {}

local activeOnDemandDuels: { [Player]: DuelSession } = {}
local pendingChallenges: { [Player]: { Target: Player, Timestamp: number } } = {}
local spawnedQiRings: { [DuelSession]: Instance } = {}

local arenaRemote: RemoteEvent? = nil
local playerDataManagerRef: any = nil
local cultivationManagerRef: any = nil

local spawnPart = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
local sectOrigin = if spawnPart then spawnPart.Position else Vector3.new(0, 5, 0)

local function getPlayerDataManager(): any
	if not playerDataManagerRef then
		playerDataManagerRef = require(ServerScriptService.Server.State.PlayerDataManager)
	end
	return playerDataManagerRef
end

local function getCultivationManager(): any
	if not cultivationManagerRef then
		cultivationManagerRef = require(ServerScriptService.Server.Cultivation.CultivationManager)
	end
	return cultivationManagerRef
end

local function getArenaRemote(): RemoteEvent?
	if not arenaRemote then
		arenaRemote = RemoteEvents.GetRemote("ArenaAction")
	end
	return arenaRemote
end

function ArenaManager.GetSectOrigin(): Vector3
	return sectOrigin
end

function ArenaManager.IsInSafeZone(position: Vector3): boolean
	local safeZonesFolder = Workspace:FindFirstChild("SafeZones")
	if safeZonesFolder then
		for _, part in ipairs(safeZonesFolder:GetChildren()) do
			if part:IsA("BasePart") and (position - part.Position).Magnitude <= (part.Size.Magnitude / 2) then
				return true
			end
		end
	end

	return (position - sectOrigin).Magnitude <= 350
end

function ArenaManager.AreDueling(p1: Player?, p2: Player?): boolean
	if not p1 or not p2 then return false end
	local d1 = activeOnDemandDuels[p1]
	local d2 = activeOnDemandDuels[p2]
	return (d1 ~= nil) and (d1 == d2) and (d1.IsActive == true)
end

function ArenaManager.GetActiveDuel(player: Player): DuelSession?
	return activeOnDemandDuels[player]
end

function ArenaManager.SpawnQiRing(centerPos: Vector3, radius: number): Instance
	local ring = Instance.new("Part")
	ring.Name = "OnDemandSparringQiRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, radius * 2, radius * 2)
	ring.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(0, 220, 255)
	ring.Transparency = 0.75
	ring.CanCollide = false
	ring.CanQuery = false
	ring.CanTouch = false
	ring.Anchored = true
	ring.Parent = Workspace

	local highlight = Instance.new("SelectionBox")
	highlight.Color3 = Color3.fromRGB(255, 215, 0)
	highlight.LineThickness = 0.08
	highlight.Adornee = ring
	highlight.Parent = ring

	return ring
end

function ArenaManager.StartOnDemandDuel(p1: Player, p2: Player, customCenter: Vector3?): DuelSession?
	if activeOnDemandDuels[p1] or activeOnDemandDuels[p2] then return nil end

	local c1 = p1.Character
	local c2 = p2.Character
	local hrp1 = c1 and c1:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hrp2 = c2 and c2:FindFirstChild("HumanoidRootPart") :: BasePart?

	local center = customCenter or (if hrp1 and hrp2 then (hrp1.Position + hrp2.Position) / 2 else (if hrp1 then hrp1.Position else sectOrigin))
	local ringInstance = ArenaManager.SpawnQiRing(center - Vector3.new(0, 2.5, 0), 25)

	local duelSession: DuelSession = {
		Player1 = p1,
		Player2 = p2,
		Center = center,
		Radius = 25,
		StartTime = os.clock(),
		Duration = 90,
		IsActive = true,
		Ring = ringInstance,
	}

	activeOnDemandDuels[p1] = duelSession
	activeOnDemandDuels[p2] = duelSession
	spawnedQiRings[duelSession] = ringInstance

	if c1 then c1:SetAttribute("InSparringRing", true) end
	if c2 then c2:SetAttribute("InSparringRing", true) end

	local remote = getArenaRemote()
	if remote then
		remote:FireClient(p1, { Action = "DuelStarting", OpponentName = p2.DisplayName, Duration = 90, IsOnDemand = true })
		remote:FireClient(p2, { Action = "DuelStarting", OpponentName = p1.DisplayName, Duration = 90, IsOnDemand = true })
	end

	return duelSession
end

function ArenaManager.EndOnDemandDuel(duelSession: DuelSession, winner: Player?, reason: string)
	if not duelSession or not duelSession.IsActive then return end
	duelSession.IsActive = false

	activeOnDemandDuels[duelSession.Player1] = nil
	activeOnDemandDuels[duelSession.Player2] = nil

	if duelSession.Ring and duelSession.Ring.Parent then
		duelSession.Ring:Destroy()
	end
	spawnedQiRings[duelSession] = nil

	local cultMgr = getCultivationManager()
	local pdmMgr = getPlayerDataManager()
	local remote = getArenaRemote()

	local function ConcludeFighter(p: Player, isWinner: boolean)
		local char = p.Character
		if char then
			char:SetAttribute("InSparringRing", false)
			if cultMgr and cultMgr.ApplyRealmStats then
				cultMgr.ApplyRealmStats(p)
			end
		end

		if isWinner and pdmMgr then
			if pdmMgr.AddContributionPoints then pdmMgr.AddContributionPoints(p, 50) end
			if pdmMgr.AddSpiritStones then pdmMgr.AddSpiritStones(p, 100) end
		end

		if remote then
			remote:FireClient(p, {
				Action = "DuelEnded",
				IsWinner = isWinner,
				Reason = reason,
			})
		end
	end

	if winner then
		local loser = (duelSession.Player1 == winner) and duelSession.Player2 or duelSession.Player1
		ConcludeFighter(winner, true)
		ConcludeFighter(loser, false)
	else
		ConcludeFighter(duelSession.Player1, false)
		ConcludeFighter(duelSession.Player2, false)
	end
end

function ArenaManager.Init()
	local remote = getArenaRemote()

	if remote then
		remote.OnServerEvent:Connect(function(player: Player, payload: any)
			if type(payload) ~= "table" then return end

			if payload.Action == "ChallengePlayer" and payload.TargetPlayer then
				local target = payload.TargetPlayer :: Player
				if target == player or not target.Parent then return end
				if activeOnDemandDuels[player] or activeOnDemandDuels[target] then return end

				local pChar = player.Character
				local tChar = target.Character
				local pHrp = pChar and pChar:FindFirstChild("HumanoidRootPart") :: BasePart?
				local tHrp = tChar and tChar:FindFirstChild("HumanoidRootPart") :: BasePart?

				if pHrp and tHrp and (pHrp.Position - tHrp.Position).Magnitude <= 35 then
					pendingChallenges[target] = { Target = player, Timestamp = os.clock() }
					remote:FireClient(target, {
						Action = "DuelChallenged",
						Challenger = player,
						ChallengerName = player.DisplayName,
					})
				end

			elseif payload.Action == "AcceptChallenge" and payload.Challenger then
				local challenger = payload.Challenger :: Player
				local request = pendingChallenges[player]
				if request and request.Target == challenger and (os.clock() - request.Timestamp) <= 30 then
					pendingChallenges[player] = nil
					ArenaManager.StartOnDemandDuel(challenger, player)
				end

			elseif payload.Action == "DeclineChallenge" then
				pendingChallenges[player] = nil
			end
		end)
	end

	-- Boundary monitoring for active Qi Rings
	task.spawn(function()
		while true do
			task.wait(0.5)
			for p, session in pairs(activeOnDemandDuels) do
				if session.IsActive and p.Character then
					local hrp = p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
					if hrp then
						local dist = (hrp.Position - session.Center).Magnitude
						if dist > (session.Radius + 2) then
							local flatDir = Vector3.new(session.Center.X - hrp.Position.X, 0, session.Center.Z - hrp.Position.Z)
							local dir = if flatDir.Magnitude > 0.001 then flatDir.Unit else Vector3.new(0, 0, -1)

							local rootAtt = hrp:FindFirstChild("RootAttachment") :: Attachment?
							if not rootAtt then
								rootAtt = Instance.new("Attachment")
								rootAtt.Name = "RootAttachment"
								rootAtt.Parent = hrp
							end

							local existingVel = hrp:FindFirstChild("ArenaBoundaryVel")
							if existingVel then
								existingVel:Destroy()
							end

							local reboundVel = Instance.new("LinearVelocity")
							reboundVel.Name = "ArenaBoundaryVel"
							reboundVel.Attachment0 = rootAtt
							reboundVel.ForceLimitMode = Enum.ForceLimitMode.PerAxis
							reboundVel.MaxAxesForce = Vector3.new(250000, 5000, 250000)
							reboundVel.VectorVelocity = dir * 20
							reboundVel.RelativeTo = Enum.ActuatorRelativeTo.World
							reboundVel.Parent = hrp

							task.delay(0.15, function()
								if reboundVel and reboundVel.Parent then
									reboundVel:Destroy()
								end
							end)
						end
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(leavingPlayer)
		local session = activeOnDemandDuels[leavingPlayer]
		if session and session.IsActive then
			local opponent = (session.Player1 == leavingPlayer) and session.Player2 or session.Player1
			ArenaManager.EndOnDemandDuel(session, opponent, "Opponent Disconnected")
		end
		activeOnDemandDuels[leavingPlayer] = nil
		pendingChallenges[leavingPlayer] = nil
	end)

	print("[ASCEND] ArenaManager Initialized (On-Demand Qi Ring Sparring Active).")
end

return ArenaManager