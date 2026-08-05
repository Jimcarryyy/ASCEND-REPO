local showadditions = false

function countclones(thing,name) 
local returnnumber = "" 
for abc,def in pairs(thing:GetChildren()) do
if def.Name == name.. returnnumber.. "_ToolStorage" then 
if returnnumber == "" then 
returnnumber = 0
end
returnnumber = returnnumber + 1
end
end 
local rexu = returnnumber 
if returnnumber == "" then 
rexu = "no"
end
print("Counted ".. rexu.. " clones of ".. name)
return returnnumber
end

local players = game:GetService("Players") 
local storage = game:GetService("ServerStorage")
local model = script.Parent.Parent 
local style = script.StylePieces
local guis = script:WaitForChild("GUIs")  
local hipheightest = script:WaitForChild("AdditionalHipHeight")
local remotefolder = script:WaitForChild("Remotes") 
local cs = script:WaitForChild("CharacterScripts") 
local items = script:WaitForChild("Backpack")
local used = false 
local tagname = "QUACKMORPHED" 
local quiack = storage:FindFirstChild("QuackCache") 
local quick = nil
if quiack == nil then 
quiack = Instance.new("Folder",storage) 
quiack.Name = "QuackCache"
end  
local basehumanoid = script.Parent.Parent:FindFirstChildWhichIsA("Humanoid",true)
local body = basehumanoid.Parent 
local root = body:WaitForChild("HumanoidRootPart") 
local greatmagnus = countclones(quiack,body.Name) 
print("QuackPad ".. body.Name.. greatmagnus.. " bound")
wait() 
items.Name = body.Name.. greatmagnus.. "_ToolStorage" 
items.Parent = quiack
print("QuackPad Loaded")

function removeface(face)
	for i,v in pairs(face:GetChildren()) do
		if v.ClassName == "Decal" then
			v:Destroy()
		end
	end
end

