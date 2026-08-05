local shadows = script.Parent.Shadows

shadows.MouseButton1Click:Connect(function()
	if game.Lighting.GlobalShadows == false then
		shadows.Text = 'Shadows - On'
		game.Lighting.GlobalShadows = not game.Lighting.GlobalShadows
	else
		shadows.Text = 'Shadows - Off'
		game.Lighting.GlobalShadows = not game.Lighting.GlobalShadows
	end
end)