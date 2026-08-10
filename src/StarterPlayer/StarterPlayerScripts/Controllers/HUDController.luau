--!strict
--[[
    HUDController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.luau
    Client HUD engine for ASCEND.
    Unified Light-Mode Aesthetic (FredokaOne Font, Emerald HP, Azure Qi, Clean Panel Styling).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)
local ItemConfig = require(ReplicatedStorage.Shared.Configs.ItemConfig)
local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local HUDController = {}
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local UI_FONT = Enum.Font.FredokaOne

-- LIGHT-MODE PALETTE (Matching Alchemy)
local COLOR_LIGHT_PANEL  = Color3.fromRGB(241, 245, 249) -- #F1F5F9
local COLOR_LIGHT_CARD   = Color3.fromRGB(255, 255, 255) -- #FFFFFF
local COLOR_LIGHT_BORDER = Color3.fromRGB(203, 213, 225) -- #CBD5E1
local COLOR_TEXT_MAIN    = Color3.fromRGB(15, 23, 42)    -- #0F172A
local COLOR_TEXT_SUB     = Color3.fromRGB(100, 116, 139)  -- #64748B
local COLOR_HP_GREEN     = Color3.fromRGB(16, 185, 129)  -- #10B981
local COLOR_AZURE_BLUE   = Color3.fromRGB(59, 130, 246)   -- #3B82F6
local COLOR_ACTION_GOLD  = Color3.fromRGB(217, 119, 6)   -- #D97706

local hudScreenGui: ScreenGui
local vitalFrame: Frame
local hpBarFill: Frame
local hpBarText: TextLabel
local qiBarFill: Frame
local qiBarText: TextLabel
local realmBadgeText: TextLabel

local hotbarFrame: Frame
local hotbarSlots: { [number]: Frame } = {}
local hotbarKeybinds = { "1", "2", "3", "4", "5", "K" }

local currentInventoryData: { [number]: any } = {}
local updateInventoryRemote: RemoteEvent

function HUDController.Init()
	updateInventoryRemote = RemoteEvents.GetRemote("UpdateInventory")

	HUDController.BuildHUD()

	updateInventoryRemote.OnClientEvent:Connect(function(inventoryData: { [number]: any })
		currentInventoryData = inventoryData or {}
		HUDController.UpdateHotbar()
	end)

	player.CharacterAdded:Connect(function(character)
		HUDController.HookCharacter(character)
	end)

	if player.Character then
		HUDController.HookCharacter(player.Character)
	end

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		local keyNum = tonumber(input.KeyCode.Name:sub(-1))
		if keyNum and keyNum >= 1 and keyNum <= 5 then
			local inventoryActionRemote = RemoteEvents.GetRemote("InventoryAction")
			inventoryActionRemote:FireServer({
				Action = "UseItem",
				SlotIndex = keyNum,
			})
		end
	end)

	print("[ASCEND] Light-Mode HUDController Initialized.")
end

