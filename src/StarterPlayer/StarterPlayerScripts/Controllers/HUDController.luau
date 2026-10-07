--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Directly binds to:
      1. MasterHUDGui.TopRightMapFrame (Minimap + Live Compass Heading)
      2. MasterHUDGui.FullWorldMapFrame (Interactive Full Sector Map Modal with Live Pin & Landmarks)
      3. MasterHUDGui.ToastContainer.ToastLabel with Generation-ID anti-race protection
      4. KillRewardGui.KillBanner (Dynamic Spirit Stones, Qi & Item Drops on Mob Defeats)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)

local HUDController = {}
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui

local TWEEN_FADE_IN = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_FADE_OUT = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local VICTORY_CHIME_SFX = "rbxassetid://131237241"
local victorySoundInstance: Sound? = nil

-- Toast References
local masterGui: ScreenGui?
local toastContainer: Frame?
local toastLabel: TextLabel?
local currentToastId: number = 0
local currentTween: Tween? = nil

-- Kill & Loot Banner References
local killGui: ScreenGui?
local killBanner: Frame?
local killMobName: TextLabel?
local killStonesPill: Frame?
local killQiPill: Frame?
local killDropPill: Frame?
local killBannerThread: thread? = nil

-- Minimap & Full World Map References
local minimapFrame: Frame?
local mapHeaderText: TextLabel?
local minimapPlayerMarker: TextLabel?
local minimapCoordsLabel: TextLabel?
local fullWorldMapModal: Frame?
local fullMapLivePin: TextLabel?
local fullMapFooterCoords: TextLabel?
local mapRenderConnection: RBXScriptConnection? = nil

-- World Boundary Bounds for 2D Map Normalization (Studs)
local MAP_MIN_X = -1200
local MAP_MAX_X = 1200
local MAP_MIN_Z = -1200
local MAP_MAX_Z = 1200

local function FormatNumber(num: number): string
	local formatted = tostring(math.floor(math.abs(num)))
	local k
	while true do
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return formatted
end

local function PlayUISound(soundId: string, volume: number?)
	if soundId == VICTORY_CHIME_SFX and victorySoundInstance then
		victorySoundInstance.Volume = volume or 1.0
		victorySoundInstance:Play()
		return
	end

	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1.0
	sound.Parent = SoundService
	sound:Play()
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

function HUDController.ToggleWorldMap()
	if not fullWorldMapModal then return end
	fullWorldMapModal.Visible = not fullWorldMapModal.Visible
end

