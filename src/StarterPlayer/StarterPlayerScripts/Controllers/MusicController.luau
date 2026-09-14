--!strict
--[[
    MusicController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/MusicController.luau
    Client music controller for ASCEND.
    - Dynamic Proximity Threat Combat Music (rbxassetid://110184030258486)
    - Proximity Detection: Engages when living enemies enter within 55 studs
    - 🚀 Natural Victory Fade-Out: Instantly begins a smooth 2.8s decrescendo when all nearby enemies die
    - Pack-Aware: Keeps playing if additional living foes are still within threat radius
    - Respects player BGM settings from SettingsGui
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local MusicController = {}
local player = Players.LocalPlayer

local COMBAT_MUSIC_ASSET = "rbxassetid://110184030258486"
local ENGAGE_DISTANCE = 55 -- Studs distance to enemy mob to trigger battle music
local DISENGAGE_BUFFER_SECONDS = 1.5 -- Short grace buffer if fleeing combat

local combatMusic: Sound? = nil
local isInCombat = false
local lastThreatTimestamp = 0
local activeTween: Tween? = nil

local function SetupCombatMusic()
	local existing = SoundService:FindFirstChild("CombatBGM")
	if existing then existing:Destroy() end

	local sound = Instance.new("Sound")
	sound.Name = "CombatBGM"
	sound.SoundId = COMBAT_MUSIC_ASSET
	sound.Looped = true
	sound.Volume = 0 -- Start silent for smooth fade-in
	sound.PlaybackSpeed = 1.0
	sound.Parent = SoundService

	sound:Play()
	combatMusic = sound
end

local function IsPlayerInThreat(): boolean
	local char = player.Character
	if not char then return false end

	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return false end

	local playerPos = hrp.Position

	-- Scan Workspace.MobSpawns and Workspace for active living mobs
	local mobSpawns = Workspace:FindFirstChild("MobSpawns") or Workspace:FindFirstChild("BeastSpawns")
	local searchContainers = { mobSpawns, Workspace }

	for _, container in ipairs(searchContainers) do
		if container then
			for _, desc in ipairs(container:GetChildren()) do
				if desc:IsA("Model") and desc ~= char then
					local enemyHum = desc:FindFirstChildOfClass("Humanoid")
					local enemyHrp = desc:FindFirstChild("HumanoidRootPart") or desc.PrimaryPart

					if enemyHum and enemyHrp and enemyHum.Health > 0 then
						local isMob = desc:FindFirstChild("MobHealthUI", true) ~= nil 
							or (desc.Parent and (desc.Parent.Name == "MobSpawns" or desc.Parent.Name == "BeastSpawns"))
							or string.find(desc.Name:lower(), "disciple")
							or string.find(desc.Name:lower(), "assassin")
							or string.find(desc.Name:lower(), "guard")
							or string.find(desc.Name:lower(), "boss")

						if isMob then
							local dist = (enemyHrp.Position - playerPos).Magnitude
							if dist <= ENGAGE_DISTANCE then
								return true
							end
						end
					end
				end
			end
		end
	end

	return false
end

local function FadeCombatMusic(targetVolume: number, duration: number)
	if not combatMusic then return end
	if activeTween then activeTween:Cancel() end

	activeTween = TweenService:Create(combatMusic, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Volume = targetVolume
	})
	activeTween:Play()
end

function MusicController.Init()
	SetupCombatMusic()

	-- 1. 🚀 Instant Victory Fade Listener on Mob Defeats
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction") :: RemoteEvent?
	if combatActionRemote then
		combatActionRemote.OnClientEvent:Connect(function(attacker: Player?, skillKey: string, payload: any?)
			if skillKey == "MobDefeated" then
				-- Check immediately if any other enemies are still alive nearby
				task.defer(function()
					task.wait(0.15) -- Small breath for death ragdoll/cleanup to register
					if not IsPlayerInThreat() then
						if isInCombat then
							isInCombat = false
							lastThreatTimestamp = 0
							-- Naturally fade out battle music over 2.8s on victory
							FadeCombatMusic(0.00, 2.8)
						end
					end
				end)
			end
		end)
	end

	-- 2. Periodic Proximity Check (Runs every 0.35s)
	task.spawn(function()
		while true do
			task.wait(0.35)

			-- Honor player's BGM mute setting from SettingsGui
			if combatMusic and combatMusic.Volume > 0 and (player:GetAttribute("BGMEnabled") == false) then
				combatMusic.Volume = 0
				continue
			end

			local threatDetected = IsPlayerInThreat()
			local now = os.clock()

			if threatDetected then
				lastThreatTimestamp = now
				if not isInCombat then
					isInCombat = true
					-- Smoothly swell into combat music over 1.2s
					FadeCombatMusic(0.50, 1.2)
				end
			else
				if isInCombat then
					-- If player walked away or all enemies died without event trigger
					if (now - lastThreatTimestamp) >= DISENGAGE_BUFFER_SECONDS then
						isInCombat = false
						FadeCombatMusic(0.00, 2.8)
					end
				end
			end
		end
	end)

	print("[ASCEND] MusicController Initialized (Natural Victory Fade-Out & Pack Awareness Active).")
end

return MusicController