function HUDController.BuildHUD()
	local oldHud = playerGui:FindFirstChild("AscendMainHUD")
	if oldHud then oldHud:Destroy() end

	hudScreenGui = Instance.new("ScreenGui")
	hudScreenGui.Name = "AscendMainHUD"
	hudScreenGui.ResetOnSpawn = false
	hudScreenGui.DisplayOrder = 10
	hudScreenGui.Parent = playerGui

	-- TOP-LEFT VITAL FRAME (Matching Alchemy Sub-Panel Style)
	vitalFrame = Instance.new("Frame")
	vitalFrame.Name = "VitalFrame"
	vitalFrame.Size = UDim2.new(0, 360, 0, 110)
	vitalFrame.Position = UDim2.new(0, 20, 0, 20)
	vitalFrame.BackgroundColor3 = COLOR_LIGHT_PANEL
	vitalFrame.BorderSizePixel = 0
	vitalFrame.Parent = hudScreenGui

	local vfStroke = Instance.new("UIStroke")
	vfStroke.Color = COLOR_LIGHT_BORDER
	vfStroke.Thickness = 1.5
	vfStroke.Parent = vitalFrame

	realmBadgeText = Instance.new("TextLabel")
	realmBadgeText.Name = "RealmBadgeText"
	realmBadgeText.Size = UDim2.new(1, -20, 0, 26)
	realmBadgeText.Position = UDim2.new(0, 10, 0, 6)
	realmBadgeText.BackgroundTransparency = 1
	realmBadgeText.Text = "Qi Condensation — Tier 1"
	realmBadgeText.TextColor3 = COLOR_TEXT_MAIN
	realmBadgeText.Font = UI_FONT
	realmBadgeText.TextSize = 18
	realmBadgeText.TextXAlignment = Enum.TextXAlignment.Left
	realmBadgeText.Parent = vitalFrame

	-- HEALTH BAR
	local hpBg = Instance.new("Frame")
	hpBg.Size = UDim2.new(1, -60, 0, 24)
	hpBg.Position = UDim2.new(0, 48, 0, 38)
	hpBg.BackgroundColor3 = COLOR_LIGHT_CARD
	hpBg.BorderSizePixel = 0
	hpBg.Parent = vitalFrame

	local hpStroke = Instance.new("UIStroke")
	hpStroke.Color = COLOR_LIGHT_BORDER
	hpStroke.Thickness = 1
	hpStroke.Parent = hpBg

	hpBarFill = Instance.new("Frame")
	hpBarFill.Size = UDim2.new(1, 0, 1, 0)
	hpBarFill.BackgroundColor3 = COLOR_HP_GREEN
	hpBarFill.BorderSizePixel = 0
	hpBarFill.Parent = hpBg

	hpBarText = Instance.new("TextLabel")
	hpBarText.Size = UDim2.new(1, 0, 1, 0)
	hpBarText.BackgroundTransparency = 1
	hpBarText.Text = "100 / 100"
	hpBarText.TextColor3 = COLOR_TEXT_MAIN
	hpBarText.Font = UI_FONT
	hpBarText.TextSize = 13
	hpBarText.ZIndex = 5
	hpBarText.Parent = hpBg

	local hpLbl = Instance.new("TextLabel")
	hpLbl.Size = UDim2.new(0, 36, 0, 24)
	hpLbl.Position = UDim2.new(0, -40, 0, 0)
	hpLbl.BackgroundTransparency = 1
	hpLbl.Text = "HP"
	hpLbl.TextColor3 = COLOR_TEXT_SUB
	hpLbl.Font = UI_FONT
	hpLbl.TextSize = 13
	hpLbl.TextXAlignment = Enum.TextXAlignment.Right
	hpLbl.Parent = hpBg

	-- CLAMPED QI BAR
	local qiBg = Instance.new("Frame")
	qiBg.Size = UDim2.new(1, -60, 0, 24)
	qiBg.Position = UDim2.new(0, 48, 0, 68)
	qiBg.BackgroundColor3 = COLOR_LIGHT_CARD
	qiBg.BorderSizePixel = 0
	qiBg.Parent = vitalFrame

	local qiStroke = Instance.new("UIStroke")
	qiStroke.Color = COLOR_LIGHT_BORDER
	qiStroke.Thickness = 1
	qiStroke.Parent = qiBg

	qiBarFill = Instance.new("Frame")
	qiBarFill.Size = UDim2.new(1, 0, 1, 0)
	qiBarFill.BackgroundColor3 = COLOR_AZURE_BLUE
	qiBarFill.BorderSizePixel = 0
	qiBarFill.Parent = qiBg

	qiBarText = Instance.new("TextLabel")
	qiBarText.Size = UDim2.new(1, 0, 1, 0)
	qiBarText.BackgroundTransparency = 1
	qiBarText.Text = "800 / 800"
	qiBarText.TextColor3 = COLOR_TEXT_MAIN
	qiBarText.Font = UI_FONT
	qiBarText.TextSize = 13
	qiBarText.ZIndex = 5
	qiBarText.Parent = qiBg

	local qiLbl = Instance.new("TextLabel")
	qiLbl.Size = UDim2.new(0, 36, 0, 24)
	qiLbl.Position = UDim2.new(0, -40, 0, 0)
	qiLbl.BackgroundTransparency = 1
	qiLbl.Text = "QI"
	qiLbl.TextColor3 = COLOR_TEXT_SUB
	qiLbl.Font = UI_FONT
	qiLbl.TextSize = 13
	qiLbl.TextXAlignment = Enum.TextXAlignment.Right
	qiLbl.Parent = qiBg

	-- BOTTOM CENTER KEYBIND BADGE HOTBAR
	hotbarFrame = Instance.new("Frame")
	hotbarFrame.Name = "HotbarFrame"
	hotbarFrame.Size = UDim2.new(0, 430, 0, 66)
	hotbarFrame.Position = UDim2.new(0.5, -215, 1, -85)
	hotbarFrame.BackgroundColor3 = COLOR_LIGHT_PANEL
	hotbarFrame.BorderSizePixel = 0
	hotbarFrame.Parent = hudScreenGui

	local hbStroke = Instance.new("UIStroke")
	hbStroke.Color = COLOR_LIGHT_BORDER
	hbStroke.Thickness = 1.5
	hbStroke.Parent = hotbarFrame

	local hbLayout = Instance.new("UIListLayout")
	hbLayout.FillDirection = Enum.FillDirection.Horizontal
	hbLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hbLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hbLayout.Padding = UDim.new(0, 10)
	hbLayout.Parent = hotbarFrame

	for i = 1, 6 do
		local slot = Instance.new("Frame")
		slot.Name = "HotbarSlot_" .. i
		slot.Size = UDim2.new(0, 56, 0, 52)
		slot.BackgroundColor3 = COLOR_LIGHT_CARD
		slot.BorderSizePixel = 0
		slot.Parent = hotbarFrame

		local sStroke = Instance.new("UIStroke")
		sStroke.Color = COLOR_LIGHT_BORDER
		sStroke.Thickness = 1.5
		sStroke.Parent = slot

		-- Keybind Indicator Badge
		local badge = Instance.new("TextLabel")
		badge.Name = "KeybindBadge"
		badge.Size = UDim2.new(0, 20, 0, 18)
		badge.Position = UDim2.new(0, 2, 0, 2)
		badge.BackgroundColor3 = COLOR_TEXT_MAIN
		badge.Text = hotbarKeybinds[i] or tostring(i)
		badge.TextColor3 = COLOR_LIGHT_CARD
		badge.Font = UI_FONT
		badge.TextSize = 12
		badge.ZIndex = 10
		badge.Parent = slot

		local bCorner = Instance.new("UICorner")
		bCorner.CornerRadius = UDim.new(0, 4)
		bCorner.Parent = badge

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.Size = UDim2.new(1, -12, 1, -12)
		icon.Position = UDim2.new(0, 6, 0, 6)
		icon.BackgroundTransparency = 1
		icon.ScaleType = Enum.ScaleType.Fit
		icon.Visible = false
		icon.Parent = slot

		local countLbl = Instance.new("TextLabel")
		countLbl.Name = "CountLabel"
		countLbl.Size = UDim2.new(1, -4, 0, 14)
		countLbl.Position = UDim2.new(0, 0, 1, -14)
		countLbl.BackgroundTransparency = 1
		countLbl.TextColor3 = COLOR_TEXT_SUB
		countLbl.Font = UI_FONT
		countLbl.TextSize = 11
		countLbl.TextXAlignment = Enum.TextXAlignment.Right
		countLbl.Text = ""
		countLbl.Parent = slot

		hotbarSlots[i] = slot
	end
