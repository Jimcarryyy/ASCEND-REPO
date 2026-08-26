local Tool = script.Parent
local Sounds = Tool.Handle.Sounds:GetChildren()
local active = false
local cooldown = 0.6

local function HitObject(hit: Instance, damage: number, enemyHit: Player)
	local bill = Instance.new("BillboardGui")
	bill.MaxDistance = 60
	bill.Size = UDim2.new(0, 35, 0, 35)
	bill.AlwaysOnTop = true
	bill.LightInfluence = 1
	bill.Adornee = hit
	
	local txt = Instance.new("TextLabel")
	txt.Text = damage
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.new(1, 0, 1, 0)
	txt.TextScaled = true
	txt.FontFace = Font.new(
		"rbxasset://fonts/families/FredokaOne.json", 
		Enum.FontWeight.Bold
	)
	txt.TextColor3 = Color3.fromRGB(255, 255, 255)
	txt.TextStrokeTransparency = 0
	txt.Parent = bill
	bill.Parent = workspace
	game:GetService("Debris"):AddItem(bill, 0.8)
end

Tool.Activated:Connect(function()
	if active == false then
		Sounds[math.random(1, #Sounds)]:Play()
		active = true
		
		if Tool:FindFirstChild("toolanim") then Tool.toolanim:Destroy() end
		local Anim = Instance.new("StringValue")
		Anim.Name = "toolanim"
		Anim.Value = "Slash"
		Anim.Parent = Tool
		
		task.wait(cooldown)
		active = false
	end
end)

Tool.spine.Touched:Connect(function(hit)
	local character = Tool.Parent
	
	if active == true and character:IsA("Model") then
		if hit.Parent then
			if hit.Parent:FindFirstChild("Humanoid") then
				local damage = math.random(1, 7)
				local player = game.Players:GetPlayerFromCharacter(character)
				local enemy = game.Players:GetPlayerFromCharacter(hit.Parent)
				
				if hit.Parent.Humanoid.Health > 0 then
					if enemy then
						if player.Team ~= enemy.Team then
							HitObject(hit, damage, enemy)
							hit.Parent.Humanoid.Health -= damage
						end
					else
						HitObject(hit, damage)
						hit.Parent.Humanoid.Health -= damage
					end
				end
			end
		end
	end
end)