local lighting = game.Lighting
local button = script.Parent

button.MouseButton1Click:Connect(function()
	if lighting.ClockTime == 10 then
		lighting.ClockTime = 19
		button.Text = "Day" 
		
		
	else
		
		
		lighting.ClockTime = 10
		button.Text = "Night" 
	end
end)