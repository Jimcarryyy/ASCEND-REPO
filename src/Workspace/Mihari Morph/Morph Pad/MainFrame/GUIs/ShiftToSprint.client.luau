local UIS = game:GetService('UserInputService')
local Player = game.Players.LocalPlayer
local Character = Player.Character


UIS.InputBegan:connect(function(input)--When a player has pressed LeftShift it will play the animation and it will set the normal walking speed (16) to 35.
 if input.KeyCode == Enum.KeyCode.LeftShift then
  Character.Humanoid.WalkSpeed = 45
  local Anim = Instance.new('Animation')
		Anim.AnimationId = 'rbxassetid://10502553747'
  PlayAnim = Character.Humanoid:LoadAnimation(Anim)
  PlayAnim:Play()
 end
end)


UIS.InputEnded:connect(function(input)
 if input.KeyCode == Enum.KeyCode.LeftShift then
  Character.Humanoid.WalkSpeed = 16
  PlayAnim:Stop()
 end
end)