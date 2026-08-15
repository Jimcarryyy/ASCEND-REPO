--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Only applies to your account name
if player.Name == "Han_jueee" or player.UserId > 0 then
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		local widthScale = humanoid:FindFirstChild("BodyWidthScale") :: NumberValue?
		if not widthScale then
			widthScale = Instance.new("NumberValue")
			widthScale.Name = "BodyWidthScale"
			widthScale.Parent = humanoid
		end
		widthScale.Value = 1.2 -- 20% Wider Torso/Shoulders for developer
	end)

	if player.Character then
		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local widthScale = humanoid:FindFirstChild("BodyWidthScale") :: NumberValue?
			if not widthScale then
				widthScale = Instance.new("NumberValue")
				widthScale.Name = "BodyWidthScale"
				widthScale.Parent = humanoid
			end
			widthScale.Value = 1.2
		end
	end
end