function gettooltable(list) 
local finale = {}
for a,v in pairs(list) do 
local bickus = v:Clone()  
bickus.Parent = quiack
table.insert(finale,#finale + 1,bickus)
end 
for b,i in pairs(items:GetChildren()) do 
local bickuse = i:Clone() 
bickuse.Parent = quiack
table.insert(finale,#finale + 1,bickuse)
end 
return finale
end

function createorfindtorso(model) 
local torso = model:FindFirstChild("Torso") 
if torso == nil then
torso = Instance.new("Part",model) 
local root = model:WaitForChild("HumanoidRootPart") 
torso.Size = root.Size 
torso.CanCollide = false 
torso.Massless = true 
if showadditions == true then 
torso.Transparency = 0.75
else
torso.Transparency = 1 
end 
torso.Name = "Torso"
local W = Instance.new("Motor6D",root)
				W.Part0 = root
				W.Part1 = torso
				local CJ = CFrame.new(root.Position)
				local C0 = root.CFrame:inverse()*CJ
				local C1 = root.CFrame:inverse()*CJ
				W.C0 = C0
				W.C1 = C1  
				W.MaxVelocity = 0.1
				W.Name = "Root Hip" 
local headmann = Instance.new("Part",model) 
headmann.Size = Vector3.new(1,1,1) 
headmann.CanCollide = false 
headmann.Massless = true 
if showadditions == false then 
headmann.Transparency = 1 
end 
headmann.Name = "Head"
local W2 = Instance.new("Motor6D",torso)
				W2.Part0 = torso
				W2.Part1 = headmann
				local CJo = CFrame.new(torso.Position)
				local C0o = torso.CFrame:inverse()*CJo
				local C1o = torso.CFrame:inverse()*CJo
				W2.C0 = C0o
				W2.C1 = C1o  
				W2.MaxVelocity = 0.1
				W2.Name = "Neck" 
local tablerpar = {{"Left Arm", "Left Shoulder",torso,Vector3.new(1,2,1),false},{"Left Leg", "Left Hip",torso,Vector3.new(1,1,2),true},{"Right Leg", "Right Hip",torso,Vector3.new(2,1,1),true}}
for antivirus,malware in pairs(tablerpar) do 
local headmann2 = Instance.new("Part",model) 
headmann2.Size = malware[4] 
headmann2.CanCollide = malware[5] 
headmann2.Massless = true 
if showadditions == false then 
headmann2.Transparency = 1 
end  
headmann2.Name = malware[1]
local W3 = Instance.new("Motor6D",malware[3])
				W3.Part0 = malware[3]
				W3.Part1 = headmann2
				local CJ0 = CFrame.new(torso.Position)
				local C00 = torso.CFrame:inverse()*CJ0
				local C10 = torso.CFrame:inverse()*CJ0
				W3.C0 = C00
				W3.C1 = C10  
				W3.MaxVelocity = 0.1
				W3.Name = malware[2]
end 
end 
return torso
end

function emergancyprotocol(head,distance,name,parent) 
local abudabih = Instance.new("Part",head.Parent) 
abudabih.Orientation = Vector3.new(90,0,0)  
abudabih.Position = head.Position - distance
if showadditions == false then 
abudabih.Transparency = 1 
end  
abudabih.CanCollide = false 
abudabih.Massless = true
local rotatedCFrame = CFrame.Angles(90, 0, 0)
local W = Instance.new("Motor6D")
				W.Part0 = head
				W.Part1 = abudabih
				local CJ = CFrame.new(head.Position)
				local C0 = head.CFrame:inverse()*CJ
				local C1 = abudabih.CFrame:inverse()*CJ
				W.C0 = C0
				W.C1 = C1 
				W.MaxVelocity = 0.1 
				if parent == "part" then 
				W.Parent = abudabih 
	else
				W.Parent = parent
				end
				W.Name = name
return abudabih
end

function morph(character) 
local player = players:GetPlayerFromCharacter(character) 
local human = character:FindFirstChildOfClass("Humanoid") 
local successe = false
if human ~= nil and player ~= nil then 
human:UnequipTools() 
wait()
local toolstogive = gettooltable(player.Backpack:GetChildren()) 
wait() 
local oldcframe = character:WaitForChild("HumanoidRootPart").CFrame
local	char = body:Clone() 
for vasdf,dsfd in pairs(char:GetDescendants()) do 
if dsfd.ClassName == "BasePart" or dsfd.ClassName == "MeshPart" or  dsfd.ClassName == "UnionOperation" then 
dsfd.CanCollide = false 
dsfd.Massless = true
end
end
		char.Name = player.Name 
		local alsoroot =  char:WaitForChild("HumanoidRootPart") 
		alsoroot.CFrame = CFrame.new(Vector3.new(0,0,0))
		local humbuso = char:FindFirstChildOfClass("Humanoid") 
		if humbuso == nil then 
		humbuso = Instance.new("Humanoid",char)
		end  
		humbuso.HipHeight = humbuso.HipHeight + hipheightest.Value
		if humbuso.RigType == Enum.HumanoidRigType.R15 then 
		if char:FindFirstChild("RightHand") == nil then 
		local hand = emergancyprotocol(char.HumanoidRootPart,Vector3.new(-1.5, 0, 2),"RightShoulder","part") 
		hand.Name = "RightHand" 
		humbuso.HipHeight = humbuso.HipHeight + 1
		end
		else
		if char:FindFirstChild("Right Arm") == nil then 
		local torsocreated = createorfindtorso(char)
		local hand = emergancyprotocol(char.HumanoidRootPart,Vector3.new(-1.5, -0.5, 2),"Right Shoulder",torsocreated) 
		hand.Name = "Right Arm"
		end
		end
		if alsoroot.Anchored == true then 
		alsoroot.Anchored = false
		end 
		if char:FindFirstChild(script.Parent.Name) ~= nil and char[script.Parent.Name]:FindFirstChild(script.Name) ~= nil then 
		char[script.Parent.Name]:Destroy()
		end 
		char:MakeJoints()
		local tagman = Instance.new("BoolValue",char) 
		tagman.Name = tagname
		player.Character = char
		player.Character.Parent = workspace 
		alsoroot.CFrame = oldcframe
wait()
for index,value in pairs(cs:GetChildren()) do 
value:Clone().Parent = player.Character
end 
for index,value in pairs(guis:GetChildren()) do 
value:Clone().Parent = player.PlayerGui
end 
if #remotefolder:GetChildren() >= 1 then
remotefolder:Clone().Parent = player.Character 
end
wait(3) 
for index,value in pairs(toolstogive) do 
local duplicatetoole = player.Backpack:FindFirstChild(value.Name)
if duplicatetoole == nil or duplicatetoole.ToolTip ~= value.ToolTip then 
value.Parent = player.Backpack 
			else
value:Destroy()
end
end
successe = true
end	
return successe
end

function touchman(p)
	if used ~= true then
		if p.Parent:FindFirstChildOfClass("Humanoid") and p.Parent:FindFirstChild("HumanoidRootPart") then
		used = true
		if p.Parent:FindFirstChild(tagname) == nil then
			local tag = Instance.new("BoolValue")
			tag.Name = tagname
			tag.Parent = p.Parent
			local diditdo = morph(p.Parent)
		end 
		wait()
		used = false
		end
	end
end 

script.Parent.Touched:connect(function(h) 
touchman(h)
end) 
for hij,klm in pairs(style:GetDescendants()) do 
if klm.ClassName == "BasePart" or klm.ClassName == "UnionOperation" or klm.ClassName == "MeshPart" then 
klm.Touched:connect(function(par) 
touchman(par)	
end) 
end
end