--!strict
--[[
    TeaHouseController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/TeaHouseController.luau
    Client UI controller for StarterGui.TeaHouseGui.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local TeaHouseController = {}
local teaRemote: RemoteEvent

local gui: ScreenGui
local backdrop: Frame
local window: Frame
local closeBtn: TextButton
local brewBtn: TextButton
local selectedIndex = 1

local TEA_PREVIEWS = {
	[1] = { Title = "JADE DEW SPIRIT TEA", Duration = "BUFF DURATION: 10 MINUTES", Cost = 100, B1 = "• Instant Qi Replenishment: +250 Spirit Qi", B2 = "• Meditation Cultivation Speed: +10% Boost", B3 = "• Qi Condensation Rate: +2.0x in Sakura Zone", Lore = "Brewed from fresh morning dew harvested atop high mountain pines. Cleanses meridians." },
	[2] = { Title = "CRIMSON GINSENG BREW", Duration = "BUFF DURATION: 10 MINUTES", Cost = 150, B1 = "• Instant Health Recovery: +500 HP", B2 = "• Natural Health Regeneration: +15% Boost", B3 = "• Physical Posture Resilience: +10% Stun Resistance", Lore = "Decocted from ancient volcanic ginseng roots. Stirs raging vitality in the mortal blood." },
	[3] = { Title = "DRAGON WELL SWORD TEA", Duration = "BUFF DURATION: 15 MINUTES", Cost = 250, B1 = "• Sword Intent Accumulation: +15% Faster Rate", B2 = "• Critical Strike Damage Multiplier: +10%", B3 = "• Flying Sword Flight Speed: +15 Studs/Sec", Lore = "Infused with sharp sword intent. Sharpens the disciple's focus during lethal sword duels." },
}

function TeaHouseController.Init()
	teaRemote = RemoteEvents.GetRemote("TeaHouseAction")

	gui = playerGui:WaitForChild("TeaHouseGui") :: ScreenGui
	backdrop = gui:WaitForChild("ModalBackdrop") :: Frame
	window = backdrop:WaitForChild("TeaWindow") :: Frame

	closeBtn = window:WaitForChild("CloseButton") :: TextButton
	brewBtn = window:WaitForChild("BrewButton") :: TextButton

	local leftPanel = window:WaitForChild("TeaMenuPanel") :: Frame
	local rightPanel = window:WaitForChild("TeaDetailsPanel") :: Frame

	local selTitle = rightPanel:WaitForChild("SelectedTitle") :: TextLabel
	local durationBadge = rightPanel:WaitForChild("DurationBadge") :: TextLabel
	local b1 = rightPanel:WaitForChild("Benefit1") :: TextLabel
	local b2 = rightPanel:WaitForChild("Benefit2") :: TextLabel
	local b3 = rightPanel:WaitForChild("Benefit3") :: TextLabel
	local loreDesc = rightPanel:WaitForChild("LoreDescription") :: TextLabel

	backdrop.Visible = false

	local function SelectTea(idx: number)
		selectedIndex = idx
		local data = TEA_PREVIEWS[idx]
		if not data then return end

		selTitle.Text = data.Title
		durationBadge.Text = data.Duration
		b1.Text = data.B1
		b2.Text = data.B2
		b3.Text = data.B3
		loreDesc.Text = data.Lore
		brewBtn.Text = string.format("BREW & DRINK TEA (%d SPIRIT STONES)", data.Cost)
	end

	-- Hook Left Panel Selection Cards
	for i = 1, 3 do
		local card = leftPanel:FindFirstChild("TeaCard_" .. i)
		if card and card:IsA("TextButton") then
			card.Activated:Connect(function()
				SelectTea(i)
			end)
		end
	end

	closeBtn.Activated:Connect(function()
		backdrop.Visible = false
	end)

	brewBtn.Activated:Connect(function()
		teaRemote:FireServer({ Action = "BrewAndDrink", TeaIndex = selectedIndex })
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt, who)
		if who ~= localPlayer then return end
		local act = prompt.ActionText:lower()
		if act == "order spirit tea" or (prompt.Parent and prompt.Parent.Name == "Sect_NPC_XiaoLing") then
			backdrop.Visible = true
			SelectTea(1)
			teaRemote:FireServer({ Action = "RequestSync" })
		end
	end)

	teaRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" then return end
		if payload.Action == "OpenTeaHouse" then
			backdrop.Visible = true
			SelectTea(1)
		elseif payload.Action == "Result" then
			print("[Tea House]:", payload.Message)
		end
	end)

	print("[ASCEND] TeaHouseController Initialized.")
end

return TeaHouseController