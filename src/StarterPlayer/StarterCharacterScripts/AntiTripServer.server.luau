--!strict
-- StarterPlayer.StarterCharacterScripts.AntiTripServer (Server Script)
local character = script.Parent
local humanoid = character:WaitForChild("Humanoid") :: Humanoid

-- Server-authoritative disable of clumsy physics stumble and ragdoll
humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)

-- R6 safe step height check
pcall(function()
	if humanoid.StepHeight < 2.0 then
		humanoid.StepHeight = 2.0
	end
end)

-- R6 Heroic Body Scaling
local BODY_SCALE = 1.05       -- 15% larger than default R6
local HEAD_REDUCTION = 0.90   -- 10% smaller head for natural anime proportions

task.defer(function()
	if not character or not character.Parent then return end

	-- 1. Scale body model
	character:ScaleTo(BODY_SCALE)

	local head = character:FindFirstChild("Head") :: BasePart?
	local torso = character:FindFirstChild("Torso") :: BasePart?
	if not head or not torso then return end

	-- 2. Scale head mesh
	local headMesh = head:FindFirstChildOfClass("SpecialMesh")
	if headMesh then
		headMesh.Scale = headMesh.Scale * HEAD_REDUCTION
	end

	-- 3. Scale head accessories & hair
	for _, acc in ipairs(character:GetChildren()) do
		if acc:IsA("Accessory") then
			local handle = acc:FindFirstChild("Handle") :: BasePart?
			if handle then
				local att = handle:FindFirstChildOfClass("Attachment")
				if att and head:FindFirstChild(att.Name) then
					local mesh = handle:FindFirstChildOfClass("SpecialMesh")
					if mesh then
						mesh.Scale = mesh.Scale * HEAD_REDUCTION
					elseif handle:IsA("MeshPart") then
						handle.Size = handle.Size * HEAD_REDUCTION
					end
					att.Position = att.Position * HEAD_REDUCTION
				end
			end
		end
	end

	-- 4. Flush neck joint alignment
	local neck = torso:FindFirstChild("Neck") :: Motor6D?
	if neck then
		neck.C1 = CFrame.new(0, -0.45 * BODY_SCALE, 0, -1, 0, 0, 0, 0, 1, 0, 1, -0)
	end
end)