local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Remote = Tool:WaitForChild("Remote")

local Mouse = nil

Tool.Equipped:Connect(function(m)
	Mouse = m
end)

Tool.Unequipped:Connect(function()
	Mouse = nil
end)

Tool.Activated:Connect(function()
	Remote:FireServer(Mouse.Target)
end)