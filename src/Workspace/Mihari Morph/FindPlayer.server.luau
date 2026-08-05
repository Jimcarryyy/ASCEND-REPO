local character = script.Parent
local hum = character:WaitForChild("Humanoid")

local damage = 90 -- How much damage the killer will do.
local Range = 999999999999999999999999999999999999999999 -- How far the killer can see the character.
local killDistance = 8 --  How close the character has to be to kill.

local function findPlayer()
	local players = game.Players:GetPlayers()
	
	for i, player in pairs(players) do
		if player.Character then
			if player.Character:FindFirstChild("Humanoid").Health > 0 then
				local target = player.Character
				local distance = (character.HumanoidRootPart.Position - target.HumanoidRootPart.Position).Magnitude
				
				if distance < Range then
					hum:MoveTo(target.HumanoidRootPart.Position)
				end
				
				if distance < killDistance then
					if target.Humanoid then
						target.Humanoid:TakeDamage(damage)
					end
				end
				
				
			end
			
		end
	end
	
end

while wait() do
	findPlayer()
end