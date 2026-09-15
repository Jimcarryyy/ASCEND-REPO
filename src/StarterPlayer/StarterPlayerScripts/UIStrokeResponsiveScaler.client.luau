--!strict
--[[
    UIStrokeResponsiveScaler.client.luau
    Location: StarterPlayer/StarterPlayerScripts/UIStrokeResponsiveScaler.client.luau
    Authoritative responsive stroke scaler for ASCEND.
    Strictly modifies UIStroke.Thickness only based on device viewport height.
]]

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui
local camera = Workspace.CurrentCamera

local BASE_REFERENCE_HEIGHT = 1080 -- Standard 1080p desktop base
local MIN_SCALE_RATIO = 0.65       -- Lowest scale for small phones
local MIN_THICKNESS_FLOOR = 0.60   -- Prevents strokes from completely vanishing

local trackedStrokes: { [UIStroke]: number } = {}

local function RegisterStroke(stroke: UIStroke)
	local base = stroke:GetAttribute("BaseThickness")
	if type(base) ~= "number" then
		base = stroke.Thickness
		stroke:SetAttribute("BaseThickness", base)
	end
	trackedStrokes[stroke] = base
end

local function UpdateAllStrokes()
	if not camera then return end
	local screenHeight = camera.ViewportSize.Y
	if screenHeight <= 0 then return end

	-- Calculate proportional device scale
	local scaleFactor = math.clamp(screenHeight / BASE_REFERENCE_HEIGHT, MIN_SCALE_RATIO, 1.0)

	for stroke, baseThickness in pairs(trackedStrokes) do
		if stroke.Parent ~= nil then
			local newThickness = math.max(MIN_THICKNESS_FLOOR, math.round(baseThickness * scaleFactor * 10) / 10)
			stroke.Thickness = newThickness
		else
			trackedStrokes[stroke] = nil
		end
	end
end

-- 1. Index all current strokes in PlayerGui
for _, desc in ipairs(playerGui:GetDescendants()) do
	if desc:IsA("UIStroke") then
		RegisterStroke(desc)
	end
end

-- 2. Watch for dynamically cloned UI (Inventory slots, toasts, damage numbers)
playerGui.DescendantAdded:Connect(function(desc)
	if desc:IsA("UIStroke") then
		RegisterStroke(desc)
		if camera then
			local scaleFactor = math.clamp(camera.ViewportSize.Y / BASE_REFERENCE_HEIGHT, MIN_SCALE_RATIO, 1.0)
			local base = trackedStrokes[desc] or desc.Thickness
			desc.Thickness = math.max(MIN_THICKNESS_FLOOR, math.round(base * scaleFactor * 10) / 10)
		end
	end
end)

-- 3. Update whenever device orientation or viewport resolution changes
if camera then
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateAllStrokes)
	task.spawn(UpdateAllStrokes)
end

print("[ASCEND] UIStrokeResponsiveScaler Active (Borders scale proportionally on mobile).")
