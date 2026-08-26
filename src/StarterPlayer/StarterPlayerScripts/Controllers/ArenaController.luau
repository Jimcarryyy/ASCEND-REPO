--!strict
--[[
    ArenaController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/ArenaController.luau
    Directly bound to StarterGui.ArenaGUI:
    - Replaces all hardcoded UI with your custom Studio ArenaGUI
    - TELEPORT button warps disciple to the Arena Lobby Grounds
    - Listens for Dual-Pad match countdowns and live duel HUDs
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)

local ArenaController = {}
ArenaController.__index = ArenaController

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

local arenaRemote: RemoteEvent

-- UI References (Bound directly to your ArenaGUI)
local arenaGui: ScreenGui
local overlayBackdrop: Frame
local mainFrame: GuiObject
local headerFrame: Frame
local closeButton: GuiButton
local descriptionFrame: Frame
local descriptionLabel: TextLabel
local buttonFrame: Frame
local teleportButton: GuiButton
local teleportTextLabel: TextLabel?

local countdownToast: TextLabel?
local isOpen: boolean = false

local function IsPositionInsideGui(guiObject: GuiObject, x: number, y: number): boolean
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return x >= pos.X and x <= (pos.X + size.X) and y >= pos.Y and y <= (pos.Y + size.Y)
end

function ArenaController.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	arenaGui = (playerGui:WaitForChild("ArenaGUI", 10) or playerGui:WaitForChild("ArenaRegistrationGui", 10)) :: ScreenGui
	if not arenaGui then
		warn("[ArenaController] ArenaGUI not found in PlayerGui!")
		return
	end

	arenaGui.DisplayOrder = 10
	arenaGui.Enabled = false

	overlayBackdrop = arenaGui:WaitForChild("OverlayBackdrop", 5) :: Frame
	mainFrame = arenaGui:WaitForChild("MainFrame", 5) :: GuiObject
	mainFrame.Active = true

	-- 1. Header & Close Button
	headerFrame = mainFrame:WaitForChild("HeaderFrame", 5) :: Frame
	closeButton = (headerFrame:FindFirstChild("CloseImageButton") or headerFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton

	-- 2. Description Frame
	descriptionFrame = mainFrame:WaitForChild("DescriptionFrame", 5) :: Frame
	descriptionLabel = descriptionFrame:WaitForChild("DescriptionLabel", 5) :: TextLabel

	-- 3. Button Frame & Teleport Button
	buttonFrame = mainFrame:WaitForChild("ButtonFrame", 5) :: Frame
	teleportButton = (buttonFrame:FindFirstChild("UseImageButton") or buttonFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton
	teleportTextLabel = teleportButton:FindFirstChild("UseTextLabel") or teleportButton:FindFirstChildOfClass("TextLabel")

	-- Bind Button Events
	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			ArenaController.Close()
		end)
	end

	if overlayBackdrop then
		overlayBackdrop.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local clickPos = input.Position
				if not IsPositionInsideGui(mainFrame, clickPos.X, clickPos.Y) then
					ArenaController.Close()
				end
			end
		end)
	end

	-- Teleport Button Click
	teleportButton.MouseButton1Click:Connect(function()
		arenaRemote:FireServer({ Action = "TeleportToLobby" })
		ArenaController.Close()
	end)

	-- Listen for Server Arena Events
	arenaRemote.OnClientEvent:Connect(function(payload: any)
		if type(payload) ~= "table" or not payload.Action then return end

		if payload.Action == "OpenArenaMenu" then
			ArenaController.Open()
		elseif payload.Action == "CountdownTick" then
			ArenaController.ShowCountdown(payload.Seconds)
		elseif payload.Action == "CountdownCancelled" then
			ArenaController.ShowCountdownMessage("Match Cancelled — Challenger Stepped Off Pad", Color3.fromRGB(255, 100, 100))
		elseif payload.Action == "DuelStarting" then
			ArenaController.ShowCountdownMessage("⚔️ DUEL COMMENCED! ⚔️", Color3.fromRGB(255, 215, 0))
		elseif payload.Action == "DuelEnded" then
			local resultText = if payload.IsWinner then "🏆 VICTORY!" else (if payload.IsDraw then "🤝 DRAW!" else "DEFEAT (Concession)")
			local resultCol = if payload.IsWinner then Color3.fromRGB(50, 220, 100) else (if payload.IsDraw then Color3.fromRGB(100, 200, 255) else Color3.fromRGB(255, 80, 80))
			ArenaController.ShowCountdownMessage(resultText .. "\n" .. (payload.Reason or ""), resultCol)
		end
	end)

	print("[ASCEND] ArenaController Initialized (Studio ArenaGUI Connected).")
end

function ArenaController.OpenRegistrationModal()
	ArenaController.Open()
end

function ArenaController.ToggleModal()
	if isOpen then
		ArenaController.Close()
	else
		ArenaController.Open()
	end
end

function ArenaController.Open()
	isOpen = true
	arenaGui.Enabled = true
	mainFrame.Visible = true
	if overlayBackdrop then overlayBackdrop.Visible = true end
end

function ArenaController.Close()
	isOpen = false
	arenaGui.Enabled = false
	mainFrame.Visible = false
	if overlayBackdrop then overlayBackdrop.Visible = false end
end

-- =============================================================================
-- ON-SCREEN COUNTDOWN TOAST
-- =============================================================================
function ArenaController.ShowCountdown(seconds: number)
	ArenaController.ShowCountdownMessage(string.format("⚔️ DUEL STARTING IN %d... ⚔️", seconds), Color3.fromRGB(255, 220, 50))
end

function ArenaController.ShowCountdownMessage(text: string, color: Color3)
	if not countdownToast or not countdownToast.Parent then
		countdownToast = Instance.new("TextLabel")
		countdownToast.Name = "ArenaCountdownToast"
		countdownToast.Size = UDim2.new(0, 480, 0, 60)
		countdownToast.Position = UDim2.new(0.5, 0, 0.25, 0)
		countdownToast.AnchorPoint = Vector2.new(0.5, 0.5)
		countdownToast.BackgroundTransparency = 1
		countdownToast.Font = Enum.Font.LuckiestGuy
		countdownToast.TextSize = 28
		countdownToast.TextStrokeTransparency = 0
		countdownToast.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
		countdownToast.ZIndex = 50
		countdownToast.Parent = arenaGui
	end

	countdownToast.Text = text
	countdownToast.TextColor3 = color
	countdownToast.Visible = true

	local bounceTween = TweenService:Create(countdownToast, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 32,
	})
	bounceTween:Play()

	task.delay(1.5, function()
		if countdownToast and countdownToast.Text == text then
			countdownToast.Visible = false
			countdownToast.TextSize = 28
		end
	end)
end

return ArenaController