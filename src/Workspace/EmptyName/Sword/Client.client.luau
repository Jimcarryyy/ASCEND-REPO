local Tool = script.Parent
local player = game.Players.LocalPlayer
local mouse = player:GetMouse()

Tool.Equipped:Connect(function()
	task.wait()
	mouse.Icon = "rbxasset://textures/PivotEditor/PivotEditor.png"
end)

Tool.Unequipped:Connect(function()
	mouse.Icon = ""
end)