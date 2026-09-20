-- StarterPlayer.StarterCharacterScripts.AntiTripServer (Regular SCRIPT, runs on Server)
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
