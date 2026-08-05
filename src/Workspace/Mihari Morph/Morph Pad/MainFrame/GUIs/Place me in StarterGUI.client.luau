local Player = game.Players.LocalPlayer
	local Character = workspace:WaitForChild(Player.Name)
		local Humanoid = Character:WaitForChild('Humanoid')
		
local RunAnimation = Instance.new('Animation')
RunAnimation.AnimationId = 'rbxassetid://10502553747'
RAnimation = Humanoid:LoadAnimation(RunAnimation)

Running = false

function Handler(BindName, InputState)
	if InputState == Enum.UserInputState.Begin and BindName == 'RunBind' then
		Running = true
		Humanoid.WalkSpeed = 45
	elseif InputState == Enum.UserInputState.End and BindName == 'RunBind' then
		Running = false
		if RAnimation.IsPlaying then
			RAnimation:Stop()
		end
		Humanoid.WalkSpeed = 16
	end
end

Humanoid.Running:connect(function(Speed)
	if Speed >= 10 and Running and not RAnimation.IsPlaying then
		RAnimation:Play()
		Humanoid.WalkSpeed = 45
	elseif Speed >= 10 and not Running and RAnimation.IsPlaying then
		RAnimation:Stop()
		Humanoid.WalkSpeed = 16
	elseif Speed < 10 and RAnimation.IsPlaying then
		RAnimation:Stop()
		Humanoid.WalkSpeed = 16
	end
end)

Humanoid.Changed:connect(function()
	if Humanoid.Jump and RAnimation.IsPlaying then
		RAnimation:Stop()
	end
end)

game:GetService('ContextActionService'):BindAction('RunBind', Handler, true, Enum.KeyCode.LeftShift)