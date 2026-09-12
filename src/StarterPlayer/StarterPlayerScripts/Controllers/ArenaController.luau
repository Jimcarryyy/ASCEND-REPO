--!strict
--[[
    ArenaController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/ArenaController.luau
    Directly bound to StarterGui Arena interfaces:
      - Safe fallback resolution (ArenaGUI / ArenaRegistrationGui / SparringGuidanceGui)
      - Crash-proof modal toggling (Zero nil crashes if GUI is absent)
      - Teleports to Arena Lobby or displays guidance toast
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

-- UI References
local arenaGui: ScreenGui?
local overlayBackdrop: Frame?
local mainFrame: GuiObject?
local headerFrame: Frame?
local closeButton: GuiButton?
local descriptionFrame: Frame?
local descriptionLabel: TextLabel?
local buttonFrame: Frame?
local teleportButton: GuiButton?
local teleportTextLabel: TextLabel?

local countdownToast: TextLabel?
local isOpen: boolean = false

local function EmitToast(msg: string)
	local controllers = player.PlayerScripts:FindFirstChild("Controllers")
	if controllers then
		local hudCtrl = controllers:FindFirstChild("HUDController")
		if hudCtrl then
			local req = require(hudCtrl) :: any
			if req and req.ShowToast then
				req.ShowToast(msg)
			end
		end
	end
end

local function IsPositionInsideGui(guiObject: GuiObject, x: number, y: number): boolean
	local pos = guiObject.AbsolutePosition
	local size = guiObject.AbsoluteSize
	return x >= pos.X and x <= (pos.X + size.X) and y >= pos.Y and y <= (pos.Y + size.Y)
end

function ArenaController.Init()
	arenaRemote = RemoteEvents.GetRemote("ArenaAction")

	-- Safe Multi-Gui Resolver
	arenaGui = playerGui:FindFirstChild("ArenaGUI") :: ScreenGui?
		or playerGui:FindFirstChild("ArenaRegistrationGui") :: ScreenGui?
		or playerGui:FindFirstChild("SparringGuidanceGui") :: ScreenGui?

	if not arenaGui then
		task.spawn(function()
			arenaGui = (playerGui:WaitForChild("ArenaGUI", 3) or playerGui:WaitForChild("ArenaRegistrationGui", 3) or playerGui:WaitForChild("SparringGuidanceGui", 3)) :: ScreenGui?
			if arenaGui then
				ArenaController.BindGui(arenaGui)
			end
		end)
	else
		ArenaController.BindGui(arenaGui)
	end

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

	print("[ASCEND] ArenaController Initialized (Crash-Proof Gateway Active).")
end

function ArenaController.BindGui(gui: ScreenGui)
	arenaGui = gui
	arenaGui.DisplayOrder = 10
	arenaGui.Enabled = false

	overlayBackdrop = arenaGui:FindFirstChild("OverlayBackdrop", true) :: Frame?
	mainFrame = arenaGui:FindFirstChild("MainFrame", true) :: GuiObject?
	if mainFrame then mainFrame.Active = true end

	-- 1. Header & Close Button
	headerFrame = mainFrame and mainFrame:FindFirstChild("HeaderFrame", true) :: Frame?
	closeButton = if headerFrame then (headerFrame:FindFirstChild("CloseImageButton") or headerFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton? else nil

	-- 2. Button Frame & Teleport Button
	buttonFrame = mainFrame and mainFrame:FindFirstChild("ButtonFrame", true) :: Frame?
	teleportButton = if buttonFrame then (buttonFrame:FindFirstChild("UseImageButton") or buttonFrame:FindFirstChildWhichIsA("GuiButton")) :: GuiButton? else nil

	if closeButton then
		closeButton.MouseButton1Click:Connect(function()
			ArenaController.Close()
		end)
	end

	if overlayBackdrop and mainFrame then
		overlayBackdrop.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				local clickPos = input.Position
				if mainFrame and not IsPositionInsideGui(mainFrame, clickPos.X, clickPos.Y) then
					ArenaController.Close()
				end
			end
		end)
	end

	if teleportButton then
		teleportButton.MouseButton1Click:Connect(function()
			arenaRemote:FireServer({ Action = "TeleportToLobby" })
			ArenaController.Close()
		end)
	end
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
	if not arenaGui then
		-- Fallback Action: Warps disciple directly to the sparring arena lobby
		EmitToast("Teleporting to Sparring Arena Lobby...")
		arenaRemote:FireServer({ Action = "TeleportToLobby" })
		return
	end

	isOpen = true
	arenaGui.Enabled = true
	if mainFrame then mainFrame.Visible = true end
	if overlayBackdrop then overlayBackdrop.Visible = true end
end

function ArenaController.Close()
	isOpen = false
	if arenaGui then
		arenaGui.Enabled = false
	end
	if mainFrame then mainFrame.Visible = false end
	if overlayBackdrop then overlayBackdrop.Visible = false end
end

-- =============================================================================
-- ON-SCREEN COUNTDOWN TOAST
-- =============================================================================
function ArenaController.ShowCountdown(seconds: number)
	ArenaController.ShowCountdownMessage(string.format("⚔️ DUEL STARTING IN %d... ⚔️", seconds), Color3.fromRGB(255, 220, 50))
end

function ArenaController.ShowCountdownMessage(text: string, color: Color3)
	local container = arenaGui or playerGui:FindFirstChild("MasterHUDGui")
	if not container then return end

	if not countdownToast or not countdownToast.Parent then
		countdownToast = Instance.new("TextLabel")
		countdownToast.Name = "ArenaCountdownToast"
		countdownToast.Size = UDim2.new(0, 480, 0, 60)
		countdownToast.Position = UDim2.new(0.5, 0, 0.25, 0)
		countdownToast.AnchorPoint = Vector2.new(0.5, 0.5)
		countdownToast.BackgroundTransparency = 1
		countdownToast.Font = Enum.Font.Bangers
		countdownToast.TextSize = 28
		countdownToast.TextStrokeTransparency = 0
		countdownToast.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
		countdownToast.ZIndex = 50
		countdownToast.Parent = container
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