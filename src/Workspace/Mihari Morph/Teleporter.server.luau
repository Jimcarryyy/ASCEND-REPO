local npcIsStuck = false
local stuckAmount = 0
local lastPosition
local root = script.Parent.HumanoidRootPart
local originPos = root.CFrame
spawn(function()
	while root.Parent do
		lastPosition = root.Position
		wait(1) -- check interval
		if (lastPosition - root.Position).magnitude < 1 then 
			print("not moving")
			stuckAmount += 1
			if stuckAmount == 3 then
				print("teleported")
				root.CFrame = originPos
				script.Parent.Teleport:Fire()
			end
		else
			stuckAmount = 0
			npcIsStuck = false
		end
	end
end)