--!strict
--[[
    WeaponManager.luau
    Location: src/ServerScriptService/Server/Combat/WeaponManager.luau
    Modern MeshPart / Model / Tool / Procedural Qi weapon attachment manager.
    Attaches 3D weapons using RightHand RightGripAttachment alignment.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = require(ReplicatedStorage.Shared.Network.RemoteEvents)
local UIAssets = require(ReplicatedStorage.Shared.Configs.UIAssets)

export type WeaponType = "FlyingSword" | "Spear" | "Gauntlet"

local WeaponManager = {}
local equippedWeapons: { [Player]: WeaponType } = {}
local updateSkillStateRemote: RemoteEvent

function WeaponManager.Init()
	updateSkillStateRemote = RemoteEvents.GetRemote("UpdateSkillState")

	Players.PlayerAdded:Connect(function(player)
		equippedWeapons[player] = "FlyingSword"
		player.CharacterAdded:Connect(function(character)
			task.wait(0.3)
			WeaponManager.AttachWeaponModel(player, "FlyingSword")
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		equippedWeapons[player] = nil
	end)

	-- Handle weapon swap requests from clients
	local combatActionRemote = RemoteEvents.GetRemote("CombatAction")
	combatActionRemote.OnServerEvent:Connect(function(player: Player, payload: any)
		if type(payload) == "table" and payload.RequestWeaponSwap then
			local requestedWeapon = payload.RequestWeaponSwap :: string
			if requestedWeapon == "FlyingSword" or requestedWeapon == "Spear" or requestedWeapon == "Gauntlet" then
				WeaponManager.EquipWeapon(player, requestedWeapon :: WeaponType)
			end
		end
	end)

	print("[ASCEND] WeaponManager Engine Initialized.")
end

function WeaponManager.GetEquippedWeapon(player: Player): WeaponType
	return equippedWeapons[player] or "FlyingSword"
end

function WeaponManager.SetWeaponVisibility(player: Player, visible: boolean)
	local character = player.Character
	if not character then return end

	local weaponInst = character:FindFirstChild("Equipped3DWeapon")
	if weaponInst then
		if weaponInst:IsA("Model") then
			for _, descendant in ipairs(weaponInst:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = if visible then 0 else 1
				end
			end
		elseif weaponInst:IsA("BasePart") then
			weaponInst.Transparency = if visible then 0 else 1
		end
	end

	local gauntletLeft = character:FindFirstChild("Equipped3DGauntlet_Left")
	if gauntletLeft then
		if gauntletLeft:IsA("Model") then
			for _, descendant in ipairs(gauntletLeft:GetDescendants()) do
				if descendant:IsA("BasePart") then
					descendant.Transparency = if visible then 0 else 1
				end
			end
		elseif gauntletLeft:IsA("BasePart") then
			gauntletLeft.Transparency = if visible then 0.3 else 1
		end
	end
end

function WeaponManager.AttachWeaponModel(player: Player, weaponType: WeaponType)
	local character = player.Character
	if not character then return end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm") :: BasePart?
	if not rightHand then return end

	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm") :: BasePart?

	-- Remove old 3D weapon models & old Motor6D grips
	local oldWeapon = character:FindFirstChild("Equipped3DWeapon")
	if oldWeapon then oldWeapon:Destroy() end

	local oldLeftGauntlet = character:FindFirstChild("Equipped3DGauntlet_Left")
	if oldLeftGauntlet then oldLeftGauntlet:Destroy() end
	
	local oldGripRight = rightHand:FindFirstChild("WeaponGrip")
	if oldGripRight then oldGripRight:Destroy() end

	if leftHand then
		local oldGripLeft = leftHand:FindFirstChild("WeaponGripLeft")
		if oldGripLeft then oldGripLeft:Destroy() end
	end

	-- Procedural Dual Qi Gauntlets
	if weaponType == "Gauntlet" then
		local function CreateGauntletBracer(handPart: BasePart, isLeft: boolean)
			local gPart = Instance.new("Part")
			gPart.Name = if isLeft then "Equipped3DGauntlet_Left" else "Equipped3DWeapon"
			gPart.Size = Vector3.new(0.85, 1.1, 0.85)
			gPart.CanCollide = false
			gPart.Massless = true
			gPart.Material = Enum.Material.Neon
			gPart.Transparency = 0.3
			gPart.Color = Color3.fromRGB(0, 220, 255)

			local auraLight = Instance.new("PointLight")
			auraLight.Range = 8
			auraLight.Brightness = 2.5
			auraLight.Color = Color3.fromRGB(0, 220, 255)
			auraLight.Parent = gPart

			local motor = Instance.new("Motor6D")
			motor.Name = if isLeft then "WeaponGripLeft" else "WeaponGrip"
			motor.Part0 = handPart
			motor.Part1 = gPart
			motor.C0 = CFrame.new(0, 0, 0)
			motor.C1 = CFrame.new(0, 0, 0)
			motor.Parent = handPart

			gPart.Parent = character
		end

		if rightHand then CreateGauntletBracer(rightHand :: BasePart, false) end
		if leftHand then CreateGauntletBracer(leftHand :: BasePart, true) end
		return
	end

	-- 1. SEARCH REPLICATEDSTORAGE DIRECTLY (Top Level & Subfolders)
	local weaponTemplate: Instance? = nil

	if weaponType == "FlyingSword" then
		weaponTemplate = ReplicatedStorage:FindFirstChild("HeavenlyVoidBlade")
			or ReplicatedStorage:FindFirstChild("VoidFlyingSword")
			or ReplicatedStorage:FindFirstChild("FlyingSword")
	elseif weaponType == "Spear" then
		weaponTemplate = ReplicatedStorage:FindFirstChild("DragonSovereignSpear")
			or ReplicatedStorage:FindFirstChild("Spear")
	end

	-- Fallback search inside ReplicatedStorage.Weapons if present
	if not weaponTemplate then
		local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons") :: Folder?
		if weaponsFolder then
			weaponTemplate = weaponsFolder:FindFirstChild(weaponType)
		end
	end

	local weaponInstance: Instance? = nil
	local handle: BasePart? = nil

	if weaponTemplate then
		weaponInstance = weaponTemplate:Clone()
		weaponInstance.Name = "Equipped3DWeapon"

		-- Clean up legacy scripts inside custom model
		for _, scriptInst in ipairs(weaponInstance:GetDescendants()) do
			if scriptInst:IsA("LuaSourceContainer") then
				scriptInst:Destroy()
			end
		end

		if weaponInstance:IsA("Model") then
			local modelInst = weaponInstance :: Model
			handle = modelInst.PrimaryPart 
				or (weaponInstance:FindFirstChild("Handle") :: BasePart?) 
				or weaponInstance:FindFirstChildOfClass("MeshPart") 
				or weaponInstance:FindFirstChildOfClass("BasePart")
		elseif weaponInstance:IsA("BasePart") then
			handle = weaponInstance :: BasePart
		end
	end

	-- 2. PROCEDURAL FALLBACK ONLY IF NO MODEL IS FOUND
	if not handle then
		warn(string.format("[WeaponManager] Model for %s not found in ReplicatedStorage. Using procedural fallback.", weaponType))
		local placeholder = Instance.new("Part")
		placeholder.Name = "Equipped3DWeapon"
		placeholder.CanCollide = false
		placeholder.Massless = true
		placeholder.Material = Enum.Material.Neon
		placeholder.Transparency = 0.25

		local auraLight = Instance.new("PointLight")
		auraLight.Range = 10
		auraLight.Brightness = 3
		auraLight.Parent = placeholder

		if weaponType == "FlyingSword" then
			placeholder.Size = Vector3.new(0.5, 0.3, 4.5)
			placeholder.Color = Color3.fromRGB(0, 220, 255)
			auraLight.Color = Color3.fromRGB(0, 220, 255)
		elseif weaponType == "Spear" then
			placeholder.Size = Vector3.new(0.4, 0.4, 7.5)
			placeholder.Color = Color3.fromRGB(50, 255, 120)
			auraLight.Color = Color3.fromRGB(50, 255, 120)
		end

		weaponInstance = placeholder
		handle = placeholder
	end

	if not handle or not weaponInstance then return end

	handle.CanCollide = false
	handle.Massless = true

	-- Programmatically Add Weapon Trail Attachments
	local topAttach = handle:FindFirstChild("TrailTop") :: Attachment? or Instance.new("Attachment")
	topAttach.Name = "TrailTop"
	topAttach.Position = Vector3.new(0, 2.2, 0)
	topAttach.Parent = handle

	local botAttach = handle:FindFirstChild("TrailBottom") :: Attachment? or Instance.new("Attachment")
	botAttach.Name = "TrailBottom"
	botAttach.Position = Vector3.new(0, -0.8, 0)
	botAttach.Parent = handle

	local trail = handle:FindFirstChild("WeaponTrail") :: Trail? or Instance.new("Trail")
	trail.Name = "WeaponTrail"
	trail.Attachment0 = topAttach
	trail.Attachment1 = botAttach
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.22
	trail.Enabled = false
	trail.Parent = handle

	-- 1. Ensure Arm RightGripAttachment exists
	local armGrip = rightHand:FindFirstChild("RightGripAttachment") :: Attachment?
	if not armGrip then
		armGrip = Instance.new("Attachment")
		armGrip.Name = "RightGripAttachment"
		armGrip.Position = Vector3.new(0, -1, 0)
		armGrip.Orientation = Vector3.new(0, 0, 0)
		armGrip.Parent = rightHand
	end

	-- 2. Read RightGripAttachment or Grip Attachment from Weapon
	local customGripAttachment = handle:FindFirstChild("RightGripAttachment") :: Attachment? 
		or handle:FindFirstChild("Grip") :: Attachment? 
		or weaponInstance:FindFirstChild("RightGripAttachment", true) :: Attachment? 
		or weaponInstance:FindFirstChild("Grip", true) :: Attachment?

	-- Auto-create attachment if missing
	if not customGripAttachment then
		local newAtt = Instance.new("Attachment")
		newAtt.Name = "RightGripAttachment"
		newAtt.Position = Vector3.new(0, 0, 0)
		newAtt.Orientation = Vector3.new(0, 90, 90)
		newAtt.Parent = handle
		customGripAttachment = newAtt
	end

	-- 3. Connect Motor6D Joint
	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponGrip"
	motor.Part0 = rightHand
	motor.Part1 = handle
	motor.C0 = armGrip.CFrame
	motor.C1 = customGripAttachment.CFrame
	motor.Parent = rightHand

	weaponInstance.Parent = character
	print(string.format("[WeaponManager] Successfully attached 3D Model '%s' to %s.", weaponInstance.Name, player.Name))
end

function WeaponManager.EquipWeapon(player: Player, weaponType: WeaponType)
	local character = player.Character
	if not character then return end

	character:SetAttribute("WeaponType", weaponType)
	equippedWeapons[player] = weaponType

	WeaponManager.AttachWeaponModel(player, weaponType)

	local skillIcons = {
		M1 = UIAssets.Skills.M1_SwordArt,
		F = UIAssets.Skills.M2_HeavySlam,
		Q = UIAssets.Skills.SwordTempest,
		E = UIAssets.Skills.DragonRoar,
		R = UIAssets.Skills.TribulationBolt,
		Shift = UIAssets.Skills.DodgeWindstep,
	}

	updateSkillStateRemote:FireClient(player, weaponType, skillIcons)
	print(string.format("[WeaponManager] Player %s equipped weapon: %s", player.Name, weaponType))
end

return WeaponManager