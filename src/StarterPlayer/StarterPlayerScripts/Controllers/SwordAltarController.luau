--!strict
--[[
    SwordAltarController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/SwordAltarController.luau
    Master client controller for StarterGui.SwordAltarGachaGui:
      - Live backend sync of player Pity counter and Spirit Stones
      - Dynamic Sword Intent Resonance & Flight Speed stats
      - Full interactive support for Draw1Button & Draw10Button
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local ModalWindowManager = require(script.Parent.ModalWindowManager)

local localPlayer = Players.LocalPlayer

local SwordAltarController = {}

-- UI Elements
local altarGui: ScreenGui? = nil
local modalBackdrop: Frame? = nil
local mainWindow: Frame? = nil
local closeButton: GuiButton? = nil
local draw1Btn: TextButton? = nil
local draw10Btn: TextButton? = nil
local pityTextLabel: TextLabel? = nil
local intentBonusLabel: TextLabel? = nil

local isOpen = false
local altarRemote: RemoteEvent? = nil
local currentPity = 0

local function ResolveUI()
	local playerGui = localPlayer:WaitForChild("PlayerGui")
	altarGui = playerGui:WaitForChild("SwordAltarGachaGui", 10) :: ScreenGui?
	if not altarGui then
		warn("[SwordAltarController] SwordAltarGachaGui not found in PlayerGui!")
		return
	end

	altarGui.Enabled = false
	altarGui.ResetOnSpawn = false

	modalBackdrop = altarGui:WaitForChild("ModalBackdrop", 5) :: Frame?
	mainWindow = modalBackdrop and modalBackdrop:WaitForChild("MainWindow", 5) :: Frame?
	if not mainWindow then
		warn("[SwordAltarController] MainWindow not found!")
		return
	end

	local header = mainWindow:FindFirstChild("HeaderFrame")
	closeButton = (header and header:FindFirstChild("CloseButton")) 
		or mainWindow:FindFirstChild("CloseButton") :: GuiButton?

	draw1Btn = mainWindow:FindFirstChild("Draw1Button") :: TextButton?
	draw10Btn = mainWindow:FindFirstChild("Draw10Button") :: TextButton?

	-- Pity Label
	local bannerPanel = mainWindow:FindFirstChild("BannerPanel")
	local pityBox = bannerPanel and bannerPanel:FindFirstChild("PityBox")
	pityTextLabel = pityBox and pityBox:FindFirstChild("PityText") :: TextLabel?

	-- Resonance Stats Label
	local intentPanel = mainWindow:FindFirstChild("SwordIntentPanel")
	intentBonusLabel = intentPanel and intentPanel:FindFirstChild("IntentBonus") :: TextLabel?

	pcall(function()
		altarRemote = RemoteEvents.GetRemote("AltarAction")
	end)
end

local function UpdatePityDisplay(pity: number)
	currentPity = pity
	if pityTextLabel then
		local remaining = math.max(0, 50 - pity)
		if remaining == 0 then
			pityTextLabel.Text = "PITY: 50 / 50 (GUARANTEED 5-STAR NEXT DRAW!)"
			pityTextLabel.TextColor3 = Color3.fromRGB(255, 215, 110)
		else
			pityTextLabel.Text = string.format("PITY: %d / 50 (GUARANTEED 5-STAR IN %d DRAWS)", pity, remaining)
			pityTextLabel.TextColor3 = Color3.fromRGB(56, 189, 248)
		end
	end
end

local function UpdateResonanceDisplay()
	if not intentBonusLabel then return end

	local char = localPlayer.Character
	local swordIntent = (char and char:GetAttribute("SwordIntent")) or localPlayer:GetAttribute("SwordIntent") or 100
	local equippedWeapon = localPlayer:GetAttribute("EquippedWeapon") or "Celestial Jian"
	local flightSpeed = localPlayer:GetAttribute("FlightSpeed") or 48

	intentBonusLabel.Text = string.format(
		"• Current Sword Intent: %d%% Charged\n• Active Weapon: %s\n• Active Intent Multiplier: +25%% Power\n• Flying Sword Speed: %d Studs/Sec",
		math.round(swordIntent),
		tostring(equippedWeapon),
		math.round(flightSpeed)
	)
end

function SwordAltarController.Open()
	if isOpen or not altarGui or not modalBackdrop then return end
	isOpen = true

	ModalWindowManager.RequestOpen("SwordAltar")
	altarGui.Enabled = true
	modalBackdrop.Visible = true

	UpdateResonanceDisplay()

	-- Sync pity immediately from replicated attribute
	local initialPity = (localPlayer:GetAttribute("AltarPity") :: number?) or 0
	UpdatePityDisplay(initialPity)

	-- Request server sync
	if altarRemote then
		altarRemote:FireServer({ Action = "GetPity" })
	end
end

function SwordAltarController.Close()
	if not isOpen or not altarGui or not modalBackdrop then return end
	isOpen = false

	modalBackdrop.Visible = false
	altarGui.Enabled = false
	ModalWindowManager.NotifyClosed("SwordAltar")
end

local function RequestCommune(count: number)
	if not altarRemote then
		pcall(function()
			altarRemote = RemoteEvents.GetRemote("AltarAction")
		end)
	end
	if not altarRemote then return end

	altarRemote:FireServer({ Action = "Commune", Count = count })
end

function SwordAltarController.Init()
	ResolveUI()

	ModalWindowManager.Register("SwordAltar", function()
		SwordAltarController.Close()
	end)

	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			SwordAltarController.Close()
		end)
	end

	if draw1Btn then
		draw1Btn.MouseButton1Click:Connect(function()
			RequestCommune(1)
		end)
	end

	if draw10Btn then
		draw10Btn.MouseButton1Click:Connect(function()
			RequestCommune(10)
		end)
	end

	-- Listen for real-time Attribute replication
	localPlayer:GetAttributeChangedSignal("AltarPity"):Connect(function()
		local updatedPity = (localPlayer:GetAttribute("AltarPity") :: number?) or 0
		UpdatePityDisplay(updatedPity)
	end)

	-- Server Results & Pity Sync Listener
	if altarRemote then
		altarRemote.OnClientEvent:Connect(function(payload: any)
			if type(payload) ~= "table" then return end

			if payload.Action == "PitySync" then
				UpdatePityDisplay(payload.Pity or 0)
			elseif payload.Success == true then
				UpdatePityDisplay(payload.NewPity or 0)
				UpdateResonanceDisplay()

				local bestReward = payload.Results[1]
				for _, res in ipairs(payload.Results) do
					if res.Rarity == "Mythic" then
						bestReward = res
						break
					elseif res.Rarity == "Legendary" and bestReward.Rarity ~= "Mythic" then
						bestReward = res
					end
				end

				print(string.format("[Sword Altar] Awakened: %s (%s)!", bestReward.Name, bestReward.Rarity))
			elseif payload.Success == false then
				warn("[Sword Altar] " .. tostring(payload.Message))
			end
		end)
	end

	-- Proximity Prompt on Sect_SwordAltar_Complete
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		if player ~= localPlayer then return end
		local ancestor = prompt:FindFirstAncestor("Sect_SwordAltar_Complete")
		if prompt.Name == "SwordAltarPrompt" or prompt.Name == "AltarPrompt" or ancestor ~= nil then
			if isOpen then
				SwordAltarController.Close()
			else
				SwordAltarController.Open()
			end
		end
	end)

	print("[SwordAltarController] Wired to Draw1Button, Draw10Button & Live Server Pity Sync.")
end

return SwordAltarController