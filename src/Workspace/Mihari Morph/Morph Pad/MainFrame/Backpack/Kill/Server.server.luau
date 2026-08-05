local Tool = script.Parent
local Handle = Tool:WaitForChild("Handle")
local Remote = Tool:WaitForChild("Remote")

local Character
local Player
local Humanoid
local Head

local Debounce = false
local KillSFX = script.Kill

function Equipped()
	Character = Tool.Parent
	Player = game.Players:GetPlayerFromCharacter(Character)
	Humanoid = Character:WaitForChild("Humanoid")
	Head = Character:WaitForChild("Head")
end

function UntagHumanoid(Humanoid)
	for i, v in pairs(Humanoid:GetChildren()) do
		if v:IsA("ObjectValue") and v.Name == "creator" then
			v:Destroy()
		end
	end
end

function TagHumanoid(Humanoid)
	local Creator_Tag = Instance.new("ObjectValue")
	Creator_Tag.Name = "creator"
	Creator_Tag.Value = Player
		game.Debris:AddItem(Creator_Tag, 10)

	Creator_Tag.Parent = Humanoid
end
function StunHumanoid(Humanoid, Debris)
	local Stun_Tag = Instance.new("BoolValue")
	Stun_Tag.Name = "Stunned"
	Stun_Tag.Parent = Humanoid
	game.Debris:AddItem(Stun_Tag, Debris)
end

function CreateSFX(Part, Sound)
	local SFX = Sound:Clone()
	SFX.PlaybackSpeed = (math.random(8,11) * .1)
	SFX.Parent = Part
	SFX:Play()
	game.Debris:AddItem(SFX,SFX.TimeLength + 1)
end

Remote.OnServerEvent:Connect(function(FiredPlayer,MouseHit)
	if MouseHit == nil then return end
	if Humanoid.Health == 0 then return end
	if FiredPlayer ~= Player then return end
	
	local EnemyHumanoid = MouseHit.Parent:FindFirstChildOfClass("Humanoid") or MouseHit.Parent.Parent:FindFirstChildOfClass("Humanoid")	
	if EnemyHumanoid == nil then return end	
	UntagHumanoid(EnemyHumanoid)
	TagHumanoid(EnemyHumanoid)
	
	for i, obj in pairs(EnemyHumanoid.Parent:GetChildren()) do
		if obj:IsA("BasePart") then 
			local ClonePart = obj:Clone()
			ClonePart.Material = Enum.Material.Neon
			ClonePart.BrickColor = BrickColor.new("White")
			ClonePart.CanCollide = true
			ClonePart.CFrame = obj.CFrame
			ClonePart.Parent = workspace
			ClonePart:ClearAllChildren()
			
			CreateSFX(ClonePart,KillSFX)
			local Emitter = script.VaporizePE:Clone()
			Emitter.Parent = ClonePart
			Emitter:Emit(25)
			
			local BodyForce = Instance.new("BodyForce")
			BodyForce.force = Vector3.new(0, workspace.Gravity, 0) * ClonePart:GetMass() * 1
			BodyForce.Parent = ClonePart
			
			local Velocity = Instance.new("BodyVelocity")
			Velocity.MaxForce = Vector3.new(100000, 100000, 100000)
			Velocity.P = math.huge
			Velocity.Velocity = Vector3.new(math.random(-5,5),math.random(-5,5),math.random(-5,5))
			Velocity.Parent = ClonePart
			game.Debris:AddItem(Velocity, .1)
			local Info = TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.InOut,0,false,2)
			local Goal = {Transparency = 1}
			local PlayableTween = game:GetService("TweenService"):Create(ClonePart,Info,Goal)
			PlayableTween:Play()
			game.Debris:AddItem(ClonePart,4.5)
			obj:Destroy()
		elseif obj:IsA("Accessory") or obj.Name == "CharacterSystem" then
			obj:Destroy()
		end
	end
end)

Tool.Equipped:Connect(Equipped)