function HUDController.HookStudioUI()
	masterGui = (PlayerGui:FindFirstChild("MasterHUDGui") or PlayerGui:WaitForChild("MasterHUDGui", 6)) :: ScreenGui?
	if masterGui then
		toastContainer = masterGui:FindFirstChild("ToastContainer") :: Frame?
		if toastContainer then
			toastLabel = toastContainer:FindFirstChild("ToastLabel") :: TextLabel?
			toastContainer.Visible = false
			if toastLabel then
				toastLabel.TextTransparency = 1
			end
		end

		-- Wire Minimap
		minimapFrame = masterGui:FindFirstChild("TopRightMapFrame") :: Frame?
		if minimapFrame then
			local mapHeader = minimapFrame:FindFirstChild("MapHeader")
			mapHeaderText = if mapHeader then mapHeader:FindFirstChild("HeaderText") :: TextLabel? else nil

			local mapCanvas = minimapFrame:FindFirstChild("MapCanvas")
			minimapPlayerMarker = if mapCanvas then mapCanvas:FindFirstChild("PlayerMarker") :: TextLabel? else nil

			local mapFooter = minimapFrame:FindFirstChild("MapFooter")
			minimapCoordsLabel = if mapFooter then mapFooter:FindFirstChild("CoordinatesLabel") :: TextLabel? else nil

			local openBtn = minimapFrame:FindFirstChild("OpenFullMapButton") :: TextButton?
			if openBtn then
				openBtn.Activated:Connect(HUDController.ToggleWorldMap)
			end
		end

		-- Wire Full World Map Modal
		fullWorldMapModal = masterGui:FindFirstChild("FullWorldMapFrame") :: Frame?
		if fullWorldMapModal then
			local modalHeader = fullWorldMapModal:FindFirstChild("ModalHeader")
			local closeBtn = modalHeader and modalHeader:FindFirstChild("CloseMapButton") :: TextButton?
			if closeBtn then
				closeBtn.Activated:Connect(function()
					fullWorldMapModal.Visible = false
				end)
			end

			local fullCanvas = fullWorldMapModal:FindFirstChild("FullMapCanvas")
			fullMapLivePin = if fullCanvas then fullCanvas:FindFirstChild("LivePlayerPin") :: TextLabel? else nil

			local modalFooter = fullWorldMapModal:FindFirstChild("ModalFooter")
			fullMapFooterCoords = if modalFooter then modalFooter:FindFirstChild("FooterCoordsLabel") :: TextLabel? else nil
		end

		if mapRenderConnection then
			mapRenderConnection:Disconnect()
			mapRenderConnection = nil
		end

		mapRenderConnection = RunService.RenderStepped:Connect(function()
			local character = LocalPlayer.Character
			local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			local cam = Workspace.CurrentCamera
			if not cam then return end

			local look = cam.CFrame.LookVector
			local headingAngle = math.atan2(look.X, -look.Z)
			local deg = math.deg(headingAngle)
			if deg < 0 then deg += 360 end

			local dirStr = "NORTH"
			if deg >= 337.5 or deg < 22.5 then dirStr = "NORTH"
			elseif deg >= 22.5 and deg < 67.5 then dirStr = "NE"
			elseif deg >= 67.5 and deg < 112.5 then dirStr = "EAST"
			elseif deg >= 112.5 and deg < 157.5 then dirStr = "SE"
			elseif deg >= 157.5 and deg < 202.5 then dirStr = "SOUTH"
			elseif deg >= 202.5 and deg < 247.5 then dirStr = "SW"
			elseif deg >= 247.5 and deg < 292.5 then dirStr = "WEST"
			elseif deg >= 292.5 and deg < 337.5 then dirStr = "NW"
			end

			if mapHeaderText then
				mapHeaderText.Text = string.format("[ MAP · %s %03d° ]", dirStr, math.floor(deg))
			end

			if minimapPlayerMarker then
				minimapPlayerMarker.Rotation = -deg
			end

			if hrp then
				local pos = hrp.Position
				if minimapCoordsLabel then
					minimapCoordsLabel.Text = string.format("X: %d   Z: %d", math.floor(pos.X), math.floor(pos.Z))
				end

				-- Update Live Pin on Full World Map
				if fullWorldMapModal and fullWorldMapModal.Visible and fullMapLivePin then
					local normX = math.clamp((pos.X - MAP_MIN_X) / (MAP_MAX_X - MAP_MIN_X), 0, 1)
					local normZ = math.clamp((pos.Z - MAP_MIN_Z) / (MAP_MAX_Z - MAP_MIN_Z), 0, 1)
					fullMapLivePin.Position = UDim2.new(normX, 0, normZ, 0)
					fullMapLivePin.Rotation = -deg

					if fullMapFooterCoords then
						fullMapFooterCoords.Text = string.format("COORDINATES: X: %d | Z: %d  •  HEADING: %s (%03d°)  •  [M] CLOSE",
							math.floor(pos.X), math.floor(pos.Z), dirStr, math.floor(deg))
					end
				end
			end
		end)
	end

	killGui = (PlayerGui:FindFirstChild("KillRewardGui") or PlayerGui:WaitForChild("KillRewardGui", 6)) :: ScreenGui?
	if killGui then
		killBanner = killGui:FindFirstChild("KillBanner") :: Frame?
		if killBanner then
			killBanner.AnchorPoint = Vector2.new(0.5, 0)
			killBanner.Visible = false
			killMobName = killBanner:FindFirstChild("MobNameLabel") :: TextLabel?
			local lootContainer = killBanner:FindFirstChild("LootContainer") :: Frame?
			if lootContainer then
				killStonesPill = lootContainer:FindFirstChild("StonesPill") :: Frame?
				killQiPill = lootContainer:FindFirstChild("QiPill") :: Frame?
				killDropPill = lootContainer:FindFirstChild("DropPill") :: Frame?
			end
		end
	end
end

function HUDController.ShowToast(message: string, duration: number?)
	if not toastContainer or not toastLabel then return end

	currentToastId += 1
	local thisToastId = currentToastId
	local holdDuration = duration or 2.8

	if currentTween then
		currentTween:Cancel()
		currentTween = nil
	end

	toastLabel.Text = message
	toastLabel.TextTransparency = 0
	toastContainer.Visible = true

	currentTween = TweenService:Create(toastLabel, TWEEN_FADE_IN, { TextTransparency = 0 })
	currentTween:Play()

	task.spawn(function()
		task.wait(holdDuration)
		if currentToastId == thisToastId and toastLabel and toastContainer then
			currentTween = TweenService:Create(toastLabel, TWEEN_FADE_OUT, { TextTransparency = 1 })
			currentTween:Play()

			task.wait(0.36)
			if currentToastId == thisToastId and toastContainer and toastLabel then
				if toastLabel.TextTransparency >= 0.9 then
					toastContainer.Visible = false
				end
			end
		end
	end)
end

function HUDController.ShowItemToast(itemId: string, count: number?, qualityText: string?)
	local itemDef = nil
	pcall(function() itemDef = ItemConfig.GetItem(itemId) end)

	local itemName = if itemDef and itemDef.Name then itemDef.Name else tostring(itemId):gsub("_", " ")
	local qStr = if qualityText and qualityText ~= "" then string.format(" (%s)", qualityText) else ""
	local cStr = if count and count > 1 then string.format(" x%d", count) else ""

	HUDController.ShowToast(string.format("Obtained: %s%s%s", itemName, qStr, cStr), 2.8)