end

function HUDController.HookCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local function updateHP()
		local hp = humanoid.Health
		local maxHp = math.max(1, humanoid.MaxHealth)
		local ratio = math.clamp(hp / maxHp, 0, 1)
		hpBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		hpBarText.Text = string.format("%d / %d", math.floor(hp), math.floor(maxHp))
	end

	local function updateQi()
		local rawQi = character:GetAttribute("Qi") or 800
		local rawMaxQi = character:GetAttribute("MaxQi") or 800

		local clampedQi = math.clamp(rawQi, 0, 800)
		local clampedMaxQi = math.clamp(rawMaxQi, 1, 800)
		local ratio = math.clamp(clampedQi / clampedMaxQi, 0, 1)

		qiBarFill.Size = UDim2.new(ratio, 0, 1, 0)
		qiBarText.Text = string.format("%d / %d", math.floor(clampedQi), clampedMaxQi)
	end

	humanoid.HealthChanged:Connect(updateHP)
	character:GetAttributeChangedSignal("Qi"):Connect(updateQi)
	character:GetAttributeChangedSignal("MaxQi"):Connect(updateQi)

	updateHP()
	updateQi()
end

function HUDController.UpdateHotbar()
	for i = 1, 5 do
		local slotFrame = hotbarSlots[i]
		if not slotFrame then continue end

		local icon = slotFrame:FindFirstChild("Icon") :: ImageLabel?
		local countLbl = slotFrame:FindFirstChild("CountLabel") :: TextLabel?

		local slotData = currentInventoryData[i]
		if slotData then
			local itemDef = ItemConfig.GetItem(slotData.ItemId)
			if itemDef then
				if icon then icon.Visible = true end
				if countLbl then countLbl.Text = if slotData.Count > 1 then "x" .. slotData.Count else "" end
			end
		else
			if icon then icon.Visible = false end
			if countLbl then countLbl.Text = "" end
		end
	end

	local slot6 = hotbarSlots[6]
	if slot6 then
		local countLbl = slot6:FindFirstChild("CountLabel") :: TextLabel?
		if countLbl then countLbl.Text = "POUCH" end
	end
end

return HUDController