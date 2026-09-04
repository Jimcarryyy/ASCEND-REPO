		local humanoid = script.Parent:WaitForChild("Humanoid")
		local MAX_HP = 1e15

		humanoid.MaxHealth = MAX_HP
		humanoid.Health = MAX_HP
		humanoid.BreakJointsOnDeath = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

		humanoid.HealthChanged:Connect(function(health)
			if health < MAX_HP then
				humanoid.Health = MAX_HP
			end
		end)
	