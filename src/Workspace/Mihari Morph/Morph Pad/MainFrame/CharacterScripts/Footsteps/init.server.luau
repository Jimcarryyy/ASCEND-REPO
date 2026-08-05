local Settings = require(script.Settings)
local Player = game.Players:GetPlayerFromCharacter(script.Parent)
local Activated = false
local Delay = 0.196
local DefaultDelay = Delay

function CreateSound(FolderType)
	if FolderType then
		if script.SFX:FindFirstChild(FolderType) ~= nil then
			local SoundCount = script.SFX:FindFirstChild(FolderType):GetChildren()
			local SelectionChoice = math.random(1, #SoundCount)
			local SFX = SoundCount[SelectionChoice]:Clone()
			SFX.Parent = script.Parent:WaitForChild("HumanoidRootPart")
			SFX:Play()
			game:GetService("Debris"):AddItem(SFX, Settings.SFXDebrisDelay)
		else
			warn(tostring(FolderType).." - is not a valid material!")
		end
	end
end

function PlaySFX(Result)
	CreateSound(Result)
end

function DetectMaterial(MaterialType)
	local MaterialDesignType = nil
	local GetMaterialTypes = script.MaterialTypes:GetChildren()
	for i=1, #GetMaterialTypes do
		local GetFolderData = GetMaterialTypes[i]:GetChildren()
		
		for n=1, #GetFolderData do
			if tostring(MaterialType) == GetFolderData[n].Name then
				MaterialDesignType = GetFolderData[n].Parent.Name
				break
			end
		end
	end
	
	if MaterialDesignType then
		PlaySFX(MaterialDesignType)
	else
		warn(tostring(MaterialType).." has not been registered to the database!")
	end
end

game["Run Service"].Heartbeat:connect(function(Delta)
	if Activated == false then
		local MaterialType = script.Parent:WaitForChild("Humanoid").FloorMaterial
		local Distance = (script.Parent:WaitForChild("HumanoidRootPart").Velocity * Vector3.new(1, 0, 1)).magnitude
		Activated = true
		wait(Delay)
		--Prevents auto playing sounds (Checks distances)
		if Distance >= 5 then
			if script.Parent.Humanoid.WalkSpeed >= Settings.RunningSpeed then
				Delay = DefaultDelay
			else
				Delay = DefaultDelay * 2.5
			end
			DetectMaterial(MaterialType)
		end
		Activated = false
	end
end)
