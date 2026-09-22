-- [DYNAMIC HUD ZONE FRAME & PRESSURE MONITOR]
local function StartQiZoneMonitor()
	task.spawn(function()
		local realmColors = {
			[1] = Color3.fromRGB(180, 240, 255),
			[2] = Color3.fromRGB(120, 220, 255),
			[3] = Color3.fromRGB(255, 215, 0),
			[4] = Color3.fromRGB(200, 130, 255),
			[5] = Color3.fromRGB(255, 100, 100),
			[6] = Color3.fromRGB(110, 255, 190),
			[7] = Color3.fromRGB(255, 160, 60),
			[8] = Color3.fromRGB(255, 240, 140),
			[9] = Color3.fromRGB(220, 110, 255),
			[10] = Color3.fromRGB(255, 255, 255),
		}

		while true do
			task.wait(0.3)
			local char = localPlayer.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			local qiNodes = Workspace:FindFirstChild("QiNodes")

			-- Resolve player tier authoritatively
			local playerTier = 1
			local cultConfig = require(ReplicatedStorage.Shared.Configs.CultivationConfig)
			local currentRealm = char and char:GetAttribute("Realm") or localPlayer:GetAttribute("Realm")
			if currentRealm and cultConfig and cultConfig[currentRealm] then
				playerTier = cultConfig[currentRealm].Tier or 1
			elseif localPlayer:GetAttribute("Tier") then
				playerTier = localPlayer:GetAttribute("Tier")
			end

			-- Locate ZoneFrame in PlayerGui
			local masterHud = playerGui:FindFirstChild("MasterHUDGui")
			local zoneFrame = masterHud and masterHud:FindFirstChild("ZoneFrame") :: Frame?
			local zoneLabel = zoneFrame and zoneFrame:FindFirstChildWhichIsA("TextLabel") :: TextLabel?

			local currentZone: BasePart? = nil
			local zoneDist = math.huge

			if hrp and qiNodes then
				for _, node in ipairs(qiNodes:GetChildren()) do
					if node:IsA("BasePart") then
						local dist = (hrp.Position - node.Position).Magnitude
						local radius = math.max(node.Size.X, node.Size.Z) / 2 + 3
						if dist <= radius and dist < zoneDist then
							currentZone = node
							zoneDist = dist
						end
					end
				end
			end

			if zoneFrame and zoneLabel then
				if currentZone then
					local reqTier = (currentZone:GetAttribute("RequiredTier") or currentZone:GetAttribute("MinTier") or 1) :: number
					local reqRealm = tostring(currentZone:GetAttribute("RequiredRealm") or "Spiritual Realm")
					local nodeName = tostring(currentZone:GetAttribute("NodeName") or currentZone.Name)
					local mult = (currentZone:GetAttribute("QiMultiplier") or 1.0) :: number

					zoneFrame.Visible = true
					zoneLabel.FontFace = Font.fromName("Fondamento", Enum.FontWeight.Bold)
					zoneLabel.Font = Enum.Font.Fondamento

					if playerTier < reqTier then
						-- UNDER-LEVELED: WARNING MODE
						zoneLabel.Text = string.format("⚠️ %s [Requires Tier %d (%s) — Qi Ineffective (1.0x)]", nodeName, reqTier, reqRealm)
						zoneLabel.TextColor3 = Color3.fromRGB(255, 75, 75)
					else
						-- AUTHORIZED: ACTIVE MULTIPLIER MODE
						zoneLabel.Text = string.format("✦ %s — %.1fx Qi SPEED ✦", nodeName, mult)
						zoneLabel.TextColor3 = realmColors[reqTier] or Color3.fromRGB(255, 255, 255)
					end
				else
					-- Outside all zones
					zoneFrame.Visible = false
				end
			end
		end
	end)
end

