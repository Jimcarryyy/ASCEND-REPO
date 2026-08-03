--!strict
--[[
    WeaponManager.luau
    Modern MeshPart / Model / Tool / Procedural Qi weapon attachment manager.
    Adds programmatic White Weapon Swing Trail attachments to all weapons.
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

function WeaponManager.AttachWeaponModel(player: Player, weaponType: WeaponType)
	local character = player.Character
	if not character then return end

	local rightHand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	if not rightHand then return end

	local leftHand = character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm")

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

	-- Search for custom 3D weapon model in ReplicatedStorage/Weapons or ReplicatedStorage/Shared/Configs/Weapons
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons") :: Folder?
	if not weaponsFolder then
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local configs = if shared then shared:FindFirstChild("Configs") else nil
		if configs then
			weaponsFolder = configs:FindFirstChild("Weapons") :: Folder?
		end
	end

	local weaponTemplate = if weaponsFolder then weaponsFolder:FindFirstChild(weaponType) else nil

	local weaponInstance: Instance?
	local handle: BasePart?
	local toolGripCFrame: CFrame?

	if weaponTemplate then
		weaponInstance = weaponTemplate:Clone()
		weaponInstance.Name = "Equipped3DWeapon"

		-- Clean up legacy scripts inside custom model/tool
		for _, scriptInst in ipairs(weaponInstance:GetDescendants()) do
			if scriptInst:IsA("LuaSourceContainer") then
				scriptInst:Destroy()
			end
		end

		if weaponTemplate:IsA("Tool") then
			local tool = weaponTemplate :: Tool
			toolGripCFrame = tool.Grip
			handle = weaponInstance:FindFirstChild("Handle") :: BasePart?
		elseif weaponInstance:IsA("Model") then
			local modelInst = weaponInstance :: Model
			local primary = modelInst.PrimaryPart or weaponInstance:FindFirstChild("Handle") :: BasePart?
			handle = primary or (weaponInstance:FindFirstChildOfClass("BasePart") :: BasePart)
		elseif weaponInstance:IsA("BasePart") then
			handle = weaponInstance :: BasePart
		end
	end

	-- Fallback placeholder Part if no model is found
	local isPlaceholder = false
	if not handle then
		isPlaceholder = true
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
			placeholder.Size = Vector3.new(0.3, 4.2, 0.8)
			placeholder.Color = Color3.fromRGB(0, 220, 255)
			auraLight.Color = Color3.fromRGB(0, 220, 255)
		elseif weaponType == "Spear" then
			placeholder.Size = Vector3.new(0.3, 6.5, 0.3)
			placeholder.Color = Color3.fromRGB(255, 180, 40)
			auraLight.Color = Color3.fromRGB(255, 180, 40)
		end

		weaponInstance = placeholder
		handle = placeholder
	end

	if not handle or not weaponInstance then return end

	handle.CanCollide = false
	handle.Massless = true

	-- Programmatically Add Crisp White Weapon Trail
	local topAttach = Instance.new("Attachment")
	topAttach.Name = "TrailTop"
	topAttach.Position = Vector3.new(0, 2.2, 0)
	topAttach.Parent = handle

	local botAttach = Instance.new("Attachment")
	botAttach.Name = "TrailBottom"
	botAttach.Position = Vector3.new(0, -0.8, 0)
	botAttach.Parent = handle

	local trail = Instance.new("Trail")
	trail.Name = "WeaponTrail"
	trail.Attachment0 = topAttach
	trail.Attachment1 = botAttach
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)) -- Crisp White
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1)
	})
	trail.Lifetime = 0.22
	trail.Enabled = false
	trail.Parent = handle

	-- Create Motor6D joint attached to RightHand
	local rightGrip = rightHand:FindFirstChild("RightGripAttachment") :: Attachment?
	local customGripAttachment = handle:FindFirstChild("Grip") :: Attachment? or weaponInstance:FindFirstChild("Grip", true) :: Attachment?

	local motor = Instance.new("Motor6D")
	motor.Name = "WeaponGrip"
	motor.Part0 = rightHand
	motor.Part1 = handle

	local baseCFrame = if rightGrip then rightGrip.CFrame else CFrame.new(0, 0, 0)

	if isPlaceholder then
		motor.C0 = CFrame.new(0, 0, 0)
		motor.C1 = CFrame.new(0, 0, 0)
	elseif toolGripCFrame then
		motor.C0 = baseCFrame
		motor.C1 = toolGripCFrame * CFrame.Angles(math.rad(-90), 0, 0)
	elseif customGripAttachment then
		motor.C0 = baseCFrame
		motor.C1 = customGripAttachment.CFrame
	else
		motor.C0 = CFrame.new(0, 0, 0)
		motor.C1 = CFrame.new(0, 0, 0)
	end

	motor.Parent = rightHand
	weaponInstance.Parent = character
end

function WeaponManager.EquipWeapon(player: Player, weaponType: WeaponType)

    local character = player.Character
	if not character then return end

	character:SetAttribute("WeaponType", weaponType)
	equippedWeapons[player] = weaponType

	-- Spawn and weld 3D Weapon Model or Placeholder
	WeaponManager.AttachWeaponModel(player, weaponType)

	-- Generate skill icon map for the client HUD
	local skillIcons = {}
	if weaponType == "FlyingSword" then
		skillIcons = {
			M1 = UIAssets.Skills.M1_SwordArt,
			F = UIAssets.Skills.M2_HeavySlam,
			Q = UIAssets.Skills.SwordTempest,
			E = UIAssets.Skills.DragonRoar,
			R = UIAssets.Skills.TribulationBolt,
			Shift = UIAssets.Skills.DodgeWindstep,
		}
	elseif weaponType == "Spear" then
		skillIcons = {
			M1 = UIAssets.Weapons.Spear,
			F = UIAssets.Skills.HundredPalms,
			Q = UIAssets.Skills.ParryQiShield,
			E = UIAssets.Skills.DragonRoar,
			R = UIAssets.Skills.TribulationBolt,
			Shift = UIAssets.Skills.DodgeWindstep,
		}
	elseif weaponType == "Gauntlet" then
		skillIcons = {
			M1 = UIAssets.Weapons.Gauntlet,
			F = UIAssets.Skills.ParryQiShield,
			Q = UIAssets.Skills.HundredPalms,
			E = UIAssets.Skills.M2_HeavySlam,
			R = UIAssets.Skills.TribulationBolt,
			Shift = UIAssets.Skills.DodgeWindstep,
		}
	end

	-- Notify client HUD to update skill slot icons
	updateSkillStateRemote:FireClient(player, weaponType, skillIcons)

	print(string.format("[WeaponManager] Player %s equipped weapon: %s", player.Name, weaponType))
end

return WeaponManager