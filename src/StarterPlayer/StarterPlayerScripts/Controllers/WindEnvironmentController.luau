--!strict
--[[
    WindEnvironmentController.luau
    Location: src/StarterPlayer/StarterPlayerScripts/Controllers/WindEnvironmentController.luau
    Client environmental controller for ASCEND.
    Applies stylized, organic gusting wind sway (REST -> GUST -> SWAY -> SETTLE)
    to nearby trees, flexible bamboo, and foliage using spatial distance culling.
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local WindEnvironmentController = {}

local MAX_CULL_DISTANCE = 160 -- Animates plants within 160 studs of camera

export type PlantType = "LargeTree" | "SmallTree" | "Bamboo" | "Grass"

type AnimatedFoliageData = {
	Part: BasePart,
	OriginalCFrame: CFrame,
	PhaseOffset: number,
	PlantCategory: PlantType,
}

local foliageList: { AnimatedFoliageData } = {}
local camera = Workspace.CurrentCamera

local FOLIAGE_PATTERNS = {
	"leaf", "leaves", "canopy", "foliage", "crown", "pineleaves", "top", "bamboo", "grass", "bush"
}

local function CategorizePlant(instance: Instance, partName: string): PlantType
	local nameLower = partName:lower()
	local modelName = (if instance.Parent then instance.Parent.Name else ""):lower()

	if nameLower:find("bamboo") or modelName:find("bamboo") then
		return "Bamboo"
	elseif nameLower:find("grass") or modelName:find("grass") then
		return "Grass"
	elseif nameLower:find("pine") or modelName:find("pine") or nameLower:find("large") then
		return "LargeTree"
	else
		return "SmallTree"
	end
end

function WindEnvironmentController.ScanEnvironment()
	table.clear(foliageList)

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local partName = descendant.Name:lower()
			local isPlant = false
			
			for _, pattern in ipairs(FOLIAGE_PATTERNS) do
				if partName:find(pattern) then
					isPlant = true
					break
				end
			end

			if isPlant then
				local pos = descendant.Position
				local phase = (pos.X * 0.08) + (pos.Z * 0.08)
				local category = CategorizePlant(descendant, partName)

				table.insert(foliageList, {
					Part = descendant,
					OriginalCFrame = descendant.CFrame,
					PhaseOffset = phase,
					PlantCategory = category,
				})
			end
		end
	end
end

-- Add this helper function inside WindEnvironmentController.luau

local function SetupWindLines(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if not root then return end

	-- Clean up previous emitter if respawned
	local existing = root:FindFirstChild("MurimWindEmitter")
	if existing then existing:Destroy() end

	local attachment = Instance.new("Attachment")
	attachment.Name = "MurimWindEmitter"
	attachment.Position = Vector3.new(0, 4, 0)
	attachment.Parent = root

	local particles = Instance.new("ParticleEmitter")
	particles.Name = "WindRibbons"
	particles.Texture = "rbxassetid://6454399793" -- Soft streak line texture
	particles.Orientation = Enum.ParticleOrientation.VelocityParallel
	particles.Rate = 6
	particles.Lifetime = NumberRange.new(1.8, 2.8)
	particles.Speed = NumberRange.new(18, 32)
	particles.SpreadAngle = Vector2.new(15, 10)
	particles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.3, 0.45),
		NumberSequenceKeypoint.new(0.8, 0.3),
		NumberSequenceKeypoint.new(1, 0),
	})
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.65),
		NumberSequenceKeypoint.new(0.7, 0.75),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Color = ColorSequence.new(Color3.fromRGB(225, 235, 245))
	particles.LightEmission = 0.4
	particles.EmissionDirection = Enum.NormalId.Back
	particles.Parent = attachment

	-- Sync particle velocity with GlobalWind every frame
	task.spawn(function()
		while attachment and attachment.Parent do
			local currentWind = workspace.GlobalWind
			if currentWind.Magnitude > 1 then
				particles.EmissionDirection = Enum.NormalId.Front
				attachment.CFrame = CFrame.lookAt(Vector3.zero, currentWind.Unit)
				particles.Speed = NumberRange.new(currentWind.Magnitude * 0.8, currentWind.Magnitude * 1.3)
				particles.Rate = math.clamp(currentWind.Magnitude * 0.5, 4, 18)
			else
				particles.Rate = 2
			end
			task.wait(0.2)
		end
	end)
end

function WindEnvironmentController.Init()
	WindEnvironmentController.ScanEnvironment()

	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.wait(0.2)
			local partName = descendant.Name:lower()
			for _, pattern in ipairs(FOLIAGE_PATTERNS) do
				if partName:find(pattern) then
					local pos = descendant.Position
					local phase = (pos.X * 0.08) + (pos.Z * 0.08)
					local category = CategorizePlant(descendant, partName)

					table.insert(foliageList, {
						Part = descendant,
						OriginalCFrame = descendant.CFrame,
						PhaseOffset = phase,
						PlantCategory = category,
					})
					break
				end
			end
		end
	end)

	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	local function OnCharacterAdded(char)
		SetupWindLines(char)
	end

	if localPlayer.Character then
		OnCharacterAdded(localPlayer.Character)
	end
	localPlayer.CharacterAdded:Connect(OnCharacterAdded)

	-- Single Centralized Render Loop for Organic Gusting Wind
	local clock = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		clock += deltaTime * 1.8
		local camPos = camera.CFrame.Position

		-- Organic Gust Envelope (REST -> GUST -> SWAY -> SETTLE -> GUST)
		local noiseValue = math.noise(clock * 0.25, 0, 0)
		local gustEnvelope = math.clamp(noiseValue * 2.2 + math.sin(clock * 0.8) * 0.4, 0.1, 1.8)

		for _, data in ipairs(foliageList) do
			local part = data.Part
			if part and part.Parent then
				local dist = (part.Position - camPos).Magnitude
				if dist <= MAX_CULL_DISTANCE then
					local phase = clock + data.PhaseOffset
					local category = data.PlantCategory

					local maxSwayAngle = 0.065
					local frequencyMult = 1.0

					if category == "Bamboo" then
						-- Bamboo bends and flexes dramatically with wind gusts
						maxSwayAngle = 0.140 -- ~8 degrees sway
						frequencyMult = 2.2
					elseif category == "Grass" then
						maxSwayAngle = 0.110
						frequencyMult = 3.2
					elseif category == "SmallTree" then
						maxSwayAngle = 0.095 -- ~5.5 degrees sway
						frequencyMult = 1.5
					else
						-- Large Trees (heavy slow crown sway)
						maxSwayAngle = 0.065 -- ~3.7 degrees sway
						frequencyMult = 1.0
					end

					-- Calculate Sway Rotation
					local wave = math.sin(phase * frequencyMult) * gustEnvelope
					local sway = wave * maxSwayAngle
					local swayRotation = CFrame.Angles(sway, 0, sway * 0.4)

					part.CFrame = data.OriginalCFrame * swayRotation
				end
			end
		end
	end)

	print("[ASCEND] WindEnvironmentController Initialized (Organic Gusting Wind & Bamboo Flexibility Enabled).")
end

return WindEnvironmentController