-- [QI ZONE PROXIMITY & SPIRITUAL PRESSURE MONITOR]
function CultivationController.Init()
	HookStudioUI()

	StartQiZoneMonitor()	SetupInnerDemonUI()

	local cultivationRemote = RemoteEvents.GetRemote("UpdateCultivation")
	local cultivationActionRemote = RemoteEvents.GetRemote("CultivationAction")

	cultivationRemote.OnClientEvent:Connect(function(data: { [string]: any })
		if type(data) ~= "table" then return end
		local character = player.Character
		if not character then return end

		-- 1. Meditation Audio & FOV Toggle
		local newMeditatingState = (data.IsMeditating == true)
		if newMeditatingState ~= isMeditating then
			if newMeditatingState then
				CultivationController.StartMeditation(character)
			else
				CultivationController.StopMeditation(character)
			end
		end

		-- 2. Dantian Saturated [B] Keybind Prompt Toggle
		if type(data.MaxQi) == "number" and type(data.TargetQi) == "number" then
			local isSaturated = (data.MaxQi >= data.TargetQi)
			if readyPrompt then
				if isSaturated and not isReadyPromptActive then
					isReadyPromptActive = true
					readyPrompt.Position = UDim2.new(0.5, 0, 0.90, 0)
					readyPrompt.Visible = true
					if tonumber(data.Order) == 9 then
						readyPrompt.Text = "[B] INITIATE HEAVENLY TRIBULATION (Dan Required)"
						readyPrompt.TextColor3 = Color3.fromRGB(255, 215, 0)
					elseif readyPrompt:IsA("TextLabel") or readyPrompt:IsA("TextButton") then
						readyPrompt.Text = "[B] BREAKTHROUGH READY"
						readyPrompt.TextColor3 = Color3.fromRGB(255, 255, 255)
					end
					TweenService:Create(readyPrompt, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						Position = UDim2.new(0.5, 0, 0.82, 0),
					}):Play()
				elseif not isSaturated and isReadyPromptActive then
					isReadyPromptActive = false
					readyPrompt.Visible = false
				end
			end
		end

		-- 3. Breakthrough Rejection Event Handler
		if data.Action == "BreakthroughRejected" then
			local cur = tonumber(data.CurrentQi) or 0
			local tgt = tonumber(data.TargetQi) or 1
			local pct = tonumber(data.Percentage) or math.floor((cur / math.max(1, tgt)) * 100)
			CultivationController.ShowRejectionToast(cur, tgt, pct, data.Message)
		end

		-- 4. Breakthrough Success / Ascension Event Handler
		if data.Action == "BreakthroughSuccess" then
			CultivationController.ShowAscensionModal(data)
		end
	end)

	cultivationActionRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end

		if payload.Action == "InnerDemonStart" then
			StartCameraShake()
			if vignetteFrame then
				TweenService:Create(vignetteFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 0.35,
					ImageColor3 = payload.AuraColor or Color3.fromRGB(90, 0, 40),
				}):Play()
			end

		elseif payload.Action == "FocusPulsePrompt" then
			currentQteWave = payload.Wave
			isQteActive = true
			if qteContainer and pulseRing then
				qteContainer.Visible = true
				pulseRing.Size = UDim2.new(2.0, 0, 2.0, 0)
				local win = payload.Window or 1.2
				local tween = TweenService:Create(pulseRing, TweenInfo.new(win, Enum.EasingStyle.Linear), {
					Size = UDim2.new(1.0, 0, 1.0, 0),
				})
				tween:Play()
			end

		elseif payload.Action == "InnerDemonBacklash" then
			isQteActive = false
			StopCameraShake()
			if qteContainer then qteContainer.Visible = false end
			if vignetteFrame then
				vignetteFrame.ImageColor3 = Color3.fromRGB(255, 0, 0)
				vignetteFrame.ImageTransparency = 0.1
				TweenService:Create(vignetteFrame, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 1.0,
				}):Play()
			end
			CultivationController.ShowRejectionToast(0, 0, 0, payload.Message or "TRIBULATION BACKLASH: Qi Deviation!")

		elseif payload.Action == "InnerDemonSuccess" then
			isQteActive = false
			StopCameraShake()
			if qteContainer then qteContainer.Visible = false end
			if vignetteFrame then
				TweenService:Create(vignetteFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					ImageTransparency = 1.0,
				}):Play()
			end
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if isQteActive and currentQteWave then
			if input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isQteActive = false
				if qteContainer then qteContainer.Visible = false end
				cultivationActionRemote:FireServer({
					Action = "FocusPulse",
					Wave = currentQteWave,
				})
				return
			end
		end

		if processed then return end
	end)

	RunService.Heartbeat:Connect(function()
		local char = player.Character
		if char and not isMeditating then
			UpdateZoneBanner(char)
		end
	end)

	print("[ASCEND] CultivationController Initialized (Inner Demon QTE & Rejection Feedback Active).")
end

return CultivationController