end

function HUDController.ShowMobKillBanner(payload: { [string]: any })
	if not killBanner then return end

	if killBannerThread then
		task.cancel(killBannerThread)
		killBannerThread = nil
	end

	local mobName = tostring(payload.MobName or "Enemy Foe"):upper()
	if killMobName then
		if payload.IsBoss == true then
			killMobName.Text = "★ BOSS VANQUISHED: " .. mobName .. " ★"
		else
			killMobName.Text = "VANQUISHED: " .. mobName
		end
	end

	local stones = tonumber(payload.Stones) or 0
	if killStonesPill then
		local lbl = killStonesPill:FindFirstChild("PillText") :: TextLabel?
		if lbl then lbl.Text = string.format("+%s STONES", FormatNumber(stones)) end
		killStonesPill.Visible = (stones > 0)
	end

	local qi = tonumber(payload.Qi) or 0
	if killQiPill then
		local lbl = killQiPill:FindFirstChild("PillText") :: TextLabel?
		if lbl then lbl.Text = string.format("+%s QI", FormatNumber(qi)) end
		killQiPill.Visible = (qi > 0)
	end

	if killDropPill then
		if type(payload.Drops) == "table" and #payload.Drops > 0 then
			local drop = payload.Drops[1]
			local itemDef = nil
			pcall(function() itemDef = ItemConfig.GetItem(drop.Name) end)
			local cleanName = if itemDef and itemDef.Name then itemDef.Name else tostring(drop.Name):gsub("_", " ")
			local lbl = killDropPill:FindFirstChild("PillText") :: TextLabel?
			if lbl then
				lbl.Text = string.format("+%d %s", tonumber(drop.Count) or 1, cleanName:upper())
			end
			killDropPill.Visible = true
		else
			killDropPill.Visible = false
		end
	end

	PlayUISound(VICTORY_CHIME_SFX, if payload.IsBoss == true then 1.4 else 0.85)

	killBanner.AnchorPoint = Vector2.new(0.5, 0)
	killBanner.Position = UDim2.new(0.5, 0, -0.15, 0)
	killBanner.Visible = true

	local targetY = if toastContainer then toastContainer.Position.Y else UDim.new(0.035, 0)

	local dropTween = TweenService:Create(killBanner, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, targetY.Scale, targetY.Offset),
	})
	dropTween:Play()

	killBannerThread = task.spawn(function()
		task.wait(3.5)
		local riseTween = TweenService:Create(killBanner, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, -0.15, 0),
		})
		riseTween:Play()
		riseTween.Completed:Wait()
		killBanner.Visible = false
	end)
end

function HUDController.Init()
	HUDController.HookStudioUI()

	local sound = Instance.new("Sound")
	sound.Name = "PreloadedVictoryChime"
	sound.SoundId = VICTORY_CHIME_SFX
	sound.Volume = 0.85
	sound.Parent = SoundService
	victorySoundInstance = sound

	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ sound })
		end)
	end)

	-- Hotkey [M] to toggle World Map
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed or UserInputService:GetFocusedTextBox() ~= nil then return end
		if input.KeyCode == Enum.KeyCode.M then
			HUDController.ToggleWorldMap()
		end
	end)

	local gatherRemote = RemoteEvents.GetRemote("GatheringAction") :: RemoteEvent?
	if gatherRemote then
		gatherRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			local targetItem = payload.ItemId or payload.HerbId or payload.HerbName
			if targetItem and (payload.Success == nil or payload.Success == true) then
				HUDController.ShowItemToast(tostring(targetItem), payload.Amount or 1, payload.Quality)
			end
		end)
	end

	local alchemyRemote = RemoteEvents.GetRemote("AlchemyAction") :: RemoteEvent?
	if alchemyRemote then
		alchemyRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end
			if payload.Action == "RefineResult" and payload.Success then
				HUDController.ShowToast(payload.Message or "Refined Spirit Dan Successfully!", 3.0)
			end
		end)
	end

	local sectRemote = RemoteEvents.GetRemote("SectAction") :: RemoteEvent?
	if sectRemote then
		sectRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) == "table" and payload.Action == "QuestCompleted" then
				HUDController.ShowToast("Sect Duty Completed! Rewards Claimed.", 3.0)
			end
		end)
	end

	local combatActionRemote = RemoteEvents.GetRemote("CombatAction") :: RemoteEvent?
	if combatActionRemote then
		combatActionRemote.OnClientEvent:Connect(function(attacker: Player?, skillKey: string, payload: any?)
			if skillKey == "MobDefeated" and type(payload) == "table" then
				HUDController.ShowMobKillBanner(payload)
			end
		end)
	end

	print("[ASCEND] HUDController Initialized (Minimap + Interactive World Map Modal Active).")
end

return HUDController